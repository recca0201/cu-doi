import 'package:ban_bua_tuong/domain/player_progress.dart';
import 'package:ban_bua_tuong/ui/screens/arena_map_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';

void main() {
  testWidgets('arena map 390x844 arcade-night hierarchy', (tester) async {
    await pumpApp(
      tester,
      progress: const PlayerProgress(
        results: <int, LevelResult>{
          1: LevelResult(stars: 3),
          2: LevelResult(skipped: true),
        },
      ),
      home: const RepaintBoundary(
        key: Key('arena-map-golden'),
        child: ArenaMapScreen(),
      ),
    );
    await expectLater(
      find.byKey(const Key('arena-map-golden')),
      matchesGoldenFile('goldens/arena_map_390x844.png'),
    );
  });
}
