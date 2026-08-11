import '../sim/arena.dart';
import '../sim/arenas.dart';
import 'leaderboard_models.dart';
import 'player_progress.dart';

/// Pure-Dart eligibility policy for scores sent to platform leaderboards.
///
/// The campaign and simulation constants remain the authorities for arena
/// coverage and maximum scores; this policy intentionally carries no tuned
/// per-arena values of its own.
abstract interface class LeaderboardScorePolicy {
  ScoreValidation validate({
    required int arenaId,
    required int score,
    required PlayerProgress progress,
  });
}

class ArenaLeaderboardScorePolicy implements LeaderboardScorePolicy {
  const ArenaLeaderboardScorePolicy();

  @override
  ScoreValidation validate({
    required int arenaId,
    required int score,
    required PlayerProgress progress,
  }) {
    final ArenaSpec? arena = _arenaFor(arenaId);
    if (arena == null) {
      return const ScoreValidation.rejected(
        reason: ScoreValidationReason.invalidArena,
      );
    }

    final int maximumScore =
        arena.targets.length * kPointsPerTarget * kMaxMultiplier;
    if (!progress.isCompleted(arenaId)) {
      return ScoreValidation.rejected(
        reason: ScoreValidationReason.notCompletedByWin,
        maximumScore: maximumScore,
      );
    }
    if (score <= 0) {
      return ScoreValidation.rejected(
        reason: ScoreValidationReason.nonPositiveScore,
        maximumScore: maximumScore,
      );
    }
    if (score != progress.highScoreFor(arenaId)) {
      return ScoreValidation.rejected(
        reason: ScoreValidationReason.notPersistedRecord,
        maximumScore: maximumScore,
      );
    }
    if (score > maximumScore) {
      return ScoreValidation.rejected(
        reason: ScoreValidationReason.exceedsMaximum,
        maximumScore: maximumScore,
      );
    }
    return ScoreValidation.eligible(maximumScore: maximumScore);
  }

  ArenaSpec? _arenaFor(int arenaId) {
    for (final ArenaSpec arena in kArenas) {
      if (arena.id == arenaId) return arena;
    }
    return null;
  }
}
