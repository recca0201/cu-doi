import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import '../domain/leaderboard_models.dart';
import 'leaderboard_limits.dart';

typedef PlatformAvatarFetcher =
    Future<Uint8List?> Function(PlatformAvatarRef avatar);
typedef PlatformAvatarGuard = bool Function(PlatformAvatarRef avatar);

/// Bounded, memory-only loader for platform-owned leaderboard avatars.
///
/// A `null` result is the neutral per-row fallback. Failures never escape and
/// therefore cannot fail the containing leaderboard page.
class PlatformAvatarLoader {
  PlatformAvatarLoader({
    required this._fetch,
    PlatformAvatarGuard? isCurrent,
    this.timeout = kLeaderboardAvatarTimeout,
    this.maxAvatarBytes = kMaxAvatarBytes,
    this.maxConcurrentRequests = kMaxConcurrentAvatarRequests,
    this.maxPendingRequests = kMaxPendingAvatarRequests,
    this.maxCacheEntries = kMaxAvatarCacheEntries,
    this.maxCacheBytes = kMaxAvatarCacheBytes,
  }) : _isCurrent = isCurrent ?? _alwaysCurrent {
    if (timeout <= Duration.zero ||
        maxAvatarBytes < 1 ||
        maxConcurrentRequests < 1 ||
        maxPendingRequests < 1 ||
        maxCacheEntries < 1 ||
        maxCacheBytes < 1) {
      throw ArgumentError('Avatar loader limits must be positive');
    }
  }

  final PlatformAvatarFetcher _fetch;
  final PlatformAvatarGuard _isCurrent;

  final Duration timeout;
  final int maxAvatarBytes;
  final int maxConcurrentRequests;
  final int maxPendingRequests;
  final int maxCacheEntries;
  final int maxCacheBytes;

  final LinkedHashMap<PlatformAvatarRef, Uint8List> _cache =
      LinkedHashMap<PlatformAvatarRef, Uint8List>();
  final Map<PlatformAvatarRef, Future<Uint8List?>> _inFlight =
      <PlatformAvatarRef, Future<Uint8List?>>{};
  final Queue<_AvatarJob> _pending = Queue<_AvatarJob>();
  final Set<_AvatarJob> _activeJobs = <_AvatarJob>{};

  int _activeRequests = 0;
  int _cacheBytes = 0;
  int _generation = 0;

  int get cacheEntryCount => _cache.length;
  int get cacheByteCount => _cacheBytes;
  int get activeRequestCount => _activeRequests;
  int get pendingRequestCount => _pending.length;

  Future<Uint8List?> load(
    PlatformAvatarRef avatar, {
    int? identityEpoch,
    String? playerHash,
    bool Function()? remainsCurrent,
  }) async {
    if (!_matchesRow(
          avatar,
          identityEpoch: identityEpoch,
          playerHash: playerHash,
          remainsCurrent: remainsCurrent,
        ) ||
        !_isCurrent(avatar)) {
      return null;
    }

    final Uint8List? cached = _takeCached(avatar);
    if (cached != null) return Uint8List.fromList(cached);

    final Future<Uint8List?> request = _inFlight[avatar] ??= _enqueue(avatar);
    final Uint8List? bytes = await request;
    if (bytes == null ||
        !_matchesRow(
          avatar,
          identityEpoch: identityEpoch,
          playerHash: playerHash,
          remainsCurrent: remainsCurrent,
        ) ||
        !_isCurrent(avatar)) {
      return null;
    }
    return Uint8List.fromList(bytes);
  }

  Future<Uint8List?> loadForRow(
    PlatformAvatarRef avatar, {
    required int identityEpoch,
    required String playerHash,
    bool Function()? remainsCurrent,
  }) => load(
    avatar,
    identityEpoch: identityEpoch,
    playerHash: playerHash,
    remainsCurrent: remainsCurrent,
  );

  void clear() {
    _generation += 1;
    _cache.clear();
    _cacheBytes = 0;
    for (final _AvatarJob job in _pending) {
      job.cancel();
    }
    _pending.clear();
    for (final _AvatarJob job in _activeJobs) {
      job.cancel();
    }
    _inFlight.clear();
  }

  Future<Uint8List?> _enqueue(PlatformAvatarRef avatar) {
    if (_pending.length >= maxPendingRequests) {
      return Future<Uint8List?>.value();
    }
    final Completer<Uint8List?> completer = Completer<Uint8List?>();
    _pending.add(_AvatarJob(avatar, completer, _generation));
    _drain();
    final Future<Uint8List?> result = completer.future;
    unawaited(
      result.whenComplete(() {
        if (identical(_inFlight[avatar], result)) {
          _inFlight.remove(avatar);
        }
      }),
    );
    return result;
  }

  void _drain() {
    while (_activeRequests < maxConcurrentRequests && _pending.isNotEmpty) {
      final _AvatarJob job = _pending.removeFirst();
      if (job.cancelled || job.generation != _generation) {
        job.cancel();
        continue;
      }
      _activeRequests += 1;
      _activeJobs.add(job);
      unawaited(_run(job));
    }
  }

  Future<void> _run(_AvatarJob job) async {
    Uint8List? result;
    try {
      final Uint8List? fetched = await _fetch(job.avatar).timeout(timeout);
      if (fetched != null &&
          fetched.lengthInBytes <= maxAvatarBytes &&
          !job.cancelled &&
          job.generation == _generation &&
          _isCurrent(job.avatar)) {
        result = Uint8List.fromList(fetched);
        _store(job.avatar, result);
      }
    } catch (_) {
      result = null;
    } finally {
      _activeJobs.remove(job);
      _activeRequests -= 1;
      if (!job.completer.isCompleted) job.completer.complete(result);
      _drain();
    }
  }

  Uint8List? _takeCached(PlatformAvatarRef avatar) {
    final Uint8List? bytes = _cache.remove(avatar);
    if (bytes != null) _cache[avatar] = bytes;
    return bytes;
  }

  void _store(PlatformAvatarRef avatar, Uint8List bytes) {
    final Uint8List? previous = _cache.remove(avatar);
    if (previous != null) _cacheBytes -= previous.lengthInBytes;
    _cache[avatar] = bytes;
    _cacheBytes += bytes.lengthInBytes;

    while (_cache.length > maxCacheEntries || _cacheBytes > maxCacheBytes) {
      final PlatformAvatarRef oldest = _cache.keys.first;
      final Uint8List removed = _cache.remove(oldest)!;
      _cacheBytes -= removed.lengthInBytes;
    }
  }

  static bool _matchesRow(
    PlatformAvatarRef avatar, {
    required int? identityEpoch,
    required String? playerHash,
    required bool Function()? remainsCurrent,
  }) =>
      (identityEpoch == null || avatar.identityEpoch == identityEpoch) &&
      (playerHash == null || avatar.playerHash == playerHash) &&
      (remainsCurrent == null || remainsCurrent());

  static bool _alwaysCurrent(PlatformAvatarRef _) => true;
}

class _AvatarJob {
  _AvatarJob(this.avatar, this.completer, this.generation);

  final PlatformAvatarRef avatar;
  final Completer<Uint8List?> completer;
  final int generation;
  bool cancelled = false;

  void cancel() {
    cancelled = true;
    if (!completer.isCompleted) completer.complete(null);
  }
}
