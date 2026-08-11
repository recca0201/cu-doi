import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/account_deletion_repository.dart';
import '../data/local_player_store.dart';

enum AccountPhase {
  restoring,
  guest,
  authenticating,
  authenticated,
  cachedAccountOffline,
  syncing,
  signingOut,
  error,
  deletionPending,
  providerRecoveryRequired,
  deleted,
}

enum AuthProviderKind { google, apple }

class AccountIdentity {
  const AccountIdentity({required this.uid, required this.providers});
  final String uid;
  final Set<AuthProviderKind> providers;
}

class ReauthenticationProof {
  const ReauthenticationProof({required this.provider, required this.idToken});
  final AuthProviderKind provider;
  final String idToken;
}

class AccountState {
  const AccountState({
    this.phase = AccountPhase.guest,
    this.uid,
    this.providers = const {},
    this.lastSyncedAt,
    this.errorCode,
    this.requestId,
    this.deletionReceipt,
  });
  final AccountPhase phase;
  final String? uid;
  final Set<AuthProviderKind> providers;
  final DateTime? lastSyncedAt;
  final String? errorCode;
  final String? requestId;
  final DeletionReceipt? deletionReceipt;
  bool get isAuthenticated =>
      uid != null &&
      !{AccountPhase.guest, AccountPhase.deleted}.contains(phase);
  bool get blocksLocalReset =>
      isAuthenticated ||
      {
        AccountPhase.deletionPending,
        AccountPhase.providerRecoveryRequired,
      }.contains(phase);
}

abstract class AccountRepository {
  Future<AccountIdentity?> signIn(AuthProviderKind provider);
  Future<Set<AuthProviderKind>> link(AuthProviderKind provider);
  Future<void> signOut();
  Future<ReauthenticationProof> reauthenticate(AuthProviderKind provider) =>
      Future<ReauthenticationProof>.error(
        UnsupportedError('Reauthentication is not available'),
      );
}

class AccountController extends StateNotifier<AccountState> {
  AccountController(this._repository, {this._store, this._deletionRepository})
    : super(const AccountState());
  final AccountRepository _repository;
  final LocalPlayerStore? _store;
  final AccountDeletionRepository? _deletionRepository;
  bool _busy = false;
  int _ownerEpoch = 0;
  Timer? _pollTimer;
  int get ownerEpoch => _ownerEpoch;

  Future<void> signIn(AuthProviderKind provider) async {
    if (_busy) return;
    _busy = true;
    final previous = state;
    state = const AccountState(phase: AccountPhase.authenticating);
    try {
      final identity = await _repository.signIn(provider);
      if (identity == null) {
        state = previous;
        return;
      }
      final accountOwner = OwnerKey.account(identity.uid);
      final guest = _store == null
          ? null
          : await _store.load(const OwnerKey.guest());
      if (_store != null &&
          guest != null &&
          !await _store.save(accountOwner, guest)) {
        await _repository.signOut();
        state = AccountState(
          phase: AccountPhase.error,
          errorCode: 'claimFailed',
        );
        return;
      }
      _ownerEpoch++;
      state = AccountState(
        phase: AccountPhase.authenticated,
        uid: identity.uid,
        providers: identity.providers,
      );
    } catch (_) {
      state = previous.phase == AccountPhase.guest
          ? const AccountState(
              phase: AccountPhase.error,
              errorCode: 'signInFailed',
            )
          : previous;
    } finally {
      _busy = false;
    }
  }

  Future<void> link(AuthProviderKind provider) async {
    if (!state.isAuthenticated || _busy) return;
    _busy = true;
    final previous = state;
    try {
      state = AccountState(
        phase: AccountPhase.authenticated,
        uid: previous.uid,
        providers: await _repository.link(provider),
      );
    } catch (_) {
      state = AccountState(
        phase: AccountPhase.error,
        uid: previous.uid,
        providers: previous.providers,
        errorCode: 'linkFailed',
      );
    } finally {
      _busy = false;
    }
  }

  Future<bool> signOut() async {
    if (_busy || state.uid == null) return false;
    _busy = true;
    final previous = state;
    state = AccountState(
      phase: AccountPhase.signingOut,
      uid: previous.uid,
      providers: previous.providers,
    );
    try {
      if (_store != null) {
        final account = await _store.load(OwnerKey.account(previous.uid!));
        final guestOwner = OwnerKey.uidDerivedGuest(previous.uid!);
        if (!await _store.save(
          guestOwner,
          account.copyWith(deletionPending: false),
        )) {
          state = previous;
          return false;
        }
        await _store.save(
          const OwnerKey.guest(),
          account.copyWith(deletionPending: false),
        );
      }
      await _repository.signOut();
      _ownerEpoch++;
      state = const AccountState();
      return true;
    } catch (_) {
      state = previous;
      return false;
    } finally {
      _busy = false;
    }
  }

  Future<bool> beginDeletion(ReauthenticationProof proof) async {
    if (_busy ||
        state.uid == null ||
        _store == null ||
        _deletionRepository == null) {
      return false;
    }
    _busy = true;
    final previous = state;
    try {
      final account = await _store.load(OwnerKey.account(previous.uid!));
      if (!await _store.save(
        const OwnerKey.guest(),
        account.copyWith(deletionPending: true),
      )) {
        return false;
      }
      if (!await _store.save(
        OwnerKey.account(previous.uid!),
        account.copyWith(deletionPending: true),
      )) {
        return false;
      }
      _ownerEpoch++;
      final receipt = await _deletionRepository.begin(proof, _randomId());
      state = AccountState(
        phase: AccountPhase.deletionPending,
        uid: previous.uid,
        providers: previous.providers,
        requestId: receipt.requestId,
        deletionReceipt: receipt,
      );
      _schedulePoll();
      return true;
    } catch (_) {
      state = AccountState(
        phase: AccountPhase.error,
        uid: previous.uid,
        providers: previous.providers,
        errorCode: 'deletionStartFailed',
      );
      return false;
    } finally {
      _busy = false;
    }
  }

  Future<bool> requestDeletion(AuthProviderKind provider) async {
    try {
      return beginDeletion(await _repository.reauthenticate(provider));
    } catch (_) {
      state = AccountState(
        phase: AccountPhase.error,
        uid: state.uid,
        providers: state.providers,
        errorCode: 'reauthenticationFailed',
      );
      return false;
    }
  }

  Future<void> pollDeletion() async {
    final receipt = state.deletionReceipt;
    if (receipt == null || _deletionRepository == null) return;
    try {
      final status = await _deletionRepository
          .status(receipt)
          .timeout(const Duration(seconds: 10));
      if (status.phase == DeletionServerPhase.providerRecoveryRequired) {
        state = AccountState(
          phase: AccountPhase.providerRecoveryRequired,
          uid: state.uid,
          providers: state.providers,
          requestId: receipt.requestId,
          deletionReceipt: receipt,
        );
      } else if (status.terminal) {
        state = AccountState(
          phase: AccountPhase.deleted,
          requestId: receipt.requestId,
        );
        _pollTimer?.cancel();
      }
    } catch (_) {
      /* durable receipt remains retryable */
    }
  }

  void _schedulePoll() {
    _pollTimer?.cancel();
    _pollTimer = Timer(const Duration(seconds: 5), pollDeletion);
  }

  String _randomId() => base64Url
      .encode(List.generate(24, (_) => Random.secure().nextInt(256)))
      .replaceAll('=', '');
  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
