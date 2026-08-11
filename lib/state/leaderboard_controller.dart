import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/leaderboard_repository.dart';
import '../domain/leaderboard_models.dart';
import '../domain/player_progress.dart';

/// The leaderboard is deliberately all-time only. Keeping this as a typed
/// value prevents future UI code from accidentally presenting day/week as a
/// third filter beside Global and Friends.
enum LeaderboardPeriod { allTime }

/// Complete screen-state matrix from the approved handoff.
enum LeaderboardViewStatus {
  loaded,
  loading,
  empty,
  serviceError,
  offlineCache,
  offlineNoCache,
  friendsUnavailable,
  authPrompt,
}

/// Immutable, UI-facing state for one arena leaderboard route.
class LeaderboardViewState {
  LeaderboardViewState({
    required this.arenaId,
    required this.scope,
    required this.status,
    required this.submissionSummary,
    this.page,
    this.snapshot,
    this.reasonCode,
    this.isLoading = false,
  });

  final int arenaId;
  final LeaderboardScope scope;
  final LeaderboardPeriod period = LeaderboardPeriod.allTime;
  final LeaderboardViewStatus status;
  final LeaderboardPage? page;
  final LeaderboardSnapshot? snapshot;
  final String? reasonCode;
  final bool isLoading;
  final SubmissionSummary submissionSummary;

  /// Back and filter controls are never disabled by a read request.
  bool get canNavigateBack => true;
  bool get canSelectScope => true;
  bool get isStale => status == LeaderboardViewStatus.offlineCache;
  bool get hasRows => rowCount > 0;

  bool get canRetry => switch (status) {
    LeaderboardViewStatus.serviceError ||
    LeaderboardViewStatus.offlineCache ||
    LeaderboardViewStatus.offlineNoCache ||
    LeaderboardViewStatus.friendsUnavailable => true,
    _ => false,
  };

  int get rowCount {
    final LeaderboardPage? live = page;
    if (live != null) {
      return live.leaders.length + (live.currentPlayer == null ? 0 : 1);
    }
    final LeaderboardSnapshot? cached = snapshot;
    if (cached != null) {
      return cached.rows.length + (cached.currentPlayer == null ? 0 : 1);
    }
    return 0;
  }

  PendingScore? get arenaSubmission => submissionSummary.forArena(arenaId);

  LeaderboardViewState copyWith({
    LeaderboardScope? scope,
    LeaderboardViewStatus? status,
    LeaderboardPage? page,
    LeaderboardSnapshot? snapshot,
    String? reasonCode,
    bool? isLoading,
    SubmissionSummary? submissionSummary,
    bool clearPage = false,
    bool clearSnapshot = false,
    bool clearReasonCode = false,
  }) => LeaderboardViewState(
    arenaId: arenaId,
    scope: scope ?? this.scope,
    status: status ?? this.status,
    page: clearPage ? null : page ?? this.page,
    snapshot: clearSnapshot ? null : snapshot ?? this.snapshot,
    reasonCode: clearReasonCode ? null : reasonCode ?? this.reasonCode,
    isLoading: isLoading ?? this.isLoading,
    submissionSummary: submissionSummary ?? this.submissionSummary,
  );
}

/// Owns one arena context and its remembered Global/Friends scope.
///
/// Reads never invoke interactive authentication. [authenticateFromUserAction]
/// is the sole controller path that may cross that boundary after the Flutter
/// explanation dialog has been accepted by the player.
class LeaderboardController extends StateNotifier<LeaderboardViewState> {
  LeaderboardController(
    this._repository, {
    required int arenaId,
    this.onOpened,
    this.onAuthenticated,
    SubmissionSummary? submissionSummary,
  }) : super(
         _initialState(
           repository: _repository,
           arenaId: arenaId,
           submissionSummary: submissionSummary,
         ),
       ) {
    _repository.addIdentityInvalidationListener(
      _invalidateForIdentityChangeSynchronously,
    );
  }

  final LeaderboardRepository _repository;
  final Future<void> Function()? onOpened;
  final Future<void> Function()? onAuthenticated;

