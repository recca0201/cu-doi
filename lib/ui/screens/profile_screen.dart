import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/bb_tokens.dart';
import '../../core/bb_theme.dart';
import '../../domain/player_profile.dart';
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
                BbKarstHeader(
                  titleAsset:
                      'assets/images/ui/karst/profile_title_banner_v2.png',
                  titleLabel: t.profileTitle,
                  titleKey: const Key('profile-title'),
                  backLabel: t.backCta,
                  backKey: const Key('profile-back'),
                  onBack: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: profile.restoring
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 440),
                              child: Column(
                                children: [
                                  _ProfilePanel(
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
                                            account.displayName ??
                                                t.defaultPlayerName,
                                          ),
                                          key: const Key('profile-name'),
                                          style: BbText.h2(BbTokens.cream),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        TextButton(
                                          style: TextButton.styleFrom(
                                            foregroundColor:
                                                BbTokens.primaryGold,
                                          ),
                                          onPressed: () =>
                                              _editName(context, ref, profile),
                                          child: Text(
                                            t.editNameCta,
                                            style: BbText.button(
                                              BbTokens.primaryGold,
                                            ).copyWith(fontSize: 16),
                                          ),
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
                                          textAlign: TextAlign.center,
                                          style: BbText.small(
                                            BbTokens.cream.withValues(
                                              alpha: .72,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _Metrics(summary: summary, t: t),
                                  if (summary.completedLevels == 0)
                                    Container(
                                      margin: const EdgeInsets.only(top: 12),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: BbTokens.karstDeep.withValues(
                                          alpha: .84,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: BbTokens.karstBronze
                                              .withValues(alpha: .72),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.auto_awesome_rounded,
                                            color: BbTokens.primaryGold,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              t.profileEncouragement,
                                              style: BbText.body(
                                                BbTokens.cream,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (focusAccount) ...[
                                    const SizedBox(height: 12),
                                    _AccountCard(account: account, t: t),
                                  ],
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
                                  if (!focusAccount)
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
    final value = await _showNameEditor(
      context,
      initialName: state.profile.customDisplayName ?? '',
    );
    if (value == null || !context.mounted) return;
    await _saveProfileName(context, ref, value);
  }
}

enum _GoogleNameChoice { google, custom }

Future<String?> _showNameEditor(
  BuildContext context, {
  required String initialName,
}) async {
  String draft = initialName;
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      key: const Key('profile-name-editor'),
      title: Text(AppLocalizations.of(context).editNameCta),
      content: TextFormField(
        key: const Key('profile-name-field'),
        initialValue: initialName,
        maxLength: kMaxDisplayNameGraphemes,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onChanged: (value) => draft = value,
        onFieldSubmitted: (value) => Navigator.pop(context, value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context).cancelCta),
        ),
        FilledButton(
          key: const Key('profile-name-save'),
          onPressed: () => Navigator.pop(context, draft),
          child: Text(AppLocalizations.of(context).saveCta),
        ),
      ],
    ),
  );
}

Future<bool> _saveProfileName(
  BuildContext context,
  WidgetRef ref,
  String value,
) async {
  final ok = await ref.read(profileProvider.notifier).saveName(value);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).invalidNameError)),
    );
  }
  return ok;
}

