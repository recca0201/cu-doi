import 'player_progress.dart';

enum GameServicePlatform { gameCenter, playGames }

enum LeaderboardScope { global, friends }

enum SubmissionState { pending, permanentlyFailed }

/// Explicit outcome for one local score-to-platform submission attempt.
///
/// An empty durable queue is intentionally not represented here: it cannot
/// distinguish an accepted score from a score that was never queued. Receipts
/// are memory-only and are produced only by the local persistence/submission
/// pipeline.
enum SubmissionAttemptStatus {
  notQueued,
  persistFailed,
  pending,
  accepted,
  failed,
}

enum IdentityConfidence {
  confirmedCurrent,
  lastKnownUnchanged,
  changed,
  unknown,
}

enum IdentitySaltState { uninitialized, ready, regeneratedAfterPurge }

enum PlatformIdentityEventKind { authenticated, signedOut, accountChanged }

enum LeaderboardLoadStatus {
  fresh,
  staleCache,
  empty,
  friendsUnavailable,
  authRequired,
  serviceError,
}

enum GameServicesFailureCode {
  cancelled,
  restricted,
  friendsUnavailable,
  unauthenticated,
  retryable,
  permanent,
  unsupported,
}

GameServicePlatform? gameServicePlatformFromName(String? value) {
  for (final GameServicePlatform platform in GameServicePlatform.values) {
    if (platform.name == value) return platform;
  }
  return null;
}

LeaderboardScope? leaderboardScopeFromName(String? value) {
  for (final LeaderboardScope scope in LeaderboardScope.values) {
    if (scope.name == value) return scope;
  }
  return null;
}

SubmissionState? submissionStateFromName(String? value) {
  for (final SubmissionState state in SubmissionState.values) {
    if (state.name == value) return state;
  }
  return null;
}

/// Opaque, memory-only reference understood by the platform avatar bridge.
///
/// The identity epoch and player hash prevent a late avatar response from
/// being applied to a row after an account change. The token must never be
/// written into a leaderboard snapshot.
class PlatformAvatarRef {
  const PlatformAvatarRef({
    required this.platform,
    required this.identityEpoch,
    required this.playerHash,
    required this.token,
  });

  final GameServicePlatform platform;
  final int identityEpoch;
  final String playerHash;
  final String token;

  @override
  bool operator ==(Object other) =>
      other is PlatformAvatarRef &&
      other.platform == platform &&
      other.identityEpoch == identityEpoch &&
      other.playerHash == playerHash &&
      other.token == token;

  @override
  int get hashCode => Object.hash(platform, identityEpoch, playerHash, token);
}

class PlatformIdentity {
  const PlatformIdentity({
    required this.platform,
    required this.playerId,
    required this.displayName,
    required this.sessionToken,
    this.avatar,
  });

  final GameServicePlatform platform;
  final String playerId;
  final String displayName;

  /// Opaque native-owned token binding calls to this exact auth/player
  /// session. It is never persisted or derived in Dart.
  final String sessionToken;
  final PlatformAvatarRef? avatar;

  @override
  bool operator ==(Object other) =>
      other is PlatformIdentity &&
      other.platform == platform &&
      other.playerId == playerId &&
      other.displayName == displayName &&
      other.sessionToken == sessionToken &&
      other.avatar == avatar;

  @override
  int get hashCode =>
      Object.hash(platform, playerId, displayName, sessionToken, avatar);
}

class PlatformIdentityEvent {
  const PlatformIdentityEvent({
    required this.kind,
    required this.epoch,
    this.identity,
  });

  const PlatformIdentityEvent.authenticated({
    required PlatformIdentity this.identity,
    required this.epoch,
  }) : kind = PlatformIdentityEventKind.authenticated;

  const PlatformIdentityEvent.signedOut({required this.epoch})
    : kind = PlatformIdentityEventKind.signedOut,
      identity = null;

  const PlatformIdentityEvent.accountChanged({
    required this.epoch,
    this.identity,
  }) : kind = PlatformIdentityEventKind.accountChanged;

  final PlatformIdentityEventKind kind;
  final int epoch;
  final PlatformIdentity? identity;
}

class PlatformIdentityState {
  const PlatformIdentityState({
    required this.confidence,
    required this.epoch,
    this.identity,
  });

  const PlatformIdentityState.unknown()
    : confidence = IdentityConfidence.unknown,
      epoch = 0,
      identity = null;

  final IdentityConfidence confidence;
  final int epoch;
  final PlatformIdentity? identity;

  bool get mayUseMatchingCache =>
      confidence == IdentityConfidence.confirmedCurrent ||
      confidence == IdentityConfidence.lastKnownUnchanged;

