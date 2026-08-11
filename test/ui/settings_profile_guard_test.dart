import 'package:ban_bua_tuong/state/account_controller.dart';
import 'package:ban_bua_tuong/state/providers.dart';
import 'package:ban_bua_tuong/ui/screens/settings_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/pump_app.dart';

class Repo implements AccountRepository {
  @override
  Future<Set<AuthProviderKind>> link(AuthProviderKind provider) async => {
    provider,
  };
  @override
  Future<AccountIdentity?> signIn(AuthProviderKind provider) async => null;
  @override
  Future<void> signOut() async {}
  @override
  Future<ReauthenticationProof> reauthenticate(
    AuthProviderKind provider,
  ) async => ReauthenticationProof(provider: provider, idToken: 'x');
}

class Seeded extends AccountController {
  Seeded(AccountState value) : super(Repo()) {
    state = value;
  }
}

void main() {
  testWidgets('authenticated and deletion states hide unsafe local reset', (
    tester,
  ) async {
    await pumpApp(
      tester,
      home: const SettingsScreen(),
      overrides: [
        accountProvider.overrideWith(
          (ref) => Seeded(
            const AccountState(
              phase: AccountPhase.authenticated,
              uid: 'u',
              providers: {AuthProviderKind.google},
            ),
          ),
        ),
      ],
    );
    expect(find.text('Xóa tiến trình'), findsNothing);
    expect(find.textContaining('đám mây'), findsOneWidget);
  });
}
