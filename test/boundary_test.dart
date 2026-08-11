import 'dart:io';

import 'package:ban_bua_tuong/domain/player_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('simulation and domain dependency boundaries remain intact', () {
    for (final file in Directory('lib/sim').listSync().whereType<File>()) {
      expect(file.readAsStringSync(), isNot(contains('package:flutter')));
      expect(file.readAsStringSync(), isNot(contains('firebase')));
    }
    for (final file in Directory('lib/domain').listSync().whereType<File>()) {
      expect(file.readAsStringSync(), isNot(contains('/l10n/')));
    }
    final arena = File('lib/sim/arena.dart').readAsStringSync();
    expect(arena, isNot(contains('final Chapter')));
    final chapters = File('lib/domain/chapters.dart').readAsStringSync();
    expect(chapters, isNot(contains('withResult(')));
    expect(chapters, isNot(contains('withSkipped(')));
  });

  test('profile feature introduces no analytics or gameplay event log', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, isNot(contains('firebase_analytics')));
    for (final directory in <String>['lib/domain', 'lib/data', 'lib/state']) {
      for (final file in Directory(directory).listSync().whereType<File>()) {
        expect(file.readAsStringSync(), isNot(contains('eventLog')));
        expect(file.readAsStringSync(), isNot(contains('logShot')));
      }
    }
  });

  test('linear unlock rule is unchanged', () {
    const progress = PlayerProgress(
      results: <int, LevelResult>{3: LevelResult(stars: 1)},
    );
    expect(progress.isUnlocked(4), isTrue);
    expect(progress.isUnlocked(5), isFalse);
  });
}
