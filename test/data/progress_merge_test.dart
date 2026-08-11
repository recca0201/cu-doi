import 'package:ban_bua_tuong/data/firebase_sync_repository.dart';
import 'package:ban_bua_tuong/domain/player_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'merge takes maxima, never sums coins, and completed clears skipped',
    () {
      final a = PlayerProgress(
        coins: 10,
        results: {
          1: const LevelResult(
            stars: 0,
            highScore: 20,
            skipped: true,
            losses: 4,
          ),
        },
      );
      final b = PlayerProgress(
        coins: 8,
        results: {1: const LevelResult(stars: 2, highScore: 50, losses: 2)},
      );
      final merged = PlayerProgress.merge(a, b);
      expect(merged.coins, 10);
      expect(merged.starsFor(1), 2);
      expect(merged.highScoreFor(1), 50);
      expect(merged.lossesFor(1), 4);
      expect(merged.isSkipped(1), isFalse);
    },
  );
  test('cloud codec is dense and rejects malformed data', () {
    final encoded = ProgressCloudCodec.encode(const PlayerProgress());
    expect((encoded['levels'] as Map), hasLength(20));
    expect(ProgressCloudCodec.decode(encoded).results, isEmpty);
    final malformed = Map<String, Object>.from(encoded)..['levels'] = {'1': {}};
    expect(() => ProgressCloudCodec.decode(malformed), throwsFormatException);
  });
}
