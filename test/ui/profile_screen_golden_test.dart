import 'package:ban_bua_tuong/ui/screens/profile_screen.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import '../support/pump_app.dart';

Future<void> _loadMaterialIcons() async {
  await (FontLoader(
    'MaterialIcons',
  )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
}

void main() {
  setUpAll(_loadMaterialIcons);

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(800, 1100),
  ]) {
    testWidgets('profile reflows and scrolls at $size', (tester) async {
      await pumpApp(
        tester,
        home: const ProfileScreen(),
        size: size,
        textScaler: size.width == 320
            ? const TextScaler.linear(2)
            : TextScaler.noScaling,
      );
      await tester.pump();
      expect(find.byType(Scrollable), findsWidgets);
      expect(tester.takeException(), isNull);
      if (size == const Size(390, 844)) {
        await expectLater(
          find.byType(ProfileScreen),
          matchesGoldenFile('goldens/profile_screen_390x844.png'),
        );
      }
    });
  }
}
