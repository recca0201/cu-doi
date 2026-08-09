import 'package:ban_bua_tuong/sim/arena.dart';
import 'package:ban_bua_tuong/sim/arenas.dart';
import 'package:ban_bua_tuong/sim/geometry.dart';
import 'package:ban_bua_tuong/sim/shot_runner.dart';
import 'package:flutter_test/flutter_test.dart';

/// These tests exist because nobody has been able to run the app. The
/// simulation layer is pure Dart precisely so that the rule that makes this
/// game not-a-bubble-shooter can be verified without a device.
///
/// If any of these fail, the mechanic is broken and playtesting is pointless.

/// Flies a shot to its death and returns the runner. Events accumulate in
/// [ShotRunner.pending] because nothing drains them here.
ShotRunner fly({
  required List<TargetSpec> targets,
  required List<bool> alive,
  V2 direction = const V2(0, -1),
  int presetBanks = 0,
  List<Segment>? segments,
}) {
  final ShotRunner runner = ShotRunner(
    segments: segments ?? arenaWalls(),
    targets: targets,
    alive: alive,
    origin: kShooterOrigin,
    direction: direction,
  );
  runner.banks = presetBanks;

  // Generous budget: a shallow shot ping-ponging across the arena can stay
  // alive for ten seconds of simulated flight before it spends its banks.
  double t = 0;
  while (runner.ball.alive && t < 20) {
    runner.step(1 / 120);
    t += 1 / 120;
  }
  return runner;
}

List<ShotEvent> eventsOf(ShotRunner r, ShotEventKind kind) =>
    r.pending.where((ShotEvent e) => e.kind == kind).toList();

