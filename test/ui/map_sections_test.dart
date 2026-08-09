import 'package:ban_bua_tuong/ui/map_sections.dart';
import 'package:ban_bua_tuong/sim/arena.dart';
import 'package:ban_bua_tuong/sim/arenas.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sections preserve four distinct five-arena grids', () {
    final sections = buildMapSections();
    expect(sections, hasLength(4));
    expect(sections.map((section) => section.arenas.length), everyElement(5));
    expect(
      sections.expand((section) => section.arenas).map((a) => a.id),
      orderedEquals(List<int>.generate(20, (index) => index + 1)),
    );
  });

  test('offset includes padding, headers, rows and section gaps', () {
    final sections = buildMapSections();
    const metrics = MapGridMetrics(
      leadingPad: 12,
      headerExtent: 72,
      rowExtent: 112,
      sectionGap: 20,
      viewportExtent: 700,
      maxScrollExtent: 2000,
    );
    expect(offsetForLevel(sections, 1, metrics), 12);
    expect(offsetForLevel(sections, 8, metrics), 12 + 72 + 224 + 20);
    expect(offsetForLevel(sections, 20, metrics), greaterThan(900));
    expect(offsetForLevel(sections, 99, metrics), 0);
  });

  test('oversized grid tile disables initial positioning', () {
    final sections = buildMapSections();
    const metrics = MapGridMetrics(
      leadingPad: 12,
      headerExtent: 72,
      rowExtent: 401,
      sectionGap: 20,
      viewportExtent: 800,
      maxScrollExtent: 2000,
    );
    expect(offsetForLevel(sections, 20, metrics), 0);
  });

  test('arenas outside known ranges remain in a final fallback section', () {
    const ArenaSpec extra = ArenaSpec(
      id: 99,
      name: 'Khác',
      nameEn: 'Other',
      hint: '',
      hintEn: '',
      shots: 1,
      targets: <TargetSpec>[],
      starThresholds: <int>[1, 2, 3],
    );
    final sections = buildMapSections(arenas: <ArenaSpec>[...kArenas, extra]);
    expect(sections.last.chapter, isNull);
    expect(sections.last.arenas.single.id, 99);
  });
}
