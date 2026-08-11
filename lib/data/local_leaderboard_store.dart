import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/leaderboard_limits.dart';
import '../domain/leaderboard_models.dart';
import 'identity_hasher.dart';

/// Durable, identity-partitioned cache and score queue.
///
/// Each snapshot and arena submission has its own versioned envelope. No raw
/// platform player ID, avatar reference, or avatar bytes are accepted by this
/// persistence boundary.
class LocalLeaderboardStore {
  LocalLeaderboardStore(this._prefs);

  static const int _envelopeVersion = 1;
  static const String snapshotPreferencePrefix =
      kLeaderboardSnapshotPreferencePrefix;
  static const String submissionPreferencePrefix =
      kLeaderboardSubmissionPreferencePrefix;
  static const String _backfillPreferencePrefix =
      kLeaderboardBackfillPreferencePrefix;
  static const String settingsPreferenceKey = 'leaderboard_v1_settings';

  final SharedPreferences _prefs;
  Future<void> _tail = Future<void>.value();
  int _lastAccessStamp = 0;

  Future<LeaderboardSnapshot?> loadSnapshot(LeaderboardCacheKey key) =>
      _serialized<LeaderboardSnapshot?>(() async {
        final String preferenceKey = _snapshotPreferenceKey(key);
        final Map<String, dynamic>? envelope = await _readEnvelope(
          preferenceKey,
          category: 'snapshot',
        );
        if (envelope == null) return null;
        late final LeaderboardSnapshot snapshot;
        try {
          final LeaderboardCacheKey persistedKey = LeaderboardCacheKey.fromJson(
            Map<String, dynamic>.from(envelope['key'] as Map),
          );
          if (persistedKey != key) {
            throw const FormatException('Snapshot key mismatch');
          }
          snapshot = LeaderboardSnapshot.fromJson(
            Map<String, dynamic>.from(envelope['snapshot'] as Map),
          );
          _validateSnapshot(snapshot);
        } catch (error) {
          await _quarantine(preferenceKey, 'snapshot', error);
          return null;
        }

        // Access recency only controls best-effort LRU eviction. A storage
        // failure here is not evidence that the already-decoded snapshot is
        // corrupt, and must never delete otherwise usable offline data.
        try {
          envelope['lastAccessed'] = _nextAccessStamp();
          await _writeString(preferenceKey, jsonEncode(envelope));
        } catch (_) {}
        return snapshot;
      });

  Future<void> saveSnapshot(
    LeaderboardCacheKey key,
    LeaderboardSnapshot value,
  ) => _serialized<void>(() async {
    final String preferenceKey = _snapshotPreferenceKey(key);
    final Map<String, dynamic> envelope = _boundedSnapshotEnvelope(key, value);
    await _writeString(preferenceKey, jsonEncode(envelope));
    await _evictSnapshots(key.identity);
  });

  Future<List<PendingScore>> loadSubmissions(IdentityKey identity) =>
      _serialized<List<PendingScore>>(() async {
        final String prefix = _submissionIdentityPrefix(identity);
        final List<PendingScore> result = <PendingScore>[];
        final List<String> keys = _prefs
            .getKeys()
            .where((String key) => key.startsWith(prefix))
            .toList(growable: false);
        for (final String preferenceKey in keys) {
          final Map<String, dynamic>? envelope = await _readEnvelope(
            preferenceKey,
            category: 'submission',
          );
          if (envelope == null) continue;
          try {
            final PendingScore score = PendingScore.fromJson(
              Map<String, dynamic>.from(envelope['score'] as Map),
            );
            _validatePendingScore(score);
            if (score.identity != identity ||
                preferenceKey != _submissionPreferenceKey(score)) {
              throw const FormatException('Submission key mismatch');
            }
            result.add(score);
          } catch (error) {
            await _quarantine(preferenceKey, 'submission', error);
          }
        }
        result.sort(
          (PendingScore left, PendingScore right) =>
              left.arenaId.compareTo(right.arenaId),
        );
        return List<PendingScore>.unmodifiable(result);
      });

