import 'geometry.dart';

/// The arena is a fixed logical space, letterboxed into whatever the screen
/// gives us. All simulation happens in these units, so behaviour is identical
/// on every device — which matters because App Review tested on an iPad.
const double kArenaWidth = 100;
const double kArenaHeight = 160;

const double kBallRadius = 2.2;
const double kTargetRadius = 4.6;

/// Logical units per second. At this speed a shot crosses the arena in ~1.2s,
/// which is slow enough to read a carom and fast enough to feel like a shot.
const double kShotSpeed = 132;

/// A shot expires after this many banks.
///
/// This number is load-bearing and was NOT guessed. At the original value of 14
/// a brute-force sweep over 721 aim angles found that all three arenas could be
/// cleared with a **single** shot for a full 3 stars, by firing almost flat and
/// letting the ball ping-pong across the arena. That made the shot budget and
/// every `requiredBanks` value decoration, and reduced the game to "aim low".
///
/// At 5, no arena is clearable in one shot, the strongest single shot takes 2
/// targets, and a perfect clear needs at least 2 shots out of 4. Raising this
/// re-opens the degenerate strategy — re-run the solver if you change it.
const int kMaxBanks = 5;

/// Highest BỪA multiplier. Matched to [kMaxBanks] so the curve tops out exactly
/// when the shot does; a cap above the bank budget is unreachable decoration.
const int kMaxMultiplier = 6;

const int kPointsPerTarget = 100;

/// Where the launcher sits.
const V2 kShooterOrigin = V2(kArenaWidth / 2, 150);

class TargetSpec {
  const TargetSpec(
    this.pos,
    this.requiredBanks, {
    this.palette = 0,
  });

  final V2 pos;

  /// Minimum banks the projectile must have accumulated before this target can
  /// be broken. **This is the whole game.** A projectile that arrives with
  /// fewer banks bounces off and the target reacts smugly.
  final int requiredBanks;

  /// Index into the render palette. Presentation only.
  final int palette;
}

/// Axis-aligned solid obstacle.
class BlockSpec {
  const BlockSpec(this.left, this.top, this.right, this.bottom);

  final double left;
  final double top;
  final double right;
  final double bottom;

  List<Segment> toSegments() {
    final V2 tl = V2(left, top);
    final V2 tr = V2(right, top);
    final V2 br = V2(right, bottom);
    final V2 bl = V2(left, bottom);
    return <Segment>[
      Segment(tl, tr, kind: SurfaceKind.block),
      Segment(tr, br, kind: SurfaceKind.block),
      Segment(br, bl, kind: SurfaceKind.block),
      Segment(bl, tl, kind: SurfaceKind.block),
    ];
  }
}

/// A single-sided-looking but physically double-sided angled bumper.
class DeflectorSpec {
  const DeflectorSpec(this.a, this.b);

  final V2 a;
  final V2 b;

  Segment toSegment() => Segment(a, b, kind: SurfaceKind.deflector);
}

class ArenaSpec {
  const ArenaSpec({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.hint,
    required this.hintEn,
    required this.shots,
    required this.targets,
    required this.starThresholds,
    this.blocks = const <BlockSpec>[],
    this.deflectors = const <DeflectorSpec>[],
  });

  final int id;

  /// Vietnamese is the primary language, as in the parent project. English is
  /// carried alongside rather than through ARB because `lib/sim/` must not
  /// import Flutter — it has to stay unit-testable without a widget tree.
  final String name;
  final String nameEn;
  final String hint;
  final String hintEn;
  final int shots;
  final List<TargetSpec> targets;

  /// Three ascending score thresholds for 1/2/3 stars.
  final List<int> starThresholds;

  final List<BlockSpec> blocks;
  final List<DeflectorSpec> deflectors;
}

/// Arena boundary. There is deliberately **no bottom wall** — a shot that
/// comes back down past the launcher is gone. That is the cost that makes
/// chasing a high multiplier a real decision instead of free money.
List<Segment> arenaWalls() => const <Segment>[
      Segment(V2(0, 0), V2(0, kArenaHeight)),
      Segment(V2(kArenaWidth, 0), V2(kArenaWidth, kArenaHeight)),
      Segment(V2(0, 0), V2(kArenaWidth, 0)),
    ];

/// Flattens an arena into the segment soup the simulation actually collides
/// against. Order is irrelevant; every segment is tested every substep.
List<Segment> buildSegments(ArenaSpec arena) {
  final List<Segment> out = <Segment>[...arenaWalls()];
  for (final BlockSpec b in arena.blocks) {
    out.addAll(b.toSegments());
  }
  for (final DeflectorSpec d in arena.deflectors) {
    out.add(d.toSegment());
  }
  return out;
}

/// Picks the Vietnamese or English string for a locale code.
String forLocale(String code, String vi, String en) => code == 'en' ? en : vi;
