import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/bb_tokens.dart';
import '../../core/bb_theme.dart';
import '../../domain/profile_summary.dart';
import '../../sim/arenas.dart';
import '../../l10n/app_localizations.dart';
import '../../state/profile_controller.dart';
import '../../state/account_controller.dart';
import '../../state/providers.dart';
import '../widgets/bb_backdrop.dart';
import '../widgets/bb_widgets.dart';
import '../widgets/player_avatar.dart';
import 'avatar_editor_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, this.focusAccount = false});
  final bool focusAccount;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final profile = ref.watch(profileProvider);
    final progress = ref.watch(progressProvider);
    final account = ref.watch(accountProvider);
    final summary = ProfileSummary.fromProgress(progress);
    return Scaffold(
      backgroundColor: BbTokens.karstDeep,
      body: Stack(
        children: [
          const Positioned.fill(
            child: BbCanyonBackdrop(scrim: .65, bottomShade: .8),
          ),
          SafeArea(
            child: Column(
              children: [
                SizedBox(
                  height: 56,
                  child: Row(
                    children: [
                      IconButton(
                        key: const Key('profile-back'),
                        tooltip: t.backCta,
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          t.profileTitle,
                          textAlign: TextAlign.center,
                          style: BbText.h2(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Expanded(
                  child: profile.restoring
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 440),
                              child: Column(
                                children: [
                                  BbCard(
                                    child: Column(
                                      children: [
                                        PlayerAvatar(
                                          avatar: profile.profile.avatar,
                                          size: 92,
                                          onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const AvatarEditorScreen(),
                                            ),
                                          ),
                                          semanticLabel: t.changeAvatarCta,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          profile.profile.displayName(
                                            t.defaultPlayerName,
                                          ),
                                          key: const Key('profile-name'),
                                          style: BbText.h2(Colors.white),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              _editName(context, ref, profile),
                                          child: Text(t.editNameCta),
                                        ),
                                        Text(
                                          account.phase == AccountPhase.guest
                                              ? t.guestStatus
                                              : account.phase ==
                                                    AccountPhase.deletionPending
                                              ? t.accountPending
                                              : account.phase ==
                                                    AccountPhase
                                                        .providerRecoveryRequired
                                              ? t.accountRecovery
                                              : account.phase ==
                                                    AccountPhase.deleted
                                              ? t.accountDeleted
                                              : t.signedInStatus,
                                          style: BbText.small(
                                            BbTokens.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _Metrics(summary: summary, t: t),
                                  if (summary.completedLevels == 0)
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Text(
                                        t.profileEncouragement,
                                        style: BbText.body(Colors.white),
                                      ),
                                    ),
                                  const SizedBox(height: 12),
                                  ...summary.chapters.map(
                                    (c) => _ChapterPanel(
                                      chapter: c,
                                      summary: summary,
                                      t: t,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _Badges(summary: summary, t: t),
                                  const SizedBox(height: 12),
                                  _AccountCard(account: account, t: t),
                                ],
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editName(
    BuildContext context,
    WidgetRef ref,
    ProfileState state,
  ) async {
    final controller = TextEditingController(
      text: state.profile.customDisplayName ?? '',
    );
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).editNameCta),
        content: TextField(
          controller: controller,
          maxLength: 40,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).cancelCta),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(AppLocalizations.of(context).saveCta),
          ),
        ],
      ),
    );
    if (value == null) return;
    final ok = await ref.read(profileProvider.notifier).saveName(value);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).invalidNameError)),
      );
    }
  }
}

class _Badges extends StatelessWidget {
  const _Badges({required this.summary, required this.t});
  final ProfileSummary summary;
  final AppLocalizations t;
  @override
  Widget build(BuildContext context) => BbCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.badgesTitle, style: BbText.h3(Colors.white)),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: summary.badges.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemBuilder: (context, index) {
            final badge = summary.badges[index];
            return Semantics(
              label:
                  '${badge.id}, ${badge.unlocked ? t.badgeUnlocked : t.badgeLocked}, ${badge.progress}/${badge.target}',
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: badge.unlocked
                        ? BbTokens.primaryGold
                        : BbTokens.textMuted,
                    width: 2,
                  ),
                ),
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Icon(
                      badge.unlocked
                          ? Icons.workspace_premium
                          : Icons.lock_outline,
                      color: badge.unlocked
                          ? BbTokens.primaryGold
                          : BbTokens.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${badge.id}\n${badge.progress}/${badge.target}',
                        maxLines: 2,
                        style: BbText.tiny(Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    ),
  );
}

class _AccountCard extends ConsumerWidget {
  const _AccountCard({required this.account, required this.t});
  final AccountState account;
  final AppLocalizations t;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(accountProvider.notifier);
    return BbCard(
      key: const Key('profile-account-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.accountTitle, style: BbText.h3(Colors.white)),
          const SizedBox(height: 8),
          Text(
            account.phase == AccountPhase.guest
                ? t.guestAccountBody
                : account.phase == AccountPhase.deletionPending
                ? '${t.accountPending}\n${account.requestId ?? ''}'
                : account.phase == AccountPhase.providerRecoveryRequired
                ? '${t.accountRecovery}\n${account.requestId ?? ''}'
                : account.phase == AccountPhase.deleted
                ? t.accountDeleted
                : '${t.signedInStatus}: ${account.providers.map((p) => p.name).join(', ')}',
            style: BbText.body(BbTokens.textMuted),
          ),
          const SizedBox(height: 12),
          if (!account.isAuthenticated &&
              account.phase != AccountPhase.deletionPending) ...[
            BbButton(
              label: t.signInGoogleCta,
              expand: true,
              onPressed: () => controller.signIn(AuthProviderKind.google),
            ),
            const SizedBox(height: 8),
            BbButton(
              label: t.signInAppleCta,
              variant: BbVariant.secondary,
              expand: true,
              onPressed: () => controller.signIn(AuthProviderKind.apple),
            ),
          ] else if (account.isAuthenticated &&
              account.phase != AccountPhase.deletionPending &&
              account.phase != AccountPhase.providerRecoveryRequired) ...[
            for (final provider in AuthProviderKind.values)
              if (!account.providers.contains(provider))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: BbButton(
                    label: provider == AuthProviderKind.google
                        ? t.signInGoogleCta
                        : t.signInAppleCta,
                    expand: true,
                    onPressed: () => controller.link(provider),
                  ),
                ),
            BbButton(
              label: t.signOutCta,
              variant: BbVariant.secondary,
              expand: true,
              onPressed: () => _confirmSignOut(context, controller),
            ),
            const SizedBox(height: 8),
            BbButton.danger(
              label: t.deleteAccountCta,
              expand: true,
              onPressed: () => _confirmDelete(context, controller),
            ),
          ] else if (account.phase == AccountPhase.deletionPending)
            BbButton(
              label: t.retryCta,
              expand: true,
              onPressed: controller.pollDeletion,
            ),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut(
    BuildContext context,
    AccountController controller,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.signOutCta),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancelCta),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.signOutCta),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.signOut();
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AccountController controller,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.deleteAccountTitle),
        content: Text(t.deleteAccountBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancelCta),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.confirmDeleteCta),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final provider = account.providers.contains(AuthProviderKind.apple)
          ? AuthProviderKind.apple
          : AuthProviderKind.google;
      await controller.requestDeletion(provider);
    }
  }
}

