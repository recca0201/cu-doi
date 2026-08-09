import 'dart:io';

import 'package:ban_bua_tuong/sim/geometry.dart';
import 'package:ban_bua_tuong/sim/shot_runner.dart';
import 'package:ban_bua_tuong/ui/comic_effect_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reduced motion blocks particles but leaves static state untouched', () {
    final ComicEffectController effects = ComicEffectController(
      reducedMotion: true,
    );
    effects.onEvent(
      ShotEvent(ShotEventKind.bank, const V2(2, 2)),
      banksAtEvent: 4,
    );
    effects.levelEnd(const V2(2, 2));
    expect(effects.elements, isEmpty);

    final String source = File(
      'lib/ui/screens/game_screen.dart',
    ).readAsStringSync();
    expect(source, contains('MediaQuery.disableAnimationsOf(context)'));
    expect(source, contains('shake: _reducedMotion ? 0 : _shake'));
    expect(source, contains('currentBanks: runner?.banks ?? 0'));
  });
}
