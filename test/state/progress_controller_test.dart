import 'dart:async';

import 'package:ban_bua_tuong/data/progress_repository.dart';
import 'package:ban_bua_tuong/domain/economy.dart';
import 'package:ban_bua_tuong/domain/player_progress.dart';
import 'package:ban_bua_tuong/state/providers.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repo implements ProgressRepository {
  _Repo(this.value, {this.gate});
  PlayerProgress value;
  bool writeSucceeds = true;
  Completer<void>? gate;
  int saves = 0;

  @override
  Future<PlayerProgress> load() async => value;

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
