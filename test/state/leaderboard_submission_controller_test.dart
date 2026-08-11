import 'dart:async';
import 'dart:typed_data';

import 'package:ban_bua_tuong/data/game_services_gateway.dart';
import 'package:ban_bua_tuong/data/identity_hasher.dart';
import 'package:ban_bua_tuong/data/leaderboard_repository.dart';
import 'package:ban_bua_tuong/data/local_leaderboard_store.dart';
import 'package:ban_bua_tuong/domain/leaderboard_models.dart';
import 'package:ban_bua_tuong/domain/player_progress.dart';
import 'package:ban_bua_tuong/state/leaderboard_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const PlatformIdentity identity = PlatformIdentity(
    platform: GameServicePlatform.gameCenter,
    playerId: 'platform-player-a',
    displayName: 'Player A',
    sessionToken: 'session-a',
  );

  late SharedPreferences prefs;
  late LocalLeaderboardStore store;
  late IdentityHasher hasher;
  late _SubmissionGateway gateway;
  late LeaderboardRepository repository;
  late LeaderboardSubmissionController controller;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
    store = LocalLeaderboardStore(prefs);
    hasher = IdentityHasher(prefs);
    gateway = _SubmissionGateway();
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
    controller = LeaderboardSubmissionController(repository);
  });

  test(
    'first auth backfills eligible history once for this identity',
    () async {
      final PlayerProgress progress = PlayerProgress(
        results: <int, LevelResult>{
          1: const LevelResult(stars: 2, highScore: 700),
          2: const LevelResult(skipped: true, highScore: 800),
          3: const LevelResult(losses: 4),
          4: const LevelResult(stars: 1, highScore: 0),
          5: const LevelResult(stars: 3, highScore: 900),
        },
      );
      gateway.submitFailure = const GameServicesException(
        GameServicesFailureCode.retryable,
      );

      await controller.onAuthenticated(progress, progressConfirmed: true);
      await controller.onAuthenticated(progress, progressConfirmed: true);
      await _pumpUntil(
        () =>
            gateway.submitCalls.length == 2 &&
            controller.state.pendingCount == 2,
      );

      expect(gateway.authenticateCalls, 0);
      expect(gateway.submitCalls, <(int, int)>[(1, 700), (1, 700)]);
      expect(controller.state.pendingCount, 2);
      expect(
        controller.state.scores.map((PendingScore item) => item.arenaId),
        <int>[1, 5],
      );
      final IdentityKey key = IdentityKey(
        platform: identity.platform,
        identityHash: hasher.hashPlayerId(identity.playerId),
      );
      expect(await store.hasCompletedInitialBackfill(key), isTrue);
    },
  );

  test(
    'persisted wins enqueue only a new high score and triggers do not duplicate',
    () async {
      final PlayerProgress progress = const PlayerProgress().withResult(
        1,
        2,
        700,
      );
      gateway.submitFailure = const GameServicesException(
        GameServicesFailureCode.retryable,
      );
      final RecordOutcome newRecord = RecordOutcome(
        persisted: true,
        arenaId: 1,
        attemptedScore: 700,
        previousBest: 500,
        currentBest: 700,
        completedByWin: true,
        persistedProgress: progress,
      );

      await controller.onPersistedWin(newRecord);
      await controller.onLeaderboardOpened();
      await controller.onAppResumed();

      expect(controller.state.scores, hasLength(1));
      expect(controller.state.forArena(1)!.score, 700);
      expect(gateway.authenticateCalls, 0);

      await controller.onPersistedWin(
        RecordOutcome(
          persisted: true,
          arenaId: 1,
          attemptedScore: 700,
          previousBest: 700,
          currentBest: 700,
          completedByWin: true,
          persistedProgress: progress,
        ),
      );
      expect(controller.state.scores, hasLength(1));
    },
  );

  test('a win is never queued before its local save succeeds', () async {
    final PlayerProgress committed = const PlayerProgress().withResult(
      1,
      1,
      500,
    );
    final PlayerProgress candidate = committed.withResult(1, 2, 700);
    gateway.submitFailure = const GameServicesException(
      GameServicesFailureCode.retryable,
    );

    await controller.onPersistedWin(
      RecordOutcome(
        persisted: false,
        arenaId: 1,
        attemptedScore: 700,
        previousBest: 500,
        currentBest: 500,
        completedByWin: true,
        persistedProgress: committed,
      ),
    );
    expect(controller.state.scores, isEmpty);
    expect(gateway.submitCalls, isEmpty);
    expect(
      controller.state.receiptForArena(1, score: 700)?.status,
      SubmissionAttemptStatus.persistFailed,
    );
    expect(
      controller.state.receiptForArena(1, score: 700)?.reasonCode,
      'progress_write_failed',
    );

    await controller.onPersistedWin(
      RecordOutcome(
        persisted: true,
        arenaId: 1,
        attemptedScore: 700,
        previousBest: 500,
        currentBest: 700,
        completedByWin: true,
        persistedProgress: candidate,
      ),
    );
    expect(controller.state.forArena(1)!.score, 700);
    expect(candidate.highScoreFor(1), 700);
    expect(candidate.coins, greaterThan(committed.coins));
  });

  test(
    'queue persistence failure is explicit and never reported sent',
    () async {
      final LocalLeaderboardStore failingStore = _FailingQueueStore(prefs);
      final LeaderboardSubmissionController failingController =
          LeaderboardSubmissionController(
            LeaderboardRepository(
              gateway: gateway,
              store: failingStore,
              identityHasher: hasher,
              initialIdentityState: const PlatformIdentityState(
                confidence: IdentityConfidence.confirmedCurrent,
                epoch: 1,
                identity: identity,
              ),
            ),
          );
      final PlayerProgress progress = const PlayerProgress().withResult(
        1,
        1,
        500,
      );

      await failingController.onPersistedWin(
        RecordOutcome(
          persisted: true,
          arenaId: 1,
          attemptedScore: 500,
          previousBest: 0,
          currentBest: 500,
          completedByWin: true,
          persistedProgress: progress,
        ),
      );

      expect(failingController.state.scores, isEmpty);
      expect(gateway.submitCalls, isEmpty);
      expect(
        failingController.state.receiptForArena(1, score: 500),
        const SubmissionReceipt(
          arenaId: 1,
          score: 500,
          status: SubmissionAttemptStatus.persistFailed,
          reasonCode: 'queue_write_failed',
        ),
      );
    },
  );

  test('non-record and platform acceptance have distinct receipts', () async {
    final PlayerProgress progress = const PlayerProgress().withResult(
      1,
      1,
      500,
    );

    await controller.onPersistedWin(
      RecordOutcome(
        persisted: true,
        arenaId: 1,
        attemptedScore: 400,
        previousBest: 500,
        currentBest: 500,
        completedByWin: true,
        persistedProgress: progress,
      ),
    );
    expect(
      controller.state.receiptForArena(1, score: 400)?.status,
      SubmissionAttemptStatus.notQueued,
    );
    expect(gateway.submitCalls, isEmpty);

    await controller.onPersistedWin(
      RecordOutcome(
        persisted: true,
        arenaId: 1,
        attemptedScore: 500,
        previousBest: 0,
        currentBest: 500,
        completedByWin: true,
        persistedProgress: progress,
      ),
    );
    await _pumpUntil(
      () =>
          controller.state.receiptForArena(1, score: 500)?.status ==
          SubmissionAttemptStatus.accepted,
    );

    expect(controller.state.scores, isEmpty);
    expect(gateway.submitCalls, <(int, int)>[(1, 500)]);
  });

  test('manual retry is required after a permanent rejection', () async {
    final PlayerProgress progress = const PlayerProgress().withResult(
      1,
      2,
      700,
    );
    gateway.submitFailure = const GameServicesException(
      GameServicesFailureCode.permanent,
    );
    await controller.onPersistedWin(
      RecordOutcome(
        persisted: true,
        arenaId: 1,
        attemptedScore: 700,
        previousBest: 0,
        currentBest: 700,
        completedByWin: true,
        persistedProgress: progress,
      ),
    );
    await _pumpUntil(() => controller.state.permanentlyFailedCount == 1);

    expect(controller.state.permanentlyFailedCount, 1);
    expect(controller.state.forArena(1)!.reasonCode, 'permanent');
    final int callsAfterFailure = gateway.submitCalls.length;
    gateway.submitFailure = null;
    await controller.onAppResumed();
    expect(gateway.submitCalls, hasLength(callsAfterFailure));

    await controller.retryFailed(1);
    expect(controller.state.scores, isEmpty);
    expect(gateway.submitCalls, hasLength(callsAfterFailure + 1));
  });

  test(
    'revoked auth retains durable queue but invalidates old UI state',
    () async {
      final PlayerProgress progress = const PlayerProgress().withResult(
        1,
        2,
        700,
      );
      gateway.submitFailure = const GameServicesException(
        GameServicesFailureCode.unauthenticated,
      );
      await controller.onPersistedWin(
        RecordOutcome(
          persisted: true,
          arenaId: 1,
          attemptedScore: 700,
          previousBest: 0,
          currentBest: 700,
          completedByWin: true,
          persistedProgress: progress,
        ),
      );
      await controller.onAppResumed();
      await controller.onLeaderboardOpened();

      final IdentityKey key = IdentityKey(
        platform: identity.platform,
        identityHash: hasher.hashPlayerId(identity.playerId),
      );
      expect(controller.state.scores, isEmpty);
      expect((await store.loadSubmissions(key)).single.score, 700);
      expect(repository.identityState.maySubmit, isFalse);
      expect(repository.identityState.confidence, IdentityConfidence.changed);
      expect(repository.identityState.identity, isNull);
      expect(gateway.authenticateCalls, 0);
    },
  );

  test('overlapping automatic triggers share one serialized flush', () async {
    await hasher.initialize();
    final IdentityKey key = IdentityKey(
      platform: identity.platform,
      identityHash: hasher.hashPlayerId(identity.playerId),
    );
    await store.upsertHighest(
      PendingScore(
        identityHash: key.identityHash,
        platform: key.platform,
        arenaId: 1,
        score: 700,
      ),
    );
    await store.upsertHighest(
      PendingScore(
        identityHash: key.identityHash,
        platform: key.platform,
        arenaId: 2,
        score: 900,
      ),
    );
    gateway.submitGate = Completer<void>();

    final Future<void> resume = controller.onAppResumed();
    final Future<void> open = controller.onLeaderboardOpened();
    await _pumpUntil(() => gateway.activeSubmissions == 1);
    expect(gateway.maximumConcurrentSubmissions, 1);
    gateway.submitGate!.complete();
    await Future.wait(<Future<void>>[resume, open]);

    expect(gateway.maximumConcurrentSubmissions, 1);
    expect(gateway.submitCalls, <(int, int)>[(1, 700), (2, 900)]);
    expect(controller.state.scores, isEmpty);
  });
}

