import 'dart:async';

import 'package:ban_bua_tuong/data/identity_hasher.dart';
import 'package:ban_bua_tuong/data/leaderboard_repository.dart';
import 'package:ban_bua_tuong/data/local_leaderboard_store.dart';
import 'package:ban_bua_tuong/data/progress_repository.dart';
import 'package:ban_bua_tuong/domain/economy.dart';
import 'package:ban_bua_tuong/domain/leaderboard_models.dart';
import 'package:ban_bua_tuong/domain/player_progress.dart';
import 'package:ban_bua_tuong/state/leaderboard_controller.dart';
import 'package:ban_bua_tuong/state/providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_game_services_gateway.dart';

class _Repo implements ProgressRepository {
  _Repo(this.value, {this.gate, this.loadGate});
  PlayerProgress value;
  bool writeSucceeds = true;
  Completer<void>? gate;
  Completer<void>? loadGate;
  int saves = 0;

  @override
  Future<PlayerProgress> load() async {
    await loadGate?.future;
    return value;
  }

  @override
  Future<bool> save(PlayerProgress progress) async {
    saves++;
    await gate?.future;
    if (writeSucceeds) value = progress;
    return writeSucceeds;
  }
}

Future<ProgressController> _controller(_Repo repo) async {
  final ProgressController controller = ProgressController(repo);
  await Future<void>.delayed(Duration.zero);
  return controller;
}

