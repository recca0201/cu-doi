import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/rewarded_ad_service.dart';
import '../domain/economy.dart';

enum RewardedAdStatus {
  idle,
  loading,
  earned,
  dismissed,
  unavailable,
  saveFailed,
}

class RewardedAdState {
  const RewardedAdState({this.status = RewardedAdStatus.idle});

  final RewardedAdStatus status;
  bool get busy => status == RewardedAdStatus.loading;
}

final class RewardedAdController extends StateNotifier<RewardedAdState> {
  RewardedAdController(this._service, this._grantCoins)
    : super(const RewardedAdState());

  final RewardedAdService _service;
  final Future<bool> Function(int amount) _grantCoins;

  Future<void> show() async {
    if (state.busy) return;
    state = const RewardedAdState(status: RewardedAdStatus.loading);
    final RewardedAdOutcome outcome;
    try {
      outcome = await _service.show();
    } on Object {
      state = const RewardedAdState(status: RewardedAdStatus.unavailable);
      return;
    }
    switch (outcome) {
      case RewardedAdOutcome.earned:
        final bool saved = await _grantCoins(kRewardedAdCoins);
        state = RewardedAdState(
          status: saved ? RewardedAdStatus.earned : RewardedAdStatus.saveFailed,
        );
      case RewardedAdOutcome.dismissed:
        state = const RewardedAdState(status: RewardedAdStatus.dismissed);
      case RewardedAdOutcome.unavailable:
        state = const RewardedAdState(status: RewardedAdStatus.unavailable);
    }
  }
}
