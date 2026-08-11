import 'dart:async';

import 'package:flutter/services.dart';

import '../core/leaderboard_limits.dart';
import '../domain/leaderboard_models.dart';
import 'game_services_gateway.dart';

/// Versioned Flutter adapter for the first-party GameKit/PGS bridges.
class MethodChannelGameServicesGateway implements GameServicesGateway {
  MethodChannelGameServicesGateway({
    MethodChannel? channel,
    EventChannel? eventChannel,
    Stream<Object?>? identityEventStream,
    this.readTimeout = kLeaderboardReadTimeout,
    this.submitTimeout = kLeaderboardSubmitTimeout,
    this.avatarTimeout = kLeaderboardAvatarTimeout,
  }) : _channel = channel ?? const MethodChannel(channelName),
       _identityEventStream =
           identityEventStream ??
           (eventChannel ?? const EventChannel(identityEventChannelName))
               .receiveBroadcastStream();

  static const String channelName = 'ban_bua_tuong/game_services/v1';
  static const String identityEventChannelName =
      'ban_bua_tuong/game_services/identity_events/v1';

  final MethodChannel _channel;
  final Stream<Object?> _identityEventStream;

  final Duration readTimeout;
  final Duration submitTimeout;
  final Duration avatarTimeout;

  @override
  Future<PlatformIdentity?> restoreIdentity() async {
    final Object? payload = await _invoke<Object?>(
      'restoreIdentity',
      timeout: readTimeout,
    );
    if (payload == null) return null;
    return _decodeSafely(() => _decodeIdentity(payload));
  }

  @override
  Future<PlatformIdentity> authenticate({required bool interactive}) async {
    final Object? payload = await _invoke<Object?>(
      'authenticate',
      arguments: <String, Object>{'interactive': interactive},
      timeout: readTimeout,
    );
    if (payload == null) {
      throw const GameServicesException(
        GameServicesFailureCode.unauthenticated,
      );
    }
    return _decodeSafely(() => _decodeIdentity(payload));
  }

  @override
  Future<LeaderboardPage> loadLeaderboard({
    required PlatformIdentity identity,
    required int arenaId,
    required LeaderboardScope scope,
    required int limit,
  }) async {
    _validateArenaId(arenaId);
    if (limit < 1 || limit > kMaxLeaderboardRows) {
      throw const GameServicesException(GameServicesFailureCode.permanent);
    }
    final Object? payload = await _invoke<Object?>(
      'loadLeaderboard',
      arguments: <String, Object>{
        ..._identityBinding(identity),
        'arenaId': arenaId,
        'scope': scope.name,
        'limit': limit,
      },
      timeout: readTimeout,
    );
    return _decodeSafely(() => _decodePage(payload));
  }

  @override
  Future<Uint8List?> loadAvatar({
    required PlatformIdentity identity,
    required PlatformAvatarRef avatar,
  }) async {
    final Object? payload = await _invoke<Object?>(
      'loadAvatar',
      arguments: <String, Object>{
        ..._identityBinding(identity),
        'platform': avatar.platform.name,
        'identityEpoch': avatar.identityEpoch,
        'playerHash': avatar.playerHash,
        'token': avatar.token,
      },
      timeout: avatarTimeout,
    );
    if (payload == null) return null;
    final Uint8List bytes = switch (payload) {
      Uint8List value => value,
      List<int> value => Uint8List.fromList(value),
      _ => throw const GameServicesException(GameServicesFailureCode.retryable),
    };
    if (bytes.lengthInBytes > kMaxAvatarBytes) {
      throw const GameServicesException(GameServicesFailureCode.retryable);
    }
    return bytes;
  }

  @override
  Stream<PlatformIdentityEvent> get identityEvents => _identityEventStream
      .map<PlatformIdentityEvent>(
        (Object? payload) => _decodeSafely(() => _decodeIdentityEvent(payload)),
      )
      .transform<PlatformIdentityEvent>(
        StreamTransformer<
          PlatformIdentityEvent,
          PlatformIdentityEvent
        >.fromHandlers(
          handleError:
              (
                Object error,
                StackTrace stackTrace,
                EventSink<PlatformIdentityEvent> sink,
              ) {
                sink.addError(_normalizeError(error), stackTrace);
              },
        ),
      );

