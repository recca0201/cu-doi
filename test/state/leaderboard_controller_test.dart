import 'dart:async';
import 'dart:typed_data';

import 'package:ban_bua_tuong/data/game_services_gateway.dart';
import 'package:ban_bua_tuong/data/identity_hasher.dart';
import 'package:ban_bua_tuong/data/leaderboard_repository.dart';
import 'package:ban_bua_tuong/data/local_leaderboard_store.dart';
import 'package:ban_bua_tuong/domain/leaderboard_models.dart';
import 'package:ban_bua_tuong/state/leaderboard_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const PlatformIdentity identity = PlatformIdentity(
    platform: GameServicePlatform.gameCenter,
    playerId: 'player-a',
    displayName: 'Player A',
    sessionToken: 'session-a',
  );
  const PlatformIdentity identityB = PlatformIdentity(
    platform: GameServicePlatform.gameCenter,
    playerId: 'player-b',
    displayName: 'Player B',
    sessionToken: 'session-b',
  );

  late SharedPreferences preferences;
  late LocalLeaderboardStore store;
  late IdentityHasher hasher;
  late _ReadGateway gateway;
  late LeaderboardRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    preferences = await SharedPreferences.getInstance();
    store = LocalLeaderboardStore(preferences);
    hasher = IdentityHasher(preferences);
    gateway = _ReadGateway();
    repository = LeaderboardRepository(
      gateway: gateway,
      store: store,
      identityHasher: hasher,
      initialIdentityState: const PlatformIdentityState(
        confidence: IdentityConfidence.confirmedCurrent,
        epoch: 1,
        identity: identity,
      ),
    );
  });

  Future<void> seedSnapshot({required int arenaId, required int score}) async {
    await hasher.initialize();
    await store.saveSnapshot(
      LeaderboardCacheKey(
        platform: identity.platform,
        identityHash: hasher.hashPlayerId(identity.playerId),
        arenaId: arenaId,
        scope: LeaderboardScope.global,
      ),
      LeaderboardSnapshot(
        rows: <PersistedLeaderboardRow>[
          PersistedLeaderboardRow(
            rank: 1,
            playerHash: 'cached-player',
            displayName: 'Cached',
            score: score,
            isCurrentPlayer: false,
          ),
        ],
        fetchedAt: DateTime.utc(2026, 8, 10),
      ),
    );
  }

  test('defaults to Global and remembers the last selected scope', () async {
    final LeaderboardController first = LeaderboardController(
      repository,
      arenaId: 4,
    );
    addTearDown(first.dispose);
    expect(first.state.scope, LeaderboardScope.global);

    final Future<void> selection = first.selectScope(LeaderboardScope.friends);
    await _completeNext(
      gateway,
      LeaderboardPage(leaders: const <LeaderboardEntry>[]),
    );
    await selection;

    final LeaderboardController reopened = LeaderboardController(
      repository,
      arenaId: 4,
    );
    addTearDown(reopened.dispose);
    expect(reopened.state.scope, LeaderboardScope.friends);
  });

  test('scope selection loads the same arena all-time board', () async {
    final LeaderboardController controller = LeaderboardController(
      repository,
      arenaId: 7,
    );
    addTearDown(controller.dispose);

    final Future<void> load = controller.selectScope(LeaderboardScope.friends);
    await _completeNext(gateway, _page(score: 910));
    await load;

    expect(gateway.calls, <(int, LeaderboardScope)>[
      (7, LeaderboardScope.friends),
    ]);
    expect(controller.state.period, LeaderboardPeriod.allTime);
    expect(controller.state.status, LeaderboardViewStatus.loaded);
  });

  test('loading is nonblocking and keeps Back and scope available', () async {
    final LeaderboardController controller = LeaderboardController(
      repository,
      arenaId: 2,
    );
    addTearDown(controller.dispose);

    final Future<void> load = controller.load();
    expect(controller.state.status, LeaderboardViewStatus.loading);
    expect(controller.state.isLoading, isTrue);
    expect(controller.state.canNavigateBack, isTrue);
    expect(controller.state.canSelectScope, isTrue);

    await _completeNext(gateway, _page(score: 500));
    await load;
  });

  test('a valid empty board never synthesizes zero-score rows', () async {
    final LeaderboardController controller = LeaderboardController(
      repository,
      arenaId: 1,
    );
    addTearDown(controller.dispose);

    final Future<void> load = controller.load();
    await _completeNext(
      gateway,
      LeaderboardPage(leaders: const <LeaderboardEntry>[]),
    );
    await load;

    expect(controller.state.status, LeaderboardViewStatus.empty);
    expect(controller.state.page, isNull);
    expect(controller.state.snapshot, isNull);
    expect(controller.state.rowCount, 0);
  });

  test(
    'friends unavailable is explicit and Global remains selectable',
    () async {
      final LeaderboardController controller = LeaderboardController(
        repository,
        arenaId: 3,
      );
      addTearDown(controller.dispose);

      final Future<void> friends = controller.selectScope(
        LeaderboardScope.friends,
      );
      await _failNext(
        gateway,
        const GameServicesException(GameServicesFailureCode.friendsUnavailable),
      );
      await friends;
      expect(controller.state.status, LeaderboardViewStatus.friendsUnavailable);

      final Future<void> global = controller.selectScope(
        LeaderboardScope.global,
      );
      await _completeNext(gateway, _page(score: 720));
      await global;
      expect(controller.state.status, LeaderboardViewStatus.loaded);
      expect(controller.state.scope, LeaderboardScope.global);
    },
  );

  test('retry replaces a service error with a loaded board', () async {
    final LeaderboardController controller = LeaderboardController(
      repository,
      arenaId: 5,
    );
    addTearDown(controller.dispose);

    final Future<void> failed = controller.load();
    await _failNext(
      gateway,
      const GameServicesException(GameServicesFailureCode.permanent),
    );
    await failed;
    expect(controller.state.status, LeaderboardViewStatus.serviceError);

    final Future<void> retried = controller.retry();
    await _completeNext(gateway, _page(score: 1100));
    await retried;
    expect(controller.state.status, LeaderboardViewStatus.loaded);
    expect(controller.state.page!.leaders.single.score, 1100);
  });

  test(
    'retryable failure uses matching cache, otherwise offline no-cache',
    () async {
      await seedSnapshot(arenaId: 6, score: 600);
      final LeaderboardController cached = LeaderboardController(
        repository,
        arenaId: 6,
      );
      addTearDown(cached.dispose);

      final Future<void> cachedLoad = cached.load();
      await _failNext(
        gateway,
        const GameServicesException(GameServicesFailureCode.retryable),
      );
      await cachedLoad;
      expect(cached.state.status, LeaderboardViewStatus.offlineCache);
      expect(cached.state.snapshot!.rows.single.score, 600);

      final LeaderboardController uncached = LeaderboardController(
        repository,
        arenaId: 8,
      );
      addTearDown(uncached.dispose);
      final Future<void> uncachedLoad = uncached.load();
      await _failNext(
        gateway,
        const GameServicesException(GameServicesFailureCode.retryable),
      );
      await uncachedLoad;
      expect(uncached.state.status, LeaderboardViewStatus.offlineNoCache);
      expect(uncached.state.rowCount, 0);
    },
  );

  test(
    'last-known identity without matching cache is offline no-cache',
    () async {
      final LeaderboardRepository lastKnown = LeaderboardRepository(
        gateway: gateway,
        store: store,
        identityHasher: hasher,
        initialIdentityState: const PlatformIdentityState(
          confidence: IdentityConfidence.lastKnownUnchanged,
          epoch: 1,
          identity: identity,
        ),
      );
      final LeaderboardController controller = LeaderboardController(
        lastKnown,
        arenaId: 13,
      );
      addTearDown(controller.dispose);

      await controller.load();

      expect(controller.state.status, LeaderboardViewStatus.offlineNoCache);
      expect(gateway.calls, isEmpty);
    },
  );

  test(
    'fresh data replaces stale cache and removes the stale warning',
    () async {
      await seedSnapshot(arenaId: 9, score: 400);
      final LeaderboardController controller = LeaderboardController(
        repository,
        arenaId: 9,
      );
      addTearDown(controller.dispose);

      final Future<void> stale = controller.load();
      await _failNext(
        gateway,
        const GameServicesException(GameServicesFailureCode.retryable),
      );
      await stale;
      expect(controller.state.status, LeaderboardViewStatus.offlineCache);

      final Future<void> fresh = controller.retry();
      await _completeNext(gateway, _page(score: 1200));
      await fresh;
      expect(controller.state.status, LeaderboardViewStatus.loaded);
      expect(controller.state.isStale, isFalse);
      expect(controller.state.snapshot, isNull);
      expect(controller.state.page!.leaders.single.score, 1200);
    },
  );

  test('a late request cannot overwrite a newly selected scope', () async {
    final LeaderboardController controller = LeaderboardController(
      repository,
      arenaId: 10,
    );
    addTearDown(controller.dispose);

    final Future<void> global = controller.load();
    await _pumpUntil(() => gateway.pending.length == 1);
    final Completer<LeaderboardPage> oldRequest = gateway.pending.single;

    final Future<void> friends = controller.selectScope(
      LeaderboardScope.friends,
    );
    await _pumpUntil(() => gateway.pending.length == 2);
    gateway.pending.last.complete(_page(score: 2000));
    await friends;
    expect(controller.state.scope, LeaderboardScope.friends);
    expect(controller.state.page!.leaders.single.score, 2000);

    oldRequest.complete(_page(score: 100));
    await global;
    expect(controller.state.scope, LeaderboardScope.friends);
    expect(controller.state.page!.leaders.single.score, 2000);
  });

  test(
    'open retries submissions once and never starts platform auth',
    () async {
      int openRetries = 0;
      final LeaderboardController controller = LeaderboardController(
        repository,
        arenaId: 11,
        onOpened: () async {
          openRetries++;
        },
      );
      addTearDown(controller.dispose);

      final Future<void> firstOpen = controller.open();
      await _completeNext(gateway, _page(score: 300));
      await firstOpen;
      await controller.open();

      expect(openRetries, 1);
      expect(gateway.authenticateCalls, 0);
    },
  );

  test(
    'auth-required and submission summary are explicit view state',
    () async {
      final LeaderboardRepository unauthenticated = LeaderboardRepository(
        gateway: gateway,
        store: store,
        identityHasher: hasher,
      );
      final LeaderboardController controller = LeaderboardController(
        unauthenticated,
        arenaId: 12,
        submissionSummary: SubmissionSummary(
          scores: const <PendingScore>[
            PendingScore(
              identityHash: 'hash',
              platform: GameServicePlatform.gameCenter,
              arenaId: 12,
              score: 800,
            ),
          ],
        ),
      );
      addTearDown(controller.dispose);

      await controller.load();
      expect(controller.state.status, LeaderboardViewStatus.authPrompt);
      expect(controller.state.submissionSummary.pendingCount, 1);
      expect(controller.state.arenaSubmission!.score, 800);
      expect(gateway.authenticateCalls, 0);
    },
  );

  test('account event synchronously removes the open account page', () async {
    final LeaderboardController controller = LeaderboardController(
      repository,
      arenaId: 12,
    );
    addTearDown(controller.dispose);
    final Future<void> initial = controller.load();
    await _completeNext(gateway, _page(score: 1200));
    await initial;
    expect(controller.state.page, isNotNull);

    repository.handleIdentityEvent(
      const PlatformIdentityEvent.accountChanged(epoch: 2, identity: identityB),
    );

    expect(controller.state.page, isNull);
    expect(controller.state.snapshot, isNull);
    expect(controller.state.status, LeaderboardViewStatus.authPrompt);
    expect(controller.state.submissionSummary.scores, isEmpty);

    repository.handleIdentityEvent(
      const PlatformIdentityEvent.authenticated(identity: identityB, epoch: 3),
    );
    expect(controller.state.page, isNull);
    expect(controller.state.status, LeaderboardViewStatus.loading);
    await _completeNext(gateway, _page(score: 2200));
    await _pumpUntil(
      () => controller.state.status == LeaderboardViewStatus.loaded,
    );
    expect(controller.state.page!.leaders.single.score, 2200);
    expect(gateway.identities.last, identityB);
  });

  test(
    'auth starts one board read without waiting for delayed submissions',
    () async {
      final LeaderboardRepository unauthenticated = LeaderboardRepository(
        gateway: gateway,
        store: store,
        identityHasher: hasher,
      );
      gateway.authenticatedIdentity = identity;
      final Completer<void> delayedSubmissions = Completer<void>();
      final LeaderboardController controller = LeaderboardController(
        unauthenticated,
        arenaId: 14,
        onAuthenticated: () => delayedSubmissions.future,
      );

      final Future<bool> first = controller.authenticateFromUserAction();
      final Future<bool> duplicate = controller.authenticateFromUserAction();
      await _pumpUntil(
        () => gateway.pending.where((item) => !item.isCompleted).length == 1,
      );
      expect(gateway.authenticateCalls, 1);
      expect(gateway.calls, <(int, LeaderboardScope)>[
        (14, LeaderboardScope.global),
      ]);

      await _completeNext(gateway, _page(score: 3100));
      expect(await first.timeout(const Duration(seconds: 1)), isTrue);
      expect(await duplicate.timeout(const Duration(seconds: 1)), isTrue);
      expect(delayedSubmissions.isCompleted, isFalse);
      expect(controller.state.status, LeaderboardViewStatus.loaded);
      expect(controller.state.page!.leaders.single.score, 3100);

      controller.dispose();
      delayedSubmissions.complete();
      await pumpEventQueue();
    },
  );
}

