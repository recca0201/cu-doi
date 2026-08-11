import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/bb_theme.dart';
import '../../core/bb_tokens.dart';
import '../../core/platform_avatar.dart';
import '../../domain/leaderboard_models.dart';
import '../../l10n/app_localizations.dart';
import 'bb_widgets.dart';

/// Typed adapter around generated ARB copy for the leaderboard component family.
class LeaderboardCopy {
  const LeaderboardCopy._(this._l10n);

  factory LeaderboardCopy.of(BuildContext context) =>
      LeaderboardCopy._(AppLocalizations.of(context));

  final AppLocalizations _l10n;

  String get title => _l10n.leaderboardTitle;
  String level(int arenaId, String arenaName) =>
      _l10n.leaderboardLevel(arenaId, arenaName);
  String get global => _l10n.leaderboardGlobal;
  String get friends => _l10n.leaderboardFriends;
  String get allTime => _l10n.leaderboardAllTime;
  String get you => _l10n.leaderboardYou;
  String get outsideTop => _l10n.leaderboardOutsideTop100;
  String selected(bool value) =>
      value ? _l10n.leaderboardSelected : _l10n.leaderboardNotSelected;
  String scopeLabel(LeaderboardScope scope) =>
      scope == LeaderboardScope.global ? global : friends;
  String scopeAnnouncement(LeaderboardScope scope) =>
      _l10n.leaderboardScopeAnnouncement(scopeLabel(scope));
  String loadedAnnouncement(int arenaId, LeaderboardScope scope) =>
      _l10n.leaderboardLoadedAnnouncement(scopeLabel(scope), arenaId);
  String get leadersLabel => _l10n.leaderboardTopThreeLabel;
  String get listLabel => _l10n.leaderboardListFromRankLabel(4);
  String rowLabel(LeaderboardEntry entry, String score) =>
      _l10n.leaderboardRowSemantics(entry.rank, entry.displayName, score);
  String get currentSuffix => _l10n.leaderboardCurrentPlayerSuffix;

  String loadingAnnouncement(int arenaId) =>
      _l10n.leaderboardLoadingAnnouncement(arenaId);
  String get loadingTitle => _l10n.leaderboardLoadingTitle;
  String get loadingBadge => _l10n.leaderboardLoadingBadge;
  String emptyTitle(int arenaId) => _l10n.leaderboardEmptyTitle(arenaId);
  String emptyMessage(LeaderboardScope scope) =>
      _l10n.leaderboardEmptyMessage(scopeLabel(scope));
  String get serviceErrorTitle => _l10n.leaderboardServiceErrorTitle;
  String get serviceErrorMessage => _l10n.leaderboardServiceErrorMessage;
  String get serviceErrorBadge => _l10n.leaderboardServiceErrorBadge;
  String get retry => _l10n.leaderboardRetryCta;
  String get back => _l10n.backCta;
  String get staleTitle => _l10n.leaderboardStaleTitle;
  String staleMessage(int arenaId, LeaderboardScope scope) =>
      _l10n.leaderboardStaleMessage(scopeLabel(scope), arenaId);
  String get offlineBadge => _l10n.leaderboardOfflineBadge;
  String get offlineQueueMessage => _l10n.leaderboardOfflineQueueMessage;
  String get offlineEmptyTitle => _l10n.leaderboardOfflineEmptyTitle;
  String offlineEmptyMessage(int arenaId, LeaderboardScope scope) =>
      _l10n.leaderboardOfflineEmptyMessage(arenaId, scopeLabel(scope));
  String get friendsUnavailableTitle =>
      _l10n.leaderboardFriendsUnavailableTitle;
  String get friendsUnavailableMessage =>
      _l10n.leaderboardFriendsUnavailableMessage;
  String get viewGlobal => _l10n.leaderboardViewGlobalCta;
  String get authTitle => _l10n.leaderboardAuthTitle;
  String get authDescription => _l10n.leaderboardAuthDescription;
  String get authConnect => _l10n.leaderboardAuthConnectCta;
  String get authLater => _l10n.leaderboardAuthLaterCta;
  String get authPromptMessage => _l10n.leaderboardAuthPromptMessage;
  String get submissionTitle => _l10n.leaderboardSubmissionTitle;
  String get submissionSent => _l10n.leaderboardSubmissionSent;
  String get submissionSentMessage => _l10n.leaderboardSubmissionSentMessage;
  String get submissionPending => _l10n.leaderboardSubmissionPending;
  String get submissionPendingMessage =>
      _l10n.leaderboardSubmissionPendingMessage;
  String get submissionFailed => _l10n.leaderboardSubmissionFailed;
  String get submissionNotQueued => _l10n.leaderboardSubmissionNotQueued;
  String get submissionNotQueuedMessage =>
      _l10n.leaderboardSubmissionNotQueuedMessage;
  String get submissionPersistFailedMessage =>
      _l10n.leaderboardSubmissionPersistFailedMessage;
  String get submissionDisconnected => _l10n.leaderboardSubmissionDisconnected;
  String get submissionDisconnectedMessage =>
      _l10n.leaderboardSubmissionDisconnectedMessage;
  String get submitScore => _l10n.leaderboardSubmitScoreCta;
  String get reconnect => _l10n.leaderboardReconnectCta;
  String get retrySubmission => _l10n.leaderboardRetrySubmissionCta;
  String achievedScore(String score) => _l10n.leaderboardAchievedScore(score);

