import 'package:ban_bua_tuong/domain/player_progress.dart';
import 'package:ban_bua_tuong/core/bb_tokens.dart';
import 'package:ban_bua_tuong/ui/screens/arena_map_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';

void main() {
  testWidgets('karst shell shows chapter progress and three-column cards', (
    tester,
  ) async {
    await pumpApp(tester, home: const ArenaMapScreen());
    expect(
      (tester.widget<Scaffold>(find.byType(Scaffold))).backgroundColor,
      BbTokens.karstDeep,
    );
    expect(find.byKey(const Key('arena-map-title')), findsOneWidget);
    expect(find.text('Chương 1 · Học luật dội'), findsOneWidget);
    expect(find.text('0/15 sao'), findsWidgets);
    expect(find.byKey(const ValueKey<String>('arena-1')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('arena-5')), findsOneWidget);
    final Offset one = tester.getTopLeft(
      find.byKey(const ValueKey<String>('arena-1')),
    );
    final Offset five = tester.getTopLeft(
      find.byKey(const ValueKey<String>('arena-5')),
    );
    expect(five.dy, greaterThan(one.dy));
  });

  testWidgets('open card enables play while a locked card explains', (
    tester,
  ) async {
    await pumpApp(tester, home: const ArenaMapScreen());
    final Finder openNode = find.descendant(
      of: find.byKey(const ValueKey<String>('arena-1')),
      matching: find.byType(InkWell),
    );
    tester.widget<InkWell>(openNode).onTap!();
    await tester.pump();
    expect(find.byType(SnackBar), findsNothing);
    final Finder playButton = find.byKey(const Key('selected-arena-play'));
    expect(playButton, findsOneWidget);
    final Finder playInk = find.descendant(
      of: playButton,
      matching: find.byType(InkWell),
    );
    expect(tester.widget<InkWell>(playInk).onTap, isNotNull);
    final Finder lockedNode = find.descendant(
      of: find.byKey(const ValueKey<String>('arena-2')),
      matching: find.byType(InkWell),
    );
    tester.widget<InkWell>(lockedNode).onTap!();
    await tester.pump();
    expect(
      find.text('Xong màn trước đã rồi mới tới màn này nha!'),
      findsWidgets,
    );
  });

  testWidgets('text scale 2 does not overflow map shell', (tester) async {
    await pumpApp(
      tester,
      home: const ArenaMapScreen(),
      textScaler: const TextScaler.linear(2),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'nodes expose unlocked, current, completed, skipped and locked states',
    (tester) async {
      await pumpApp(
        tester,
        progress: const PlayerProgress(
          results: <int, LevelResult>{
            2: LevelResult(skipped: true),
            3: LevelResult(stars: 2),
          },
        ),
        home: const ArenaMapScreen(),
      );
      expect(find.text('ĐÃ BỎ QUA'), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsWidgets);
      expect(find.byIcon(Icons.star_outline_rounded), findsWidgets);
      expect(find.text('4'), findsWidgets);
      expect(find.byIcon(Icons.lock_rounded), findsWidgets);
      for (var id = 1; id <= 5; id++) {
        expect(
          tester.getSize(find.byKey(ValueKey<String>('arena-$id'))).height,
          176,
        );
      }
    },
  );
}
