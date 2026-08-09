import 'package:ban_bua_tuong/domain/player_progress.dart';
import 'package:ban_bua_tuong/ui/screens/game_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';

Future<void> _finishStraightShot(WidgetTester tester) async {
  await tester.tapAt(const Offset(195, 430));
  for (var i = 0; i < 180; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

void main() {
  testWidgets(
    'intro voice lives in the existing guide and does not auto-close',
    (tester) async {
      await pumpApp(
        tester,
        home: const GameScreen(arenaId: 1, showGuide: true),
      );
      expect(find.byKey(const Key('character-dialogue-intro')), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      expect(find.byKey(const Key('character-dialogue-intro')), findsOneWidget);
      final Finder cta = find.text('Hiểu rồi, bắn thôi!').last;
      await tester.ensureVisible(cta);
      await tester.pump();
      await tester.tap(cta);
      await tester.pump();
      expect(find.byKey(const Key('character-dialogue-intro')), findsNothing);
    },
  );

  testWidgets(
    'crowded loss uses short dialogue and remains scroll-safe at 2x',
    (tester) async {
      await pumpApp(
        tester,
        textScaler: const TextScaler.linear(2),
        progress: const PlayerProgress(
          coins: 500,
          results: <int, LevelResult>{1: LevelResult(losses: 2)},
        ),
        home: const GameScreen(arenaId: 1),
      );
      for (var shot = 0; shot < 3; shot++) {
        await _finishStraightShot(tester);
      }
      expect(find.text('Lệch một góc thôi — thử lại nhé!'), findsOneWidget);
      expect(find.textContaining('50 xu'), findsWidgets);
      expect(find.byKey(const Key('skip-arena-button')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
