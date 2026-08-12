import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:ban_bua_tuong/data/game_services_gateway.dart';
import 'package:ban_bua_tuong/data/progress_repository.dart';
import 'package:ban_bua_tuong/domain/leaderboard_models.dart';
import 'package:ban_bua_tuong/domain/player_progress.dart';
import 'package:ban_bua_tuong/l10n/app_localizations.dart';
import 'package:ban_bua_tuong/sim/arena.dart';
import 'package:ban_bua_tuong/sim/geometry.dart';
import 'package:ban_bua_tuong/state/providers.dart';
import 'package:ban_bua_tuong/ui/fit.dart';
import 'package:ban_bua_tuong/ui/screens/game_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TrackingProgressRepository implements ProgressRepository {
  PlayerProgress value = const PlayerProgress();
  final List<String> events;
  int saves = 0;

  _TrackingProgressRepository(this.events);

  @override
  Future<PlayerProgress> load() async => value;

  @override
  Future<bool> save(PlayerProgress progress) async {
    events.add('local-save');
    saves++;
    value = progress;
    return true;
  }
}

class _Gateway implements GameServicesGateway {
  _Gateway(this.events);

  final List<String> events;
  int restores = 0;
  int authentications = 0;
  int reads = 0;
  int submissions = 0;

  static const PlatformIdentity identity = PlatformIdentity(
    platform: GameServicePlatform.playGames,
    playerId: 'player-one',
    displayName: 'Người chơi',
    sessionToken: 'session-one',
  );

  @override
  Future<PlatformIdentity?> restoreIdentity() async {
    restores++;
    return identity;
  }

  @override
  Future<PlatformIdentity> authenticate({required bool interactive}) async {
    authentications++;
    return identity;
  }

  @override
  Future<LeaderboardPage> loadLeaderboard({
    required PlatformIdentity identity,
    required int arenaId,
    required LeaderboardScope scope,
    required int limit,
  }) async {
    reads++;
    return LeaderboardPage(leaders: const <LeaderboardEntry>[]);
  }

  @override
  Future<Uint8List?> loadAvatar({
    required PlatformIdentity identity,
    required PlatformAvatarRef avatar,
  }) async => null;

  @override
  Stream<PlatformIdentityEvent> get identityEvents =>
      const Stream<PlatformIdentityEvent>.empty();

  @override
  Future<void> submitScore({
    required PlatformIdentity identity,
    required int arenaId,
    required int score,
  }) async {
    events.add('submit');
    submissions++;
  }

  @override
  Future<void> validateConfiguration() async {}
}

class _EagerLeaderboardOwner extends ConsumerWidget {
  const _EagerLeaderboardOwner({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(leaderboardLifecycleCoordinatorProvider);
    return child;
  }
}

Future<({ProviderContainer container, _TrackingProgressRepository progress})>
_pumpGame(
  WidgetTester tester, {
  required _Gateway gateway,
  required bool eagerLeaderboard,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final _TrackingProgressRepository progress = _TrackingProgressRepository(
    gateway.events,
  );
  final ProviderContainer container = ProviderContainer(
    overrides: <Override>[
      sharedPreferencesProvider.overrideWithValue(prefs),
      progressRepositoryProvider.overrideWithValue(progress),
      gameServicesGatewayProvider.overrideWithValue(gateway),
    ],
  );
  addTearDown(container.dispose);
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: eagerLeaderboard
            ? const _EagerLeaderboardOwner(child: GameScreen(arenaId: 1))
            : const GameScreen(arenaId: 1),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 30));
  return (container: container, progress: progress);
}

Future<void> _shoot(WidgetTester tester, double degrees) async {
  final Finder arena = find.byKey(const Key('game-arena-input'));
  final Size size = tester.getSize(arena);
  final ArenaFit fit = ArenaFit.of(size);
  final double radians = degrees * math.pi / 180;
  final V2 direction = V2(math.sin(radians), -math.cos(radians));
  final Offset local = fit.toScreen(kShooterOrigin + direction * 60);
  await tester.tapAt(tester.getTopLeft(arena) + local);
  for (int i = 0; i < 120; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (find.byKey(const Key('result-win-title')).evaluate().isNotEmpty) break;
  }
}

void main() {
  testWidgets(
    'aiming and a live runner perform no leaderboard read, submit or retry',
    (WidgetTester tester) async {
      final List<String> events = <String>[];
      final _Gateway gateway = _Gateway(events);
      final setup = await _pumpGame(
        tester,
        gateway: gateway,
        eagerLeaderboard: true,
      );
      for (int index = 0; index < 20; index++) {
        if (setup.container
            .read(leaderboardRepositoryProvider)
            .identityState
            .maySubmit) {
          break;
        }
        await tester.pump();
      }
      expect(
        setup.container
            .read(leaderboardRepositoryProvider)
            .identityState
            .maySubmit,
        isTrue,
      );
      final hasher = setup.container.read(identityHasherProvider);
      await hasher.initialize();
      final IdentityKey identityKey = IdentityKey(
        platform: _Gateway.identity.platform,
        identityHash: hasher.hashPlayerId(_Gateway.identity.playerId),
      );
      await setup.container
          .read(localLeaderboardStoreProvider)
          .upsertHighest(
            PendingScore(
              identityHash: identityKey.identityHash,
              platform: identityKey.platform,
              arenaId: 2,
              score: 600,
            ),
          );

      final Finder arena = find.byKey(const Key('game-arena-input'));
      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(arena),
      );
      await gesture.moveBy(const Offset(30, -60));
      await tester.pump();
      expect(find.byKey(const Key('win-leaderboard-button')), findsNothing);
      expect(gateway.reads, 0);
      expect(gateway.authentications, 0);
      expect(gateway.submissions, 0);
      expect(
        await setup.container
            .read(localLeaderboardStoreProvider)
            .loadSubmissions(identityKey),
        hasLength(1),
      );

      await gesture.up();
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.byKey(const Key('win-leaderboard-button')), findsNothing);
      expect(gateway.reads, 0);
      expect(gateway.authentications, 0);
      expect(gateway.submissions, 0);
      expect(
        await setup.container
            .read(localLeaderboardStoreProvider)
            .loadSubmissions(identityKey),
        hasLength(1),
      );
    },
  );

  testWidgets(
    'first release saves a win locally without leaderboard submission',
    (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      final List<String> events = <String>[];
      final _Gateway gateway = _Gateway(events);
      final setup = await _pumpGame(
        tester,
        gateway: gateway,
        eagerLeaderboard: true,
      );

      await _shoot(tester, -45.5694444444);
      await _shoot(tester, -46.75);
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }

      expect(find.byKey(const Key('result-win-title')), findsOneWidget);
      expect(find.text('Màn sau'), findsOneWidget);
      expect(find.text('Chọn màn'), findsOneWidget);
      expect(find.byKey(const Key('win-leaderboard-button')), findsNothing);
      expect(setup.progress.saves, 1);
      expect(gateway.submissions, 0);
      final int coinsAfterWin = setup.progress.value.coins;
      expect(find.byKey(const Key('result-win-title')), findsOneWidget);
      expect(find.text('Màn sau'), findsOneWidget);
      expect(find.text('Chọn màn'), findsOneWidget);
      expect(setup.progress.saves, 1);
      expect(setup.progress.value.coins, coinsAfterWin);
      expect(gateway.submissions, 0);
      expect(setup.container.read(progressProvider).isCompleted(1), isTrue);
      semantics.dispose();
    },
  );
}
