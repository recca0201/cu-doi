import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/bb_theme.dart';
import '../../core/bb_tokens.dart';
import '../../domain/character.dart';
import '../../l10n/app_localizations.dart';
import '../character_dialogue.dart';
import '../widgets/bb_widgets.dart';

abstract final class _TutorialArt {
  static const String title = 'assets/images/ui/galaxy/tutorial_title.png';
  static const String close = 'assets/images/ui/galaxy/tutorial_close.png';
  static const String stepBadge =
      'assets/images/ui/galaxy/tutorial_step_badge.png';
  static const String cardFrame =
      'assets/images/ui/galaxy/tutorial_card_frame.png';
  static const String gotItVi =
      'assets/images/ui/galaxy/tutorial_got_it_vi.png';
  static const String dontShowVi =
      'assets/images/ui/galaxy/tutorial_dont_show_vi.png';
}

enum _RuleArt { aim, bounce, direct, score, floor }

class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key, this.onDontShowAgain});

  final VoidCallback? onDontShowAgain;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: BbTokens.nightIndigo,
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
    final bool isVietnamese =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'vi';
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
          child: IgnorePointer(child: CustomPaint(painter: _RulesBackdrop())),
        ),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
              child: Column(
                children: <Widget>[
                  _RulesHeader(
                    title: t.howToTitle,
                    isVietnamese: isVietnamese,
                    onClose: onDismiss,
                  ),
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
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: isVietnamese
                            ? BbAssetButton(
                                asset: _TutorialArt.gotItVi,
                                height: 58,
                                semanticLabel: t.gotItCta,
                                hiddenText: t.gotItCta,
                                onPressed: onDismiss,
                              )
                            : BbButton.primary(
                                label: t.gotItCta,
                                size: BbSize.lg,
                                icon: Icons.check_rounded,
                                expand: true,
                                onPressed: onDismiss,
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: isVietnamese
                            ? BbAssetButton(
                                asset: _TutorialArt.dontShowVi,
                                height: 58,
                                semanticLabel: t.dontShowAgainCta,
                                hiddenText: t.dontShowAgainCta,
                                onPressed: onDontShowAgain,
                              )
                            : BbButton.secondary(
                                label: t.dontShowAgainCta,
                                size: BbSize.lg,
                                icon: Icons.check_box_rounded,
                                expand: true,
                                onPressed: onDontShowAgain,
                              ),
                      ),
                    ],
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
  const _RulesHeader({
    required this.title,
    required this.isVietnamese,
    required this.onClose,
  });

  final String title;
  final bool isVietnamese;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 104,
    child: Stack(
      alignment: Alignment.center,
      children: <Widget>[
        if (!isVietnamese)
          Positioned(
            left: 18,
            right: 18,
            bottom: 8,
            child: Container(
              height: 47,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: <Color>[Color(0xFF0B54B4), Color(0xFF183486)],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: BbTokens.outlineDark, width: 4),
                boxShadow: BbTokens.sticker(4),
              ),
            ),
          ),
        Positioned(
          left: 22,
          right: 22,
          top: 10,
          child: SizedBox(
            key: const Key('how-to-title'),
            height: 78,
            child: isVietnamese
                ? Image.asset(
                    _TutorialArt.title,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  )
                : BbGameTitle(label: title, height: 72, fontSize: 58),
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
          child: BbAssetButton(
            asset: _TutorialArt.close,
            semanticLabel: MaterialLocalizations.of(context).closeButtonTooltip,
            width: 48,
            height: 48,
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
    constraints: const BoxConstraints(minHeight: 126),
    padding: const EdgeInsets.fromLTRB(9, 10, 12, 10),
    decoration: BoxDecoration(
      image: const DecorationImage(
        image: AssetImage(_TutorialArt.cardFrame),
        fit: BoxFit.fill,
      ),
      borderRadius: BorderRadius.circular(18),
      boxShadow: const <BoxShadow>[
        BoxShadow(color: BbTokens.outlineDark, offset: Offset(0, 4)),
      ],
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Align(
          alignment: Alignment.topCenter,
          child: _StepBadge(number: number),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 5,
          child: SizedBox(
            height: 104,
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
        const SizedBox(width: 12),
        Expanded(
          flex: 5,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: BbText.h3(BbTokens.primaryGold).copyWith(fontSize: 18),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: BbText.small(Colors.white).copyWith(fontSize: 13),
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
      image: const DecorationImage(
        image: AssetImage(_TutorialArt.stepBadge),
        fit: BoxFit.contain,
      ),
      shape: BoxShape.circle,
    ),
    child: Text(
      '$number',
      style: BbText.h2(Colors.white).copyWith(
        fontSize: 25,
        shadows: const <Shadow>[
          Shadow(color: BbTokens.outlineDark, offset: Offset(0, 2)),
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
      color: const Color(0xF20A1B46),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: BbTokens.secondaryBlue, width: 2),
    ),
    child: Row(
      children: <Widget>[
        const Icon(
          Icons.lightbulb_rounded,
          color: BbTokens.primaryGold,
          size: 31,
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: BbText.small(Colors.white))),
        const SizedBox(width: 8),
        for (int i = 1; i <= 4; i++) ...<Widget>[
          _MiniTarget(number: i),
          if (i < 4) const SizedBox(width: 4),
        ],
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
    return Container(
      width: 31,
      height: 31,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors[number - 1],
        border: Border.all(color: BbTokens.outlineDark, width: 2),
      ),
      child: Text(
        '$number',
        style: BbText.button(Colors.white).copyWith(fontSize: 14),
      ),
    );
  }
}

class _RulesBackdrop extends CustomPainter {
  const _RulesBackdrop();

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, -.5),
          radius: 1.1,
          colors: <Color>[Color(0xFF12356E), Color(0xFF050C25)],
        ).createShader(rect),
    );
    final Paint rail = Paint()
      ..color = const Color(0xFF45658F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    final RRect frame = RRect.fromRectAndRadius(
      Rect.fromLTRB(5, 5, size.width - 5, size.height - 5),
      const Radius.circular(22),
    );
    canvas.drawRRect(frame, rail);
    canvas.drawRRect(
      frame,
      Paint()
        ..color = BbTokens.trajectoryCyan.withValues(alpha: .45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    final Paint mote = Paint()
      ..color = BbTokens.trajectoryCyan.withValues(alpha: .13);
    for (int i = 0; i < 34; i++) {
      canvas.drawCircle(
        Offset(
          ((i * 83 + 17) % 401) / 401 * size.width,
          ((i * 137 + 23) % 409) / 409 * size.height,
        ),
        i % 8 == 0 ? 2 : .8,
        mote,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RulesBackdrop oldDelegate) => false;
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
      canvas.drawCircle(c, 15, Paint()..color = color);
      _diagramText(canvas, '$number', c + const Offset(0, 2), 18, Colors.white);
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
