import 'dart:io';

import 'package:ban_bua_tuong/sim/arena.dart';
import 'package:ban_bua_tuong/sim/arenas.dart';
import 'package:ban_bua_tuong/sim/geometry.dart';
import 'package:ban_bua_tuong/ui/arena_painter.dart';
import 'package:ban_bua_tuong/ui/comic_effect_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:ui' as ui;

ArenaPainter painter({
  List<EffectElement>? effects,
  bool reducedMotion = false,
  double shake = 0,
}) {
  final ArenaSpec arena = kArenas.first;
  return ArenaPainter(
    arena: arena,
    alive: List<bool>.filled(arena.targets.length, true),
    aimDirection: const V2(0, -1),
    previewPoints: const <V2>[],
    showPreview: false,
    trail: const <V2>[],
    ghostTrail: const <V2>[V2(50, 150), V2(50, 100)],
    ballPos: const V2(50, 80),
    currentBanks: 4,
    shotInFlight: true,
    stamps: const <Stamp>[],
    shake: shake,
    effects: effects ?? const <EffectElement>[],
    reducedMotion: reducedMotion,
  );
}

Future<List<int>> render(ArenaPainter arenaPainter) async {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(recorder);
  arenaPainter.paint(canvas, const Size(390, 700));
  final ui.Image image = await recorder.endRecording().toImage(390, 700);
  final data = await image.toByteData();
  image.dispose();
  return data!.buffer.asUint8List();
}

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Baloo2',
    )..addFont(rootBundle.load('assets/fonts/Baloo2-Variable.ttf'))).load();
  });

  test('empty effects preserve output and non-empty effects render', () async {
    final List<int> omitted = await render(painter());
    final List<int> explicit = await render(
      painter(effects: const <EffectElement>[]),
    );
    expect(explicit, omitted);
    final EffectElement element = EffectElement(
      kind: EffectKind.bank,
      pos: const V2(25, 70),
      tier: EffectTier.forLevel(4)!,
    );
    expect(
      await render(painter(effects: <EffectElement>[element])),
      isNot(omitted),
    );
  });

  test('effect draw call remains below trail, targets, and ball', () {
    final String source = File('lib/ui/arena_painter.dart').readAsStringSync();
    expect(
      source.indexOf('_paintEffects(canvas, fit)'),
      lessThan(source.indexOf('_paintTrail(canvas, fit)')),
    );
    expect(
      source.indexOf('_paintEffects(canvas, fit)'),
      lessThan(source.indexOf('_paintTargets(canvas, fit)')),
    );
    expect(
      source.indexOf('_paintEffects(canvas, fit)'),
      lessThan(source.indexOf('_paintBall(canvas, fit, ball)')),
    );
    expect(source, contains('math.min(segmentAlpha, 0x20)'));
  });

  testWidgets('armed target remains readable over an overlapping effect', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final EffectElement overlap = EffectElement(
      kind: EffectKind.broke,
      pos: kArenas.first.targets.first.pos,
      tier: EffectTier.forLevel(4)!,
    );
    await tester.pumpWidget(
      RepaintBoundary(
        key: const Key('armed-effect-golden'),
        child: SizedBox.expand(
          child: CustomPaint(
            painter: painter(effects: <EffectElement>[overlap]),
          ),
        ),
      ),
    );
    await expectLater(
      find.byKey(const Key('armed-effect-golden')),
      matchesGoldenFile('goldens/arena_painter_effects.png'),
    );
  });
}
