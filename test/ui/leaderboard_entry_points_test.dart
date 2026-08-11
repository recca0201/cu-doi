import 'package:ban_bua_tuong/domain/player_progress.dart';
import 'package:ban_bua_tuong/ui/screens/arena_map_screen.dart';
import 'package:ban_bua_tuong/ui/screens/leaderboard_screen.dart';
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
    'selected unlocked arena exposes a labelled leaderboard action only',
    (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await pumpApp(tester, home: const ArenaMapScreen());

      expect(find.bySemanticsLabel('Xem bảng xếp hạng Màn 1'), findsOneWidget);
      expect(
        find.byKey(const Key('selected-arena-leaderboard')),
        findsOneWidget,
      );

      final Finder lockedNode = find.descendant(
        of: find.byKey(const ValueKey<String>('arena-2')),
        matching: find.byType(InkWell),
      );
      tester.widget<InkWell>(lockedNode).onTap!();
      await tester.pump();

      expect(find.byIcon(Icons.lock_rounded), findsWidgets);
      expect(find.bySemanticsLabel('Xem bảng xếp hạng Màn 1'), findsOneWidget);
      expect(find.bySemanticsLabel('Xem bảng xếp hạng Màn 2'), findsNothing);
      semantics.dispose();
    },
  );

  testWidgets('push and pop preserve chapter selection and scroll owner', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpApp(
      tester,
      progress: _progressThrough(11),
      home: const ArenaMapScreen(targetArenaId: 12),
    );

    final State<StatefulWidget> mapStateBefore = tester.state(
      find.byType(ArenaMapScreen),
    );
    final CustomScrollView scrollBefore = tester.widget(
      find.byKey(const Key('arena-map-scroll')),
    );
    final double offsetBefore = scrollBefore.controller!.offset;
    expect(find.text('Chương 3 · Zig-zag'), findsOneWidget);
    expect(find.bySemanticsLabel('Xem bảng xếp hạng Màn 12'), findsOneWidget);

    await tester.tap(find.byKey(const Key('selected-arena-leaderboard')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));
    expect(find.byType(LeaderboardScreen), findsOneWidget);

    await tester.tap(find.byKey(const Key('leaderboard-back')));
    await tester.pumpAndSettle();

    expect(find.byType(ArenaMapScreen), findsOneWidget);
    expect(tester.state(find.byType(ArenaMapScreen)), same(mapStateBefore));
    expect(find.text('Chương 3 · Zig-zag'), findsOneWidget);
    expect(find.bySemanticsLabel('Xem bảng xếp hạng Màn 12'), findsOneWidget);
    final CustomScrollView scrollAfter = tester.widget(
      find.byKey(const Key('arena-map-scroll')),
    );
    expect(scrollAfter.controller!.offset, offsetBefore);
    semantics.dispose();
  });
}
