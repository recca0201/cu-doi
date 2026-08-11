import 'package:ban_bua_tuong/domain/leaderboard_models.dart';
import 'package:ban_bua_tuong/domain/leaderboard_score_policy.dart';
import 'package:ban_bua_tuong/domain/player_progress.dart';
import 'package:ban_bua_tuong/sim/arena.dart';
import 'package:ban_bua_tuong/sim/arenas.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const LeaderboardScorePolicy policy = ArenaLeaderboardScorePolicy();

  group('LeaderboardScorePolicy', () {
    test('accepts the persisted winning record for every arena 1..20', () {
      expect(
        kArenas.map((arena) => arena.id),
        orderedEquals(<int>[
          for (int arenaId = 1; arenaId <= 20; arenaId++) arenaId,
        ]),
      );

      for (final arena in kArenas) {
        final int maximumScore =
            arena.targets.length * kPointsPerTarget * kMaxMultiplier;
        final PlayerProgress progress = PlayerProgress(
          results: <int, LevelResult>{
            arena.id: LevelResult(stars: 1, highScore: maximumScore),
          },
        );

        final ScoreValidation validation = policy.validate(
          arenaId: arena.id,
          score: maximumScore,
          progress: progress,
        );

        expect(
          validation.isEligible,
          isTrue,
          reason: 'arena ${arena.id} should use its generated target count',
        );
        expect(validation.maximumScore, maximumScore);

        final int impossibleScore = maximumScore + 1;
        final PlayerProgress impossibleProgress = PlayerProgress(
          results: <int, LevelResult>{
            arena.id: LevelResult(stars: 3, highScore: impossibleScore),
          },
        );
        expect(
          policy
              .validate(
                arenaId: arena.id,
                score: impossibleScore,
                progress: impossibleProgress,
              )
              .reason,
          ScoreValidationReason.exceedsMaximum,
          reason: 'arena ${arena.id} should reject its derived cap + 1',
        );
      }
    });

    test('rejects arena ids outside the generated campaign', () {
      const PlayerProgress progress = PlayerProgress(
        results: <int, LevelResult>{1: LevelResult(stars: 1, highScore: 100)},
      );

      for (final int arenaId in <int>[0, -1, 21]) {
        expect(
          policy
              .validate(arenaId: arenaId, score: 100, progress: progress)
              .reason,
          ScoreValidationReason.invalidArena,
        );
      }
    });

    test('rejects skipped-only and lost-only arenas', () {
      const PlayerProgress skipped = PlayerProgress(
        results: <int, LevelResult>{
          1: LevelResult(highScore: 100, skipped: true),
        },
      );
      const PlayerProgress lost = PlayerProgress(
        results: <int, LevelResult>{1: LevelResult(highScore: 100, losses: 1)},
      );

      expect(
        policy.validate(arenaId: 1, score: 100, progress: skipped).reason,
        ScoreValidationReason.notCompletedByWin,
      );
      expect(
        policy.validate(arenaId: 1, score: 100, progress: lost).reason,
        ScoreValidationReason.notCompletedByWin,
      );
    });

    test('rejects zero and a score different from the persisted record', () {
      const PlayerProgress progress = PlayerProgress(
        results: <int, LevelResult>{1: LevelResult(stars: 1, highScore: 500)},
      );

      expect(
        policy.validate(arenaId: 1, score: 0, progress: progress).reason,
        ScoreValidationReason.nonPositiveScore,
      );
      expect(
        policy.validate(arenaId: 1, score: 499, progress: progress).reason,
        ScoreValidationReason.notPersistedRecord,
      );
      expect(
        policy.validate(arenaId: 1, score: 501, progress: progress).reason,
        ScoreValidationReason.notPersistedRecord,
      );
    });
  });

  group('leaderboard domain models', () {
    test('cache and identity keys isolate every persistence dimension', () {
      const IdentityKey identity = IdentityKey(
        platform: GameServicePlatform.gameCenter,
        identityHash: 'identity-a',
      );
      expect(IdentityKey.fromJson(identity.toJson()), identity);

      const LeaderboardCacheKey key = LeaderboardCacheKey(
        platform: GameServicePlatform.gameCenter,
        identityHash: 'identity-a',
        arenaId: 3,
        scope: LeaderboardScope.global,
      );
      expect(LeaderboardCacheKey.fromJson(key.toJson()), key);
      expect(
        key,
        isNot(
          const LeaderboardCacheKey(
            platform: GameServicePlatform.playGames,
            identityHash: 'identity-a',
            arenaId: 3,
            scope: LeaderboardScope.global,
          ),
        ),
      );
      expect(
        key,
        isNot(
          const LeaderboardCacheKey(
            platform: GameServicePlatform.gameCenter,
            identityHash: 'identity-b',
            arenaId: 3,
            scope: LeaderboardScope.global,
          ),
        ),
      );
      expect(
        key,
        isNot(
          const LeaderboardCacheKey(
            platform: GameServicePlatform.gameCenter,
            identityHash: 'identity-a',
            arenaId: 4,
            scope: LeaderboardScope.global,
          ),
        ),
      );
      expect(
        key,
        isNot(
          const LeaderboardCacheKey(
            platform: GameServicePlatform.gameCenter,
            identityHash: 'identity-a',
            arenaId: 3,
            scope: LeaderboardScope.friends,
          ),
        ),
      );
    });

    test('runtime pages and persisted snapshots own immutable row lists', () {
      const PlatformAvatarRef avatar = PlatformAvatarRef(
        platform: GameServicePlatform.gameCenter,
        identityEpoch: 7,
        playerHash: 'hash-a',
        token: 'opaque-native-token',
      );
      final List<LeaderboardEntry> runtimeRows = <LeaderboardEntry>[
        const LeaderboardEntry(
          rank: 1,
          playerId: 'raw-player-id',
          displayName: 'Player',
          score: 1200,
          isCurrentPlayer: true,
          avatar: avatar,
        ),
      ];
      final LeaderboardPage page = LeaderboardPage(leaders: runtimeRows);
      runtimeRows.clear();
      expect(page.leaders, hasLength(1));
      expect(() => page.leaders.clear(), throwsUnsupportedError);

      final List<PersistedLeaderboardRow> persistedRows =
          <PersistedLeaderboardRow>[
            const PersistedLeaderboardRow(
              rank: 1,
              playerHash: 'hash-a',
              displayName: 'Player',
              score: 1200,
              isCurrentPlayer: true,
            ),
          ];
      final LeaderboardSnapshot snapshot = LeaderboardSnapshot(
        rows: persistedRows,
        fetchedAt: DateTime.utc(2026, 8, 11),
      );
      persistedRows.clear();
      expect(snapshot.rows, hasLength(1));
      expect(() => snapshot.rows.clear(), throwsUnsupportedError);

      final String persistedText = snapshot.toJson().toString();
      expect(persistedText, isNot(contains('raw-player-id')));
      expect(persistedText, isNot(contains('opaque-native-token')));
      final LeaderboardSnapshot restored = LeaderboardSnapshot.fromJson(
        snapshot.toJson(),
      );
      expect(restored.rows, snapshot.rows);
      expect(restored.fetchedAt, snapshot.fetchedAt);
    });

    test('pending scores round-trip and summaries expose queue state', () {
      const PendingScore pending = PendingScore(
        identityHash: 'identity-a',
        platform: GameServicePlatform.playGames,
        arenaId: 12,
        score: 1800,
      );
      const PendingScore failed = PendingScore(
        identityHash: 'identity-a',
        platform: GameServicePlatform.playGames,
        arenaId: 13,
        score: 1500,
        state: SubmissionState.permanentlyFailed,
        reasonCode: 'score_rejected',
      );

      expect(PendingScore.fromJson(failed.toJson()), failed);
      final SubmissionSummary summary = SubmissionSummary(
        scores: <PendingScore>[pending, failed],
        isFlushing: true,
      );
      expect(summary.pendingCount, 1);
      expect(summary.permanentlyFailedCount, 1);
      expect(summary.forArena(12), pending);
      expect(summary.forArena(13), failed);
      expect(summary.isFlushing, isTrue);
      expect(() => summary.scores.clear(), throwsUnsupportedError);
    });

    test(
      'scope defaults safely and identity confidence gates personal data',
      () {
        expect(
          LeaderboardSettings.fromJson(const <String, dynamic>{}).lastScope,
          LeaderboardScope.global,
        );
        expect(
          LeaderboardSettings.fromJson(const <String, dynamic>{
            'lastScope': 'invalid',
          }).lastScope,
          LeaderboardScope.global,
        );
        expect(
          LeaderboardSettings.fromJson(const <String, dynamic>{
            'lastScope': 'friends',
          }).lastScope,
          LeaderboardScope.friends,
        );

        const PlatformIdentity identity = PlatformIdentity(
          platform: GameServicePlatform.gameCenter,
          playerId: 'raw-player-id',
          displayName: 'Player',
          sessionToken: 'session-player',
        );
        const PlatformIdentityState confirmed = PlatformIdentityState(
          confidence: IdentityConfidence.confirmedCurrent,
          epoch: 2,
          identity: identity,
        );
        const PlatformIdentityState lastKnown = PlatformIdentityState(
          confidence: IdentityConfidence.lastKnownUnchanged,
          epoch: 2,
          identity: identity,
        );
        const PlatformIdentityState changed = PlatformIdentityState(
          confidence: IdentityConfidence.changed,
          epoch: 3,
        );

        expect(confirmed.mayUseMatchingCache, isTrue);
        expect(confirmed.maySubmit, isTrue);
        expect(lastKnown.mayUseMatchingCache, isTrue);
        expect(lastKnown.maySubmit, isFalse);
        expect(changed.mayUseMatchingCache, isFalse);
        expect(changed.maySubmit, isFalse);
      },
    );

    test('load results represent each repository outcome explicitly', () {
      final LeaderboardPage page = LeaderboardPage(
        leaders: const <LeaderboardEntry>[],
      );
      expect(
        LeaderboardLoadResult.fresh(page).status,
        LeaderboardLoadStatus.fresh,
      );
      expect(
        const LeaderboardLoadResult.empty().status,
        LeaderboardLoadStatus.empty,
      );
      expect(
        const LeaderboardLoadResult.friendsUnavailable().status,
        LeaderboardLoadStatus.friendsUnavailable,
      );
      expect(
        const LeaderboardLoadResult.authRequired().status,
        LeaderboardLoadStatus.authRequired,
      );
      expect(
        const LeaderboardLoadResult.serviceError().status,
        LeaderboardLoadStatus.serviceError,
      );
    });
  });
}