class _Metrics extends StatelessWidget {
  const _Metrics({required this.summary, required this.t});
  final ProfileSummary summary;
  final AppLocalizations t;
  @override
  Widget build(BuildContext context) => BbCard(
    child: Wrap(
      spacing: 18,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        _metric(t.profileStars, '${summary.totalStars}/60'),
        _metric(t.coinsLabel, '${summary.coins}'),
        _metric(t.profileCompleted, '${summary.completedLevels}/20'),
        _metric(t.bestScoreLabel, '${summary.bestScore}'),
      ],
    ),
  );
  Widget _metric(String label, String value) => SizedBox(
    width: 78,
    child: Column(
      children: [
        Text(value, style: BbText.h3(Colors.white)),
        Text(
          label,
          textAlign: TextAlign.center,
          style: BbText.tiny(BbTokens.textMuted),
        ),
      ],
    ),
  );
}

class _ChapterPanel extends StatelessWidget {
  const _ChapterPanel({
    required this.chapter,
    required this.summary,
    required this.t,
  });
  final ChapterSummary chapter;
  final ProfileSummary summary;
  final AppLocalizations t;
  @override
  Widget build(BuildContext context) => Card(
    color: const Color(0xEE073736),
    child: ExpansionTile(
      initiallyExpanded: chapter.chapter.number == 1,
      textColor: Colors.white,
      collapsedTextColor: Colors.white,
      title: Text(t.profileChapter(chapter.chapter.number)),
      subtitle: Text(
        '${chapter.completed}/5 · ${chapter.stars}/15 ${t.profileStars}',
      ),
      children: summary.records
          .where((r) => chapter.chapter.contains(r.levelId))
          .map(
            (r) => ListTile(
              title: Text(
                '${t.arenaNumberLabel(r.levelId)} · ${Localizations.localeOf(context).languageCode == 'en' ? kArenas[r.levelId - 1].nameEn : kArenas[r.levelId - 1].name}',
                style: const TextStyle(color: Colors.white),
              ),
              trailing: Text(
                r.state == LevelRecordState.completed
                    ? '${r.stars}★ · ${r.highScore}'
                    : r.state == LevelRecordState.skipped
                    ? t.arenaSkippedBadge
                    : r.state == LevelRecordState.locked
                    ? t.arenaLocked
                    : '—',
                style: TextStyle(
                  color: r.state == LevelRecordState.completed
                      ? BbTokens.primaryGold
                      : BbTokens.textMuted,
                ),
              ),
            ),
          )
          .toList(),
    ),
  );
}
