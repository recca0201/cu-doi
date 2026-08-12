import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../core/game_audio_service.dart';
import '../core/game_audio_lifecycle.dart';
import '../core/haptic_service.dart';
import '../core/platform_avatar.dart';
import '../core/rewarded_ad_service.dart';
import '../data/game_services_gateway.dart';
import '../data/identity_hasher.dart';
import '../data/leaderboard_repository.dart';
import '../data/local_leaderboard_store.dart';
import '../data/method_channel_game_services_gateway.dart';
import '../data/progress_repository.dart';
import '../data/local_player_store.dart';
import '../data/firebase_bootstrap.dart';
import '../data/firebase_account_repository.dart';
import '../data/account_deletion_repository.dart';
import 'account_controller.dart';
import '../data/dialogue_seen_repository.dart';
import '../data/settings_repository.dart';
import '../domain/character.dart';
import '../domain/economy.dart';
import '../domain/leaderboard_models.dart';
import '../domain/player_progress.dart';
import 'hint_controller.dart';
import 'leaderboard_controller.dart';
import 'leaderboard_lifecycle_coordinator.dart';
import 'profile_controller.dart';
import 'rewarded_ad_controller.dart';

/// Overridden in `main()` after `SharedPreferences.getInstance()` resolves, so
/// nothing downstream has to be async. Reading it without the override is a
/// programming error, not a runtime condition.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw StateError(
    'sharedPreferencesProvider must be overridden in main() '
    'or in a test ProviderScope.',
  ),
);

final firebaseBootstrapProvider = Provider<FirebaseBootstrapResult>(
  (ref) => const FirebaseBootstrapResult.guest(),
);

class _GuestOnlyAccountRepository implements AccountRepository {
  @override
  Future<Set<AuthProviderKind>> link(AuthProviderKind provider) =>
      Future.error(StateError('Firebase is not configured'));
  @override
  Future<AccountIdentity?> signIn(AuthProviderKind provider) =>
      Future.error(StateError('Firebase is not configured'));
  @override
  Future<void> signOut() async {}
  @override
  Future<ReauthenticationProof> reauthenticate(AuthProviderKind provider) =>
      Future.error(StateError('Firebase is not configured'));
}

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(sharedPreferencesProvider)),
);

class SettingsController extends StateNotifier<AppSettings> {
  SettingsController(this._repo) : super(_repo.load());

  final SettingsRepository _repo;

  void setSound(bool value) => _apply(state.copyWith(soundOn: value));
  void setMusic(bool value) => _apply(state.copyWith(musicOn: value));
  void setHaptics(bool value) => _apply(state.copyWith(hapticsOn: value));
  void setLocale(String code) => _apply(state.copyWith(localeCode: code));

  void _apply(AppSettings next) {
    state = next;
    _repo.save(next);
  }
}

final settingsProvider = StateNotifierProvider<SettingsController, AppSettings>(
  (ref) => SettingsController(ref.watch(settingsRepositoryProvider)),
);

/// Local-only for now. `FirestoreProgressRepository` from the parent project
/// implements the same interface and can be swapped in here without touching
/// state or UI — that was the point of the abstraction.
final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => LocalProgressRepository(ref.watch(sharedPreferencesProvider)),
);

class ProgressController extends StateNotifier<PlayerProgress> {
  ProgressController(this._repo, {PlayerProgress? initial})
    : _ready = Completer<void>(),
      _hasConfirmedSnapshot = initial != null,
      super(initial ?? const PlayerProgress()) {
    if (initial == null) {
      unawaited(_restore());
    } else {
      _ready.complete();
    }
  }

  final ProgressRepository _repo;
  final Completer<void> _ready;
  Future<void> _tail = Future<void>.value();
  bool _spending = false;
  bool _hasConfirmedSnapshot;

  Future<void> get ready => _ready.future;
  bool get isReady => _ready.isCompleted;
  bool get hasConfirmedSnapshot => _hasConfirmedSnapshot;

  Future<void> _restore() async {
    try {
      state = await _repo.load();
      _hasConfirmedSnapshot = true;
    } catch (_) {
      // Keep the constructor seed for gameplay, but do not let leaderboard
      // backfill treat it as a restored/confirmed progress snapshot.
      _hasConfirmedSnapshot = false;
    } finally {
      if (!_ready.isCompleted) _ready.complete();
    }
  }

