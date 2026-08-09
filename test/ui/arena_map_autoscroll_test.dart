import 'package:ban_bua_tuong/domain/player_progress.dart';
import 'package:ban_bua_tuong/ui/screens/arena_map_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';

void main() {
  testWidgets('inferred next arena starts in view without animation', (
    tester,
  ) async {
    await pumpApp(
      tester,
      home: const ArenaMapScreen(),
      progress: const PlayerProgress(
        results: <int, LevelResult>{7: LevelResult(stars: 1)},
      ),
    );
    final CustomScrollView scroll = tester.widget(
      find.byKey(const Key('arena-map-scroll')),
    );
    expect(scroll.controller!.offset, greaterThan(0));
  });

  testWidgets('explicit valid target is applied before the first frame', (
    tester,
  ) async {
    await pumpApp(
      tester,
      home: const ArenaMapScreen(targetArenaId: 20),
      progress: const PlayerProgress(
        results: <int, LevelResult>{7: LevelResult(stars: 1)},
      ),
    );
    final CustomScrollView scroll = tester.widget(
      find.byKey(const Key('arena-map-scroll')),
    );
    expect(scroll.controller!.offset, greaterThan(0));
  });

  testWidgets('invalid explicit target falls back without throwing', (
    tester,
  ) async {
    await pumpApp(
      tester,
      home: const ArenaMapScreen(targetArenaId: 99),
      progress: const PlayerProgress(
        results: <int, LevelResult>{7: LevelResult(stars: 1)},
      ),
    );
    final CustomScrollView scroll = tester.widget(
      find.byKey(const Key('arena-map-scroll')),
    );
    expect(scroll.controller!.offset, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('dependency changes do not recreate the scroll controller', (
    tester,
  ) async {
    await pumpApp(tester, home: const ArenaMapScreen());
    final Finder scrollFinder = find.byKey(const Key('arena-map-scroll'));
    final ScrollController before = tester
        .widget<CustomScrollView>(scrollFinder)
        .controller!;
    await tester.drag(scrollFinder, const Offset(0, -300));
    await tester.pump();
    final double offset = before.offset;
    await tester.binding.setSurfaceSize(const Size(430, 900));
    await tester.pump();
    final ScrollController after = tester
        .widget<CustomScrollView>(scrollFinder)
        .controller!;
    expect(identical(before, after), isTrue);
    expect(after.offset, offset);
  });
}
