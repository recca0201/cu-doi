import 'dart:async';

import 'package:flutter/services.dart';

const Duration kHapticCooldown = Duration(milliseconds: 60);

enum HapticEvent { bank, blockedShot, targetBroken, levelEnd }

/// Best-effort haptic feedback fed by the same presentation events as audio
/// and comic effects. Gameplay events share one cooldown bucket; the terminal
/// cue is deliberately exempt so a last target break cannot swallow it.
class HapticService {
  factory HapticService({required bool enabled, DateTime Function()? now}) =>
      HapticService._(enabled, now ?? DateTime.now);

  HapticService._(this._enabled, this._now);

  bool _enabled;
  final DateTime Function() _now;
  final Map<int, DateTime> _lastFired = <int, DateTime>{};

  static const Map<HapticEvent, int> _bucket = <HapticEvent, int>{
    HapticEvent.bank: 0,
    HapticEvent.blockedShot: 0,
    HapticEvent.targetBroken: 0,
    HapticEvent.levelEnd: 1,
  };

  static const Map<int, Duration> _cooldown = <int, Duration>{
    0: kHapticCooldown,
    1: Duration.zero,
  };

  bool get enabled => _enabled;

  void setEnabled(bool value) {
    _enabled = value;
    if (!value) _lastFired.clear();
  }

  void fire(HapticEvent event) {
    if (!_enabled) return;
    final int bucket = _bucket[event]!;
    final DateTime now = _now();
    final DateTime? previous = _lastFired[bucket];
    if (previous != null && now.difference(previous) < _cooldown[bucket]!) {
      return;
    }
    _lastFired[bucket] = now;

    final Future<void> result = switch (event) {
      HapticEvent.bank => HapticFeedback.selectionClick(),
      HapticEvent.blockedShot => HapticFeedback.mediumImpact(),
      HapticEvent.targetBroken => HapticFeedback.heavyImpact(),
      HapticEvent.levelEnd => HapticFeedback.vibrate(),
    };
    unawaited(result.catchError((Object _) {}));
  }
}