  /// Records a finished arena. Arena ids reuse the parent project's level-id
  /// keyspace, so `PlayerProgress` needed no changes at all.
  Future<RecordOutcome> record(int arenaId, int stars, int score) {
    return _enqueue<RecordOutcome>(() async {
      final PlayerProgress previous = state;
      final int previousBest = previous.highScoreFor(arenaId);
      final PlayerProgress candidate = previous.withResult(
        arenaId,
        stars,
        score,
      );
      final PlayerProgress next = PlayerProgress(
        results: Map<int, LevelResult>.unmodifiable(candidate.results),
        coins: candidate.coins,
      );

      if (!await _repo.save(next)) {
        return RecordOutcome(
          persisted: false,
          arenaId: arenaId,
          attemptedScore: score,
          previousBest: previousBest,
          currentBest: previousBest,
          completedByWin: stars >= 1,
          persistedProgress: previous,
        );
      }

      state = next;
      return RecordOutcome(
        persisted: true,
        arenaId: arenaId,
        attemptedScore: score,
        previousBest: previousBest,
        currentBest: next.highScoreFor(arenaId),
        completedByWin: stars >= 1,
        persistedProgress: next,
      );
    });
  }

  Future<void> reset() async {
    await _enqueue<void>(() async {
      const next = PlayerProgress();
      if (await _repo.save(next)) state = next;
    });
  }

  Future<void> recordLoss(int arenaId) async {
    await _enqueue<void>(() async {
      final next = state.withLoss(arenaId);
      if (await _repo.save(next)) state = next;
    });
  }

  Future<bool> grantCoins(int amount) => _enqueue<bool>(() async {
    if (amount <= 0) return false;
    final PlayerProgress next = state.withCoinsEarned(amount);
    if (!await _repo.save(next)) return false;
    state = next;
    return true;
  });

  Future<SpendResult> spendOnHint() =>
      _spend(cost: kHintCost, transform: (PlayerProgress value) => value);

  Future<SpendResult> skipArena(int arenaId) => _spend(
    cost: kSkipCost,
    transform: (PlayerProgress value) => value.withSkipped(arenaId),
  );

  Future<SpendResult> _spend({
    required int cost,
    required PlayerProgress Function(PlayerProgress) transform,
  }) async {
    if (_spending) return SpendResult.writeFailed;
    if (!state.canAfford(cost)) return SpendResult.insufficientCoins;
    _spending = true;
    try {
      return await _enqueue<SpendResult>(() async {
        if (!state.canAfford(cost)) return SpendResult.insufficientCoins;
        final PlayerProgress next = transform(state).withCoinsSpent(cost);
        if (!await _repo.save(next)) return SpendResult.writeFailed;
        state = next;
        return SpendResult.ok;
      });
    } finally {
      _spending = false;
    }
  }

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final completer = Completer<T>();
    _tail = _tail.then((_) async {
      try {
        await ready;
        completer.complete(await operation());
      } catch (error, stack) {
        completer.completeError(error, stack);
      }
    });
    return completer.future;
  }
}

final progressProvider =
    StateNotifierProvider<ProgressController, PlayerProgress>(
      (ref) => ProgressController(ref.watch(progressRepositoryProvider)),
    );

/// Override this seam in widget/integration tests to avoid a real platform UI.
/// The production adapter normalizes unsupported hosts to a harmless status.
final gameServicesGatewayProvider = Provider<GameServicesGateway>((ref) {
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    return MethodChannelGameServicesGateway();
  }
  return const _UnsupportedGameServicesGateway();
});

class _UnsupportedGameServicesGateway implements GameServicesGateway {
  const _UnsupportedGameServicesGateway();

  static const GameServicesException _unsupported = GameServicesException(
    GameServicesFailureCode.unsupported,
  );

  @override
  Future<PlatformIdentity?> restoreIdentity() async => null;

  @override
  Future<PlatformIdentity> authenticate({required bool interactive}) =>
      Future<PlatformIdentity>.error(_unsupported);

  @override
  Future<LeaderboardPage> loadLeaderboard({
    required PlatformIdentity identity,
    required int arenaId,
    required LeaderboardScope scope,
    required int limit,
  }) => Future<LeaderboardPage>.error(_unsupported);

  @override
  Future<Uint8List?> loadAvatar({
    required PlatformIdentity identity,
    required PlatformAvatarRef avatar,
  }) async => null;

  @override
  Stream<PlatformIdentityEvent> get identityEvents =>
      const Stream<PlatformIdentityEvent>.empty();

  @override
  Future<void> submitScore({
    required PlatformIdentity identity,
    required int arenaId,
    required int score,
  }) => Future<void>.error(_unsupported);

