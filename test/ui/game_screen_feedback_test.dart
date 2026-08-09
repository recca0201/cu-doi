import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'game screen fans out simulation events without a second input layer',
    () {
      final String source = File(
        'lib/ui/screens/game_screen.dart',
      ).readAsStringSync();
      expect(source, contains('_effects.onEvent('));
      expect(source, contains('_haptics.fire(HapticEvent.bank)'));
      expect(source, contains('_haptics.fire(HapticEvent.blockedShot)'));
      expect(source, contains('_haptics.fire(HapticEvent.targetBroken)'));
      expect(source, contains('_haptics.fire(HapticEvent.levelEnd)'));
      expect(source, contains('_effects.tick(dt)'));
      expect(source, contains('if (_effects.isNotEmpty) dirty = true'));
      expect(source, contains('_effects.clear();'));
      expect(source, contains('audio.play(GameSound.wallImpact)'));
      expect(source, contains('audio.play(GameSound.comicImpact)'));
      expect(source, isNot(contains('GameSound.values.add')));
    },
  );

  test('endShot is the first statement of finishShot', () {
    final String source = File(
      'lib/ui/screens/game_screen.dart',
    ).readAsStringSync();
    final RegExpMatch match = RegExp(
      r'void _finishShot\(ShotRunner runner\) \{\s*([^\n]+)',
    ).firstMatch(source)!;
    expect(match.group(1), contains('_effects.endShot(runner.endReason)'));
  });
}
