import 'dart:async';

import 'package:ban_bua_tuong/core/game_audio_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'initialize preloads effects and starts configured background music',
    () async {
      final _FakeAudioBackend backend = _FakeAudioBackend();
      final GameAudioService service = GameAudioService(
        enabled: true,
        musicEnabled: true,
        backend: backend,
      );

      await service.initialize();
      await service.initialize();

      expect(backend.preloadCalls, 1);
      expect(backend.preloaded, contains('win.mp3'));
      expect(backend.looped, <String>['background_loop.mp3']);
      expect(backend.loopVolumes, <double>[0.16]);
    },
  );

  test('suspend stops music and resume starts one fresh loop', () async {
    final _FakeAudioBackend backend = _FakeAudioBackend();
    final GameAudioService service = GameAudioService(
      enabled: true,
      musicEnabled: true,
      backend: backend,
    );
    await service.initialize();
    final _FakeAudioPlayer first = backend.players.single;

    service.suspend();
    await Future<void>.delayed(Duration.zero);
    expect(first.stopCalls, 1);
    expect(first.disposeCalls, 1);

    service.resume();
    await Future<void>.delayed(Duration.zero);
    expect(backend.looped, hasLength(2));
  });

  test('music setting remains off across initialization and resume', () async {
    final _FakeAudioBackend backend = _FakeAudioBackend();
    final GameAudioService service = GameAudioService(
      enabled: true,
      musicEnabled: false,
      backend: backend,
    );

    await service.initialize();
    service.suspend();
    service.resume();
    await Future<void>.delayed(Duration.zero);

    expect(backend.looped, isEmpty);
  });
}

final class _FakeAudioBackend implements GameAudioBackend {
  int preloadCalls = 0;
  List<String> preloaded = <String>[];
  final List<String> looped = <String>[];
  final List<double> loopVolumes = <double>[];
  final List<_FakeAudioPlayer> players = <_FakeAudioPlayer>[];

  @override
  Future<void> preload(List<String> paths) async {
    preloadCalls++;
    preloaded = paths;
  }

  @override
  Future<GameAudioPlayer> play(String path, {required double volume}) async {
    final _FakeAudioPlayer player = _FakeAudioPlayer();
    players.add(player);
    return player;
  }

  @override
  Future<GameAudioPlayer> loop(String path, {required double volume}) async {
    looped.add(path);
    loopVolumes.add(volume);
    final _FakeAudioPlayer player = _FakeAudioPlayer();
    players.add(player);
    return player;
  }
}

final class _FakeAudioPlayer implements GameAudioPlayer {
  final StreamController<void> _completion = StreamController<void>();
  int stopCalls = 0;
  int disposeCalls = 0;

  @override
  Stream<void> get onComplete => _completion.stream;

  @override
  Future<void> stop() async {
    stopCalls++;
  }

  @override
  Future<void> dispose() async {
    disposeCalls++;
    await _completion.close();
  }
}
