import 'dart:math' as math;

import 'package:ban_bua_tuong/data/game_services_gateway.dart';
import 'package:ban_bua_tuong/data/identity_hasher.dart';
import 'package:ban_bua_tuong/data/leaderboard_repository.dart';
import 'package:ban_bua_tuong/data/local_leaderboard_store.dart';
import 'package:ban_bua_tuong/data/progress_repository.dart';
import 'package:ban_bua_tuong/domain/leaderboard_models.dart';
import 'package:ban_bua_tuong/domain/player_progress.dart';
import 'package:ban_bua_tuong/l10n/app_localizations.dart';
import 'package:ban_bua_tuong/sim/arena.dart';
import 'package:ban_bua_tuong/sim/geometry.dart';
import 'package:ban_bua_tuong/state/leaderboard_controller.dart';
import 'package:ban_bua_tuong/state/providers.dart';
import 'package:ban_bua_tuong/ui/fit.dart';
import 'package:ban_bua_tuong/ui/screens/game_screen.dart';
import 'package:ban_bua_tuong/ui/screens/leaderboard_screen.dart';
import 'package:ban_bua_tuong/ui/screens/menu_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/support/fake_game_services_gateway.dart';
import '../test/support/pump_app.dart';

const PlatformIdentity _playerA = PlatformIdentity(
  platform: GameServicePlatform.playGames,
  playerId: 'platform-player-a',
  displayName: 'Player A',
  sessionToken: 'session-a',
);

