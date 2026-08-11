import 'dart:async';
import 'dart:typed_data';

import 'package:ban_bua_tuong/data/game_services_gateway.dart';
import 'package:ban_bua_tuong/data/identity_hasher.dart';
import 'package:ban_bua_tuong/data/leaderboard_repository.dart';
import 'package:ban_bua_tuong/data/local_leaderboard_store.dart';
import 'package:ban_bua_tuong/domain/leaderboard_models.dart';
import 'package:ban_bua_tuong/state/account_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const PlatformIdentity identity = PlatformIdentity(
    platform: GameServicePlatform.gameCenter,
    playerId: 'player-current',
    displayName: 'Tôi',
    sessionToken: 'session-current',
  );

  LeaderboardEntry row({
    required int rank,
    required String playerId,
    required int score,
    bool mine = false,
  }) => LeaderboardEntry(
    rank: rank,
    playerId: playerId,
    displayName: playerId,
    score: score,
    isCurrentPlayer: mine,
  );

  late SharedPreferences prefs;
  late LocalLeaderboardStore store;
  late IdentityHasher hasher;
  late FakeGameServicesGateway gateway;

  LeaderboardRepository repository({
    PlatformIdentityState state = const PlatformIdentityState.unknown(),
  }) => LeaderboardRepository(
    gateway: gateway,
    store: store,
    identityHasher: hasher,
    initialIdentityState: state,
    now: () => DateTime.utc(2026, 8, 11, 12),
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
    store = LocalLeaderboardStore(prefs);
    hasher = IdentityHasher(prefs);
    gateway = FakeGameServicesGateway();
  });

  test(
    'silent restore never presents UI; user auth is always interactive',
    () async {
      gateway.restoredIdentity = identity;
      gateway.authenticatedIdentity = identity;
      final LeaderboardRepository repo = repository();

      final PlatformIdentityState restored = await repo.restoreIdentity();
      final PlatformIdentity authenticated = await repo
          .authenticateFromUserAction();

      expect(restored.confidence, IdentityConfidence.confirmedCurrent);
      expect(authenticated, identity);
      expect(gateway.restoreCalls, 1);
      expect(gateway.authenticateArguments, <bool>[true]);
    },
  );

  test(
    'returns auth-required without an identity or a platform read',
    () async {
      final LeaderboardRepository repo = repository();

      final LeaderboardLoadResult result = await repo.load(
        arenaId: 1,
        scope: LeaderboardScope.global,
        allowMatchingCache: true,
      );

      expect(result.status, LeaderboardLoadStatus.authRequired);
      expect(gateway.loadCalls, isEmpty);
    },
  );

  test(
    'fresh read keeps platform rank/ties and represents current player once',
    () async {
      gateway.loadHandler = (_, _, _) async => LeaderboardPage(
        leaders: <LeaderboardEntry>[
          row(rank: 1, playerId: 'leader-a', score: 9000),
          row(rank: 1, playerId: 'leader-b', score: 9000),
          row(rank: 7, playerId: identity.playerId, score: 7000, mine: true),
        ],
        currentPlayer: row(
          rank: 7,
          playerId: identity.playerId,
          score: 7000,
          mine: true,
        ),
      );
      final LeaderboardRepository repo = repository(
        state: const PlatformIdentityState(
          confidence: IdentityConfidence.confirmedCurrent,
          epoch: 4,
          identity: identity,
        ),
      );

      final LeaderboardLoadResult result = await repo.load(
        arenaId: 3,
        scope: LeaderboardScope.global,
        allowMatchingCache: true,
      );

      expect(result.status, LeaderboardLoadStatus.fresh);
      expect(
        result.page!.leaders.map((LeaderboardEntry item) => item.rank),
        <int>[1, 1, 7],
      );
      expect(
        result.page!.leaders.where(
          (LeaderboardEntry item) => item.isCurrentPlayer,
        ),
        hasLength(1),
      );
      expect(result.page!.currentPlayer, isNull);
      expect(gateway.loadCalls.single, (3, LeaderboardScope.global, 100));
      expect(gateway.loadIdentities.single, identity);
    },
  );

  test('fresh network data survives a local cache-write failure', () async {
    store = _FailingSnapshotStore(prefs);
    gateway.loadHandler = (_, _, _) async => LeaderboardPage(
      leaders: <LeaderboardEntry>[
        row(rank: 1, playerId: 'fresh-player', score: 9500),
      ],
    );
    final LeaderboardRepository repo = repository(
      state: const PlatformIdentityState(
        confidence: IdentityConfidence.confirmedCurrent,
        epoch: 1,
        identity: identity,
      ),
    );

    final LeaderboardLoadResult result = await repo.load(
      arenaId: 3,
      scope: LeaderboardScope.global,
      allowMatchingCache: true,
    );

    expect(result.status, LeaderboardLoadStatus.fresh);
    expect(result.page!.leaders.single.playerId, 'fresh-player');
  });

  test(
    'current player outside top 100 stays separate with platform rank',
    () async {
      gateway.loadHandler = (_, _, _) async => LeaderboardPage(
        leaders: List<LeaderboardEntry>.generate(
          100,
          (int index) => row(
            rank: index + 1,
            playerId: 'leader-$index',
            score: 10000 - index,
          ),
        ),
        currentPlayer: row(
          rank: 143,
          playerId: identity.playerId,
          score: 4321,
          mine: true,
        ),
      );
      final LeaderboardRepository repo = repository(
        state: const PlatformIdentityState(
          confidence: IdentityConfidence.confirmedCurrent,
          epoch: 1,
          identity: identity,
        ),
      );

      final LeaderboardLoadResult result = await repo.load(
        arenaId: 4,
        scope: LeaderboardScope.global,
        allowMatchingCache: true,
      );

      expect(result.page!.leaders, hasLength(100));
      expect(result.page!.currentPlayer!.rank, 143);
      expect(result.page!.currentPlayer!.isCurrentPlayer, isTrue);
    },
  );

  test(
    'valid empty read returns empty and caches the complete result',
    () async {
      gateway.loadHandler = (_, _, _) async =>
          LeaderboardPage(leaders: const <LeaderboardEntry>[]);
      final LeaderboardRepository repo = repository(
        state: const PlatformIdentityState(
          confidence: IdentityConfidence.confirmedCurrent,
          epoch: 1,
          identity: identity,
        ),
      );

      final LeaderboardLoadResult result = await repo.load(
        arenaId: 5,
        scope: LeaderboardScope.friends,
        allowMatchingCache: true,
      );
      final String hash = hasher.hashPlayerId(identity.playerId);

      expect(result.status, LeaderboardLoadStatus.empty);
      expect(
        await store.loadSnapshot(
          LeaderboardCacheKey(
            platform: identity.platform,
            identityHash: hash,
            arenaId: 5,
            scope: LeaderboardScope.friends,
          ),
        ),
        isNotNull,
      );
    },
  );

  test(
    'maps friends-unavailable separately and never caches a failure',
    () async {
      gateway.loadHandler = (_, _, _) async =>
          throw const GameServicesException(
            GameServicesFailureCode.friendsUnavailable,
          );
      final LeaderboardRepository repo = repository(
        state: const PlatformIdentityState(
          confidence: IdentityConfidence.confirmedCurrent,
          epoch: 2,
          identity: identity,
        ),
      );

      final LeaderboardLoadResult result = await repo.load(
        arenaId: 6,
        scope: LeaderboardScope.friends,
        allowMatchingCache: true,
      );

      expect(result.status, LeaderboardLoadStatus.friendsUnavailable);
      expect(
        result.reasonCode,
        GameServicesFailureCode.friendsUnavailable.name,
      );
    },
  );

  test(
    'maps unauthenticated and service errors without matching cache',
    () async {
      final LeaderboardRepository repo = repository(
        state: const PlatformIdentityState(
          confidence: IdentityConfidence.confirmedCurrent,
          epoch: 2,
          identity: identity,
        ),
      );
      gateway.loadHandler = (_, _, _) async =>
          throw const GameServicesException(
            GameServicesFailureCode.unauthenticated,
          );
      expect(
        (await repo.load(
          arenaId: 7,
          scope: LeaderboardScope.global,
          allowMatchingCache: true,
        )).status,
        LeaderboardLoadStatus.authRequired,
      );
      expect(repo.identityState.confidence, IdentityConfidence.changed);

      gateway.loadHandler = (_, _, _) async =>
          throw const GameServicesException(GameServicesFailureCode.retryable);
      final LeaderboardRepository retryableRepo = repository(
        state: const PlatformIdentityState(
          confidence: IdentityConfidence.confirmedCurrent,
          epoch: 3,
          identity: identity,
        ),
      );
      final LeaderboardLoadResult service = await retryableRepo.load(
        arenaId: 8,
        scope: LeaderboardScope.global,
        allowMatchingCache: true,
      );
      expect(service.status, LeaderboardLoadStatus.serviceError);
      expect(service.reasonCode, GameServicesFailureCode.retryable.name);
    },
  );

  test(
    'native unauth rejection invalidates identity without reading old cache',
    () async {
      final _TrackingSnapshotStore tracking = _TrackingSnapshotStore(prefs);
      store = tracking;
      gateway.loadHandler = (_, _, _) async =>
          throw const GameServicesException(
            GameServicesFailureCode.unauthenticated,
          );
      final LeaderboardRepository repo = repository(
        state: const PlatformIdentityState(
          confidence: IdentityConfidence.confirmedCurrent,
          epoch: 4,
          identity: identity,
        ),
      );

      final LeaderboardLoadResult result = await repo.load(
        arenaId: 7,
        scope: LeaderboardScope.global,
        allowMatchingCache: true,
      );

      expect(result.status, LeaderboardLoadStatus.authRequired);
      expect(tracking.loadCalls, 0);
      expect(repo.identityState.confidence, IdentityConfidence.changed);
      expect(repo.identityState.identity, isNull);
    },
  );

  test(
    'fallback reads only the exact platform identity arena and scope key',
    () async {
      await hasher.initialize();
      final String hash = hasher.hashPlayerId(identity.playerId);
      LeaderboardSnapshot cached(String label) => LeaderboardSnapshot(
        rows: <PersistedLeaderboardRow>[
          PersistedLeaderboardRow(
            rank: 1,
            playerHash: 'hash-$label',
            displayName: label,
            score: 100,
            isCurrentPlayer: false,
          ),
        ],
        fetchedAt: DateTime.utc(2026, 8, 10),
      );
      await store.saveSnapshot(
        LeaderboardCacheKey(
          platform: identity.platform,
          identityHash: hash,
          arenaId: 9,
          scope: LeaderboardScope.global,
        ),
        cached('exact'),
      );
      await store.saveSnapshot(
        LeaderboardCacheKey(
          platform: identity.platform,
          identityHash: hash,
          arenaId: 9,
          scope: LeaderboardScope.friends,
        ),
        cached('wrong-scope'),
      );
      gateway.loadHandler = (_, _, _) async =>
          throw const GameServicesException(GameServicesFailureCode.retryable);
      final LeaderboardRepository repo = repository(
        state: const PlatformIdentityState(
          confidence: IdentityConfidence.confirmedCurrent,
          epoch: 3,
          identity: identity,
        ),
      );

      final LeaderboardLoadResult result = await repo.load(
        arenaId: 9,
        scope: LeaderboardScope.global,
        allowMatchingCache: true,
      );

      expect(result.status, LeaderboardLoadStatus.staleCache);
      expect(result.snapshot!.rows.single.displayName, 'exact');
    },
  );

  for (final IdentityConfidence confidence in IdentityConfidence.values) {
    test(
      'identity confidence ${confidence.name} enforces cache boundary',
      () async {
        await hasher.initialize();
        final String hash = hasher.hashPlayerId(identity.playerId);
        final LeaderboardCacheKey key = LeaderboardCacheKey(
          platform: identity.platform,
          identityHash: hash,
          arenaId: 10,
          scope: LeaderboardScope.global,
        );
        await store.saveSnapshot(
          key,
          LeaderboardSnapshot(
            rows: const <PersistedLeaderboardRow>[],
            currentPlayer: PersistedLeaderboardRow(
              rank: 120,
              playerHash: hash,
              displayName: 'Tôi',
              score: 1000,
              isCurrentPlayer: true,
            ),
            fetchedAt: DateTime.utc(2026, 8, 10),
          ),
        );
        gateway.loadHandler = (_, _, _) async =>
            throw const GameServicesException(
              GameServicesFailureCode.retryable,
            );
        final LeaderboardRepository repo = repository(
          state: PlatformIdentityState(
            confidence: confidence,
            epoch: 3,
            identity: identity,
          ),
        );

        final LeaderboardLoadResult result = await repo.load(
          arenaId: 10,
          scope: LeaderboardScope.global,
          allowMatchingCache: true,
        );

        if (confidence == IdentityConfidence.confirmedCurrent ||
            confidence == IdentityConfidence.lastKnownUnchanged) {
          expect(result.status, LeaderboardLoadStatus.staleCache);
          expect(result.snapshot!.currentPlayer!.displayName, 'Tôi');
        } else {
          expect(result.status, LeaderboardLoadStatus.authRequired);
          expect(result.snapshot, isNull);
        }
        expect(
          gateway.loadCalls.length,
          confidence == IdentityConfidence.confirmedCurrent ? 1 : 0,
        );
      },
    );
  }

  test(
    'newer request discards a late response before cache mutation',
    () async {
      final Completer<LeaderboardPage> first = Completer<LeaderboardPage>();
      int request = 0;
      gateway.loadHandler = (_, _, _) {
        request++;
        if (request == 1) return first.future;
        return Future<LeaderboardPage>.value(
          LeaderboardPage(
            leaders: <LeaderboardEntry>[
              row(rank: 1, playerId: 'new', score: 200),
            ],
          ),
        );
      };
      final LeaderboardRepository repo = repository(
        state: const PlatformIdentityState(
          confidence: IdentityConfidence.confirmedCurrent,
          epoch: 7,
          identity: identity,
        ),
      );

      final Future<LeaderboardLoadResult> oldLoad = repo.load(
        arenaId: 11,
        scope: LeaderboardScope.global,
        allowMatchingCache: true,
      );
      while (gateway.loadCalls.isEmpty) {
        await Future<void>.delayed(Duration.zero);
      }
      final LeaderboardLoadResult newest = await repo.load(
        arenaId: 11,
        scope: LeaderboardScope.global,
        allowMatchingCache: true,
      );
      first.complete(
        LeaderboardPage(
          leaders: <LeaderboardEntry>[
            row(rank: 1, playerId: 'old', score: 100),
          ],
        ),
      );

      expect(newest.page!.leaders.single.playerId, 'new');
      await expectLater(oldLoad, throwsA(isA<LeaderboardRequestDiscarded>()));
      final String hash = hasher.hashPlayerId(identity.playerId);
      final LeaderboardSnapshot saved = (await store.loadSnapshot(
        LeaderboardCacheKey(
          platform: identity.platform,
          identityHash: hash,
          arenaId: 11,
          scope: LeaderboardScope.global,
        ),
      ))!;
      expect(saved.rows.single.displayName, 'new');
    },
  );

  test(
    'identity epoch change discards an in-flight response and its cache',
    () async {
      final Completer<LeaderboardPage> pending = Completer<LeaderboardPage>();
      gateway.loadHandler = (_, _, _) => pending.future;
      final LeaderboardRepository repo = repository(
        state: const PlatformIdentityState(
          confidence: IdentityConfidence.confirmedCurrent,
          epoch: 8,
          identity: identity,
        ),
      );

      final Future<LeaderboardLoadResult> load = repo.load(
        arenaId: 12,
        scope: LeaderboardScope.global,
        allowMatchingCache: true,
      );
      while (gateway.loadCalls.isEmpty) {
        await Future<void>.delayed(Duration.zero);
      }
      repo.handleIdentityEvent(
        const PlatformIdentityEvent.accountChanged(epoch: 9),
      );
      pending.complete(
        LeaderboardPage(
          leaders: <LeaderboardEntry>[
            row(rank: 1, playerId: 'old-account', score: 999),
          ],
        ),
      );

      await expectLater(load, throwsA(isA<LeaderboardRequestDiscarded>()));
      expect(repo.identityState.confidence, IdentityConfidence.changed);
      final String hash = hasher.hashPlayerId(identity.playerId);
      expect(
        await store.loadSnapshot(
          LeaderboardCacheKey(
            platform: identity.platform,
            identityHash: hash,
            arenaId: 12,
            scope: LeaderboardScope.global,
          ),
        ),
        isNull,
      );
    },
  );

  test('Firebase account lifecycle cannot change platform identity', () async {
    final LeaderboardRepository repo = repository(
      state: const PlatformIdentityState(
        confidence: IdentityConfidence.confirmedCurrent,
        epoch: 6,
        identity: identity,
      ),
    );
    final AccountController account = AccountController(
      _FakeAccountRepository(),
    );
    addTearDown(account.dispose);

    await account.signIn(AuthProviderKind.google);
    await account.link(AuthProviderKind.apple);
    expect(await account.signOut(), isTrue);

    expect(account.state.phase, AccountPhase.guest);
    expect(repo.identityState.identity, identity);
    expect(repo.identityState.confidence, IdentityConfidence.confirmedCurrent);
    expect(repo.identityEpoch, 6);
    expect(gateway.restoreCalls, 0);
    expect(gateway.authenticateArguments, isEmpty);
    expect(gateway.loadCalls, isEmpty);
    expect(gateway.submitCalls, 0);
  });

  test(
    'clearing the app namespace removes leaderboard cache and queue',
    () async {
      await hasher.initialize();
      final String identityHash = hasher.hashPlayerId(identity.playerId);
      final IdentityKey identityKey = IdentityKey(
        platform: identity.platform,
        identityHash: identityHash,
      );
      final LeaderboardCacheKey cacheKey = LeaderboardCacheKey(
        platform: identity.platform,
        identityHash: identityHash,
        arenaId: 1,
        scope: LeaderboardScope.global,
      );
      await store.saveSnapshot(
        cacheKey,
        LeaderboardSnapshot(
          rows: <PersistedLeaderboardRow>[
            PersistedLeaderboardRow(
              rank: 1,
              playerHash: identityHash,
              displayName: 'Tôi',
              score: 500,
              isCurrentPlayer: true,
            ),
          ],
          fetchedAt: DateTime.utc(2026, 8, 11),
        ),
      );
      await store.upsertHighest(
        PendingScore(
          identityHash: identityHash,
          platform: identity.platform,
          arenaId: 1,
          score: 500,
        ),
      );
      await store.markInitialBackfillComplete(identityKey);
      expect(await store.loadSnapshot(cacheKey), isNotNull);
      expect(await store.loadSubmissions(identityKey), hasLength(1));

      expect(await prefs.clear(), isTrue);

      final LocalLeaderboardStore afterClear = LocalLeaderboardStore(prefs);
      expect(await afterClear.loadSnapshot(cacheKey), isNull);
      expect(await afterClear.loadSubmissions(identityKey), isEmpty);
      expect(
        await afterClear.hasCompletedInitialBackfill(identityKey),
        isFalse,
      );
      expect(prefs.getString(IdentityHasher.saltPreferenceKey), isNull);
      expect(
        prefs.getKeys().where(
          (String key) => kLeaderboardIdentityPartitionPrefixes.any(
            (String prefix) => key.startsWith(prefix),
          ),
        ),
        isEmpty,
      );
    },
  );
}

