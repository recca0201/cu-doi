import 'package:ban_bua_tuong/main.dart';
import 'package:ban_bua_tuong/state/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Smoke test, not a behaviour test. It catches the class of mistake that is
/// invisible without a toolchain: a layout that throws, a painter that blows up,
/// a gesture never wired to the launcher, a missing l10n key.
///
/// Two deliberate choices:
///  * Sound and music start OFF. `GameAudioService` short-circuits `play()` when
///    disabled, which keeps flame_audio (and its missing platform plugin) out of
///    the test entirely.
///  * No `pumpAndSettle` anywhere. The game screen runs a permanently active
///    Ticker, so settling would never complete.
Future<void> _pumpFrames(WidgetTester tester, {int frames = 12}) async {
  for (int i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _boot(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    'soundOn': false,
    'musicOn': false,
    'localeCode': 'vi',
  });
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const BanBuaTuongApp(),
    ),
  );
  await _pumpFrames(tester, frames: 4);
}

void main() {
  testWidgets('the menu builds in Vietnamese', (WidgetTester tester) async {
    await _boot(tester);

    expect(find.text('Bắn Bừa'), findsOneWidget);
    expect(find.text('Chơi ngay'), findsOneWidget);
    expect(find.text('Chọn màn'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a fresh player is shown the rules, then can take a shot',
      (WidgetTester tester) async {
    await _boot(tester);

    await tester.tap(find.text('Chơi ngay'));
    await _pumpFrames(tester);

    // Fresh progress means the inversion gets explained before the first shot.
    expect(find.text('Luật chơi'), findsOneWidget);
    await tester.tap(find.text('Hiểu rồi, bắn thôi!'));
    await _pumpFrames(tester, frames: 4);

    expect(find.textContaining('Bắn thẳng không tính'), findsWidgets);
    expect(find.textContaining('Còn 3 cú bắn'), findsOneWidget);

    // Tap the upper arena to aim and fire.
    await tester.tapAt(const Offset(195, 380));
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.textContaining('Còn 2 cú bắn'), findsOneWidget);

    // Let the shot fly, bank and die without taking the frame down.
    await _pumpFrames(tester, frames: 40);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the stage list is reachable and locks later stages',
      (WidgetTester tester) async {
    await _boot(tester);

    await tester.tap(find.text('Chọn màn'));
    await _pumpFrames(tester);

    expect(find.textContaining('Bắn thẳng không tính'), findsOneWidget);
    // Stage 1 is unlocked on a fresh install; everything after it is not. The
    // list is lazy, so assert presence rather than an exact count.
    expect(find.text('Chưa mở'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
