import 'package:ban_bua_tuong/data/settings_repository.dart';
import 'package:ban_bua_tuong/ui/screens/arena_map_screen.dart';
import 'package:ban_bua_tuong/ui/screens/how_to_play_screen.dart';
import 'package:ban_bua_tuong/ui/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';

String assetName(WidgetTester tester, Finder finder) =>
    (tester.widget<Image>(finder).image as AssetImage).assetName;

void main() {
  testWidgets('English shell screens use English title banner assets', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      locale: const Locale('en'),
      home: const ArenaMapScreen(),
    );
    expect(
      assetName(
        tester,
        find.descendant(
          of: find.byKey(const Key('arena-map-title')),
          matching: find.byType(Image),
        ),
      ),
      'assets/images/ui/karst/stage_title_banner_en_v1.png',
    );

    await pumpApp(
      tester,
      locale: const Locale('en'),
      home: HowToPlayPanel(onDismiss: () {}, onDontShowAgain: () {}),
    );
    expect(
      assetName(
        tester,
        find.descendant(
          of: find.byKey(const Key('how-to-title')),
          matching: find.byType(Image),
        ),
      ),
      'assets/images/ui/karst/rules_title_banner_en_v1.png',
    );

    await pumpApp(
      tester,
      locale: const Locale('en'),
      settings: const AppSettings(localeCode: 'en'),
      home: const SettingsScreen(),
    );
    expect(
      assetName(tester, find.byKey(const Key('settings-title'))),
      'assets/images/ui/karst/settings_title_banner_en_v1.png',
    );
  });
}
