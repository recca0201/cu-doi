import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/arena_ink.dart';
import '../core/bb_theme.dart';
import '../sim/arena.dart';
import '../sim/geometry.dart';
import 'fit.dart';

double _clamp01(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);

/// A floating piece of comic feedback. Purely presentational — same spirit as
/// the production game's comic layer, except here it annotates a mechanic that
/// actually exists.
class Stamp {
  Stamp(this.text, this.pos, this.rgb, {this.big = false});

  final String text;
  final V2 pos;

  /// 0xRRGGBB.
  final int rgb;
  final bool big;

  double age = 0;
}

class ArenaPainter extends CustomPainter {
  ArenaPainter({
    required this.arena,
    required this.alive,
    required this.aimDirection,
    required this.previewPoints,
    required this.showPreview,
    required this.trail,
    required this.ghostTrail,
    required this.ballPos,
    required this.currentBanks,
    required this.shotInFlight,
    required this.stamps,
    required this.shake,
  });

  final ArenaSpec arena;
  final List<bool> alive;
  final V2 aimDirection;
  final List<V2> previewPoints;
  final bool showPreview;
  final List<V2> trail;
  final List<V2> ghostTrail;
  final V2? ballPos;

  /// Banks accumulated by the shot in flight, or 0 when idle. Drives the
  /// "armed" tell on every target: as the ball climbs the bank count, targets
  /// light up one tier at a time. This is the most important readability
  /// feature in the prototype — it is how the rule teaches itself.
  final int currentBanks;

  final bool shotInFlight;
  final List<Stamp> stamps;
  final double shake;

  @override
  void paint(Canvas canvas, Size size) {
    final ArenaFit fit = ArenaFit.of(size);

    _paintBackdrop(canvas, size);

    canvas.save();
    if (shake > 0.001) {
      // Deterministic jitter — no Random inside a paint pass.
      final double a = shake * fit.u(0.9);
      canvas.translate(math.sin(shake * 47) * a, math.cos(shake * 61) * a);
    }

    _paintFrame(canvas, fit);
    _paintBlocks(canvas, fit);
    _paintDeflectors(canvas, fit);
    _paintGhost(canvas, fit);
    _paintTrail(canvas, fit);
    _paintTargets(canvas, fit);
    if (showPreview && !shotInFlight) _paintAim(canvas, fit);
    _paintLauncher(canvas, fit);
    final V2? ball = ballPos;
    if (ball != null) _paintBall(canvas, fit, ball);
    _paintMultiplier(canvas, fit, size);
    _paintStamps(canvas, fit);

    canvas.restore();
  }

