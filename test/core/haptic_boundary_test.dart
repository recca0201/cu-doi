import 'dart:io';

import 'package:ban_bua_tuong/core/haptic_service.dart';
import 'package:ban_bua_tuong/sim/shot_runner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('haptics reuse shot events and stay outside pure simulation', () {
    expect(HapticEvent.values.length, ShotEventKind.values.length + 1);
    for (final FileSystemEntity entity in Directory('lib/sim').listSync()) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      expect(entity.readAsStringSync(), isNot(contains('package:flutter')));
    }
    expect(
      File('lib/sim/shot_runner.dart').readAsStringSync(),
      isNot(contains('haptic_service.dart')),
    );
    final String pubspec = File('pubspec.yaml').readAsStringSync();
    expect(
      pubspec,
      isNot(
        matches(RegExp(r'^\s*(haptic_feedback|vibration):', multiLine: true)),
      ),
    );
  });
}