  Future<void> upsertHighest(PendingScore score) => _serialized<void>(() async {
    _validatePendingScore(score);
    final String preferenceKey = _submissionPreferenceKey(score);
    final PendingScore? existing = await _readSubmission(preferenceKey);
    // Equal-score history/backfill is not an explicit retry action. In
    // particular it must not resurrect a permanent rejection as pending.
    if (existing != null && existing.score >= score.score) return;
    await _writeSubmission(preferenceKey, score);
  });

  /// The sole transition that may explicitly resurrect an equal-score
  /// permanent failure. Repository callers expose this only from manual Retry.
  Future<void> retryPermanentlyFailed(PendingScore score) =>
      _serialized<void>(() async {
        final String preferenceKey = _submissionPreferenceKey(score);
        final PendingScore? existing = await _readSubmission(preferenceKey);
        if (existing == null ||
            existing.score != score.score ||
            existing.state != SubmissionState.permanentlyFailed) {
          return;
        }
        await _writeSubmission(
          preferenceKey,
          existing.copyWith(
            state: SubmissionState.pending,
            clearReasonCode: true,
          ),
        );
      });

  Future<void> markPermanentlyFailed(PendingScore score, String reasonCode) =>
      _serialized<void>(() async {
        final String preferenceKey = _submissionPreferenceKey(score);
        final PendingScore? existing = await _readSubmission(preferenceKey);
        if (existing == null || existing.score != score.score) return;
        final String normalizedReason = _normalizeReasonCode(reasonCode);
        await _writeSubmission(
          preferenceKey,
          existing.copyWith(
            state: SubmissionState.permanentlyFailed,
            reasonCode: normalizedReason,
          ),
        );
      });

  Future<void> removeSubmission(PendingScore score) =>
      _serialized<void>(() async {
        final String preferenceKey = _submissionPreferenceKey(score);
        final PendingScore? existing = await _readSubmission(preferenceKey);
        if (existing != null && existing.score == score.score) {
          final bool removed = await _prefs.remove(preferenceKey);
          if (!removed && _prefs.containsKey(preferenceKey)) {
            throw StateError('Failed to durably remove leaderboard submission');
          }
        }
      });

  Future<bool> hasCompletedInitialBackfill(IdentityKey identity) =>
      _serialized<bool>(() async {
        final String preferenceKey = _backfillPreferenceKey(identity);
        final Map<String, dynamic>? envelope = await _readEnvelope(
          preferenceKey,
          category: 'backfill',
        );
        if (envelope == null) return false;
        try {
          final BackfillMarker marker = BackfillMarker.fromJson(
            Map<String, dynamic>.from(envelope['marker'] as Map),
          );
          if (marker.identity != identity) {
            throw const FormatException('Backfill identity mismatch');
          }
          return true;
        } catch (error) {
          await _quarantine(preferenceKey, 'backfill', error);
          return false;
        }
      });

  /// Marks backfill only after all earlier queue writes on this store finish.
  Future<void> markInitialBackfillComplete(IdentityKey identity) =>
      _serialized<void>(() async {
        final Map<String, Object?> envelope = <String, Object?>{
          'schemaVersion': _envelopeVersion,
          'marker': BackfillMarker(identity: identity).toJson(),
        };
        await _writeString(
          _backfillPreferenceKey(identity),
          jsonEncode(envelope),
        );
      });

  Future<void> saveLastScope(LeaderboardScope scope) =>
      _serialized<void>(() async {
        final Map<String, Object> envelope = <String, Object>{
          'schemaVersion': _envelopeVersion,
          ...LeaderboardSettings(lastScope: scope).toJson(),
        };
        await _writeString(settingsPreferenceKey, jsonEncode(envelope));
      });

  LeaderboardScope loadLastScope() {
    final Object? stored = _prefs.get(settingsPreferenceKey);
    if (stored is! String) return LeaderboardScope.global;
    try {
      final Map<String, dynamic> envelope = Map<String, dynamic>.from(
        jsonDecode(stored) as Map,
      );
      if (envelope['schemaVersion'] != _envelopeVersion) {
        return LeaderboardScope.global;
      }
      return LeaderboardSettings.fromJson(envelope).lastScope;
    } catch (_) {
      return LeaderboardScope.global;
    }
  }

  Future<T> _serialized<T>(Future<T> Function() operation) {
    final Future<T> result = _tail.then<T>((_) => operation());
    _tail = result.then<void>((_) {}, onError: (_, _) {});
    return result;
  }