  void _paintBackdrop(Canvas canvas, Size size) {
    final Rect r = Offset.zero & size;
    canvas.drawRect(
      r,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[ArenaInk.of(ArenaInk.bgTop), ArenaInk.of(ArenaInk.bgBottom)],
        ).createShader(r),
    );
  }

  void _paintFrame(Canvas canvas, ArenaFit fit) {
    final Rect arenaRect = Rect.fromPoints(
      fit.toScreen(const V2(0, 0)),
      fit.toScreen(const V2(kArenaWidth, kArenaHeight)),
    );

    // Faint playfield wash so the live area reads as a stage.
    canvas.drawRect(arenaRect, Paint()..color = ArenaInk.of(ArenaInk.frame, 0x1F));

    // Left, top and right are real walls. The bottom is drawn dashed and red
    // because it is NOT a wall — anything crossing it is lost. That asymmetry
    // is what makes chasing a bigger multiplier a gamble instead of free money.
    final Path p = Path()
      ..moveTo(arenaRect.left, arenaRect.bottom)
      ..lineTo(arenaRect.left, arenaRect.top)
      ..lineTo(arenaRect.right, arenaRect.top)
      ..lineTo(arenaRect.right, arenaRect.bottom);
    canvas.drawPath(
      p,
      Paint()
        ..color = ArenaInk.of(ArenaInk.frame)
        ..style = PaintingStyle.stroke
        ..strokeWidth = fit.u(0.9)
        ..strokeCap = StrokeCap.round,
    );

    _dashed(
      canvas,
      <Offset>[
        Offset(arenaRect.left, arenaRect.bottom),
        Offset(arenaRect.right, arenaRect.bottom),
      ],
      Paint()
        ..color = ArenaInk.of(ArenaInk.danger, 0x77)
        ..strokeWidth = fit.u(0.6)
        ..strokeCap = StrokeCap.round,
      fit.u(2.4),
      fit.u(2.0),
    );
  }

  void _paintBlocks(Canvas canvas, ArenaFit fit) {
    for (final BlockSpec b in arena.blocks) {
      final Rect r = Rect.fromPoints(
        fit.toScreen(V2(b.left, b.top)),
        fit.toScreen(V2(b.right, b.bottom)),
      );
      final RRect rr = RRect.fromRectAndRadius(r, Radius.circular(fit.u(1.2)));
      canvas.drawRRect(rr, Paint()..color = ArenaInk.of(ArenaInk.blockFill));
      canvas.drawRRect(
        rr,
        Paint()
          ..color = ArenaInk.of(ArenaInk.frame, 0x99)
          ..style = PaintingStyle.stroke
          ..strokeWidth = fit.u(0.55),
      );
    }
  }

  void _paintDeflectors(Canvas canvas, ArenaFit fit) {
    for (final DeflectorSpec d in arena.deflectors) {
      final Offset a = fit.toScreen(d.a);
      final Offset b = fit.toScreen(d.b);
      canvas.drawLine(
        a,
        b,
        Paint()
          ..color = ArenaInk.of(ArenaInk.deflector, 0x38)
          ..strokeWidth = fit.u(3.0)
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawLine(
        a,
        b,
        Paint()
          ..color = ArenaInk.of(ArenaInk.deflector)
          ..strokeWidth = fit.u(1.1)
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _paintGhost(Canvas canvas, ArenaFit fit) {
    if (ghostTrail.length < 2) return;
    canvas.drawPath(
      _pathOf(ghostTrail, fit),
      Paint()
        ..color = ArenaInk.of(ArenaInk.cream, 0x24)
        ..style = PaintingStyle.stroke
        ..strokeWidth = fit.u(0.5)
        ..strokeCap = StrokeCap.round,
    );
  }

  void _paintTrail(Canvas canvas, ArenaFit fit) {
    if (trail.length < 2) return;
    canvas.drawPath(
      _pathOf(trail, fit),
      Paint()
        ..color = ArenaInk.of(ArenaInk.cream, 0x59)
        ..style = PaintingStyle.stroke
        ..strokeWidth = fit.u(0.55)
        ..strokeCap = StrokeCap.round,
    );
    // Hot head of the trail, so the eye can follow a fast carom.
    final int from = trail.length > 26 ? trail.length - 26 : 0;
    canvas.drawPath(
      _pathOf(trail.sublist(from), fit),
      Paint()
        ..color = ArenaInk.of(ArenaInk.cream)
        ..style = PaintingStyle.stroke
        ..strokeWidth = fit.u(0.95)
        ..strokeCap = StrokeCap.round,
    );
  }

  void _paintTargets(Canvas canvas, ArenaFit fit) {
    for (int i = 0; i < arena.targets.length; i++) {
      if (!alive[i]) continue;
      final TargetSpec t = arena.targets[i];
      final Offset c = fit.toScreen(t.pos);
      final double r = fit.u(kTargetRadius);
      final int base = ArenaInk.targets[t.palette % ArenaInk.targets.length];
      final bool armed = currentBanks >= t.requiredBanks;

      if (armed) {
        canvas.drawCircle(c, r * 1.55, Paint()..color = ArenaInk.of(base, 0x28));
        canvas.drawCircle(
          c,
          r * 1.24,
          Paint()
            ..color = ArenaInk.of(base, 0x96)
            ..style = PaintingStyle.stroke
            ..strokeWidth = fit.u(0.5),
        );
      }

      canvas.drawCircle(c, r, Paint()..color = ArenaInk.of(base));
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = ArenaInk.of(ArenaInk.outline)
          ..style = PaintingStyle.stroke
          ..strokeWidth = fit.u(0.6),
      );

      _paintFace(canvas, c, r, armed: armed);
      _paintRequirementChip(canvas, fit, c, r, t.requiredBanks, armed: armed);
    }
  }

  /// Armed targets look alarmed; un-armed ones look smug. The face IS the rule
  /// explanation — a player should never have to read the number to get it.
  void _paintFace(Canvas canvas, Offset c, double r, {required bool armed}) {
    final double ex = r * 0.36;
    final double ey = -r * 0.14;
    final Color dark = ArenaInk.of(ArenaInk.outline);

    if (armed) {
      final Paint fill = Paint()..color = dark;
      canvas.drawCircle(Offset(c.dx - ex, c.dy + ey), r * 0.20, fill);
      canvas.drawCircle(Offset(c.dx + ex, c.dy + ey), r * 0.20, fill);
      canvas.drawCircle(Offset(c.dx, c.dy + r * 0.42), r * 0.15, fill);
      return;
    }

    // Half-lidded eyes.
    final Paint lid = Paint()
      ..color = dark
      ..strokeWidth = r * 0.15
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(c.dx - ex - r * 0.16, c.dy + ey),
      Offset(c.dx - ex + r * 0.16, c.dy + ey),
      lid,
    );
    canvas.drawLine(
      Offset(c.dx + ex - r * 0.16, c.dy + ey),
      Offset(c.dx + ex + r * 0.16, c.dy + ey),
      lid,
    );
    // Smirk, pulled to one side.
    final Path smirk = Path()
      ..moveTo(c.dx - r * 0.18, c.dy + r * 0.38)
      ..quadraticBezierTo(
        c.dx + r * 0.10,
        c.dy + r * 0.56,
        c.dx + r * 0.34,
        c.dy + r * 0.30,
      );
    canvas.drawPath(
      smirk,
      Paint()
        ..color = dark
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.13
        ..strokeCap = StrokeCap.round,
    );
  }

  void _paintRequirementChip(
    Canvas canvas,
    ArenaFit fit,
    Offset c,
    double r,
    int required, {
    required bool armed,
  }) {
    final Offset chip = Offset(c.dx + r * 0.78, c.dy - r * 0.78);
    final double cr = r * 0.46;
    final Color accent =
        armed ? ArenaInk.of(ArenaInk.frame) : ArenaInk.of(ArenaInk.cream, 0x66);
    canvas.drawCircle(chip, cr, Paint()..color = ArenaInk.of(ArenaInk.outline));
    canvas.drawCircle(
      chip,
      cr,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = fit.u(0.35),
    );
    _text(
      canvas,
      '$required',
      chip,
      cr * 1.25,
      armed ? ArenaInk.of(ArenaInk.frame) : ArenaInk.of(ArenaInk.cream),
    );
  }

  void _paintAim(Canvas canvas, ArenaFit fit) {
    if (previewPoints.length < 2) return;
    final List<Offset> pts =
        previewPoints.map((V2 p) => fit.toScreen(p)).toList();

    // First leg is confident; anything past the first bank is faint. The
    // production game highlights every bubble a shot will pop, which removes
    // most of the aiming skill. This shows geometry, truncated — enough to
    // learn reflection from, not enough to be handed the answer.
    _dashed(
      canvas,
      pts.sublist(0, 2),
      Paint()
        ..color = ArenaInk.of(ArenaInk.frame, 0x8A)
        ..strokeWidth = fit.u(0.6)
        ..strokeCap = StrokeCap.round,
      fit.u(2.2),
      fit.u(1.8),
    );
    if (pts.length > 2) {
      _dashed(
        canvas,
        pts.sublist(1),
        Paint()
          ..color = ArenaInk.of(ArenaInk.frame, 0x3D)
          ..strokeWidth = fit.u(0.5)
          ..strokeCap = StrokeCap.round,
        fit.u(1.5),
        fit.u(2.4),
      );
    }
  }

  void _paintLauncher(Canvas canvas, ArenaFit fit) {
    final Offset c = fit.toScreen(kShooterOrigin);
    final double angle = math.atan2(aimDirection.y, aimDirection.x);

    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(angle);
    final RRect barrel = RRect.fromRectAndRadius(
      Rect.fromLTRB(0, -fit.u(2.4), fit.u(10), fit.u(2.4)),
      Radius.circular(fit.u(1.2)),
    );
    canvas.drawRRect(barrel, Paint()..color = ArenaInk.of(ArenaInk.frame));
    canvas.drawRRect(
      barrel,
      Paint()
        ..color = ArenaInk.of(ArenaInk.outline)
        ..style = PaintingStyle.stroke
        ..strokeWidth = fit.u(0.5),
    );
    canvas.restore();

    canvas.drawCircle(c, fit.u(5.2), Paint()..color = ArenaInk.of(ArenaInk.outline));
    canvas.drawCircle(c, fit.u(4.0), Paint()..color = ArenaInk.of(ArenaInk.frame));
  }

  void _paintBall(Canvas canvas, ArenaFit fit, V2 pos) {
    final Offset c = fit.toScreen(pos);
    canvas.drawCircle(
      c,
      fit.u(kBallRadius * 2.2),
      Paint()..color = ArenaInk.of(ArenaInk.cream, 0x33),
    );
    canvas.drawCircle(c, fit.u(kBallRadius), Paint()..color = ArenaInk.of(ArenaInk.cream));
  }

  /// Live BỪA multiplier. Only appears once the shot has actually banked, so
  /// the number never sits at ×1 as furniture.
  void _paintMultiplier(Canvas canvas, ArenaFit fit, Size size) {
    if (!shotInFlight || currentBanks <= 0) return;
    final int mult = math.min(1 + currentBanks, kMaxMultiplier);
    _text(
      canvas,
      'BỪA ×$mult',
      Offset(size.width / 2, fit.toScreen(const V2(0, 14)).dy),
      fit.u(11),
      ArenaInk.of(ArenaInk.frame, 0x59),
    );
  }

  void _paintStamps(Canvas canvas, ArenaFit fit) {
    for (final Stamp s in stamps) {
      final double t = _clamp01(s.age / 1.1);
      final int alpha = ((1 - t) * 255).round();
      // Start clear of the target rather than on top of it. Anchoring a stamp
      // at the target centre puts the text under the face it is reacting to,
      // which made the most important message in the game ("Bắn thẳng à?")
      // unreadable at the exact moment it needs to land.
      final Offset at = fit.toScreen(s.pos) -
          Offset(0, fit.u(kTargetRadius + 3.5) + fit.u(7) * t);
      _text(
        canvas,
        s.text,
        at,
        fit.u(s.big ? 7.0 : 4.6) * (1 + 0.18 * (1 - t)),
        ArenaInk.of(s.rgb, alpha),
      );
    }
  }

  // ------------------------------------------------------------------
  // helpers
  // ------------------------------------------------------------------

  Path _pathOf(List<V2> pts, ArenaFit fit) {
    final Path p = Path();
    if (pts.isEmpty) return p;
    final Offset first = fit.toScreen(pts.first);
    p.moveTo(first.dx, first.dy);
    for (int i = 1; i < pts.length; i++) {
      final Offset o = fit.toScreen(pts[i]);
      p.lineTo(o.dx, o.dy);
    }
    return p;
  }

  void _dashed(
    Canvas canvas,
    List<Offset> pts,
    Paint paint,
    double dash,
    double gap,
  ) {
    for (int i = 0; i < pts.length - 1; i++) {
      final Offset a = pts[i];
      final Offset b = pts[i + 1];
      final double len = (b - a).distance;
      if (len < 1e-6) continue;
      final Offset dir = (b - a) / len;
      double t = 0;
      while (t < len) {
        final double e = math.min(t + dash, len);
        canvas.drawLine(a + dir * t, a + dir * e, paint);
        t = e + gap;
      }
    }
  }

  void _text(
    Canvas canvas,
    String value,
    Offset center,
    double fontSize,
    Color color,
  ) {
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          color: color,
          fontFamily: BbText.displayFamily,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant ArenaPainter old) => true;
}
