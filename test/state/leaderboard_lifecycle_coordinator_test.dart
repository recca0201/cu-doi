import 'dart:async';
import 'dart:typed_data';

import 'package:ban_bua_tuong/core/platform_avatar.dart';
import 'package:ban_bua_tuong/data/game_services_gateway.dart';
import 'package:ban_bua_tuong/data/identity_hasher.dart';
import 'package:ban_bua_tuong/data/leaderboard_repository.dart';
import 'package:ban_bua_tuong/data/local_leaderboard_store.dart';
import 'package:ban_bua_tuong/domain/leaderboard_models.dart';
import 'package:ban_bua_tuong/domain/player_progress.dart';
import 'package:ban_bua_tuong/state/leaderboard_controller.dart';
import 'package:ban_bua_tuong/state/leaderboard_lifecycle_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const PlatformIdentity identityA = PlatformIdentity(
    platform: GameServicePlatform.gameCenter,
    playerId: 'platform-player-a',
    displayName: 'Player A',
    sessionToken: 'session-a',
  );
  const PlatformIdentity identityB = PlatformIdentity(
    platform: GameServicePlatform.gameCenter,
    playerId: 'platform-player-b',
    displayName: 'Player B',
    sessionToken: 'session-b',
  );
  const PlatformIdentity identityARefreshed = PlatformIdentity(
    platform: GameServicePlatform.gameCenter,
    playerId: 'platform-player-a',
    displayName: 'Player A',
    sessionToken: 'session-a-refreshed',
  );

  late SharedPreferences preferences;
  late _LifecycleGateway gateway;
  late IdentityHasher hasher;
  late LocalLeaderboardStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    preferences = await SharedPreferences.getInstance();
    gateway = _LifecycleGateway();
    hasher = IdentityHasher(preferences);
    store = LocalLeaderboardStore(preferences);
  });

  test('startup performs silent restore and never interactive auth', () async {
    gateway.restoredIdentity = identityA;
    final LeaderboardRepository repository = _repository(
      gateway: gateway,
      store: store,
      hasher: hasher,
    );
    final LeaderboardLifecycleCoordinator coordinator =
        LeaderboardLifecycleCoordinator(
          gateway: gateway,
          repository: repository,
          submissions: LeaderboardSubmissionController(repository),
          avatarLoader: _avatarLoader(gateway, repository),
          progress: () => const PlayerProgress(),
          progressReady: () async {},
          progressConfirmed: () => true,
        );
    addTearDown(coordinator.dispose);

    await coordinator.initializeSilently();

    expect(gateway.restoreCalls, 1);
    expect(gateway.authenticateCalls, 0);
    expect(
      repository.identityState.confidence,
      IdentityConfidence.confirmedCurrent,
    );
    expect(repository.identityState.identity, identityA);
    expect(gateway.submitCalls, isEmpty);
  });

  test('resume flushes only while the current identity is confirmed', () async {
    final LeaderboardRepository repository = _repository(
      gateway: gateway,
      store: store,
      hasher: hasher,
    );
    final LeaderboardSubmissionController submissions =
        LeaderboardSubmissionController(repository);
    final LeaderboardLifecycleCoordinator coordinator =
        LeaderboardLifecycleCoordinator(
          gateway: gateway,
          repository: repository,
          submissions: submissions,
          avatarLoader: _avatarLoader(gateway, repository),
          progress: () => const PlayerProgress(),
          progressReady: () async {},
          progressConfirmed: () => true,
        );
    addTearDown(coordinator.dispose);

    await coordinator.onAppResumed();
    expect(gateway.submitCalls, isEmpty);
    expect(gateway.authenticateCalls, 0);

    await coordinator.handlePlatformIdentityEvent(
      const PlatformIdentityEvent.authenticated(identity: identityA, epoch: 1),
    );
    // Let the authentication-triggered empty flush finish before seeding the
    // score whose resume ordering this test observes.
    await pumpEventQueue();
    await hasher.initialize();
    final IdentityKey key = IdentityKey(
      platform: identityA.platform,
      identityHash: hasher.hashPlayerId(identityA.playerId),
    );
    await store.upsertHighest(
      PendingScore(
        identityHash: key.identityHash,
        platform: key.platform,
        arenaId: 1,
        score: 700,
      ),
    );

    gateway.restoredIdentity = identityA;
    gateway.callLog.clear();
    await coordinator.onAppResumed();
    expect(gateway.submitCalls, <(int, int)>[(1, 700)]);
    expect(gateway.callLog, <String>['restore', 'submit']);

    await coordinator.handlePlatformIdentityEvent(
      const PlatformIdentityEvent.signedOut(epoch: 2),
    );
    gateway.restoredIdentity = null;
    await store.upsertHighest(
      PendingScore(
        identityHash: key.identityHash,
        platform: key.platform,
        arenaId: 2,
        score: 900,
      ),
    );
    await coordinator.onAppResumed();
    expect(gateway.submitCalls, <(int, int)>[(1, 700)]);
    expect(gateway.authenticateCalls, 0);
  });

  test(
    'early auth event awaits confirmed progress before marking backfill',
    () async {
      final Completer<void> progressGate = Completer<void>();
      final Completer<void> submitGate = Completer<void>();
      gateway.submitGate = submitGate;
      PlayerProgress progress = const PlayerProgress();
      bool confirmed = false;
      final LeaderboardRepository repository = _repository(
        gateway: gateway,
        store: store,
        hasher: hasher,
      );
      final LeaderboardLifecycleCoordinator coordinator =
          LeaderboardLifecycleCoordinator(
            gateway: gateway,
            repository: repository,
            submissions: LeaderboardSubmissionController(repository),
            avatarLoader: _avatarLoader(gateway, repository),
            progress: () => progress,
            progressReady: () => progressGate.future,
            progressConfirmed: () => confirmed,
          );
      addTearDown(coordinator.dispose);

      final Future<void> handled = coordinator.handlePlatformIdentityEvent(
        const PlatformIdentityEvent.authenticated(
          identity: identityA,
          epoch: 1,
        ),
      );
      await hasher.initialize();
      final IdentityKey key = IdentityKey(
        platform: identityA.platform,
        identityHash: hasher.hashPlayerId(identityA.playerId),
      );
      await pumpEventQueue();

      expect(await store.hasCompletedInitialBackfill(key), isFalse);
      expect(await store.loadSubmissions(key), isEmpty);
      expect(gateway.submitCalls, isEmpty);

      progress = const PlayerProgress().withResult(1, 1, 700);
      confirmed = true;
      progressGate.complete();
      await handled;
      await _pumpUntil(() => gateway.submitCalls.isNotEmpty);

      expect(await store.hasCompletedInitialBackfill(key), isTrue);
      expect((await store.loadSubmissions(key)).single.score, 700);
      submitGate.complete();
    },
  );

  test('same player with a new session token advances the epoch', () async {
    final LeaderboardRepository repository = _repository(
      gateway: gateway,
      store: store,
      hasher: hasher,
      initialIdentityState: const PlatformIdentityState(
        confidence: IdentityConfidence.confirmedCurrent,
        epoch: 4,
        identity: identityA,
      ),
    );
    final LeaderboardLifecycleCoordinator coordinator =
        LeaderboardLifecycleCoordinator(
          gateway: gateway,
          repository: repository,
          submissions: LeaderboardSubmissionController(repository),
          avatarLoader: _avatarLoader(gateway, repository),
          progress: () => const PlayerProgress(),
          progressReady: () async {},
          progressConfirmed: () => true,
        );
    addTearDown(coordinator.dispose);

    await coordinator.handlePlatformIdentityEvent(
      const PlatformIdentityEvent.authenticated(
        identity: identityARefreshed,
        epoch: 4,
      ),
    );

    expect(repository.identityEpoch, 5);
    expect(repository.identityState.identity, identityARefreshed);
  });

  test(
    'detached identity events contain progress readiness failures',
    () async {
      final LeaderboardRepository repository = _repository(
        gateway: gateway,
        store: store,
        hasher: hasher,
      );
      final LeaderboardLifecycleCoordinator coordinator =
          LeaderboardLifecycleCoordinator(
            gateway: gateway,
            repository: repository,
            submissions: LeaderboardSubmissionController(repository),
            avatarLoader: _avatarLoader(gateway, repository),
            progress: () => const PlayerProgress(),
            progressReady: () =>
                Future<void>.error(StateError('progress restore failed')),
            progressConfirmed: () => false,
          );
      addTearDown(coordinator.dispose);

      gateway.emit(
        const PlatformIdentityEvent.authenticated(
          identity: identityA,
          epoch: 1,
        ),
      );
      await pumpEventQueue();

      expect(repository.identityState.identity, identityA);
      expect(repository.identityState.maySubmit, isTrue);
    },
  );

  test(
    'account change advances epoch and rejects late reads, submits and avatars',
    () async {
      final LeaderboardRepository repository = _repository(
        gateway: gateway,
        store: store,
        hasher: hasher,
        initialIdentityState: const PlatformIdentityState(
          confidence: IdentityConfidence.confirmedCurrent,
          epoch: 1,
          identity: identityA,
        ),
      );
      final LeaderboardSubmissionController submissions =
          LeaderboardSubmissionController(repository);
      final PlatformAvatarLoader avatars = _avatarLoader(gateway, repository);
      final LeaderboardLifecycleCoordinator coordinator =
          LeaderboardLifecycleCoordinator(
            gateway: gateway,
            repository: repository,
            submissions: submissions,
            avatarLoader: avatars,
            progress: () => const PlayerProgress(),
            progressReady: () async {},
            progressConfirmed: () => true,
          );
      addTearDown(coordinator.dispose);

      await hasher.initialize();
      final IdentityKey oldKey = IdentityKey(
        platform: identityA.platform,
        identityHash: hasher.hashPlayerId(identityA.playerId),
      );
      final PendingScore oldPending = PendingScore(
        identityHash: oldKey.identityHash,
        platform: oldKey.platform,
        arenaId: 1,
        score: 700,
      );
      await store.upsertHighest(oldPending);

      gateway.loadGate = Completer<void>();
      gateway.submitGate = Completer<void>();
      gateway.avatarGate = Completer<void>();
      final Future<LeaderboardLoadResult> lateRead = repository.load(
        arenaId: 1,
        scope: LeaderboardScope.global,
        allowMatchingCache: false,
      );
      final Future<void> lateSubmit = submissions.onAppResumed();
      const PlatformAvatarRef oldAvatar = PlatformAvatarRef(
        platform: GameServicePlatform.gameCenter,
        identityEpoch: 1,
        playerHash: 'old-row-hash',
        token: 'old-avatar-token',
      );
      final Future<Uint8List?> lateAvatar = avatars.loadForRow(
        oldAvatar,
        identityEpoch: 1,
        playerHash: 'old-row-hash',
      );
      await _pumpUntil(
        () =>
            gateway.loadCalls == 1 &&
            gateway.submitCalls.length == 1 &&
            gateway.avatarCalls == 1,
      );

      // A native bridge is allowed to repeat its previous epoch. The Dart
      // lifecycle boundary must still make an account switch strictly newer.
      gateway.emit(
        const PlatformIdentityEvent.accountChanged(
          epoch: 1,
          identity: identityB,
        ),
      );
      await _pumpUntil(() => repository.identityEpoch == 2);
      expect(repository.identityEpoch, 2);
      expect(repository.identityState.confidence, IdentityConfidence.changed);

      gateway.loadGate!.complete();
      gateway.submitGate!.complete();
      gateway.avatarGate!.complete();

      await expectLater(lateRead, throwsA(isA<LeaderboardRequestDiscarded>()));
      await lateSubmit;
      expect(await lateAvatar, isNull);
      expect(avatars.cacheEntryCount, 0);
      expect(await store.loadSubmissions(oldKey), <PendingScore>[oldPending]);
    },
  );
}

