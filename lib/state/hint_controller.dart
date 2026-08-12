import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../sim/geometry.dart';
import '../sim/hint_finder.dart';
import '../domain/economy.dart';

enum HintStatus {
  idle,
  computing,
  shown,
  unavailable,
  failed,
  insufficientCoins,
}

class HintState {
  const HintState({
    this.status = HintStatus.idle,
    this.path = const <V2>[],
    this.purchasedPath = const <V2>[],
    this.purchasedForArenaId,
    this.targetsDestroyed = 0,
    this.targetIndices = const <int>[],
    this.purchasedTargetIndices = const <int>[],
  });

  final HintStatus status;
  final List<V2> path;
  final List<V2> purchasedPath;
  final int? purchasedForArenaId;
  final int targetsDestroyed;
  final List<int> targetIndices;
  final List<int> purchasedTargetIndices;

  HintState copyWith({
    HintStatus? status,
    List<V2>? path,
    List<V2>? purchasedPath,
    int? purchasedForArenaId,
    int? targetsDestroyed,
    List<int>? targetIndices,
    List<int>? purchasedTargetIndices,
    bool clearArenaId = false,
  }) => HintState(
    status: status ?? this.status,
    path: path ?? this.path,
    purchasedPath: purchasedPath ?? this.purchasedPath,
    purchasedForArenaId: clearArenaId
        ? null
        : (purchasedForArenaId ?? this.purchasedForArenaId),
    targetsDestroyed: targetsDestroyed ?? this.targetsDestroyed,
    targetIndices: targetIndices ?? this.targetIndices,
    purchasedTargetIndices:
        purchasedTargetIndices ?? this.purchasedTargetIndices,
  );
}

typedef HintFinder = Future<HintShot?> Function(ArenaSnapshot snapshot);

Future<HintShot?> _findInIsolate(ArenaSnapshot snapshot) =>
    compute(findHintShot, snapshot);

class HintController extends StateNotifier<HintState> {
  HintController(
    this._spendOnHint,
    this._canAffordHint, [
    this._finder = _findInIsolate,
  ]) : super(const HintState());

  final Future<SpendResult> Function() _spendOnHint;
  final bool Function() _canAffordHint;
  final HintFinder _finder;
  bool _disposed = false;

  Future<void> request(ArenaSnapshot snapshot) async {
    if (state.status == HintStatus.computing) return;
    if (!_canAffordHint()) {
      state = state.copyWith(status: HintStatus.insufficientCoins);
      return;
    }
    state = state.copyWith(status: HintStatus.computing, path: const <V2>[]);
    try {
      final HintShot? shot = await _finder(snapshot);
      if (_disposed) return;
      if (shot == null) {
        state = state.copyWith(status: HintStatus.unavailable);
        return;
      }
      final SpendResult result = await _spendOnHint();
      if (_disposed) return;
      switch (result) {
        case SpendResult.ok:
          final List<V2> path = List<V2>.unmodifiable(shot.path);
          final List<int> targetIndices = List<int>.unmodifiable(
            shot.targetIndices,
          );
          state = HintState(
            status: HintStatus.shown,
            path: path,
            purchasedPath: path,
            purchasedForArenaId: snapshot.arenaId,
            targetsDestroyed: shot.targetsDestroyed,
            targetIndices: targetIndices,
            purchasedTargetIndices: targetIndices,
          );
        case SpendResult.insufficientCoins:
          state = state.copyWith(status: HintStatus.insufficientCoins);
        case SpendResult.writeFailed:
          state = state.copyWith(status: HintStatus.failed);
      }
    } catch (_) {
      if (!_disposed) state = state.copyWith(status: HintStatus.failed);
    }
  }

  void clearOnShot() {
    if (_disposed) return;
    state = state.copyWith(
      status: HintStatus.idle,
      path: const <V2>[],
      targetIndices: const <int>[],
    );
  }

  void onArenaLoaded(int arenaId) {
    if (_disposed) return;
    if (state.purchasedForArenaId == arenaId &&
        state.purchasedPath.isNotEmpty) {
      state = state.copyWith(
        status: HintStatus.shown,
        path: state.purchasedPath,
        targetIndices: state.purchasedTargetIndices,
      );
      return;
    }
    state = const HintState();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
