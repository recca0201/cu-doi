import 'dart:async';
import 'dart:typed_data';

import 'package:ban_bua_tuong/data/game_services_gateway.dart';
import 'package:ban_bua_tuong/data/identity_hasher.dart';
import 'package:ban_bua_tuong/data/leaderboard_repository.dart';
import 'package:ban_bua_tuong/data/local_leaderboard_store.dart';
import 'package:ban_bua_tuong/domain/leaderboard_models.dart';
import 'package:ban_bua_tuong/domain/player_progress.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const PlatformIdentity playerA = PlatformIdentity(
    platform: GameServicePlatform.playGames,
    playerId: 'player-a',
    displayName: 'A',
    sessionToken: 'session-a',
  );
  const PlatformIdentity playerB = PlatformIdentity(
    platform: GameServicePlatform.playGames,
    playerId: 'player-b',
    displayName: 'B',
    sessionToken: 'session-b',
  );

  late SharedPreferences prefs;
  late LocalLeaderboardStore store;
  late IdentityHasher hasher;
  late _Gateway gateway;

  LeaderboardRepository repository(PlatformIdentity identity, int epoch) =>
      LeaderboardRepository(
        gateway: gateway,
        store: store,
        identityHasher: hasher,
        initialIdentityState: PlatformIdentityState(
          confidence: IdentityConfidence.confirmedCurrent,
          epoch: epoch,
          identity: identity,
        ),
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
    store = LocalLeaderboardStore(prefs);
    hasher = IdentityHasher(prefs);
    gateway = _Gateway();
  });

  test(
    'backfill is capped at 20, durable, identity-scoped and highest-only',
    () async {
      final Map<int, LevelResult> results = <int, LevelResult>{
        for (int arenaId = 1; arenaId <= 20; arenaId++)
          arenaId: const LevelResult(stars: 1, highScore: 100),
        21: const LevelResult(stars: 3, highScore: 9999),
      };
      final PlayerProgress progress = PlayerProgress(results: results);
      final LeaderboardRepository first = repository(playerA, 1);

      await first.enqueueEligibleHistory(progress, progressConfirmed: true);
      await first.enqueueEligibleHistory(progress, progressConfirmed: true);
      await hasher.initialize();
      final IdentityKey keyA = IdentityKey(
        platform: playerA.platform,
        identityHash: hasher.hashPlayerId(playerA.playerId),
      );
      expect(await store.loadSubmissions(keyA), hasLength(20));
      expect(await store.hasCompletedInitialBackfill(keyA), isTrue);

      final LeaderboardRepository second = repository(playerB, 2);
      await second.enqueueEligibleHistory(
        const PlayerProgress().withResult(1, 1, 200),
        progressConfirmed: true,
      );
      final IdentityKey keyB = IdentityKey(
        platform: playerB.platform,
        identityHash: hasher.hashPlayerId(playerB.playerId),
      );
      expect(await store.loadSubmissions(keyA), hasLength(20));
      expect((await store.loadSubmissions(keyB)).single.score, 200);
    },
  );

  test(
    'unconfirmed default progress never writes the backfill marker',
    () async {
      final LeaderboardRepository repo = repository(playerA, 1);

      await repo.enqueueEligibleHistory(
        const PlayerProgress(),
        progressConfirmed: false,
      );
      await hasher.initialize();
      final IdentityKey key = IdentityKey(
        platform: playerA.platform,
        identityHash: hasher.hashPlayerId(playerA.playerId),
      );

      expect(await store.hasCompletedInitialBackfill(key), isFalse);
      expect(await store.loadSubmissions(key), isEmpty);
    },
  );

  test(
    'new high score requires exact persisted progress and replaces lower pending',
    () async {
      final LeaderboardRepository repo = repository(playerA, 1);
      final PlayerProgress first = const PlayerProgress().withResult(1, 1, 500);
      await repo.enqueueNewHighScore(arenaId: 1, score: 500, progress: first);
      await repo.enqueueNewHighScore(arenaId: 1, score: 400, progress: first);
      final PlayerProgress higher = first.withResult(1, 2, 700);
      await repo.enqueueNewHighScore(arenaId: 1, score: 700, progress: higher);
      await hasher.initialize();
      final IdentityKey key = IdentityKey(
        platform: playerA.platform,
        identityHash: hasher.hashPlayerId(playerA.playerId),
      );

      expect(await store.loadSubmissions(key), <PendingScore>[
        PendingScore(
          identityHash: key.identityHash,
          platform: key.platform,
          arenaId: 1,
          score: 700,
        ),
      ]);
    },
  );

  test(
    'accepted scores are removed; retryable scores survive restart',
    () async {
      final LeaderboardRepository first = repository(playerA, 1);
      final PlayerProgress progress = const PlayerProgress()
          .withResult(1, 1, 500)
          .withResult(2, 1, 600);
      await first.enqueueEligibleHistory(progress, progressConfirmed: true);
      gateway.outcomes.add(null);
      gateway.outcomes.add(
        const GameServicesException(GameServicesFailureCode.retryable),
      );

      final SubmissionSummary firstSummary = await first
          .flushEligibleSubmissions();
      expect(firstSummary.pendingCount, 1);
      expect(firstSummary.forArena(2)!.score, 600);

      final LeaderboardRepository restarted = repository(playerA, 1);
      final SubmissionSummary restartedSummary = await restarted
          .flushEligibleSubmissions();
      expect(restartedSummary.scores, isEmpty);
      expect(gateway.calls, <(int, int)>[(1, 500), (2, 600), (2, 600)]);
      expect(gateway.identities, everyElement(playerA));
    },
  );

  test(
    'durable remove failure retains pending and never reports accepted',
    () async {
      final LeaderboardRepository enqueueing = repository(playerA, 1);
      final PlayerProgress progress = const PlayerProgress().withResult(
        1,
        1,
        500,
      );
      await enqueueing.enqueueEligibleHistory(
        progress,
        progressConfirmed: true,
      );
      await hasher.initialize();
      final IdentityKey key = IdentityKey(
        platform: playerA.platform,
        identityHash: hasher.hashPlayerId(playerA.playerId),
      );
      final _RetainingRemovePreferences retainingPreferences =
          _RetainingRemovePreferences(prefs);
      store = LocalLeaderboardStore(retainingPreferences);
      final LeaderboardRepository flushing = repository(playerA, 1);

      final SubmissionSummary summary = await flushing
          .flushEligibleSubmissions();

      expect(gateway.calls, <(int, int)>[(1, 500)]);
      expect(retainingPreferences.removeCalls, 1);
      expect(summary.pendingCount, 1);
      expect(summary.forArena(1)!.score, 500);
      expect(summary.receiptForArena(1, score: 500), isNull);
      expect(
        await LocalLeaderboardStore(prefs).loadSubmissions(key),
        hasLength(1),
      );
    },
  );

  test(
    'backfill preserves equal permanently-failed score until manual retry',
    () async {
      final LeaderboardRepository repo = repository(playerA, 1);
      final PlayerProgress progress = const PlayerProgress().withResult(
        1,
        1,
        500,
      );
      await hasher.initialize();
      final IdentityKey key = IdentityKey(
        platform: playerA.platform,
        identityHash: hasher.hashPlayerId(playerA.playerId),
      );
      final PendingScore rejected = PendingScore(
        identityHash: key.identityHash,
        platform: key.platform,
        arenaId: 1,
        score: 500,
      );
      await store.upsertHighest(rejected);
      await store.markPermanentlyFailed(rejected, 'score_rejected');

      await repo.enqueueEligibleHistory(progress, progressConfirmed: true);

      PendingScore loaded = (await store.loadSubmissions(key)).single;
      expect(loaded.state, SubmissionState.permanentlyFailed);
      expect(loaded.reasonCode, 'score_rejected');

      await repo.retryFailedManually(1);
      loaded = (await store.loadSubmissions(key)).single;
      expect(loaded.state, SubmissionState.pending);
      expect(loaded.reasonCode, isNull);
    },
  );

  test(
    'identity change during submission cannot mutate the old queue response',
    () async {
      final LeaderboardRepository repo = repository(playerA, 4);
      final PlayerProgress progress = const PlayerProgress().withResult(
        1,
        1,
        500,
      );
      await repo.enqueueEligibleHistory(progress, progressConfirmed: true);
      gateway.gate = Completer<void>();

      final Future<SubmissionSummary> flush = repo.flushEligibleSubmissions();
      await _pumpUntil(() => gateway.calls.isNotEmpty);
      repo.handleIdentityEvent(
        const PlatformIdentityEvent.accountChanged(epoch: 5, identity: playerB),
      );
      gateway.gate!.complete();
      await flush;
      final IdentityKey keyA = IdentityKey(
        platform: playerA.platform,
        identityHash: hasher.hashPlayerId(playerA.playerId),
      );

      expect((await store.loadSubmissions(keyA)).single.score, 500);
      expect(repo.identityState.confidence, IdentityConfidence.changed);
    },
  );
}

