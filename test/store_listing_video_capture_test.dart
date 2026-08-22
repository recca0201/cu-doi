import 'dart:math' as math;

import 'package:ban_bua_tuong/sim/arena.dart';
import 'package:ban_bua_tuong/sim/geometry.dart';
import 'package:ban_bua_tuong/sim/shot_runner.dart';
import 'package:ban_bua_tuong/ui/fit.dart';
import 'package:ban_bua_tuong/ui/screens/game_screen.dart';
import 'package:ban_bua_tuong/data/settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/pump_app.dart';

Future<void> _loadMaterialIcons() async {
  await (FontLoader(
    'MaterialIcons',
  )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
}

Future<void> _capture(
  WidgetTester tester,
  Finder boundary,
  int frame,
) async {
  await expectLater(
    boundary,
    matchesGoldenFile(
      '../store_listing/video/frames/frame_${frame.toString().padLeft(4, '0')}.png',
    ),
  );
}

Future<void> _advanceSimulation(WidgetTester tester, int frames) async {
  for (int i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 83));
  }
}

Offset _aimPoint(Rect arenaRect, double degrees) {
  final ArenaFit fit = ArenaFit.of(arenaRect.size);
  final double radians = degrees * math.pi / 180;
  final V2 direction = clampAim(
    V2(math.sin(radians), -math.cos(radians)),
  );
  return arenaRect.topLeft +
      fit.toScreen(kShooterOrigin + direction * 44).translate(0, 0);
}

void main() {
  setUpAll(_loadMaterialIcons);

  testWidgets('capture a real two-shot level clear', (tester) async {
    const boundaryKey = Key('store-video');
    await pumpApp(
      tester,
      size: const Size(440, 956),
      locale: const Locale('vi'),
      settings: const AppSettings(soundOn: false, musicOn: false),
      home: const RepaintBoundary(
        key: boundaryKey,
        child: GameScreen(arenaId: 1),
      ),
    );
    for (int i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    final boundary = find.byKey(boundaryKey);
    final arena = find.byKey(const Key('game-arena-input'));
    int frame = 0;

    // Establishing hold with the real arena and targets.
    for (int i = 0; i < 10; i++) {
      await _capture(tester, boundary, frame++);
      await tester.pump(const Duration(milliseconds: 83));
    }

    // Solver solution for Arena 1, shot 1: clamped shallow-left bank.
    await tester.tapAt(_aimPoint(tester.getRect(arena), -85));
    for (int i = 0; i < 54; i++) {
      await tester.pump(const Duration(milliseconds: 83));
      await _capture(tester, boundary, frame++);
    }

    // Let the first shot fully end, then replay the solver's finishing angle.
    await _advanceSimulation(tester, 120);
    await tester.tapAt(_aimPoint(tester.getRect(arena), 7.75));
    for (int i = 0; i < 66; i++) {
      await tester.pump(const Duration(milliseconds: 83));
      await _capture(tester, boundary, frame++);
    }

    // Hold on the genuine win result.
    await _advanceSimulation(tester, 120);
    for (int i = 0; i < 22; i++) {
      await _capture(tester, boundary, frame++);
      await tester.pump(const Duration(milliseconds: 83));
    }
  });
}
