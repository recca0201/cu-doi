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

Future<void> _boot(
  WidgetTester tester, {
  Size size = const Size(390, 844),
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    'soundOn': false,
    'musicOn': false,
    'localeCode': 'vi',
  });
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const BanBuaTuongApp(),
    ),
  );
  await _pumpFrames(tester, frames: 4);
}

void main() {
  for (final Size size in <Size>[
    const Size(320, 568),
    const Size(390, 844),
    const Size(600, 960),
    const Size(1024, 1366),
  ]) {
    testWidgets('menu stays usable at ${size.width}x${size.height}', (
      WidgetTester tester,
    ) async {
      await _boot(tester, size: size);

      final Finder logo = find.byKey(const Key('main-logo'));
      final Finder play = find.byKey(const Key('menu-play'));
      final Finder arenaSelect = find.byKey(const Key('menu-arena-select'));
      final Finder leaderboard = find.byKey(const Key('menu-leaderboard'));
      final Finder howToPlay = find.byKey(const Key('menu-how-to-play'));
      final Finder tagline = find.byKey(const Key('menu-tagline'));
      final Finder playerAvatar = find.byKey(const Key('menu-player-avatar'));
      final Finder playerCopy = find.byKey(const Key('menu-player-copy'));
      expect(logo, findsOneWidget);
      expect(play, findsOneWidget);
      expect(arenaSelect, findsOneWidget);
      expect(leaderboard, findsOneWidget);
      expect(howToPlay, findsOneWidget);
      expect(tagline, findsOneWidget);
      expect(playerAvatar, findsOneWidget);
      expect(playerCopy, findsOneWidget);
      expect(tester.getRect(logo).left, greaterThanOrEqualTo(0));
      expect(tester.getRect(logo).right, lessThanOrEqualTo(size.width));
      expect(tester.getRect(play).left, greaterThanOrEqualTo(0));
      expect(tester.getRect(play).right, lessThanOrEqualTo(size.width));
      expect(
        tester.getRect(arenaSelect).bottom,
        lessThanOrEqualTo(size.height),
      );
      expect(
        tester.getRect(leaderboard).bottom,
        lessThanOrEqualTo(size.height),
      );
      expect(tester.getRect(howToPlay).bottom, lessThanOrEqualTo(size.height));
      expect(tester.getRect(tagline).bottom, lessThanOrEqualTo(size.height));
      expect(
        tester.getRect(arenaSelect).width,
        greaterThan(tester.getRect(leaderboard).width),
      );
      expect(
        tester.getRect(leaderboard).top,
        closeTo(tester.getRect(howToPlay).top, 0.5),
      );
      expect(
        tester.getRect(arenaSelect).bottom,
        lessThan(tester.getRect(leaderboard).top),
      );
      expect(
        tester.getRect(playerAvatar).right,
        lessThanOrEqualTo(tester.getRect(playerCopy).left),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('the menu builds in Vietnamese', (WidgetTester tester) async {
    await _boot(tester);

    expect(find.text('game bắn dội tường'), findsOneWidget);
    expect(find.byKey(const Key('menu-play')), findsOneWidget);
    expect(find.byKey(const Key('menu-arena-select')), findsOneWidget);
    expect(find.byKey(const Key('menu-leaderboard')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a fresh player is shown the rules, then can take a shot', (
    WidgetTester tester,
  ) async {
    await _boot(tester);

    await tester.tap(find.byKey(const Key('menu-play')));
    await _pumpFrames(tester);

    // Fresh progress means the inversion gets explained before the first shot.
    expect(find.text('Luật chơi'), findsOneWidget);
    final Finder gotIt = find.text('Hiểu rồi, bắn thôi!');
    await tester.ensureVisible(gotIt);
    await tester.pump();
    await tester.tap(gotIt);
    await _pumpFrames(tester, frames: 4);

    expect(find.textContaining('Còn 3 cú bắn'), findsOneWidget);

    // Tap the upper arena to aim and fire.
    await tester.tapAt(const Offset(195, 380));
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.textContaining('Còn 2 cú bắn'), findsOneWidget);

    // Let the shot fly, bank and die without taking the frame down.
    await _pumpFrames(tester, frames: 40);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the stage list is reachable and locks later stages', (
    WidgetTester tester,
  ) async {
    await _boot(tester);

    await tester.tap(find.byKey(const Key('menu-arena-select')));
    await _pumpFrames(tester);

    expect(find.text('Chương 1 · Học luật dội'), findsOneWidget);
    // Stage 1 is unlocked on a fresh install; everything after it is not. The
    // grid is lazy, so assert lock icons rather than an exact count.
    expect(find.byIcon(Icons.lock_rounded), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