LeaderboardPage _page({required int score}) => LeaderboardPage(
  leaders: <LeaderboardEntry>[
    LeaderboardEntry(
      rank: 1,
      playerId: 'leader',
      displayName: 'Leader',
      score: score,
      isCurrentPlayer: false,
    ),
  ],
);

Future<void> _completeNext(_ReadGateway gateway, LeaderboardPage page) async {
  await _pumpUntil(
    () => gateway.pending.any(
      (Completer<LeaderboardPage> item) => !item.isCompleted,
    ),
  );
  gateway.pending
      .lastWhere((Completer<LeaderboardPage> item) => !item.isCompleted)
      .complete(page);
}

Future<void> _failNext(_ReadGateway gateway, Object error) async {
  await _pumpUntil(
    () => gateway.pending.any(
      (Completer<LeaderboardPage> item) => !item.isCompleted,
    ),
  );
  gateway.pending
      .lastWhere((Completer<LeaderboardPage> item) => !item.isCompleted)
      .completeError(error);
}

Future<void> _pumpUntil(bool Function() condition) async {
  for (int index = 0; index < 100 && !condition(); index++) {
    await Future<void>.delayed(Duration.zero);
  }
  expect(condition(), isTrue);
}

class _ReadGateway implements GameServicesGateway {
  final StreamController<PlatformIdentityEvent> events =
      StreamController<PlatformIdentityEvent>.broadcast();
  final List<(int, LeaderboardScope)> calls = <(int, LeaderboardScope)>[];
  final List<Completer<LeaderboardPage>> pending =
      <Completer<LeaderboardPage>>[];
  int authenticateCalls = 0;
  PlatformIdentity? authenticatedIdentity;
  final List<PlatformIdentity> identities = <PlatformIdentity>[];

  @override
  Future<LeaderboardPage> loadLeaderboard({
    required PlatformIdentity identity,
    required int arenaId,
    required LeaderboardScope scope,
    required int limit,
  }) {
    calls.add((arenaId, scope));
    identities.add(identity);
    final Completer<LeaderboardPage> result = Completer<LeaderboardPage>();
    pending.add(result);
    return result.future;
  }

  @override
  Future<PlatformIdentity> authenticate({required bool interactive}) async {
    authenticateCalls++;
    return authenticatedIdentity ??
        (throw const GameServicesException(
          GameServicesFailureCode.unauthenticated,
        ));
  }

  @override
  Stream<PlatformIdentityEvent> get identityEvents => events.stream;

  @override
  Future<Uint8List?> loadAvatar({
    required PlatformIdentity identity,
    required PlatformAvatarRef avatar,
  }) async => null;

  @override
  Future<PlatformIdentity?> restoreIdentity() async => null;

  @override
  Future<void> submitScore({
    required PlatformIdentity identity,
    required int arenaId,
    required int score,
  }) async {}

  @override
  Future<void> validateConfiguration() async {}
}