  String permanentFailureReason(String? reasonCode) {
    final String normalized = reasonCode?.trim().toLowerCase() ?? '';
    if (normalized == 'unsupported') {
      return _l10n.leaderboardReasonUnsupported;
    }
    if (normalized == 'restricted') {
      return _l10n.leaderboardReasonRestricted;
    }
    if (normalized == 'permanent' || normalized == 'rejected') {
      return _l10n.leaderboardReasonRejected;
    }
    return _l10n.leaderboardReasonUnknown;
  }
}

String formatLeaderboardScore(BuildContext context, int score) =>
    NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    ).format(score);

/// Global/Friends is deliberately the only interactive leaderboard filter.
class LeaderboardScopeControl extends StatelessWidget {
  const LeaderboardScopeControl({
    super.key,
    required this.scope,
    required this.onSelected,
  });

  final LeaderboardScope scope;
  final ValueChanged<LeaderboardScope> onSelected;

  @override
  Widget build(BuildContext context) {
    final LeaderboardCopy copy = LeaderboardCopy.of(context);
    return BbCard(
      color: BbTokens.karstDeep,
      borderColor: BbTokens.karstBronze,
      shadowColor: BbTokens.outlineDark,
      radius: 19,
      padding: const EdgeInsets.all(BbTokens.sp1),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _ScopeOption(
              key: const Key('leaderboard-scope-global'),
              label: copy.global,
              icon: Icons.public_rounded,
              selected: scope == LeaderboardScope.global,
              selectedCopy: copy.selected(scope == LeaderboardScope.global),
              onTap: () => onSelected(LeaderboardScope.global),
            ),
          ),
          const SizedBox(width: BbTokens.sp1),
          Expanded(
            child: _ScopeOption(
              key: const Key('leaderboard-scope-friends'),
              label: copy.friends,
              icon: Icons.people_alt_rounded,
              selected: scope == LeaderboardScope.friends,
              selectedCopy: copy.selected(scope == LeaderboardScope.friends),
              onTap: () => onSelected(LeaderboardScope.friends),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScopeOption extends StatelessWidget {
  const _ScopeOption({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.selectedCopy,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final String selectedCopy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    button: true,
    selected: selected,
    label: '$label, $selectedCopy',
    onTap: onTap,
    child: ExcludeSemantics(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: onTap,
        child: AnimatedContainer(
          duration: BbTokens.durFast,
          constraints: const BoxConstraints(minHeight: BbTokens.tapMin),
          padding: const EdgeInsets.symmetric(
            horizontal: BbTokens.sp2,
            vertical: BbTokens.sp2,
          ),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF15947F) : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: selected ? BbTokens.primaryGold : Colors.transparent,
              width: BbTokens.bd2,
            ),
            boxShadow: selected
                ? BbTokens.sticker(BbTokens.stickerSm, const Color(0xFF3D210E))
                : const <BoxShadow>[],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, size: 21, color: BbTokens.cream),
              const SizedBox(width: BbTokens.sp1),
              Flexible(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: BbText.button(BbTokens.cream).copyWith(fontSize: 15),
                ),
              ),
              if (selected) ...<Widget>[
                const SizedBox(width: BbTokens.sp1),
                const Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: BbTokens.primaryGold,
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

class LeaderboardPeriodLabel extends StatelessWidget {
  const LeaderboardPeriodLabel({super.key});

  @override
  Widget build(BuildContext context) {
    final String label = LeaderboardCopy.of(context).allTime;
    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Expanded(child: _BronzeRule()),
            const SizedBox(width: BbTokens.sp2),
            const Icon(
              Icons.schedule_rounded,
              color: BbTokens.karstTeal,
              size: 21,
            ),
            const SizedBox(width: BbTokens.sp1),
            Flexible(
              child: Text(
                label,
                maxLines: 2,
                textAlign: TextAlign.center,
                style: BbText.button(BbTokens.karstTeal).copyWith(fontSize: 15),
              ),
            ),
            const SizedBox(width: BbTokens.sp2),
            const Expanded(child: _BronzeRule()),
          ],
        ),
      ),
    );
  }
}

class _BronzeRule extends StatelessWidget {
  const _BronzeRule();

  @override
  Widget build(BuildContext context) => Container(
    height: 1.5,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: <Color>[Colors.transparent, BbTokens.karstBronze],
      ),
    ),
  );
}

