import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/game_audio_service.dart';
import '../core/haptic_service.dart';
import '../data/progress_repository.dart';
import '../data/dialogue_seen_repository.dart';
import '../data/settings_repository.dart';
import '../domain/character.dart';
import '../domain/economy.dart';
import '../domain/player_progress.dart';
import 'hint_controller.dart';

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
  void setHaptics(bool value) => _apply(state.copyWith(hapticsOn: value));
  void setLocale(String code) => _apply(state.copyWith(localeCode: code));

  void _apply(AppSettings next) {
    state = next;
    _repo.save(next);
  }
}

final settingsProvider = StateNotifierProvider<SettingsController, AppSettings>(
  (ref) => SettingsController(ref.watch(settingsRepositoryProvider)),
);

/// Local-only for now. `FirestoreProgressRepository` from the parent project
/// implements the same interface and can be swapped in here without touching
/// state or UI — that was the point of the abstraction.
final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => LocalProgressRepository(ref.watch(sharedPreferencesProvider)),
);

class ProgressController extends StateNotifier<PlayerProgress> {
  ProgressController(this._repo, {PlayerProgress? initial})
    : super(initial ?? const PlayerProgress()) {
    if (initial == null) _restore();
  }

  final ProgressRepository _repo;
  bool _spending = false;

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

  Future<void> recordLoss(int arenaId) async {
    state = state.withLoss(arenaId);
    await _repo.save(state);
  }

  Future<SpendResult> spendOnHint() =>
      _spend(cost: kHintCost, transform: (PlayerProgress value) => value);

  Future<SpendResult> skipArena(int arenaId) => _spend(
    cost: kSkipCost,
    transform: (PlayerProgress value) => value.withSkipped(arenaId),
  );

  Future<SpendResult> _spend({
    required int cost,
    required PlayerProgress Function(PlayerProgress) transform,
  }) async {
    if (_spending) return SpendResult.writeFailed;
    if (!state.canAfford(cost)) return SpendResult.insufficientCoins;
    _spending = true;
    try {
      final PlayerProgress next = transform(state).withCoinsSpent(cost);
      if (!await _repo.save(next)) return SpendResult.writeFailed;
      state = next;
      return SpendResult.ok;
    } finally {
      _spending = false;
    }
  }
}

final progressProvider =
    StateNotifierProvider<ProgressController, PlayerProgress>(
      (ref) => ProgressController(ref.watch(progressRepositoryProvider)),
    );

final dialogueSeenRepositoryProvider = Provider<DialogueSeenRepository>(
  (ref) => LocalDialogueSeenRepository(ref.watch(sharedPreferencesProvider)),
);

class DialogueSeenController extends StateNotifier<Set<DialogueId>> {
  DialogueSeenController(this._repo) : super(<DialogueId>{}) {
    restore();
  }

  final DialogueSeenRepository _repo;
  bool isRestored = false;

  Future<void> restore() async {
    state = Set<DialogueId>.of(await _repo.load());
    isRestored = true;
  }

  bool hasSeen(DialogueId id) => state.contains(id);

  Future<bool> markSeen(DialogueId id) async {
    if (state.contains(id)) return true;
    final Set<DialogueId> next = Set<DialogueId>.of(state)..add(id);
    if (!await _repo.save(next)) return false;
    state = next;
    return true;
  }
}

final dialogueSeenProvider =
    StateNotifierProvider<DialogueSeenController, Set<DialogueId>>(
      (ref) =>
          DialogueSeenController(ref.watch(dialogueSeenRepositoryProvider)),
    );

final hintControllerProvider =
    StateNotifierProvider.autoDispose<HintController, HintState>(
      (ref) => HintController(
        ref.read(progressProvider.notifier).spendOnHint,
        () => ref.read(progressProvider).canAfford(kHintCost),
      ),
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

final hapticServiceProvider = Provider<HapticService>((ref) {
  final HapticService service = HapticService(
    enabled: ref.read(settingsProvider).hapticsOn,
  );
  ref.listen<AppSettings>(settingsProvider, (AppSettings? _, AppSettings next) {
    service.setEnabled(next.hapticsOn);
  });
  return service;
});
