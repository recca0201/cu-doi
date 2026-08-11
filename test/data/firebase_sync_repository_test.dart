import 'package:ban_bua_tuong/data/firebase_sync_repository.dart';
import 'package:ban_bua_tuong/domain/player_progress.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeSync implements FirebaseSyncRepository {
  PlayerProgress remote;
  FakeSync(this.remote);
  @override
  Future<void> commitProfileMutation(
    String uid,
    Map<String, Object?> mutation,
  ) async {}
  @override
  Future<PlayerProgress> reconcile(String uid, PlayerProgress local) async =>
      remote = PlayerProgress.merge(remote, local);
}

void main() {
  test('reconcile is deterministic and never rolls progress back', () async {
    final repo = FakeSync(
      const PlayerProgress(
        coins: 8,
        results: {1: LevelResult(stars: 3, highScore: 900)},
      ),
    );
    final merged = await repo.reconcile(
      'uid',
      const PlayerProgress(
        coins: 12,
        results: {
          1: LevelResult(stars: 1, highScore: 1000),
          2: LevelResult(skipped: true),
        },
      ),
    );
    expect(merged.coins, 12);
    expect(merged.starsFor(1), 3);
    expect(merged.highScoreFor(1), 1000);
    expect(merged.isSkipped(2), true);
  });
}