class LeaderboardStateCard extends StatelessWidget {
  const LeaderboardStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.liveLabel,
    this.badge,
    this.badgeColor = BbTokens.karstBronze,
    this.accentColor = BbTokens.karstBronze,
    this.busy = false,
    this.actions = const <Widget>[],
    this.extra,
  });

  final IconData icon;
  final String title;
  final String message;
  final String liveLabel;
  final String? badge;
  final Color badgeColor;
  final Color accentColor;
  final bool busy;
  final List<Widget> actions;
  final Widget? extra;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    child: BbCard(
      color: BbTokens.karstTeal,
      borderColor: accentColor,
      shadowColor: const Color(0xFF3D210E),
      padding: const EdgeInsets.all(BbTokens.sp3),
      radius: 18,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Semantics(
            liveRegion: true,
            label: liveLabel,
            child: ExcludeSemantics(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        width: BbTokens.tapMin,
                        height: BbTokens.tapMin,
                        decoration: BoxDecoration(
                          color: BbTokens.karstDeep,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: accentColor, width: 2),
                        ),
                        child: Icon(icon, color: BbTokens.cream, size: 27),
                      ),
                      const SizedBox(width: BbTokens.sp2),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(title, style: BbText.h3(BbTokens.cream)),
                            const SizedBox(height: BbTokens.sp1),
                            Text(
                              message,
                              style: BbText.small(BbTokens.cream).copyWith(
                                fontWeight: FontWeight.w700,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (badge != null) ...<Widget>[
                    const SizedBox(height: BbTokens.sp3),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: BbBadge(
                        badge!,
                        color: badgeColor,
                        fg: badgeColor.computeLuminance() > .55
                            ? BbTokens.outlineDark
                            : BbTokens.cream,
                      ),
                    ),
                  ],
                  if (busy) ...<Widget>[
                    const SizedBox(height: BbTokens.sp3),
                    const LinearProgressIndicator(
                      minHeight: 8,
                      color: BbTokens.primaryGold,
                      backgroundColor: BbTokens.karstDeep,
                      borderRadius: BorderRadius.all(Radius.circular(99)),
                    ),
                    const SizedBox(height: BbTokens.sp2),
                    for (int i = 0; i < 3; i++)
                      Container(
                        height: 48,
                        margin: const EdgeInsets.only(bottom: BbTokens.sp2),
                        decoration: BoxDecoration(
                          color: BbTokens.karstDeep.withValues(alpha: .48),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: BbTokens.karstBronze),
                        ),
                      ),
                  ],
                  if (extra != null) ...<Widget>[
                    const SizedBox(height: BbTokens.sp3),
                    extra!,
                  ],
                ],
              ),
            ),
          ),
          if (actions.isNotEmpty) ...<Widget>[
            const SizedBox(height: BbTokens.sp3),
            for (int index = 0; index < actions.length; index++) ...<Widget>[
              SizedBox(width: double.infinity, child: actions[index]),
              if (index != actions.length - 1)
                const SizedBox(height: BbTokens.sp2),
            ],
          ],
        ],
      ),
    ),
  );
}