LeaderboardRepository _repository({
  required _LifecycleGateway gateway,
  required LocalLeaderboardStore store,
  required IdentityHasher hasher,
  PlatformIdentityState initialIdentityState =
      const PlatformIdentityState.unknown(),
}) => LeaderboardRepository(
  gateway: gateway,
  store: store,
  identityHasher: hasher,
  initialIdentityState: initialIdentityState,
);

PlatformAvatarLoader _avatarLoader(
  _LifecycleGateway gateway,
  LeaderboardRepository repository,
) => PlatformAvatarLoader(
  fetch: (PlatformAvatarRef avatar) => gateway.loadAvatar(
    identity: repository.identityState.identity!,
    avatar: avatar,
  ),
  isCurrent: (PlatformAvatarRef avatar) =>
      avatar.identityEpoch == repository.identityEpoch,
);

Future<void> _pumpUntil(bool Function() condition) async {
  for (int index = 0; index < 100 && !condition(); index++) {
    await Future<void>.delayed(Duration.zero);
  }
  expect(condition(), isTrue);
}

class _LifecycleGateway implements GameServicesGateway {
  final StreamController<PlatformIdentityEvent> _events =
      StreamController<PlatformIdentityEvent>.broadcast(sync: true);
  final List<(int, int)> submitCalls = <(int, int)>[];
  final List<String> callLog = <String>[];
  PlatformIdentity? restoredIdentity;
  Completer<void>? loadGate;
  Completer<void>? submitGate;
  Completer<void>? avatarGate;
  int restoreCalls = 0;
  int authenticateCalls = 0;
  int loadCalls = 0;
  int avatarCalls = 0;

  void emit(PlatformIdentityEvent event) => _events.add(event);

  @override
  Future<PlatformIdentity?> restoreIdentity() async {
    restoreCalls++;
    callLog.add('restore');
    return restoredIdentity;
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
  }) async {
    loadCalls++;
    await loadGate?.future;
    return LeaderboardPage(
      leaders: const <LeaderboardEntry>[
        LeaderboardEntry(
          rank: 1,
          playerId: 'platform-player-a',
          displayName: 'Player A',
          score: 700,
          isCurrentPlayer: true,
        ),
      ],
    );
  }

  @override
  Future<Uint8List?> loadAvatar({
    required PlatformIdentity identity,
    required PlatformAvatarRef avatar,
  }) async {
    avatarCalls++;
    await avatarGate?.future;
    return Uint8List.fromList(<int>[1, 2, 3]);
  }

  @override
  Stream<PlatformIdentityEvent> get identityEvents => _events.stream;

  @override
  Future<void> submitScore({
    required PlatformIdentity identity,
    required int arenaId,
    required int score,
  }) async {
    submitCalls.add((arenaId, score));
    callLog.add('submit');
    await submitGate?.future;
  }

  @override
  Future<void> validateConfiguration() async {}
}