void main() {
  test(
    'readiness stays pending and unconfirmed until restore completes',
    () async {
      final Completer<void> loadGate = Completer<void>();
      final PlayerProgress restored = const PlayerProgress().withResult(
        2,
        1,
        640,
      );
      final ProgressController controller = ProgressController(
        _Repo(restored, loadGate: loadGate),
      );

      expect(controller.isReady, isFalse);
      expect(controller.hasConfirmedSnapshot, isFalse);
      expect(controller.state.results, isEmpty);

      loadGate.complete();
      await controller.ready;

      expect(controller.isReady, isTrue);
      expect(controller.hasConfirmedSnapshot, isTrue);
      expect(controller.state.highScoreFor(2), 640);
    },
  );

  test('record returns the exact persisted post-save snapshot', () async {
    final PlayerProgress initial = const PlayerProgress().withResult(3, 1, 500);
    final _Repo repo = _Repo(initial);
    final ProgressController controller = await _controller(repo);

    final RecordOutcome outcome = await controller.record(3, 2, 900);

    expect(outcome.persisted, isTrue);
    expect(outcome.arenaId, 3);
    expect(outcome.previousBest, 500);
    expect(outcome.currentBest, 900);
    expect(outcome.completedByWin, isTrue);
    expect(outcome.isNewRecord, isTrue);
    expect(identical(outcome.persistedProgress, repo.value), isTrue);
    expect(identical(outcome.persistedProgress, controller.state), isTrue);
  });

  test('record reports no new record until its save succeeds', () async {
    final PlayerProgress initial = const PlayerProgress().withResult(3, 1, 500);
    final _Repo repo = _Repo(initial)..writeSucceeds = false;
    final ProgressController controller = await _controller(repo);

    final RecordOutcome failed = await controller.record(3, 2, 900);

    expect(failed.persisted, isFalse);
    expect(failed.previousBest, 500);
    expect(failed.currentBest, 500);
    expect(failed.isNewRecord, isFalse);
    expect(identical(failed.persistedProgress, initial), isTrue);
    expect(identical(controller.state, initial), isTrue);

    repo.writeSucceeds = true;
    final RecordOutcome persisted = await controller.record(3, 2, 900);
    expect(persisted.persisted, isTrue);
    expect(persisted.previousBest, 500);
    expect(persisted.currentBest, 900);
    expect(persisted.isNewRecord, isTrue);
  });

  test('equal or lower winning scores do not report a new record', () async {
    final PlayerProgress initial = const PlayerProgress().withResult(3, 1, 900);
    final _Repo repo = _Repo(initial);
    final ProgressController controller = await _controller(repo);

    final RecordOutcome equal = await controller.record(3, 2, 900);
    final RecordOutcome lower = await controller.record(3, 3, 700);

    expect(equal.persisted, isTrue);
    expect(equal.isNewRecord, isFalse);
    expect(lower.persisted, isTrue);
    expect(lower.isNewRecord, isFalse);
    expect(lower.currentBest, 900);
  });

  test('an accepted platform score never mutates local progress', () async {
    final _Repo progressRepository = _Repo(const PlayerProgress());
    final ProgressController progress = await _controller(progressRepository);
    final RecordOutcome outcome = await progress.record(1, 2, 500);
    final PlayerProgress committed = progress.state;
    final int committedCoins = committed.coins;

    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final FakeGameServicesGateway gateway = FakeGameServicesGateway();
    addTearDown(gateway.dispose);
    const PlatformIdentity identity = PlatformIdentity(
      platform: GameServicePlatform.playGames,
      playerId: 'platform-player',
      displayName: 'Platform Player',
      sessionToken: 'session-player',
    );
    final LeaderboardRepository leaderboard = LeaderboardRepository(
      gateway: gateway,
      store: LocalLeaderboardStore(preferences),
      identityHasher: IdentityHasher(preferences),
      initialIdentityState: const PlatformIdentityState(
        confidence: IdentityConfidence.confirmedCurrent,
        epoch: 1,
        identity: identity,
      ),
    );
    final LeaderboardSubmissionController submissions =
        LeaderboardSubmissionController(leaderboard);

    await submissions.onPersistedWin(outcome);
    await pumpEventQueue();

    expect(gateway.submitCalls, <({int arenaId, int score})>[
      (arenaId: 1, score: 500),
    ]);
    expect(submissions.state.scores, isEmpty);
    expect(
      submissions.state.receiptForArena(1, score: 500)?.status,
      SubmissionAttemptStatus.accepted,
    );
    expect(progressRepository.saves, 1);
    expect(identical(progress.state, committed), isTrue);
    expect(progress.state.highScoreFor(1), 500);
    expect(progress.state.starsFor(1), 2);
    expect(progress.state.coins, committedCoins);
  });

  test('paid operations commit only after a successful write', () async {
    final _Repo repo = _Repo(const PlayerProgress(coins: 200));
    final ProgressController controller = await _controller(repo);
    expect(await controller.spendOnHint(), SpendResult.ok);
    expect(controller.state.coins, 150);

    repo.writeSucceeds = false;
    expect(await controller.skipArena(2), SpendResult.writeFailed);
    expect(controller.state.coins, 150);
    expect(controller.state.isSkipped(2), isFalse);

    final _Repo poorRepo = _Repo(const PlayerProgress(coins: 20));
    final ProgressController poor = await _controller(poorRepo);
    expect(await poor.spendOnHint(), SpendResult.insufficientCoins);
    expect(poorRepo.saves, 0);
  });

  test('the spending lock rejects overlapping transactions', () async {
    final Completer<void> gate = Completer<void>();
    final _Repo repo = _Repo(const PlayerProgress(coins: 500), gate: gate);
    final ProgressController controller = await _controller(repo);
    final Future<SpendResult> first = controller.spendOnHint();
    final Future<SpendResult> second = controller.spendOnHint();
    expect(await second, SpendResult.writeFailed);
    gate.complete();
    expect(await first, SpendResult.ok);
    expect(controller.state.coins, 450);
  });

  test('losses persist, skip resets them, and reset clears all', () async {
    final _Repo repo = _Repo(const PlayerProgress(coins: 500));
    final ProgressController controller = await _controller(repo);
    await controller.recordLoss(4);
    await controller.recordLoss(4);
    expect(controller.state.lossesFor(4), 2);
    expect((await _controller(_Repo(repo.value))).state.lossesFor(4), 2);
    expect(await controller.skipArena(4), SpendResult.ok);
    expect(controller.state.lossesFor(4), 0);
    await controller.reset();
    expect(controller.state.results, isEmpty);
  });
}