  int _requestSerial = 0;
  Future<void>? _openFuture;
  Future<bool>? _authenticationFuture;
  bool _disposed = false;

  /// Called when the route opens. Submission retry and board read start
  /// independently; repeat calls share the same future and cannot duplicate an
  /// opening-triggered queue flush.
  Future<void> open() => _openFuture ??= _open();

  Future<void> _open() async {
    await Future.wait<void>(<Future<void>>[_notifyOpened(), load()]);
  }

  Future<void> _notifyOpened() async {
    try {
      await onOpened?.call();
    } catch (_) {
      // Submission retry is best-effort and must not replace read state.
    }
  }

  Future<void> load() => _load(clearVisibleData: !state.hasRows);

  Future<void> retry() => _load(clearVisibleData: !state.hasRows);

  Future<void> selectScope(LeaderboardScope scope) async {
    if (scope == state.scope) return;

    // Invalidate the previous request synchronously, before either persistence
    // or the new network call gets a chance to yield.
    _requestSerial++;
    if (!_disposed) {
      state = state.copyWith(
        scope: scope,
        status: LeaderboardViewStatus.loading,
        isLoading: true,
        clearPage: true,
        clearSnapshot: true,
        clearReasonCode: true,
      );
    }

    final Future<void> persist = _repository.store
        .saveLastScope(scope)
        .catchError((Object _) {});
    await Future.wait<void>(<Future<void>>[
      persist,
      _load(clearVisibleData: true),
    ]);
  }

  /// Must only be called after an explicit confirmation in app UI.
  Future<bool> authenticateFromUserAction() {
    final Future<bool>? existing = _authenticationFuture;
    if (existing != null) return existing;
    final Future<bool> operation = _authenticateFromUserAction();
    _authenticationFuture = operation;
    unawaited(
      operation.whenComplete(() {
        if (identical(_authenticationFuture, operation)) {
          _authenticationFuture = null;
        }
      }),
    );
    return operation;
  }

  Future<bool> _authenticateFromUserAction() async {
    try {
      await _repository.authenticateFromUserAction();
      if (_disposed) return false;

      // Backfill persistence and the board read start together. The
      // submission controller begins its network flush only after durable
      // queueing, but that flush never gates the visible leaderboard.
      final Future<void> backfill = _notifyAuthenticated();
      final Future<void> board = _load(clearVisibleData: true);
      unawaited(backfill.catchError((Object _) {}));
      await board;
      return true;
    } catch (_) {
      if (!_disposed) {
        // This can reveal a matching last-known cache, but it still cannot
        // initiate another platform authentication prompt.
        await _load(clearVisibleData: true);
      }
      return false;
    }
  }

  Future<void> _notifyAuthenticated() async {
    try {
      await onAuthenticated?.call();
    } catch (_) {
      // A queue failure cannot invalidate successful platform auth/read.
    }
  }

  void updateSubmissionSummary(SubmissionSummary summary) {
    if (_disposed) return;
    state = state.copyWith(submissionSummary: summary);
  }

  void _invalidateForIdentityChangeSynchronously() {
    if (_disposed) return;
    _requestSerial++;
    final bool canLoadNewIdentity =
        _repository.identityState.mayUseMatchingCache &&
        _repository.identityState.identity != null;
    state = state.copyWith(
      status: canLoadNewIdentity
          ? LeaderboardViewStatus.loading
          : LeaderboardViewStatus.authPrompt,
      isLoading: canLoadNewIdentity,
      submissionSummary: SubmissionSummary(),
      clearPage: true,
      clearSnapshot: true,
      clearReasonCode: true,
    );
    if (canLoadNewIdentity && _authenticationFuture == null) {
      scheduleMicrotask(() {
        if (!_disposed) unawaited(_load(clearVisibleData: true));
      });
    }
  }

