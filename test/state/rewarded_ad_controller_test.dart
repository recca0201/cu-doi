import 'dart:async';

import 'package:ban_bua_tuong/core/rewarded_ad_service.dart';
import 'package:ban_bua_tuong/domain/economy.dart';
import 'package:ban_bua_tuong/state/rewarded_ad_controller.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FakeRewardedAdService implements RewardedAdService {
  RewardedAdOutcome outcome = RewardedAdOutcome.earned;
  Completer<RewardedAdOutcome>? gate;
  int calls = 0;

  @override
  Future<RewardedAdOutcome> show() async {
    calls++;
    return gate == null ? outcome : gate!.future;
  }
}

void main() {
  test('completed ad grants exactly one hint worth of coins', () async {
    final _FakeRewardedAdService ads = _FakeRewardedAdService();
    final List<int> grants = <int>[];
    final RewardedAdController controller = RewardedAdController(ads, (
      int amount,
    ) async {
      grants.add(amount);
      return true;
    });

    await controller.show();

    expect(grants, <int>[kHintCost]);
    expect(kRewardedAdCoins, kHintCost);
    expect(controller.state.status, RewardedAdStatus.earned);
  });

  test('dismissed or unavailable ad never grants coins', () async {
    final _FakeRewardedAdService ads = _FakeRewardedAdService();
    int grants = 0;
    final RewardedAdController controller = RewardedAdController(ads, (
      int _,
    ) async {
      grants++;
      return true;
    });

    ads.outcome = RewardedAdOutcome.dismissed;
    await controller.show();
    expect(controller.state.status, RewardedAdStatus.dismissed);

    ads.outcome = RewardedAdOutcome.unavailable;
    await controller.show();
    expect(controller.state.status, RewardedAdStatus.unavailable);
    expect(grants, 0);
  });

  test('parallel taps share the loading lock', () async {
    final _FakeRewardedAdService ads = _FakeRewardedAdService()
      ..gate = Completer<RewardedAdOutcome>();
    final RewardedAdController controller = RewardedAdController(
      ads,
      (int _) async => true,
    );

    final Future<void> first = controller.show();
    await controller.show();
    expect(ads.calls, 1);
    expect(controller.state.status, RewardedAdStatus.loading);

    ads.gate!.complete(RewardedAdOutcome.earned);
    await first;
    expect(controller.state.status, RewardedAdStatus.earned);
  });
}
