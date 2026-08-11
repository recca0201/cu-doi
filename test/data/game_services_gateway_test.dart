import 'dart:async';

import 'package:ban_bua_tuong/core/leaderboard_limits.dart';
import 'package:ban_bua_tuong/data/game_services_gateway.dart';
import 'package:ban_bua_tuong/data/method_channel_game_services_gateway.dart';
import 'package:ban_bua_tuong/domain/leaderboard_models.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel(
    MethodChannelGameServicesGateway.channelName,
  );
  final List<MethodCall> calls = <MethodCall>[];
  const PlatformIdentity identity = PlatformIdentity(
    platform: GameServicePlatform.gameCenter,
    playerId: 'raw-player-id',
    displayName: 'Platform player',
    sessionToken: 'identity-session',
  );

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
          calls.add(call);
          return switch (call.method) {
            'restoreIdentity' => <String, Object?>{
              'platform': 'gameCenter',
              'playerId': 'raw-player-id',
              'sessionToken': 'identity-session',
              'displayName': 'Tên nền tảng',
            },
            'authenticate' => <String, Object?>{
              'platform': 'playGames',
              'playerId': 'another-raw-id',
              'sessionToken': 'another-session',
              'displayName': 'Platform Name',
            },
            'loadLeaderboard' => <String, Object?>{
              'leaders': <Object?>[
                <String, Object?>{
                  'rank': 7,
                  'playerId': 'row-id',
                  'displayName': 'Row name',
                  'score': 1200,
                  'isCurrentPlayer': true,
                  'avatar': <String, Object?>{
                    'platform': 'gameCenter',
                    'identityEpoch': 4,
                    'playerHash': 'row-hash',
                    'token': 'opaque-token',
                  },
                },
              ],
              'currentPlayer': null,
            },
            'loadAvatar' => Uint8List.fromList(<int>[1, 2, 3]),
            'submitScore' || 'validateConfiguration' => null,
            _ => throw MissingPluginException(),
          };
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'uses a versioned channel and distinct silent/interactive auth',
    () async {
      expect(MethodChannelGameServicesGateway.channelName, endsWith('/v1'));
      final MethodChannelGameServicesGateway gateway =
          MethodChannelGameServicesGateway(channel: channel);

      final PlatformIdentity? restored = await gateway.restoreIdentity();
      final PlatformIdentity silent = await gateway.authenticate(
        interactive: false,
      );
      final PlatformIdentity interactive = await gateway.authenticate(
        interactive: true,
      );

      expect(restored?.platform, GameServicePlatform.gameCenter);
      expect(silent.platform, GameServicePlatform.playGames);
      expect(interactive.displayName, 'Platform Name');
      expect(calls.map((MethodCall call) => call.method), <String>[
        'restoreIdentity',
        'authenticate',
        'authenticate',
      ]);
      expect(calls[0].arguments, isNull);
      expect(calls[1].arguments, <String, Object>{'interactive': false});
      expect(calls[2].arguments, <String, Object>{'interactive': true});
    },
  );

  test('sends arena IDs, scope and score but never a leaderboard ID', () async {
    final MethodChannelGameServicesGateway gateway =
        MethodChannelGameServicesGateway(channel: channel);

    final LeaderboardPage page = await gateway.loadLeaderboard(
      identity: identity,
      arenaId: 8,
      scope: LeaderboardScope.friends,
      limit: 100,
    );
    await gateway.submitScore(identity: identity, arenaId: 8, score: 1200);
    await gateway.validateConfiguration();

    expect(page.leaders, hasLength(1));
    expect(page.leaders.single.rank, 7);
    expect(page.leaders.single.avatar?.identityEpoch, 4);
    expect(calls[0].arguments, <String, Object>{
      'expectedPlayerId': 'raw-player-id',
      'identitySessionToken': 'identity-session',
      'arenaId': 8,
      'scope': 'friends',
      'limit': 100,
    });
    expect(calls[1].arguments, <String, Object>{
      'expectedPlayerId': 'raw-player-id',
      'identitySessionToken': 'identity-session',
      'arenaId': 8,
      'score': 1200,
    });
    for (final MethodCall call in calls) {
      expect(
        (call.arguments as Map?)?.containsKey('leaderboardId') ?? false,
        isFalse,
      );
    }
  });

  test('loads avatar through the opaque reference contract', () async {
    final MethodChannelGameServicesGateway gateway =
        MethodChannelGameServicesGateway(channel: channel);
    const PlatformAvatarRef avatar = PlatformAvatarRef(
      platform: GameServicePlatform.gameCenter,
      identityEpoch: 3,
      playerHash: 'player-hash',
      token: 'avatar-token',
    );

    expect(
      await gateway.loadAvatar(identity: identity, avatar: avatar),
      Uint8List.fromList(<int>[1, 2, 3]),
    );
    expect(calls.single.method, 'loadAvatar');
    expect(calls.single.arguments, <String, Object>{
      'expectedPlayerId': 'raw-player-id',
      'identitySessionToken': 'identity-session',
      'platform': 'gameCenter',
      'identityEpoch': 3,
      'playerHash': 'player-hash',
      'token': 'avatar-token',
    });
  });

  test('decodes identity events without presenting authentication', () async {
    final StreamController<Object?> events = StreamController<Object?>();
    addTearDown(events.close);
    final MethodChannelGameServicesGateway gateway =
        MethodChannelGameServicesGateway(
          channel: channel,
          identityEventStream: events.stream,
        );
    final Future<PlatformIdentityEvent> next = gateway.identityEvents.first;

    events.add(<String, Object?>{
      'kind': 'accountChanged',
      'epoch': 9,
      'identity': <String, Object?>{
        'platform': 'gameCenter',
        'playerId': 'new-id',
        'sessionToken': 'new-session',
        'displayName': 'New player',
      },
    });

    final PlatformIdentityEvent event = await next;
    expect(event.kind, PlatformIdentityEventKind.accountChanged);
    expect(event.epoch, 9);
    expect(event.identity?.playerId, 'new-id');
    expect(calls, isEmpty);
  });

  test('rejects a native identity that omits the session binding', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
          expect(call.method, 'restoreIdentity');
          return <String, Object?>{
            'platform': 'gameCenter',
            'playerId': 'raw-player-id',
            'displayName': 'Platform player',
          };
        });
    final MethodChannelGameServicesGateway gateway =
        MethodChannelGameServicesGateway(channel: channel);

    await expectLater(
      gateway.restoreIdentity(),
      throwsA(
        isA<GameServicesException>().having(
          (GameServicesException error) => error.code,
          'code',
          GameServicesFailureCode.retryable,
        ),
      ),
    );
  });

  test(
    'empty expected identity binding never reaches the native channel',
    () async {
      final MethodChannelGameServicesGateway gateway =
          MethodChannelGameServicesGateway(channel: channel);
      const PlatformIdentity invalid = PlatformIdentity(
        platform: GameServicePlatform.gameCenter,
        playerId: 'raw-player-id',
        displayName: 'Player',
        sessionToken: '',
      );

      await expectLater(
        gateway.submitScore(identity: invalid, arenaId: 1, score: 100),
        throwsA(
          isA<GameServicesException>().having(
            (GameServicesException error) => error.code,
            'code',
            GameServicesFailureCode.unauthenticated,
          ),
        ),
      );
      expect(calls, isEmpty);
    },
  );

  for (final MapEntry<String, GameServicesFailureCode> example
      in <String, GameServicesFailureCode>{
        'cancelled': GameServicesFailureCode.cancelled,
        'restricted': GameServicesFailureCode.restricted,
        'friends_unavailable': GameServicesFailureCode.friendsUnavailable,
        'unauthenticated': GameServicesFailureCode.unauthenticated,
        'retryable': GameServicesFailureCode.retryable,
        'permanent': GameServicesFailureCode.permanent,
        'unsupported': GameServicesFailureCode.unsupported,
      }.entries) {
    test(
      'normalizes ${example.key} without retaining platform details',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall _) async {
              throw PlatformException(
                code: example.key,
                message: 'secret display name and raw id',
                details: <String, Object>{'leaderboardId': 'raw-board-id'},
              );
            });
        final MethodChannelGameServicesGateway gateway =
            MethodChannelGameServicesGateway(channel: channel);

        final Object error = await gateway.restoreIdentity().then<Object>(
          (_) => fail('expected normalized failure'),
          onError: (Object error) => error,
        );

        expect(error, isA<GameServicesException>());
        expect((error as GameServicesException).code, example.value);
        expect(error.toString(), isNot(contains('secret display name')));
        expect(error.toString(), isNot(contains('raw-board-id')));
      },
    );
  }

  test('missing plugin is normalized as unsupported', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    final MethodChannelGameServicesGateway gateway =
        MethodChannelGameServicesGateway(channel: channel);

    await expectLater(
      gateway.restoreIdentity(),
      throwsA(
        isA<GameServicesException>().having(
          (GameServicesException error) => error.code,
          'code',
          GameServicesFailureCode.unsupported,
        ),
      ),
    );
  });

  test('uses the shared 10s, 8s and 5s production deadlines', () {
    final MethodChannelGameServicesGateway gateway =
        MethodChannelGameServicesGateway(channel: channel);

    expect(gateway.readTimeout, kLeaderboardReadTimeout);
    expect(gateway.submitTimeout, kLeaderboardSubmitTimeout);
    expect(gateway.avatarTimeout, kLeaderboardAvatarTimeout);
  });

  test('read, submit and avatar deadline expiry is retryable', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (MethodCall _) => Completer<Object?>().future,
        );
    final MethodChannelGameServicesGateway gateway =
        MethodChannelGameServicesGateway(
          channel: channel,
          readTimeout: const Duration(milliseconds: 1),
          submitTimeout: const Duration(milliseconds: 1),
          avatarTimeout: const Duration(milliseconds: 1),
        );
    const PlatformAvatarRef avatar = PlatformAvatarRef(
      platform: GameServicePlatform.playGames,
      identityEpoch: 1,
      playerHash: 'hash',
      token: 'token',
    );

    for (final Future<Object?> operation in <Future<Object?>>[
      gateway.loadLeaderboard(
        identity: identity,
        arenaId: 1,
        scope: LeaderboardScope.global,
        limit: 100,
      ),
      gateway.submitScore(identity: identity, arenaId: 1, score: 100),
      gateway.loadAvatar(identity: identity, avatar: avatar),
    ]) {
      await expectLater(
        operation,
        throwsA(
          isA<GameServicesException>().having(
            (GameServicesException error) => error.code,
            'code',
            GameServicesFailureCode.retryable,
          ),
        ),
      );
    }
  });
}
