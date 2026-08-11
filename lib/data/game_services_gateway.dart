import 'dart:typed_data';

import '../domain/leaderboard_models.dart';

/// Platform-neutral boundary for Game Center and Play Games Services.
///
/// Implementations must keep platform leaderboard identifiers on the native
/// side. Callers identify a board only by its campaign [arenaId].
abstract interface class GameServicesGateway {
  Future<PlatformIdentity?> restoreIdentity();

  Future<PlatformIdentity> authenticate({required bool interactive});

  Future<LeaderboardPage> loadLeaderboard({
    required PlatformIdentity identity,
    required int arenaId,
    required LeaderboardScope scope,
    required int limit,
  });

  Future<Uint8List?> loadAvatar({
    required PlatformIdentity identity,
    required PlatformAvatarRef avatar,
  });

  Stream<PlatformIdentityEvent> get identityEvents;

  Future<void> submitScore({
    required PlatformIdentity identity,
    required int arenaId,
    required int score,
  });

  Future<void> validateConfiguration();
}

/// A sanitized failure safe to use for retry decisions and localized copy.
///
/// Native messages and details are deliberately not retained because they can
/// contain player names, identifiers, avatar tokens or raw leaderboard IDs.
class GameServicesException implements Exception {
  const GameServicesException(this.code);

  final GameServicesFailureCode code;

  String get reasonCode => code.name;

  bool get isRetryable => code == GameServicesFailureCode.retryable;

  @override
  String toString() => 'GameServicesException(${code.name})';
}

/// Alternate domain wording retained for callers that model failures rather
/// than exceptions. Both names describe the same sanitized value.
typedef GameServicesFailure = GameServicesException;
