import '../sim/arena.dart';
import '../sim/arenas.dart';
import 'player_progress.dart';

/// A presentation-neutral campaign chapter, defined only by its level range.
class Chapter {
  const Chapter(this.number, this.firstLevelId, this.lastLevelId);

  final int number;
  final int firstLevelId;
  final int lastLevelId;

  bool contains(int levelId) =>
      levelId >= firstLevelId && levelId <= lastLevelId;
}

const List<Chapter> kChapters = <Chapter>[
  Chapter(1, 1, 5),
  Chapter(2, 6, 10),
  Chapter(3, 11, 15),
  Chapter(4, 16, 20),
];

Chapter? chapterOf(int levelId, {List<Chapter> chapters = kChapters}) {
  for (final Chapter chapter in chapters) {
    if (chapter.contains(levelId)) return chapter;
  }
  return null;
}

int chapterMaxStars(Chapter chapter) =>
    (chapter.lastLevelId - chapter.firstLevelId + 1) * 3;

int chapterEarnedStars(Chapter chapter, PlayerProgress progress) {
  var total = 0;
  for (var id = chapter.firstLevelId; id <= chapter.lastLevelId; id++) {
    total += progress.starsFor(id);
  }
  return total;
}

/// Picks the level that should be visible when the map first appears.
///
/// An explicit, valid route target wins. Otherwise the next level after the
/// furthest completed/skipped level is selected. New and fully-complete
/// campaigns deliberately return null so the map starts at the top.
int? targetLevelId(
  PlayerProgress progress, {
  int? requestedArenaId,
  List<ArenaSpec> arenas = kArenas,
}) {
  bool exists(int id) => arenas.any((ArenaSpec arena) => arena.id == id);
  if (requestedArenaId != null && exists(requestedArenaId)) {
    return requestedArenaId;
  }
  if (progress.completedMax == 0) return null;
  final int candidate = progress.completedMax + 1;
  return exists(candidate) ? candidate : null;
}
