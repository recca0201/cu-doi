import 'dart:async';
import 'dart:typed_data';

import 'package:ban_bua_tuong/data/game_services_gateway.dart';
import 'package:ban_bua_tuong/domain/leaderboard_models.dart';

typedef FakeRestoreIdentityHandler = Future<PlatformIdentity?> Function();
typedef FakeAuthenticateHandler =
    Future<PlatformIdentity> Function(bool interactive);
typedef FakeLeaderboardLoadHandler =
    Future<LeaderboardPage> Function(
      int arenaId,
      LeaderboardScope scope,
      int limit,
    );
typedef FakeAvatarLoadHandler =
    Future<Uint8List?> Function(PlatformAvatarRef avatar);
typedef FakeScoreSubmitHandler = Future<void> Function(int arenaId, int score);

/// Scriptable platform boundary shared by leaderboard integration/regression
/// tests. It records every externally visible operation and never opens real
/// Game Center or Play Games UI.
class FakeGameServicesGateway implements GameServicesGateway {
  FakeGameServicesGateway({
    this.restoredIdentity,
    this.authenticatedIdentity,
    this.restoreHandler,
    this.authenticateHandler,
    this.loadHandler,
    this.avatarHandler,
    this.submitHandler,
  });

  PlatformIdentity? restoredIdentity;
  PlatformIdentity? authenticatedIdentity;
  FakeRestoreIdentityHandler? restoreHandler;
  FakeAuthenticateHandler? authenticateHandler;
  FakeLeaderboardLoadHandler? loadHandler;
  FakeAvatarLoadHandler? avatarHandler;
  FakeScoreSubmitHandler? submitHandler;

  final List<String> callLog = <String>[];
  final List<bool> authenticateArguments = <bool>[];
  final List<({int arenaId, LeaderboardScope scope, int limit})> loadCalls =
      <({int arenaId, LeaderboardScope scope, int limit})>[];
  final List<PlatformAvatarRef> avatarCalls = <PlatformAvatarRef>[];
  final List<({int arenaId, int score})> submitCalls =
      <({int arenaId, int score})>[];
  final List<PlatformIdentity> loadIdentities = <PlatformIdentity>[];
  final List<PlatformIdentity> avatarIdentities = <PlatformIdentity>[];
  final List<PlatformIdentity> submitIdentities = <PlatformIdentity>[];

  int restoreCalls = 0;
  int validateConfigurationCalls = 0;

  final StreamController<PlatformIdentityEvent> _identityEvents =
      StreamController<PlatformIdentityEvent>.broadcast(sync: true);

  void emitIdentityEvent(PlatformIdentityEvent event) {
    callLog.add('identity:${event.kind.name}:${event.epoch}');
    _identityEvents.add(event);
  }

  @override
  Future<PlatformIdentity?> restoreIdentity() async {
    restoreCalls++;
    callLog.add('restore');
    final FakeRestoreIdentityHandler? handler = restoreHandler;
    return handler == null ? restoredIdentity : handler();
  }

  @override
  Future<PlatformIdentity> authenticate({required bool interactive}) async {
    authenticateArguments.add(interactive);
    callLog.add('authenticate:$interactive');
    final FakeAuthenticateHandler? handler = authenticateHandler;
    if (handler != null) return handler(interactive);
    final PlatformIdentity? identity = authenticatedIdentity;
    if (identity != null) return identity;
    throw const GameServicesException(GameServicesFailureCode.unauthenticated);
  }

  @override
  Future<LeaderboardPage> loadLeaderboard({
    required PlatformIdentity identity,
    required int arenaId,
    required LeaderboardScope scope,
    required int limit,
  }) async {
    loadIdentities.add(identity);
    loadCalls.add((arenaId: arenaId, scope: scope, limit: limit));
    callLog.add('load:$arenaId:${scope.name}:$limit');
    final FakeLeaderboardLoadHandler? handler = loadHandler;
    if (handler != null) return handler(arenaId, scope, limit);
    return LeaderboardPage(leaders: const <LeaderboardEntry>[]);
  }

  @override
  Future<Uint8List?> loadAvatar({
    required PlatformIdentity identity,
    required PlatformAvatarRef avatar,
  }) async {
    avatarIdentities.add(identity);
    avatarCalls.add(avatar);
    callLog.add('avatar:${avatar.identityEpoch}');
    final FakeAvatarLoadHandler? handler = avatarHandler;
    return handler == null ? null : handler(avatar);
  }

  @override
  Stream<PlatformIdentityEvent> get identityEvents => _identityEvents.stream;

  @override
  Future<void> submitScore({
    required PlatformIdentity identity,
    required int arenaId,
    required int score,
  }) async {
    submitIdentities.add(identity);
    submitCalls.add((arenaId: arenaId, score: score));
    callLog.add('submit:$arenaId:$score');
    await submitHandler?.call(arenaId, score);
  }

  @override
  Future<void> validateConfiguration() async {
    validateConfigurationCalls++;
    callLog.add('validateConfiguration');
  }

  Future<void> dispose() => _identityEvents.close();
}
