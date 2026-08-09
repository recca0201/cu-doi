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
