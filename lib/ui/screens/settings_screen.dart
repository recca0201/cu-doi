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
      backgroundColor: BbTokens.sky,
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: BbDotPattern()),
          SafeArea(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(BbTokens.sp4),
                  child: Row(
                    children: <Widget>[
                      BbIconButton(
                        icon: Icons.arrow_back_rounded,
                        variant: BbVariant.light,
                        semanticLabel: t.backCta,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: BbTokens.sp3),
                      Text(t.settingsTitle, style: BbText.h2()),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: BbTokens.gutter,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: BbTokens.screenMax,
                      ),
                      child: Column(
                        children: <Widget>[
                          BbCard(
                            child: Column(
                              children: <Widget>[
                                _Row(
                                  label: t.soundLabel,
                                  child: BbToggle(
                                    value: settings.soundOn,
                                    semanticLabel: t.soundLabel,
                                    onChanged: controller.setSound,
                                  ),
                                ),
                                const Divider(height: BbTokens.sp6),
                                _Row(
                                  label: t.musicLabel,
                                  child: BbToggle(
                                    value: settings.musicOn,
                                    semanticLabel: t.musicLabel,
                                    onChanged: controller.setMusic,
                                  ),
                                ),
                                const Divider(height: BbTokens.sp6),
                                _Row(
                                  label: t.languageLabel,
                                  child: Row(
                                    children: <Widget>[
                                      BbButton(
                                        label: 'VI',
                                        size: BbSize.sm,
                                        variant: BbVariant.light,
                                        selected: settings.localeCode == 'vi',
                                        onPressed: () =>
                                            controller.setLocale('vi'),
                                      ),
                                      const SizedBox(width: BbTokens.sp2),
                                      BbButton(
                                        label: 'EN',
                                        size: BbSize.sm,
                                        variant: BbVariant.light,
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Row(
        children: <Widget>[
          Expanded(child: Text(label, style: BbText.body())),
          child,
        ],
      );
}