class _Badges extends StatelessWidget {
  const _Badges({required this.summary, required this.t});
  final ProfileSummary summary;
  final AppLocalizations t;
  @override
  Widget build(BuildContext context) => _ProfilePanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProfileSectionTitle(
          icon: Icons.workspace_premium_rounded,
          label: t.badgesTitle,
        ),
        const SizedBox(height: 12),
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
                  color: BbTokens.karstDeep.withValues(alpha: .72),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: badge.unlocked
                        ? BbTokens.primaryGold
                        : BbTokens.karstBronze.withValues(alpha: .42),
                    width: 1.5,
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
                          : BbTokens.cream.withValues(alpha: .42),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${badge.id}\n${badge.progress}/${badge.target}',
                        maxLines: 2,
                        style: BbText.tiny(BbTokens.cream),
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
    final bool authenticating = account.phase == AccountPhase.authenticating;
    final bool supportsAppleSignIn =
        Theme.of(context).platform != TargetPlatform.android;
    return _ProfilePanel(
      key: const Key('profile-account-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProfileSectionTitle(
            icon: Icons.account_circle_rounded,
            label: t.accountTitle,
          ),
          const SizedBox(height: 10),
          Text(
            account.phase == AccountPhase.guest
                ? t.guestAccountBody
                : authenticating
                ? t.signInProgress
                : account.phase == AccountPhase.error
                ? t.signInFailedMessage
                : account.phase == AccountPhase.deletionPending
                ? '${t.accountPending}\n${account.requestId ?? ''}'
                : account.phase == AccountPhase.providerRecoveryRequired
                ? '${t.accountRecovery}\n${account.requestId ?? ''}'
                : account.phase == AccountPhase.deleted
                ? t.accountDeleted
                : '${t.signedInStatus}: ${account.providers.map((p) => p.name).join(', ')}',
            style: BbText.body(BbTokens.cream.withValues(alpha: .72)),
          ),
          if (account.isAuthenticated && account.displayName != null) ...[
            const SizedBox(height: 8),
            Text(
              account.displayName!,
              key: const Key('account-display-name'),
              style: BbText.h3(BbTokens.cream),
            ),
          ],
          if (account.isAuthenticated && account.email != null) ...[
            const SizedBox(height: 2),
            Text(
              account.email!,
              key: const Key('account-email'),
              style: BbText.small(BbTokens.cream.withValues(alpha: .82)),
            ),
          ],
          if (authenticating) ...[
            const SizedBox(height: 10),
            const LinearProgressIndicator(
              key: Key('account-sign-in-progress'),
              color: BbTokens.primaryGold,
              backgroundColor: BbTokens.karstDeep,
            ),
          ],
          const SizedBox(height: 12),
          if (!account.isAuthenticated &&
              account.phase != AccountPhase.deletionPending) ...[
            BbButton(
              label: t.signInGoogleCta,
              expand: true,
              onPressed: authenticating
                  ? null
                  : () => _signInWithGoogleNameChoice(context, ref, controller),
            ),
            if (supportsAppleSignIn) ...[
              const SizedBox(height: 8),
              BbButton(
                label: t.signInAppleCta,
                variant: BbVariant.karst,
                expand: true,
                onPressed: authenticating
                    ? null
                    : () => controller.signIn(AuthProviderKind.apple),
              ),
            ],
          ] else if (account.isAuthenticated &&
              account.phase != AccountPhase.deletionPending &&
              account.phase != AccountPhase.providerRecoveryRequired) ...[
            for (final provider in AuthProviderKind.values)
              if (!account.providers.contains(provider) &&
                  (provider != AuthProviderKind.apple || supportsAppleSignIn))
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
              variant: BbVariant.karst,
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
            )
          else if (account.phase == AccountPhase.providerRecoveryRequired)
            BbButton(
              label: t.retryCta,
              expand: true,
              onPressed: () => controller.refreshDeletionProof(
                account.providers.contains(AuthProviderKind.apple)
                    ? AuthProviderKind.apple
                    : AuthProviderKind.google,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _signInWithGoogleNameChoice(
    BuildContext context,
    WidgetRef ref,
    AccountController controller,
  ) async {
    await controller.signIn(AuthProviderKind.google);
    if (!context.mounted) return;

    final AccountState signedIn = ref.read(accountProvider);
    if (!signedIn.isAuthenticated ||
        !signedIn.providers.contains(AuthProviderKind.google)) {
      return;
    }

    final ProfileController profile = ref.read(profileProvider.notifier);
    await profile.ready;
    if (!context.mounted) return;

    final String googleName = signedIn.displayName?.trim() ?? '';
    if (googleName.isEmpty) {
      final customName = await _showNameEditor(
        context,
        initialName: ref.read(profileProvider).profile.customDisplayName ?? '',
      );
      if (customName != null && context.mounted) {
        await _saveProfileName(context, ref, customName);
      }
      return;
    }

    final choice = await showDialog<_GoogleNameChoice>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          key: const Key('google-name-choice'),
          title: Text(t.choosePlayerNameTitle),
          content: Text(t.choosePlayerNameBody(googleName)),
          actions: [
            TextButton(
              key: const Key('google-name-custom'),
              onPressed: () => Navigator.pop(context, _GoogleNameChoice.custom),
              child: Text(t.choosePlayerNameCustomCta),
            ),
            FilledButton(
              key: const Key('google-name-use'),
              onPressed: () => Navigator.pop(context, _GoogleNameChoice.google),
              child: Text(t.choosePlayerNameUseCta),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;

    if (choice == _GoogleNameChoice.google) {
      await _saveProfileName(context, ref, googleName);
      return;
    }
    if (choice != _GoogleNameChoice.custom) return;

    final customName = await _showNameEditor(context, initialName: googleName);
    if (customName != null && context.mounted) {
      await _saveProfileName(context, ref, customName);
    }
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
  Widget build(BuildContext context) {
    final bool largeText = MediaQuery.textScalerOf(context).scale(16) > 22;
    return _ProfilePanel(
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: largeText ? 1 : 2,
        childAspectRatio: largeText ? 4 : 2.25,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        children: [
          _metric(
            Icons.star_rounded,
            t.profileStars,
            '${summary.totalStars}/60',
          ),
          _metric(Icons.paid_rounded, t.coinsLabel, '${summary.coins}'),
          _metric(
            Icons.flag_rounded,
            t.profileCompleted,
            '${summary.completedLevels}/20',
          ),
          _metric(
            Icons.military_tech_rounded,
            t.bestScoreLabel,
            '${summary.bestScore}',
          ),
        ],
      ),
    );
  }

  Widget _metric(IconData icon, String label, String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: BbTokens.karstDeep.withValues(alpha: .72),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: BbTokens.karstBronze.withValues(alpha: .46),
        width: 1.5,
      ),
    ),
    child: Row(
      children: [
        Icon(icon, color: BbTokens.primaryGold, size: 24),
        const SizedBox(width: 8),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: BbText.h3(BbTokens.cream)),
                  Text(
                    label,
                    maxLines: 1,
                    style: BbText.tiny(BbTokens.cream.withValues(alpha: .68)),
                  ),
                ],
              ),
            ),
          ),
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
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: _ProfilePanel(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: Material(
          color: Colors.transparent,
          child: ExpansionTile(
            initiallyExpanded: chapter.chapter.number == 1,
            iconColor: BbTokens.primaryGold,
            collapsedIconColor: BbTokens.karstBronze,
            textColor: BbTokens.cream,
            collapsedTextColor: BbTokens.cream,
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            title: Text(
              t.profileChapter(chapter.chapter.number),
              style: BbText.h3(BbTokens.cream),
            ),
            subtitle: Text(
              '${chapter.completed}/5 · ${chapter.stars}/15 ${t.profileStars}',
              style: BbText.small(BbTokens.cream.withValues(alpha: .68)),
            ),
            children: summary.records
                .where((r) => chapter.chapter.contains(r.levelId))
                .map(
                  (r) => Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: BbTokens.karstBronze.withValues(alpha: .24),
                        ),
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: ListTile(
                        dense: true,
                        title: Text(
                          '${t.arenaNumberLabel(r.levelId)} · ${Localizations.localeOf(context).languageCode == 'en' ? kArenas[r.levelId - 1].nameEn : kArenas[r.levelId - 1].name}',
                          style: BbText.body(BbTokens.cream),
                        ),
                        trailing: Text(
                          r.state == LevelRecordState.completed
                              ? '${r.stars}★ · ${r.highScore}'
                              : r.state == LevelRecordState.skipped
                              ? t.arenaSkippedBadge
                              : r.state == LevelRecordState.locked
                              ? t.arenaLocked
                              : '—',
                          style: BbText.small(
                            r.state == LevelRecordState.completed
                                ? BbTokens.primaryGold
                                : BbTokens.cream.withValues(alpha: .58),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    ),
  );
}

class _ProfilePanel extends StatelessWidget {
  const _ProfilePanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(BbTokens.sp5),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => BbCard(
    color: BbTokens.karstTeal,
    borderColor: BbTokens.karstBronze,
    shadowColor: BbTokens.karstShadow,
    padding: padding,
    child: child,
  );
}

class _ProfileSectionTitle extends StatelessWidget {
  const _ProfileSectionTitle({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: BbTokens.primaryGold, size: 24),
      const SizedBox(width: 8),
      Expanded(child: Text(label, style: BbText.h3(BbTokens.cream))),
    ],
  );
}
