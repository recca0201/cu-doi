import 'package:shared_preferences/shared_preferences.dart';

/// User settings — sound, music, and locale (US-015, US-016). VI is default.
class AppSettings {
  const AppSettings({
    this.soundOn = true,
    this.musicOn = true,
    this.hapticsOn = true,
    this.localeCode = 'vi',
  });
  final bool soundOn;
  final bool musicOn;
  final bool hapticsOn;
  final String localeCode;

  AppSettings copyWith({
    bool? soundOn,
    bool? musicOn,
    bool? hapticsOn,
    String? localeCode,
  }) => AppSettings(
    soundOn: soundOn ?? this.soundOn,
    musicOn: musicOn ?? this.musicOn,
    hapticsOn: hapticsOn ?? this.hapticsOn,
    localeCode: localeCode ?? this.localeCode,
  );
}

class SettingsRepository {
  SettingsRepository(this._prefs);
  final SharedPreferences _prefs;

  AppSettings load() => AppSettings(
    soundOn: _prefs.getBool('soundOn') ?? true,
    musicOn: _prefs.getBool('musicOn') ?? true,
    hapticsOn: _prefs.getBool('hapticsOn') ?? true,
    localeCode: _prefs.getString('localeCode') ?? 'vi',
  );

  Future<void> save(AppSettings s) async {
    await _prefs.setBool('soundOn', s.soundOn);
    await _prefs.setBool('musicOn', s.musicOn);
    await _prefs.setBool('hapticsOn', s.hapticsOn);
    await _prefs.setString('localeCode', s.localeCode);
  }
}
