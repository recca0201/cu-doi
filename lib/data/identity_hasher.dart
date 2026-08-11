import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/leaderboard_models.dart';

/// Prefixes containing identity-bound leaderboard data.
///
/// They intentionally exclude device-only presentation settings. When the
/// installation salt is lost, these partitions can no longer be addressed
/// safely and are removed before a replacement salt is created.
const String kLeaderboardSnapshotPreferencePrefix = 'leaderboard_v1_snapshot_';
const String kLeaderboardSubmissionPreferencePrefix =
    'leaderboard_v1_submission_';
const String kLeaderboardBackfillPreferencePrefix = 'leaderboard_v1_backfill_';

const List<String> kLeaderboardIdentityPartitionPrefixes = <String>[
  kLeaderboardSnapshotPreferencePrefix,
  kLeaderboardSubmissionPreferencePrefix,
  kLeaderboardBackfillPreferencePrefix,
];

/// Creates installation-scoped, non-reversible platform-player identifiers.
class IdentityHasher {
  IdentityHasher(this._prefs);

  static const String saltPreferenceKey = 'leaderboard_identity_salt_v1';
  static const int _saltByteCount = 32;

  final SharedPreferences _prefs;
  List<int>? _salt;
  IdentitySaltState _saltState = IdentitySaltState.uninitialized;

  IdentitySaltState get saltState => _saltState;

  Future<void> initialize() async {
    final Object? storedSalt = _prefs.get(saltPreferenceKey);
    final String? encoded = storedSalt is String ? storedSalt : null;
    final List<int>? decoded = _decodeSalt(encoded);
    if (decoded != null) {
      _salt = decoded;
      _saltState = IdentitySaltState.ready;
      return;
    }

    final bool hadIdentityPartitions = _prefs.getKeys().any(
      (String key) => kLeaderboardIdentityPartitionPrefixes.any(
        (String prefix) => key.startsWith(prefix),
      ),
    );
    if (hadIdentityPartitions) {
      for (final String key in _prefs.getKeys().toList(growable: false)) {
        if (kLeaderboardIdentityPartitionPrefixes.any(
          (String prefix) => key.startsWith(prefix),
        )) {
          if (!await _prefs.remove(key)) {
            throw StateError('Could not purge stale leaderboard partition');
          }
        }
      }
    }

    final Random random = Random.secure();
    final List<int> salt = List<int>.generate(
      _saltByteCount,
      (_) => random.nextInt(256),
      growable: false,
    );
    final String value = base64UrlEncode(salt);
    if (!await _prefs.setString(saltPreferenceKey, value) ||
        _prefs.getString(saltPreferenceKey) != value) {
      throw StateError('Could not persist leaderboard identity salt');
    }
    _salt = salt;
    _saltState = hadIdentityPartitions
        ? IdentitySaltState.regeneratedAfterPurge
        : IdentitySaltState.ready;
  }

  String hashPlayerId(String platformPlayerId) {
    final List<int>? salt = _salt;
    if (salt == null || _saltState == IdentitySaltState.uninitialized) {
      throw StateError('IdentityHasher.initialize() must complete first');
    }
    if (platformPlayerId.isEmpty) {
      throw ArgumentError.value(
        platformPlayerId,
        'platformPlayerId',
        'must not be empty',
      );
    }
    return Hmac(sha256, salt).convert(utf8.encode(platformPlayerId)).toString();
  }

  List<int>? _decodeSalt(String? value) {
    if (value == null) return null;
    try {
      final List<int> bytes = base64Url.decode(value);
      return bytes.length == _saltByteCount ? bytes : null;
    } on FormatException {
      return null;
    }
  }
}
