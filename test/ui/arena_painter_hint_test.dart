import 'package:ban_bua_tuong/sim/arena.dart';
import 'package:ban_bua_tuong/sim/arenas.dart';
import 'package:ban_bua_tuong/sim/geometry.dart';
import 'package:ban_bua_tuong/ui/arena_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('hint is visually distinct among ghost and armed targets', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final ArenaSpec arena = kArenas.first;
    await tester.pumpWidget(
      RepaintBoundary(
        key: const Key('hint-golden'),
        child: SizedBox.expand(
          child: CustomPaint(
            painter: ArenaPainter(
              arena: arena,
              alive: List<bool>.filled(arena.targets.length, true),
              aimDirection: const V2(0, -1),
              previewPoints: const <V2>[],
              showPreview: false,
              trail: const <V2>[],
              ghostTrail: const <V2>[V2(50, 150), V2(85, 70), V2(20, 15)],
              hintPath: const <V2>[
                V2(50, 150),
                V2(4, 82),
                V2(70, 4),
                V2(50, 54),
              ],
              ballPos: null,
              currentBanks: 4,
              shotInFlight: false,
              stamps: const <Stamp>[],
              shake: 0,
            ),
          ),
        ),
      ),
    );
    await expectLater(
      find.byKey(const Key('hint-golden')),
      matchesGoldenFile('goldens/arena_painter_hint.png'),
    );
  });
}
