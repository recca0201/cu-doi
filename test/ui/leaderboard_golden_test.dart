import 'package:ban_bua_tuong/domain/leaderboard_models.dart';
import 'package:ban_bua_tuong/state/leaderboard_controller.dart';
import 'package:ban_bua_tuong/ui/screens/leaderboard_screen.dart';
import 'package:ban_bua_tuong/ui/widgets/bb_backdrop.dart';
import 'package:ban_bua_tuong/ui/widgets/leaderboard_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';

bool _materialIconsLoaded = false;

Future<void> _loadMaterialIcons() async {
  if (_materialIconsLoaded) return;
  await (FontLoader(
    'MaterialIcons',
  )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  _materialIconsLoaded = true;
}

void main() {
  LeaderboardEntry entry(
    int rank,
    String name,
    int score, {
    bool current = false,
  }) => LeaderboardEntry(
    rank: rank,
    playerId: current ? 'mine' : 'player-$rank',
    displayName: name,
    score: score,
    isCurrentPlayer: current,
  );

  LeaderboardViewState state(
    LeaderboardViewStatus status, {
    LeaderboardPage? page,
    LeaderboardSnapshot? snapshot,
  }) => LeaderboardViewState(
    arenaId: 12,
    scope: LeaderboardScope.global,
    status: status,
    page: page,
    snapshot: snapshot,
    submissionSummary: SubmissionSummary(),
  );

  final LeaderboardPage loadedPage = LeaderboardPage(
    leaders: <LeaderboardEntry>[
      entry(1, 'RồngThép', 125600),
      entry(2, 'LinhNhi', 98750),
      entry(3, 'ChơiCúDội', 76300),
      entry(4, 'ThangLaoCao', 62400),
      entry(5, 'AnhBaPhải', 54210),
      entry(6, 'Mạnh Mẽ Lên', 47890),
      entry(7, 'CúDộiMaster', 42150),
      entry(8, 'Người Chơi Ẩn Danh', 36820),
    ],
    currentPlayer: entry(127, 'Người chơi', 8400, current: true),
  );

  final LeaderboardSnapshot offlineSnapshot = LeaderboardSnapshot(
    rows: const <PersistedLeaderboardRow>[
      PersistedLeaderboardRow(
        rank: 1,
        playerHash: 'cached-dragon',
        displayName: 'RồngThép',
        score: 125600,
        isCurrentPlayer: false,
      ),
      PersistedLeaderboardRow(
        rank: 2,
        playerHash: 'cached-linh',
        displayName: 'LinhNhi',
        score: 98750,
        isCurrentPlayer: false,
      ),
      PersistedLeaderboardRow(
        rank: 3,
        playerHash: 'cached-doi',
        displayName: 'ChơiCúDội',
        score: 76300,
        isCurrentPlayer: false,
      ),
    ],
    fetchedAt: DateTime.utc(2026, 8, 10),
  );

  Future<void> expectGolden(
    WidgetTester tester, {
    required String name,
    required LeaderboardViewState viewState,
    bool showAuthDialog = false,
  }) async {
    await _loadMaterialIcons();
    final Key boundaryKey = ValueKey<String>('leaderboard-golden-$name');
    await pumpApp(
      tester,
      size: const Size(390, 844),
      home: RepaintBoundary(
        key: boundaryKey,
        child: TickerMode(
          enabled: false,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              LeaderboardScreenView(
                state: viewState,
                arenaName: 'Leo thang',
                onBack: () {},
                onScopeSelected: (_) {},
                onRetry: () {},
              ),
              if (showAuthDialog) ...<Widget>[
                const ModalBarrier(
                  dismissible: false,
                  color: Color(0xC4000000),
                ),
                LeaderboardAuthDialog(onConnect: () {}, onLater: () {}),
              ],
            ],
          ),
        ),
      ),
    );
    final BuildContext context = tester.element(
      find.byType(LeaderboardScreenView),
    );
    await tester.runAsync(
      () => precacheImage(const AssetImage(kVietnamKarstBackdrop), context),
    );
    await tester.pump();
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/leaderboard_${name}_390x844.png'),
    );
  }

  testWidgets('loaded karst leaderboard', (WidgetTester tester) async {
    await expectGolden(
      tester,
      name: 'loaded',
      viewState: state(LeaderboardViewStatus.loaded, page: loadedPage),
    );
  });

  testWidgets('loading karst leaderboard', (WidgetTester tester) async {
    await expectGolden(
      tester,
      name: 'loading',
      viewState: state(LeaderboardViewStatus.loading),
    );
  });

  testWidgets('offline karst leaderboard', (WidgetTester tester) async {
    await expectGolden(
      tester,
      name: 'offline',
      viewState: state(
        LeaderboardViewStatus.offlineCache,
        snapshot: offlineSnapshot,
      ),
    );
  });

  testWidgets('service-error karst leaderboard', (WidgetTester tester) async {
    await expectGolden(
      tester,
      name: 'error',
      viewState: state(LeaderboardViewStatus.serviceError),
    );
  });

  testWidgets('auth karst leaderboard', (WidgetTester tester) async {
    await expectGolden(
      tester,
      name: 'auth',
      viewState: state(LeaderboardViewStatus.authPrompt),
      showAuthDialog: true,
    );
  });
}
