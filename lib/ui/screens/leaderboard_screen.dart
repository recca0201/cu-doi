import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/bb_theme.dart';
import '../../core/bb_tokens.dart';
import '../../core/platform_avatar.dart';
import '../../domain/leaderboard_models.dart';
import '../../sim/arena.dart';
import '../../sim/arenas.dart';
import '../../state/leaderboard_controller.dart';
import '../../state/providers.dart';
import '../widgets/bb_backdrop.dart';
import '../widgets/bb_widgets.dart';
import '../widgets/leaderboard_widgets.dart';

enum LeaderboardOrigin { arenaMap, winResult }

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({
    super.key,
    required this.arenaId,
    required this.origin,
    this.achievedScore,
  });

  final int arenaId;
  final LeaderboardOrigin origin;
  final int? achievedScore;

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  late final LeaderboardController _controller;
  late final PlatformAvatarLoader _avatarLoader;
  late final VoidCallback _removeControllerListener;
  late LeaderboardViewState _viewState;

  @override
  void initState() {
    super.initState();
    _avatarLoader = ref.read(platformAvatarLoaderProvider);
    final submissions = ref.read(leaderboardSubmissionProvider.notifier);
    _controller = LeaderboardController(
      ref.read(leaderboardRepositoryProvider),
      arenaId: widget.arenaId,
      submissionSummary: ref.read(leaderboardSubmissionProvider),
      onOpened: submissions.onLeaderboardOpened,
      onAuthenticated: () async {
        final ProgressController progress = ref.read(progressProvider.notifier);
        await progress.ready;
        await submissions.onAuthenticated(
          ref.read(progressProvider),
          progressConfirmed: progress.hasConfirmedSnapshot,
        );
      },
    );
    bool initializing = true;
    _removeControllerListener = _controller.addListener((next) {
      _viewState = next;
      if (!initializing && mounted) setState(() {});
    });
    initializing = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_controller.open());
    });
  }

  @override
  void dispose() {
    _avatarLoader.clear();
    _removeControllerListener();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SubmissionSummary>(leaderboardSubmissionProvider, (_, next) {
      _controller.updateSubmissionSummary(next);
    });
    final LeaderboardViewState state = _viewState;
    final String locale = Localizations.localeOf(context).languageCode;
    final arena = kArenas.firstWhere((arena) => arena.id == widget.arenaId);
    return LeaderboardScreenView(
      state: state,
      arenaName: forLocale(locale, arena.name, arena.nameEn),
      achievedScore: widget.achievedScore,
      avatarLoader: _avatarLoader,
      onBack: () => Navigator.of(context).maybePop(),
      onScopeSelected: (LeaderboardScope scope) {
        _avatarLoader.clear();
        unawaited(_controller.selectScope(scope));
      },
      onRetry: () {
        unawaited(_controller.retry());
      },
      onAuthenticate: _controller.authenticateFromUserAction,
      onAuthDismissed: () {
        final LeaderboardViewState latest = _viewState;
        // A failed/cancelled platform flow may reveal a matching last-known
        // cache. Keep that cache visible; otherwise return to the entry route.
        if (latest.status != LeaderboardViewStatus.offlineCache) {
          Navigator.of(context).maybePop();
        }
      },
      onRetrySubmission: () {
        unawaited(
          ref
              .read(leaderboardSubmissionProvider.notifier)
              .retryFailed(widget.arenaId),
        );
      },
    );
  }
}

/// Pure presentation seam used by widget tests and visual previews.
class LeaderboardScreenView extends StatelessWidget {
  const LeaderboardScreenView({
    super.key,
    required this.state,
    required this.arenaName,
    required this.onBack,
    required this.onScopeSelected,
    this.avatarLoader,
    this.achievedScore,
    this.onRetry,
    this.onAuthenticate,
    this.onAuthDismissed,
    this.onRetrySubmission,
  });

  final LeaderboardViewState state;
  final String arenaName;
  final VoidCallback onBack;
  final ValueChanged<LeaderboardScope> onScopeSelected;
  final PlatformAvatarLoader? avatarLoader;
  final int? achievedScore;
  final VoidCallback? onRetry;
  final Future<bool> Function()? onAuthenticate;
  final VoidCallback? onAuthDismissed;
  final VoidCallback? onRetrySubmission;

