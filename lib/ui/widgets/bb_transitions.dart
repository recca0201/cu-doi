import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Pushes [page] with a circular "iris" reveal growing out of [center] — a
/// global screen position, typically the level node or button that was tapped,
/// so the target screen feels like it bloomed from what the thumb touched.
///
/// Falls back to a plain fade when the platform asks for reduced motion, matching
/// the rest of the game's motion gating.
Route<T> bbRevealRoute<T>({
  required Widget page,
  required Offset center,
  Duration duration = const Duration(milliseconds: 520),
}) => PageRouteBuilder<T>(
  transitionDuration: duration,
  reverseTransitionDuration: const Duration(milliseconds: 260),
  pageBuilder: (_, _, _) => page,
  transitionsBuilder: (context, anim, _, child) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return FadeTransition(opacity: anim, child: child);
    }
    final curved = CurvedAnimation(parent: anim, curve: Curves.easeInOutCubic);
    return AnimatedBuilder(
      animation: curved,
      child: child,
      builder: (_, child) => ClipPath(
        clipper: _CircleReveal(center: center, fraction: curved.value),
        child: child,
      ),
    );
  },
);

/// The centre of the render box behind [context], in global coordinates. Returns
/// the screen centre when the box is not laid out yet, so callers always get a
/// usable origin.
Offset bbCenterOf(BuildContext context) {
  final box = context.findRenderObject() as RenderBox?;
  if (box == null || !box.hasSize) {
    final size = MediaQuery.sizeOf(context);
    return Offset(size.width / 2, size.height / 2);
  }
  return box.localToGlobal(box.size.center(Offset.zero));
}

class _CircleReveal extends CustomClipper<Path> {
  const _CircleReveal({required this.center, required this.fraction});

  final Offset center;
  final double fraction;

  @override
  Path getClip(Size size) => Path()
    ..addOval(
      Rect.fromCircle(center: center, radius: _maxRadius(size) * fraction),
    );

  /// Distance from [center] to the furthest corner — the radius at which the
  /// circle has covered the whole screen.
  double _maxRadius(Size size) {
    final dx = math.max(center.dx, size.width - center.dx);
    final dy = math.max(center.dy, size.height - center.dy);
    return math.sqrt(dx * dx + dy * dy);
  }

  @override
  bool shouldReclip(_CircleReveal old) =>
      old.fraction != fraction || old.center != center;
}