  @override
  Future<void> validateConfiguration() => Future<void>.error(_unsupported);
}

final identityHasherProvider = Provider<IdentityHasher>(
  (ref) => IdentityHasher(ref.watch(sharedPreferencesProvider)),
);

final localLeaderboardStoreProvider = Provider<LocalLeaderboardStore>(
  (ref) => LocalLeaderboardStore(ref.watch(sharedPreferencesProvider)),
);

final leaderboardRepositoryProvider = Provider<LeaderboardRepository>(
  (ref) => LeaderboardRepository(
    gateway: ref.watch(gameServicesGatewayProvider),
    store: ref.watch(localLeaderboardStoreProvider),
    identityHasher: ref.watch(identityHasherProvider),
  ),
);

final platformAvatarLoaderProvider = Provider<PlatformAvatarLoader>((ref) {
  final LeaderboardRepository repository = ref.watch(
    leaderboardRepositoryProvider,
  );
  final GameServicesGateway gateway = ref.watch(gameServicesGatewayProvider);
  return PlatformAvatarLoader(
    fetch: (PlatformAvatarRef avatar) async {
      final PlatformIdentityState state = repository.identityState;
      final PlatformIdentity? identity = state.identity;
      if (!state.maySubmit ||
          identity == null ||
          identity.platform != avatar.platform ||
          state.epoch != avatar.identityEpoch) {
        return null;
      }
      return gateway.loadAvatar(identity: identity, avatar: avatar);
    },
    isCurrent: (PlatformAvatarRef avatar) =>
        avatar.identityEpoch == repository.identityEpoch,
  );
});

final leaderboardSubmissionProvider =
    StateNotifierProvider<LeaderboardSubmissionController, SubmissionSummary>(
      (ref) => LeaderboardSubmissionController(
        ref.watch(leaderboardRepositoryProvider),
      ),
    );

/// Descriptive alias retained for consumers that ask for the controller seam.
final leaderboardSubmissionControllerProvider = leaderboardSubmissionProvider;

/// One route/controller per arena. The controller restores the device-local
/// Global/Friends preference itself and keeps that arena fixed while the scope
/// changes, so cached rows can never bleed across contexts.
final leaderboardProvider = StateNotifierProvider.autoDispose
    .family<LeaderboardController, LeaderboardViewState, int>((ref, arenaId) {
      final LeaderboardSubmissionController submissions = ref.read(
        leaderboardSubmissionProvider.notifier,
      );
      final LeaderboardController controller = LeaderboardController(
        ref.watch(leaderboardRepositoryProvider),
        arenaId: arenaId,
        submissionSummary: ref.read(leaderboardSubmissionProvider),
        onOpened: submissions.onLeaderboardOpened,
        onAuthenticated: () async {
          final ProgressController progress = ref.read(
            progressProvider.notifier,
          );
          await progress.ready;
          await submissions.onAuthenticated(
            ref.read(progressProvider),
            progressConfirmed: progress.hasConfirmedSnapshot,
          );
        },
      );

      ref.listen<SubmissionSummary>(leaderboardSubmissionProvider, (
        SubmissionSummary? _,
        SubmissionSummary next,
      ) {
        controller.updateSubmissionSummary(next);
      });
      unawaited(controller.open());
      return controller;
    });

/// Descriptive alias for consumers that prefer the controller-oriented name.
final leaderboardControllerProvider = leaderboardProvider;

final leaderboardLifecycleCoordinatorProvider =
    Provider<LeaderboardLifecycleCoordinator>((ref) {
      final LeaderboardLifecycleCoordinator coordinator =
          LeaderboardLifecycleCoordinator(
            gateway: ref.watch(gameServicesGatewayProvider),
            repository: ref.watch(leaderboardRepositoryProvider),
            submissions: ref.watch(leaderboardSubmissionProvider.notifier),
            avatarLoader: ref.watch(platformAvatarLoaderProvider),
            progress: () => ref.read(progressProvider),
            progressReady: () => ref.read(progressProvider.notifier).ready,
            progressConfirmed: () =>
                ref.read(progressProvider.notifier).hasConfirmedSnapshot,
          );
      ref.onDispose(() {
        _ignoreLeaderboardLifecycleFailure(coordinator.dispose());
      });
      _ignoreLeaderboardLifecycleFailure(coordinator.initializeSilently());
      return coordinator;
    });

