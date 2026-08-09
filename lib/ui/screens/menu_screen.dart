import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/bb_theme.dart';
import '../../core/bb_tokens.dart';
import '../../domain/character.dart';
import '../../domain/player_progress.dart';
import '../../l10n/app_localizations.dart';
import '../../sim/arena.dart';
import '../../sim/arenas.dart';
import '../../state/providers.dart';
import '../widgets/bb_widgets.dart';
import 'arena_map_screen.dart';
import 'game_screen.dart';
import 'how_to_play_screen.dart';
import 'settings_screen.dart';

/// Galaxy-arcade launcher inspired by the product key art. Only real product
/// flows are surfaced; decorative shop/event/mission buttons stay out.
class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations t = AppLocalizations.of(context);
    final PlayerProgress progress = ref.watch(progressProvider);
    ref.watch(dialogueSeenProvider);

    final int firstUnfinished = kArenas
        .map((ArenaSpec arena) => arena.id)
        .firstWhere(
          (int id) => !progress.isCompleted(id) && !progress.isSkipped(id),
          orElse: () => kArenas.first.id,
        );
    final DialogueSeenController dialogueSeen = ref.read(
      dialogueSeenProvider.notifier,
    );
    final bool showGuide =
        dialogueSeen.isRestored && !dialogueSeen.hasSeen(DialogueId.intro);

    void play() => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            GameScreen(arenaId: firstUnfinished, showGuide: showGuide),
      ),
    );

    return Scaffold(
      backgroundColor: BbTokens.nightIndigo,
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: CustomPaint(painter: _MenuBackdrop())),
          SafeArea(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool tablet =
                    MediaQuery.sizeOf(context).shortestSide >=
                    BbTokens.tabletBreakpoint;
                final bool compactHeight = constraints.maxHeight < 720;
                final double maxContentWidth = tablet ? 520 : 430;
                final double contentWidth = constraints.maxWidth.clamp(
                  0,
                  maxContentWidth,
                );
                final double maxCompositionHeight = tablet ? 920 : 860;
                final double compositionHeight = constraints.maxHeight
                    .clamp(650, maxCompositionHeight)
                    .toDouble();
                final double verticalInset =
                    constraints.maxHeight > compositionHeight
                    ? (constraints.maxHeight - compositionHeight) / 2
                    : 0;
                final double sidePadding = tablet ? 20 : 14;
                final double actionWidth = (contentWidth - sidePadding * 2)
                    .clamp(0, 460)
                    .toDouble();
                final double logoHeight = compactHeight
                    ? 142
                    : (tablet ? 200 : 176);

                return SingleChildScrollView(
                  padding: EdgeInsets.only(
                    top: verticalInset,
                    bottom: verticalInset,
                  ),
                  child: Center(
                    child: SizedBox(
                      width: contentWidth,
                      height: compositionHeight,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          sidePadding,
                          compactHeight ? 4 : 8,
                          sidePadding,
                          compactHeight ? 4 : 6,
                        ),
                        child: Column(
                          children: <Widget>[
                            _PlayerHud(
                              t: t,
                              progress: progress,
                              currentArena: firstUnfinished,
                              onSettings: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const SettingsScreen(),
                                ),
                              ),
                            ),
                            SizedBox(height: compactHeight ? 4 : 8),
                            _GameLogo(title: t.appTitle, height: logoHeight),
                            SizedBox(height: compactHeight ? 2 : 6),
                            _ScorePlaque(
                              label: t.bestScoreLabel,
                              score: progress.bestScore,
                              width: actionWidth * .72,
                              height: compactHeight ? 68 : 78,
                            ),
                            SizedBox(height: compactHeight ? 8 : 12),
                            SizedBox(
                              width: actionWidth,
                              child: BbMenuButton(
                                key: const Key('menu-play'),
                                label: t.playCta,
                                icon: Icons.play_arrow_rounded,
                                hero: true,
                                onPressed: play,
                              ),
                            ),
                            SizedBox(height: compactHeight ? 10 : 14),
                            SizedBox(
                              width: actionWidth,
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: BbMenuButton(
                                      key: const Key('menu-arena-select'),
                                      label: t.arenaSelectCta,
                                      icon: Icons.track_changes_rounded,
                                      variant: BbVariant.secondary,
                                      onPressed: () =>
                                          Navigator.of(context).push(
                                            MaterialPageRoute<void>(
                                              builder: (_) =>
                                                  const ArenaMapScreen(),
                                            ),
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: BbMenuButton(
                                      key: const Key('menu-how-to-play'),
                                      label: t.howToCta,
                                      icon: Icons.route_rounded,
                                      variant: BbVariant.accent,
                                      onPressed: () =>
                                          Navigator.of(context).push(
                                            MaterialPageRoute<void>(
                                              builder: (_) => HowToPlayScreen(
                                                onDontShowAgain: () {
                                                  dialogueSeen.markSeen(
                                                    DialogueId.intro,
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: _MascotStage(
                                tagline: t.menuTagline,
                                onPlay: play,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerHud extends StatelessWidget {
  const _PlayerHud({
    required this.t,
    required this.progress,
    required this.currentArena,
    required this.onSettings,
  });

  final AppLocalizations t;
  final PlayerProgress progress;
  final int currentArena;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final bool narrow = MediaQuery.sizeOf(context).width < 360;
    final double hudHeight = narrow ? 60 : 66;
    final double panelHeight = narrow ? 52 : 58;
    final double avatarSize = narrow ? 56 : 66;
    final double avatarPadding = narrow ? 46 : 54;
    final double counterWidth = narrow ? 92 : 118;
    final double gap = narrow ? 6 : 10;

    return SizedBox(
      height: hudHeight,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Container(
              height: panelHeight,
              padding: EdgeInsets.fromLTRB(
                avatarPadding,
                6,
                narrow ? 6 : 10,
                6,
              ),
              decoration: _navyPanel(radius: 18),
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Positioned(
                    left: -(avatarPadding + 4),
                    top: narrow ? -8 : -10,
                    child: Container(
                      width: avatarSize,
                      height: avatarSize,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: BbTokens.primaryGold,
                        border: Border.all(
                          color: BbTokens.outlineDark,
                          width: 4,
                        ),
                        boxShadow: BbTokens.sticker(3),
                      ),
                      child: const ClipOval(
                        child: Image(
                          image: AssetImage(
                            'assets/images/mascot/cu_doi_mascot_galaxy_v3.png',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        t.characterName.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: BbText.h3(
                          Colors.white,
                        ).copyWith(fontSize: narrow ? 14 : 17),
                      ),
                      if (!narrow)
                        Text(
                          '${t.currentLevelBadge} · ${t.arenaSelectTitle} $currentArena',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: BbText.tiny(
                            BbTokens.textMuted,
                          ).copyWith(letterSpacing: 0, fontSize: 10),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: gap),
          SizedBox(
            width: counterWidth,
            child: Column(
              children: <Widget>[
                _CounterPill(
                  icon: Icons.monetization_on_rounded,
                  color: BbTokens.primaryGold,
                  value: '${progress.coins}',
                ),
                SizedBox(height: narrow ? 2 : 6),
                _CounterPill(
                  icon: Icons.star_rounded,
                  color: BbTokens.primaryGold,
                  value: '${progress.totalStars}/${kArenas.length * 3}',
                ),
              ],
            ),
          ),
          SizedBox(width: narrow ? 5 : 8),
          BbIconButton(
            icon: Icons.settings_rounded,
            semanticLabel: t.settingsCta,
            diameter: narrow ? 40 : 44,
            onPressed: onSettings,
          ),
        ],
      ),
    );
  }
}

class _CounterPill extends StatelessWidget {
  const _CounterPill({
    required this.icon,
    required this.color,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    height: 28,
    padding: const EdgeInsets.only(left: 5, right: 8),
    decoration: _navyPanel(radius: 14, borderWidth: 2),
    child: Row(
      children: <Widget>[
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 4),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: BbText.h3(Colors.white)),
          ),
        ),
      ],
    ),
  );
}

class _GameLogo extends StatelessWidget {
  const _GameLogo({required this.title, required this.height});

  final String title;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: <Widget>[
        const Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _LogoBurstPainter()),
          ),
        ),
        const Positioned(
          left: 3,
          bottom: 33,
          child: _BankToken(value: '2', color: BbTokens.tertiaryPurple),
        ),
        const Positioned(
          right: 3,
          bottom: 41,
          child: _BankToken(value: '3', color: BbTokens.dangerRed),
        ),
        const Positioned(
          left: 5,
          right: 5,
          top: 0,
          bottom: 23,
          child: Image(
            key: Key('main-logo'),
            image: AssetImage('assets/images/brand/cu_doi_logo_galaxy_v1.png'),
            fit: BoxFit.contain,
            semanticLabel: 'CÚ DỘI!',
          ),
        ),
        Positioned(
          bottom: 3,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            decoration: BoxDecoration(
              color: BbTokens.secondaryBlueDark,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: BbTokens.outlineDark, width: 3),
              boxShadow: BbTokens.sticker(3),
            ),
            child: Text(
              title,
              style: BbText.button(Colors.white).copyWith(fontSize: 16),
            ),
          ),
        ),
      ],
    ),
  );
}

class _BankToken extends StatelessWidget {
  const _BankToken({required this.value, required this.color});

  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 48,
    height: 48,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color,
      border: Border.all(color: BbTokens.outlineDark, width: 4),
      boxShadow: BbTokens.sticker(4),
    ),
    child: Text(value, style: BbText.h1(Colors.white).copyWith(fontSize: 28)),
  );
}

class _ScorePlaque extends StatelessWidget {
  const _ScorePlaque({
    required this.label,
    required this.score,
    required this.width,
    required this.height,
  });

  final String label;
  final int score;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final bool compact = height < 74;
    return Container(
      width: width.clamp(240, 330),
      height: height,
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFFFFF9E8), Color(0xFFFFE6A0)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: BbTokens.primaryGoldDark, width: 4),
        boxShadow: BbTokens.sticker(6, BbTokens.outlineDark),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            label.toUpperCase(),
            style: BbText.tiny(
              BbTokens.primaryGoldDark,
            ).copyWith(fontSize: compact ? 10 : 11),
          ),
          Text(
            _formatScore(score),
            style: BbText.score(
              const Color(0xFF6A2500),
            ).copyWith(fontSize: compact ? 32 : 36),
          ),
        ],
      ),
    );
  }
}

