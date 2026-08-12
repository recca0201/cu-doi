import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/arena_ink.dart';
import '../../core/bb_theme.dart';
import '../../core/bb_tokens.dart';
import '../../domain/character.dart';
import '../../l10n/app_localizations.dart';
import '../character_dialogue.dart';
import '../pangolin_ball_art.dart';
import '../widgets/bb_backdrop.dart';
import '../widgets/bb_widgets.dart';

abstract final class _TutorialArt {
  static const String title =
      'assets/images/ui/karst/rules_title_banner_v2.png';
  static const String cardFrame = 'assets/images/ui/karst/detail_panel.png';
}

enum _RuleArt { aim, bounce, direct, score, floor }

class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key, this.onDontShowAgain});

  final VoidCallback? onDontShowAgain;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: BbTokens.karstDeep,
    body: SafeArea(
      child: HowToPlayPanel(
        onDismiss: () => Navigator.of(context).pop(),
        onDontShowAgain: () {
          onDontShowAgain?.call();
          Navigator.of(context).pop();
        },
      ),
    ),
  );
}

class HowToPlayPanel extends StatelessWidget {
  const HowToPlayPanel({
    super.key,
    required this.onDismiss,
    required this.onDontShowAgain,
    this.showDialogue = false,
  });

  final VoidCallback onDismiss;
  final VoidCallback onDontShowAgain;
  final bool showDialogue;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    final List<({String title, String body, _RuleArt art})>
    rules = <({String title, String body, _RuleArt art})>[
      (title: t.howToAimTitle, body: t.howToAimBody, art: _RuleArt.aim),
      (
        title: t.howToBounceTitle,
        body: t.howToBounceBody,
        art: _RuleArt.bounce,
      ),
      (
        title: t.howToDirectTitle,
        body: t.howToDirectBody,
        art: _RuleArt.direct,
      ),
      (title: t.howToScoreTitle, body: t.howToScoreBody, art: _RuleArt.score),
      (title: t.howToFloorTitle, body: t.howToFloorBody, art: _RuleArt.floor),
    ];

