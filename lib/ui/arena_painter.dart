import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/arena_ink.dart';
import '../core/bb_theme.dart';
import '../sim/arena.dart';
import '../sim/geometry.dart';
import 'comic_effect_controller.dart';
import 'fit.dart';
import 'pangolin_ball_art.dart';

double _clamp01(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);

double multiplierFontSizeForBanks(int banks) =>
    6.0 + math.min(banks, kMaxBanks - 1) * 0.8;

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
    this.hintPath = const <V2>[],
    required this.ballPos,
    required this.currentBanks,
    required this.shotInFlight,
    required this.stamps,
    required this.shake,
    this.effects = const <EffectElement>[],
    this.reducedMotion = false,
    this.illustratedBackdrop = false,
    this.launcherSprite,
  });

  final ArenaSpec arena;
  final List<bool> alive;
  final V2 aimDirection;
  final List<V2> previewPoints;
  final bool showPreview;
  final List<V2> trail;
  final List<V2> ghostTrail;
  final List<V2> hintPath;
  final V2? ballPos;

  /// Banks accumulated by the shot in flight, or 0 when idle. Drives the
  /// "armed" tell on every target: as the ball climbs the bank count, targets
  /// light up one tier at a time. This is the most important readability
  /// feature in the prototype — it is how the rule teaches itself.
  final int currentBanks;

  final bool shotInFlight;
  final List<Stamp> stamps;
  final double shake;
  final List<EffectElement> effects;
  final bool reducedMotion;
  final bool illustratedBackdrop;
  final ui.Image? launcherSprite;

  @override
  void paint(Canvas canvas, Size size) {
    final ArenaFit fit = ArenaFit.of(size);

    _paintBackdrop(canvas, size);

    canvas.save();
    if (!reducedMotion && shake > 0.001) {
      // Deterministic jitter — no Random inside a paint pass.
      final double a = shake * fit.u(0.9);
      canvas.translate(math.sin(shake * 47) * a, math.cos(shake * 61) * a);
    }

    _paintFrame(canvas, fit);
    _paintBlocks(canvas, fit);
    _paintDeflectors(canvas, fit);
    _paintGhost(canvas, fit);
    _paintHint(canvas, fit);
    _paintEffects(canvas, fit);
    _paintTrail(canvas, fit);
    _paintTargets(canvas, fit);
    if (showPreview && !shotInFlight) _paintAim(canvas, fit);
    _paintLauncher(canvas, fit);
    final V2? ball = ballPos;
    if (ball != null) _paintBall(canvas, fit, ball);
    _paintStamps(canvas, fit);

    canvas.restore();
  }

  void _paintBackdrop(Canvas canvas, Size size) {
    final Rect r = Offset.zero & size;
    if (illustratedBackdrop) {
      canvas.drawRect(
        r,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              const Color(0xFF0A4950).withValues(alpha: .12),
              const Color(0xFF062F34).withValues(alpha: .28),
              const Color(0xFF041A1D).withValues(alpha: .56),
            ],
          ).createShader(r),
      );
      return;
    }
    canvas.drawRect(
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFF286F83),
            Color(0xFF244F55),
            Color(0xFF102E31),
            Color(0xFF071A1C),
          ],
        ).createShader(r),
    );

    void ridge(double base, Color color, List<double> peaks) {
      final Path path = Path()..moveTo(0, size.height);
      for (int i = 0; i < peaks.length; i++) {
        path.lineTo(
          size.width * i / (peaks.length - 1),
          size.height * (base - peaks[i]),
        );
      }
      path
        ..lineTo(size.width, size.height)
        ..close();
      canvas.drawPath(path, Paint()..color = color);
    }

    ridge(.62, const Color(0xFF4B7661).withValues(alpha: .42), <double>[
      .02,
      .13,
      .05,
      .20,
      .04,
      .15,
      .02,
    ]);
    ridge(.82, const Color(0xFF274E42).withValues(alpha: .68), <double>[
      .04,
      .24,
      .09,
      .31,
      .06,
      .21,
      .03,
    ]);
    ridge(1.0, const Color(0xFF112F2A).withValues(alpha: .92), <double>[
      .08,
      .29,
      .14,
      .23,
      .10,
      .32,
      .07,
    ]);

    final Paint mote = Paint()
      ..color = const Color(0xFFFFE0A0).withValues(alpha: .30);
    final Paint blueMote = Paint()
      ..color = const Color(0xFF8FE9FF).withValues(alpha: .42);
    for (int i = 0; i < 38; i++) {
      final double x = ((i * 73 + 19) % 389) / 389 * size.width;
      final double y = ((i * 127 + 31) % 397) / 397 * size.height;
      final Offset p = Offset(x, y);
      canvas.drawCircle(
        p,
        i % 13 == 0 ? 1.45 : .55,
        i % 9 == 0 ? blueMote : mote,
      );
      if (i % 19 == 0) {
        canvas.drawLine(
          p - const Offset(3, 0),
          p + const Offset(3, 0),
          blueMote..strokeWidth = .6,
        );
        canvas.drawLine(
          p - const Offset(0, 3),
          p + const Offset(0, 3),
          blueMote,
        );
      }
    }
  }

  void _paintFrame(Canvas canvas, ArenaFit fit) {
    final Rect arenaRect = Rect.fromPoints(
      fit.toScreen(const V2(0, 0)),
      fit.toScreen(const V2(kArenaWidth, kArenaHeight)),
    );

    // Faint playfield wash so the live area reads as a stage.
    canvas.drawRect(
      arenaRect,
      Paint()..color = Colors.black.withValues(alpha: .06),
    );

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
        ..color = ArenaInk.of(ArenaInk.outline)
        ..style = PaintingStyle.stroke
        ..strokeWidth = fit.u(4.2)
        ..strokeCap = StrokeCap.square,
    );
    canvas.drawPath(
      p,
      Paint()
        ..color = const Color(0xFF075A52)
        ..style = PaintingStyle.stroke
        ..strokeWidth = fit.u(2.8)
        ..strokeCap = StrokeCap.square,
    );
    canvas.drawPath(
      p,
      Paint()
        ..color = ArenaInk.of(ArenaInk.primaryGold, 0xB8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = fit.u(.35),
    );

    final Paint seam = Paint()
      ..color = ArenaInk.of(ArenaInk.outline, 0xCC)
      ..strokeWidth = fit.u(.45);
    for (double y = 15; y < kArenaHeight - 8; y += 24) {
      canvas.drawLine(
        fit.toScreen(V2(0, y)),
        fit.toScreen(V2(2.1, y + 2)),
        seam,
      );
      canvas.drawLine(
        fit.toScreen(V2(kArenaWidth - 2.1, y + 2)),
        fit.toScreen(V2(kArenaWidth, y)),
        seam,
      );
    }

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
      canvas.drawRRect(
        rr.shift(Offset(0, fit.u(.9))),
        Paint()..color = ArenaInk.of(ArenaInk.outline, 0xCC),
      );
      canvas.drawRRect(
        rr,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFF61779B), Color(0xFF243A61)],
          ).createShader(r),
      );
      canvas.drawRRect(
        rr,
        Paint()
          ..color = const Color(0xFF9CB4D6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = fit.u(0.38),
      );
      canvas.drawLine(
        Offset(r.left + fit.u(.8), r.top + fit.u(.7)),
        Offset(r.right - fit.u(.8), r.top + fit.u(.7)),
        Paint()
          ..color = Colors.white.withValues(alpha: .22)
          ..strokeWidth = fit.u(.35)
          ..strokeCap = StrokeCap.round,
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
          ..color = ArenaInk.of(ArenaInk.outline)
          ..strokeWidth = fit.u(4.6)
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawLine(
        a,
        b,
        Paint()
          ..color = const Color(0xFF5E7397)
          ..strokeWidth = fit.u(3.2)
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawLine(
        a,
        b,
        Paint()
          ..color = const Color(0xFFB6C8E2)
          ..strokeWidth = fit.u(.42)
          ..strokeCap = StrokeCap.round,
      );
      for (final Offset bolt in <Offset>[a, b]) {
        canvas.drawCircle(
          bolt,
          fit.u(1.15),
          Paint()..color = ArenaInk.of(ArenaInk.outline),
        );
        canvas.drawCircle(
          bolt,
          fit.u(.55),
          Paint()..color = const Color(0xFFB6C8E2),
        );
      }
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

  void _paintHint(Canvas canvas, ArenaFit fit) {
    if (hintPath.length < 2) return;
    final List<Offset> points = hintPath.map(fit.toScreen).toList();
    final Paint paint = Paint()
      ..color = ArenaInk.of(ArenaInk.primaryGold, ArenaInk.hintAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = fit.u(ArenaInk.hintStrokeWidth)
      ..strokeCap = StrokeCap.round;
    _dashed(
      canvas,
      points,
      paint,
      fit.u(ArenaInk.hintDash),
      fit.u(ArenaInk.hintGap),
    );
    for (int i = 1; i < points.length - 1; i++) {
      canvas.drawCircle(points[i], fit.u(ArenaInk.hintWaypointRadius), paint);
    }
  }

  void _paintEffects(Canvas canvas, ArenaFit fit) {
    if (reducedMotion) return;
    for (final EffectElement element in effects) {
      final double progress = _clamp01(element.age / element.tier.duration);
      final double grow = .35 + .65 * (1 - math.pow(1 - progress, 2));
      final int alpha = ((1 - progress) * 230).round();
      final Offset center = fit.toScreen(element.pos);
      final double length = fit.u(element.tier.spokeLength * grow);
      final double inner = length * .28;
      final double phase = element.kind.index * .37;
      for (int i = 0; i < element.tier.spokeCount; i++) {
        final double angle = phase + math.pi * 2 * i / element.tier.spokeCount;
        final Offset direction = Offset(math.cos(angle), math.sin(angle));
        _paintProtectedSpoke(
          canvas,
          fit,
          center + direction * inner,
          center + direction * length,
          alpha,
          element.tier.spokeWidth,
        );
      }
    }
  }

  void _paintProtectedSpoke(
    Canvas canvas,
    ArenaFit fit,
    Offset from,
    Offset to,
    int alpha,
    double width,
  ) {
    const int pieces = 12;
    for (int piece = 0; piece < pieces; piece++) {
      final double a = piece / pieces;
      final double b = (piece + 1) / pieces;
      final Offset start = Offset.lerp(from, to, a)!;
      final Offset end = Offset.lerp(from, to, b)!;
      final Offset midpoint = Offset.lerp(start, end, .5)!;
      int segmentAlpha = alpha;
      for (int i = 0; i < arena.targets.length; i++) {
        if (!alive[i]) continue;
        final Offset target = fit.toScreen(arena.targets[i].pos);
        if ((midpoint - target).distance < fit.u(kTargetRadius * 1.55)) {
          segmentAlpha = math.min(segmentAlpha, 0x20);
          break;
        }
      }
      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = ArenaInk.of(ArenaInk.trajectoryCyan, segmentAlpha)
          ..strokeWidth = fit.u(width)
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _paintTrail(Canvas canvas, ArenaFit fit) {
    if (trail.length < 2) return;
    canvas.drawPath(
      _pathOf(trail, fit),
      Paint()
        ..color = ArenaInk.of(ArenaInk.trajectoryCyan, 0x26)
        ..style = PaintingStyle.stroke
        ..strokeWidth = fit.u(2.4)
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      _pathOf(trail, fit),
      Paint()
        ..color = ArenaInk.of(ArenaInk.trajectoryCyan, 0xA8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = fit.u(.72)
        ..strokeCap = StrokeCap.round,
    );
    // Hot head of the trail, so the eye can follow a fast carom.
    final int from = trail.length > 26 ? trail.length - 26 : 0;
    canvas.drawPath(
      _pathOf(trail.sublist(from), fit),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = fit.u(.52)
        ..strokeCap = StrokeCap.round,
    );
  }

  void _paintTargets(Canvas canvas, ArenaFit fit) {
    for (int i = 0; i < arena.targets.length; i++) {
      if (!alive[i]) continue;
      final TargetSpec t = arena.targets[i];
      final Offset c = fit.toScreen(t.pos);
      final double r = fit.u(kTargetRadius * 1.18);
      final int base = ArenaInk.targets[t.palette % ArenaInk.targets.length];
      final bool armed = currentBanks >= t.requiredBanks;

      canvas.drawCircle(
        c,
        r * (armed ? 1.72 : 1.38),
        Paint()
          ..color = ArenaInk.of(
            armed ? ArenaInk.energyCyan : 0xFFB86A24,
            armed ? 0x58 : 0x24,
          ),
      );
      canvas.drawCircle(
        c,
        r * 1.16,
        Paint()
          ..color = ArenaInk.of(
            armed ? ArenaInk.energyCyan : 0xFFFFB43C,
            armed ? 0xE8 : 0x8A,
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = fit.u(armed ? .72 : .42),
      );

      paintPangolinBall(
        canvas,
        center: c,
        radius: r,
        shellColor: ArenaInk.of(base),
        armed: armed,
        number: t.requiredBanks,
      );
    }
  }

  void _paintAim(Canvas canvas, ArenaFit fit) {
    if (previewPoints.length < 2) return;
    final List<Offset> pts = previewPoints
        .map((V2 p) => fit.toScreen(p))
        .toList();

    // First leg is confident; anything past the first bank is faint. The
    // production game highlights every bubble a shot will pop, which removes
    // most of the aiming skill. This shows geometry, truncated — enough to
    // learn reflection from, not enough to be handed the answer.
    _dashed(
      canvas,
      pts.sublist(0, 2),
      Paint()
        ..color = ArenaInk.of(ArenaInk.trajectoryCyan, 0xDE)
        ..strokeWidth = fit.u(0.72)
        ..strokeCap = StrokeCap.round,
      fit.u(2.2),
      fit.u(1.8),
    );
    if (pts.length > 2) {
      _dashed(
        canvas,
        pts.sublist(1),
        Paint()
          ..color = ArenaInk.of(ArenaInk.trajectoryCyan, 0x62)
          ..strokeWidth = fit.u(0.52)
          ..strokeCap = StrokeCap.round,
        fit.u(1.5),
        fit.u(2.4),
      );
    }
  }

  void _paintLauncher(Canvas canvas, ArenaFit fit) {
    final Offset c = fit.toScreen(kShooterOrigin);
    final double angle = math.atan2(aimDirection.y, aimDirection.x);
    final ui.Image? sprite = launcherSprite;

    if (sprite != null) {
      canvas.drawCircle(
        c,
        fit.u(8.2),
        Paint()..color = ArenaInk.of(ArenaInk.energyCyan, 0x24),
      );
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(angle);
      canvas.drawImageRect(
        sprite,
        Rect.fromLTWH(0, 0, sprite.width.toDouble(), sprite.height.toDouble()),
        Rect.fromLTRB(-fit.u(5.2), -fit.u(6.2), fit.u(17.2), fit.u(6.2)),
        Paint()..filterQuality = FilterQuality.high,
      );
      canvas.restore();
      canvas.drawCircle(
        c,
        fit.u(4.55),
        Paint()
          ..color = const Color(0xFF0B4C4A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = fit.u(.7),
      );
      paintPangolinBall(
        canvas,
        center: c,
        radius: fit.u(3.65),
        shellColor: const Color(0xFFE97822),
        showFace: false,
      );
      return;
    }

    final Rect pedestal = Rect.fromCenter(
      center: c + Offset(0, fit.u(4.8)),
      width: fit.u(13.5),
      height: fit.u(11),
    );
    final RRect pedestalShape = RRect.fromRectAndRadius(
      pedestal,
      Radius.circular(fit.u(3)),
    );
    canvas.drawRRect(
      pedestalShape.shift(Offset(0, fit.u(1.3))),
      Paint()..color = ArenaInk.of(ArenaInk.galaxyIndigo),
    );
    canvas.drawRRect(
      pedestalShape,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFF3159A7),
            Color(0xFF18204D),
            Color(0xFF0B102E),
          ],
        ).createShader(pedestal),
    );
    canvas.drawRRect(
      pedestalShape,
      Paint()
        ..color = ArenaInk.of(ArenaInk.energyCyan, 0xD8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = fit.u(.7),
    );

    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(angle);
    final RRect barrel = RRect.fromRectAndRadius(
      Rect.fromLTRB(0, -fit.u(2.65), fit.u(11.5), fit.u(2.65)),
      Radius.circular(fit.u(1.2)),
    );
    canvas.drawRRect(
      barrel.inflate(fit.u(.7)),
      Paint()..color = ArenaInk.of(ArenaInk.energyCyan, 0x30),
    );
    canvas.drawRRect(
      barrel,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFF5935BA),
            Color(0xFF193B80),
            Color(0xFF0B1238),
          ],
        ).createShader(barrel.outerRect),
    );
    canvas.drawRRect(
      barrel,
      Paint()
        ..color = ArenaInk.of(ArenaInk.energyCyan)
        ..style = PaintingStyle.stroke
        ..strokeWidth = fit.u(0.55),
    );
    canvas.drawLine(
      Offset(fit.u(1.4), -fit.u(1.25)),
      Offset(fit.u(9.8), -fit.u(1.25)),
      Paint()
        ..color = Colors.white.withValues(alpha: .44)
        ..strokeWidth = fit.u(.28)
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      Offset(fit.u(11), 0),
      fit.u(2.1),
      Paint()
        ..color = ArenaInk.of(ArenaInk.galaxyMagenta, 0xD0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = fit.u(.55),
    );
    canvas.restore();

    canvas.drawCircle(
      c,
      fit.u(6.6),
      Paint()..color = ArenaInk.of(ArenaInk.energyCyan, 0x28),
    );
    canvas.drawCircle(
      c,
      fit.u(5.45),
      Paint()..color = ArenaInk.of(ArenaInk.galaxyIndigo),
    );
    canvas.drawCircle(
      c,
      fit.u(4.75),
      Paint()
        ..shader = SweepGradient(
          colors: <Color>[
            ArenaInk.of(ArenaInk.energyCyan),
            ArenaInk.of(ArenaInk.galaxyMagenta),
            ArenaInk.of(ArenaInk.energyCyan),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: fit.u(4.75))),
    );
    paintPangolinBall(
      canvas,
      center: c,
      radius: fit.u(3.65),
      shellColor: const Color(0xFFE97822),
      showFace: false,
    );
  }

  void _paintBall(Canvas canvas, ArenaFit fit, V2 pos) {
    final Offset c = fit.toScreen(pos);
    canvas.drawCircle(
      c,
      fit.u(kBallRadius * 3.4),
      Paint()..color = ArenaInk.of(ArenaInk.energyCyan, 0x24),
    );
    canvas.drawCircle(
      c,
      fit.u(kBallRadius * 2.25),
      Paint()..color = const Color(0xFFFFB43C).withValues(alpha: .14),
    );
    paintPangolinBall(
      canvas,
      center: c,
      radius: fit.u(kBallRadius),
      shellColor: const Color(0xFFE97822),
      armed: currentBanks > 0,
      showFace: false,
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
      final Offset at =
          fit.toScreen(s.pos) -
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
