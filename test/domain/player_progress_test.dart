import 'package:ban_bua_tuong/domain/player_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads old and sparse saves with defaults', () {
    final PlayerProgress old = PlayerProgress.fromJson(<String, dynamic>{
      'coins': 120,
      'results': <String, dynamic>{
        '3': <String, dynamic>{'stars': 2, 'highScore': 900},
      },
    });
    expect(old.coins, 120);
    expect(old.starsFor(3), 2);
    expect(old.highScoreFor(3), 900);
    expect(old.isSkipped(3), isFalse);
    expect(old.lossesFor(3), 0);

    final PlayerProgress sparse = PlayerProgress.fromJson(<String, dynamic>{
      'results': <String, dynamic>{'3': <String, dynamic>{}},
    });
    expect(sparse.starsFor(3), 0);
  });

  test('skipped stages unlock linearly without granting stars', () {
    const PlayerProgress progress = PlayerProgress(
      results: <int, LevelResult>{3: LevelResult(skipped: true)},
    );
    expect(progress.isUnlocked(4), isTrue);
    expect(progress.totalStars, 0);
    expect(progress.isCompleted(3), isFalse);
    expect(progress.isSkipped(3), isTrue);
    expect(progress.isUnlocked(5), isFalse);
  });

  test('spending, skipping, losses and a real win preserve invariants', () {
    const PlayerProgress initial = PlayerProgress(coins: 100);
    expect(initial.canAfford(100), isTrue);
    expect(initial.canAfford(101), isFalse);
    expect(initial.withCoinsSpent(150).coins, 0);

    final PlayerProgress skipped = initial.withLoss(3).withSkipped(3);
    expect(skipped.isSkipped(3), isTrue);
    expect(skipped.lossesFor(3), 0);

    final PlayerProgress lost = skipped.withLoss(3);
    expect(lost.lossesFor(3), 1);
    final PlayerProgress won = lost.withResult(3, 2, 900);
    expect(won.isSkipped(3), isFalse);
    expect(won.lossesFor(3), 0);
    expect(won.starsFor(3), 2);
    expect(won.highScoreFor(3), 900);
  });
}
