import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../state/account_controller.dart';

class FirebaseAccountRepository
    implements AccountRepository, CurrentAccountRepository {
  FirebaseAccountRepository(this.auth, {GoogleSignIn? googleSignIn})
    : _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth auth;
  final GoogleSignIn _googleSignIn;
  Future<void>? _googleInitialization;
  bool _googleInitialized = false;

  @override
  AccountIdentity? get currentIdentity {
    final user = auth.currentUser;
    return user == null ? null : _identity(user);
  }

  Stream<AccountIdentity?> authStateChanges() => auth.authStateChanges().map(
    (user) => user == null ? null : _identity(user),
  );

  @override
  Future<AccountIdentity?> signIn(AuthProviderKind provider) async {
    final UserCredential result;
    if (provider == AuthProviderKind.google) {
      final OAuthCredential? credential = await _googleCredential();
      if (credential == null) return null;
      result = await auth.signInWithCredential(credential);
    } else {
      result = await auth.signInWithProvider(AppleAuthProvider());
    }
    return result.user == null ? null : _identity(result.user!);
  }

  @override
  Future<Set<AuthProviderKind>> link(AuthProviderKind provider) async {
    final user = auth.currentUser;
    if (user == null) throw StateError('No authenticated account');
    if (provider == AuthProviderKind.google) {
      final OAuthCredential? credential = await _googleCredential();
      if (credential == null) return _providers(user);
      await user.linkWithCredential(credential);
    } else {
      await user.linkWithProvider(AppleAuthProvider());
    }
    await user.reload();
    return _providers(auth.currentUser ?? user);
  }

  @override
  Future<ReauthenticationProof> reauthenticate(
    AuthProviderKind provider,
  ) async {
    final user = auth.currentUser;
    if (user == null) throw StateError('No authenticated account');
    final UserCredential result;
    if (provider == AuthProviderKind.google) {
      final OAuthCredential? credential = await _googleCredential();
      if (credential == null) throw StateError('Google sign-in was canceled');
      result = await user.reauthenticateWithCredential(credential);
    } else {
      result = await user.reauthenticateWithProvider(AppleAuthProvider());
    }
    final token = await result.user?.getIdToken(true);
    return ReauthenticationProof(provider: provider, idToken: token ?? '');
  }

  @override
  Future<void> signOut() async {
    await auth.signOut();
    if (_googleInitialized) await _googleSignIn.signOut();
  }

  Future<OAuthCredential?> _googleCredential() async {
    await (_googleInitialization ??= _initializeGoogle());
    try {
      final GoogleSignInAccount account = await _googleSignIn.authenticate();
      final String? idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw StateError('Google Sign-In returned no ID token');
      }
      return GoogleAuthProvider.credential(idToken: idToken);
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled ||
          error.code == GoogleSignInExceptionCode.interrupted) {
        return null;
      }
      rethrow;
    }
  }

  Future<void> _initializeGoogle() async {
    await _googleSignIn.initialize();
    _googleInitialized = true;
  }

  AccountIdentity _identity(User user) => AccountIdentity(
    uid: user.uid,
    providers: _providers(user),
    displayName: _firstNonEmpty(<String?>[
      user.displayName,
      ...user.providerData.map((info) => info.displayName),
    ]),
    email: _firstNonEmpty(<String?>[
      user.email,
      ...user.providerData.map((info) => info.email),
    ]),
  );

  String? _firstNonEmpty(Iterable<String?> values) {
    for (final value in values) {
      final normalized = value?.trim();
      if (normalized != null && normalized.isNotEmpty) return normalized;
    }
    return null;
  }

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
