import '../domain/chapters.dart';
import '../sim/arena.dart';
import '../sim/arenas.dart';

class ChapterSection {
  const ChapterSection({required this.chapter, required this.arenas});

  final Chapter? chapter;
  final List<ArenaSpec> arenas;
}

List<ChapterSection> buildMapSections({
  List<ArenaSpec> arenas = kArenas,
  List<Chapter> chapters = kChapters,
}) {
  final List<ArenaSpec> ordered = List<ArenaSpec>.of(arenas)
    ..sort((ArenaSpec a, ArenaSpec b) => a.id.compareTo(b.id));
  final List<ChapterSection> result = <ChapterSection>[];
  final Set<int> assigned = <int>{};
  for (final Chapter chapter in chapters) {
    final List<ArenaSpec> members = ordered
        .where((ArenaSpec arena) => chapter.contains(arena.id))
        .toList(growable: false);
    if (members.isNotEmpty) {
      assigned.addAll(members.map((ArenaSpec arena) => arena.id));
      result.add(ChapterSection(chapter: chapter, arenas: members));
    }
  }
  final List<ArenaSpec> remaining = ordered
      .where((ArenaSpec arena) => !assigned.contains(arena.id))
      .toList(growable: false);
  if (remaining.isNotEmpty) {
    result.add(ChapterSection(chapter: null, arenas: remaining));
  }
  return result;
}

class MapGridMetrics {
  const MapGridMetrics({
    required this.leadingPad,
    required this.headerExtent,
    required this.rowExtent,
    required this.sectionGap,
    required this.viewportExtent,
    required this.maxScrollExtent,
    this.columnCount = 4,
  });

  final double leadingPad;
  final double headerExtent;
  final double rowExtent;
  final double sectionGap;
  final double viewportExtent;
  final double maxScrollExtent;
  final int columnCount;
}

const double kAutoScrollTileRatio = 0.5;

double offsetForLevel(
  List<ChapterSection> sections,
  int levelId,
  MapGridMetrics metrics,
) {
  if (metrics.rowExtent > metrics.viewportExtent * kAutoScrollTileRatio) {
    return 0;
  }
  double sectionStart = metrics.leadingPad;
  for (final ChapterSection section in sections) {
    final int index = section.arenas.indexWhere(
      (ArenaSpec arena) => arena.id == levelId,
    );
    final int rows = (section.arenas.length / metrics.columnCount).ceil();
    if (index >= 0) {
      final int row = index ~/ metrics.columnCount;
      final double tileTop =
          sectionStart + metrics.headerExtent + row * metrics.rowExtent;
      final double desired = tileTop - metrics.headerExtent;
      return desired.clamp(0, metrics.maxScrollExtent);
    }
    sectionStart +=
        metrics.headerExtent + rows * metrics.rowExtent + metrics.sectionGap;
  }
  return 0;
}
