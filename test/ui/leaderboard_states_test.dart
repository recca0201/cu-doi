import 'dart:ui' show SemanticsAction;

import 'package:ban_bua_tuong/domain/leaderboard_models.dart';
import 'package:ban_bua_tuong/state/leaderboard_controller.dart';
import 'package:ban_bua_tuong/ui/screens/leaderboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SemanticsNode;
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';

void main() {
  LeaderboardViewState state(
    LeaderboardViewStatus status, {
    LeaderboardScope scope = LeaderboardScope.global,
    LeaderboardPage? page,
    LeaderboardSnapshot? snapshot,
    SubmissionSummary? submissions,
    String? reasonCode,
  }) => LeaderboardViewState(
    arenaId: 12,
    scope: scope,
    status: status,
    page: page,
    snapshot: snapshot,
    reasonCode: reasonCode,
    submissionSummary: submissions ?? SubmissionSummary(),
  );

  Future<void> pumpState(
    WidgetTester tester,
    LeaderboardViewState viewState, {
    VoidCallback? onBack,
    ValueChanged<LeaderboardScope>? onScopeSelected,
    VoidCallback? onRetry,
    VoidCallback? onRetrySubmission,
    Future<bool> Function()? onAuthenticate,
    int? achievedScore,
    Size size = const Size(390, 844),
    TextScaler textScaler = TextScaler.noScaling,
  }) => pumpApp(
    tester,
    size: size,
    textScaler: textScaler,
    home: LeaderboardScreenView(
      state: viewState,
      arenaName: 'Leo thang',
      onBack: onBack ?? () {},
      onScopeSelected: onScopeSelected ?? (_) {},
      onRetry: onRetry,
      onAuthenticate: onAuthenticate,
      onRetrySubmission: onRetrySubmission,
      achievedScore: achievedScore,
    ),
  );

  testWidgets('loading is announced while Back and scope remain usable', (
    tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    int backs = 0;
    LeaderboardScope? selected;
    await pumpState(
      tester,
      state(LeaderboardViewStatus.loading),
      onBack: () => backs++,
      onScopeSelected: (LeaderboardScope value) => selected = value,
    );

    expect(find.byKey(const Key('leaderboard-state-loading')), findsOneWidget);
    expect(
      find.bySemanticsLabel('Đang tải bảng xếp hạng Màn 12'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('leaderboard-scope-friends')));
    await tester.tap(find.byKey(const Key('leaderboard-back')));
    expect(selected, LeaderboardScope.friends);
    expect(backs, 1);
    semantics.dispose();
  });

  testWidgets('empty and service error are specific and retry is explicit', (
    tester,
  ) async {
    await pumpState(tester, state(LeaderboardViewStatus.empty));
    expect(find.text('Chưa có điểm cho Màn 12'), findsOneWidget);
    expect(find.textContaining('người đầu tiên'), findsOneWidget);
    expect(find.text('0'), findsNothing);

    int retries = 0;
    await pumpState(
      tester,
      state(LeaderboardViewStatus.serviceError, reasonCode: 'retryable'),
      onRetry: () => retries++,
    );
    expect(
      find.byKey(const Key('leaderboard-state-service-error')),
      findsOneWidget,
    );
    expect(find.text('Không tải được bảng xếp hạng'), findsOneWidget);
    await tester.tap(find.byKey(const Key('leaderboard-retry')));
    expect(retries, 1);
  });

  testWidgets(
    'offline cache is visibly stale and no-cache never borrows rows',
    (tester) async {
      final LeaderboardSnapshot snapshot = LeaderboardSnapshot(
        rows: const <PersistedLeaderboardRow>[
          PersistedLeaderboardRow(
            rank: 1,
            playerHash: 'cached-one',
            displayName: 'Rồng cache',
            score: 125600,
            isCurrentPlayer: false,
          ),
        ],
        fetchedAt: DateTime.utc(2026, 8, 10),
      );
      await pumpState(
        tester,
        state(LeaderboardViewStatus.offlineCache, snapshot: snapshot),
        achievedScore: 42150,
      );
      expect(
        find.byKey(const Key('leaderboard-state-offline-cache')),
        findsOneWidget,
      );
      expect(find.text('Dữ liệu có thể đã cũ'), findsOneWidget);
      expect(find.text('Rồng cache'), findsOneWidget);
      expect(find.text('Đã gửi'), findsNothing);
      expect(find.text('Gửi điểm'), findsNothing);

      await pumpState(
        tester,
        state(
          LeaderboardViewStatus.offlineNoCache,
          scope: LeaderboardScope.friends,
        ),
      );
      expect(find.text('Không có dữ liệu offline'), findsOneWidget);
      expect(find.textContaining('Màn 12 · Bạn bè'), findsOneWidget);
      expect(find.text('Rồng cache'), findsNothing);
    },
  );

  testWidgets('friends unavailable explains fallback to Global', (
    tester,
  ) async {
    LeaderboardScope? selected;
    await pumpState(
      tester,
      state(
        LeaderboardViewStatus.friendsUnavailable,
        scope: LeaderboardScope.friends,
        reasonCode: 'restricted',
      ),
      onScopeSelected: (LeaderboardScope value) => selected = value,
    );
    expect(find.text('Không thể hiển thị bảng Bạn bè'), findsOneWidget);
    expect(find.textContaining('quyền riêng tư'), findsOneWidget);
    await tester.tap(find.byKey(const Key('leaderboard-view-global')));
    expect(selected, LeaderboardScope.global);
  });

  testWidgets('submission sent, pending, failed and unconnected are distinct', (
    tester,
  ) async {
    LeaderboardPage page() =>
        LeaderboardPage(leaders: const <LeaderboardEntry>[]);
    await pumpState(
      tester,
      state(LeaderboardViewStatus.loaded, page: page()),
      achievedScore: 42150,
    );
    expect(find.text('Chưa gửi'), findsOneWidget);
    expect(find.text('Đã gửi'), findsNothing);

    await pumpState(
      tester,
      state(
        LeaderboardViewStatus.loaded,
        page: page(),
        submissions: SubmissionSummary(
          receipts: const <SubmissionReceipt>[
            SubmissionReceipt(
              arenaId: 12,
              score: 42150,
              status: SubmissionAttemptStatus.accepted,
            ),
          ],
        ),
      ),
      achievedScore: 42150,
    );
    expect(find.text('Đã gửi'), findsOneWidget);
    expect(find.byKey(const Key('leaderboard-submit-retry')), findsNothing);

    const PendingScore pending = PendingScore(
      identityHash: 'mine',
      platform: GameServicePlatform.gameCenter,
      arenaId: 12,
      score: 42150,
    );
    await pumpState(
      tester,
      state(
        LeaderboardViewStatus.loaded,
        page: page(),
        submissions: SubmissionSummary(scores: const <PendingScore>[pending]),
      ),
      achievedScore: 42150,
    );
    expect(find.text('Đang chờ'), findsOneWidget);
    expect(find.textContaining('tự gửi khi có mạng'), findsOneWidget);
    expect(find.byKey(const Key('leaderboard-submit-retry')), findsNothing);

    int manualRetries = 0;
    final PendingScore failed = pending.copyWith(
      state: SubmissionState.permanentlyFailed,
      reasonCode: 'unsupported',
    );
    await pumpState(
      tester,
      state(
        LeaderboardViewStatus.loaded,
        page: page(),
        submissions: SubmissionSummary(scores: <PendingScore>[failed]),
      ),
      achievedScore: 42150,
      onRetrySubmission: () => manualRetries++,
    );
    expect(find.text('Không gửi được'), findsOneWidget);
    expect(find.textContaining('không hỗ trợ'), findsOneWidget);
    expect(find.text('unsupported'), findsNothing);
    await tester.tap(find.byKey(const Key('leaderboard-submit-retry')));
    expect(manualRetries, 1);

    await pumpState(
      tester,
      state(
        LeaderboardViewStatus.offlineNoCache,
        submissions: SubmissionSummary(scores: <PendingScore>[failed]),
      ),
      achievedScore: 42150,
      onRetrySubmission: () => manualRetries++,
    );
    expect(find.text('Không gửi được'), findsOneWidget);
    expect(find.byKey(const Key('leaderboard-submit-retry')), findsNothing);
    expect(find.byKey(const Key('leaderboard-submit-connect')), findsOneWidget);

    await pumpState(
      tester,
      state(LeaderboardViewStatus.authPrompt),
      achievedScore: 42150,
    );
    expect(find.text('Chưa kết nối'), findsOneWidget);
    expect(find.byKey(const Key('leaderboard-submit-retry')), findsNothing);
  });

  testWidgets(
    'live status does not exclude Back, Retry, Connect or manual send actions',
    (tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();

      await pumpState(
        tester,
        state(LeaderboardViewStatus.serviceError),
        onRetry: () {},
      );
      _expectTapAction(tester, const Key('leaderboard-back'));
      _expectTapAction(tester, const Key('leaderboard-retry'));

      await pumpState(
        tester,
        state(LeaderboardViewStatus.authPrompt),
        achievedScore: 42150,
        onAuthenticate: () async => true,
      );
      _expectTapAction(tester, const Key('leaderboard-auth-open'));
      _expectTapAction(tester, const Key('leaderboard-submit-connect'));

      final PendingScore failed =
          const PendingScore(
            identityHash: 'mine',
            platform: GameServicePlatform.gameCenter,
            arenaId: 12,
            score: 42150,
          ).copyWith(
            state: SubmissionState.permanentlyFailed,
            reasonCode: 'unsupported',
          );
      await pumpState(
        tester,
        state(
          LeaderboardViewStatus.loaded,
          page: LeaderboardPage(leaders: const <LeaderboardEntry>[]),
          submissions: SubmissionSummary(scores: <PendingScore>[failed]),
        ),
        achievedScore: 42150,
        onRetrySubmission: () {},
      );
      _expectTapAction(tester, const Key('leaderboard-submit-retry'));
      semantics.dispose();
    },
  );

  testWidgets('state-card live announcement is represented only once', (
    tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpState(tester, state(LeaderboardViewStatus.loading));

    expect(
      find.bySemanticsLabel('Đang tải bảng xếp hạng Màn 12'),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('state regions remain responsive on tablet and large text', (
    tester,
  ) async {
    for (final (Size size, TextScaler scaler) in <(Size, TextScaler)>[
      (const Size(800, 1100), TextScaler.noScaling),
      (const Size(390, 844), const TextScaler.linear(2)),
    ]) {
      await pumpState(
        tester,
        state(LeaderboardViewStatus.serviceError),
        size: size,
        textScaler: scaler,
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byKey(const Key('leaderboard-panel'))).width,
        lessThanOrEqualTo(440),
      );
      expect(
        tester.getSize(find.byKey(const Key('leaderboard-retry'))).height,
        greaterThanOrEqualTo(48),
      );
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}

void _expectTapAction(WidgetTester tester, Key key) {
  final SemanticsNode node = tester.getSemantics(find.byKey(key));
  expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
}
