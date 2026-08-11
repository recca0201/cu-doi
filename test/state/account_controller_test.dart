import 'package:ban_bua_tuong/data/account_deletion_repository.dart';
import 'package:ban_bua_tuong/data/local_player_store.dart';
import 'package:ban_bua_tuong/domain/player_progress.dart';
import 'package:ban_bua_tuong/state/account_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeAccountRepository implements AccountRepository {
  bool canceled = false;
  bool signedOut = false;
  Set<AuthProviderKind> providers = {AuthProviderKind.google};
  @override
  Future<AccountIdentity?> signIn(AuthProviderKind provider) async =>
      canceled ? null : AccountIdentity(uid: 'uid-one', providers: {provider});
  @override
  Future<Set<AuthProviderKind>> link(AuthProviderKind provider) async =>
      providers = {...providers, provider};
  @override
  Future<void> signOut() async {
    signedOut = true;
  }

  @override
  Future<ReauthenticationProof> reauthenticate(
    AuthProviderKind provider,
  ) async => ReauthenticationProof(provider: provider, idToken: 'fresh');
}

class FakeDeletionRepository implements AccountDeletionRepository {
  DeletionServerPhase phase = DeletionServerPhase.queued;
  int refreshed = 0;
  @override
  Future<DeletionReceipt> begin(
    ReauthenticationProof proof,
    String idempotencyKey,
  ) async => const DeletionReceipt(
    receipt: 'receipt-receipt-receipt-receipt-1234',
    requestId: 'DEL-1',
  );
  @override
  Future<void> refreshProviderProof(
    DeletionReceipt receipt,
    ReauthenticationProof proof,
  ) async {
    refreshed++;
  }

  @override
  Future<DeletionStatus> status(DeletionReceipt receipt) async =>
      DeletionStatus(phase);
}

void main() {
  late LocalPlayerStore store;
  late FakeAccountRepository auth;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = LocalPlayerStore(await SharedPreferences.getInstance());
    auth = FakeAccountRepository();
    await store.save(
      const OwnerKey.guest(),
      const PlayerEnvelope(progress: PlayerProgress(coins: 42)),
    );
  });
  test(
    'cancel keeps guest, sign in claims and sign out creates full guest copy',
    () async {
      final controller = AccountController(auth, store: store);
      auth.canceled = true;
      await controller.signIn(AuthProviderKind.google);
      expect(controller.state.phase, AccountPhase.guest);
      auth.canceled = false;
      await controller.signIn(AuthProviderKind.google);
      expect(controller.state.uid, 'uid-one');
      expect(
        (await store.load(OwnerKey.account('uid-one'))).progress.coins,
        42,
      );
      expect(await controller.signOut(), isTrue);
      expect(controller.state.phase, AccountPhase.guest);
      expect(
        (await store.load(OwnerKey.uidDerivedGuest('uid-one'))).progress.coins,
        42,
      );
    },
  );
  test('link preserves uid and provider conflict is isolated', () async {
    final controller = AccountController(auth, store: store);
    await controller.signIn(AuthProviderKind.google);
    await controller.link(AuthProviderKind.apple);
    expect(controller.state.uid, 'uid-one');
    expect(controller.state.providers, contains(AuthProviderKind.apple));
  });
  test(
    'account deletion precommits guest, polls recovery and terminal only',
    () async {
      final deletion = FakeDeletionRepository();
      final controller = AccountController(
        auth,
        store: store,
        deletionRepository: deletion,
      );
      await controller.signIn(AuthProviderKind.google);
      expect(await controller.requestDeletion(AuthProviderKind.google), isTrue);
      expect(controller.state.phase, AccountPhase.deletionPending);
      expect(
        (await store.load(const OwnerKey.guest())).deletionPending,
        isTrue,
      );
      deletion.phase = DeletionServerPhase.providerRecoveryRequired;
      await controller.pollDeletion();
      expect(controller.state.phase, AccountPhase.providerRecoveryRequired);
      expect(
        await controller.refreshDeletionProof(AuthProviderKind.google),
        isTrue,
      );
      expect(deletion.refreshed, 1);
      deletion.phase = DeletionServerPhase.completed;
      await controller.pollDeletion();
      expect(controller.state.phase, AccountPhase.deleted);
      expect((await store.load(OwnerKey.account('uid-one'))).progress.coins, 0);
    },
  );
}