  Map<String, dynamic> _boundedSnapshotEnvelope(
    LeaderboardCacheKey key,
    LeaderboardSnapshot value,
  ) {
    if (key.identityHash.isEmpty ||
        value.schemaVersion != LeaderboardSnapshot.currentSchemaVersion) {
      throw const FormatException('Invalid leaderboard snapshot input');
    }
    final List<PersistedLeaderboardRow> rows = value.rows
        .take(kMaxLeaderboardRows)
        .toList(growable: true);
    PersistedLeaderboardRow? currentPlayer = value.currentPlayer;

    Map<String, dynamic> build() => <String, dynamic>{
      'schemaVersion': _envelopeVersion,
      'key': key.toJson(),
      'snapshot': LeaderboardSnapshot(
        rows: rows,
        currentPlayer: currentPlayer,
        fetchedAt: value.fetchedAt,
      ).toJson(),
      'lastAccessed': _nextAccessStamp(),
    };

    Map<String, dynamic> envelope = build();
    while (_encodedSize(envelope) > kMaxLeaderboardSnapshotBytes &&
        rows.isNotEmpty) {
      rows.removeLast();
      envelope = build();
    }
    if (_encodedSize(envelope) > kMaxLeaderboardSnapshotBytes &&
        currentPlayer != null) {
      currentPlayer = null;
      envelope = build();
    }
    if (_encodedSize(envelope) > kMaxLeaderboardSnapshotBytes) {
      throw StateError('Leaderboard snapshot envelope exceeds byte limit');
    }
    return envelope;
  }

  Future<void> _evictSnapshots(IdentityKey identity) async {
    final String prefix = _snapshotIdentityPrefix(identity);
    final List<({String key, int accessed})> candidates =
        <({String key, int accessed})>[];
    for (final String preferenceKey in _prefs.getKeys().where(
      (String key) => key.startsWith(prefix),
    )) {
      final Object? stored = _prefs.get(preferenceKey);
      if (stored is! String) {
        await _quarantine(
          preferenceKey,
          'snapshot',
          const FormatException('Snapshot envelope is not a string'),
        );
        continue;
      }
      try {
        final Map<String, dynamic> envelope = Map<String, dynamic>.from(
          jsonDecode(stored) as Map,
        );
        if (envelope['schemaVersion'] != _envelopeVersion) {
          throw const FormatException('Unsupported snapshot envelope');
        }
        final LeaderboardCacheKey persistedKey = LeaderboardCacheKey.fromJson(
          Map<String, dynamic>.from(envelope['key'] as Map),
        );
        if (persistedKey.identity != identity ||
            preferenceKey != _snapshotPreferenceKey(persistedKey)) {
          throw const FormatException('Snapshot partition mismatch');
        }
        candidates.add((
          key: preferenceKey,
          accessed: envelope['lastAccessed'] as int? ?? 0,
        ));
      } catch (error) {
        await _quarantine(preferenceKey, 'snapshot', error);
      }
    }
    candidates.sort((left, right) => left.accessed.compareTo(right.accessed));
    final int excess = candidates.length - kMaxLeaderboardSnapshotsPerIdentity;
    for (int index = 0; index < excess; index++) {
      await _prefs.remove(candidates[index].key);
    }
  }

  Future<PendingScore?> _readSubmission(String preferenceKey) async {
    final Map<String, dynamic>? envelope = await _readEnvelope(
      preferenceKey,
      category: 'submission',
    );
    if (envelope == null) return null;
    try {
      final PendingScore result = PendingScore.fromJson(
        Map<String, dynamic>.from(envelope['score'] as Map),
      );
      _validatePendingScore(result);
      if (preferenceKey != _submissionPreferenceKey(result)) {
        throw const FormatException('Submission partition mismatch');
      }
      return result;
    } catch (error) {
      await _quarantine(preferenceKey, 'submission', error);
      return null;
    }
  }

  Future<void> _writeSubmission(
    String preferenceKey,
    PendingScore score,
  ) async {
    final Map<String, Object?> envelope = <String, Object?>{
      'schemaVersion': _envelopeVersion,
      'score': score.toJson(),
    };
    await _writeString(preferenceKey, jsonEncode(envelope));
  }

