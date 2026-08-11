import 'dart:async';
import 'dart:developer' as dev;

import '../core/leaderboard_limits.dart';
import '../domain/leaderboard_models.dart';
import '../domain/leaderboard_score_policy.dart';
import '../domain/player_progress.dart';
import 'game_services_gateway.dart';
import 'identity_hasher.dart';
import 'local_leaderboard_store.dart';

/// Signals that a leaderboard read completed after a newer request or identity
/// epoch had already taken ownership of the result channel.
///
/// Controllers should ignore this exception. It is deliberately distinct from
/// a service error: retry UI for an obsolete scope/account would be misleading.
class LeaderboardRequestDiscarded implements Exception {
  const LeaderboardRequestDiscarded();

  @override
  String toString() => 'LeaderboardRequestDiscarded';
}

/// Coordinates platform reads with identity-partitioned offline snapshots.
///
/// This class has no Firebase dependency. A platform player is the sole
/// identity authority for leaderboard cache and submission partitions.
class LeaderboardRepository {
  LeaderboardRepository({
    required this.gateway,
    required this.store,
    required this.identityHasher,
    this._scorePolicy = const ArenaLeaderboardScorePolicy(),
    PlatformIdentityState initialIdentityState =
        const PlatformIdentityState.unknown(),
    DateTime Function()? now,
  }) : _identityState = initialIdentityState,
       _now = now ?? DateTime.now;

  final GameServicesGateway gateway;
  final LocalLeaderboardStore store;
  final IdentityHasher identityHasher;
  final LeaderboardScorePolicy _scorePolicy;
  final DateTime Function() _now;

  PlatformIdentityState _identityState;
  Future<void>? _hasherInitialization;
  Future<void> _submissionTail = Future<void>.value();
  int _requestEpoch = 0;
  final Set<void Function()> _identityInvalidationListeners =
      <void Function()>{};

  PlatformIdentityState get identityState => _identityState;
  int get identityEpoch => _identityState.epoch;
  int get requestEpoch => _requestEpoch;

  void addIdentityInvalidationListener(void Function() listener) {
    _identityInvalidationListeners.add(listener);
  }

  void removeIdentityInvalidationListener(void Function() listener) {
    _identityInvalidationListeners.remove(listener);
  }

  /// Inspects the existing platform session without allowing native auth UI.
  Future<PlatformIdentityState> restoreIdentity() async {
    await _ensureHasherInitialized();
    final int epochAtStart = identityEpoch;
    final int requestAtStart = _requestEpoch;
    try {
      final PlatformIdentity? restored = await gateway.restoreIdentity();
      if (identityEpoch != epochAtStart || requestAtStart != _requestEpoch) {
        return _identityState;
      }
      if (restored == null) {
        _retainLastKnownOrBecomeUnknown();
      } else {
        _confirmIdentity(restored);
      }
    } on GameServicesException {
      if (identityEpoch == epochAtStart && requestAtStart == _requestEpoch) {
        // A failed silent refresh is not evidence of an account switch. Cache
        // remains eligible only when this process already knew the identity.
        _retainLastKnownOrBecomeUnknown();
      }
    }
    return _identityState;
  }

  /// The only repository path that may ask the native bridge to present auth.
  Future<PlatformIdentity> authenticateFromUserAction() async {
    await _ensureHasherInitialized();
    try {
      final PlatformIdentity identity = await gateway.authenticate(
        interactive: true,
      );
      _confirmIdentity(identity);
      return identity;
    } catch (_) {
      _retainLastKnownOrBecomeUnknown();
      rethrow;
    }
  }

  /// Applies a native account event and invalidates all work from older epochs.
  ///
  /// Lifecycle wiring may call this method from [GameServicesGateway.identityEvents].
  /// Firebase account events must not be forwarded here.
  void handleIdentityEvent(PlatformIdentityEvent event) {
    if (event.epoch < identityEpoch) return;
    _requestEpoch++;
    switch (event.kind) {
      case PlatformIdentityEventKind.authenticated:
        final PlatformIdentity? identity = event.identity;
        _identityState = identity == null
            ? PlatformIdentityState(
                confidence: IdentityConfidence.unknown,
                epoch: event.epoch,
              )
            : PlatformIdentityState(
                confidence: IdentityConfidence.confirmedCurrent,
                epoch: event.epoch,
                identity: identity,
              );
      case PlatformIdentityEventKind.signedOut:
        _identityState = PlatformIdentityState(
          confidence: IdentityConfidence.changed,
          epoch: event.epoch,
        );
      case PlatformIdentityEventKind.accountChanged:
        _identityState = PlatformIdentityState(
          confidence: IdentityConfidence.changed,
          epoch: event.epoch,
          identity: event.identity,
        );
    }
    _notifyIdentityInvalidated();
  }