    return Stack(
      children: <Widget>[
        const Positioned.fill(
          child: BbCanyonBackdrop(scrim: .34, bottomShade: .62),
        ),
        const Positioned.fill(child: BbKarstFrameOverlay()),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
              child: Column(
                children: <Widget>[
                  _RulesHeader(title: t.howToTitle, onClose: onDismiss),
                  if (showDialogue) ...<Widget>[
                    const SizedBox(height: 12),
                    CharacterDialogue(
                      id: DialogueId.intro,
                      onDismiss: onDismiss,
                    ),
                  ],
                  const SizedBox(height: 14),
                  for (int i = 0; i < rules.length; i++) ...<Widget>[
                    _RuleCard(
                      number: i + 1,
                      title: rules[i].title,
                      body: rules[i].body,
                      art: rules[i].art,
                    ),
                    const SizedBox(height: 10),
                  ],
                  _TargetNote(text: t.howToTargetNote),
                  const SizedBox(height: 16),
                  FractionallySizedBox(
                    widthFactor: .60,
                    child: BbButton.primary(
                      label: t.gotItCta,
                      size: BbSize.lg,
                      icon: Icons.check_rounded,
                      expand: true,
                      onPressed: onDismiss,
                    ),
                  ),
                  const SizedBox(height: 10),
                  FractionallySizedBox(
                    widthFactor: .60,
                    child: BbButton.karst(
                      label: t.dontShowAgainCta,
                      size: BbSize.md,
                      icon: Icons.check_box_rounded,
                      expand: true,
                      onPressed: onDontShowAgain,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RulesHeader extends StatelessWidget {
  const _RulesHeader({required this.title, required this.onClose});

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 104,
    child: Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Positioned(
          left: 32,
          right: 32,
          top: 8,
          child: SizedBox(
            key: const Key('how-to-title'),
            height: 92,
            child: Image.asset(
              _TutorialArt.title,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
        Positioned.fill(
          child: ExcludeSemantics(
            child: Opacity(opacity: 0, child: Center(child: Text(title))),
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          child: BbIconButton(
            icon: Icons.close_rounded,
            variant: BbVariant.karst,
            semanticLabel: MaterialLocalizations.of(context).closeButtonTooltip,
            diameter: 48,
            onPressed: onClose,
          ),
        ),
      ],
    ),
  );
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({
    required this.number,
    required this.title,
    required this.body,
    required this.art,
  });

  final int number;
  final String title;
  final String body;
  final _RuleArt art;

  @override
  Widget build(BuildContext context) => Container(
    key: Key('how-to-rule-$number'),
    constraints: const BoxConstraints(minHeight: 146),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      boxShadow: const <BoxShadow>[
        BoxShadow(color: Color(0x993D210E), offset: Offset(0, 3)),
      ],
    ),
    clipBehavior: Clip.antiAlias,
    child: Stack(
      children: <Widget>[
        Positioned.fill(
          child: Transform.scale(
            scaleX: 1.16,
            scaleY: 1.32,
            alignment: Alignment.topCenter,
            child: Image.asset(
              _TutorialArt.cardFrame,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 21, 34, 24),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double textScale = MediaQuery.textScalerOf(
                context,
              ).scale(1);
              final bool stacked =
                  constraints.maxWidth < 300 || textScale > 1.35;
              final Widget heading = Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  _StepBadge(number: number),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      key: Key('how-to-title-$number'),
                      maxLines: 2,
                      overflow: TextOverflow.visible,
                      style: BbText.h3(
                        BbTokens.primaryGold,
                      ).copyWith(fontSize: 17),
                    ),
                  ),
                ],
              );
              final Widget diagram = _RuleDiagramBox(
                key: Key('how-to-art-$number'),
                art: art,
              );
              final Widget explanation = Text(
                body,
                key: Key('how-to-body-$number'),
                style: BbText.small(Colors.white).copyWith(fontSize: 12.5),
              );

              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    heading,
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.center,
                      child: SizedBox(width: 190, height: 124, child: diagram),
                    ),
                    const SizedBox(height: 10),
                    explanation,
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  heading,
                  const SizedBox(height: 9),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      SizedBox(width: 132, height: 112, child: diagram),
                      const SizedBox(width: 12),
                      Expanded(child: explanation),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ],
    ),
  );
}

class _RuleDiagramBox extends StatelessWidget {
  const _RuleDiagramBox({super.key, required this.art});

  final _RuleArt art;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: const Color(0xFF071E27),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(
        color: BbTokens.trajectoryCyan.withValues(alpha: .75),
        width: 1.5,
      ),
      boxShadow: const <BoxShadow>[
        BoxShadow(color: Color(0x66032124), offset: Offset(0, 2)),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(11),
      child: CustomPaint(painter: _RuleDiagram(art)),
    ),
  );
}

class _StepBadge extends StatelessWidget {
  const _StepBadge({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) => Container(
    width: 44,
    height: 44,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: const RadialGradient(
        center: Alignment(-.28, -.32),
        colors: <Color>[
          Color(0xFF2FC0A2),
          Color(0xFF087064),
          Color(0xFF043032),
        ],
      ),
      border: Border.all(color: const Color(0xFFFFD36A), width: 3),
      boxShadow: const <BoxShadow>[
        BoxShadow(color: Color(0x993D210E), offset: Offset(0, 3)),
      ],
    ),
    child: Text(
      '$number',
      style: BbText.h2(const Color(0xFFFFF3D7)).copyWith(
        fontSize: 23,
        shadows: const <Shadow>[
          Shadow(color: Color(0xFF3D210E), offset: Offset(0, 2)),
        ],
      ),
    ),
  );
}

class _TargetNote extends StatelessWidget {
  const _TargetNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xF2074542),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: BbTokens.karstBronze, width: 2),
    ),
    child: Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            const Icon(
              Icons.lightbulb_rounded,
              color: BbTokens.primaryGold,
              size: 31,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: BbText.small(Colors.white))),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            for (int i = 1; i <= 4; i++) ...<Widget>[
              _MiniTarget(number: i),
              if (i < 4) const SizedBox(width: 8),
            ],
          ],
        ),
      ],
    ),
  );
}

