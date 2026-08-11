import 'package:ban_bua_tuong/data/firebase_sync_repository.dart';
import 'package:ban_bua_tuong/data/local_player_store.dart';
import 'package:ban_bua_tuong/domain/player_progress.dart';
import 'package:ban_bua_tuong/state/sync_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeSync implements FirebaseSyncRepository {
  bool fail = false;
  @override
  Future<void> commitProfileMutation(
    String uid,
    Map<String, Object?> mutation,
  ) async {}
  @override
  Future<PlayerProgress> reconcile(String uid, PlayerProgress local) async {
    if (fail) throw StateError('offline');
    return PlayerProgress.merge(local, const PlayerProgress(coins: 20));
  }
}

void main() {
  test(
    'offline error remains pending and retry can sync durable cache',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = LocalPlayerStore(await SharedPreferences.getInstance());
      await store.save(
        OwnerKey.account('u'),
        const PlayerEnvelope(progress: PlayerProgress(coins: 4)),
      );
      final repo = FakeSync()..fail = true;
      final controller = SyncController(repo, store);
      await controller.reconcile('u');
      expect(controller.state.phase, SyncPhase.retryableError);
      repo.fail = false;
      await controller.reconcile('u');
      expect(controller.state.phase, SyncPhase.synced);
      expect((await store.load(OwnerKey.account('u'))).progress.coins, 20);
      expect(
        controller.retryDelay(20),
        lessThanOrEqualTo(const Duration(minutes: 6)),
      );
    },
  );
}