typedef LoadHandler =
    Future<LeaderboardPage> Function(
      int arenaId,
      LeaderboardScope scope,
      int limit,
    );

class FakeGameServicesGateway implements GameServicesGateway {
  PlatformIdentity? restoredIdentity;
  PlatformIdentity? authenticatedIdentity;
  int restoreCalls = 0;
  final List<bool> authenticateArguments = <bool>[];
  final List<(int, LeaderboardScope, int)> loadCalls =
      <(int, LeaderboardScope, int)>[];
  final List<PlatformIdentity> loadIdentities = <PlatformIdentity>[];
  final List<PlatformIdentity> submitIdentities = <PlatformIdentity>[];
  LoadHandler? loadHandler;
  final StreamController<PlatformIdentityEvent> events =
      StreamController<PlatformIdentityEvent>.broadcast();
  int submitCalls = 0;

  @override
  Future<PlatformIdentity?> restoreIdentity() async {
    restoreCalls++;
    return restoredIdentity;
  }

  @override
  Future<PlatformIdentity> authenticate({required bool interactive}) async {
    authenticateArguments.add(interactive);
    return authenticatedIdentity ??
        (throw const GameServicesException(
          GameServicesFailureCode.unauthenticated,
        ));
  }

  @override
  Future<LeaderboardPage> loadLeaderboard({
    required PlatformIdentity identity,
    required int arenaId,
    required LeaderboardScope scope,
    required int limit,
  }) {
    loadCalls.add((arenaId, scope, limit));
    loadIdentities.add(identity);
    return loadHandler?.call(arenaId, scope, limit) ??
        Future<LeaderboardPage>.value(
          LeaderboardPage(leaders: const <LeaderboardEntry>[]),
        );
  }

