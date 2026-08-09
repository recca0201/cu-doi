import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Vietnamese and English ARB files have identical message keys', () {
    Set<String> keys(String path) =>
        (jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>).keys
            .where((String key) => !key.startsWith('@'))
            .toSet();

    final Set<String> english = keys('lib/l10n/app_en.arb');
    final Set<String> vietnamese = keys('lib/l10n/app_vi.arb');
    expect(english, vietnamese);
    expect(
      english,
      containsAll(<String>[
        'characterName',
        'chapter1Title',
        'chapter2Title',
        'chapter3Title',
        'chapter4Title',
        'chapterOtherTitle',
        'chapterProgressLabel',
        'currentLevelBadge',
        'dialogueIntro',
        'dialogueWin',
        'dialogueLose',
        'dialogueLoseShort',
        'dialogueFinalVictory',
        'hapticsLabel',
      ]),
    );

    for (final String path in <String>[
      'lib/l10n/app_en.arb',
      'lib/l10n/app_vi.arb',
    ]) {
      final Map<String, dynamic> values =
          jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
      for (final MapEntry<String, dynamic> entry in values.entries) {
        if (entry.key.startsWith('@') || entry.value is! String) continue;
        expect((entry.value as String).trim(), isNotEmpty, reason: entry.key);
        expect(
          entry.value,
          isNot(contains(RegExp(r'TODO|FIXME|placeholder'))),
          reason: entry.key,
        );
      }
    }
  });
}
