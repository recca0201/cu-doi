import 'dart:async';
import 'dart:developer' as developer;

import 'package:flame_audio/flame_audio.dart';

enum GameSound {
  shoot,
  pop,
  win,
  lose,
  blockedGap,
  wallImpact,
  rouletteTick,
  comicImpact,
  politeClap,
}

enum GameAudioScope { gameplayEffect, terminalResult }

/// Minimal owned-player contract used to keep the audio budget testable.
abstract interface class GameAudioPlayer {
  Stream<void> get onComplete;

  Future<void> stop();

  Future<void> dispose();
}

/// Injectable boundary around Flame's global audio cache and player factory.
abstract interface class GameAudioBackend {
  Future<void> preload(List<String> paths);

  Future<GameAudioPlayer> play(String path, {required double volume});

  Future<GameAudioPlayer> loop(String path, {required double volume});
}

/// Owns bundled effects and looping music while respecting both audio settings.
///
/// The service owns every player it creates. Reservations count toward the
/// three-player cap even while the backend is still starting, so simultaneous
/// calls cannot grow an unbounded pool.
class GameAudioService {
  GameAudioService({
    required bool enabled,
    bool? musicEnabled,
    GameAudioBackend? backend,
    DateTime Function()? now,
  }) : _backend = backend ?? const _FlameGameAudioBackend(),
       _now = now ?? DateTime.now,
       _soundEnabled = enabled,
       _musicEnabled = musicEnabled ?? enabled;

  final GameAudioBackend _backend;
  final DateTime Function() _now;
  bool _soundEnabled;
  bool _musicEnabled;

  static const int _maxPlayers = 3;
  static const String _backgroundMusicPath = 'background_loop.mp3';
  static const double _backgroundMusicVolume = 0.16;

  static const Map<GameSound, String> _files = {
    GameSound.shoot: 'shoot.mp3',
    GameSound.pop: 'bubble_pop_comic.mp3',
    GameSound.win: 'win.mp3',
    GameSound.lose: 'lose.mp3',
    GameSound.blockedGap: 'blocked_gap_boing.mp3',
    GameSound.wallImpact: 'wall_impact.mp3',
    GameSound.rouletteTick: 'roulette_tick.mp3',
    GameSound.comicImpact: 'comic_impact.mp3',
    GameSound.politeClap: 'polite_clap.mp3',
  };

  static const Map<GameSound, double> _volumes = {
    GameSound.shoot: 0.55,
    GameSound.pop: 0.68,
    GameSound.win: 0.80,
    GameSound.lose: 0.70,
    GameSound.blockedGap: 0.55,
    GameSound.wallImpact: 0.60,
    GameSound.rouletteTick: 0.42,
    GameSound.comicImpact: 0.65,
    GameSound.politeClap: 0.48,
  };

  static const Map<GameSound, Duration> _cooldowns = {
    GameSound.shoot: Duration(milliseconds: 80),
    GameSound.pop: Duration(milliseconds: 45),
    GameSound.win: Duration(milliseconds: 500),
    GameSound.lose: Duration(milliseconds: 500),
    GameSound.blockedGap: Duration(milliseconds: 300),
    GameSound.wallImpact: Duration(milliseconds: 80),
    GameSound.rouletteTick: Duration(milliseconds: 70),
    GameSound.comicImpact: Duration(milliseconds: 220),
    GameSound.politeClap: Duration(milliseconds: 600),
  };

  final Map<GameSound, DateTime> _lastStarted = {};
  final List<_AudioSlot> _slots = [];
  int _nextSequence = 0;
  int _musicGeneration = 0;
  bool _initialized = false;
  bool _suspended = false;
  GameAudioPlayer? _backgroundPlayer;

  static String assetPathFor(GameSound sound) => _files[sound]!;

