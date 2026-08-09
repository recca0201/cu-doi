import 'dart:math' as math;

/// Minimal 2D vector.
///
/// Deliberately pure Dart — no `dart:ui`, no Flutter. The whole simulation
/// layer is testable with `flutter test` without a widget tree, which is the
/// only part of this prototype that can be verified mechanically rather than
/// by feel.
class V2 {
  const V2(this.x, this.y);

  final double x;
  final double y;

  static const V2 zero = V2(0, 0);

  V2 operator +(V2 other) => V2(x + other.x, y + other.y);
  V2 operator -(V2 other) => V2(x - other.x, y - other.y);
  V2 operator *(double s) => V2(x * s, y * s);
  V2 operator -() => V2(-x, -y);

  double dot(V2 other) => x * other.x + y * other.y;

  double get lengthSquared => x * x + y * y;
  double get length => math.sqrt(lengthSquared);

  V2 get normalized {
    final double l = length;
    if (l < 1e-9) return zero;
    return V2(x / l, y / l);
  }

  /// Reflection of this vector about a unit normal [n].
  V2 reflect(V2 n) => this - n * (2 * dot(n));

  @override
  String toString() =>
      'V2(${x.toStringAsFixed(2)}, ${y.toStringAsFixed(2)})';
}

/// What a surface is, for scoring and presentation purposes.
///
/// All three reflect identically; they differ only in whether a bounce earns
/// BỪA credit and in how they are drawn.
enum SurfaceKind {
  /// Arena boundary. Earns BỪA credit.
  wall,

  /// Solid obstacle inside the arena. Earns BỪA credit.
  block,

  /// Angled bumper. Earns BỪA credit.
  deflector,
}

class Segment {
  const Segment(this.a, this.b, {this.kind = SurfaceKind.wall});

  final V2 a;
  final V2 b;
  final SurfaceKind kind;

  /// Unit normal, arbitrarily oriented (left of a→b). Only used as a fallback
  /// when a ball's centre lands exactly on the segment and the contact normal
  /// is therefore undefined.
  V2 get fallbackNormal {
    final V2 d = (b - a).normalized;
    return V2(-d.y, d.x);
  }
}

/// Closest point to [p] on the segment [a]→[b].
V2 closestPointOnSegment(V2 p, V2 a, V2 b) {
  final V2 ab = b - a;
  final double len2 = ab.lengthSquared;
  if (len2 < 1e-12) return a;
  double t = (p - a).dot(ab) / len2;
  if (t < 0) t = 0;
  if (t > 1) t = 1;
  return a + ab * t;
}
