import 'package:ban_bua_tuong/ui/screens/menu_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';

void main() {
  testWidgets('first release exposes no leaderboard entry point', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, home: const MenuScreen());

    expect(find.byKey(const Key('menu-leaderboard')), findsNothing);
    expect(find.byKey(const Key('menu-how-to-play')), findsOneWidget);
    expect(find.byKey(const Key('menu-arena-select')), findsOneWidget);
  });
}
