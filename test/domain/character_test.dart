import 'dart:io';

import 'package:ban_bua_tuong/domain/character.dart';
import 'package:ban_bua_tuong/l10n/app_localizations_en.dart';
import 'package:ban_bua_tuong/l10n/app_localizations_vi.dart';
import 'package:ban_bua_tuong/ui/localized_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every dialogue resolves to finished Vietnamese and English copy', () {
    final vi = AppLocalizationsVi();
    final en = AppLocalizationsEn();
    for (final id in DialogueId.values) {
      for (final text in <String>[dialogueText(id, vi), dialogueText(id, en)]) {
        expect(text.trim(), isNotEmpty);
        expect(text, isNot(contains(RegExp(r'TODO|FIXME|placeholder'))));
      }
    }
    expect(characterName(vi), isNotEmpty);
    expect(characterName(en), isNotEmpty);
  });

  test('character domain stays pure and contains no localized copy', () {
    final source = File('lib/domain/character.dart').readAsStringSync();
    expect(source, isNot(contains('package:flutter')));
    expect(source, isNot(contains('/l10n/')));
    expect(source, isNot(contains('Tôi là')));
  });
}