  /// Alias used by lifecycle adapters that phrase native messages as updates.
  void applyIdentityEvent(PlatformIdentityEvent event) =>
      handleIdentityEvent(event);

  /// Invalidates reads when a route closes or changes context.
  void invalidatePendingLoads() {
    _requestEpoch++;
  }

  Future<LeaderboardLoadResult> load({
    required int arenaId,
    required LeaderboardScope scope,
    required bool allowMatchingCache,
  }) async {
    if (arenaId < 1 || arenaId > 20) {
      throw RangeError.range(arenaId, 1, 20, 'arenaId');
    }
    final PlatformIdentityState state = _identityState;
    final PlatformIdentity? identity = state.identity;
    if (!state.mayUseMatchingCache || identity == null) {
      return const LeaderboardLoadResult.authRequired();
    }

    final int requestAtStart = ++_requestEpoch;
    final int identityEpochAtStart = state.epoch;
    await _ensureHasherInitialized();
    _throwIfObsolete(requestAtStart, identityEpochAtStart);
    final LeaderboardCacheKey key = LeaderboardCacheKey(
      platform: identity.platform,
      identityHash: identityHasher.hashPlayerId(identity.playerId),
      arenaId: arenaId,
      scope: scope,
    );
    Future<LeaderboardSnapshot?> readMatchingCache() => allowMatchingCache
        ? store.loadSnapshot(key)
        : Future<LeaderboardSnapshot?>.value();

    // lastKnownUnchanged is cache-readable but not an authenticated network or
    // submission identity. In particular, this never invokes auth UI.
    if (state.confidence == IdentityConfidence.lastKnownUnchanged) {
      final LeaderboardSnapshot? cached = await readMatchingCache();
      _throwIfObsolete(requestAtStart, identityEpochAtStart);
      return cached == null
          ? const LeaderboardLoadResult.authRequired()
          : LeaderboardLoadResult.staleCache(
              _normalizeCachedSnapshot(cached, key.identityHash),
            );
    }

    try {
      final LeaderboardPage loaded = await gateway.loadLeaderboard(
        identity: identity,
        arenaId: arenaId,
        scope: scope,
        limit: kMaxLeaderboardRows,
      );
      _throwIfObsolete(requestAtStart, identityEpochAtStart);
      final LeaderboardPage page = _normalizePage(loaded, identity.playerId);
      final LeaderboardSnapshot snapshot = _snapshotFromPage(page);

      // Only a complete successful platform read reaches this write. Failure,
      // timeout and obsolete-response paths leave the previous cache untouched.
      try {
        await store.saveSnapshot(key, snapshot);
      } catch (error, stackTrace) {
        // A cache is an offline optimization. A complete, identity-bound
        // platform response remains fresh even when the local snapshot cannot
        // be written.
        dev.log(
          'leaderboard snapshot write failed',
          name: 'data.leaderboard_repository',
          error: error.runtimeType,
          stackTrace: stackTrace,
        );
      }
      _throwIfObsolete(requestAtStart, identityEpochAtStart);

      if (page.leaders.isEmpty && page.currentPlayer == null) {
        return const LeaderboardLoadResult.empty();
      }
      return LeaderboardLoadResult.fresh(page);
    } on LeaderboardRequestDiscarded {
      rethrow;
    } on GameServicesException catch (error) {
      _throwIfObsolete(requestAtStart, identityEpochAtStart);
      if (error.code == GameServicesFailureCode.friendsUnavailable) {
        return LeaderboardLoadResult.friendsUnavailable(
          reasonCode: error.reasonCode,
        );
      }
      if (error.code == GameServicesFailureCode.unauthenticated) {
        // Native identity mismatch is also reported on the event channel, but
        // that event can arrive after this method reply. Invalidate now so an
        // old-account cache cannot be surfaced in the intervening frame.
        _rejectCurrentIdentity();
        return const LeaderboardLoadResult.authRequired();
      }
      final LeaderboardSnapshot? cached = await readMatchingCache();
      _throwIfObsolete(requestAtStart, identityEpochAtStart);
      if (cached != null) {
        return LeaderboardLoadResult.staleCache(
          _normalizeCachedSnapshot(cached, key.identityHash),
        );
      }
      return switch (error.code) {
        GameServicesFailureCode.unauthenticated ||
        GameServicesFailureCode.cancelled ||
        GameServicesFailureCode.restricted =>
          const LeaderboardLoadResult.authRequired(),
        _ => LeaderboardLoadResult.serviceError(reasonCode: error.reasonCode),
      };
    } catch (_) {
      _throwIfObsolete(requestAtStart, identityEpochAtStart);
      final LeaderboardSnapshot? cached = await readMatchingCache();
      _throwIfObsolete(requestAtStart, identityEpochAtStart);
      return cached == null
          ? const LeaderboardLoadResult.serviceError(
              reasonCode: 'invalid_response',
            )
          : LeaderboardLoadResult.staleCache(
              _normalizeCachedSnapshot(cached, key.identityHash),
            );
    }
  }

