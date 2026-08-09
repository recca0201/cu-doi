import 'package:ban_bua_tuong/data/dialogue_seen_repository.dart';
import 'package:ban_bua_tuong/domain/character.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('seen state uses its own key and round-trips', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final repo = LocalDialogueSeenRepository(prefs);
    expect(await repo.save(<DialogueId>{DialogueId.intro}), isTrue);
    expect(await repo.load(), <DialogueId>{DialogueId.intro});
    expect(prefs.getString('dialogue_seen_v1'), isNotNull);
    expect(prefs.getString('progress_v1'), isNull);
  });

  test('missing and unknown entries are harmless', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final repo = LocalDialogueSeenRepository(prefs);
    expect(await repo.load(), isEmpty);
    await prefs.setString('dialogue_seen_v1', '["intro","futureLine",4]');
    expect(await repo.load(), <DialogueId>{DialogueId.intro});
  });

  test('failed and throwing writes return false', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    expect(
      await LocalDialogueSeenRepository(
        prefs,
        writer: (_, _) async => false,
      ).save(<DialogueId>{DialogueId.intro}),
      isFalse,
    );
    expect(
      await LocalDialogueSeenRepository(
        prefs,
        writer: (_, _) => Future<bool>.error(StateError('disk')),
      ).save(<DialogueId>{DialogueId.intro}),
      isFalse,
    );
  });
}