void main() {
  group('the rule: banks must be earned before a target can break', () {
    test('a direct hit does NOT break a target that requires one bank', () {
      final List<bool> alive = <bool>[true];
      final ShotRunner r = fly(
        targets: <TargetSpec>[const TargetSpec(V2(50, 100), 1)],
        alive: alive,
      );

      expect(alive[0], isTrue, reason: 'target must survive a direct hit');
      expect(eventsOf(r, ShotEventKind.broke), isEmpty);
      expect(eventsOf(r, ShotEventKind.blocked), isNotEmpty,
          reason: 'the player must get told why nothing happened');
    });

    test('bouncing off an un-earned target earns no bank credit', () {
      final List<bool> alive = <bool>[true];
      final ShotRunner r = fly(
        targets: <TargetSpec>[const TargetSpec(V2(50, 100), 1)],
        alive: alive,
      );

      // Fired straight up, reflected straight back down off the target, out
      // the bottom. It never touched a wall, so it never banked.
      expect(r.banks, 0);
      expect(r.multiplier, 1);
      expect(r.endReason, ShotEndReason.exitedBottom);
    });

    test('the same shot breaks the target once a bank has been banked', () {
      final List<bool> alive = <bool>[true];
      final ShotRunner r = fly(
        targets: <TargetSpec>[const TargetSpec(V2(50, 100), 1)],
        alive: alive,
        presetBanks: 1,
      );

      expect(alive[0], isFalse);
      final List<ShotEvent> broke = eventsOf(r, ShotEventKind.broke);
      expect(broke, hasLength(1));
      expect(broke.first.points, kPointsPerTarget * 2,
          reason: 'one bank means a x2 multiplier');
    });

    test('breaking punches through instead of stopping the shot', () {
      final List<bool> alive = <bool>[true];
      final ShotRunner r = fly(
        targets: <TargetSpec>[const TargetSpec(V2(50, 100), 1)],
        alive: alive,
        presetBanks: 1,
      );

      // Having punched through, the ball kept climbing and hit the top wall.
      // That chain is the whole reward fantasy — if this fails, a big carom
      // can only ever clear one target.
      expect(r.banks, greaterThanOrEqualTo(2));
    });

    test('a shot rakes a line of eligible targets in one pass', () {
      final List<bool> alive = <bool>[true, true, true];
      final ShotRunner r = fly(
        targets: <TargetSpec>[
          const TargetSpec(V2(50, 120), 1),
          const TargetSpec(V2(50, 100), 1),
          const TargetSpec(V2(50, 80), 1),
        ],
        alive: alive,
        presetBanks: 1,
      );

      expect(alive, everyElement(isFalse));
      expect(eventsOf(r, ShotEventKind.broke), hasLength(3));
    });
  });

  group('banking', () {
    test('one wall contact counts exactly once', () {
      // Straight up the middle with no targets: the only surface it can touch
      // is the top wall. Without contact debouncing this racks up dozens of
      // phantom banks while depenetrating.
      final ShotRunner r = fly(targets: <TargetSpec>[], alive: <bool>[]);

      expect(r.banks, 1);
      expect(r.multiplier, 2);
      expect(r.endReason, ShotEndReason.exitedBottom);
    });

    test('a side wall bank raises the multiplier', () {
      final ShotRunner r = fly(
        targets: <TargetSpec>[],
        alive: <bool>[],
        direction: const V2(-1, -1),
      );

      expect(r.banks, greaterThanOrEqualTo(1));
      expect(r.multiplier, greaterThanOrEqualTo(2));
    });

    test('the multiplier is capped', () {
      final ShotRunner r = ShotRunner(
        segments: arenaWalls(),
        targets: <TargetSpec>[],
        alive: <bool>[],
        origin: kShooterOrigin,
        direction: const V2(0, -1),
      );
      r.banks = 500;
      expect(r.multiplier, kMaxMultiplier);
    });

    test('a shot cannot bank forever', () {
      // Fired shallowly so it ping-pongs across the arena and should die on
      // the bank budget rather than escaping out of the bottom.
      final ShotRunner r = fly(
        targets: <TargetSpec>[],
        alive: <bool>[],
        direction: const V2(1, -0.22),
      );
      expect(r.banks, lessThanOrEqualTo(kMaxBanks));
      expect(r.endReason, isNotNull);
      expect(r.endReason, isNot(ShotEndReason.timeout),
          reason: 'timeout means the sim got stuck, not that the shot ended');
    });
  });

  group('aiming', () {
    test('the launcher cannot fire downward or flat', () {
      expect(clampAim(const V2(0, 1)).y, lessThan(0));
      expect(clampAim(const V2(1, 0)).y, lessThan(0));
      expect(clampAim(const V2(-1, 0.5)).y, lessThan(0));
      expect(clampAim(V2.zero).y, lessThan(0));
    });

    test('the preview bends at a target it will bounce off', () {
      final List<V2> path = previewPath(
        segments: arenaWalls(),
        targets: <TargetSpec>[const TargetSpec(V2(50, 100), 1)],
        alive: <bool>[true],
        origin: kShooterOrigin,
        direction: const V2(0, -1),
      );

      // Must have a vertex, otherwise the drawn line runs straight through a
      // target the ball never passes and points somewhere it never goes.
      expect(path.length, greaterThanOrEqualTo(3));
      expect(path.first.y, kShooterOrigin.y);
      expect(path[1].y, greaterThan(90.0));
      expect(path[1].y, lessThan(kShooterOrigin.y));
    });
  });

  group('arena data', () {
    test('every arena is internally coherent', () {
      for (final ArenaSpec a in kArenas) {
        expect(a.targets, isNotEmpty, reason: 'arena ${a.id}');
        expect(a.shots, greaterThan(0), reason: 'arena ${a.id}');
        expect(a.starThresholds, hasLength(3), reason: 'arena ${a.id}');
        for (final TargetSpec t in a.targets) {
          expect(t.requiredBanks, greaterThanOrEqualTo(1),
              reason: 'arena ${a.id}: a target breakable with zero banks '
                  'would defeat the entire mechanic');
          expect(t.requiredBanks, lessThan(kMaxBanks), reason: 'arena ${a.id}');
          expect(t.pos.x, greaterThan(kTargetRadius), reason: 'arena ${a.id}');
          expect(t.pos.x, lessThan(kArenaWidth - kTargetRadius),
              reason: 'arena ${a.id}');
          expect(t.pos.y, greaterThan(kTargetRadius), reason: 'arena ${a.id}');
          expect(t.pos.y, lessThan(kShooterOrigin.y - kTargetRadius * 2),
              reason: 'arena ${a.id}: target sits on top of the launcher');
        }
      }
    });

    test('a fresh shot does not start already touching something', () {
      for (final ArenaSpec a in kArenas) {
        final List<Segment> segments = buildSegments(a);
        for (final Segment s in segments) {
          final V2 closest =
              closestPointOnSegment(kShooterOrigin, s.a, s.b);
          expect((kShooterOrigin - closest).length,
              greaterThan(kBallRadius * 1.5),
              reason: 'arena ${a.id}: the launcher is inside a surface');
        }
      }
    });
  });
}