  /// Durably queues each eligible local record once for the active platform
  /// identity. The marker is written only after all twenty records have been
  /// evaluated and all eligible queue writes have completed.
  Future<void> enqueueEligibleHistory(
    PlayerProgress progress, {
    required bool progressConfirmed,
  }) async {
    if (!progressConfirmed) return;
    final _SubmissionBinding? binding = await _submissionBinding(
      requireConfirmedIdentity: true,
    );
    if (binding == null || !_bindingIsCurrent(binding, requireSubmit: true)) {
      return;
    }
    if (await store.hasCompletedInitialBackfill(binding.identityKey)) return;
    if (!_bindingIsCurrent(binding, requireSubmit: true)) return;

    for (int arenaId = 1; arenaId <= 20; arenaId++) {
      final int score = progress.highScoreFor(arenaId);
      final ScoreValidation validation = _scorePolicy.validate(
        arenaId: arenaId,
        score: score,
        progress: progress,
      );
      if (!validation.isEligible) continue;
      if (!_bindingIsCurrent(binding, requireSubmit: true)) return;
      await store.upsertHighest(
        PendingScore(
          identityHash: binding.identityKey.identityHash,
          platform: binding.identityKey.platform,
          arenaId: arenaId,
          score: score,
        ),
      );
    }

    if (_bindingIsCurrent(binding, requireSubmit: true)) {
      await store.markInitialBackfillComplete(binding.identityKey);
    }
  }

  /// Queues a score only against the exact post-save progress snapshot.
  ///
  /// Callers must await local progress persistence before invoking this method.
  Future<SubmissionReceipt> enqueueNewHighScore({
    required int arenaId,
    required int score,
    required PlayerProgress progress,
  }) async {
    final _SubmissionBinding? binding = await _submissionBinding(
      requireConfirmedIdentity: true,
    );
    if (binding == null || !_bindingIsCurrent(binding, requireSubmit: true)) {
      return SubmissionReceipt(
        arenaId: arenaId,
        score: score,
        status: SubmissionAttemptStatus.notQueued,
        reasonCode: GameServicesFailureCode.unauthenticated.name,
      );
    }
    final ScoreValidation validation = _scorePolicy.validate(
      arenaId: arenaId,
      score: score,
      progress: progress,
    );
    if (!validation.isEligible) {
      return SubmissionReceipt(
        arenaId: arenaId,
        score: score,
        status: SubmissionAttemptStatus.notQueued,
        reasonCode: validation.reason?.name,
      );
    }
    if (!_bindingIsCurrent(binding, requireSubmit: true)) {
      return SubmissionReceipt(
        arenaId: arenaId,
        score: score,
        status: SubmissionAttemptStatus.notQueued,
        reasonCode: GameServicesFailureCode.unauthenticated.name,
      );
    }
    try {
      await store.upsertHighest(
        PendingScore(
          identityHash: binding.identityKey.identityHash,
          platform: binding.identityKey.platform,
          arenaId: arenaId,
          score: score,
        ),
      );
      if (!_bindingIsCurrent(binding, requireSubmit: true)) {
        return SubmissionReceipt(
          arenaId: arenaId,
          score: score,
          status: SubmissionAttemptStatus.notQueued,
          reasonCode: GameServicesFailureCode.unauthenticated.name,
        );
      }
      PendingScore? queued;
      for (final PendingScore item in await store.loadSubmissions(
        binding.identityKey,
      )) {
        if (item.arenaId == arenaId) {
          queued = item;
          break;
        }
      }
      if (queued == null || queued.score != score) {
        return SubmissionReceipt(
          arenaId: arenaId,
          score: score,
          status: SubmissionAttemptStatus.persistFailed,
          reasonCode: 'queue_write_failed',
        );
      }
      return SubmissionReceipt(
        arenaId: arenaId,
        score: score,
        status: queued.state == SubmissionState.permanentlyFailed
            ? SubmissionAttemptStatus.failed
            : SubmissionAttemptStatus.pending,
        reasonCode: queued.reasonCode,
      );
    } catch (_) {
      return SubmissionReceipt(
        arenaId: arenaId,
        score: score,
        status: SubmissionAttemptStatus.persistFailed,
        reasonCode: 'queue_write_failed',
      );
    }
  }

