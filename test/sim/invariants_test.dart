import 'dart:io';
import 'dart:math' as math;

import 'package:ban_bua_tuong/sim/arena.dart';
import 'package:ban_bua_tuong/sim/arenas.dart';
import 'package:ban_bua_tuong/sim/geometry.dart';
import 'package:ban_bua_tuong/sim/shot_runner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('balance constants and all campaign thresholds remain fixed', () {
    expect(kMaxBanks, 5);
    expect(kMinAimUp, .6);
    expect(kMaxMultiplier, 6);
    expect(kArenas.map((a) => a.starThresholds).toList(), <List<int>>[
      <int>[750, 1100, 1350],
      <int>[750, 1100, 1350],
      <int>[650, 950, 1150],
      <int>[950, 1350, 1700],
      <int>[650, 950, 1150],
      <int>[900, 1300, 1600],
      <int>[750, 1100, 1350],
      <int>[700, 1000, 1250],
      <int>[900, 1300, 1600],
      <int>[750, 1100, 1350],
      <int>[800, 1150, 1450],
      <int>[1150, 1650, 2050],
      <int>[900, 1300, 1600],
      <int>[900, 1300, 1600],
      <int>[900, 1300, 1600],
      <int>[750, 1100, 1350],
      <int>[750, 1100, 1350],
      <int>[1000, 1450, 1800],
      <int>[850, 1200, 1550],
      <int>[1300, 1850, 2350],
    ]);
    for (final FileSystemEntity entity in Directory('lib/sim').listSync()) {
      if (entity is File && entity.path.endsWith('.dart')) {
        expect(entity.readAsStringSync(), isNot(contains('package:flutter')));
      }
    }
  });

  test('no arena can be cleared by one shot across the solver angle fan', () {
    const int angleSteps = 721;
    const double spreadDegrees = 85;

    for (final ArenaSpec arena in kArenas) {
      bool foundOneShotClear = false;
      for (int sample = 0; sample < angleSteps; sample++) {
        final double degrees =
            -spreadDegrees + 2 * spreadDegrees * sample / (angleSteps - 1);
        final double radians = degrees * math.pi / 180;
        final List<bool> alive = List<bool>.filled(arena.targets.length, true);
        final ShotRunner runner = ShotRunner(
          segments: buildSegments(arena),
          targets: arena.targets,
          alive: alive,
          origin: kShooterOrigin,
          direction: clampAim(V2(math.sin(radians), -math.cos(radians))),
          recordTrail: false,
        );
        while (runner.ball.alive) {
          runner.step(1 / 120);
          runner.pending.clear();
        }
        if (!alive.any((bool value) => value)) {
          foundOneShotClear = true;
          break;
        }
      }
      expect(foundOneShotClear, isFalse, reason: 'arena ${arena.id}');
    }
  });
}