  bool get maySubmit =>
      confidence == IdentityConfidence.confirmedCurrent && identity != null;
}

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.playerId,
    required this.displayName,
    required this.score,
    required this.isCurrentPlayer,
    this.avatar,
  });

  final int rank;
  final String playerId;
  final String displayName;
  final PlatformAvatarRef? avatar;
  final int score;
  final bool isCurrentPlayer;

  @override
  bool operator ==(Object other) =>
      other is LeaderboardEntry &&
      other.rank == rank &&
      other.playerId == playerId &&
      other.displayName == displayName &&
      other.avatar == avatar &&
      other.score == score &&
      other.isCurrentPlayer == isCurrentPlayer;

  @override
  int get hashCode =>
      Object.hash(rank, playerId, displayName, avatar, score, isCurrentPlayer);
}

class LeaderboardPage {
  LeaderboardPage({
    required Iterable<LeaderboardEntry> leaders,
    this.currentPlayer,
  }) : leaders = List<LeaderboardEntry>.unmodifiable(leaders);

  final List<LeaderboardEntry> leaders;
  final LeaderboardEntry? currentPlayer;
}

class PersistedLeaderboardRow {
  const PersistedLeaderboardRow({
    required this.rank,
    required this.playerHash,
    required this.displayName,
    required this.score,
    required this.isCurrentPlayer,
  });

  final int rank;
  final String playerHash;
  final String displayName;
  final int score;
  final bool isCurrentPlayer;

  Map<String, Object> toJson() => <String, Object>{
    'rank': rank,
    'playerHash': playerHash,
    'displayName': displayName,
    'score': score,
    'isCurrentPlayer': isCurrentPlayer,
  };

  factory PersistedLeaderboardRow.fromJson(Map<String, dynamic> json) =>
      PersistedLeaderboardRow(
        rank: json['rank'] as int,
        playerHash: json['playerHash'] as String,
        displayName: json['displayName'] as String,
        score: json['score'] as int,
        isCurrentPlayer: json['isCurrentPlayer'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) =>
      other is PersistedLeaderboardRow &&
      other.rank == rank &&
      other.playerHash == playerHash &&
      other.displayName == displayName &&
      other.score == score &&
      other.isCurrentPlayer == isCurrentPlayer;

  @override
  int get hashCode =>
      Object.hash(rank, playerHash, displayName, score, isCurrentPlayer);
}

class IdentityKey {
  const IdentityKey({required this.platform, required this.identityHash});

  final GameServicePlatform platform;
  final String identityHash;

  Map<String, String> toJson() => <String, String>{
    'platform': platform.name,
    'identityHash': identityHash,
  };

