import 'package:ban_bua_tuong/ui/screens/avatar_editor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/pump_app.dart';

void main() {
  testWidgets(
    'shows four mascot moods, shared header, preview and privacy copy',
    (tester) async {
      await pumpApp(tester, home: const AvatarEditorScreen());
      await tester.pump();
      expect(find.byKey(const Key('avatar-title')), findsOneWidget);
      expect(find.byKey(const Key('avatar-back')), findsOneWidget);
      expect(find.byKey(const Key('avatar-square-preview')), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(
        find.text('Bộ chọn hệ thống chỉ mở khi bạn chọn và đồng bộ avatar.'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('pangolin-gold'), findsOneWidget);
      expect(find.bySemanticsLabel('pangolin-victory'), findsOneWidget);
      expect(find.bySemanticsLabel('pangolin-surprised'), findsOneWidget);
      expect(find.bySemanticsLabel('pangolin-gentle-sad'), findsOneWidget);
    },
  );
  testWidgets('system picker cancel is a no-op', (tester) async {
    await pumpApp(
      tester,
      home: AvatarEditorScreen(pickImagePath: () async => null),
    );
    await tester.tap(find.text('Ảnh từ thiết bị'));
    await tester.pump();
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
