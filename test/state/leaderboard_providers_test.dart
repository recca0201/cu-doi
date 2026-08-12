import 'dart:async';
import 'dart:typed_data';

import 'package:ban_bua_tuong/data/game_services_gateway.dart';
import 'package:ban_bua_tuong/data/leaderboard_repository.dart';
import 'package:ban_bua_tuong/domain/leaderboard_models.dart';
import 'package:ban_bua_tuong/main.dart';
import 'package:ban_bua_tuong/state/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences preferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'soundOn': false,
      'musicOn': false,
      'localeCode': 'vi',
    });
    preferences = await SharedPreferences.getInstance();
  });

  test(
    'fake gateway override feeds repository, avatar and lifecycle graph',
    () async {
      final _ProviderGateway gateway = _ProviderGateway();
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(preferences),
          gameServicesGatewayProvider.overrideWithValue(gateway),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(leaderboardRepositoryProvider).gateway,
        same(gateway),
      );
      container.read(leaderboardLifecycleCoordinatorProvider);
      await _pumpUntil(() => gateway.restoreCalls == 1);
      expect(gateway.authenticateCalls, 0);

      final LeaderboardRepository repository = container.read(
        leaderboardRepositoryProvider,
      );
      await _pumpUntil(() => repository.identityState.maySubmit);

      final PlatformAvatarRef avatar = PlatformAvatarRef(
        platform: GameServicePlatform.gameCenter,
        identityEpoch: repository.identityEpoch,
        playerHash: 'row-hash',
        token: 'avatar-token',
      );
      expect(
        await container.read(platformAvatarLoaderProvider).load(avatar),
        Uint8List.fromList(<int>[4, 5, 6]),
      );
      expect(gateway.avatarCalls, 1);
      expect(gateway.lastAvatarIdentity?.sessionToken, 'provider-session');
    },
  );

  testWidgets('first release does not start platform leaderboard lifecycle', (
    WidgetTester tester,
  ) async {
    final _ProviderGateway gateway = _ProviderGateway();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(preferences),
          gameServicesGatewayProvider.overrideWithValue(gateway),
        ],
        child: const BanBuaTuongApp(),
      ),
    );
    await tester.pump();

    expect(gateway.restoreCalls, 0);
    expect(gateway.authenticateCalls, 0);
    expect(find.byKey(const Key('menu-play')), findsOneWidget);
  });
}

Future<void> _pumpUntil(bool Function() condition) async {
  for (int index = 0; index < 100 && !condition(); index++) {
    await Future<void>.delayed(Duration.zero);
  }
  expect(condition(), isTrue);
}

class _ProviderGateway implements GameServicesGateway {
  final StreamController<PlatformIdentityEvent> _events =
      StreamController<PlatformIdentityEvent>.broadcast();
  int restoreCalls = 0;
  int authenticateCalls = 0;
  int avatarCalls = 0;
  PlatformIdentity? lastAvatarIdentity;

  @override
  Future<PlatformIdentity?> restoreIdentity() async {
    restoreCalls++;
    return const PlatformIdentity(
      platform: GameServicePlatform.gameCenter,
      playerId: 'provider-player',
      displayName: 'Provider Player',
      sessionToken: 'provider-session',
    );
  }

  @override
  Future<PlatformIdentity> authenticate({required bool interactive}) async {
    authenticateCalls++;
    throw const GameServicesException(GameServicesFailureCode.unauthenticated);
  }

  @override
  Future<LeaderboardPage> loadLeaderboard({
    required PlatformIdentity identity,
    required int arenaId,
    required LeaderboardScope scope,
    required int limit,
  }) async => LeaderboardPage(leaders: const <LeaderboardEntry>[]);

  @override
  Future<Uint8List?> loadAvatar({
    required PlatformIdentity identity,
    required PlatformAvatarRef avatar,
  }) async {
    avatarCalls++;
    lastAvatarIdentity = identity;
    return Uint8List.fromList(<int>[4, 5, 6]);
  }

  @override
  Stream<PlatformIdentityEvent> get identityEvents => _events.stream;

  @override
  Future<void> submitScore({
    required PlatformIdentity identity,
    required int arenaId,
    required int score,
  }) async {}

  @override
  Future<void> validateConfiguration() async {}
}