Future<void> _pumpUntil(bool Function() condition) async {
  for (int index = 0; index < 100 && !condition(); index++) {
    await Future<void>.delayed(Duration.zero);
  }
  expect(condition(), isTrue);
}

class _Gateway implements GameServicesGateway {
  final StreamController<PlatformIdentityEvent> events =
      StreamController<PlatformIdentityEvent>.broadcast();
  final List<(int, int)> calls = <(int, int)>[];
  final List<PlatformIdentity> identities = <PlatformIdentity>[];
  final List<GameServicesException?> outcomes = <GameServicesException?>[];
  Completer<void>? gate;

  @override
  Future<void> submitScore({
    required PlatformIdentity identity,
    required int arenaId,
    required int score,
  }) async {
    calls.add((arenaId, score));
    identities.add(identity);
    await gate?.future;
    if (outcomes.isNotEmpty) {
      final GameServicesException? outcome = outcomes.removeAt(0);
      if (outcome != null) throw outcome;
    }
  }

  @override
  Future<PlatformIdentity?> restoreIdentity() async => null;

  @override
  Future<PlatformIdentity> authenticate({required bool interactive}) async =>
      throw const GameServicesException(
        GameServicesFailureCode.unauthenticated,
      );

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

class _RetainingRemovePreferences implements SharedPreferences {
  _RetainingRemovePreferences(this._delegate);

  final SharedPreferences _delegate;
  int removeCalls = 0;

  @override
  bool containsKey(String key) => _delegate.containsKey(key);

  @override
  Object? get(String key) => _delegate.get(key);

  @override
  Set<String> getKeys() => _delegate.getKeys();

  @override
  String? getString(String key) => _delegate.getString(key);

  @override
  Future<bool> remove(String key) async {
    removeCalls++;
    return false;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
