import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/bb_theme.dart';
import '../../core/bb_tokens.dart';
import '../../data/settings_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../state/providers.dart';
import '../../state/account_controller.dart';
import '../widgets/bb_backdrop.dart';
import '../widgets/bb_widgets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations t = AppLocalizations.of(context);
    final AppSettings settings = ref.watch(settingsProvider);
    final SettingsController controller = ref.read(settingsProvider.notifier);
    final AccountState account = ref.watch(accountProvider);

    return Scaffold(
      backgroundColor: BbTokens.karstDeep,
      body: Stack(
        children: <Widget>[
          const Positioned.fill(
            child: BbCanyonBackdrop(scrim: .52, bottomShade: .72),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: BbTokens.screenMax),
                child: Column(
                  children: <Widget>[
                    _SettingsHeader(
                      title: t.settingsTitle,
                      backLabel: t.backCta,
                      onBack: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(BbTokens.gutter),
                        child: Column(
                          children: <Widget>[
                            BbCard(
                              color: const Color(0xF207504A),
                              borderColor: BbTokens.karstBronze,
                              shadowColor: const Color(0xFF3D210E),
                              child: Column(
                                children: <Widget>[
                                  _Row(
                                    icon: Icons.volume_up_rounded,
                                    label: t.soundLabel,
                                    child: BbToggle(
                                      value: settings.soundOn,
                                      semanticLabel: t.soundLabel,
                                      onChanged: controller.setSound,
                                    ),
                                  ),
                                  const _NightDivider(),
                                  _Row(
                                    icon: Icons.music_note_rounded,
                                    label: t.musicLabel,
                                    child: BbToggle(
                                      value: settings.musicOn,
                                      semanticLabel: t.musicLabel,
                                      onChanged: controller.setMusic,
                                    ),
                                  ),
                                  const _NightDivider(),
                                  _Row(
                                    icon: Icons.vibration_rounded,
                                    label: t.hapticsLabel,
                                    child: BbToggle(
                                      value: settings.hapticsOn,
                                      semanticLabel: t.hapticsLabel,
                                      onChanged: controller.setHaptics,
                                    ),
                                  ),
                                  const _NightDivider(),
                                  _Row(
                                    icon: Icons.language_rounded,
                                    label: t.languageLabel,
                                    child: Row(
                                      children: <Widget>[
                                        BbButton(
                                          label: 'VI',
                                          size: BbSize.sm,
                                          variant: settings.localeCode == 'vi'
                                              ? BbVariant.primary
                                              : BbVariant.karst,
                                          selected: settings.localeCode == 'vi',
                                          onPressed: () =>
                                              controller.setLocale('vi'),
                                        ),
                                        const SizedBox(width: BbTokens.sp2),
                                        BbButton(
                                          label: 'EN',
                                          size: BbSize.sm,
                                          variant: settings.localeCode == 'en'
                                              ? BbVariant.primary
                                              : BbVariant.karst,
                                          selected: settings.localeCode == 'en',
                                          onPressed: () =>
                                              controller.setLocale('en'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: BbTokens.sp5),
                            if (!account.blocksLocalReset)
                              FractionallySizedBox(
                                widthFactor: .60,
                                child: BbButton.danger(
                                  label: t.resetProgressCta,
                                  expand: true,
                                  onPressed: () async {
                                    await ref
                                        .read(progressProvider.notifier)
                                        .reset();
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(t.resetProgressDone),
                                      ),
                                    );
                                  },
                                ),
                              )
                            else
                              BbCard(
                                child: Text(
                                  t.signedInResetGuard,
                                  textAlign: TextAlign.center,
                                  style: BbText.body(BbTokens.textPrimary),
                                ),
                              ),
                            const SizedBox(height: BbTokens.sp6),
                          ],
                        ),
                      ),
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
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, required this.child});

  final IconData icon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Icon(icon, color: const Color(0xFFFFD36A)),
      const SizedBox(width: BbTokens.sp3),
      Expanded(child: Text(label, style: BbText.body(BbTokens.textPrimary))),
      child,
    ],
  );
}

class _NightDivider extends StatelessWidget {
  const _NightDivider();

  @override
  Widget build(BuildContext context) => Divider(
    height: BbTokens.sp6,
    color: BbTokens.karstBronze.withValues(alpha: .35),
  );
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({
    required this.title,
    required this.backLabel,
    required this.onBack,
  });

  final String title;
  final String backLabel;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 82,
    child: Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Positioned(
          left: 68,
          right: 68,
          top: 0,
          bottom: 0,
          child: Semantics(
            header: true,
            label: title,
            child: ExcludeSemantics(
              child: Image.asset(
                'assets/images/ui/karst/settings_title_banner_v2.png',
                key: const Key('settings-title'),
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        ),
        Positioned(
          left: 10,
          top: 14,
          child: Semantics(
            button: true,
            label: backLabel,
            onTap: onBack,
            child: GestureDetector(
              onTap: onBack,
              child: const Image(
                image: AssetImage('assets/images/ui/karst/back_button.png'),
                width: 52,
                height: 52,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
