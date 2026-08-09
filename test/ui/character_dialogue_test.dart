import 'package:ban_bua_tuong/domain/character.dart';
import 'package:ban_bua_tuong/ui/character_dialogue.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';

void main() {
  testWidgets(
    'modal dialogue is semantic, scroll-safe, and closes in one tap',
    (tester) async {
      var dismissed = false;
      await pumpApp(
        tester,
        textScaler: const TextScaler.linear(2),
        home: CharacterDialogue(
          id: DialogueId.intro,
          presentation: CharacterDialoguePresentation.modal,
          onDismiss: () => dismissed = true,
        ),
      );
      expect(find.text('Dội'), findsOneWidget);
      final Finder dismiss = find.byKey(const Key('dialogue-dismiss'));
      expect(tester.getSize(dismiss).height, greaterThanOrEqualTo(48));
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(dismiss);
      await tester.pump();
      await tester.tap(dismiss);
      await tester.pump();
      expect(dismissed, isTrue);
    },
  );

  testWidgets('embedded dialogue has no separate gold CTA', (tester) async {
    await pumpApp(
      tester,
      home: CharacterDialogue(id: DialogueId.levelWin, onDismiss: () {}),
    );
    expect(find.byKey(const Key('dialogue-dismiss')), findsNothing);
    expect(find.byKey(const Key('dialogue-close')), findsOneWidget);
  });
}
