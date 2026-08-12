import 'dart:io';

import 'package:ban_bua_tuong/sim/arena.dart';
import 'package:ban_bua_tuong/sim/arenas.dart';
import 'package:ban_bua_tuong/sim/hint_finder.dart';
import 'package:ban_bua_tuong/sim/shot_runner.dart';
import 'package:flutter_test/flutter_test.dart';

ArenaSnapshot _arenaSnapshot(List<bool> alive) {
  final ArenaSpec arena = kArenas.first;
  return ArenaSnapshot(
    segments: buildSegments(arena),
    targets: arena.targets,
    alive: alive,
    origin: kShooterOrigin,
    arenaId: arena.id,
    budget: const Duration(seconds: 10),
  );
}

void main() {
  test('finds a deterministic useful shot without mutating the arena', () {
    final List<bool> alive = List<bool>.filled(
      kArenas.first.targets.length,
      true,
    );
    final HintShot? first = findHintShot(_arenaSnapshot(alive));
    final HintShot? second = findHintShot(_arenaSnapshot(alive));
    expect(first, isNotNull);
    expect(second, isNotNull);
    expect(first!.targetsDestroyed, greaterThanOrEqualTo(1));
    expect(first.targetIndices, isNotEmpty);
    expect(first.path.first.x, kShooterOrigin.x);
    expect(first.path.first.y, kShooterOrigin.y);
    expect(first.path.last.y, inInclusiveRange(0, kArenaHeight));
    expect(second!.aim.x, closeTo(first.aim.x, 1e-12));
    expect(second.aim.y, closeTo(first.aim.y, 1e-12));
    expect(alive, everyElement(isTrue));

    final List<bool> replayAlive = List<bool>.of(alive);
    final ShotRunner replay = ShotRunner(
      segments: _arenaSnapshot(alive).segments,
      targets: kArenas.first.targets,
      alive: replayAlive,
      origin: kShooterOrigin,
      direction: first.aim,
      recordTrail: false,
    );
    int guard = 0;
    while (replay.ball.alive && guard < kHintSimulationStepGuard) {
      replay.step(kHintSimulationDt);
      guard++;
    }
    for (final int targetIndex in first.targetIndices) {
      expect(
        replayAlive[targetIndex],
        isFalse,
        reason: 'Hint target $targetIndex must break when its aim is replayed',
      );
    }
  });

  test(
    'uses the current alive snapshot and returns null for an empty arena',
    () {
      expect(
        findHintShot(
          _arenaSnapshot(
            List<bool>.filled(kArenas.first.targets.length, false),
          ),
        ),
        isNull,
      );
    },
  );

  test('simulation boundary stays free of Flutter imports', () {
    final String source = File('lib/sim/hint_finder.dart').readAsStringSync();
    expect(source, isNot(contains('package:flutter/')));
  });

  test('guard covers the ShotRunner fourteen-second timeout', () {
    expect(kHintSimulationDt, 1 / 120);
    expect(kHintSimulationStepGuard, greaterThanOrEqualTo(14 * 120));
  });
}
