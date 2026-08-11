import 'dart:async';
import 'dart:typed_data';

import 'package:ban_bua_tuong/core/leaderboard_limits.dart';
import 'package:ban_bua_tuong/core/platform_avatar.dart';
import 'package:ban_bua_tuong/domain/leaderboard_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  PlatformAvatarRef ref(int value, {int epoch = 1, String? playerHash}) =>
      PlatformAvatarRef(
        platform: GameServicePlatform.gameCenter,
        identityEpoch: epoch,
        playerHash: playerHash ?? 'player-$value',
        token: 'token-$value',
      );

  test('production avatar limits match the approved contract', () {
    expect(kMaxAvatarBytes, 256 * 1024);
    expect(kMaxConcurrentAvatarRequests, 4);
    expect(kMaxPendingAvatarRequests, 32);
    expect(kMaxAvatarCacheEntries, 32);
    expect(kMaxAvatarCacheBytes, 8 * 1024 * 1024);
    expect(kLeaderboardAvatarTimeout, const Duration(seconds: 5));
  });

  test('oversized payload and row failure return per-row fallback', () async {
    final PlatformAvatarLoader oversized = PlatformAvatarLoader(
      fetch: (_) async => Uint8List(kMaxAvatarBytes + 1),
    );
    final PlatformAvatarLoader failed = PlatformAvatarLoader(
      fetch: (_) async => throw StateError('one row failed'),
    );

    expect(await oversized.load(ref(1)), isNull);
    expect(await failed.load(ref(2)), isNull);
  });

  test('allows at most four native avatar requests concurrently', () async {
    int active = 0;
    int maximumActive = 0;
    final List<Completer<Uint8List?>> requests = <Completer<Uint8List?>>[];
    final PlatformAvatarLoader loader = PlatformAvatarLoader(
      fetch: (_) {
        active += 1;
        if (active > maximumActive) {
          maximumActive = active;
        }
        final Completer<Uint8List?> completer = Completer<Uint8List?>();
        requests.add(completer);
        return completer.future.whenComplete(() => active -= 1);
      },
    );

    final List<Future<Uint8List?>> results = List<Future<Uint8List?>>.generate(
      8,
      (int index) => loader.load(ref(index)),
    );
    await pumpEventQueue();
    expect(requests, hasLength(kMaxConcurrentAvatarRequests));
    expect(maximumActive, kMaxConcurrentAvatarRequests);

    while (requests.length < 8) {
      final List<Completer<Uint8List?>> current = List.of(requests);
      for (final Completer<Uint8List?> request in current) {
        if (!request.isCompleted) {
          request.complete(Uint8List.fromList(<int>[1]));
        }
      }
      await pumpEventQueue();
    }
    for (final Completer<Uint8List?> request in requests) {
      if (!request.isCompleted) {
        request.complete(Uint8List.fromList(<int>[1]));
      }
    }
    await Future.wait(results);
    expect(maximumActive, kMaxConcurrentAvatarRequests);
  });

  test('uses LRU eviction by both entry count and byte budget', () async {
    int calls = 0;
    final PlatformAvatarLoader loader = PlatformAvatarLoader(
      fetch: (_) async {
        calls += 1;
        return Uint8List(3);
      },
      maxCacheEntries: 2,
      maxCacheBytes: 5,
    );

    await loader.load(ref(1));
    await loader.load(ref(2));
    expect(loader.cacheEntryCount, 1);
    expect(loader.cacheByteCount, 3);
    await loader.load(ref(1));
    expect(calls, 3, reason: 'the least-recently-used entry was evicted');
  });

  test('cache hit refreshes recency before entry-count eviction', () async {
    int calls = 0;
    final PlatformAvatarLoader loader = PlatformAvatarLoader(
      fetch: (_) async {
        calls += 1;
        return Uint8List.fromList(<int>[calls]);
      },
      maxCacheEntries: 2,
      maxCacheBytes: 100,
    );

    await loader.load(ref(1));
    await loader.load(ref(2));
    await loader.load(ref(1));
    await loader.load(ref(3));
    await loader.load(ref(2));

    expect(calls, 4);
  });

  test(
    'epoch/player-hash guard rejects stale responses before and after await',
    () async {
      int epoch = 4;
      String playerHash = 'current-player';
      int calls = 0;
      final Completer<Uint8List?> pending = Completer<Uint8List?>();
      final PlatformAvatarLoader loader = PlatformAvatarLoader(
        fetch: (_) {
          calls += 1;
          return pending.future;
        },
        isCurrent: (PlatformAvatarRef avatar) =>
            avatar.identityEpoch == epoch && avatar.playerHash == playerHash,
      );
      final PlatformAvatarRef current = ref(
        1,
        epoch: epoch,
        playerHash: playerHash,
      );

      expect(
        await loader.load(ref(2, epoch: epoch - 1, playerHash: playerHash)),
        isNull,
      );
      expect(calls, 0, reason: 'a stale row must not start native work');

      final Future<Uint8List?> result = loader.load(current);
      await pumpEventQueue();
      epoch += 1;
      pending.complete(Uint8List.fromList(<int>[7, 8]));

      expect(await result, isNull);
      expect(loader.cacheEntryCount, 0);
    },
  );

  test('explicit row guard rejects a recycled row', () async {
    int calls = 0;
    final PlatformAvatarLoader loader = PlatformAvatarLoader(
      fetch: (_) async {
        calls += 1;
        return Uint8List.fromList(<int>[1]);
      },
    );

    expect(
      await loader.loadForRow(
        ref(1, epoch: 2, playerHash: 'one'),
        identityEpoch: 2,
        playerHash: 'different-row',
      ),
      isNull,
    );
    expect(calls, 0);
  });

  test(
    'avatar deadline becomes fallback and does not block later rows',
    () async {
      int calls = 0;
      final PlatformAvatarLoader loader = PlatformAvatarLoader(
        fetch: (_) {
          calls += 1;
          if (calls == 1) return Completer<Uint8List?>().future;
          return Future<Uint8List?>.value(Uint8List.fromList(<int>[2]));
        },
        timeout: const Duration(milliseconds: 1),
        maxConcurrentRequests: 1,
      );

      final Future<Uint8List?> first = loader.load(ref(1));
      final Future<Uint8List?> second = loader.load(ref(2));

      expect(await first, isNull);
      expect(await second, Uint8List.fromList(<int>[2]));
    },
  );

  test(
    'pending work is capped and clear resolves every stale caller',
    () async {
      final List<Completer<Uint8List?>> started = <Completer<Uint8List?>>[];
      final PlatformAvatarLoader loader = PlatformAvatarLoader(
        fetch: (_) {
          final Completer<Uint8List?> gate = Completer<Uint8List?>();
          started.add(gate);
          return gate.future;
        },
        timeout: const Duration(minutes: 1),
        maxConcurrentRequests: 1,
        maxPendingRequests: 2,
      );

      final List<Future<Uint8List?>> results =
          List<Future<Uint8List?>>.generate(
            5,
            (int index) => loader.load(ref(index)),
          );
      await pumpEventQueue();

      expect(started, hasLength(1));
      expect(loader.activeRequestCount, 1);
      expect(loader.pendingRequestCount, 2);
      expect(await results[3], isNull);
      expect(await results[4], isNull);

      loader.clear();
      expect(loader.pendingRequestCount, 0);
      expect(await Future.wait(results.take(3)), everyElement(isNull));

      started.single.complete(Uint8List.fromList(<int>[7, 8, 9]));
      await pumpEventQueue();
      expect(loader.activeRequestCount, 0);
      expect(loader.cacheEntryCount, 0);
    },
  );
}
