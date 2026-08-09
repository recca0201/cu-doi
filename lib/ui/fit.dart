import 'dart:math' as math;
import 'dart:ui' show Offset, Size;

import '../sim/arena.dart';
import '../sim/geometry.dart';

/// Letterboxes the fixed logical arena into whatever space the widget gets.
///
/// Simulation never sees pixels. That is what keeps behaviour identical on a
/// phone and on the iPad App Review actually tested on.
class ArenaFit {
  const ArenaFit(this.scale, this.dx, this.dy);

  final double scale;
  final double dx;
  final double dy;

  static ArenaFit of(Size size) {
    final double s = math.min(
      size.width / kArenaWidth,
      size.height / kArenaHeight,
    );
    return ArenaFit(
      s,
      (size.width - kArenaWidth * s) / 2,
      (size.height - kArenaHeight * s) / 2,
    );
  }

  Offset toScreen(V2 p) => Offset(dx + p.x * scale, dy + p.y * scale);

  V2 toLogical(Offset o) => V2((o.dx - dx) / scale, (o.dy - dy) / scale);

  /// Logical units → pixels, for stroke widths and radii.
  double u(double v) => v * scale;
}