enum LeaderboardSubmissionPresentation {
  sent,
  pending,
  failed,
  notQueued,
  unconnected,
}

class LeaderboardSubmissionPanel extends StatelessWidget {
  const LeaderboardSubmissionPanel({
    super.key,
    required this.presentation,
    this.reason,
    this.onAction,
    this.actionLabel,
    this.actionKey,
  });

  final LeaderboardSubmissionPresentation presentation;
  final String? reason;
  final VoidCallback? onAction;
  final String? actionLabel;
  final Key? actionKey;

  @override
  Widget build(BuildContext context) {
    final LeaderboardCopy copy = LeaderboardCopy.of(context);
    final (IconData, String, String, Color) content = switch (presentation) {
      LeaderboardSubmissionPresentation.sent => (
        Icons.check_circle_rounded,
        copy.submissionSent,
        copy.submissionSentMessage,
        const Color(0xFF31C48D),
      ),
      LeaderboardSubmissionPresentation.pending => (
        Icons.schedule_rounded,
        copy.submissionPending,
        copy.submissionPendingMessage,
        BbTokens.primaryGold,
      ),
      LeaderboardSubmissionPresentation.failed => (
        Icons.error_outline_rounded,
        copy.submissionFailed,
        reason ?? copy.permanentFailureReason(null),
        BbTokens.dangerRed,
      ),
      LeaderboardSubmissionPresentation.notQueued => (
        Icons.info_outline_rounded,
        copy.submissionNotQueued,
        reason ?? copy.submissionNotQueuedMessage,
        BbTokens.karstBronze,
      ),
      LeaderboardSubmissionPresentation.unconnected => (
        Icons.link_off_rounded,
        copy.submissionDisconnected,
        copy.submissionDisconnectedMessage,
        BbTokens.karstBronze,
      ),
    };
    return Semantics(
      container: true,
      child: BbCard(
        color: BbTokens.karstDeep,
        borderColor: content.$4,
        shadowColor: const Color(0xFF3D210E),
        padding: const EdgeInsets.all(BbTokens.sp3),
        radius: 17,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Semantics(
              liveRegion: true,
              label: '${copy.submissionTitle}: ${content.$2}. ${content.$3}',
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      copy.submissionTitle,
                      style: BbText.h3(BbTokens.cream),
                    ),
                    const SizedBox(height: BbTokens.sp2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Icon(content.$1, color: content.$4, size: 28),
                        const SizedBox(width: BbTokens.sp2),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                content.$2,
                                style: BbText.button(BbTokens.cream),
                              ),
                              const SizedBox(height: BbTokens.sp1),
                              Text(
                                content.$3,
                                style: BbText.small(
                                  BbTokens.cream,
                                ).copyWith(height: 1.25),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (onAction != null && actionLabel != null) ...<Widget>[
              const SizedBox(height: BbTokens.sp3),
              BbButton.karst(
                key:
                    actionKey ??
                    (presentation == LeaderboardSubmissionPresentation.failed
                        ? const Key('leaderboard-submit-retry')
                        : const Key('leaderboard-submit-connect')),
                label: actionLabel!,
                icon: presentation == LeaderboardSubmissionPresentation.failed
                    ? Icons.refresh_rounded
                    : Icons.link_rounded,
                onPressed: onAction,
                expand: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class LeaderboardAuthDialog extends StatelessWidget {
  const LeaderboardAuthDialog({
    super.key,
    required this.onConnect,
    required this.onLater,
  });

  final VoidCallback onConnect;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    final LeaderboardCopy copy = LeaderboardCopy.of(context);
    return PopScope(
      canPop: false,
      child: Dialog(
        key: const Key('leaderboard-auth-dialog'),
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(BbTokens.sp3),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: BbCard(
            color: BbTokens.karstTeal,
            borderColor: BbTokens.karstBronze,
            shadowColor: const Color(0xFF3D210E),
            padding: const EdgeInsets.all(BbTokens.sp4),
            radius: 22,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.emoji_events_rounded,
                  color: BbTokens.primaryGold,
                  size: 52,
                ),
                const SizedBox(height: BbTokens.sp2),
                Text(
                  copy.authTitle,
                  textAlign: TextAlign.center,
                  style: BbText.h2(BbTokens.cream),
                ),
                const SizedBox(height: BbTokens.sp2),
                Text(
                  copy.authDescription,
                  textAlign: TextAlign.center,
                  style: BbText.body(BbTokens.cream).copyWith(height: 1.3),
                ),
                const SizedBox(height: BbTokens.sp4),
                BbButton.primary(
                  key: const Key('leaderboard-auth-confirm'),
                  label: copy.authConnect,
                  icon: Icons.link_rounded,
                  onPressed: onConnect,
                  expand: true,
                ),
                const SizedBox(height: BbTokens.sp2),
                BbButton.karst(
                  key: const Key('leaderboard-auth-later'),
                  label: copy.authLater,
                  icon: Icons.schedule_rounded,
                  onPressed: onLater,
                  expand: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bounded platform avatar with a neutral, non-profile fallback.
class LeaderboardAvatar extends StatelessWidget {
  const LeaderboardAvatar({
    super.key,
    required this.entry,
    this.loader,
    this.size = 44,
    this.borderColor = BbTokens.karstBronze,
  });

  final LeaderboardEntry entry;
  final PlatformAvatarLoader? loader;
  final double size;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final PlatformAvatarRef? avatar = entry.avatar;
    if (avatar == null || loader == null) return _fallback();
    return FutureBuilder<Uint8List?>(
      future: loader!.loadForRow(
        avatar,
        identityEpoch: avatar.identityEpoch,
        playerHash: avatar.playerHash,
      ),
      builder: (BuildContext context, AsyncSnapshot<Uint8List?> snapshot) {
        final Uint8List? bytes = snapshot.data;
        if (bytes == null) return _fallback();
        return _frame(
          Image.memory(
            bytes,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            excludeFromSemantics: true,
          ),
        );
      },
    );
  }

  Widget _fallback() => KeyedSubtree(
    key: ValueKey<String>('leaderboard-avatar-fallback-${entry.playerId}'),
    child: _frame(
      Icon(
        Icons.person_rounded,
        color: const Color(0xFF3D352C),
        size: size * .58,
      ),
    ),
  );

  Widget _frame(Widget child) => Container(
    width: size,
    height: size,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[Color(0xFFFFE2A0), Color(0xFF806B57)],
      ),
      border: Border.all(color: borderColor, width: 2.5),
      boxShadow: BbTokens.sticker(BbTokens.stickerSm, const Color(0xFF3D210E)),
    ),
    child: Center(child: child),
  );
}

class LeaderboardPodium extends StatelessWidget {
  const LeaderboardPodium({
    super.key,
    required this.entries,
    this.avatarLoader,
  });

  final List<LeaderboardEntry> entries;
  final PlatformAvatarLoader? avatarLoader;

  @override
  Widget build(BuildContext context) {
    final List<LeaderboardEntry> top = entries.take(3).toList(growable: false);
    if (top.isEmpty) return const SizedBox.shrink();
    // Keep every platform row and its authoritative rank, including ties.
    // The second returned row sits left of the leader to match the approved
    // podium composition; this is presentation order, never app-side ranking.
    final List<LeaderboardEntry> ordered = top.length == 1
        ? top
        : <LeaderboardEntry>[top[1], top[0], if (top.length == 3) top[2]];
    return Semantics(
      container: true,
      label: LeaderboardCopy.of(context).leadersLabel,
      child: Row(
        key: const Key('leaderboard-podium'),
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          for (int index = 0; index < ordered.length; index++) ...<Widget>[
            if (index > 0) const SizedBox(width: BbTokens.sp2),
            Expanded(
              child: LeaderboardPodiumCard(
                entry: ordered[index],
                avatarLoader: avatarLoader,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class LeaderboardPodiumCard extends StatelessWidget {
  const LeaderboardPodiumCard({
    super.key,
    required this.entry,
    this.avatarLoader,
  });

  final LeaderboardEntry entry;
  final PlatformAvatarLoader? avatarLoader;

  @override
  Widget build(BuildContext context) {
    final bool first = entry.rank == 1;
    final Color medal = switch (entry.rank) {
      1 => BbTokens.primaryGold,
      2 => const Color(0xFFB8C8C9),
      _ => BbTokens.karstBronze,
    };
    final String score = formatLeaderboardScore(context, entry.score);
    final LeaderboardCopy copy = LeaderboardCopy.of(context);
    Widget card = Semantics(
      container: true,
      label:
          '${copy.rowLabel(entry, score)}${entry.isCurrentPlayer ? ', ${copy.currentSuffix}' : ''}',
      child: ExcludeSemantics(
        child: Padding(
          padding: EdgeInsets.only(top: first ? 0 : 13),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: first ? 54 : 46,
                height: first ? 42 : 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: medal,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: BbTokens.outlineDark, width: 2.5),
                  boxShadow: BbTokens.sticker(3, const Color(0xFF3D210E)),
                ),
                child: Text(
                  '${entry.rank}',
                  style: BbText.h2(
                    first ? const Color(0xFF3D210E) : BbTokens.cream,
                  ).copyWith(fontSize: first ? 25 : 21),
                ),
              ),
              LeaderboardAvatar(
                entry: entry,
                loader: avatarLoader,
                size: first ? 68 : 56,
                borderColor: medal,
              ),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 70),
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 7),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[Color(0xFF0A6A5B), BbTokens.karstDeep],
                  ),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: entry.isCurrentPlayer ? BbTokens.primaryGold : medal,
                    width: entry.isCurrentPlayer ? 3 : 2,
                  ),
                  boxShadow: BbTokens.sticker(3, const Color(0xFF3D210E)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    if (entry.isCurrentPlayer)
                      BbBadge(
                        copy.you,
                        color: BbTokens.primaryGold,
                        fg: BbTokens.outlineDark,
                      ),
                    Text(
                      entry.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: BbText.small(
                        BbTokens.cream,
                      ).copyWith(fontWeight: FontWeight.w800, height: 1.1),
                    ),
                    Text(
                      score,
                      maxLines: 1,
                      style:
                          BbText.h3(
                            first ? BbTokens.primaryGold : BbTokens.cream,
                          ).copyWith(
                            fontSize: 16,
                            fontFeatures: const <FontFeature>[
                              FontFeature.tabularFigures(),
                            ],
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    card = KeyedSubtree(
      key: ValueKey<String>('leaderboard-entry-${entry.playerId}'),
      child: card,
    );
    return entry.isCurrentPlayer
        ? KeyedSubtree(
            key: const Key('leaderboard-current-player'),
            child: card,
          )
        : card;
  }
}

class LeaderboardRankList extends StatelessWidget {
  const LeaderboardRankList({
    super.key,
    required this.entries,
    this.avatarLoader,
  });

  final List<LeaderboardEntry> entries;
  final PlatformAvatarLoader? avatarLoader;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    return Semantics(
      container: true,
      label: LeaderboardCopy.of(context).listLabel,
      child: BbCard(
        color: BbTokens.karstTeal,
        borderColor: BbTokens.karstBronze,
        shadowColor: const Color(0xFF3D210E),
        padding: EdgeInsets.zero,
        radius: 17,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Column(
            children: <Widget>[
              for (int index = 0; index < entries.length; index++) ...<Widget>[
                LeaderboardRankRow(
                  entry: entries[index],
                  avatarLoader: avatarLoader,
                ),
                if (index != entries.length - 1)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: BbTokens.karstBronze,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class LeaderboardRankRow extends StatelessWidget {
  const LeaderboardRankRow({
    super.key,
    required this.entry,
    this.avatarLoader,
    this.separateCurrentPlayer = false,
  });

  final LeaderboardEntry entry;
  final PlatformAvatarLoader? avatarLoader;
  final bool separateCurrentPlayer;

  @override
  Widget build(BuildContext context) {
    final String score = formatLeaderboardScore(context, entry.score);
    final LeaderboardCopy copy = LeaderboardCopy.of(context);
    final bool current = entry.isCurrentPlayer || separateCurrentPlayer;
    Widget row = Semantics(
      container: true,
      label:
          '${copy.rowLabel(entry, score)}${current ? ', ${copy.currentSuffix}' : ''}',
      child: ExcludeSemantics(
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(
            horizontal: BbTokens.sp2,
            vertical: BbTokens.sp2,
          ),
          decoration: BoxDecoration(
            gradient: current
                ? const LinearGradient(
                    colors: <Color>[Color(0xFF15947F), BbTokens.karstTeal],
                  )
                : null,
            border: current
                ? Border.all(color: BbTokens.primaryGold, width: 3)
                : null,
            borderRadius: current ? BorderRadius.circular(14) : null,
          ),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 38,
                child: Text(
                  '${entry.rank}',
                  textAlign: TextAlign.center,
                  style: BbText.h3(BbTokens.cream).copyWith(
                    fontSize: 19,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: BbTokens.sp2),
              LeaderboardAvatar(entry: entry, loader: avatarLoader),
              const SizedBox(width: BbTokens.sp3),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (current)
                      Padding(
                        padding: const EdgeInsets.only(bottom: BbTokens.sp1),
                        child: BbBadge(
                          copy.you,
                          color: BbTokens.primaryGold,
                          fg: BbTokens.outlineDark,
                        ),
                      ),
                    Text(
                      entry.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: BbText.body(
                        BbTokens.cream,
                      ).copyWith(fontWeight: FontWeight.w800, height: 1.15),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: BbTokens.sp2),
              Text(
                score,
                maxLines: 1,
                textAlign: TextAlign.right,
                style:
                    BbText.h3(
                      current ? BbTokens.primaryGold : BbTokens.cream,
                    ).copyWith(
                      fontSize: 17,
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
              ),
            ],
          ),
        ),
      ),
    );
    row = KeyedSubtree(
      key: ValueKey<String>('leaderboard-entry-${entry.playerId}'),
      child: row,
    );
    return current
        ? KeyedSubtree(key: const Key('leaderboard-current-player'), child: row)
        : row;
  }
}

class LeaderboardCurrentPlayer extends StatelessWidget {
  const LeaderboardCurrentPlayer({
    super.key,
    required this.entry,
    this.avatarLoader,
  });

  final LeaderboardEntry entry;
  final PlatformAvatarLoader? avatarLoader;

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      BbCard(
        color: BbTokens.karstTeal,
        borderColor: BbTokens.primaryGold,
        shadowColor: const Color(0xFF3D210E),
        padding: EdgeInsets.zero,
        radius: 17,
        child: LeaderboardRankRow(
          entry: entry,
          avatarLoader: avatarLoader,
          separateCurrentPlayer: true,
        ),
      ),
      const SizedBox(height: BbTokens.sp2),
      Text(
        LeaderboardCopy.of(context).outsideTop,
        textAlign: TextAlign.center,
        style: BbText.small(BbTokens.cream).copyWith(
          fontWeight: FontWeight.w800,
          shadows: const <Shadow>[
            Shadow(color: BbTokens.outlineDark, offset: Offset(0, 2)),
          ],
        ),
      ),
    ],
  );
}
