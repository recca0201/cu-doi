import 'package:ban_bua_tuong/ui/screens/how_to_play_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';

void main() {
  testWidgets('five illustrated rules are scroll-safe at 2x text', (
    WidgetTester tester,
  ) async {
    var dismissed = false;
    var hidden = false;
    await pumpApp(
      tester,
      textScaler: const TextScaler.linear(2),
      home: HowToPlayPanel(
        onDismiss: () => dismissed = true,
        onDontShowAgain: () => hidden = true,
      ),
    );

    expect(find.text('Luật chơi'), findsOneWidget);
    expect(find.text('Ngắm và bắn'), findsOneWidget);
    expect(find.text('Đáy sân mở'), findsOneWidget);

    final Finder hideButton = find.text('Không hiện lại');
    await tester.ensureVisible(hideButton);
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.tap(hideButton);
    await tester.pump();

    expect(hidden, isTrue);
    expect(dismissed, isFalse);
  });
}
