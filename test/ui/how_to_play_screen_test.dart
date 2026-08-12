import 'package:ban_bua_tuong/ui/screens/how_to_play_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';

void main() {
  testWidgets('how-to-play rules match the gameplay visual language', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpApp(
      tester,
      size: const Size(390, 1600),
      home: RepaintBoundary(
        key: const Key('how-to-play-golden'),
        child: HowToPlayPanel(onDismiss: () {}, onDontShowAgain: () {}),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(const Key('how-to-play-golden')),
      matchesGoldenFile('goldens/how_to_play_390x1600.png'),
    );
  });

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

  for (final ({Size size, double scale}) scenario
      in <({Size size, double scale})>[
        (size: const Size(320, 568), scale: 1),
        (size: const Size(390, 844), scale: 2),
      ]) {
    testWidgets(
      'rule art and copy stay inside every card at ${scenario.size} ${scenario.scale}x',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(scenario.size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await pumpApp(
          tester,
          textScaler: TextScaler.linear(scenario.scale),
          home: HowToPlayPanel(onDismiss: () {}, onDontShowAgain: () {}),
        );

        for (int number = 1; number <= 5; number++) {
          final Finder card = find.byKey(Key('how-to-rule-$number'));
          await tester.ensureVisible(card);
          await tester.pump();
          final Rect cardRect = tester.getRect(card);
          for (final String part in <String>['art', 'title', 'body']) {
            final Rect partRect = tester.getRect(
              find.byKey(Key('how-to-$part-$number')),
            );
            expect(
              cardRect.inflate(.1).contains(partRect.topLeft) &&
                  cardRect.inflate(.1).contains(partRect.bottomRight),
              isTrue,
              reason: 'Rule $number $part must remain inside its card',
            );
          }
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
