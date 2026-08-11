import 'package:ban_bua_tuong/domain/leaderboard_models.dart';
import 'package:ban_bua_tuong/state/leaderboard_controller.dart';
import 'package:ban_bua_tuong/ui/screens/leaderboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';

void main() {
  LeaderboardEntry entry(
    int rank, {
    String? id,
    String? name,
    int? score,
    bool current = false,
  }) => LeaderboardEntry(
    rank: rank,
    playerId: id ?? 'player-$rank',
    displayName: name ?? 'Người chơi $rank',
    score: score ?? (200000 - rank * 100),
    isCurrentPlayer: current,
  );

  LeaderboardViewState loaded({
    required List<LeaderboardEntry> leaders,
    LeaderboardEntry? currentPlayer,
    LeaderboardScope scope = LeaderboardScope.global,
  }) => LeaderboardViewState(
    arenaId: 12,
    scope: scope,
    status: LeaderboardViewStatus.loaded,
    page: LeaderboardPage(leaders: leaders, currentPlayer: currentPlayer),
    submissionSummary: SubmissionSummary(),
  );

  Future<void> pumpLoaded(
    WidgetTester tester,
    LeaderboardViewState state, {
    Size size = const Size(390, 844),
    TextScaler textScaler = TextScaler.noScaling,
    Locale locale = const Locale('vi'),
  }) => pumpApp(
    tester,
    size: size,
    textScaler: textScaler,
    locale: locale,
    home: LeaderboardScreenView(
      state: state,
      arenaName: locale.languageCode == 'en' ? 'Climb Up' : 'Leo thang',
      onBack: () {},
      onScopeSelected: (_) {},
    ),
  );

  testWidgets('caps leaders at 100 and renders outside current player once', (
    tester,
  ) async {
    final List<LeaderboardEntry> leaders = List<LeaderboardEntry>.generate(
      101,
      (int index) => entry(index + 1),
    );
    final LeaderboardEntry mine = entry(
      127,
      id: 'mine',
      name: 'Người chơi',
      score: 8400,
      current: true,
    );

    await pumpLoaded(tester, loaded(leaders: leaders, currentPlayer: mine));

    expect(
      find.byKey(const ValueKey<String>('leaderboard-entry-player-100')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('leaderboard-entry-player-101')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('leaderboard-entry-mine')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('leaderboard-current-player')), findsOneWidget);
    expect(find.text('Bạn đang ngoài top 100'), findsOneWidget);
  });

  testWidgets('current player inside top 100 is never appended again', (
    tester,
  ) async {
    final LeaderboardEntry mine = entry(7, id: 'mine', name: 'CúDộiMaster');
    await pumpLoaded(
      tester,
      loaded(
        leaders: <LeaderboardEntry>[entry(1), entry(2), entry(3), mine],
        currentPlayer: mine,
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('leaderboard-entry-mine')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('leaderboard-current-player')), findsOneWidget);
    expect(find.text('Bạn đang ngoài top 100'), findsNothing);
  });

  testWidgets('platform-provided ties remain distinct and authoritative', (
    tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpLoaded(
      tester,
      loaded(
        leaders: <LeaderboardEntry>[
          entry(1, id: 'tie-a', name: 'Đồng hạng A', score: 125600),
          entry(1, id: 'tie-b', name: 'Đồng hạng B', score: 125600),
          entry(3, id: 'third', name: 'Hạng ba', score: 90000),
        ],
      ),
    );

    expect(
      find.bySemanticsLabel('Hạng 1, Đồng hạng A, 125.600 điểm'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Hạng 1, Đồng hạng B, 125.600 điểm'),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets(
    'podium, neutral avatar, two-line name and tabular score render',
    (tester) async {
      const String longName =
          'Tên người chơi nền tảng rất dài nhưng vẫn chỉ có hai dòng';
      await pumpLoaded(
        tester,
        loaded(
          leaders: <LeaderboardEntry>[
            entry(1, name: 'RồngThép', score: 125600),
            entry(2, name: 'LinhNhi', score: 98750),
            entry(3, name: 'ChơiCúDội', score: 76300),
            entry(4, name: longName, score: 62400),
          ],
        ),
      );

      expect(find.byKey(const Key('leaderboard-podium')), findsOneWidget);
      expect(
        find.byKey(
          const ValueKey<String>('leaderboard-avatar-fallback-player-4'),
        ),
        findsOneWidget,
      );
      final Text name = tester.widget<Text>(find.text(longName));
      expect(name.maxLines, 2);
      expect(name.overflow, TextOverflow.ellipsis);
      final Text score = tester.widget<Text>(find.text('62.400'));
      expect(
        score.style!.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
    },
  );

  testWidgets('scope and row semantics carry non-color cues in reading order', (
    tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpLoaded(
      tester,
      loaded(
        leaders: <LeaderboardEntry>[
          entry(1, name: 'RồngThép', score: 125600),
          entry(2),
          entry(3),
          entry(4, name: 'ThangLaoCao', score: 62400),
        ],
      ),
    );

    final Finder global = find.byKey(const Key('leaderboard-scope-global'));
    final Finder friends = find.byKey(const Key('leaderboard-scope-friends'));
    final Finder back = find.byKey(const Key('leaderboard-back'));
    expect(tester.getSize(global).height, greaterThanOrEqualTo(48));
    expect(tester.getSize(friends).height, greaterThanOrEqualTo(48));
    expect(tester.getSize(back).height, greaterThanOrEqualTo(48));
    expect(find.bySemanticsLabel('Toàn cầu, đã chọn'), findsOneWidget);
    expect(find.bySemanticsLabel('Bạn bè, chưa chọn'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Hạng 4, ThangLaoCao, 62.400 điểm'),
      findsOneWidget,
    );
    expect(find.text('Mọi thời đại'), findsOneWidget);
    expect(find.textContaining('Ngày'), findsNothing);
    expect(find.textContaining('Tuần'), findsNothing);
    semantics.dispose();
  });

  testWidgets('loaded and scope live regions are localized in VI and EN', (
    tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    final LeaderboardViewState state = loaded(
      leaders: <LeaderboardEntry>[
        entry(1, name: 'RồngThép', score: 125600),
        entry(2),
        entry(3),
        entry(4, name: 'ThangLaoCao', score: 62400),
      ],
    );

    await pumpLoaded(tester, state);
    expect(
      find.bySemanticsLabel('Đã tải bảng Toàn cầu cho Màn 12'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Hạng 4, ThangLaoCao, 62.400 điểm'),
      findsOneWidget,
    );

    await pumpLoaded(tester, state, locale: const Locale('en'));
    expect(
      find.bySemanticsLabel('Global leaderboard loaded for Level 12'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Rank 4, ThangLaoCao, 62,400 points'),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets(
    'error and offline state announcements are localized live regions',
    (tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();

      await pumpApp(
        tester,
        home: LeaderboardScreenView(
          state: LeaderboardViewState(
            arenaId: 12,
            scope: LeaderboardScope.global,
            status: LeaderboardViewStatus.serviceError,
            submissionSummary: SubmissionSummary(),
          ),
          arenaName: 'Leo thang',
          onBack: () {},
          onScopeSelected: (_) {},
        ),
      );
      final Finder error = find.bySemanticsLabel(
        'Không tải được bảng xếp hạng. '
        'Game Center/Google Play Games tạm thời không phản hồi.',
      );
      expect(error, findsOneWidget);
      expect(tester.getSemantics(error).flagsCollection.isLiveRegion, isTrue);

      await pumpApp(
        tester,
        locale: const Locale('en'),
        home: LeaderboardScreenView(
          state: LeaderboardViewState(
            arenaId: 12,
            scope: LeaderboardScope.friends,
            status: LeaderboardViewStatus.offlineNoCache,
            submissionSummary: SubmissionSummary(),
          ),
          arenaName: 'Climb Up',
          onBack: () {},
          onScopeSelected: (_) {},
        ),
      );
      final Finder offline = find.bySemanticsLabel(
        'No offline data. There is no matching saved leaderboard for '
        'Level 12 · Friends.',
      );
      expect(offline, findsOneWidget);
      expect(tester.getSemantics(offline).flagsCollection.isLiveRegion, isTrue);
      semantics.dispose();
    },
  );

  testWidgets('phone, tablet, English and large text layouts do not overflow', (
    tester,
  ) async {
    final LeaderboardViewState state = loaded(
      leaders: <LeaderboardEntry>[
        entry(1, name: 'RồngThép', score: 125600),
        entry(2),
        entry(3),
        entry(4, name: 'A platform display name that is deliberately long'),
      ],
    );

    for (final (Size size, TextScaler scaler, Locale locale)
        in <(Size, TextScaler, Locale)>[
          (const Size(390, 844), TextScaler.noScaling, const Locale('vi')),
          (const Size(800, 1100), TextScaler.noScaling, const Locale('vi')),
          (
            const Size(390, 844),
            const TextScaler.linear(2),
            const Locale('en'),
          ),
        ]) {
      await pumpLoaded(
        tester,
        state,
        size: size,
        textScaler: scaler,
        locale: locale,
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byKey(const Key('leaderboard-panel'))).width,
        lessThanOrEqualTo(440),
      );
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}
