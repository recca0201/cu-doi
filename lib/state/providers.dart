import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/game_audio_service.dart';
import '../data/progress_repository.dart';
import '../data/settings_repository.dart';
import '../domain/player_progress.dart';

/// Overridden in `main()` after `SharedPreferences.getInstance()` resolves, so
/// nothing downstream has to be async. Reading it without the override is a
/// programming error, not a runtime condition.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw StateError(
    'sharedPreferencesProvider must be overridden in main() '
    'or in a test ProviderScope.',
  ),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(sharedPreferencesProvider)),
);

class SettingsController extends StateNotifier<AppSettings> {
  SettingsController(this._repo) : super(_repo.load());

  final SettingsRepository _repo;

  void setSound(bool value) => _apply(state.copyWith(soundOn: value));
  void setMusic(bool value) => _apply(state.copyWith(musicOn: value));
  void setLocale(String code) => _apply(state.copyWith(localeCode: code));

  void _apply(AppSettings next) {
    state = next;
    _repo.save(next);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsController, AppSettings>(
  (ref) => SettingsController(ref.watch(settingsRepositoryProvider)),
);

/// Local-only for now. `FirestoreProgressRepository` from the parent project
/// implements the same interface and can be swapped in here without touching
/// state or UI — that was the point of the abstraction.
final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => LocalProgressRepository(ref.watch(sharedPreferencesProvider)),
);

class ProgressController extends StateNotifier<PlayerProgress> {
  ProgressController(this._repo) : super(const PlayerProgress()) {
    _restore();
  }

  final ProgressRepository _repo;

  Future<void> _restore() async {
    state = await _repo.load();
  }

  /// Records a finished arena. Arena ids reuse the parent project's level-id
  /// keyspace, so `PlayerProgress` needed no changes at all.
  Future<void> record(int arenaId, int stars, int score) async {
    state = state.withResult(arenaId, stars, score);
    await _repo.save(state);
  }

  Future<void> reset() async {
    state = const PlayerProgress();
    await _repo.save(state);
  }
}

final progressProvider =
    StateNotifierProvider<ProgressController, PlayerProgress>(
  (ref) => ProgressController(ref.watch(progressRepositoryProvider)),
);

/// Built once, then kept in step with settings via a listener.
///
/// Deliberately not `ref.watch(settingsProvider)` — that would tear down and
/// rebuild the audio service (and its player pool) every time the player flips
/// a toggle, cutting whatever is currently playing.
final gameAudioProvider = Provider<GameAudioService>((ref) {
  final AppSettings initial = ref.read(settingsProvider);
  final GameAudioService service = GameAudioService(
    enabled: initial.soundOn,
    musicEnabled: initial.musicOn,
  );

  ref.listen<AppSettings>(settingsProvider, (AppSettings? _, AppSettings next) {
    service.setEnabled(soundOn: next.soundOn, musicOn: next.musicOn);
  });

  ref.onDispose(service.stopAll);
  return service;
});