  @override
  Stream<PlatformIdentityEvent> get identityEvents => events.stream;

  @override
  Future<Uint8List?> loadAvatar({
    required PlatformIdentity identity,
    required PlatformAvatarRef avatar,
  }) async => null;

  @override
  Future<void> submitScore({
    required PlatformIdentity identity,
    required int arenaId,
    required int score,
  }) async {
    submitCalls++;
    submitIdentities.add(identity);
  }

  @override
  Future<void> validateConfiguration() async {}
}

class _FailingSnapshotStore extends LocalLeaderboardStore {
  _FailingSnapshotStore(super.preferences);

  @override
  Future<void> saveSnapshot(
    LeaderboardCacheKey key,
    LeaderboardSnapshot value,
  ) async {
    throw StateError('simulated cache write failure');
  }
}

class _TrackingSnapshotStore extends LocalLeaderboardStore {
  _TrackingSnapshotStore(super.preferences);

  int loadCalls = 0;

  @override
  Future<LeaderboardSnapshot?> loadSnapshot(LeaderboardCacheKey key) {
    loadCalls++;
    return super.loadSnapshot(key);
  }
}

class _FakeAccountRepository implements AccountRepository {
  Set<AuthProviderKind> providers = <AuthProviderKind>{};

  @override
  Future<AccountIdentity?> signIn(AuthProviderKind provider) async {
    providers = <AuthProviderKind>{provider};
    return AccountIdentity(uid: 'firebase-user', providers: providers);
  }

  @override
  Future<Set<AuthProviderKind>> link(AuthProviderKind provider) async {
    providers = <AuthProviderKind>{...providers, provider};
    return providers;
  }

  @override
  Future<ReauthenticationProof> reauthenticate(
    AuthProviderKind provider,
  ) async => ReauthenticationProof(provider: provider, idToken: 'test-token');

  @override
  Future<void> signOut() async {}
}
