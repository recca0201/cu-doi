import 'dart:async';

import 'package:flutter/widgets.dart';

import 'game_audio_service.dart';

/// Keeps owned audio in step with the application lifecycle.
final class GameAudioLifecycleCoordinator with WidgetsBindingObserver {
  GameAudioLifecycleCoordinator(this._audio) {
    WidgetsBinding.instance.addObserver(this);
    unawaited(_audio.initialize());
  }

  final GameAudioService _audio;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _audio.resume();
    } else {
      _audio.suspend();
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audio.stopAll();
  }
}