  /// Flushes one identity's pending scores in arena order.
  ///
  /// Calls are chained onto a single tail. Each call captures its identity
  /// epoch before joining the tail, so a trigger from an old account cannot
  /// become work for a newly selected account while it waits.
  Future<SubmissionSummary> flushEligibleSubmissions() {
    final PlatformIdentityState stateAtCall = _identityState;
    final completer = Completer<SubmissionSummary>();
    _submissionTail = _submissionTail.then((_) async {
      try {
        completer.complete(await _flushForState(stateAtCall));
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  /// Moves one permanent failure back to pending. It is not submitted until
  /// the caller explicitly invokes a flush (the controller does both for the
  /// manual Retry action).
  Future<void> retryFailedManually(int arenaId) async {
    final _SubmissionBinding? binding = await _submissionBinding(
      requireConfirmedIdentity: true,
    );
    if (binding == null || !_bindingIsCurrent(binding, requireSubmit: true)) {
      return;
    }
    final List<PendingScore> submissions = await store.loadSubmissions(
      binding.identityKey,
    );
    PendingScore? failed;
    for (final PendingScore item in submissions) {
      if (item.arenaId == arenaId &&
          item.state == SubmissionState.permanentlyFailed) {
        failed = item;
        break;
      }
    }
    if (failed == null || !_bindingIsCurrent(binding, requireSubmit: true)) {
      return;
    }
    await store.retryPermanentlyFailed(failed);
  }

  /// Returns submission state only for the currently known identity partition.
  Future<SubmissionSummary> currentSubmissionSummary() async {
    final _SubmissionBinding? binding = await _submissionBinding(
      requireConfirmedIdentity: false,
    );
    if (binding == null || !_bindingIsCurrent(binding)) {
      return SubmissionSummary();
    }
    return _summaryFor(binding);
  }

  Future<SubmissionSummary> _flushForState(
    PlatformIdentityState stateAtCall,
  ) async {
    if (!stateAtCall.maySubmit ||
        !_sameIdentityState(stateAtCall, _identityState)) {
      return currentSubmissionSummary();
    }
    await _ensureHasherInitialized();
    if (!_sameIdentityState(stateAtCall, _identityState)) {
      return currentSubmissionSummary();
    }
    final PlatformIdentity identity = stateAtCall.identity!;
    final _SubmissionBinding binding = _SubmissionBinding(
      epoch: stateAtCall.epoch,
      playerId: identity.playerId,
      sessionToken: identity.sessionToken,
      identityKey: IdentityKey(
        platform: identity.platform,
        identityHash: identityHasher.hashPlayerId(identity.playerId),
      ),
    );
    if (!_bindingIsCurrent(binding, requireSubmit: true)) {
      return currentSubmissionSummary();
    }

    final List<PendingScore> submissions = await store.loadSubmissions(
      binding.identityKey,
    );
    final List<SubmissionReceipt> receipts = <SubmissionReceipt>[];
    for (final PendingScore item in submissions) {
      if (item.state != SubmissionState.pending) continue;
      if (!_bindingIsCurrent(binding, requireSubmit: true)) break;
      try {
        await gateway.submitScore(
          identity: identity,
          arenaId: item.arenaId,
          score: item.score,
        );
        if (!_bindingIsCurrent(binding, requireSubmit: true)) break;
        await store.removeSubmission(item);
        receipts.add(
          SubmissionReceipt(
            arenaId: item.arenaId,
            score: item.score,
            status: SubmissionAttemptStatus.accepted,
          ),
        );
      } on GameServicesException catch (error) {
        if (!_bindingIsCurrent(binding, requireSubmit: true)) break;
        switch (error.code) {
          case GameServicesFailureCode.unauthenticated:
            _rejectCurrentIdentity();
            break;
          case GameServicesFailureCode.cancelled:
          case GameServicesFailureCode.restricted:
            _retainLastKnownOrBecomeUnknown();
            break;
          case GameServicesFailureCode.retryable:
          case GameServicesFailureCode.friendsUnavailable:
            break;
          case GameServicesFailureCode.permanent:
          case GameServicesFailureCode.unsupported:
            await store.markPermanentlyFailed(item, error.reasonCode);
            receipts.add(
              SubmissionReceipt(
                arenaId: item.arenaId,
                score: item.score,
                status: SubmissionAttemptStatus.failed,
                reasonCode: error.reasonCode,
              ),
            );
            continue;
        }
        break;
      } catch (_) {
        // Unknown transport/channel failures remain pending for a later
        // approved trigger. Automatic retry never starts authentication.
        break;
      }
    }
    return _bindingIsCurrent(binding)
        ? _summaryFor(binding, receipts: receipts)
        : currentSubmissionSummary();
  }

  Future<_SubmissionBinding?> _submissionBinding({
    required bool requireConfirmedIdentity,
  }) async {
    final PlatformIdentityState state = _identityState;
    final PlatformIdentity? identity = state.identity;
    if (identity == null ||
        (requireConfirmedIdentity ? !state.maySubmit : false)) {
      return null;
    }
    await _ensureHasherInitialized();
    if (!_sameIdentityState(state, _identityState)) return null;
    return _SubmissionBinding(
      epoch: state.epoch,
      playerId: identity.playerId,
      sessionToken: identity.sessionToken,
      identityKey: IdentityKey(
        platform: identity.platform,
        identityHash: identityHasher.hashPlayerId(identity.playerId),
      ),
    );
  }

  bool _bindingIsCurrent(
    _SubmissionBinding binding, {
    bool requireSubmit = false,
  }) {
    final PlatformIdentityState current = _identityState;
    final PlatformIdentity? identity = current.identity;
    return identity != null &&
        current.epoch == binding.epoch &&
        identity.platform == binding.identityKey.platform &&
        identity.playerId == binding.playerId &&
        identity.sessionToken == binding.sessionToken &&
        (!requireSubmit || current.maySubmit);
  }

  bool _sameIdentityState(
    PlatformIdentityState left,
    PlatformIdentityState right,
  ) =>
      left.epoch == right.epoch &&
      left.confidence == right.confidence &&
      left.identity?.platform == right.identity?.platform &&
      left.identity?.playerId == right.identity?.playerId &&
      left.identity?.sessionToken == right.identity?.sessionToken;

  Future<SubmissionSummary> _summaryFor(
    _SubmissionBinding binding, {
    Iterable<SubmissionReceipt> receipts = const <SubmissionReceipt>[],
  }) async {
    final List<PendingScore> scores = await store.loadSubmissions(
      binding.identityKey,
    );
    if (!_bindingIsCurrent(binding)) return SubmissionSummary();
    return SubmissionSummary(scores: scores, receipts: receipts);
  }

  Future<void> _ensureHasherInitialized() =>
      _hasherInitialization ??= identityHasher.initialize();

  void _confirmIdentity(PlatformIdentity identity) {
    final PlatformIdentity? previous = _identityState.identity;
    final bool sameIdentity =
        previous?.platform == identity.platform &&
        previous?.playerId == identity.playerId &&
        previous?.sessionToken == identity.sessionToken;
    final bool alreadyConfirmed =
        sameIdentity &&
        _identityState.confidence == IdentityConfidence.confirmedCurrent;
    final int nextEpoch = sameIdentity
        ? _identityState.epoch
        : _identityState.epoch + 1;
    _requestEpoch++;
    _identityState = PlatformIdentityState(
      confidence: IdentityConfidence.confirmedCurrent,
      epoch: nextEpoch,
      identity: identity,
    );
    if (!alreadyConfirmed) _notifyIdentityInvalidated();
  }

  void _notifyIdentityInvalidated() {
    for (final void Function() listener in List<void Function()>.of(
      _identityInvalidationListeners,
    )) {
      listener();
    }
  }

  void _retainLastKnownOrBecomeUnknown() {
    final PlatformIdentityState previous = _identityState;
    final PlatformIdentity? identity = _identityState.identity;
    _requestEpoch++;
    if (identity != null &&
        (_identityState.confidence == IdentityConfidence.confirmedCurrent ||
            _identityState.confidence ==
                IdentityConfidence.lastKnownUnchanged)) {
      _identityState = PlatformIdentityState(
        confidence: IdentityConfidence.lastKnownUnchanged,
        epoch: _identityState.epoch,
        identity: identity,
      );
    } else {
      _identityState = PlatformIdentityState(
        confidence: IdentityConfidence.unknown,
        epoch: _identityState.epoch,
      );
    }
    if (!_sameIdentityState(previous, _identityState)) {
      _notifyIdentityInvalidated();
    }
  }

  void _rejectCurrentIdentity() {
    _requestEpoch++;
    _identityState = PlatformIdentityState(
      confidence: IdentityConfidence.changed,
      epoch: _identityState.epoch + 1,
    );
    _notifyIdentityInvalidated();
  }

  void _throwIfObsolete(int request, int identityEpoch) {
    if (request != _requestEpoch || identityEpoch != _identityState.epoch) {
      throw const LeaderboardRequestDiscarded();
    }
  }

  LeaderboardPage _normalizePage(
    LeaderboardPage source,
    String currentPlayerId,
  ) {
    final List<LeaderboardEntry> leaders = source.leaders
        .take(kMaxLeaderboardRows)
        .map(
          (LeaderboardEntry row) =>
              _copyEntry(row, isCurrentPlayer: row.playerId == currentPlayerId),
        )
        .toList(growable: false);
    final bool currentIsInLeaders = leaders.any(
      (LeaderboardEntry row) => row.playerId == currentPlayerId,
    );
    final LeaderboardEntry? separate = source.currentPlayer;
    final LeaderboardEntry? currentPlayer =
        currentIsInLeaders ||
            separate == null ||
            separate.playerId != currentPlayerId
        ? null
        : _copyEntry(separate, isCurrentPlayer: true);
    return LeaderboardPage(leaders: leaders, currentPlayer: currentPlayer);
  }

  LeaderboardEntry _copyEntry(
    LeaderboardEntry source, {
    required bool isCurrentPlayer,
  }) => LeaderboardEntry(
    rank: source.rank,
    playerId: source.playerId,
    displayName: source.displayName,
    score: source.score,
    isCurrentPlayer: isCurrentPlayer,
    avatar: source.avatar,
  );

  LeaderboardSnapshot _snapshotFromPage(LeaderboardPage page) =>
      LeaderboardSnapshot(
        rows: page.leaders.map(_persistedRow),
        currentPlayer: page.currentPlayer == null
            ? null
            : _persistedRow(page.currentPlayer!),
        fetchedAt: _now().toUtc(),
      );

  PersistedLeaderboardRow _persistedRow(LeaderboardEntry row) =>
      PersistedLeaderboardRow(
        rank: row.rank,
        playerHash: identityHasher.hashPlayerId(row.playerId),
        displayName: row.displayName,
        score: row.score,
        isCurrentPlayer: row.isCurrentPlayer,
      );

  LeaderboardSnapshot _normalizeCachedSnapshot(
    LeaderboardSnapshot source,
    String currentPlayerHash,
  ) {
    final List<PersistedLeaderboardRow> rows = source.rows
        .take(kMaxLeaderboardRows)
        .map(
          (PersistedLeaderboardRow row) => _copyPersistedRow(
            row,
            isCurrentPlayer: row.playerHash == currentPlayerHash,
          ),
        )
        .toList(growable: false);
    final bool currentIsInRows = rows.any(
      (PersistedLeaderboardRow row) => row.playerHash == currentPlayerHash,
    );
    final PersistedLeaderboardRow? separate = source.currentPlayer;
    return LeaderboardSnapshot(
      rows: rows,
      currentPlayer:
          currentIsInRows ||
              separate == null ||
              separate.playerHash != currentPlayerHash
          ? null
          : _copyPersistedRow(separate, isCurrentPlayer: true),
      fetchedAt: source.fetchedAt,
      schemaVersion: source.schemaVersion,
    );
  }

  PersistedLeaderboardRow _copyPersistedRow(
    PersistedLeaderboardRow source, {
    required bool isCurrentPlayer,
  }) => PersistedLeaderboardRow(
    rank: source.rank,
    playerHash: source.playerHash,
    displayName: source.displayName,
    score: source.score,
    isCurrentPlayer: isCurrentPlayer,
  );
}

class _SubmissionBinding {
  const _SubmissionBinding({
    required this.epoch,
    required this.playerId,
    required this.sessionToken,
    required this.identityKey,
  });

  final int epoch;
  final String playerId;
  final String sessionToken;
  final IdentityKey identityKey;
}
