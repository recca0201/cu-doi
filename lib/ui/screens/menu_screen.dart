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
import '../widgets/bb_backdrop.dart';
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
      backgroundColor: BbTokens.karstDeep,
      body: Stack(
        children: <Widget>[
          const Positioned.fill(
            child: BbCanyonBackdrop(scrim: .08, bottomShade: .24),
          ),
          const Positioned.fill(child: CustomPaint(painter: _MenuAtmosphere())),
          SafeArea(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool tablet =
                    MediaQuery.sizeOf(context).shortestSide >=
                    BbTokens.tabletBreakpoint;
                final bool compact = constraints.maxHeight < 650;
                final double heightProgress =
                    ((constraints.maxHeight - 520) / 280).clamp(0.0, 1.0);
                double responsiveHeight(double compact, double regular) =>
                    compact + (regular - compact) * heightProgress;
                final double maxContentWidth = tablet ? 520 : 430;
                final double contentWidth = constraints.maxWidth.clamp(
                  0,
                  maxContentWidth,
                );
                final double maxCompositionHeight = tablet ? 920 : 860;
                final double compositionHeight = constraints.maxHeight
                    .clamp(0, maxCompositionHeight)
                    .toDouble();
                final double verticalInset =
                    constraints.maxHeight > compositionHeight
                    ? (constraints.maxHeight - compositionHeight) / 2
                    : 0;
                final double sidePadding = tablet ? 20 : 14;
                final double actionWidth = (contentWidth - sidePadding * 2)
                    .clamp(0, 460)
                    .toDouble();
                final double playAssetWidth =
                    actionWidth * (compact ? .54 : .60);
                final double playAssetHeight = playAssetWidth / 2.85;
                final double scoreWidth = (actionWidth * .58)
                    .clamp(compact ? 160 : 190, 330)
                    .toDouble();
                // The plaque artwork is visually dense at its native aspect
                // ratio. Give the two text rows a little more vertical room.
                final double scoreHeight = scoreWidth / 1.95;
                final double logoHeight = tablet
                    ? responsiveHeight(136, 200)
                    : responsiveHeight(112, 176);

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
                          responsiveHeight(4, 8),
                          sidePadding,
                          responsiveHeight(4, 6),
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
                            SizedBox(height: responsiveHeight(4, 8)),
                            _GameLogo(title: t.appTitle, height: logoHeight),
                            SizedBox(height: responsiveHeight(2, 6)),
                            _ScorePlaque(
                              label: t.bestScoreLabel,
                              score: progress.bestScore,
                              width: scoreWidth,
                              height: scoreHeight,
                            ),
                            SizedBox(height: responsiveHeight(6, 12)),
                            SizedBox(
                              width: actionWidth,
                              child: Center(
                                child: SizedBox(
                                  width: playAssetWidth,
                                  child: BbKarstPlayButton(
                                    key: const Key('menu-play'),
                                    label: t.playCta,
                                    height: playAssetHeight,
                                    onPressed: play,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: responsiveHeight(5, 9)),
                            SizedBox(
                              width: actionWidth * .60,
                              child: BbButton.karst(
                                key: const Key('menu-arena-select'),
                                label: t.arenaSelectCta,
                                icon: Icons.track_changes_rounded,
                                size: compact ? BbSize.sm : BbSize.md,
                                expand: true,
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const ArenaMapScreen(),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: responsiveHeight(5, 9)),
                            SizedBox(
                              width: actionWidth * .60,
                              child: BbButton.karst(
                                key: const Key('menu-how-to-play'),
                                label: t.howToCta,
                                icon: Icons.route_rounded,
                                size: compact ? BbSize.sm : BbSize.md,
                                expand: true,
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => HowToPlayScreen(
                                      onDontShowAgain: () {
                                        dialogueSeen.markSeen(DialogueId.intro);
                                      },
                                    ),
                                  ),
                                ),
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
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) {
      final bool narrow = constraints.maxWidth < 330;
      final double hudHeight = narrow ? 60 : 84;
      final double panelHeight = narrow ? 52 : 72;
      final double avatarSize = narrow ? 56 : 78;
      final double avatarPadding = narrow ? 64 : 86;
      // Give the identity panel priority: its two text lines need horizontal
      // breathing room more than the compact numeric counters do.
      final double counterWidth = narrow ? 86 : 98;
      final double gap = narrow ? 5 : 7;

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
                decoration: _karstPanel(radius: 18),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    Positioned(
                      // Keep the circular frame flush with the panel edge.
                      // The previous extra -4 offset made it bleed left.
                      left: -avatarPadding,
                      top: narrow ? -7 : -9,
                      child: Container(
                        key: const Key('menu-player-avatar'),
                        width: avatarSize,
                        height: avatarSize,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: BbTokens.primaryGold,
                          border: Border.all(
                            color: const Color(0xFF3D210E),
                            width: 3,
                          ),
                          boxShadow: const <BoxShadow>[
                            BoxShadow(
                              color: Color(0x993D210E),
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const ClipOval(
                          child: Image(
                            image: AssetImage(
                              'assets/images/mascot/cu_doi_mascot_pangolin_v1.png',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    Column(
                      key: const Key('menu-player-copy'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        FittedBox(
                          alignment: Alignment.centerLeft,
                          fit: BoxFit.scaleDown,
                          child: Text(
                            t.characterName.toUpperCase(),
                            maxLines: 1,
                            style: BbText.h3(
                              Colors.white,
                            ).copyWith(fontSize: narrow ? 14 : 17),
                          ),
                        ),
                        if (!narrow)
                          FittedBox(
                            alignment: Alignment.centerLeft,
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '${t.currentLevelBadge} · ${t.arenaSelectTitle} $currentArena',
                              maxLines: 1,
                              style: BbText.tiny(
                                BbTokens.textMuted,
                              ).copyWith(letterSpacing: 0, fontSize: 10),
                            ),
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
            SizedBox(width: narrow ? 4 : 6),
            BbIconButton(
              icon: Icons.settings_rounded,
              variant: BbVariant.karst,
              semanticLabel: t.settingsCta,
              diameter: narrow ? 38 : 42,
              onPressed: onSettings,
            ),
          ],
        ),
      );
    },
  );
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
          left: 24,
          right: 24,
          bottom: 5,
          child: Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.fade,
            style: BbText.button(Colors.white).copyWith(
              fontSize: 16,
              shadows: const <Shadow>[
                Shadow(color: Color(0xCC062E2B), offset: Offset(0, 2)),
              ],
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
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const Image(
            image: AssetImage(
              'assets/images/ui/karst/high_score_plaque_v2.png',
            ),
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              width * .20,
              height * .28,
              width * .20,
              height * .12,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label.toUpperCase(),
                    maxLines: 1,
                    style: BbText.tiny(const Color(0xFFFFE2A0)).copyWith(
                      fontSize: (height * .105).clamp(8, 11),
                      height: 1,
                    ),
                  ),
                ),
                Text(
                  _formatScore(score),
                  style: BbText.score(
                    BbTokens.primaryGold,
                  ).copyWith(fontSize: (height * .31).clamp(23, 42), height: 1),
                ),
              ],
            ),
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
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) {
      final double scale = (constraints.maxHeight / 300).clamp(.33, 1.0);
      return Stack(
        alignment: Alignment.topCenter,
        children: <Widget>[
          Positioned(
            left: 8 * scale,
            right: 8 * scale,
            top: 42 * scale,
            child: CustomPaint(
              size: Size(double.infinity, 115 * scale),
              painter: _RicochetPainter(),
            ),
          ),
          Positioned(
            top: 12 * scale,
            child: Semantics(
              button: true,
              label: tagline,
              onTap: onPlay,
              child: GestureDetector(
                onTap: onPlay,
                child: Image(
                  image: const AssetImage(
                    'assets/images/mascot/cu_doi_mascot_pangolin_v1.png',
                  ),
                  width: 205 * scale,
                  height: 205 * scale,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Positioned(
            left: 10 * scale,
            right: 10 * scale,
            top: 210 * scale,
            child: Container(
              key: const Key('menu-tagline'),
              padding: EdgeInsets.symmetric(
                horizontal: 14 * scale,
                vertical: 5 * scale,
              ),
              decoration: _navyPanel(radius: 16),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  tagline,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: BbText.small(
                    Colors.white,
                  ).copyWith(fontSize: (12 * scale).clamp(10, 12)),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

BoxDecoration _navyPanel({required double radius, double borderWidth = 3}) =>
    BoxDecoration(
      color: const Color(0xF2073736),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: BbTokens.primaryGold.withValues(alpha: .72),
        width: borderWidth,
      ),
      boxShadow: BbTokens.sticker(3),
    );

BoxDecoration _karstPanel({required double radius}) => BoxDecoration(
  gradient: const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[Color(0xF20A5B50), Color(0xF2043032)],
  ),
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: const Color(0xFFD99A38), width: 2.5),
  boxShadow: const <BoxShadow>[
    BoxShadow(color: Color(0x993D210E), offset: Offset(0, 3)),
  ],
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

class _MenuAtmosphere extends CustomPainter {
  const _MenuAtmosphere();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint firefly = Paint()
      ..color = const Color(0xFFFFE7A0).withValues(alpha: .76);
    for (int i = 0; i < 42; i++) {
      final Offset p = Offset(
        ((i * 79 + 23) % 487) / 487 * size.width,
        ((i * 131 + 41) % 491) / 491 * size.height * .72,
      );
      canvas.drawCircle(p, i % 11 == 0 ? 1.7 : .65, firefly);
    }
    final Paint cyan = Paint()
      ..color = BbTokens.trajectoryCyan.withValues(alpha: .70);
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
  bool shouldRepaint(covariant _MenuAtmosphere oldDelegate) => false;
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