  /// Warms short effects and starts music once settings have been restored.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await preload();
    await startBackgroundMusic();
  }

  Future<void> preload() async {
    if (!_soundEnabled) return;
    try {
      await _backend.preload(_files.values.toList(growable: false));
    } on Object catch (error, stackTrace) {
      _logFailure('Unable to preload gameplay audio', error, stackTrace);
    }
  }

  Future<void> startBackgroundMusic() async {
    if (!_musicEnabled || _suspended || _backgroundPlayer != null) return;
    final generation = ++_musicGeneration;
    try {
      final player = await _backend.loop(
        _backgroundMusicPath,
        volume: _backgroundMusicVolume,
      );
      if (!_musicEnabled || generation != _musicGeneration) {
        await _stopAndDispose(player);
        return;
      }
      _backgroundPlayer = player;
    } on Object catch (error, stackTrace) {
      _logFailure('Unable to start background music', error, stackTrace);
    }
  }

  void setEnabled({required bool soundOn, required bool musicOn}) {
    _soundEnabled = soundOn;
    _musicEnabled = musicOn;
    if (!soundOn) stopGameplayEffects();
    if (musicOn && _initialized && !_suspended) {
      unawaited(startBackgroundMusic());
    } else {
      stopBackgroundMusic();
    }
  }

  void suspend() {
    _suspended = true;
    stopGameplayEffects();
    stopBackgroundMusic();
  }

  void resume() {
    if (!_suspended) return;
    _suspended = false;
    if (_initialized && _musicEnabled) unawaited(startBackgroundMusic());
  }

  void stopBackgroundMusic() {
    _musicGeneration++;
    final player = _backgroundPlayer;
    _backgroundPlayer = null;
    if (player != null) unawaited(_stopAndDispose(player));
  }

  void play(
    GameSound sound, {
    GameAudioScope scope = GameAudioScope.gameplayEffect,
  }) {
    if (!_soundEnabled) return;
    final now = _now();
    final previous = _lastStarted[sound];
    if (previous != null && now.difference(previous) < _cooldowns[sound]!) {
      return;
    }

    final priority = _priority(sound);
    if (_slots.length >= _maxPlayers) {
      final candidates =
          _slots
              .where(
                (slot) =>
                    slot.scope == GameAudioScope.gameplayEffect &&
                    (slot.priority < priority || sound == GameSound.shoot),
              )
              .toList(growable: false)
            ..sort((a, b) {
              final byPriority = a.priority.compareTo(b.priority);
              return byPriority != 0
                  ? byPriority
                  : a.sequence.compareTo(b.sequence);
            });
      if (candidates.isEmpty) return;
      unawaited(_release(candidates.first, stop: true));
    }

    _lastStarted[sound] = now;
    final slot = _AudioSlot(
      sound: sound,
      scope: scope,
      priority: priority,
      sequence: _nextSequence++,
    );
    _slots.add(slot);
    unawaited(_start(slot));
  }

  /// Stops transient gameplay cues while allowing a result cue to finish.
  void stopGameplayEffects() {
    _lastStarted.removeWhere(
      (sound, _) => sound != GameSound.win && sound != GameSound.lose,
    );
    final gameplaySlots = _slots
        .where((slot) => slot.scope == GameAudioScope.gameplayEffect)
        .toList(growable: false);
    for (final slot in gameplaySlots) {
      unawaited(_release(slot, stop: true));
    }
  }

  /// Stops and releases players from both lifecycle scopes.
  void stopAll() {
    _lastStarted.clear();
    stopBackgroundMusic();
    final owned = _slots.toList(growable: false);
    for (final slot in owned) {
      unawaited(_release(slot, stop: true));
    }
  }

  Future<void> _start(_AudioSlot slot) async {
    try {
      final player = await _backend.play(
        assetPathFor(slot.sound),
        volume: _volumes[slot.sound]!,
      );
      if (slot.released) {
        await _stopAndDispose(player);
        return;
      }
      slot.player = player;
      slot.completion = player.onComplete.listen(
        (_) => unawaited(_release(slot, stop: false)),
        onError: (Object error, StackTrace stackTrace) {
          _logFailure(
            'Playback stream failed for ${slot.sound.name}',
            error,
            stackTrace,
          );
          unawaited(_release(slot, stop: false));
        },
      );
    } on Object catch (error, stackTrace) {
      await _release(slot, stop: false);
      _logFailure('Unable to play ${slot.sound.name} sound', error, stackTrace);
    }
  }

  Future<void> _release(_AudioSlot slot, {required bool stop}) async {
    if (slot.released) return;
    slot.released = true;
    _slots.remove(slot);
    await slot.completion?.cancel();
    final player = slot.player;
    slot.player = null;
    if (player == null) return;

    try {
      if (stop) await player.stop();
    } on Object catch (error, stackTrace) {
      _logFailure('Unable to stop ${slot.sound.name} sound', error, stackTrace);
    }
    try {
      await player.dispose();
    } on Object catch (error, stackTrace) {
      _logFailure(
        'Unable to release ${slot.sound.name} sound',
        error,
        stackTrace,
      );
    }
  }

  Future<void> _stopAndDispose(GameAudioPlayer player) async {
    try {
      await player.stop();
    } on Object catch (error, stackTrace) {
      _logFailure('Unable to stop late audio player', error, stackTrace);
    }
    try {
      await player.dispose();
    } on Object catch (error, stackTrace) {
      _logFailure('Unable to release late audio player', error, stackTrace);
    }
  }

  static int _priority(GameSound sound) => switch (sound) {
    GameSound.win || GameSound.lose => 5,
    GameSound.comicImpact => 4,
    GameSound.pop || GameSound.wallImpact => 3,
    GameSound.shoot || GameSound.blockedGap => 2,
    GameSound.rouletteTick || GameSound.politeClap => 1,
  };

  static void _logFailure(String message, Object error, StackTrace stackTrace) {
    developer.log(
      message,
      name: 'game.audio',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

final class _AudioSlot {
  _AudioSlot({
    required this.sound,
    required this.scope,
    required this.priority,
    required this.sequence,
  });

  final GameSound sound;
  final GameAudioScope scope;
  final int priority;
  final int sequence;
  GameAudioPlayer? player;
  StreamSubscription<void>? completion;
  bool released = false;
}

final class _FlameGameAudioBackend implements GameAudioBackend {
  const _FlameGameAudioBackend();

  @override
  Future<void> preload(List<String> paths) =>
      FlameAudio.audioCache.loadAll(paths);

  @override
  Future<GameAudioPlayer> play(String path, {required double volume}) async {
    final player = await FlameAudio.play(path, volume: volume);
    return _CallbackGameAudioPlayer(
      onComplete: player.onPlayerComplete,
      stopCallback: player.stop,
      disposeCallback: player.dispose,
    );
  }

  @override
  Future<GameAudioPlayer> loop(String path, {required double volume}) async {
    final player = await FlameAudio.loopLongAudio(path, volume: volume);
    return _CallbackGameAudioPlayer(
      onComplete: player.onPlayerComplete,
      stopCallback: player.stop,
      disposeCallback: player.dispose,
    );
  }
}

final class _CallbackGameAudioPlayer implements GameAudioPlayer {
  const _CallbackGameAudioPlayer({
    required this.onComplete,
    required this.stopCallback,
    required this.disposeCallback,
  });

  @override
  final Stream<void> onComplete;
  final Future<void> Function() stopCallback;
  final Future<void> Function() disposeCallback;

  @override
  Future<void> stop() => stopCallback();

  @override
  Future<void> dispose() => disposeCallback();
}
