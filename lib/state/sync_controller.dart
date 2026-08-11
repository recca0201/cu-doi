import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/firebase_sync_repository.dart';
import '../data/local_player_store.dart';

enum SyncPhase { localOnly, pending, syncing, synced, retryableError }

class SyncState {
  const SyncState({
    this.phase = SyncPhase.localOnly,
    this.pendingCount = 0,
    this.lastSyncedAt,
    this.errorCode,
  });
  final SyncPhase phase;
  final int pendingCount;
  final DateTime? lastSyncedAt;
  final String? errorCode;
}

class SyncController extends StateNotifier<SyncState> {
  SyncController(
    this.repository,
    this.store, {
    DateTime Function()? clock,
    Random? random,
  }) : _clock = clock ?? DateTime.now,
       _random = random ?? Random(),
       super(const SyncState());
  final FirebaseSyncRepository repository;
  final LocalPlayerStore store;
  final DateTime Function() _clock;
  final Random _random;
  Future<void> _tail = Future.value();
  int _epoch = 0;
  void activateOwner() => _epoch++;
  Future<void> reconcile(String uid) {
    final captured = _epoch;
    final completion = Completer<void>();
    _tail = _tail
        .then((_) async {
          if (captured != _epoch) return;
          state = const SyncState(phase: SyncPhase.syncing);
          try {
            final owner = OwnerKey.account(uid);
            final envelope = await store.load(owner);
            final merged = await repository
                .reconcile(uid, envelope.progress)
                .timeout(const Duration(seconds: 15));
            if (captured != _epoch) return;
            if (!await store.save(owner, envelope.copyWith(progress: merged))) {
              throw StateError('localCommitFailed');
            }
            if (captured == _epoch) {
              state = SyncState(
                phase: SyncPhase.synced,
                lastSyncedAt: _clock(),
              );
            }
          } catch (_) {
            if (captured == _epoch) {
              state = const SyncState(
                phase: SyncPhase.retryableError,
                pendingCount: 1,
                errorCode: 'syncFailed',
              );
            }
          }
        })
        .whenComplete(completion.complete);
    return completion.future;
  }

  Duration retryDelay(int attempt) {
    final base = (1 << attempt.clamp(0, 8)).clamp(1, 300);
    return Duration(
      milliseconds: (base * 1000 * (.8 + _random.nextDouble() * .4)).round(),
    );
  }
}
