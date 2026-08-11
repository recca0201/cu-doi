import 'dart:convert';

import 'package:ban_bua_tuong/core/leaderboard_limits.dart';
import 'package:ban_bua_tuong/data/identity_hasher.dart';
import 'package:ban_bua_tuong/data/local_leaderboard_store.dart';
import 'package:ban_bua_tuong/domain/leaderboard_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const IdentityKey gameCenterA = IdentityKey(
    platform: GameServicePlatform.gameCenter,
    identityHash: 'identity-a',
  );

  LeaderboardCacheKey cacheKey({
    GameServicePlatform platform = GameServicePlatform.gameCenter,
    String identityHash = 'identity-a',
    int arenaId = 1,
    LeaderboardScope scope = LeaderboardScope.global,
  }) => LeaderboardCacheKey(
    platform: platform,
    identityHash: identityHash,
    arenaId: arenaId,
    scope: scope,
  );

  LeaderboardSnapshot snapshot({
    int count = 1,
    String name = 'Người chơi',
    DateTime? fetchedAt,
  }) => LeaderboardSnapshot(
    rows: List<PersistedLeaderboardRow>.generate(
      count,
      (int index) => PersistedLeaderboardRow(
        rank: index + 1,
        playerHash: 'player-hash-$index',
        displayName: '$name $index',
        score: 9000 - index,
        isCurrentPlayer: index == 0,
      ),
    ),
    fetchedAt: fetchedAt ?? DateTime.utc(2026, 8, 11, 6),
  );

  group('IdentityHasher', () {
    test(
      'keeps one installation salt and stable hashes across restart',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        final IdentityHasher first = IdentityHasher(prefs);
        await first.initialize();
        final String firstHash = first.hashPlayerId('raw-platform-player-id');

        final IdentityHasher restarted = IdentityHasher(prefs);
        await restarted.initialize();

        expect(restarted.saltState, IdentitySaltState.ready);
        expect(restarted.hashPlayerId('raw-platform-player-id'), firstHash);
        expect(firstHash, isNot(contains('raw-platform-player-id')));
      },
    );

    for (final bool corrupt in <bool>[false, true]) {
      test(
        '${corrupt ? 'corrupt' : 'missing'} salt purges unaddressable partitions',
        () async {
          SharedPreferences.setMockInitialValues(<String, Object>{});
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          final IdentityHasher firstHasher = IdentityHasher(prefs);
          await firstHasher.initialize();
          final String identityHash = firstHasher.hashPlayerId('player-a');
          final LocalLeaderboardStore firstStore = LocalLeaderboardStore(prefs);
          final LeaderboardCacheKey key = cacheKey(identityHash: identityHash);
          await firstStore.saveSnapshot(key, snapshot());
          await firstStore.upsertHighest(
            PendingScore(
              identityHash: identityHash,
              platform: GameServicePlatform.gameCenter,
              arenaId: 1,
              score: 1200,
            ),
          );

          if (corrupt) {
            await prefs.setString(IdentityHasher.saltPreferenceKey, 'broken');
          } else {
            await prefs.remove(IdentityHasher.saltPreferenceKey);
          }

          final IdentityHasher recovered = IdentityHasher(prefs);
          await recovered.initialize();
          final LocalLeaderboardStore recoveredStore = LocalLeaderboardStore(
            prefs,
          );

          expect(recovered.saltState, IdentitySaltState.regeneratedAfterPurge);
          expect(await recoveredStore.loadSnapshot(key), isNull);
          expect(await recoveredStore.loadSubmissions(key.identity), isEmpty);
          expect(
            recovered.hashPlayerId('player-a'),
            isNot(equals(identityHash)),
          );
        },
      );
    }
  });

  group('snapshot cache', () {
    late SharedPreferences prefs;
    late LocalLeaderboardStore store;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      prefs = await SharedPreferences.getInstance();
      store = LocalLeaderboardStore(prefs);
    });

    test('uses platform + identity hash + arena + scope exact keys', () async {
      final LeaderboardCacheKey wanted = cacheKey();
      final LeaderboardSnapshot value = snapshot(name: 'Exact');
      await store.saveSnapshot(wanted, value);

      expect(
        (await store.loadSnapshot(wanted))!.rows.single.displayName,
        'Exact 0',
      );
      expect(
        await store.loadSnapshot(
          cacheKey(platform: GameServicePlatform.playGames),
        ),
        isNull,
      );
      expect(
        await store.loadSnapshot(cacheKey(identityHash: 'identity-b')),
        isNull,
      );
      expect(await store.loadSnapshot(cacheKey(arenaId: 2)), isNull);
      expect(
        await store.loadSnapshot(cacheKey(scope: LeaderboardScope.friends)),
        isNull,
      );
    });

    test(
      'defaults scope to global and restores the last valid scope',
      () async {
        expect(store.loadLastScope(), LeaderboardScope.global);
        await store.saveLastScope(LeaderboardScope.friends);
        expect(
          LocalLeaderboardStore(prefs).loadLastScope(),
          LeaderboardScope.friends,
        );

        await prefs.setString(
          LocalLeaderboardStore.settingsPreferenceKey,
          '{"schemaVersion":1,"lastScope":"invalid"}',
        );
        expect(
          LocalLeaderboardStore(prefs).loadLastScope(),
          LeaderboardScope.global,
        );
      },
    );

    test(
      'round trips the exact persisted snapshot without personal tokens',
      () async {
        final LeaderboardCacheKey key = cacheKey(identityHash: 'salted-hash');
        final LeaderboardSnapshot value = LeaderboardSnapshot(
          rows: const <PersistedLeaderboardRow>[
            PersistedLeaderboardRow(
              rank: 7,
              playerHash: 'salted-row-hash',
              displayName: 'Bừa Thủ',
              score: 4321,
              isCurrentPlayer: true,
            ),
          ],
          currentPlayer: const PersistedLeaderboardRow(
            rank: 107,
            playerHash: 'salted-current-hash',
            displayName: 'Tôi',
            score: 3210,
            isCurrentPlayer: true,
          ),
          fetchedAt: DateTime.utc(2026, 8, 11, 7, 8, 9),
        );
        await store.saveSnapshot(key, value);

        final LeaderboardSnapshot loaded = (await store.loadSnapshot(key))!;
        expect(loaded.rows, value.rows);
        expect(loaded.currentPlayer, value.currentPlayer);
        expect(loaded.fetchedAt, value.fetchedAt);
        final String persisted = prefs
            .getKeys()
            .map((String key) => prefs.get(key).toString())
            .join('\n');
        expect(persisted, isNot(contains('"playerId"')));
        expect(persisted, isNot(contains('"avatar"')));
      },
    );

    test('quarantines only the corrupt snapshot envelope', () async {
      final LeaderboardCacheKey corruptKey = cacheKey(arenaId: 1);
      final LeaderboardCacheKey healthyKey = cacheKey(arenaId: 2);
      await store.saveSnapshot(corruptKey, snapshot(name: 'Corrupt me'));
      await store.saveSnapshot(healthyKey, snapshot(name: 'Keep me'));
      final String corruptPreferenceKey = prefs.getKeys().singleWhere(
        (String key) =>
            key.startsWith(LocalLeaderboardStore.snapshotPreferencePrefix) &&
            prefs.getString(key)!.contains('"arenaId":1'),
      );
      await prefs.setString(corruptPreferenceKey, '{corrupt');

      expect(await store.loadSnapshot(corruptKey), isNull);
      expect(
        (await store.loadSnapshot(healthyKey))!.rows.single.displayName,
        'Keep me 0',
      );
    });

    test(
      'access timestamp write failure keeps a valid snapshot usable',
      () async {
        final LeaderboardCacheKey key = cacheKey(arenaId: 4);
        final LeaderboardSnapshot value = snapshot(name: 'Keep after write');
        await store.saveSnapshot(key, value);
        final String preferenceKey = prefs.getKeys().singleWhere(
          (String candidate) =>
              candidate.startsWith(
                LocalLeaderboardStore.snapshotPreferencePrefix,
              ) &&
              prefs.getString(candidate)!.contains('"arenaId":4'),
        );
        final String persistedBefore = prefs.getString(preferenceKey)!;
        final _FailingStringWritePreferences failingPreferences =
            _FailingStringWritePreferences(prefs);

        final LeaderboardSnapshot? loaded = await LocalLeaderboardStore(
          failingPreferences,
        ).loadSnapshot(key);

        expect(loaded?.rows.single.displayName, 'Keep after write 0');
        expect(failingPreferences.removeCalls, 0);
        expect(prefs.getString(preferenceKey), persistedBefore);
        expect(
          (await LocalLeaderboardStore(
            prefs,
          ).loadSnapshot(key))?.rows.single.displayName,
          'Keep after write 0',
        );
      },
    );

    test('caps snapshots at 100 rows and 128 KiB', () async {
      final LeaderboardCacheKey rowKey = cacheKey();
      await store.saveSnapshot(rowKey, snapshot(count: 140));
      expect((await store.loadSnapshot(rowKey))!.rows, hasLength(100));

      final LeaderboardCacheKey byteKey = cacheKey(arenaId: 2);
      await store.saveSnapshot(
        byteKey,
        snapshot(count: 100, name: List<String>.filled(5000, 'đ').join()),
      );
      final LeaderboardSnapshot bounded = (await store.loadSnapshot(byteKey))!;
      expect(bounded.rows.length, lessThan(100));
      final Iterable<String> envelopes = prefs
          .getKeys()
          .where(
            (String key) =>
                key.startsWith(LocalLeaderboardStore.snapshotPreferencePrefix),
          )
          .map((String key) => prefs.getString(key)!)
          .where((String value) => value.contains('"arenaId":2'));
      expect(envelopes, isNotEmpty);
      expect(
        envelopes.every(
          (String value) =>
              utf8.encode(value).length <= kMaxLeaderboardSnapshotBytes,
        ),
        isTrue,
      );
    });

    test('keeps only 40 least-recently-used snapshots per identity', () async {
      for (int arenaId = 1; arenaId <= 20; arenaId++) {
        for (final LeaderboardScope scope in LeaderboardScope.values) {
          await store.saveSnapshot(
            cacheKey(arenaId: arenaId, scope: scope),
            snapshot(name: '$arenaId-${scope.name}'),
          );
        }
      }
      await store.loadSnapshot(cacheKey(arenaId: 1));
      await store.saveSnapshot(cacheKey(arenaId: 21), snapshot(name: 'new'));

      expect(await store.loadSnapshot(cacheKey(arenaId: 1)), isNotNull);
      expect(
        await store.loadSnapshot(
          cacheKey(arenaId: 1, scope: LeaderboardScope.friends),
        ),
        isNull,
      );
      int count = 0;
      for (int arenaId = 1; arenaId <= 21; arenaId++) {
        for (final LeaderboardScope scope in LeaderboardScope.values) {
          if (await store.loadSnapshot(
                cacheKey(arenaId: arenaId, scope: scope),
              ) !=
              null) {
            count++;
          }
        }
      }
      expect(count, kMaxLeaderboardSnapshotsPerIdentity);
    });
  });

  group('durable submission queue', () {
    late SharedPreferences prefs;
    late LocalLeaderboardStore store;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      prefs = await SharedPreferences.getInstance();
      store = LocalLeaderboardStore(prefs);
    });

    PendingScore score(int value, {int arenaId = 3}) => PendingScore(
      identityHash: gameCenterA.identityHash,
      platform: gameCenterA.platform,
      arenaId: arenaId,
      score: value,
    );

    test('persists only the highest score per identity and arena', () async {
      await Future.wait(<Future<void>>[
        store.upsertHighest(score(1000)),
        store.upsertHighest(score(900)),
        store.upsertHighest(score(1400)),
        store.upsertHighest(score(1200)),
      ]);

      final List<PendingScore> loaded = await LocalLeaderboardStore(
        prefs,
      ).loadSubmissions(gameCenterA);
      expect(loaded, <PendingScore>[score(1400)]);
      expect(
        await store.loadSubmissions(
          const IdentityKey(
            platform: GameServicePlatform.playGames,
            identityHash: 'identity-a',
          ),
        ),
        isEmpty,
      );
    });

    test('permanent failure is durable and never appears pending', () async {
      final PendingScore attempted = score(1200);
      await store.upsertHighest(attempted);
      await store.markPermanentlyFailed(attempted, 'score_rejected');

      final PendingScore failed = (await LocalLeaderboardStore(
        prefs,
      ).loadSubmissions(gameCenterA)).single;
      expect(failed.state, SubmissionState.permanentlyFailed);
      expect(failed.reasonCode, 'score_rejected');
      expect(
        (await store.loadSubmissions(
          gameCenterA,
        )).where((PendingScore item) => item.state == SubmissionState.pending),
        isEmpty,
      );
    });

    test(
      'equal-score upsert cannot resurrect permanent failure; manual retry can',
      () async {
        final PendingScore attempted = score(1200);
        await store.upsertHighest(attempted);
        await store.markPermanentlyFailed(attempted, 'score_rejected');

        await store.upsertHighest(attempted);
        PendingScore loaded = (await store.loadSubmissions(gameCenterA)).single;
        expect(loaded.state, SubmissionState.permanentlyFailed);
        expect(loaded.reasonCode, 'score_rejected');

        await store.retryPermanentlyFailed(attempted);
        loaded = (await store.loadSubmissions(gameCenterA)).single;
        expect(loaded.state, SubmissionState.pending);
        expect(loaded.reasonCode, isNull);
      },
    );

    test('a genuinely higher score replaces a permanent failure', () async {
      final PendingScore attempted = score(1200);
      await store.upsertHighest(attempted);
      await store.markPermanentlyFailed(attempted, 'score_rejected');

      await store.upsertHighest(score(1300));

      expect((await store.loadSubmissions(gameCenterA)).single, score(1300));
    });

    test(
      'late completion cannot remove or fail a newer queued score',
      () async {
        final PendingScore old = score(1000);
        await store.upsertHighest(old);
        await store.upsertHighest(score(1500));
        await store.markPermanentlyFailed(old, 'late_failure');
        await store.removeSubmission(old);

        expect((await store.loadSubmissions(gameCenterA)).single, score(1500));
      },
    );

    test(
      'failed remove that retains the key does not acknowledge deletion',
      () async {
        final PendingScore attempted = score(1200);
        await store.upsertHighest(attempted);
        final _RetainingRemovePreferences retainingPreferences =
            _RetainingRemovePreferences(prefs);
        final LocalLeaderboardStore failingStore = LocalLeaderboardStore(
          retainingPreferences,
        );

        await expectLater(
          failingStore.removeSubmission(attempted),
          throwsA(isA<StateError>()),
        );

        expect(retainingPreferences.removeCalls, 1);
        expect(
          await LocalLeaderboardStore(prefs).loadSubmissions(gameCenterA),
          <PendingScore>[attempted],
        );
      },
    );

    test(
      'corrupt queue entries are isolated and never returned for submit',
      () async {
        await store.upsertHighest(score(1200));
        final String queueKey = prefs.getKeys().singleWhere(
          (String key) =>
              key.startsWith(LocalLeaderboardStore.submissionPreferencePrefix),
        );
        await prefs.setString(queueKey, '{corrupt');

        expect(await store.loadSubmissions(gameCenterA), isEmpty);
      },
    );

    test('backfill marker persists after queued records', () async {
      final Future<void> first = store.upsertHighest(score(1100, arenaId: 1));
      final Future<void> second = store.upsertHighest(score(2200, arenaId: 2));
      final Future<void> marker = store.markInitialBackfillComplete(
        gameCenterA,
      );
      await Future.wait(<Future<void>>[first, second, marker]);

      final LocalLeaderboardStore restarted = LocalLeaderboardStore(prefs);
      expect(await restarted.hasCompletedInitialBackfill(gameCenterA), isTrue);
      expect(await restarted.loadSubmissions(gameCenterA), hasLength(2));
    });
  });
}

class _FailingStringWritePreferences implements SharedPreferences {
  _FailingStringWritePreferences(this._delegate);

  final SharedPreferences _delegate;
  int removeCalls = 0;

  @override
  Object? get(String key) => _delegate.get(key);

  @override
  Set<String> getKeys() => _delegate.getKeys();

  @override
  String? getString(String key) => _delegate.getString(key);

  @override
  Future<bool> setString(String key, String value) async => false;

  @override
  Future<bool> remove(String key) {
    removeCalls++;
    return _delegate.remove(key);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RetainingRemovePreferences implements SharedPreferences {
  _RetainingRemovePreferences(this._delegate);

  final SharedPreferences _delegate;
  int removeCalls = 0;

  @override
  bool containsKey(String key) => _delegate.containsKey(key);

  @override
  Object? get(String key) => _delegate.get(key);

  @override
  Set<String> getKeys() => _delegate.getKeys();

  @override
  String? getString(String key) => _delegate.getString(key);

  @override
  Future<bool> remove(String key) async {
    removeCalls++;
    return false;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
