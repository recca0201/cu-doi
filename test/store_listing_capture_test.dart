import 'package:ban_bua_tuong/domain/player_progress.dart';
import 'package:ban_bua_tuong/ui/screens/arena_map_screen.dart';
import 'package:ban_bua_tuong/ui/screens/game_screen.dart';
import 'package:ban_bua_tuong/ui/screens/how_to_play_screen.dart';
import 'package:ban_bua_tuong/ui/screens/menu_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/pump_app.dart';

const _locales = <String, Locale>{
  'vi': Locale('vi'),
  'en': Locale('en'),
};

Future<void> _loadMaterialIcons() async {
  await (FontLoader(
    'MaterialIcons',
  )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
}

Future<void> _pumpStable(WidgetTester tester) async {
  for (int i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  setUpAll(_loadMaterialIcons);

  const captures = <String, Size>{
    'google_phone': Size(360, 640),
    'google_tablet_7': Size(540, 960),
    'google_tablet': Size(720, 1280),
    'iphone_69': Size(440, 956),
    'ipad_13': Size(1032, 1376),
  };

  const progress = PlayerProgress(
    results: <int, LevelResult>{
      1: LevelResult(stars: 3, highScore: 1300),
      2: LevelResult(stars: 2, highScore: 860),
      3: LevelResult(skipped: true),
    },
  );

  for (final entry in captures.entries) {
    final name = entry.key;
    final size = entry.value;
    for (final localeEntry in _locales.entries) {
      final localeName = localeEntry.key;
      final locale = localeEntry.value;

      testWidgets('store capture $name $localeName menu', (tester) async {
        const key = Key('store-menu');
        await pumpApp(
          tester,
          size: size,
          locale: locale,
          progress: progress,
          home: const RepaintBoundary(key: key, child: MenuScreen()),
        );
        await _pumpStable(tester);
        await expectLater(
          find.byKey(key),
          matchesGoldenFile(
            '../store_listing/captures/${name}_${localeName}_menu.png',
          ),
        );
      });

      testWidgets('store capture $name $localeName gameplay', (tester) async {
        const key = Key('store-gameplay');
        await pumpApp(
          tester,
          size: size,
          locale: locale,
          progress: progress,
          home: const RepaintBoundary(
            key: key,
            child: GameScreen(arenaId: 3),
          ),
        );
        await _pumpStable(tester);
        final gesture = await tester.startGesture(
          Offset(size.width * .48, size.height * .76),
        );
        await gesture.moveTo(Offset(size.width * .23, size.height * .27));
        await tester.pump(const Duration(milliseconds: 50));
        await expectLater(
          find.byKey(key),
          matchesGoldenFile(
            '../store_listing/captures/${name}_${localeName}_gameplay.png',
          ),
        );
        await gesture.cancel();
      });

      testWidgets('store capture $name $localeName map', (tester) async {
        const key = Key('store-map');
        await pumpApp(
          tester,
          size: size,
          locale: locale,
          progress: progress,
          home: const RepaintBoundary(key: key, child: ArenaMapScreen()),
        );
        await _pumpStable(tester);
        await expectLater(
          find.byKey(key),
          matchesGoldenFile(
            '../store_listing/captures/${name}_${localeName}_map.png',
          ),
        );
      });

      testWidgets('store capture $name $localeName rules', (tester) async {
        const key = Key('store-rules');
        await pumpApp(
          tester,
          size: size,
          locale: locale,
          progress: progress,
          home: const RepaintBoundary(key: key, child: HowToPlayScreen()),
        );
        await _pumpStable(tester);
        await expectLater(
          find.byKey(key),
          matchesGoldenFile(
            '../store_listing/captures/${name}_${localeName}_rules.png',
          ),
        );
      });
    }
  }
}
