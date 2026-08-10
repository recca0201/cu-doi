import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/bb_theme.dart';
import '../core/bb_tokens.dart';

/// Shared code-native art for the pangolin ball cast. Keeping this in one
/// painter makes the live arena, tutorials and map previews tell the same
/// visual story without loading a sprite for every target colour and state.
void paintPangolinBall(
  Canvas canvas, {
  required Offset center,
  required double radius,
  required Color shellColor,
  bool armed = false,
  bool showFace = true,
  int? number,
  Color outline = BbTokens.outlineDark,
}) {
  final Color light = Color.lerp(shellColor, Colors.white, .32)!;
  final Color dark = Color.lerp(shellColor, outline, .48)!;
  final Color plate = Color.lerp(shellColor, const Color(0xFFD98A2B), .26)!;

  canvas.drawCircle(
    center + Offset(0, radius * .08),
    radius,
    Paint()..color = outline.withValues(alpha: .72),
  );
  canvas.drawCircle(
    center,
    radius,
    Paint()
      ..shader = RadialGradient(
        center: const Alignment(-.34, -.42),
        radius: 1.08,
        colors: <Color>[light, shellColor, dark],
        stops: const <double>[0, .56, 1],
      ).createShader(Rect.fromCircle(center: center, radius: radius)),
  );

  if (showFace) {
    // Five broad armour plates make a cleaner helmet silhouette than a ring of
    // tiny scales. The cream mask keeps the expression legible at game size.
    for (final ({double x, double y, double size, double turn}) scale
        in <({double x, double y, double size, double turn})>[
          (x: -.58, y: -.48, size: .38, turn: -.48),
          (x: -.30, y: -.68, size: .42, turn: -.24),
          (x: 0, y: -.77, size: .45, turn: 0),
          (x: .30, y: -.68, size: .42, turn: .24),
          (x: .58, y: -.48, size: .38, turn: .48),
        ]) {
      _paintScale(
        canvas,
        center + Offset(radius * scale.x, radius * scale.y),
        radius * scale.size,
        light,
        plate,
        outline,
        turn: scale.turn,
      );
    }
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(0, radius * .02),
        width: radius * 1.18,
        height: radius * .90,
      ),
      Paint()
        ..shader =
            const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[Color(0xFFFFF3CF), Color(0xFFE8B66A)],
            ).createShader(
              Rect.fromCenter(
                center: center,
                width: radius * 1.18,
                height: radius,
              ),
            ),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(0, radius * .02),
        width: radius * 1.18,
        height: radius * .90,
      ),
      Paint()
        ..color = outline.withValues(alpha: .72)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.8, radius * .065),
    );
  } else {
    // Tiny map/tutorial tokens read better as a curled armoured shell.
    for (int i = 0; i < 3; i++) {
      final double inset = radius * (.28 + i * .24);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: inset),
        -math.pi * .72,
        math.pi * 1.44,
        false,
        Paint()
          ..color = (i.isEven ? light : plate).withValues(alpha: .86)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(.8, radius * .14)
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  canvas.drawCircle(
    center,
    radius,
    Paint()
      ..color = armed ? BbTokens.trajectoryCyan : outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * (armed ? .12 : .075),
  );

  if (showFace) _paintPangolinFace(canvas, center, radius, armed, outline);
  if (number != null) {
    if (showFace) {
      canvas.drawOval(
        Rect.fromCenter(
          center: center + Offset(0, radius * .51),
          width: radius * .68,
          height: radius * .50,
        ),
        Paint()..color = outline.withValues(alpha: .88),
      );
    }
    _paintOutlinedNumber(
      canvas,
      '$number',
      center + Offset(0, radius * (showFace ? .50 : .03)),
      radius * (showFace ? .60 : .88),
      showFace ? const Color(0xFFFFF1B8) : Colors.white,
      outline,
    );
  }
}

