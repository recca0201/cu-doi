import 'dart:async';

import 'package:ban_bua_tuong/domain/player_progress.dart';
import 'package:ban_bua_tuong/state/account_controller.dart';
import 'package:ban_bua_tuong/state/providers.dart';
import 'package:ban_bua_tuong/ui/screens/profile_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import '../support/pump_app.dart';

class _PendingAccountRepository implements AccountRepository {
  final Completer<AccountIdentity?> signInResult =
      Completer<AccountIdentity?>();

  @override
  Future<AccountIdentity?> signIn(AuthProviderKind provider) =>
      signInResult.future;

  @override
  Future<Set<AuthProviderKind>> link(AuthProviderKind provider) async => {};

  @override
  Future<ReauthenticationProof> reauthenticate(
    AuthProviderKind provider,
  ) async => throw UnsupportedError('not used');

  @override
  Future<void> signOut() async {}
}

void main() {
  testWidgets('overview restores guest metrics without zero error state', (
    tester,
  ) async {
    await pumpApp(
      tester,
      home: const ProfileScreen(),
      progress: const PlayerProgress(
        coins: 9,
        results: {
          1: LevelResult(stars: 2, highScore: 700),
          2: LevelResult(skipped: true),
        },
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('profile-title')), findsOneWidget);
    expect(find.byKey(const Key('profile-back')), findsOneWidget);
    expect(find.text('2/60'), findsOneWidget);
    expect(find.text('1/20'), findsOneWidget);
    expect(find.text('700'), findsOneWidget);
    expect(find.text('Đang chơi với tư cách khách'), findsOneWidget);
  });
  testWidgets(
    'progress details expose four chapters, records and eight badges',
    (tester) async {
      await pumpApp(tester, home: const ProfileScreen());
      await tester.pump();
      expect(find.textContaining('Chương 1'), findsOneWidget);
      expect(find.textContaining('Chương 4'), findsOneWidget);
      expect(find.text('Huy hiệu'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsNWidgets(8));
    },
  );
  testWidgets('account actions stay visible and accessible', (tester) async {
    await pumpApp(tester, home: const ProfileScreen());
    await tester.pump();
    await tester.ensureVisible(find.text('Tiếp tục với Google'));
    expect(find.text('Tiếp tục với Google'), findsOneWidget);
    expect(find.text('Tiếp tục với Apple'), findsOneWidget);
  });

  testWidgets('Google sign-in shows progress and a visible failure', (
    tester,
  ) async {
    final repository = _PendingAccountRepository();
    final controller = AccountController(repository);
    await pumpApp(
      tester,
      home: const ProfileScreen(),
      overrides: [accountProvider.overrideWith((ref) => controller)],
    );

    final googleButton = find.text('Tiếp tục với Google');
    await tester.ensureVisible(googleButton);
    await tester.tap(googleButton);
    await tester.pump();
    expect(find.byKey(const Key('account-sign-in-progress')), findsOneWidget);
    expect(find.text('Đang mở cửa sổ đăng nhập…'), findsOneWidget);

    repository.signInResult.completeError(StateError('provider failed'));
    await tester.pump();
    expect(find.textContaining('Không đăng nhập được'), findsOneWidget);
    expect(find.text('Đã đăng nhập:'), findsNothing);
  });
}