  @override
  Widget build(BuildContext context) {
    final LeaderboardCopy copy = LeaderboardCopy.of(context);
    return Scaffold(
      backgroundColor: BbTokens.karstDeep,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const BbCanyonBackdrop(scrim: .12, bottomShade: .5),
          const BbKarstFrameOverlay(),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                key: const Key('leaderboard-panel'),
                constraints: const BoxConstraints(maxWidth: BbTokens.screenMax),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    BbTokens.sp3,
                    BbTokens.sp3,
                    BbTokens.sp3,
                    BbTokens.sp4,
                  ),
                  child: Column(
                    children: <Widget>[
                      _LeaderboardHeader(
                        title: copy.title,
                        subtitle: copy.level(state.arenaId, arenaName),
                        onBack: onBack,
                      ),
                      const SizedBox(height: BbTokens.sp3),
                      LeaderboardScopeControl(
                        scope: state.scope,
                        onSelected: onScopeSelected,
                      ),
                      Semantics(
                        key: const Key('leaderboard-scope-live-region'),
                        liveRegion: true,
                        label: copy.scopeAnnouncement(state.scope),
                        child: const SizedBox.shrink(),
                      ),
                      if (state.status == LeaderboardViewStatus.loaded &&
                          state.page != null)
                        Semantics(
                          key: const Key('leaderboard-loaded-live-region'),
                          liveRegion: true,
                          label: copy.loadedAnnouncement(
                            state.arenaId,
                            state.scope,
                          ),
                          child: const SizedBox.shrink(),
                        ),
                      const SizedBox(height: BbTokens.sp3),
                      const LeaderboardPeriodLabel(),
                      const SizedBox(height: BbTokens.sp2),
                      Expanded(child: _body(context)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    final LeaderboardPage? page = state.page;
    if (state.status == LeaderboardViewStatus.loaded && page != null) {
      return LeaderboardLoadedContent(
        page: page,
        avatarLoader: avatarLoader,
        footer: _submissionPanel(context),
      );
    }
    final LeaderboardCopy copy = LeaderboardCopy.of(context);
    final Widget? submission = _submissionPanel(context);
    return switch (state.status) {
      LeaderboardViewStatus.loading => _stateScroll(
        LeaderboardStateCard(
          key: const Key('leaderboard-state-loading'),
          icon: Icons.hourglass_top_rounded,
          title: copy.loadingTitle,
          message:
              '${state.scope == LeaderboardScope.global ? copy.global : copy.friends} · ${copy.level(state.arenaId, arenaName)} · ${copy.allTime}',
          badge: copy.loadingBadge,
          badgeColor: BbTokens.primaryGold,
          liveLabel: copy.loadingAnnouncement(state.arenaId),
          busy: true,
        ),
        footer: submission,
      ),
      LeaderboardViewStatus.empty => _stateScroll(
        LeaderboardStateCard(
          key: const Key('leaderboard-state-empty'),
          icon: Icons.emoji_events_outlined,
          title: copy.emptyTitle(state.arenaId),
          message: copy.emptyMessage(state.scope),
          liveLabel:
              '${copy.emptyTitle(state.arenaId)}. ${copy.emptyMessage(state.scope)}',
        ),
        footer: submission,
      ),
      LeaderboardViewStatus.serviceError => _stateScroll(
        LeaderboardStateCard(
          key: const Key('leaderboard-state-service-error'),
          icon: Icons.error_outline_rounded,
          title: copy.serviceErrorTitle,
          message: copy.serviceErrorMessage,
          badge: copy.serviceErrorBadge,
          badgeColor: BbTokens.dangerRed,
          accentColor: BbTokens.dangerRed,
          liveLabel: '${copy.serviceErrorTitle}. ${copy.serviceErrorMessage}',
          actions: <Widget>[
            BbButton.primary(
              key: const Key('leaderboard-retry'),
              label: copy.retry,
              icon: Icons.refresh_rounded,
              onPressed: onRetry,
              expand: true,
            ),
            BbButton.karst(
              label: copy.back,
              icon: Icons.arrow_back_rounded,
              onPressed: onBack,
              expand: true,
            ),
          ],
        ),
        footer: submission,
      ),
      LeaderboardViewStatus.offlineCache => _offlineCache(context),
      LeaderboardViewStatus.offlineNoCache => _stateScroll(
        LeaderboardStateCard(
          key: const Key('leaderboard-state-offline-no-cache'),
          icon: Icons.cloud_off_rounded,
          title: copy.offlineEmptyTitle,
          message: copy.offlineEmptyMessage(state.arenaId, state.scope),
          badge: copy.offlineBadge,
          badgeColor: BbTokens.primaryGold,
          accentColor: BbTokens.primaryGold,
          liveLabel:
              '${copy.offlineEmptyTitle}. ${copy.offlineEmptyMessage(state.arenaId, state.scope)}',
          actions: <Widget>[
            BbButton.karst(
              key: const Key('leaderboard-retry'),
              label: copy.retry,
              icon: Icons.refresh_rounded,
              onPressed: onRetry,
              expand: true,
            ),
          ],
        ),
        footer: submission,
      ),
      LeaderboardViewStatus.friendsUnavailable => _stateScroll(
        LeaderboardStateCard(
          key: const Key('leaderboard-state-friends-unavailable'),
          icon: Icons.people_outline_rounded,
          title: copy.friendsUnavailableTitle,
          message: copy.friendsUnavailableMessage,
          badge: copy.friends,
          liveLabel:
              '${copy.friendsUnavailableTitle}. ${copy.friendsUnavailableMessage}',
          actions: <Widget>[
            BbButton.karst(
              key: const Key('leaderboard-view-global'),
              label: copy.viewGlobal,
              icon: Icons.public_rounded,
              onPressed: () => onScopeSelected(LeaderboardScope.global),
              expand: true,
            ),
            BbButton.karst(
              label: copy.back,
              icon: Icons.arrow_back_rounded,
              onPressed: onBack,
              expand: true,
            ),
          ],
        ),
        footer: submission,
      ),
      LeaderboardViewStatus.authPrompt => _stateScroll(
        LeaderboardStateCard(
          key: const Key('leaderboard-state-auth-prompt'),
          icon: Icons.emoji_events_rounded,
          title: copy.authTitle,
          message: copy.authPromptMessage,
          liveLabel: '${copy.authTitle}. ${copy.authPromptMessage}',
          actions: <Widget>[
            BbButton.primary(
              key: const Key('leaderboard-auth-open'),
              label: copy.authConnect,
              icon: Icons.link_rounded,
              onPressed: () => _showAuthDialog(context),
              expand: true,
            ),
          ],
        ),
        footer: submission,
      ),
      LeaderboardViewStatus.loaded => const SizedBox.shrink(),
    };
  }

  Widget _offlineCache(BuildContext context) {
    final LeaderboardCopy copy = LeaderboardCopy.of(context);
    final LeaderboardSnapshot? snapshot = state.snapshot;
    if (snapshot == null) {
      return _stateScroll(
        LeaderboardStateCard(
          key: const Key('leaderboard-state-offline-no-cache'),
          icon: Icons.cloud_off_rounded,
          title: copy.offlineEmptyTitle,
          message: copy.offlineEmptyMessage(state.arenaId, state.scope),
          liveLabel: copy.offlineEmptyTitle,
        ),
        footer: _submissionPanel(context),
      );
    }
    final LeaderboardPage cachedPage = LeaderboardPage(
      leaders: snapshot.rows.map(_cachedEntry),
      currentPlayer: snapshot.currentPlayer == null
          ? null
          : _cachedEntry(snapshot.currentPlayer!),
    );
    return LeaderboardLoadedContent(
      page: cachedPage,
      avatarLoader: avatarLoader,
      header: LeaderboardStateCard(
        key: const Key('leaderboard-state-offline-cache'),
        icon: Icons.cloud_off_rounded,
        title: copy.staleTitle,
        message: copy.staleMessage(state.arenaId, state.scope),
        badge: copy.offlineBadge,
        badgeColor: BbTokens.primaryGold,
        accentColor: BbTokens.primaryGold,
        liveLabel:
            '${copy.staleTitle}. ${copy.staleMessage(state.arenaId, state.scope)}',
        extra: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Icon(
              Icons.warning_amber_rounded,
              color: BbTokens.primaryGold,
            ),
            const SizedBox(width: BbTokens.sp2),
            Expanded(
              child: Text(
                copy.offlineQueueMessage,
                style: BbText.small(
                  BbTokens.cream,
                ).copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          BbButton.karst(
            key: const Key('leaderboard-retry'),
            label: copy.retry,
            icon: Icons.refresh_rounded,
            onPressed: onRetry,
            expand: true,
          ),
        ],
      ),
      footer: _submissionPanel(context),
    );
  }

  LeaderboardEntry _cachedEntry(PersistedLeaderboardRow row) =>
      LeaderboardEntry(
        rank: row.rank,
        playerId: 'cached-${row.playerHash}',
        displayName: row.displayName,
        score: row.score,
        isCurrentPlayer: row.isCurrentPlayer,
      );

  Widget _stateScroll(Widget child, {Widget? footer}) => SingleChildScrollView(
    key: const Key('leaderboard-state-scroll'),
    padding: const EdgeInsets.fromLTRB(
      BbTokens.sp1,
      BbTokens.sp1,
      BbTokens.sp1,
      BbTokens.sp4,
    ),
    child: Column(
      children: <Widget>[
        child,
        if (footer != null) ...<Widget>[
          const SizedBox(height: BbTokens.sp3),
          footer,
        ],
      ],
    ),
  );

  Widget? _submissionPanel(BuildContext context) {
    final PendingScore? durableScore = state.arenaSubmission;
    final PendingScore? score =
        achievedScore == null || durableScore?.score == achievedScore
        ? durableScore
        : null;
    final SubmissionReceipt? receipt = state.submissionSummary.receiptForArena(
      state.arenaId,
      score: achievedScore,
    );
    if (score == null && achievedScore == null && receipt == null) return null;
    final LeaderboardCopy copy = LeaderboardCopy.of(context);
    final bool disconnected =
        state.status == LeaderboardViewStatus.authPrompt ||
        state.status == LeaderboardViewStatus.offlineCache ||
        state.status == LeaderboardViewStatus.offlineNoCache;
    if (score?.state == SubmissionState.permanentlyFailed ||
        receipt?.status == SubmissionAttemptStatus.failed) {
      return _withAchievedScore(
        context,
        LeaderboardSubmissionPanel(
          presentation: LeaderboardSubmissionPresentation.failed,
          reason: copy.permanentFailureReason(
            score?.reasonCode ?? receipt?.reasonCode,
          ),
          onAction: disconnected
              ? () => _showAuthDialog(context)
              : onRetrySubmission,
          actionLabel: disconnected ? copy.reconnect : copy.retrySubmission,
          actionKey: disconnected
              ? const Key('leaderboard-submit-connect')
              : const Key('leaderboard-submit-retry'),
        ),
      );
    }
    if (receipt?.status == SubmissionAttemptStatus.persistFailed) {
      return _withAchievedScore(
        context,
        LeaderboardSubmissionPanel(
          presentation: LeaderboardSubmissionPresentation.failed,
          reason: copy.submissionPersistFailedMessage,
        ),
      );
    }
    if (score?.state == SubmissionState.pending ||
        receipt?.status == SubmissionAttemptStatus.pending) {
      return _withAchievedScore(
        context,
        const LeaderboardSubmissionPanel(
          presentation: LeaderboardSubmissionPresentation.pending,
        ),
      );
    }
    if (receipt?.status == SubmissionAttemptStatus.accepted) {
      return _withAchievedScore(
        context,
        const LeaderboardSubmissionPanel(
          presentation: LeaderboardSubmissionPresentation.sent,
        ),
      );
    }
    if (receipt?.status == SubmissionAttemptStatus.notQueued &&
        receipt?.reasonCode != GameServicesFailureCode.unauthenticated.name) {
      return _withAchievedScore(
        context,
        LeaderboardSubmissionPanel(
          presentation: LeaderboardSubmissionPresentation.notQueued,
          reason: copy.submissionNotQueuedMessage,
        ),
      );
    }
    if (disconnected) {
      final bool offline = state.status != LeaderboardViewStatus.authPrompt;
      return _withAchievedScore(
        context,
        LeaderboardSubmissionPanel(
          presentation: LeaderboardSubmissionPresentation.unconnected,
          onAction: () => _showAuthDialog(context),
          actionLabel: offline ? copy.reconnect : copy.submitScore,
        ),
      );
    }
    return _withAchievedScore(
      context,
      LeaderboardSubmissionPanel(
        presentation: LeaderboardSubmissionPresentation.notQueued,
        reason: copy.submissionNotQueuedMessage,
      ),
    );
  }

  Widget _withAchievedScore(BuildContext context, Widget status) {
    final int? score = achievedScore;
    if (score == null) return status;
    final LeaderboardCopy copy = LeaderboardCopy.of(context);
    return Column(
      children: <Widget>[
        BbBadge(
          key: const Key('leaderboard-achieved-score'),
          copy.achievedScore(formatLeaderboardScore(context, score)),
          color: BbTokens.karstTeal,
          fg: BbTokens.cream,
        ),
        const SizedBox(height: BbTokens.sp2),
        status,
      ],
    );
  }

  Future<void> _showAuthDialog(BuildContext context) async {
    final bool? accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => LeaderboardAuthDialog(
        onConnect: () => Navigator.of(dialogContext).pop(true),
        onLater: () => Navigator.of(dialogContext).pop(false),
      ),
    );
    if (!context.mounted) return;
    if (accepted != true) {
      (onAuthDismissed ?? onBack).call();
      return;
    }
    final bool authenticated =
        await (onAuthenticate?.call() ?? Future<bool>.value(false));
    if (!context.mounted) return;
    if (!authenticated) (onAuthDismissed ?? onBack).call();
  }
}

class _LeaderboardHeader extends StatelessWidget {
  const _LeaderboardHeader({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      BbIconButton(
        key: const Key('leaderboard-back'),
        icon: Icons.arrow_back_rounded,
        onPressed: onBack,
        variant: BbVariant.karst,
        semanticLabel: LeaderboardCopy.of(context).back,
      ),
      const SizedBox(width: BbTokens.sp2),
      Expanded(
        child: BbCard(
          color: BbTokens.karstTeal,
          borderColor: BbTokens.karstBronze,
          shadowColor: const Color(0xFF3D210E),
          radius: BbTokens.rMd,
          padding: const EdgeInsets.symmetric(
            horizontal: BbTokens.sp2,
            vertical: BbTokens.sp2,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                title,
                maxLines: 2,
                textAlign: TextAlign.center,
                style: BbText.h2(BbTokens.cream).copyWith(
                  fontSize: 22,
                  height: 1,
                  shadows: const <Shadow>[
                    Shadow(color: Color(0xFF3D210E), offset: Offset(0, 3)),
                  ],
                ),
              ),
              const SizedBox(height: BbTokens.sp1),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: BbText.small(
                  const Color(0xFFFFE2A0),
                ).copyWith(fontWeight: FontWeight.w800, height: 1.1),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(width: BbTokens.sp2),
      const SizedBox(width: BbTokens.tapMin),
    ],
  );
}

class LeaderboardLoadedContent extends StatelessWidget {
  const LeaderboardLoadedContent({
    super.key,
    required this.page,
    this.avatarLoader,
    this.header,
    this.footer,
  });

  final LeaderboardPage page;
  final PlatformAvatarLoader? avatarLoader;
  final Widget? header;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final LeaderboardEntry? suppliedCurrent = page.currentPlayer;
    final List<LeaderboardEntry> rawLeaders = page.leaders
        .take(100)
        .toList(growable: false);
    String? currentPlayerId = suppliedCurrent?.playerId;
    if (currentPlayerId == null) {
      for (final LeaderboardEntry entry in rawLeaders) {
        if (entry.isCurrentPlayer) {
          currentPlayerId = entry.playerId;
          break;
        }
      }
    }
    bool currentMarked = false;
    final List<LeaderboardEntry> leaders = rawLeaders
        .map((entry) {
          final bool isCurrent =
              !currentMarked &&
              currentPlayerId != null &&
              entry.playerId == currentPlayerId;
          if (isCurrent) currentMarked = true;
          if (entry.isCurrentPlayer == isCurrent) return entry;
          return LeaderboardEntry(
            rank: entry.rank,
            playerId: entry.playerId,
            displayName: entry.displayName,
            score: entry.score,
            isCurrentPlayer: isCurrent,
            avatar: entry.avatar,
          );
        })
        .toList(growable: false);
    final bool currentInLeaders = leaders.any(
      (LeaderboardEntry entry) => entry.isCurrentPlayer,
    );
    final LeaderboardEntry? outsideCurrent =
        suppliedCurrent != null && !currentInLeaders ? suppliedCurrent : null;
    final List<LeaderboardEntry> podium = leaders
        .take(3)
        .toList(growable: false);
    final List<LeaderboardEntry> remainder = leaders
        .skip(3)
        .toList(growable: false);

    return SingleChildScrollView(
      key: const Key('leaderboard-scroll'),
      padding: const EdgeInsets.only(
        left: BbTokens.sp1,
        right: BbTokens.sp1,
        bottom: BbTokens.sp4,
      ),
      child: Column(
        children: <Widget>[
          if (header != null) ...<Widget>[
            header!,
            const SizedBox(height: BbTokens.sp4),
          ],
          LeaderboardPodium(entries: podium, avatarLoader: avatarLoader),
          if (podium.isNotEmpty) const SizedBox(height: BbTokens.sp4),
          LeaderboardRankList(entries: remainder, avatarLoader: avatarLoader),
          if (outsideCurrent != null) ...<Widget>[
            const SizedBox(height: BbTokens.sp4),
            LeaderboardCurrentPlayer(
              entry: outsideCurrent,
              avatarLoader: avatarLoader,
            ),
          ],
          if (footer != null) ...<Widget>[
            const SizedBox(height: BbTokens.sp4),
            footer!,
          ],
        ],
      ),
    );
  }
}
