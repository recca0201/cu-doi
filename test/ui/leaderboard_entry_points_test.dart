import 'package:ban_bua_tuong/domain/player_progress.dart';
import 'package:ban_bua_tuong/ui/screens/leaderboard_screen.dart';
import 'package:ban_bua_tuong/ui/screens/menu_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';

PlayerProgress _progressThrough(int arenaId) => PlayerProgress(
  results: <int, LevelResult>{
    for (int id = 1; id <= arenaId; id++)
      id: LevelResult(stars: 3, highScore: 1000 + id),
  },
);

void main() {
  testWidgets(
    'main menu exposes a labelled leaderboard action for the current arena',
    (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await pumpApp(tester, home: const MenuScreen());

      expect(find.bySemanticsLabel('Xem bảng xếp hạng Màn 1'), findsOneWidget);
      expect(find.byKey(const Key('menu-leaderboard')), findsOneWidget);

      await tester.tap(find.byKey(const Key('menu-leaderboard')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 30));
      expect(find.byType(LeaderboardScreen), findsOneWidget);
      expect(find.textContaining('Màn 1'), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets(
    'push and pop preserve the menu and target the first unfinished arena',
    (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await pumpApp(
        tester,
        progress: _progressThrough(11),
        home: const MenuScreen(),
      );

      expect(find.bySemanticsLabel('Xem bảng xếp hạng Màn 12'), findsOneWidget);

      await tester.tap(find.byKey(const Key('menu-leaderboard')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 30));
      expect(find.byType(LeaderboardScreen), findsOneWidget);
      expect(find.textContaining('Màn 12'), findsOneWidget);

      await tester.tap(find.byKey(const Key('leaderboard-back')));
      await tester.pumpAndSettle();

      expect(find.byType(MenuScreen), findsOneWidget);
      expect(find.byKey(const Key('menu-play')), findsOneWidget);
      expect(find.bySemanticsLabel('Xem bảng xếp hạng Màn 12'), findsOneWidget);
      semantics.dispose();
    },
  );
}
