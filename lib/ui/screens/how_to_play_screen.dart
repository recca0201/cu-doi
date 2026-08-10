import 'dart:math' as math;

import 'package:flutter/material.dart';

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
          padding: const EdgeInsets.fromLTRB(28, 20, 34, 22),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Align(
                alignment: Alignment.topCenter,
                child: _StepBadge(number: number),
              ),
              const SizedBox(width: 8),
              Flexible(
                flex: 4,
                child: AspectRatio(
                  aspectRatio: 1.08,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF071638),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: BbTokens.trajectoryCyan.withValues(alpha: .75),
                        width: 1.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: CustomPaint(painter: _RuleDiagram(art)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 6,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    FittedBox(
                      alignment: Alignment.centerLeft,
                      fit: BoxFit.scaleDown,
                      child: Text(
                        title,
                        maxLines: 1,
                        style: BbText.h3(
                          BbTokens.primaryGold,
                        ).copyWith(fontSize: 17),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: BbText.small(
                        Colors.white,
                      ).copyWith(fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
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
    final Paint cyan = Paint()
      ..color = BbTokens.trajectoryCyan
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final Paint glow = Paint()
      ..color = BbTokens.trajectoryCyan.withValues(alpha: .22)
      ..strokeWidth = 9
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final Offset launcher = Offset(size.width * .50, size.height * .84);

    void ball(Offset c, [double radius = 9]) {
      canvas.drawCircle(
        c,
        radius + 5,
        Paint()..color = BbTokens.trajectoryCyan.withValues(alpha: .22),
      );
      canvas.drawCircle(c, radius, Paint()..color = const Color(0xFFE9FBFF));
      canvas.drawCircle(
        c,
        radius,
        Paint()
          ..color = BbTokens.trajectoryCyan
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    void launcherAt(Offset c) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: c, width: 34, height: 25),
          const Radius.circular(8),
        ),
        Paint()..color = const Color(0xFF2479C8),
      );
      canvas.drawCircle(
        c - const Offset(0, 12),
        10,
        Paint()..color = BbTokens.primaryGold,
      );
      canvas.drawCircle(
        c - const Offset(0, 12),
        7,
        Paint()..color = BbTokens.trajectoryCyan,
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
        canvas.drawCircle(point, 4, Paint()..color = Colors.white);
      }
    }

    void target(Offset c, int number, Color color) {
      canvas.drawCircle(c, 19, Paint()..color = color.withValues(alpha: .25));
      paintPangolinBall(
        canvas,
        center: c,
        radius: 15,
        shellColor: color,
        number: number,
        showFace: false,
      );
    }

    switch (art) {
      case _RuleArt.aim:
        launcherAt(launcher);
        final Offset end = Offset(size.width * .80, size.height * .20);
        _dashedLine(canvas, launcher - const Offset(0, 18), end, cyan);
        canvas.drawPath(
          Path()
            ..moveTo(end.dx, end.dy)
            ..lineTo(end.dx - 12, end.dy + 4)
            ..lineTo(end.dx - 5, end.dy + 14)
            ..close(),
          Paint()..color = Colors.white,
        );
        canvas.drawCircle(
          Offset(size.width * .38, size.height * .50),
          13,
          Paint()..color = const Color(0xFFFFB38A),
        );
        canvas.drawLine(
          Offset(size.width * .38, size.height * .50),
          Offset(size.width * .52, size.height * .35),
          Paint()
            ..color = const Color(0xFFFFB38A)
            ..strokeWidth = 9
            ..strokeCap = StrokeCap.round,
        );
      case _RuleArt.bounce:
        final Paint wall = Paint()
          ..color = const Color(0xFF657A9F)
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(size.width * .10, size.height * .16),
          Offset(size.width * .10, size.height * .84),
          wall,
        );
        canvas.drawLine(
          Offset(size.width * .52, size.height * .25),
          Offset(size.width * .82, size.height * .50),
          wall,
        );
        path(<Offset>[
          Offset(size.width * .78, size.height * .82),
          Offset(size.width * .10, size.height * .60),
          Offset(size.width * .52, size.height * .25),
          Offset(size.width * .78, size.height * .12),
        ]);
        ball(Offset(size.width * .78, size.height * .82));
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
          2,
          BbTokens.dangerRed,
        );
        launcherAt(Offset(size.width * .25, size.height * .85));
        path(<Offset>[
          Offset(size.width * .25, size.height * .73),
          Offset(size.width * .25, size.height * .44),
        ]);
        _diagramText(
          canvas,
          '×',
          Offset(size.width * .25, size.height * .62),
          31,
          BbTokens.dangerRed,
        );
        target(
          Offset(size.width * .75, size.height * .28),
          2,
          BbTokens.dangerRed,
        );
        launcherAt(Offset(size.width * .75, size.height * .85));
        path(<Offset>[
          Offset(size.width * .75, size.height * .73),
          Offset(size.width * .92, size.height * .55),
          Offset(size.width * .75, size.height * .42),
        ]);
        _diagramText(
          canvas,
          '✓',
          Offset(size.width * .75, size.height * .62),
          27,
          BbTokens.successGreen,
        );
      case _RuleArt.score:
        path(<Offset>[
          Offset(size.width * .16, size.height * .76),
          Offset(size.width * .16, size.height * .28),
          Offset(size.width * .48, size.height * .14),
          Offset(size.width * .72, size.height * .52),
        ]);
        ball(Offset(size.width * .16, size.height * .76));
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
          Offset(size.width * .67, size.height * .78),
          22,
          BbTokens.primaryGold,
        );
      case _RuleArt.floor:
        launcherAt(Offset(size.width * .40, size.height * .78));
        _dashedLine(
          canvas,
          Offset(size.width * .05, size.height * .70),
          Offset(size.width * .95, size.height * .70),
          Paint()
            ..color = BbTokens.dangerRed
            ..strokeWidth = 3,
        );
        ball(Offset(size.width * .65, size.height * .46));
        canvas.drawLine(
          Offset(size.width * .65, size.height * .57),
          Offset(size.width * .65, size.height * .88),
          Paint()
            ..color = BbTokens.dangerRed
            ..strokeWidth = 4
            ..strokeCap = StrokeCap.round,
        );
        final Offset tip = Offset(size.width * .65, size.height * .90);
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