  Future<Map<String, dynamic>?> _readEnvelope(
    String preferenceKey, {
    required String category,
  }) async {
    final Object? stored = _prefs.get(preferenceKey);
    if (stored == null) return null;
    if (stored is! String) {
      await _quarantine(
        preferenceKey,
        category,
        const FormatException('Leaderboard envelope is not a string'),
      );
      return null;
    }
    try {
      if (category == 'snapshot' &&
          utf8.encode(stored).length > kMaxLeaderboardSnapshotBytes) {
        throw const FormatException('Snapshot exceeds byte limit');
      }
      final Map<String, dynamic> envelope = Map<String, dynamic>.from(
        jsonDecode(stored) as Map,
      );
      if (envelope['schemaVersion'] != _envelopeVersion) {
        throw const FormatException('Unsupported leaderboard envelope');
      }
      return envelope;
    } catch (error) {
      await _quarantine(preferenceKey, category, error);
      return null;
    }
  }

  Future<void> _writeString(String key, String value) async {
    if (!await _prefs.setString(key, value) || _prefs.getString(key) != value) {
      throw StateError('Could not persist leaderboard data');
    }
  }

  Future<void> _quarantine(
    String preferenceKey,
    String category,
    Object error,
  ) async {
    dev.log(
      'quarantined corrupt leaderboard $category',
      name: 'data.leaderboard_store',
      error: error,
    );
    await _prefs.remove(preferenceKey);
  }

  void _validateSnapshot(LeaderboardSnapshot snapshot) {
    if (snapshot.schemaVersion != LeaderboardSnapshot.currentSchemaVersion ||
        snapshot.rows.length > kMaxLeaderboardRows) {
      throw const FormatException('Invalid leaderboard snapshot');
    }
    for (final PersistedLeaderboardRow row in <PersistedLeaderboardRow>[
      ...snapshot.rows,
      if (snapshot.currentPlayer case final PersistedLeaderboardRow current)
        current,
    ]) {
      if (row.rank < 1 || row.playerHash.isEmpty || row.score <= 0) {
        throw const FormatException('Invalid persisted leaderboard row');
      }
    }
  }

  void _validatePendingScore(PendingScore score) {
    if (score.identityHash.isEmpty ||
        score.arenaId < 1 ||
        score.arenaId > 20 ||
        score.score <= 0) {
      throw const FormatException('Invalid pending score values');
    }
    if (score.state == SubmissionState.permanentlyFailed &&
        (score.reasonCode == null || score.reasonCode!.isEmpty)) {
      throw const FormatException('Permanent failure requires a reason');
    }
  }

  String _normalizeReasonCode(String reasonCode) {
    final String normalized = reasonCode.trim().toLowerCase();
    return RegExp(r'^[a-z0-9_]{1,64}$').hasMatch(normalized)
        ? normalized
        : 'permanent_failure';
  }

  int _nextAccessStamp() {
    final int now = DateTime.now().toUtc().microsecondsSinceEpoch;
    _lastAccessStamp = now > _lastAccessStamp ? now : _lastAccessStamp + 1;
    return _lastAccessStamp;
  }

  int _encodedSize(Map<String, dynamic> value) =>
      utf8.encode(jsonEncode(value)).length;

  String _identityLocator(IdentityKey identity) =>
      '${identity.platform.name}_${sha256.convert(utf8.encode(identity.identityHash))}';

  String _snapshotIdentityPrefix(IdentityKey identity) =>
      '$snapshotPreferencePrefix${_identityLocator(identity)}_';

  String _snapshotPreferenceKey(LeaderboardCacheKey key) =>
      '${_snapshotIdentityPrefix(key.identity)}${key.arenaId}_${key.scope.name}';

  String _submissionIdentityPrefix(IdentityKey identity) =>
      '$submissionPreferencePrefix${_identityLocator(identity)}_';

  String _submissionPreferenceKey(PendingScore score) =>
      '${_submissionIdentityPrefix(score.identity)}${score.arenaId}';

  String _backfillPreferenceKey(IdentityKey identity) =>
      '$_backfillPreferencePrefix${_identityLocator(identity)}';
}
