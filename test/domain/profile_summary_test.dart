import 'package:ban_bua_tuong/domain/player_profile.dart';
import 'package:ban_bua_tuong/domain/player_progress.dart';
import 'package:ban_bua_tuong/domain/profile_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('name normalization counts grapheme clusters', () {
    expect(PlayerProfile.normalizeDisplayName('  Dội   Tường  '), 'Dội Tường');
    expect(PlayerProfile.validateDisplayName('   '), 'empty');
    expect(
      PlayerProfile.validateDisplayName(List.filled(20, '👨‍👩‍👧‍👦').join()),
      isNull,
    );
    expect(
      PlayerProfile.validateDisplayName('${List.filled(20, 'a').join()}b'),
      'tooLong',
    );
    expect(const PlayerProfile().displayName('Player'), 'Player');
  });

  test('summary distinguishes skipped from completed and caps progress', () {
    final progress = PlayerProgress(
      results: {
        1: const LevelResult(stars: 3, highScore: 500),
        2: const LevelResult(skipped: true),
        20: const LevelResult(stars: 9, highScore: 800),
      },
    );
    final summary = ProfileSummary.fromProgress(progress);
    expect(summary.chapters, hasLength(4));
    expect(summary.records, hasLength(20));
    expect(summary.badges, hasLength(8));
    expect(summary.completedLevels, 2);
    expect(summary.totalStars, 6);
    expect(summary.bestScore, 800);
    expect(summary.records[1].state, LevelRecordState.skipped);
    expect(summary.records[1].highScore, 0);
  });
}
