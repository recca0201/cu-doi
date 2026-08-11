import 'chapters.dart';
import 'player_progress.dart';

enum ChapterProgressState { locked, inProgress, completed }

enum LevelRecordState { locked, incomplete, skipped, completed }

class ChapterSummary {
  const ChapterSummary({
    required this.chapter,
    required this.completed,
    required this.stars,
    required this.state,
  });
  final Chapter chapter;
  final int completed;
  final int stars;
  final ChapterProgressState state;
}

class LevelRecordSummary {
  const LevelRecordSummary({
    required this.levelId,
    required this.state,
    required this.stars,
    required this.highScore,
  });
  final int levelId;
  final LevelRecordState state;
  final int stars;
  final int highScore;
}

class BadgeSummary {
  const BadgeSummary(this.id, this.unlocked, this.progress, this.target);
  final String id;
  final bool unlocked;
  final int progress;
  final int target;
}

class ProfileSummary {
  const ProfileSummary({
    required this.totalStars,
    required this.coins,
    required this.completedLevels,
    required this.bestScore,
    required this.chapters,
    required this.records,
    required this.badges,
  });
  final int totalStars;
  final int coins;
  final int completedLevels;
  final int bestScore;
  final List<ChapterSummary> chapters;
  final List<LevelRecordSummary> records;
  final List<BadgeSummary> badges;

  factory ProfileSummary.fromProgress(PlayerProgress progress) {
    final chapters = kChapters
        .map((chapter) {
          var completed = 0;
          var stars = 0;
          for (var id = chapter.firstLevelId; id <= chapter.lastLevelId; id++) {
            if (progress.isCompleted(id)) completed++;
            stars += progress.starsFor(id).clamp(0, 3);
          }
          final state = completed == 5
              ? ChapterProgressState.completed
              : !progress.isUnlocked(chapter.firstLevelId)
              ? ChapterProgressState.locked
              : ChapterProgressState.inProgress;
          return ChapterSummary(
            chapter: chapter,
            completed: completed,
            stars: stars,
            state: state,
          );
        })
        .toList(growable: false);
    final records = List<LevelRecordSummary>.generate(20, (index) {
      final id = index + 1;
      final state = progress.isCompleted(id)
          ? LevelRecordState.completed
          : progress.isSkipped(id)
          ? LevelRecordState.skipped
          : progress.isUnlocked(id)
          ? LevelRecordState.incomplete
          : LevelRecordState.locked;
      return LevelRecordSummary(
        levelId: id,
        state: state,
        stars: progress.starsFor(id).clamp(0, 3),
        highScore: progress.isCompleted(id) ? progress.highScoreFor(id) : 0,
      );
    }, growable: false);
    final completed = records
        .where((r) => r.state == LevelRecordState.completed)
        .length;
    final stars = records.fold<int>(0, (sum, r) => sum + r.stars).clamp(0, 60);
    final threeStarLevels = records.where((record) => record.stars >= 3).length;
    final badges = <BadgeSummary>[
      BadgeSummary('first_star', stars >= 1, stars.clamp(0, 1), 1),
      BadgeSummary(
        'perfect_three',
        threeStarLevels >= 1,
        threeStarLevels.clamp(0, 1),
        1,
      ),
      for (var index = 0; index < 4; index++)
        BadgeSummary(
          'chapter_${index + 1}',
          chapters[index].state == ChapterProgressState.completed,
          chapters[index].completed.clamp(0, 5),
          5,
        ),
      BadgeSummary(
        'campaign_complete',
        completed >= 20,
        completed.clamp(0, 20),
        20,
      ),
      BadgeSummary('all_stars', stars >= 60, stars.clamp(0, 60), 60),
    ];
    return ProfileSummary(
      totalStars: stars,
      coins: progress.coins.clamp(0, 0x7fffffff),
      completedLevels: completed,
      bestScore: progress.bestScore.clamp(0, 0x7fffffff),
      chapters: chapters,
      records: records,
      badges: badges,
    );
  }
}
