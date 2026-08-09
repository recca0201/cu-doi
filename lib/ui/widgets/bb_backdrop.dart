import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/bb_tokens.dart';

/// Signature candy-dot texture — a faint staggered grid of soft circles that
/// gives every screen the same "bubble wrapper" feel. Purely decorative and
/// non-interactive.
class BbDotPattern extends StatelessWidget {
  const BbDotPattern({
    super.key,
    this.color = BbTokens.surface,
    this.opacity = 0.12,
    this.gap = 34,
    this.radius = 4,
  });

  final Color color;
  final double opacity;
  final double gap;
  final double radius;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: CustomPaint(
      size: Size.infinite,
      painter: _DotPainter(
        color: color,
        opacity: opacity,
        gap: gap,
        radius: radius,
      ),
    ),
  );
}

/// Layered galaxy atmosphere used behind arcade-night screens. Everything is
/// deterministic so golden tests stay stable, while the soft nebulae, star
/// clusters and diffraction flares read as deep space instead of dotted paper.
class BbStarfield extends StatelessWidget {
  const BbStarfield({super.key, this.opacity = 0.5});

  final double opacity;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: CustomPaint(
      size: Size.infinite,
      painter: _StarfieldPainter(opacity),
    ),
  );
}

class _StarfieldPainter extends CustomPainter {
  const _StarfieldPainter(this.opacity);

  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect bounds = Offset.zero & size;

    void nebula(Alignment center, double radius, Color color, double alpha) {
      final Offset c = center.alongSize(size);
      final double r = size.longestSide * radius;
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: <Color>[
              color.withValues(alpha: opacity * alpha),
              color.withValues(alpha: opacity * alpha * .28),
              color.withValues(alpha: 0),
            ],
            stops: const <double>[0, .38, 1],
          ).createShader(Rect.fromCircle(center: c, radius: r)),
      );
    }

    nebula(const Alignment(-.9, -.72), .34, const Color(0xFF7B3FF2), .24);
    nebula(const Alignment(.92, -.05), .42, const Color(0xFF00B8D9), .17);
    nebula(const Alignment(-.55, .92), .38, const Color(0xFFE349B7), .12);

    // A faint diagonal Milky-Way band breaks the uniform dot-field silhouette.
    canvas.save();
    canvas.clipRect(bounds);
    canvas.translate(size.width * .52, size.height * .48);
    canvas.rotate(-.34);
    final Rect band = Rect.fromCenter(
      center: Offset.zero,
      width: size.longestSide * 1.7,
      height: size.shortestSide * .28,
    );
    canvas.drawOval(
      band,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Colors.transparent,
            const Color(0xFF93DFFF).withValues(alpha: opacity * .045),
            const Color(0xFFD7B5FF).withValues(alpha: opacity * .085),
            Colors.transparent,
          ],
        ).createShader(band),
    );
    canvas.restore();

    final Paint dot = Paint()
      ..color = Colors.white.withValues(alpha: opacity * .42);
    final Paint cyan = Paint()
      ..color = BbTokens.trajectoryCyan.withValues(alpha: opacity * .55);
    final Paint gold = Paint()
      ..color = BbTokens.primaryGold.withValues(alpha: opacity * .65);
    for (int i = 0; i < 86; i++) {
      final double x = ((i * 83 + 29) % 997) / 997 * size.width;
      final double y = ((i * 137 + 47) % 991) / 991 * size.height;
      canvas.drawCircle(
        Offset(x, y),
        i % 17 == 0 ? 1.7 : (i % 5 == 0 ? 1.05 : .58),
        i % 13 == 0 ? cyan : dot,
      );
    }
    for (int i = 0; i < 8; i++) {
      final Offset p = Offset(
        ((i * 151 + 61) % 947) / 947 * size.width,
        ((i * 211 + 89) % 953) / 953 * size.height,
      );
      final double r = i.isEven ? 3.5 : 2.5;
      canvas.drawCircle(
        p,
        r * 2.6,
        Paint()
          ..shader = RadialGradient(
            colors: <Color>[
              BbTokens.trajectoryCyan.withValues(alpha: opacity * .18),
              Colors.transparent,
            ],
          ).createShader(Rect.fromCircle(center: p, radius: r * 2.6)),
      );
      canvas.drawLine(
        p - Offset(r, 0),
        p + Offset(r, 0),
        gold..strokeWidth = .8,
      );
      canvas.drawLine(p - Offset(0, r), p + Offset(0, r), gold);
    }
  }

  @override
  bool shouldRepaint(covariant _StarfieldPainter oldDelegate) =>
      oldDelegate.opacity != opacity;
}

class _DotPainter extends CustomPainter {
  _DotPainter({
    required this.color,
    required this.opacity,
    required this.gap,
    required this.radius,
  });

  final Color color;
  final double opacity;
  final double gap;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: opacity);
    var row = 0;
    for (var y = gap / 2; y < size.height + gap; y += gap) {
      final offset = row.isEven ? 0.0 : gap / 2;
      for (var x = gap / 2 + offset; x < size.width + gap; x += gap) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
      row++;
    }
  }

  @override
  bool shouldRepaint(covariant _DotPainter old) =>
      old.color != color ||
      old.opacity != opacity ||
      old.gap != gap ||
      old.radius != radius;
}

/// Comic sunburst of soft wedges radiating from the centre; slowly spins to add
/// energy behind hero moments (menu logo, win celebration). The brand's second
/// signature after the sticker shadow. Falls back to a static burst under
/// reduced-motion.
class BbSunburst extends StatefulWidget {
  const BbSunburst({
    super.key,
    this.color = BbTokens.cream,
    this.rays = 12,
    this.opacity = 0.5,
    this.spin = true,
  });

  final Color color;
  final int rays;
  final double opacity;
  final bool spin;

  @override
  State<BbSunburst> createState() => _BbSunburstState();
}

class _BbSunburstState extends State<BbSunburst>
    with SingleTickerProviderStateMixin {
  // Created here rather than lazily: with spin off nothing else touches _c, and
  // building a ticker from dispose() on a deactivated element throws.
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 28),
    );
    if (widget.spin) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final painter = CustomPaint(
      size: Size.infinite,
      painter: _SunburstPainter(
        color: widget.color,
        rays: widget.rays,
        opacity: widget.opacity,
      ),
    );
    if (!widget.spin || MediaQuery.disableAnimationsOf(context)) {
      return IgnorePointer(child: painter);
    }
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) =>
            Transform.rotate(angle: _c.value * 2 * math.pi, child: child),
        child: painter,
      ),
    );
  }
}

class _SunburstPainter extends CustomPainter {
  _SunburstPainter({
    required this.color,
    required this.rays,
    required this.opacity,
  });

  final Color color;
  final int rays;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.longestSide;
    final step = math.pi * 2 / rays;
    final paint = Paint()..color = color.withValues(alpha: opacity);
    for (var i = 0; i < rays; i++) {
      final a = i * step;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(
          center.dx + math.cos(a) * radius,
          center.dy + math.sin(a) * radius,
        )
        ..lineTo(
          center.dx + math.cos(a + step * 0.5) * radius,
          center.dy + math.sin(a + step * 0.5) * radius,
        )
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SunburstPainter old) =>
      old.color != color || old.rays != rays || old.opacity != opacity;
}
