import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/bb_theme.dart';
import '../../core/bb_tokens.dart';
import '../../domain/player_progress.dart';
import '../../l10n/app_localizations.dart';
import '../../sim/arena.dart';
import '../../sim/arenas.dart';
import '../../state/providers.dart';
import '../widgets/bb_backdrop.dart';
import '../widgets/bb_widgets.dart';
import 'arena_map_screen.dart';
import 'game_screen.dart';
import 'settings_screen.dart';

/// Daylight brand shell. Only the arena itself goes dark — keeping the menu in
/// the parent game's cream-and-sunburst language is what makes this still read
/// as Bắn Bừa rather than as an unrelated app.
class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations t = AppLocalizations.of(context);
    final PlayerProgress progress = ref.watch(progressProvider);

    final int firstUnfinished = kArenas
        .map((ArenaSpec a) => a.id)
        .firstWhere(
          (int id) => !progress.isCompleted(id),
          orElse: () => kArenas.first.id,
        );
    final bool fresh = progress.results.isEmpty;

    return Scaffold(
      backgroundColor: BbTokens.sky,
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: BbSunburst(rays: 14, opacity: 0.35)),
          const Positioned.fill(child: BbDotPattern()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: BbTokens.gutter,
                vertical: BbTokens.sp4,
              ),
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      BbBadge('${t.coinsLabel} ${progress.coins}'),
                      BbIconButton(
                        icon: Icons.settings_rounded,
                        variant: BbVariant.light,
                        semanticLabel: t.settingsCta,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const SettingsScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    t.appTitle,
                    style: BbText.logo(BbTokens.bbCoral),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: BbTokens.sp3),
                  Text(
                    t.menuTagline,
                    style: BbText.body(BbTokens.ink700),
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(),
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: BbTokens.screenMax,
                    ),
                    child: Column(
                      children: <Widget>[
                        BbButton.primary(
                          label: t.playCta,
                          size: BbSize.lg,
                          icon: Icons.play_arrow_rounded,
                          expand: true,
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => GameScreen(
                                arenaId: firstUnfinished,
                                showGuide: fresh,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: BbTokens.sp3),
                        BbButton.accent(
                          label: t.arenaSelectCta,
                          icon: Icons.grid_view_rounded,
                          expand: true,
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const ArenaMapScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(height: BbTokens.sp3),
                        BbButton.light(
                          label: t.howToCta,
                          icon: Icons.help_outline_rounded,
                          expand: true,
                          onPressed: () => _showRules(context, t),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: BbTokens.sp5),
                  Text(
                    '${t.bestScoreLabel}: ${progress.bestScore}',
                    style: BbText.small(BbTokens.ink500),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRules(BuildContext context, AppLocalizations t) {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(BbTokens.sp5),
        child: BbCard(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(t.howToTitle, style: BbText.h2()),
                const SizedBox(height: BbTokens.sp4),
                for (final String rule in <String>[
                  t.howToRule1,
                  t.howToRule2,
                  t.howToRule3,
                  t.howToRule4,
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: BbTokens.sp3),
                    child: Text(rule, style: BbText.body()),
                  ),
                BbButton.primary(
                  label: t.gotItCta,
                  expand: true,
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