void _paintScale(
  Canvas canvas,
  Offset center,
  double size,
  Color light,
  Color dark,
  Color outline, {
  double turn = 0,
}) {
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.rotate(turn);
  final Path path = Path()
    ..moveTo(0, -size)
    ..quadraticBezierTo(size, -size * .1, 0, size)
    ..quadraticBezierTo(-size, -size * .1, 0, -size)
    ..close();
  canvas.drawPath(
    path,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[light, dark],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: size)),
  );
  canvas.drawPath(
    path,
    Paint()
      ..color = outline.withValues(alpha: .72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(.65, size * .13),
  );
  canvas.restore();
}

void _paintPangolinFace(
  Canvas canvas,
  Offset c,
  double r,
  bool armed,
  Color outline,
) {
  final double ex = r * .23;
  final double ey = -r * .16;
  final Paint white = Paint()..color = const Color(0xFFFFFBEC);
  final Paint ink = Paint()..color = outline;
  final double eyeRadius = r * (armed ? .18 : .16);

  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(c.dx - ex, c.dy + ey),
      width: eyeRadius * 1.55,
      height: eyeRadius * 1.75,
    ),
    white,
  );
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(c.dx + ex, c.dy + ey),
      width: eyeRadius * 1.55,
      height: eyeRadius * 1.75,
    ),
    white,
  );
  canvas.drawCircle(
    Offset(c.dx - ex + r * .025, c.dy + ey + r * .025),
    r * .075,
    ink,
  );
  canvas.drawCircle(
    Offset(c.dx + ex - r * .025, c.dy + ey + r * .025),
    r * .075,
    ink,
  );

  final Paint brow = Paint()
    ..color = outline
    ..strokeWidth = r * .105
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(
    Offset(c.dx - ex - r * .16, c.dy + ey - r * .24),
    Offset(c.dx - ex + r * .13, c.dy + ey - r * (armed ? .11 : .17)),
    brow,
  );
  canvas.drawLine(
    Offset(c.dx + ex - r * .13, c.dy + ey - r * (armed ? .11 : .17)),
    Offset(c.dx + ex + r * .16, c.dy + ey - r * .24),
    brow,
  );

  if (armed) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(c.dx, c.dy + r * .17),
        width: r * .25,
        height: r * .18,
      ),
      ink,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(c.dx, c.dy + r * .21),
        width: r * .15,
        height: r * .07,
      ),
      Paint()..color = BbTokens.bbCoral,
    );
    return;
  }

  final Path grin = Path()
    ..moveTo(c.dx - r * .18, c.dy + r * .11)
    ..quadraticBezierTo(
      c.dx + r * .08,
      c.dy + r * .26,
      c.dx + r * .29,
      c.dy + r * .08,
    );
  canvas.drawPath(
    grin,
    Paint()
      ..color = outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * .12
      ..strokeCap = StrokeCap.round,
  );
}

void _paintOutlinedNumber(
  Canvas canvas,
  String value,
  Offset center,
  double fontSize,
  Color fill,
  Color outline,
) {
  TextPainter painter(Paint paint) => TextPainter(
    text: TextSpan(
      text: value,
      style: TextStyle(
        foreground: paint,
        fontFamily: BbText.displayFamily,
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        height: 1,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  final TextPainter stroke = painter(
    Paint()
      ..color = outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = fontSize * .14,
  );
  stroke.paint(canvas, center - Offset(stroke.width / 2, stroke.height / 2));
  final TextPainter face = painter(Paint()..color = fill);
  face.paint(canvas, center - Offset(face.width / 2, face.height / 2));
}

class PangolinBallPainter extends CustomPainter {
  const PangolinBallPainter({
    required this.color,
    this.number,
    this.armed = false,
    this.showFace = false,
  });

  final Color color;
  final int? number;
  final bool armed;
  final bool showFace;

  @override
  void paint(Canvas canvas, Size size) {
    paintPangolinBall(
      canvas,
      center: size.center(Offset.zero),
      radius: size.shortestSide * .46,
      shellColor: color,
      number: number,
      armed: armed,
      showFace: showFace,
    );
  }

  @override
  bool shouldRepaint(covariant PangolinBallPainter oldDelegate) =>
      color != oldDelegate.color ||
      number != oldDelegate.number ||
      armed != oldDelegate.armed ||
      showFace != oldDelegate.showFace;
}
