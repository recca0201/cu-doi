import 'dart:async';

import 'package:flutter/widgets.dart';

import '../core/platform_avatar.dart';
import '../data/game_services_gateway.dart';
import '../data/leaderboard_repository.dart';
import '../domain/leaderboard_models.dart';
import '../domain/player_progress.dart';
import 'leaderboard_controller.dart';

/// App-root owner for game-services identity and retry lifecycle.
///
/// Construction subscribes to native identity events and registers the binding
/// observer, but it does not authenticate. [initializeSilently] is the only
/// startup action and delegates to the gateway's non-interactive restore path.
class LeaderboardLifecycleCoordinator with WidgetsBindingObserver {
  LeaderboardLifecycleCoordinator({
    required this._gateway,
    required this._repository,
    required this._submissions,
    required this._avatarLoader,
    required this._progress,
    required this._progressReady,
    required this._progressConfirmed,
    WidgetsBinding? binding,
  }) : _binding = binding ?? WidgetsBinding.instance {
    _binding.addObserver(this);
    _identityEvents = _gateway.identityEvents.listen(
      (PlatformIdentityEvent event) {
        _ignoreDetachedFailure(handlePlatformIdentityEvent(event));
      },
      onError: (Object _, StackTrace _) {
        // Unsupported hosts and a missing native event bridge are expected.
        // They must not affect startup, gameplay, Firebase, or local progress.
      },
    );
  }

  final GameServicesGateway _gateway;
  final LeaderboardRepository _repository;
  final LeaderboardSubmissionController _submissions;
  final PlatformAvatarLoader _avatarLoader;
  final PlayerProgress Function() _progress;
  final Future<void> Function() _progressReady;
  final bool Function() _progressConfirmed;
  final WidgetsBinding _binding;

  late final StreamSubscription<PlatformIdentityEvent> _identityEvents;
  Future<void> _tail = Future<void>.value();
  bool _disposed = false;

  /// Restores only an already available platform session. It never calls the
  /// interactive authentication method and never flushes scores at startup.
  Future<void> initializeSilently() => _serialized(() async {
    await _repository.restoreIdentity();
  });

  /// Retries durable submissions only for a confirmed, current identity.
  Future<void> onAppResumed() => _serialized(() async {
    // Refresh the native account/session binding before touching any durable
    // queue. This prevents an A queue from being flushed after the device has
    // switched to B while the app was suspended.
    await _repository.restoreIdentity();
    if (_repository.identityState.maySubmit) {
      await _submissions.onAppResumed();
    }
  });

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _ignoreDetachedFailure(onAppResumed());
    }
  }

  /// Applies identity invalidation synchronously before any queued async work.
  /// This is what makes late reads, submissions and avatar responses harmless.
  Future<void> handlePlatformIdentityEvent(PlatformIdentityEvent event) {
    if (_disposed) return Future<void>.value();
    final PlatformIdentityEvent? normalized = _normalizeEvent(event);
    if (normalized == null) return Future<void>.value();

    _repository.handleIdentityEvent(normalized);
    _avatarLoader.clear();
    _submissions.invalidateIdentitySynchronously();

    return _serialized(() async {
      if (!_eventStillCurrent(normalized)) return;
      if (normalized.kind == PlatformIdentityEventKind.authenticated &&
          _repository.identityState.maySubmit) {
        await _progressReady();
        if (!_eventStillCurrent(normalized)) return;
        await _submissions.onAuthenticated(
          _progress(),
          progressConfirmed: _progressConfirmed(),
        );
      } else {
        // Clear UI-facing state from the previous platform partition without
        // reading, submitting, or presenting authentication.
        await _submissions.refresh();
      }
    });
  }

  PlatformIdentityEvent? _normalizeEvent(PlatformIdentityEvent event) {
    final PlatformIdentityState current = _repository.identityState;
    if (event.epoch < current.epoch) return null;

    final PlatformIdentity? incoming = event.identity;
    final PlatformIdentity? existing = current.identity;
    final bool identityChanged =
        event.kind != PlatformIdentityEventKind.authenticated ||
        incoming?.platform != existing?.platform ||
        incoming?.playerId != existing?.playerId ||
        incoming?.sessionToken != existing?.sessionToken;
    final int epoch = identityChanged && event.epoch == current.epoch
        ? current.epoch + 1
        : event.epoch;

    return switch (event.kind) {
      PlatformIdentityEventKind.authenticated when incoming != null =>
        PlatformIdentityEvent.authenticated(identity: incoming, epoch: epoch),
      PlatformIdentityEventKind.signedOut => PlatformIdentityEvent.signedOut(
        epoch: epoch,
      ),
      PlatformIdentityEventKind.accountChanged =>
        PlatformIdentityEvent.accountChanged(identity: incoming, epoch: epoch),
      _ => null,
    };
  }

  bool _eventStillCurrent(PlatformIdentityEvent event) {
    final PlatformIdentityState current = _repository.identityState;
    if (current.epoch != event.epoch) return false;
    if (event.kind != PlatformIdentityEventKind.authenticated) return true;
    return current.identity?.platform == event.identity?.platform &&
        current.identity?.playerId == event.identity?.playerId &&
        current.identity?.sessionToken == event.identity?.sessionToken;
  }

  Future<void> _serialized(Future<void> Function() operation) {
    if (_disposed) return Future<void>.value();
    final Future<void> result = _tail.then((_) async {
      if (!_disposed) await operation();
    });
    _tail = result.then<void>((_) {}, onError: (_, _) {});
    return result;
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _binding.removeObserver(this);
    await _identityEvents.cancel();
    await _tail;
  }
}

void _ignoreDetachedFailure(Future<void> future) {
  unawaited(future.then<void>((_) {}, onError: (Object _, StackTrace _) {}));
}
