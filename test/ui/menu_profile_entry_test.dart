import 'package:ban_bua_tuong/ui/screens/menu_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import '../support/pump_app.dart';

void main() {
  testWidgets('identity card opens profile and back preserves menu', (
    tester,
  ) async {
    await pumpApp(tester, home: const MenuScreen());
    await tester.pump();
    final entry = find.byKey(const Key('menu-profile-entry'));
    expect(tester.getSize(entry).height, greaterThanOrEqualTo(48));
    await tester.tap(entry);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('profile-back')), findsOneWidget);
    await tester.tap(find.byKey(const Key('profile-back')));
    await tester.pumpAndSettle();
    expect(entry, findsOneWidget);
    expect(find.byKey(const Key('menu-play')), findsOneWidget);
  });
}