const PlatformIdentity _playerB = PlatformIdentity(
  platform: GameServicePlatform.playGames,
  playerId: 'platform-player-b',
  displayName: 'Player B',
  sessionToken: 'session-b',
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'menu -> explicit auth -> loaded -> scope -> offline cache -> retry',
    (WidgetTester tester) async {
      bool offline = false;
      int globalLoads = 0;
      final FakeGameServicesGateway gateway = FakeGameServicesGateway(
        authenticatedIdentity: _playerA,
      );
      addTearDown(gateway.dispose);
      gateway.loadHandler = (int arenaId, LeaderboardScope scope, int limit) {
        expect(arenaId, 1);
        expect(limit, 100);
        if (offline) {
          throw const GameServicesException(GameServicesFailureCode.retryable);
        }
        if (scope == LeaderboardScope.friends) {
          return Future<LeaderboardPage>.value(
            LeaderboardPage(
              leaders: <LeaderboardEntry>[
                _entry(
                  rank: 1,
                  playerId: 'friend-a',
                  displayName: 'Bạn Đồng Đội',
                  score: 900,
                ),
              ],
            ),
          );
        }
        globalLoads++;
        return Future<LeaderboardPage>.value(
          LeaderboardPage(
            leaders: <LeaderboardEntry>[
              _entry(
                rank: 1,
                playerId: _playerA.playerId,
                displayName: globalLoads == 1
                    ? 'Thủ Lĩnh Toàn Cầu'
                    : 'Thủ Lĩnh Đã Làm Mới',
                score: globalLoads == 1 ? 1200 : 1400,
              ),
            ],
          ),
        );
      };

      await pumpApp(
        tester,
        home: const MenuScreen(),
        overrides: <Override>[
          gameServicesGatewayProvider.overrideWithValue(gateway),
        ],
      );

      expect(gateway.authenticateArguments, isEmpty);
      expect(gateway.loadCalls, isEmpty);
      await tester.tap(find.byKey(const Key('menu-leaderboard')));
      await _pumpUntil(
        tester,
        () => find
            .byKey(const Key('leaderboard-state-auth-prompt'))
            .evaluate()
            .isNotEmpty,
      );
      expect(find.byType(LeaderboardScreen), findsOneWidget);
      expect(gateway.authenticateArguments, isEmpty);
      expect(gateway.loadCalls, isEmpty);

      await tester.tap(find.byKey(const Key('leaderboard-auth-open')));
      await tester.pumpAndSettle();
      expect(gateway.authenticateArguments, isEmpty);
      await tester.tap(find.byKey(const Key('leaderboard-auth-confirm')));
      await _pumpUntil(
        tester,
        () => find.text('Thủ Lĩnh Toàn Cầu').evaluate().isNotEmpty,
      );

      expect(gateway.authenticateArguments, <bool>[true]);
      expect(find.text('Thủ Lĩnh Toàn Cầu'), findsOneWidget);
      expect(gateway.loadCalls.last, (
        arenaId: 1,
        scope: LeaderboardScope.global,
        limit: 100,
      ));

      await tester.tap(find.byKey(const Key('leaderboard-scope-friends')));
      await _pumpUntil(
        tester,
        () => find.text('Bạn Đồng Đội').evaluate().isNotEmpty,
      );
      expect(find.text('Bạn Đồng Đội'), findsOneWidget);
      expect(gateway.loadCalls.last, (
        arenaId: 1,
        scope: LeaderboardScope.friends,
        limit: 100,
      ));

      offline = true;
      await tester.tap(find.byKey(const Key('leaderboard-scope-global')));
      await _pumpUntil(
        tester,
        () => find
            .byKey(const Key('leaderboard-state-offline-cache'))
            .evaluate()
            .isNotEmpty,
      );
      expect(find.text('Thủ Lĩnh Toàn Cầu'), findsOneWidget);
      expect(find.text('Bạn Đồng Đội'), findsNothing);

      offline = false;
      await tester.tap(find.byKey(const Key('leaderboard-retry')));
      await _pumpUntil(
        tester,
        () => find.text('Thủ Lĩnh Đã Làm Mới').evaluate().isNotEmpty,
      );
      expect(
        find.byKey(const Key('leaderboard-state-offline-cache')),
        findsNothing,
      );

      await tester.tap(find.byKey(const Key('leaderboard-back')));
      await tester.pumpAndSettle();
      expect(find.byType(MenuScreen), findsOneWidget);
      expect(find.byKey(const Key('menu-leaderboard')), findsOneWidget);
    },
  );

  testWidgets('winning saves locally, queues, then removes an accepted score', (
    WidgetTester tester,
  ) async {
    // Device integration tests use the real audio plugin unless settings are
    // explicitly disabled. Audio is unrelated to this flow and can leave a
    // native position callback alive after the widget tree is torn down.
    SharedPreferences.setMockInitialValues(<String, Object>{
      'soundOn': false,
      'musicOn': false,
      'hapticsOn': false,
      'localeCode': 'vi',
    });
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final FakeGameServicesGateway gateway = FakeGameServicesGateway(
      restoredIdentity: _playerA,
    );
    addTearDown(gateway.dispose);
    final _TrackingProgressRepository progress = _TrackingProgressRepository(
      gateway.callLog,
    );
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(preferences),
        progressRepositoryProvider.overrideWithValue(progress),
        gameServicesGatewayProvider.overrideWithValue(gateway),
      ],
    );
    addTearDown(container.dispose);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: _EagerLeaderboardOwner(child: GameScreen(arenaId: 1)),
        ),
      ),
    );
    await _pumpUntil(
      tester,
      () =>
          container.read(leaderboardRepositoryProvider).identityState.maySubmit,
    );

    await _shoot(tester, -45.5694444444);
    await _shoot(tester, -46.75);
    await _pumpUntil(tester, () => gateway.submitCalls.isNotEmpty);

    expect(find.byKey(const Key('result-win-title')), findsOneWidget);
    expect(progress.saves, 1);
    expect(progress.value.isCompleted(1), isTrue);
    expect(gateway.submitCalls, hasLength(1));
    expect(gateway.submitCalls.single.arenaId, 1);
    expect(gateway.submitCalls.single.score, progress.value.highScoreFor(1));
    expect(
      gateway.callLog.indexOf('local-save'),
      lessThan(
        gateway.callLog.indexOf('submit:1:${progress.value.highScoreFor(1)}'),
      ),
    );
    expect(container.read(leaderboardSubmissionProvider).scores, isEmpty);
  });

  test(
    'pending survives restart; permanent/manual retry, revoke and switch stay partitioned',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      final FakeGameServicesGateway gateway = FakeGameServicesGateway();
      addTearDown(gateway.dispose);
      final LocalLeaderboardStore firstStore = LocalLeaderboardStore(
        preferences,
      );
      final IdentityHasher firstHasher = IdentityHasher(preferences);
      final PlayerProgress progress = const PlayerProgress()
          .withResult(1, 1, 500)
          .withResult(2, 1, 600)
          .withResult(3, 1, 700);
      bool retryable = true;
      bool permanent = false;
      bool revoked = false;
      gateway.submitHandler = (int arenaId, int score) async {
        if (arenaId == 1 && retryable) {
          throw const GameServicesException(GameServicesFailureCode.retryable);
        }
        if (arenaId == 2 && permanent) {
          throw const GameServicesException(GameServicesFailureCode.permanent);
        }
        if (arenaId == 3 && revoked) {
          throw const GameServicesException(
            GameServicesFailureCode.unauthenticated,
          );
        }
      };

      final LeaderboardRepository first = _repository(
        gateway: gateway,
        store: firstStore,
        hasher: firstHasher,
        identity: _playerA,
        epoch: 1,
      );
      await first.enqueueNewHighScore(
        arenaId: 1,
        score: 500,
        progress: progress,
      );
      expect((await first.flushEligibleSubmissions()).pendingCount, 1);

      // Simulate a process restart: new repository, store and hasher objects
      // share only the durable application preferences.
      retryable = false;
      gateway.restoredIdentity = _playerA;
      final LocalLeaderboardStore restartedStore = LocalLeaderboardStore(
        preferences,
      );
      final IdentityHasher restartedHasher = IdentityHasher(preferences);
      final LeaderboardRepository restarted = LeaderboardRepository(
        gateway: gateway,
        store: restartedStore,
        identityHasher: restartedHasher,
      );
      await restarted.restoreIdentity();
      expect(restarted.identityState.identity, _playerA);
      expect((await restarted.flushEligibleSubmissions()).scores, isEmpty);
      expect(
        gateway.submitCalls.where(
          (call) => call.arenaId == 1 && call.score == 500,
        ),
        hasLength(2),
      );

      permanent = true;
      await restarted.enqueueNewHighScore(
        arenaId: 2,
        score: 600,
        progress: progress,
      );
      final SubmissionSummary rejected = await restarted
          .flushEligibleSubmissions();
      expect(rejected.forArena(2)!.state, SubmissionState.permanentlyFailed);
      expect(rejected.forArena(2)!.reasonCode, 'permanent');
      final int permanentAttempts = gateway.submitCalls
          .where((call) => call.arenaId == 2)
          .length;
      await restarted.flushEligibleSubmissions();
      expect(
        gateway.submitCalls.where((call) => call.arenaId == 2),
        hasLength(permanentAttempts),
      );

      permanent = false;
      final LeaderboardSubmissionController submissions =
          LeaderboardSubmissionController(restarted);
      await submissions.refresh();
      await submissions.retryFailed(2);
      expect(submissions.state.forArena(2), isNull);
      expect(
        gateway.submitCalls.where((call) => call.arenaId == 2),
        hasLength(permanentAttempts + 1),
      );

      gateway.loadHandler = (_, _, _) async => LeaderboardPage(
        leaders: <LeaderboardEntry>[
          _entry(
            rank: 1,
            playerId: _playerA.playerId,
            displayName: 'Cache chỉ của A',
            score: 700,
          ),
        ],
      );
      expect(
        (await restarted.load(
          arenaId: 3,
          scope: LeaderboardScope.global,
          allowMatchingCache: true,
        )).status,
        LeaderboardLoadStatus.fresh,
      );

      revoked = true;
      await restarted.enqueueNewHighScore(
        arenaId: 3,
        score: 700,
        progress: progress,
      );
      final SubmissionSummary afterRevoke = await restarted
          .flushEligibleSubmissions();
      // Native rejection invalidates the live account synchronously, so the
      // old account's durable queue must not remain visible in the UI summary.
      expect(afterRevoke.forArena(3), isNull);
      expect(restarted.identityState.confidence, IdentityConfidence.changed);
      final int revokedAttempts = gateway.submitCalls
          .where((call) => call.arenaId == 3)
          .length;
      await restarted.flushEligibleSubmissions();
      expect(
        gateway.submitCalls.where((call) => call.arenaId == 3),
        hasLength(revokedAttempts),
      );
      expect(gateway.authenticateArguments, isEmpty);

      restarted.handleIdentityEvent(
        const PlatformIdentityEvent.accountChanged(
          epoch: 2,
          identity: _playerB,
        ),
      );
      final LeaderboardLoadResult beforeExplicitAuth = await restarted.load(
        arenaId: 3,
        scope: LeaderboardScope.global,
        allowMatchingCache: true,
      );
      expect(beforeExplicitAuth.status, LeaderboardLoadStatus.authRequired);
      expect(beforeExplicitAuth.snapshot, isNull);

      gateway.authenticatedIdentity = _playerB;
      await restarted.authenticateFromUserAction();
      bool bOffline = true;
      gateway.loadHandler = (_, _, _) async {
        if (bOffline) {
          throw const GameServicesException(GameServicesFailureCode.retryable);
        }
        return LeaderboardPage(
          leaders: <LeaderboardEntry>[
            _entry(
              rank: 1,
              playerId: _playerB.playerId,
              displayName: 'B mới',
              score: 800,
            ),
          ],
        );
      };
      final LeaderboardLoadResult bWithoutCache = await restarted.load(
        arenaId: 3,
        scope: LeaderboardScope.global,
        allowMatchingCache: true,
      );
      expect(bWithoutCache.status, LeaderboardLoadStatus.serviceError);
      expect(bWithoutCache.snapshot, isNull);

      bOffline = false;
      final LeaderboardLoadResult bFresh = await restarted.load(
        arenaId: 3,
        scope: LeaderboardScope.global,
        allowMatchingCache: true,
      );
      expect(bFresh.status, LeaderboardLoadStatus.fresh);
      expect(bFresh.page!.leaders.single.displayName, 'B mới');
      expect((await restarted.currentSubmissionSummary()).scores, isEmpty);
      await restarted.flushEligibleSubmissions();
      expect(
        gateway.submitCalls.where((call) => call.arenaId == 3),
        hasLength(revokedAttempts),
      );

      await restartedHasher.initialize();
      final IdentityKey oldPartition = IdentityKey(
        platform: _playerA.platform,
        identityHash: restartedHasher.hashPlayerId(_playerA.playerId),
      );
      expect(
        (await restartedStore.loadSubmissions(oldPartition)).single.arenaId,
        3,
      );
    },
  );
}