  Future<void> _load({required bool clearVisibleData}) async {
    final int serial = ++_requestSerial;
    final LeaderboardScope scope = state.scope;
    if (!_disposed) {
      state = clearVisibleData
          ? state.copyWith(
              status: LeaderboardViewStatus.loading,
              isLoading: true,
              clearPage: true,
              clearSnapshot: true,
              clearReasonCode: true,
            )
          : state.copyWith(isLoading: true, clearReasonCode: true);
    }

    try {
      final LeaderboardLoadResult result = await _repository.load(
        arenaId: state.arenaId,
        scope: scope,
        allowMatchingCache: true,
      );
      if (!_owns(serial, scope)) return;
      state = _fromResult(
        state,
        result,
        identityIsLastKnown:
            _repository.identityState.confidence ==
            IdentityConfidence.lastKnownUnchanged,
      );
    } on LeaderboardRequestDiscarded {
      // Repository request epochs and the local serial deliberately overlap:
      // either layer may identify an obsolete response first.
    } catch (_) {
      if (!_owns(serial, scope)) return;
      state = state.copyWith(
        status: LeaderboardViewStatus.serviceError,
        reasonCode: 'controller_error',
        isLoading: false,
        clearPage: true,
        clearSnapshot: true,
      );
    }
  }

  bool _owns(int serial, LeaderboardScope scope) =>
      !_disposed && serial == _requestSerial && state.scope == scope;

  @override
  void dispose() {
    _disposed = true;
    _requestSerial++;
    _repository.removeIdentityInvalidationListener(
      _invalidateForIdentityChangeSynchronously,
    );
    super.dispose();
  }

  static LeaderboardViewState _initialState({
    required LeaderboardRepository repository,
    required int arenaId,
    required SubmissionSummary? submissionSummary,
  }) {
    if (arenaId < 1 || arenaId > 20) {
      throw RangeError.range(arenaId, 1, 20, 'arenaId');
    }
    return LeaderboardViewState(
      arenaId: arenaId,
      scope: repository.store.loadLastScope(),
      status: LeaderboardViewStatus.loading,
      isLoading: true,
      submissionSummary: submissionSummary ?? SubmissionSummary(),
    );
  }

  static LeaderboardViewState _fromResult(
    LeaderboardViewState previous,
    LeaderboardLoadResult result, {
    required bool identityIsLastKnown,
  }) => switch (result.status) {
    LeaderboardLoadStatus.fresh => previous.copyWith(
      status: LeaderboardViewStatus.loaded,
      page: result.page,
      isLoading: false,
      clearSnapshot: true,
      clearReasonCode: true,
    ),
    LeaderboardLoadStatus.staleCache => previous.copyWith(
      status: LeaderboardViewStatus.offlineCache,
      snapshot: result.snapshot,
      isLoading: false,
      clearPage: true,
      clearReasonCode: true,
    ),
    LeaderboardLoadStatus.empty => previous.copyWith(
      status: LeaderboardViewStatus.empty,
      isLoading: false,
      clearPage: true,
      clearSnapshot: true,
      clearReasonCode: true,
    ),
    LeaderboardLoadStatus.friendsUnavailable => previous.copyWith(
      status: LeaderboardViewStatus.friendsUnavailable,
      reasonCode: result.reasonCode,
      isLoading: false,
      clearPage: true,
      clearSnapshot: true,
    ),
    LeaderboardLoadStatus.authRequired => previous.copyWith(
      status: identityIsLastKnown
          ? LeaderboardViewStatus.offlineNoCache
          : LeaderboardViewStatus.authPrompt,
      isLoading: false,
      clearPage: true,
      clearSnapshot: true,
      clearReasonCode: true,
    ),
    LeaderboardLoadStatus.serviceError => previous.copyWith(
      status: result.reasonCode == GameServicesFailureCode.retryable.name
          ? LeaderboardViewStatus.offlineNoCache
          : LeaderboardViewStatus.serviceError,
      reasonCode: result.reasonCode,
      isLoading: false,
      clearPage: true,
      clearSnapshot: true,
    ),
  };
}

/// Owns the UI-facing submission summary and delegates durable orchestration
/// to [LeaderboardRepository]. Lifecycle and screen owners invoke these
/// methods outside gameplay simulation/render callbacks.
class LeaderboardSubmissionController extends StateNotifier<SubmissionSummary> {
  LeaderboardSubmissionController(this._repository)
    : super(SubmissionSummary()) {
    _repository.addIdentityInvalidationListener(
      invalidateIdentitySynchronously,
    );
  }