  factory IdentityKey.fromJson(Map<String, dynamic> json) {
    final GameServicePlatform? platform = gameServicePlatformFromName(
      json['platform'] as String?,
    );
    if (platform == null) throw const FormatException('Invalid platform');
    return IdentityKey(
      platform: platform,
      identityHash: json['identityHash'] as String,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is IdentityKey &&
      other.platform == platform &&
      other.identityHash == identityHash;

  @override
  int get hashCode => Object.hash(platform, identityHash);
}

class LeaderboardCacheKey {
  const LeaderboardCacheKey({
    required this.platform,
    required this.identityHash,
    required this.arenaId,
    required this.scope,
  });

  final GameServicePlatform platform;
  final String identityHash;
  final int arenaId;
  final LeaderboardScope scope;

  IdentityKey get identity =>
      IdentityKey(platform: platform, identityHash: identityHash);

  Map<String, Object> toJson() => <String, Object>{
    'platform': platform.name,
    'identityHash': identityHash,
    'arenaId': arenaId,
    'scope': scope.name,
  };

  factory LeaderboardCacheKey.fromJson(Map<String, dynamic> json) {
    final GameServicePlatform? platform = gameServicePlatformFromName(
      json['platform'] as String?,
    );
    final LeaderboardScope? scope = leaderboardScopeFromName(
      json['scope'] as String?,
    );
    if (platform == null || scope == null) {
      throw const FormatException('Invalid leaderboard cache key');
    }
    return LeaderboardCacheKey(
      platform: platform,
      identityHash: json['identityHash'] as String,
      arenaId: json['arenaId'] as int,
      scope: scope,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is LeaderboardCacheKey &&
      other.platform == platform &&
      other.identityHash == identityHash &&
      other.arenaId == arenaId &&
      other.scope == scope;

  @override
  int get hashCode => Object.hash(platform, identityHash, arenaId, scope);
}

class LeaderboardSnapshot {
  LeaderboardSnapshot({
    required Iterable<PersistedLeaderboardRow> rows,
    required this.fetchedAt,
    this.currentPlayer,
    this.schemaVersion = currentSchemaVersion,
  }) : rows = List<PersistedLeaderboardRow>.unmodifiable(rows);

  static const int currentSchemaVersion = 1;

  final List<PersistedLeaderboardRow> rows;
  final PersistedLeaderboardRow? currentPlayer;
  final DateTime fetchedAt;
  final int schemaVersion;

  Map<String, Object?> toJson() => <String, Object?>{
    'schemaVersion': schemaVersion,
    'fetchedAt': fetchedAt.toUtc().millisecondsSinceEpoch,
    'rows': rows.map((PersistedLeaderboardRow row) => row.toJson()).toList(),
    'currentPlayer': currentPlayer?.toJson(),
  };

  factory LeaderboardSnapshot.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawRows =
        json['rows'] as List<dynamic>? ?? const <dynamic>[];
    final Object? rawCurrentPlayer = json['currentPlayer'];
    return LeaderboardSnapshot(
      rows: rawRows.map(
        (dynamic row) => PersistedLeaderboardRow.fromJson(
          Map<String, dynamic>.from(row as Map),
        ),
      ),
      currentPlayer: rawCurrentPlayer == null
          ? null
          : PersistedLeaderboardRow.fromJson(
              Map<String, dynamic>.from(rawCurrentPlayer as Map),
            ),
      fetchedAt: DateTime.fromMillisecondsSinceEpoch(
        json['fetchedAt'] as int,
        isUtc: true,
      ),
      schemaVersion: json['schemaVersion'] as int? ?? currentSchemaVersion,
    );
  }
}

class PendingScore {
  const PendingScore({
    required this.identityHash,
    required this.platform,
    required this.arenaId,
    required this.score,
    this.state = SubmissionState.pending,
    this.reasonCode,
  });

  final String identityHash;
  final GameServicePlatform platform;
  final int arenaId;
  final int score;
  final SubmissionState state;
  final String? reasonCode;

  IdentityKey get identity =>
      IdentityKey(platform: platform, identityHash: identityHash);

  PendingScore copyWith({
    int? score,
    SubmissionState? state,
    String? reasonCode,
    bool clearReasonCode = false,
  }) => PendingScore(
    identityHash: identityHash,
    platform: platform,
    arenaId: arenaId,
    score: score ?? this.score,
    state: state ?? this.state,
    reasonCode: clearReasonCode ? null : reasonCode ?? this.reasonCode,
  );

  Map<String, Object?> toJson() => <String, Object?>{
    'identityHash': identityHash,
    'platform': platform.name,
    'arenaId': arenaId,
    'score': score,
    'state': state.name,
    'reasonCode': reasonCode,
  };

  factory PendingScore.fromJson(Map<String, dynamic> json) {
    final GameServicePlatform? platform = gameServicePlatformFromName(
      json['platform'] as String?,
    );
    final SubmissionState? state = submissionStateFromName(
      json['state'] as String?,
    );
    if (platform == null || state == null) {
      throw const FormatException('Invalid pending score');
    }
    return PendingScore(
      identityHash: json['identityHash'] as String,
      platform: platform,
      arenaId: json['arenaId'] as int,
      score: json['score'] as int,
      state: state,
      reasonCode: json['reasonCode'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PendingScore &&
      other.identityHash == identityHash &&
      other.platform == platform &&
      other.arenaId == arenaId &&
      other.score == score &&
      other.state == state &&
      other.reasonCode == reasonCode;

  @override
  int get hashCode =>
      Object.hash(identityHash, platform, arenaId, score, state, reasonCode);
}

class LeaderboardSettings {
  const LeaderboardSettings({this.lastScope = LeaderboardScope.global});

  final LeaderboardScope lastScope;

  Map<String, String> toJson() => <String, String>{'lastScope': lastScope.name};

  factory LeaderboardSettings.fromJson(Map<String, dynamic> json) =>
      LeaderboardSettings(
        lastScope:
            leaderboardScopeFromName(json['lastScope'] as String?) ??
            LeaderboardScope.global,
      );
}

class BackfillMarker {
  const BackfillMarker({required this.identity});

  final IdentityKey identity;

  Map<String, Object> toJson() => <String, Object>{
    'identity': identity.toJson(),
  };

  factory BackfillMarker.fromJson(Map<String, dynamic> json) => BackfillMarker(
    identity: IdentityKey.fromJson(
      Map<String, dynamic>.from(json['identity'] as Map),
    ),
  );
}

class SubmissionSummary {
  SubmissionSummary({
    Iterable<PendingScore> scores = const <PendingScore>[],
    Iterable<SubmissionReceipt> receipts = const <SubmissionReceipt>[],
    this.isFlushing = false,
  }) : scores = List<PendingScore>.unmodifiable(scores),
       receipts = List<SubmissionReceipt>.unmodifiable(receipts);

  final List<PendingScore> scores;
  final List<SubmissionReceipt> receipts;
  final bool isFlushing;

  int get pendingCount => scores
      .where((PendingScore score) => score.state == SubmissionState.pending)
      .length;
  int get permanentlyFailedCount => scores
      .where(
        (PendingScore score) =>
            score.state == SubmissionState.permanentlyFailed,
      )
      .length;

  PendingScore? forArena(int arenaId) {
    for (final PendingScore score in scores) {
      if (score.arenaId == arenaId) return score;
    }
    return null;
  }

  SubmissionReceipt? receiptForArena(int arenaId, {int? score}) {
    for (final SubmissionReceipt receipt in receipts.reversed) {
      if (receipt.arenaId == arenaId &&
          (score == null || receipt.score == score)) {
        return receipt;
      }
    }
    return null;
  }
}

class SubmissionReceipt {
  const SubmissionReceipt({
    required this.arenaId,
    required this.score,
    required this.status,
    this.reasonCode,
  });

  final int arenaId;
  final int score;
  final SubmissionAttemptStatus status;
  final String? reasonCode;

  SubmissionReceipt copyWith({
    SubmissionAttemptStatus? status,
    String? reasonCode,
    bool clearReasonCode = false,
  }) => SubmissionReceipt(
    arenaId: arenaId,
    score: score,
    status: status ?? this.status,
    reasonCode: clearReasonCode ? null : reasonCode ?? this.reasonCode,
  );

  @override
  bool operator ==(Object other) =>
      other is SubmissionReceipt &&
      other.arenaId == arenaId &&
      other.score == score &&
      other.status == status &&
      other.reasonCode == reasonCode;

  @override
  int get hashCode => Object.hash(arenaId, score, status, reasonCode);
}

class LeaderboardLoadResult {
  const LeaderboardLoadResult._({
    required this.status,
    this.page,
    this.snapshot,
    this.reasonCode,
  });

  const LeaderboardLoadResult.fresh(LeaderboardPage page)
    : this._(status: LeaderboardLoadStatus.fresh, page: page);

  const LeaderboardLoadResult.staleCache(LeaderboardSnapshot snapshot)
    : this._(status: LeaderboardLoadStatus.staleCache, snapshot: snapshot);

  const LeaderboardLoadResult.empty()
    : this._(status: LeaderboardLoadStatus.empty);

  const LeaderboardLoadResult.friendsUnavailable({String? reasonCode})
    : this._(
        status: LeaderboardLoadStatus.friendsUnavailable,
        reasonCode: reasonCode,
      );

  const LeaderboardLoadResult.authRequired()
    : this._(status: LeaderboardLoadStatus.authRequired);

  const LeaderboardLoadResult.serviceError({String? reasonCode})
    : this._(
        status: LeaderboardLoadStatus.serviceError,
        reasonCode: reasonCode,
      );

  final LeaderboardLoadStatus status;
  final LeaderboardPage? page;
  final LeaderboardSnapshot? snapshot;
  final String? reasonCode;
}

/// Stable reason categories for rejecting an attempted leaderboard score.
///
/// These are deliberately domain values rather than platform error strings so
/// callers can decide whether to enqueue without logging player data.
enum ScoreValidationReason {
  invalidArena,
  notCompletedByWin,
  nonPositiveScore,
  notPersistedRecord,
  exceedsMaximum,
}

/// Result of applying the local leaderboard score policy.
class ScoreValidation {
  const ScoreValidation.eligible({required this.maximumScore}) : reason = null;

  const ScoreValidation.rejected({required this.reason, this.maximumScore});

  final ScoreValidationReason? reason;

  /// Maximum possible score derived from live arena data, when the arena is
  /// known. It is useful for diagnostics without duplicating tuned caps.
  final int? maximumScore;

  bool get isEligible => reason == null;
  bool get eligible => isEligible;
  bool get isValid => isEligible;
}

/// Outcome of attempting to persist one terminal arena result.
///
/// On success [persistedProgress] is the exact object saved by the repository
/// and published as controller state. On failure it remains the last committed
/// snapshot, so consumers can never enqueue an uncommitted score.
class RecordOutcome {
  const RecordOutcome({
    required this.persisted,
    required this.arenaId,
    required this.attemptedScore,
    required this.previousBest,
    required this.currentBest,
    required this.completedByWin,
    required this.persistedProgress,
  });

  final bool persisted;
  final int arenaId;
  final int attemptedScore;
  final int previousBest;
  final int currentBest;
  final bool completedByWin;
  final PlayerProgress persistedProgress;

  bool get isNewRecord =>
      persisted && completedByWin && currentBest > previousBest;
  bool get isNewHighScore => isNewRecord;
}
