import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../state/account_controller.dart';

class FirebaseAccountRepository implements AccountRepository {
  FirebaseAccountRepository(this.auth);
  final FirebaseAuth auth;

  Stream<AccountIdentity?> authStateChanges() => auth.authStateChanges().map(
    (user) => user == null ? null : _identity(user),
  );

  @override
  Future<AccountIdentity?> signIn(AuthProviderKind provider) async {
    final AuthProvider authProvider = provider == AuthProviderKind.apple
        ? AppleAuthProvider()
        : GoogleAuthProvider();
    final result = await auth.signInWithProvider(authProvider);
    return result.user == null ? null : _identity(result.user!);
  }

  @override
  Future<Set<AuthProviderKind>> link(AuthProviderKind provider) async {
    final user = auth.currentUser;
    if (user == null) throw StateError('No authenticated account');
    final AuthProvider authProvider = provider == AuthProviderKind.apple
        ? AppleAuthProvider()
        : GoogleAuthProvider();
    await user.linkWithProvider(authProvider);
    await user.reload();
    return _providers(auth.currentUser ?? user);
  }

  @override
  Future<ReauthenticationProof> reauthenticate(
    AuthProviderKind provider,
  ) async {
    final user = auth.currentUser;
    if (user == null) throw StateError('No authenticated account');
    final AuthProvider authProvider = provider == AuthProviderKind.apple
        ? AppleAuthProvider()
        : GoogleAuthProvider();
    final result = await user.reauthenticateWithProvider(authProvider);
    final token = await result.user?.getIdToken(true);
    return ReauthenticationProof(provider: provider, idToken: token ?? '');
  }

  @override
  Future<void> signOut() => auth.signOut();

  AccountIdentity _identity(User user) =>
      AccountIdentity(uid: user.uid, providers: _providers(user));

  Set<AuthProviderKind> _providers(User user) => user.providerData
      .map(
        (info) => switch (info.providerId) {
          'google.com' => AuthProviderKind.google,
          'apple.com' => AuthProviderKind.apple,
          _ => null,
        },
      )
      .whereType<AuthProviderKind>()
      .toSet();
}
