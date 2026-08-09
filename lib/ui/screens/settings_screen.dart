import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/bb_theme.dart';
import '../../core/bb_tokens.dart';
import '../../data/settings_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../state/providers.dart';
import '../widgets/bb_backdrop.dart';
import '../widgets/bb_widgets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations t = AppLocalizations.of(context);
    final AppSettings settings = ref.watch(settingsProvider);
    final SettingsController controller = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: BbTokens.nightIndigo,
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: BbStarfield(opacity: .35)),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: BbTokens.screenMax),
                child: Column(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(BbTokens.sp4),
                      decoration: const BoxDecoration(
                        color: BbTokens.panelNavy,
                        border: Border(
                          bottom: BorderSide(
                            color: BbTokens.outlineDark,
                            width: BbTokens.bd2,
                          ),
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          BbIconButton(
                            icon: Icons.arrow_back_rounded,
                            semanticLabel: t.backCta,
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(width: BbTokens.sp3),
                          Expanded(
                            child: BbGameTitle(
                              key: const Key('settings-title'),
                              label: t.settingsTitle,
                              height: 44,
                              fontSize: 31,
                              tilt: -.01,
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(BbTokens.gutter),
                        child: Column(
                          children: <Widget>[
                            BbCard(
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
                                              : BbVariant.light,
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
                                              : BbVariant.light,
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
                            BbButton.danger(
                              label: t.resetProgressCta,
                              expand: true,
                              onPressed: () async {
                                await ref
                                    .read(progressProvider.notifier)
                                    .reset();
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(t.resetProgressDone)),
                                );
                              },
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
      Icon(icon, color: BbTokens.trajectoryCyan),
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
    color: BbTokens.textMuted.withValues(alpha: .22),
  );
}