class _MiniTarget extends StatelessWidget {
  const _MiniTarget({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    const List<Color> colors = <Color>[
      BbTokens.tertiaryPurple,
      BbTokens.secondaryBlue,
      BbTokens.primaryGold,
      BbTokens.dangerRed,
    ];
    return SizedBox(
      width: 31,
      height: 31,
      child: CustomPaint(
        painter: PangolinBallPainter(color: colors[number - 1], number: number),
      ),
    );
  }
}

class _RuleDiagram extends CustomPainter {
  const _RuleDiagram(this.art);

  final _RuleArt art;

  @override
  void paint(Canvas canvas, Size size) {
    final double unit = math.min(size.width / 132, size.height / 112);
    final Paint cyan = Paint()
      ..color = ArenaInk.of(ArenaInk.trajectoryCyan)
      ..strokeWidth = 2.2 * unit
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final Paint glow = Paint()
      ..color = ArenaInk.of(ArenaInk.trajectoryCyan, 0x38)
      ..strokeWidth = 7 * unit
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final Offset launcher = Offset(size.width * .50, size.height * .82);

    void ball(Offset c, [double radius = 6.5]) {
      canvas.drawCircle(
        c,
        radius * 2.2,
        Paint()..color = ArenaInk.of(ArenaInk.energyCyan, 0x28),
      );
      paintPangolinBall(
        canvas,
        center: c,
        radius: radius,
        shellColor: const Color(0xFFE97822),
        showFace: false,
      );
    }

    void launcherAt(Offset c, {double angle = -math.pi / 2}) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(angle);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(-4 * unit, -5 * unit, 24 * unit, 5 * unit),
          Radius.circular(2.5 * unit),
        ),
        Paint()
          ..shader =
              const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Color(0xFFFFD36A),
                  Color(0xFFD99A38),
                  Color(0xFF8A4E1D),
                ],
              ).createShader(
                Rect.fromLTRB(-4 * unit, -5 * unit, 24 * unit, 5 * unit),
              ),
      );
      canvas.drawCircle(
        Offset(21 * unit, 0),
        5.7 * unit,
        Paint()
          ..color = ArenaInk.of(ArenaInk.energyCyan)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2 * unit,
      );
      canvas.restore();
      paintPangolinBall(
        canvas,
        center: c,
        radius: 7 * unit,
        shellColor: const Color(0xFFE97822),
        showFace: false,
      );
    }

    void path(List<Offset> points) {
      final Path p = Path()..moveTo(points.first.dx, points.first.dy);
      for (final Offset point in points.skip(1)) {
        p.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(p, glow);
      canvas.drawPath(p, cyan);
      for (final Offset point in points.skip(1).take(points.length - 2)) {
        canvas.drawCircle(point, 2.8 * unit, Paint()..color = Colors.white);
      }
    }

    void target(Offset c, int number, Color color, {bool armed = false}) {
      canvas.drawCircle(
        c,
        15 * unit,
        Paint()
          ..color = armed
              ? ArenaInk.of(ArenaInk.energyCyan, 0x58)
              : color.withValues(alpha: .25),
      );
      paintPangolinBall(
        canvas,
        center: c,
        radius: 10.5 * unit,
        shellColor: color,
        armed: armed,
        number: number,
      );
    }

    void sideWall(double x) {
      canvas.drawLine(
        Offset(x, 5 * unit),
        Offset(x, size.height - 5 * unit),
        Paint()
          ..color = ArenaInk.of(ArenaInk.outline)
          ..strokeWidth = 7 * unit,
      );
      canvas.drawLine(
        Offset(x, 5 * unit),
        Offset(x, size.height - 5 * unit),
        Paint()
          ..color = ArenaInk.of(ArenaInk.frame)
          ..strokeWidth = 3.2 * unit,
      );
    }

    void block(Rect rect) {
      final RRect shape = RRect.fromRectAndRadius(
        rect,
        Radius.circular(2.2 * unit),
      );
      canvas.drawRRect(
        shape,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFF61779B), Color(0xFF243A61)],
          ).createShader(rect),
      );
      canvas.drawRRect(
        shape,
        Paint()
          ..color = const Color(0xFFB6C8E2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .8 * unit,
      );
    }

    void deflector(Offset a, Offset b) {
      canvas.drawLine(
        a,
        b,
        Paint()
          ..color = ArenaInk.of(ArenaInk.outline)
          ..strokeWidth = 7 * unit
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawLine(
        a,
        b,
        Paint()
          ..color = const Color(0xFF5E7397)
          ..strokeWidth = 4.5 * unit
          ..strokeCap = StrokeCap.round,
      );
    }

    void resultMark(Offset center, {required bool success}) {
      final Paint outline = Paint()
        ..color = ArenaInk.of(ArenaInk.outline)
        ..strokeWidth = 6 * unit
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final Paint color = Paint()
        ..color = success ? BbTokens.successGreen : BbTokens.dangerRed
        ..strokeWidth = 3.2 * unit
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final Path mark = success
          ? (Path()
              ..moveTo(center.dx - 7 * unit, center.dy)
              ..lineTo(center.dx - 2 * unit, center.dy + 5 * unit)
              ..lineTo(center.dx + 8 * unit, center.dy - 7 * unit))
          : (Path()
              ..moveTo(center.dx - 6 * unit, center.dy - 6 * unit)
              ..lineTo(center.dx + 6 * unit, center.dy + 6 * unit)
              ..moveTo(center.dx + 6 * unit, center.dy - 6 * unit)
              ..lineTo(center.dx - 6 * unit, center.dy + 6 * unit));
      canvas.drawPath(mark, outline);
      canvas.drawPath(mark, color);
    }

    switch (art) {
      case _RuleArt.aim:
        sideWall(size.width * .94);
        final Offset bank = Offset(size.width * .94, size.height * .30);
        final Offset end = Offset(size.width * .68, size.height * .12);
        launcherAt(launcher, angle: -.93);
        _dashedLine(canvas, launcher, bank, cyan);
        _dashedLine(
          canvas,
          bank,
          end,
          Paint()
            ..color = ArenaInk.of(ArenaInk.trajectoryCyan, 0x78)
            ..strokeWidth = 1.6 * unit
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawCircle(bank, 2.8 * unit, Paint()..color = Colors.white);
        canvas.drawCircle(
          Offset(size.width * .28, size.height * .60),
          7 * unit,
          Paint()..color = const Color(0xFFFFB38A),
        );
        canvas.drawLine(
          Offset(size.width * .28, size.height * .60),
          Offset(size.width * .45, size.height * .45),
          Paint()
            ..color = const Color(0xFFFFB38A)
            ..strokeWidth = 6 * unit
            ..strokeCap = StrokeCap.round,
        );
      case _RuleArt.bounce:
        sideWall(size.width * .08);
        block(
          Rect.fromCenter(
            center: Offset(size.width * .54, size.height * .35),
            width: size.width * .30,
            height: 12 * unit,
          ),
        );
        deflector(
          Offset(size.width * .66, size.height * .60),
          Offset(size.width * .88, size.height * .42),
        );
        path(<Offset>[
          Offset(size.width * .78, size.height * .86),
          Offset(size.width * .08, size.height * .66),
          Offset(size.width * .46, size.height * .41),
          Offset(size.width * .72, size.height * .55),
        ]);
        ball(Offset(size.width * .78, size.height * .86));
      case _RuleArt.direct:
        canvas.drawLine(
          Offset(size.width * .5, 8),
          Offset(size.width * .5, size.height - 8),
          Paint()
            ..color = BbTokens.primaryGold
            ..strokeWidth = 2,
        );
        target(
          Offset(size.width * .25, size.height * .28),
          1,
          BbTokens.dangerRed,
        );
        launcherAt(Offset(size.width * .25, size.height * .86));
        path(<Offset>[
          Offset(size.width * .25, size.height * .73),
          Offset(size.width * .25, size.height * .40),
        ]);
        resultMark(Offset(size.width * .25, size.height * .62), success: false);
        target(
          Offset(size.width * .75, size.height * .28),
          1,
          BbTokens.dangerRed,
          armed: true,
        );
        sideWall(size.width * .96);
        launcherAt(Offset(size.width * .75, size.height * .86), angle: -1.05);
        path(<Offset>[
          Offset(size.width * .75, size.height * .73),
          Offset(size.width * .96, size.height * .57),
          Offset(size.width * .75, size.height * .39),
        ]);
        resultMark(Offset(size.width * .75, size.height * .62), success: true);
      case _RuleArt.score:
        sideWall(size.width * .08);
        target(
          Offset(size.width * .75, size.height * .50),
          2,
          BbTokens.tertiaryPurple,
          armed: true,
        );
        path(<Offset>[
          Offset(size.width * .42, size.height * .86),
          Offset(size.width * .08, size.height * .56),
          Offset(size.width * .44, size.height * .16),
          Offset(size.width * .66, size.height * .43),
        ]);
        launcherAt(Offset(size.width * .42, size.height * .86), angle: -2.45);
        _diagramText(
          canvas,
          '×3',
          Offset(size.width * .73, size.height * .28),
          29,
          BbTokens.primaryGold,
        );
        _diagramText(
          canvas,
          '+300',
          Offset(size.width * .73, size.height * .76),
          19,
          BbTokens.primaryGold,
        );
      case _RuleArt.floor:
        final double floorY = size.height * .84;
        launcherAt(Offset(size.width * .35, floorY - 9 * unit), angle: -1.05);
        _dashedLine(
          canvas,
          Offset(size.width * .05, floorY),
          Offset(size.width * .95, floorY),
          Paint()
            ..color = BbTokens.dangerRed
            ..strokeWidth = 2.2 * unit,
        );
        path(<Offset>[
          Offset(size.width * .35, floorY - 13 * unit),
          Offset(size.width * .78, size.height * .30),
          Offset(size.width * .66, floorY - 4 * unit),
        ]);
        ball(Offset(size.width * .66, floorY - 4 * unit));
        canvas.drawLine(
          Offset(size.width * .66, floorY + 4 * unit),
          Offset(size.width * .66, size.height * .96),
          Paint()
            ..color = BbTokens.dangerRed
            ..strokeWidth = 3 * unit
            ..strokeCap = StrokeCap.round,
        );
        final Offset tip = Offset(size.width * .66, size.height * .97);
        canvas.drawPath(
          Path()
            ..moveTo(tip.dx, tip.dy)
            ..lineTo(tip.dx - 8, tip.dy - 10)
            ..lineTo(tip.dx + 8, tip.dy - 10)
            ..close(),
          Paint()..color = BbTokens.dangerRed,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _RuleDiagram oldDelegate) =>
      oldDelegate.art != art;
}

void _dashedLine(Canvas canvas, Offset from, Offset to, Paint paint) {
  final double length = (to - from).distance;
  if (length == 0) return;
  final Offset direction = (to - from) / length;
  for (double d = 0; d < length; d += 11) {
    canvas.drawLine(
      from + direction * d,
      from + direction * math.min(d + 6, length),
      paint,
    );
  }
}

void _diagramText(
  Canvas canvas,
  String value,
  Offset center,
  double size,
  Color color,
) {
  final TextPainter painter = TextPainter(
    text: TextSpan(
      text: value,
      style: TextStyle(
        color: color,
        fontFamily: BbText.displayFamily,
        fontSize: size,
        fontWeight: FontWeight.w800,
        shadows: const <Shadow>[
          Shadow(color: BbTokens.outlineDark, offset: Offset(0, 2)),
        ],
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  painter.paint(canvas, center - Offset(painter.width / 2, painter.height / 2));
}
