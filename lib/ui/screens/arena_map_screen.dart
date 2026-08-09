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
import 'game_screen.dart';

/// A flat list, not the parent project's serpentine trail.
///
/// With three arenas a decorated map would be theatre. When the arena count
/// grows this is the screen to reconsider — and the parent's
/// `level_map_screen.dart` is the reference to come back to.
class ArenaMapScreen extends ConsumerWidget {
  const ArenaMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations t = AppLocalizations.of(context);
    final PlayerProgress progress = ref.watch(progressProvider);
    final String code = Localizations.localeOf(context).languageCode;

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
                      Text(t.arenaSelectTitle, style: BbText.h2()),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: BbTokens.gutter,
                      vertical: BbTokens.sp3,
                    ),
                    itemCount: kArenas.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: BbTokens.sp3),
                    itemBuilder: (BuildContext ctx, int i) {
                      final ArenaSpec arena = kArenas[i];
                      final bool unlocked = progress.isUnlocked(arena.id);
                      final int stars = progress.starsFor(arena.id);
                      return _ArenaTile(
                        arena: arena,
                        localeCode: code,
                        unlocked: unlocked,
                        stars: stars,
                        onTap: unlocked
                            ? () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        GameScreen(arenaId: arena.id),
                                  ),
                                )
                            : () => ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(t.arenaLockedHint)),
                                ),
                      );
                    },
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

class _ArenaTile extends StatelessWidget {
  const _ArenaTile({
    required this.arena,
    required this.localeCode,
    required this.unlocked,
    required this.stars,
    required this.onTap,
  });

  final ArenaSpec arena;
  final String localeCode;
  final bool unlocked;
  final int stars;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: forLocale(localeCode, arena.name, arena.nameEn),
      child: GestureDetector(
        onTap: onTap,
        child: Opacity(
          opacity: unlocked ? 1 : 0.55,
          child: BbCard(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        t.arenaHeading(
                          arena.id,
                          forLocale(localeCode, arena.name, arena.nameEn),
                        ),
                        style: BbText.h3(),
                      ),
                      const SizedBox(height: BbTokens.sp1),
                      Text(
                        unlocked
                            ? t.arenaStars(stars, 3)
                            : t.arenaLocked,
                        style: BbText.small(),
                      ),
                    ],
                  ),
                ),
                if (unlocked)
                  Text(
                    '${'★' * stars}${'☆' * (3 - stars)}',
                    style: BbText.h3(BbTokens.bbYellowDark),
                  )
                else
                  const Icon(Icons.lock_rounded, color: BbTokens.ink300),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