class _MascotStage extends StatelessWidget {
  const _MascotStage({required this.tagline, required this.onPlay});

  final String tagline;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) => Stack(
    alignment: Alignment.topCenter,
    children: <Widget>[
      Positioned(
        left: 8,
        right: 8,
        top: 42,
        child: CustomPaint(
          size: const Size(double.infinity, 115),
          painter: _RicochetPainter(),
        ),
      ),
      Positioned(
        top: 12,
        child: Semantics(
          button: true,
          label: tagline,
          onTap: onPlay,
          child: GestureDetector(
            onTap: onPlay,
            child: const Image(
              image: AssetImage(
                'assets/images/mascot/cu_doi_mascot_galaxy_v3.png',
              ),
              width: 205,
              height: 205,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
      Positioned(
        left: 10,
        right: 10,
        top: 210,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: _navyPanel(radius: 16),
          child: Text(
            tagline,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: BbText.small(Colors.white).copyWith(fontSize: 12),
          ),
        ),
      ),
    ],
  );
}

BoxDecoration _navyPanel({required double radius, double borderWidth = 3}) =>
    BoxDecoration(
      color: BbTokens.panelNavy.withValues(alpha: .96),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: BbTokens.outlineDark, width: borderWidth),
      boxShadow: BbTokens.sticker(3),
    );

String _formatScore(int score) {
  final String digits = score.toString();
  final StringBuffer out = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
    out.write(digits[i]);
  }
  return out.toString();
}