void _ignoreLeaderboardLifecycleFailure(Future<void> future) {
  unawaited(future.then<void>((_) {}, onError: (Object _, StackTrace _) {}));
}

final localPlayerStoreProvider = Provider<LocalPlayerStore>(
  (ref) => LocalPlayerStore(ref.watch(sharedPreferencesProvider)),
);

final profileProvider = StateNotifierProvider<ProfileController, ProfileState>(
  (ref) => ProfileController(
    ref.watch(localPlayerStoreProvider),
    const OwnerKey.guest(),
  ),
);

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  if (!ref.watch(firebaseBootstrapProvider).enabled) {
    return _GuestOnlyAccountRepository();
  }
  return FirebaseAccountRepository(FirebaseAuth.instance);
});

final accountDeletionRepositoryProvider = Provider<AccountDeletionRepository?>((
  ref,
) {
  if (!ref.watch(firebaseBootstrapProvider).enabled) return null;
  return FirebaseAccountDeletionRepository(FirebaseFunctions.instance);
});

final accountProvider = StateNotifierProvider<AccountController, AccountState>(
  (ref) => AccountController(
    ref.watch(accountRepositoryProvider),
    store: ref.watch(localPlayerStoreProvider),
    deletionRepository: ref.watch(accountDeletionRepositoryProvider),
  ),
);

final dialogueSeenRepositoryProvider = Provider<DialogueSeenRepository>(
  (ref) => LocalDialogueSeenRepository(ref.watch(sharedPreferencesProvider)),
);

class DialogueSeenController extends StateNotifier<Set<DialogueId>> {
  DialogueSeenController(this._repo) : super(<DialogueId>{}) {
    restore();
  }

  final DialogueSeenRepository _repo;
  bool isRestored = false;

  Future<void> restore() async {
    state = Set<DialogueId>.of(await _repo.load());
    isRestored = true;
  }

  bool hasSeen(DialogueId id) => state.contains(id);

  Future<bool> markSeen(DialogueId id) async {
    if (state.contains(id)) return true;
    final Set<DialogueId> next = Set<DialogueId>.of(state)..add(id);
    if (!await _repo.save(next)) return false;
    state = next;
    return true;
  }
}

final dialogueSeenProvider =
    StateNotifierProvider<DialogueSeenController, Set<DialogueId>>(
      (ref) =>
          DialogueSeenController(ref.watch(dialogueSeenRepositoryProvider)),
    );

final hintControllerProvider =
    StateNotifierProvider.autoDispose<HintController, HintState>(
      (ref) => HintController(
        ref.read(progressProvider.notifier).spendOnHint,
        () => ref.read(progressProvider).canAfford(kHintCost),
      ),
    );

final rewardedAdServiceProvider = Provider<RewardedAdService>(
  (ref) => GoogleRewardedAdService(),
);

final rewardedAdProvider =
    StateNotifierProvider.autoDispose<RewardedAdController, RewardedAdState>(
      (ref) => RewardedAdController(
        ref.watch(rewardedAdServiceProvider),
        ref.read(progressProvider.notifier).grantCoins,
      ),
    );

/// Built once, then kept in step with settings via a listener.
///
/// Deliberately not `ref.watch(settingsProvider)` — that would tear down and
/// rebuild the audio service (and its player pool) every time the player flips
/// a toggle, cutting whatever is currently playing.
final gameAudioProvider = Provider<GameAudioService>((ref) {
  final AppSettings initial = ref.read(settingsProvider);
  final GameAudioService service = GameAudioService(
    enabled: initial.soundOn,
    musicEnabled: initial.musicOn,
  );

  ref.listen<AppSettings>(settingsProvider, (AppSettings? _, AppSettings next) {
    service.setEnabled(soundOn: next.soundOn, musicOn: next.musicOn);
  });

  ref.onDispose(service.stopAll);
  return service;
});

final gameAudioLifecycleProvider = Provider<GameAudioLifecycleCoordinator>((
  ref,
) {
  final GameAudioLifecycleCoordinator coordinator =
      GameAudioLifecycleCoordinator(ref.watch(gameAudioProvider));
  ref.onDispose(coordinator.dispose);
  return coordinator;
});

final hapticServiceProvider = Provider<HapticService>((ref) {
  final HapticService service = HapticService(
    enabled: ref.read(settingsProvider).hapticsOn,
  );
  ref.listen<AppSettings>(settingsProvider, (AppSettings? _, AppSettings next) {
    service.setEnabled(next.hapticsOn);
  });
  return service;
});
