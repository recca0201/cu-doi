import 'package:ban_bua_tuong/domain/player_progress.dart';
import 'package:ban_bua_tuong/ui/screens/profile_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import '../support/pump_app.dart';

void main() {
  testWidgets('overview restores guest metrics without zero error state', (
    tester,
  ) async {
    await pumpApp(
      tester,
      home: const ProfileScreen(),
      progress: const PlayerProgress(
        coins: 9,
        results: {
          1: LevelResult(stars: 2, highScore: 700),
          2: LevelResult(skipped: true),
        },
      ),
    );
    await tester.pump();
    expect(find.text('2/60'), findsOneWidget);
    expect(find.text('1/20'), findsOneWidget);
    expect(find.text('700'), findsOneWidget);
    expect(find.text('Đang chơi với tư cách khách'), findsOneWidget);
  });
  testWidgets(
    'progress details expose four chapters, records and eight badges',
    (tester) async {
      await pumpApp(tester, home: const ProfileScreen());
      await tester.pump();
      expect(find.textContaining('Chương 1'), findsOneWidget);
      expect(find.textContaining('Chương 4'), findsOneWidget);
      expect(find.text('Huy hiệu'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsNWidgets(8));
    },
  );
  testWidgets('account actions stay visible and accessible', (tester) async {
    await pumpApp(tester, home: const ProfileScreen());
    await tester.pump();
    await tester.ensureVisible(find.text('Tiếp tục với Google'));
    expect(find.text('Tiếp tục với Google'), findsOneWidget);
    expect(find.text('Tiếp tục với Apple'), findsOneWidget);
  });
}