class _MenuBackdrop extends CustomPainter {
  const _MenuBackdrop();

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.45, -.72),
          radius: 1.28,
          colors: <Color>[
            Color(0xFF331D78),
            Color(0xFF101D55),
            Color(0xFF05091F),
          ],
        ).createShader(rect),
    );

    void nebula(Offset center, double radius, Color color, double alpha) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: <Color>[
              color.withValues(alpha: alpha),
              color.withValues(alpha: alpha * .25),
              Colors.transparent,
            ],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }

    nebula(
      Offset(size.width * .92, size.height * .28),
      size.width * .62,
      const Color(0xFF00C2D8),
      .18,
    );
    nebula(
      Offset(size.width * -.08, size.height * .66),
      size.width * .72,
      const Color(0xFFCF3FAF),
      .16,
    );

    // Distant ringed planet: recognizable galaxy cue, kept behind the UI.
    final Offset planet = Offset(size.width * .84, size.height * .55);
    final double planetRadius = size.width * .16;
    canvas.save();
    canvas.translate(planet.dx, planet.dy);
    canvas.rotate(-.28);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: planetRadius * 3.2,
        height: planetRadius * .72,
      ),
      Paint()
        ..color = const Color(0xFF7BDCF2).withValues(alpha: .18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7,
    );
    canvas.restore();
    canvas.drawCircle(
      planet,
      planetRadius,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.45, -.45),
          colors: <Color>[
            Color(0xFF78E1F4),
            Color(0xFF3767B8),
            Color(0xFF172B6B),
          ],
        ).createShader(Rect.fromCircle(center: planet, radius: planetRadius)),
    );

    final Paint star = Paint()..color = Colors.white.withValues(alpha: .72);
    final Paint cyan = Paint()
      ..color = BbTokens.trajectoryCyan.withValues(alpha: .78);
    for (int i = 0; i < 92; i++) {
      final Offset p = Offset(
        ((i * 79 + 23) % 487) / 487 * size.width,
        ((i * 131 + 41) % 491) / 491 * size.height,
      );
      canvas.drawCircle(p, i % 16 == 0 ? 1.65 : .62, i % 11 == 0 ? cyan : star);
    }
    for (final Offset p in <Offset>[
      Offset(size.width * .12, size.height * .19),
      Offset(size.width * .88, size.height * .25),
      Offset(size.width * .24, size.height * .44),
      Offset(size.width * .72, size.height * .78),
    ]) {
      canvas.drawLine(
        p - const Offset(5, 0),
        p + const Offset(5, 0),
        cyan..strokeWidth = 1.1,
      );
      canvas.drawLine(p - const Offset(0, 5), p + const Offset(0, 5), cyan);
    }
  }

  @override
  bool shouldRepaint(covariant _MenuBackdrop oldDelegate) => false;
}