LeaderboardEntry _entry({
  required int rank,
  required String playerId,
  required String displayName,
  required int score,
}) => LeaderboardEntry(
  rank: rank,
  playerId: playerId,
  displayName: displayName,
  score: score,
  isCurrentPlayer: false,
);

LeaderboardRepository _repository({
  required FakeGameServicesGateway gateway,
  required LocalLeaderboardStore store,
  required IdentityHasher hasher,
  required PlatformIdentity identity,
  required int epoch,
}) => LeaderboardRepository(
  gateway: gateway,
  store: store,
  identityHasher: hasher,
  initialIdentityState: PlatformIdentityState(
    confidence: IdentityConfidence.confirmedCurrent,
    epoch: epoch,
    identity: identity,
  ),
);

class _TrackingProgressRepository implements ProgressRepository {
  _TrackingProgressRepository(this.events);

  final List<String> events;
  PlayerProgress value = const PlayerProgress();
  int saves = 0;

  @override
  Future<PlayerProgress> load() async => value;

  @override
  Future<bool> save(PlayerProgress progress) async {
    events.add('local-save');
    saves++;
    value = progress;
    return true;
  }
}

class _EagerLeaderboardOwner extends ConsumerWidget {
  const _EagerLeaderboardOwner({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(leaderboardLifecycleCoordinatorProvider);
    return child;
  }
}

Future<void> _shoot(WidgetTester tester, double degrees) async {
  final Finder arena = find.byKey(const Key('game-arena-input'));
  final Size size = tester.getSize(arena);
  final ArenaFit fit = ArenaFit.of(size);
  final double radians = degrees * math.pi / 180;
  final V2 direction = V2(math.sin(radians), -math.cos(radians));
  final Offset local = fit.toScreen(kShooterOrigin + direction * 60);
  await tester.tapAt(tester.getTopLeft(arena) + local);
  for (int index = 0; index < 120; index++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (find.byKey(const Key('result-win-title')).evaluate().isNotEmpty) {
      return;
    }
  }
}

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  int attempts = 150,
}) async {
  for (int index = 0; index < attempts && !condition(); index++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
  expect(condition(), isTrue);
}