Future<void> _pumpUntil(bool Function() condition) async {
  for (int index = 0; index < 100 && !condition(); index++) {
    await Future<void>.delayed(Duration.zero);
  }
  expect(condition(), isTrue);
}

class _SubmissionGateway implements GameServicesGateway {
  final StreamController<PlatformIdentityEvent> events =
      StreamController<PlatformIdentityEvent>.broadcast();
  final List<(int, int)> submitCalls = <(int, int)>[];
  GameServicesException? submitFailure;
  Completer<void>? submitGate;
  int authenticateCalls = 0;
  int activeSubmissions = 0;
  int maximumConcurrentSubmissions = 0;

  @override
  Future<void> submitScore({
    required PlatformIdentity identity,
    required int arenaId,
    required int score,
  }) async {
    submitCalls.add((arenaId, score));
    activeSubmissions++;
    if (activeSubmissions > maximumConcurrentSubmissions) {
      maximumConcurrentSubmissions = activeSubmissions;
    }
    try {
      await submitGate?.future;
      if (submitFailure != null) throw submitFailure!;
    } finally {
      activeSubmissions--;
    }
  }

  @override
  Future<PlatformIdentity> authenticate({required bool interactive}) async {
    authenticateCalls++;
    throw const GameServicesException(GameServicesFailureCode.unauthenticated);
  }

  @override
  Future<PlatformIdentity?> restoreIdentity() async => null;

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
  }) async => null;

  @override
  Stream<PlatformIdentityEvent> get identityEvents => events.stream;

  @override
  Future<void> validateConfiguration() async {}
}

class _FailingQueueStore extends LocalLeaderboardStore {
  _FailingQueueStore(super.preferences);

  @override
  Future<void> upsertHighest(PendingScore score) async {
    throw StateError('simulated durable queue failure');
  }
}