class _LogoBurstPainter extends CustomPainter {
  const _LogoBurstPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = size.center(Offset.zero);
    final Paint glow = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          Colors.white.withValues(alpha: .55),
          Colors.white.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: c, radius: size.width * .48));
    canvas.drawCircle(c, size.width * .48, glow);
  }

  @override
  bool shouldRepaint(covariant _LogoBurstPainter oldDelegate) => false;
}

class _RicochetPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Path path = Path()
      ..moveTo(8, size.height * .72)
      ..lineTo(size.width * .28, 8)
      ..lineTo(size.width * .53, size.height * .78)
      ..lineTo(size.width - 8, size.height * .18);
    canvas.drawPath(
      path,
      Paint()
        ..color = BbTokens.secondaryBlue.withValues(alpha: .7)
        ..strokeWidth = 9
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = BbTokens.trajectoryCyan
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    final Paint dot = Paint()..color = Colors.white;
    for (final Offset p in <Offset>[
      Offset(8, size.height * .72),
      Offset(size.width * .28, 8),
      Offset(size.width * .53, size.height * .78),
      Offset(size.width - 8, size.height * .18),
    ]) {
      canvas.drawCircle(p, 7, dot);
      canvas.drawCircle(
        p,
        11,
        Paint()
          ..color = BbTokens.trajectoryCyan.withValues(alpha: .35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RicochetPainter oldDelegate) => false;
}