  final LeaderboardRepository _repository;

  Future<void> onAuthenticated(
    PlayerProgress progress, {
    required bool progressConfirmed,
  }) async {
    await _guarded(() async {
      await _repository.enqueueEligibleHistory(
        progress,
        progressConfirmed: progressConfirmed,
      );
      state = _mergeSummary(await _repository.currentSubmissionSummary());
      _startDetachedFlush();
    });
  }

  Future<void> onPersistedWin(RecordOutcome outcome) async {
    await _guarded(() async {
      if (!outcome.persisted) {
        _recordReceipt(
          SubmissionReceipt(
            arenaId: outcome.arenaId,
            score: outcome.attemptedScore,
            status: SubmissionAttemptStatus.persistFailed,
            reasonCode: 'progress_write_failed',
          ),
        );
        return;
      }
      if (!outcome.isNewRecord) {
        _recordReceipt(
          SubmissionReceipt(
            arenaId: outcome.arenaId,
            score: outcome.attemptedScore,
            status: SubmissionAttemptStatus.notQueued,
            reasonCode: 'not_new_record',
          ),
        );
      } else {
        final SubmissionReceipt receipt = await _repository.enqueueNewHighScore(
          arenaId: outcome.arenaId,
          score: outcome.currentBest,
          progress: outcome.persistedProgress,
        );
        _recordReceipt(receipt);
        state = _mergeSummary(await _repository.currentSubmissionSummary());
      }
      _startDetachedFlush();
    });
  }

  Future<void> onAppResumed() => _guarded(_flush);

  Future<void> onLeaderboardOpened() => _guarded(_flush);

  Future<void> retryFailed(int arenaId) async {
    await _guarded(() async {
      await _repository.retryFailedManually(arenaId);
      final SubmissionReceipt? previous = state.receiptForArena(arenaId);
      if (previous != null) {
        _recordReceipt(
          previous.copyWith(
            status: SubmissionAttemptStatus.pending,
            clearReasonCode: true,
          ),
        );
      }
      await _flush();
    });
  }

  Future<void> refresh() => _guarded(() async {
    state = _mergeSummary(await _repository.currentSubmissionSummary());
  });

  void invalidateIdentitySynchronously() {
    state = SubmissionSummary();
  }

  @override
  void dispose() {
    _repository.removeIdentityInvalidationListener(
      invalidateIdentitySynchronously,
    );
    super.dispose();
  }

  Future<void> _flush() async {
    state = SubmissionSummary(
      scores: state.scores,
      receipts: state.receipts,
      isFlushing: true,
    );
    state = _mergeSummary(await _repository.flushEligibleSubmissions());
  }

  void _startDetachedFlush() {
    unawaited(_guarded(_flush));
  }

  void _recordReceipt(SubmissionReceipt receipt) {
    state = _mergeSummary(
      SubmissionSummary(
        scores: state.scores,
        receipts: <SubmissionReceipt>[receipt],
        isFlushing: state.isFlushing,
      ),
    );
  }

  SubmissionSummary _mergeSummary(SubmissionSummary incoming) {
    final Map<(int, int), SubmissionReceipt> receipts =
        <(int, int), SubmissionReceipt>{};
    for (final SubmissionReceipt receipt in state.receipts) {
      receipts[(receipt.arenaId, receipt.score)] = receipt;
    }
    for (final SubmissionReceipt receipt in incoming.receipts) {
      receipts[(receipt.arenaId, receipt.score)] = receipt;
    }
    return SubmissionSummary(
      scores: incoming.scores,
      receipts: receipts.values,
      isFlushing: incoming.isFlushing,
    );
  }

  Future<void> _guarded(Future<void> Function() operation) async {
    try {
      await operation();
    } catch (_) {
      // Queue/store/network failures must not interrupt gameplay or trigger
      // authentication. Preserve the last useful state and clear the spinner.
      try {
        state = _mergeSummary(await _repository.currentSubmissionSummary());
      } catch (_) {
        state = SubmissionSummary(
          scores: state.scores,
          receipts: state.receipts,
        );
      }
    }
  }
}
