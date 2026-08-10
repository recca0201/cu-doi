import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/bb_tokens.dart';

const String kVietnamKarstBackdrop =
    'assets/images/backgrounds/vietnam_karst_canyon_v2.png';

/// Premium illustrated Vietnamese karst landscape. The gradient keeps bright
/// UI readable while preserving the generated painting's atmospheric depth.
class BbCanyonBackdrop extends StatelessWidget {
  const BbCanyonBackdrop({
    super.key,
    this.scrim = .16,
    this.bottomShade = .38,
    this.alignment = Alignment.center,
  });

  final double scrim;
  final double bottomShade;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Image.asset(
          kVietnamKarstBackdrop,
          fit: BoxFit.cover,
          alignment: alignment,
          filterQuality: FilterQuality.medium,
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                const Color(0xFF063E46).withValues(alpha: scrim * .45),
                const Color(0xFF063E46).withValues(alpha: scrim),
                const Color(0xFF061F23).withValues(alpha: bottomShade),
              ],
              stops: const <double>[0, .55, 1],
            ),
          ),
        ),
      ],
    ),
  );
}

/// Decorative karst frame shared by the rules and gameplay screens.
///
/// It never participates in hit testing, so controls and arena gestures below
/// it remain usable.
class BbKarstFrameOverlay extends StatelessWidget {
  const BbKarstFrameOverlay({super.key});

  @override
  Widget build(BuildContext context) =>
      const IgnorePointer(child: CustomPaint(painter: _KarstFramePainter()));
}

class _KarstFramePainter extends CustomPainter {
  const _KarstFramePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, -.5),
          radius: 1.1,
          colors: <Color>[Color(0x442C806A), Color(0xB8042528)],
        ).createShader(rect),
    );
    final Paint rail = Paint()
      ..color = const Color(0xFF0B675B)
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
        ..color = BbTokens.primaryGold.withValues(alpha: .58)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    final Paint mote = Paint()
      ..color = BbTokens.primaryGold.withValues(alpha: .11);
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
  bool shouldRepaint(covariant _KarstFramePainter oldDelegate) => false;
}

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

/// Layered Vietnamese karst-canyon atmosphere used behind adventure screens.
/// The public name is kept for compatibility with existing screen layouts.
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
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            const Color(0xFF38A9D8).withValues(alpha: opacity * .78),
            const Color(0xFF78C8CF).withValues(alpha: opacity * .52),
            const Color(0xFF163C43).withValues(alpha: opacity * .88),
          ],
        ).createShader(bounds),
    );

    void ridge(double baseY, Color color, List<double> peaks) {
      final Path path = Path()..moveTo(0, size.height);
      for (int i = 0; i < peaks.length; i++) {
        final double x = size.width * i / (peaks.length - 1);
        final double y = size.height * (baseY - peaks[i]);
        path.lineTo(x, y);
      }
      path
        ..lineTo(size.width, size.height)
        ..close();
      canvas.drawPath(path, Paint()..color = color.withValues(alpha: opacity));
    }

    ridge(.72, const Color(0xFF5A8E7A), <double>[
      .03,
      .13,
      .08,
      .23,
      .05,
      .16,
      .02,
    ]);
    ridge(.84, const Color(0xFF315D50), <double>[
      .02,
      .20,
      .06,
      .29,
      .10,
      .24,
      .03,
    ]);
    ridge(.96, const Color(0xFF153D37), <double>[
      .07,
      .28,
      .12,
      .34,
      .06,
      .25,
      .09,
    ]);

    final Paint mist = Paint()
      ..color = const Color(0xFFD9F2DD).withValues(alpha: opacity * .13);
    for (int i = 0; i < 6; i++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(
            size.width * (i * .21 - .03),
            size.height * (.70 + (i % 2) * .06),
          ),
          width: size.width * .42,
          height: size.height * .055,
        ),
        mist,
      );
    }

    final Paint mote = Paint()
      ..color = const Color(0xFFFFE6A8).withValues(alpha: opacity * .58);
    for (int i = 0; i < 32; i++) {
      canvas.drawCircle(
        Offset(
          ((i * 83 + 29) % 997) / 997 * size.width,
          ((i * 137 + 47) % 991) / 991 * size.height * .72,
        ),
        i % 9 == 0 ? 1.5 : .65,
        mote,
      );
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
