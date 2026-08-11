import 'package:ban_bua_tuong/domain/leaderboard_models.dart';
import 'package:ban_bua_tuong/l10n/app_localizations.dart';
import 'package:ban_bua_tuong/state/leaderboard_controller.dart';
import 'package:ban_bua_tuong/ui/screens/leaderboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';

void main() {
  LeaderboardViewState authState() => LeaderboardViewState(
    arenaId: 12,
    scope: LeaderboardScope.global,
    status: LeaderboardViewStatus.authPrompt,
    submissionSummary: SubmissionSummary(),
  );

  Future<void> pumpAuth(
    WidgetTester tester, {
    required Future<bool> Function() onAuthenticate,
    required VoidCallback onAuthDismissed,
    VoidCallback? onBack,
  }) => pumpApp(
    tester,
    home: LeaderboardScreenView(
      state: authState(),
      arenaName: 'Leo thang',
      onBack: onBack ?? () {},
      onScopeSelected: (_) {},
      onAuthenticate: onAuthenticate,
      onAuthDismissed: onAuthDismissed,
    ),
  );

  testWidgets('platform authentication starts only after explanatory action', (
    tester,
  ) async {
    int authCalls = 0;
    int dismissed = 0;
    await pumpAuth(
      tester,
      onAuthenticate: () async {
        authCalls++;
        return false;
      },
      onAuthDismissed: () => dismissed++,
    );
    expect(authCalls, 0);

    await tester.tap(find.byKey(const Key('leaderboard-auth-open')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('leaderboard-auth-dialog')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('leaderboard-auth-dialog')),
        matching: find.text('Kết nối bảng xếp hạng?'),
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('vẫn có thể chơi hoàn toàn offline'),
      findsOneWidget,
    );
    expect(authCalls, 0);

    await tester.tap(find.byKey(const Key('leaderboard-auth-confirm')));
    await tester.pumpAndSettle();
    expect(authCalls, 1);
    expect(dismissed, 1);
    expect(find.byKey(const Key('leaderboard-auth-dialog')), findsNothing);
  });

  testWidgets(
    'Later is explicit, preserves state and never calls platform UI',
    (tester) async {
      int authCalls = 0;
      int dismissed = 0;
      await pumpAuth(
        tester,
        onAuthenticate: () async {
          authCalls++;
          return true;
        },
        onAuthDismissed: () => dismissed++,
      );
      await tester.tap(find.byKey(const Key('leaderboard-auth-open')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('leaderboard-auth-later')));
      await tester.pumpAndSettle();

      expect(authCalls, 0);
      expect(dismissed, 1);
      expect(find.byKey(const Key('leaderboard-auth-dialog')), findsNothing);
    },
  );

  testWidgets('auth cancellation returns to origin when no matching cache', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (BuildContext context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => LeaderboardScreenView(
                      state: authState(),
                      arenaName: 'Leo thang',
                      onBack: () => Navigator.of(context).pop(),
                      onScopeSelected: (_) {},
                      onAuthenticate: () async => true,
                      onAuthDismissed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('leaderboard-auth-open')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('leaderboard-auth-later')));
    await tester.pumpAndSettle();
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets('matching offline cache can be retained after auth failure', (
    tester,
  ) async {
    int dismissals = 0;
    await pumpAuth(
      tester,
      onAuthenticate: () async => false,
      onAuthDismissed: () => dismissals++,
    );
    await tester.tap(find.byKey(const Key('leaderboard-auth-open')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('leaderboard-auth-confirm')));
    await tester.pumpAndSettle();

    expect(dismissals, 1);
    // The dismissal policy is supplied by the route owner: keeping this route
    // mounted is the matching-cache branch; popping is covered above.
    expect(find.byKey(const Key('leaderboard-panel')), findsOneWidget);
    expect(find.byKey(const Key('leaderboard-auth-dialog')), findsNothing);
  });
}
