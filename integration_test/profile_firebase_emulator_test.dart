import 'package:ban_bua_tuong/data/firebase_sync_repository.dart';
import 'package:ban_bua_tuong/domain/player_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('two-device merge fixture is associative and idempotent', () {
    const a = PlayerProgress(
      coins: 10,
      results: {1: LevelResult(stars: 2, highScore: 500)},
    );
    const b = PlayerProgress(
      coins: 8,
      results: {
        1: LevelResult(stars: 3, highScore: 450),
        2: LevelResult(skipped: true),
      },
    );
    final first = ProgressCloudCodec.encode(PlayerProgress.merge(a, b));
    final second = ProgressCloudCodec.encode(PlayerProgress.merge(b, a));
    expect(first, second);
    expect(ProgressCloudCodec.encode(ProgressCloudCodec.decode(first)), first);
  });
}
