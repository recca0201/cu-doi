import 'dart:ui' as ui;

import 'package:ban_bua_tuong/data/settings_repository.dart';
import 'package:ban_bua_tuong/ui/screens/settings_screen.dart';
import 'package:ban_bua_tuong/ui/widgets/bb_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';

void main() {
  testWidgets('haptics toggle is ordered, semantic, immediate, and tappable', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpApp(tester, home: const SettingsScreen());

    final Finder toggles = find.byType(BbToggle);
    expect(toggles, findsNWidgets(3));
    final Finder haptic = toggles.at(2);
    expect(tester.getSize(haptic).height, greaterThanOrEqualTo(48));
    expect(
      tester.getSemantics(haptic).flagsCollection.isToggled,
      ui.Tristate.isTrue,
    );
    expect(
      tester.getTopLeft(toggles.at(1)).dy,
      lessThan(tester.getTopLeft(haptic).dy),
    );
    expect(
      tester.getTopLeft(haptic).dy,
      lessThan(tester.getTopLeft(find.text('VI')).dy),
    );

    await tester.tap(haptic);
    await tester.pumpAndSettle();
    expect(tester.widget<BbToggle>(toggles.at(2)).value, isFalse);
    expect(
      tester.getSemantics(toggles.at(2)).flagsCollection.isToggled,
      ui.Tristate.isFalse,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await pumpApp(
      tester,
      home: const SettingsScreen(),
      settings: const AppSettings(hapticsOn: false),
    );
    expect(tester.widget<BbToggle>(find.byType(BbToggle).at(2)).value, isFalse);
    semantics.dispose();
  });
}