  @override
  Future<void> submitScore({
    required PlatformIdentity identity,
    required int arenaId,
    required int score,
  }) async {
    _validateArenaId(arenaId);
    if (score <= 0) {
      throw const GameServicesException(GameServicesFailureCode.permanent);
    }
    await _invoke<Object?>(
      'submitScore',
      arguments: <String, Object>{
        ..._identityBinding(identity),
        'arenaId': arenaId,
        'score': score,
      },
      timeout: submitTimeout,
    );
  }

  @override
  Future<void> validateConfiguration() =>
      _invoke<Object?>('validateConfiguration', timeout: readTimeout);

  Future<T?> _invoke<T>(
    String method, {
    Object? arguments,
    required Duration timeout,
  }) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments).timeout(timeout);
    } on TimeoutException {
      throw const GameServicesException(GameServicesFailureCode.retryable);
    } on MissingPluginException {
      throw const GameServicesException(GameServicesFailureCode.unsupported);
    } on PlatformException catch (error) {
      throw GameServicesException(_failureCodeFor(error.code));
    } on GameServicesException {
      rethrow;
    } catch (_) {
      throw const GameServicesException(GameServicesFailureCode.retryable);
    }
  }

  static T _decodeSafely<T>(T Function() decode) {
    try {
      return decode();
    } on GameServicesException {
      rethrow;
    } catch (_) {
      throw const GameServicesException(GameServicesFailureCode.retryable);
    }
  }

  static GameServicesException _normalizeError(Object error) {
    if (error is GameServicesException) return error;
    if (error is MissingPluginException) {
      return const GameServicesException(GameServicesFailureCode.unsupported);
    }
    if (error is PlatformException) {
      return GameServicesException(_failureCodeFor(error.code));
    }
    if (error is TimeoutException) {
      return const GameServicesException(GameServicesFailureCode.retryable);
    }
    return const GameServicesException(GameServicesFailureCode.retryable);
  }

  static GameServicesFailureCode _failureCodeFor(String rawCode) {
    final String code = rawCode.toLowerCase().replaceAll(
      RegExp('[^a-z0-9]'),
      '',
    );
    if (code.contains('cancel')) return GameServicesFailureCode.cancelled;
    if (code.contains('restrict')) return GameServicesFailureCode.restricted;
    if (code.contains('friend')) {
      return GameServicesFailureCode.friendsUnavailable;
    }
    if (code.contains('unauth') ||
        code.contains('authrequired') ||
        code.contains('notauthenticated') ||
        code.contains('signinrequired')) {
      return GameServicesFailureCode.unauthenticated;
    }
    if (code.contains('unsupported') ||
        code.contains('notimplemented') ||
        code.contains('missingplugin')) {
      return GameServicesFailureCode.unsupported;
    }
    if (code.contains('permanent') ||
        code.contains('invalidscore') ||
        code.contains('invalidconfiguration') ||
        code.contains('configuration')) {
      return GameServicesFailureCode.permanent;
    }
    return GameServicesFailureCode.retryable;
  }

  static void _validateArenaId(int arenaId) {
    if (arenaId < 1 || arenaId > 20) {
      throw const GameServicesException(GameServicesFailureCode.permanent);
    }
  }

  static PlatformIdentity _decodeIdentity(Object payload) {
    final Map<Object?, Object?> map = _asMap(payload);
    final GameServicePlatform platform = _decodePlatform(map['platform']);
    return PlatformIdentity(
      platform: platform,
      playerId: _requiredString(map, 'playerId'),
      displayName: _requiredString(map, 'displayName'),
      sessionToken: _requiredString(map, 'sessionToken'),
      avatar: _decodeOptionalAvatar(map, fallbackPlatform: platform),
    );
  }

  static Map<String, Object> _identityBinding(PlatformIdentity identity) {
    if (identity.playerId.isEmpty || identity.sessionToken.isEmpty) {
      throw const GameServicesException(
        GameServicesFailureCode.unauthenticated,
      );
    }
    return <String, Object>{
      'expectedPlayerId': identity.playerId,
      'identitySessionToken': identity.sessionToken,
    };
  }

  static LeaderboardPage _decodePage(Object? payload) {
    final Map<Object?, Object?> map = _asMap(payload);
    final Object? rawLeaders = map['leaders'];
    if (rawLeaders is! List<Object?>) {
      throw const FormatException('Invalid leaders');
    }
    final List<LeaderboardEntry> leaders = rawLeaders
        .map<LeaderboardEntry>(_decodeEntry)
        .take(kMaxLeaderboardRows)
        .toList(growable: false);
    final Object? rawCurrentPlayer = map['currentPlayer'];
    return LeaderboardPage(
      leaders: leaders,
      currentPlayer: rawCurrentPlayer == null
          ? null
          : _decodeEntry(rawCurrentPlayer),
    );
  }

  static LeaderboardEntry _decodeEntry(Object? payload) {
    final Map<Object?, Object?> map = _asMap(payload);
    return LeaderboardEntry(
      rank: _requiredInt(map, 'rank'),
      playerId: _requiredString(map, 'playerId'),
      displayName: _requiredString(map, 'displayName'),
      score: _requiredInt(map, 'score'),
      isCurrentPlayer: map['isCurrentPlayer'] as bool? ?? false,
      avatar: _decodeOptionalAvatar(map),
    );
  }

  static PlatformIdentityEvent _decodeIdentityEvent(Object? payload) {
    final Map<Object?, Object?> map = _asMap(payload);
    final int epoch = _requiredInt(map, 'epoch');
    final Object? rawIdentity = map['identity'];
    final PlatformIdentity? identity = rawIdentity == null
        ? null
        : _decodeIdentity(rawIdentity);
    return switch (_requiredString(map, 'kind')) {
      'authenticated' when identity != null =>
        PlatformIdentityEvent.authenticated(identity: identity, epoch: epoch),
      'signedOut' => PlatformIdentityEvent.signedOut(epoch: epoch),
      'accountChanged' => PlatformIdentityEvent.accountChanged(
        epoch: epoch,
        identity: identity,
      ),
      _ => throw const FormatException('Invalid identity event'),
    };
  }

  static PlatformAvatarRef? _decodeOptionalAvatar(
    Map<Object?, Object?> owner, {
    GameServicePlatform? fallbackPlatform,
  }) {
    final Object? nested = owner['avatar'];
    final Map<Object?, Object?>? map = nested == null
        ? (owner['avatarToken'] == null ? null : owner)
        : _asMap(nested);
    if (map == null) return null;
    final Object? rawPlatform = map['platform'];
    final GameServicePlatform platform = rawPlatform == null
        ? fallbackPlatform ?? (throw const FormatException('Missing platform'))
        : _decodePlatform(rawPlatform);
    return PlatformAvatarRef(
      platform: platform,
      identityEpoch: _requiredInt(map, 'identityEpoch'),
      playerHash: _requiredString(map, 'playerHash'),
      token: map['token'] == null
          ? _requiredString(map, 'avatarToken')
          : _requiredString(map, 'token'),
    );
  }

  static GameServicePlatform _decodePlatform(Object? rawPlatform) {
    final GameServicePlatform? platform = gameServicePlatformFromName(
      rawPlatform as String?,
    );
    if (platform == null) throw const FormatException('Invalid platform');
    return platform;
  }

  static Map<Object?, Object?> _asMap(Object? payload) {
    if (payload is! Map<Object?, Object?>) {
      throw const FormatException('Invalid channel payload');
    }
    return payload;
  }

  static String _requiredString(Map<Object?, Object?> map, String key) {
    final Object? value = map[key];
    if (value is! String || value.isEmpty) {
      throw FormatException('Invalid $key');
    }
    return value;
  }

  static int _requiredInt(Map<Object?, Object?> map, String key) {
    final Object? value = map[key];
    if (value is! int) throw FormatException('Invalid $key');
    return value;
  }
}
