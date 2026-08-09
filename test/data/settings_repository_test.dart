import 'package:ban_bua_tuong/data/settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'old saves default haptics on and copyWith preserves other fields',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'soundOn': false,
        'musicOn': true,
        'localeCode': 'en',
      });
      final SettingsRepository repo = SettingsRepository(
        await SharedPreferences.getInstance(),
      );
      final AppSettings old = repo.load();
      expect(old.hapticsOn, isTrue);
      final AppSettings changed = old.copyWith(hapticsOn: false);
      expect(changed.soundOn, isFalse);
      expect(changed.musicOn, isTrue);
      expect(changed.localeCode, 'en');
      await repo.save(changed);
      expect(repo.load().hapticsOn, isFalse);
    },
  );
}
