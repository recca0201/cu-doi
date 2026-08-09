import 'package:ban_bua_tuong/domain/chapters.dart';
import 'package:ban_bua_tuong/domain/player_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'target level handles new, progress, skipped, and complete campaigns',
    () {
      expect(targetLevelId(const PlayerProgress()), isNull);
      expect(
        targetLevelId(
          const PlayerProgress(
            results: <int, LevelResult>{7: LevelResult(stars: 1)},
          ),
        ),
        8,
      );
      expect(
        targetLevelId(
          const PlayerProgress(
            results: <int, LevelResult>{7: LevelResult(skipped: true)},
          ),
        ),
        8,
      );
      expect(
        targetLevelId(
          const PlayerProgress(
            results: <int, LevelResult>{20: LevelResult(stars: 1)},
          ),
        ),
        isNull,
      );
    },
  );

  test('valid requested arena wins and invalid request falls back', () {
    const PlayerProgress progress = PlayerProgress(
      results: <int, LevelResult>{7: LevelResult(stars: 1)},
    );
    expect(targetLevelId(progress, requestedArenaId: 3), 3);
    expect(targetLevelId(progress, requestedArenaId: 99), 8);
  });
}
