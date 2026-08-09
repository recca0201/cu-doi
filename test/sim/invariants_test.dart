import 'dart:io';

import 'package:ban_bua_tuong/sim/arena.dart';
import 'package:ban_bua_tuong/sim/arenas.dart';
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
      <int>[550, 800, 1000],
      <int>[850, 1200, 1550],
      <int>[650, 950, 1150],
      <int>[950, 1350, 1700],
      <int>[700, 1000, 1250],
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
      <int>[950, 1350, 1700],
      <int>[800, 1150, 1450],
      <int>[1300, 1850, 2350],
    ]);
    for (final FileSystemEntity entity in Directory('lib/sim').listSync()) {
      if (entity is File && entity.path.endsWith('.dart')) {
        expect(entity.readAsStringSync(), isNot(contains('package:flutter')));
      }
    }
  });
}
