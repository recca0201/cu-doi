import 'package:ban_bua_tuong/domain/chapters.dart';
import 'package:ban_bua_tuong/domain/player_progress.dart';
import 'package:ban_bua_tuong/sim/arenas.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('campaign has four pure range-based chapters of five arenas', () {
    expect(kChapters, hasLength(4));
    expect(kChapters.map(chapterMaxStars), everyElement(15));
    expect(chapterOf(1)?.number, 1);
    expect(chapterOf(5)?.number, 1);
    expect(chapterOf(6)?.number, 2);
    expect(chapterOf(20)?.number, 4);
    expect(chapterOf(99), isNull);
    for (final chapter in kChapters) {
      expect(
        kArenas.where((arena) => chapter.contains(arena.id)),
        hasLength(5),
      );
    }
  });

  test('chapter progress reads stars and skipped arenas contribute zero', () {
    const PlayerProgress progress = PlayerProgress(
      results: <int, LevelResult>{
        1: LevelResult(stars: 3),
        2: LevelResult(stars: 2),
        3: LevelResult(skipped: true),
        7: LevelResult(stars: 1),
      },
    );
    expect(chapterEarnedStars(kChapters[0], progress), 5);
    expect(chapterEarnedStars(kChapters[1], progress), 1);
    expect(chapterEarnedStars(kChapters[2], const PlayerProgress()), 0);
    expect(
      kChapters.fold(
        0,
        (sum, chapter) => sum + chapterEarnedStars(chapter, progress),
      ),
      progress.totalStars,
    );
  });
}
