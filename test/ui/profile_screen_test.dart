import 'dart:async';

import 'package:ban_bua_tuong/domain/player_progress.dart';
import 'package:ban_bua_tuong/state/account_controller.dart';
import 'package:ban_bua_tuong/state/providers.dart';
import 'package:ban_bua_tuong/ui/screens/profile_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  testWidgets('Android offers Google sign-in without Apple sign-in', (
    tester,
  ) async {
    await pumpApp(
      tester,
      home: Theme(
        data: ThemeData(platform: TargetPlatform.android),
        child: const ProfileScreen(),
      ),
    );
    await tester.pump();
    await tester.ensureVisible(find.text('Tiếp tục với Google'));
    expect(find.text('Tiếp tục với Google'), findsOneWidget);
    expect(find.text('Tiếp tục với Apple'), findsNothing);
  });

  testWidgets('iOS keeps Apple sign-in available', (tester) async {
    await pumpApp(
      tester,
      home: Theme(
        data: ThemeData(platform: TargetPlatform.iOS),
        child: const ProfileScreen(),
      ),
    );
    await tester.pump();
    await tester.ensureVisible(find.text('Tiếp tục với Apple'));
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

  testWidgets('Google sign-in asks before replacing an existing player name', (
    tester,
  ) async {
    final repository = _PendingAccountRepository();
    await pumpApp(
      tester,
      home: const ProfileScreen(),
      overrides: [
        accountProvider.overrideWith(
          (ref) => AccountController(
            repository,
            store: ref.watch(localPlayerStoreProvider),
          ),
        ),
      ],
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ProfileScreen)),
    );
    await container.read(profileProvider.notifier).ready;
    await container.read(profileProvider.notifier).saveName('Tên khách cũ');
    await tester.pump();

    final googleButton = find.text('Tiếp tục với Google');
    await tester.ensureVisible(googleButton);
    await tester.tap(googleButton);
    repository.signInResult.complete(
      const AccountIdentity(
        uid: 'google-user',
        providers: {AuthProviderKind.google},
        displayName: 'Nguyễn Dội',
        email: 'doi@example.com',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('google-name-choice')), findsOneWidget);
    expect(
      find.textContaining('“Nguyễn Dội” từ tài khoản Google'),
      findsOneWidget,
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('profile-name'))).data,
      'Tên khách cũ',
    );

    await tester.tap(find.byKey(const Key('google-name-use')));
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const Key('profile-name'))).data,
      'Nguyễn Dội',
    );
    await tester.ensureVisible(find.byKey(const Key('account-email')));
    expect(find.text('doi@example.com'), findsOneWidget);
    expect(find.byKey(const Key('account-display-name')), findsOneWidget);
  });

  testWidgets('Google sign-in can save a different in-game name', (
    tester,
  ) async {
    final repository = _PendingAccountRepository();
    await pumpApp(
      tester,
      home: const ProfileScreen(),
      overrides: [
        accountProvider.overrideWith(
          (ref) => AccountController(
            repository,
            store: ref.watch(localPlayerStoreProvider),
          ),
        ),
      ],
    );

    final googleButton = find.text('Tiếp tục với Google');
    await tester.ensureVisible(googleButton);
    await tester.tap(googleButton);
    repository.signInResult.complete(
      const AccountIdentity(
        uid: 'google-user',
        providers: {AuthProviderKind.google},
        displayName: 'Nguyễn Dội',
        email: 'doi@example.com',
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('google-name-custom')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('profile-name-editor')), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('profile-name-field')))
          .initialValue,
      'Nguyễn Dội',
    );
    await tester.enterText(
      find.byKey(const Key('profile-name-field')),
      'Dội Cao Thủ',
    );
    await tester.tap(find.byKey(const Key('profile-name-save')));
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const Key('profile-name'))).data,
      'Dội Cao Thủ',
    );
  });
}
