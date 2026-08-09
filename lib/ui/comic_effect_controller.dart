import 'dart:math' as math;

import '../sim/arena.dart';
import '../sim/geometry.dart';
import '../sim/shot_runner.dart';

const int kMaxEffectElements = 24;

enum EffectKind { bank, blocked, broke, levelEnd }

class EffectTier {
  const EffectTier({
    required this.level,
    required this.duration,
    required this.spokeCount,
    required this.spokeLength,
    required this.spokeWidth,
  });

  final int level;
  final double duration;
  final int spokeCount;
  final double spokeLength;
  final double spokeWidth;

  static const List<EffectTier?> _tiers = <EffectTier?>[
    null,
    EffectTier(
      level: 1,
      duration: .22,
      spokeCount: 5,
      spokeLength: 3.5,
      spokeWidth: .35,
    ),
    EffectTier(
      level: 2,
      duration: .30,
      spokeCount: 7,
      spokeLength: 5.0,
      spokeWidth: .50,
    ),
    EffectTier(
      level: 3,
      duration: .40,
      spokeCount: 9,
      spokeLength: 7.0,
      spokeWidth: .70,
    ),
    EffectTier(
      level: 4,
      duration: .62,
      spokeCount: 14,
      spokeLength: 11.0,
      spokeWidth: 1.10,
    ),
  ];

  /// Level zero is intentionally empty. The bank-exhaustion event reuses the
  /// highest usable tier, derived from the gameplay constant rather than 4.
  static EffectTier? forLevel(int level) {
    if (level <= 0) return null;
    final int peak = kMaxBanks - 1;
    return _tiers[math.min(level, peak)]!;
  }
}

class EffectElement {
  EffectElement({required this.kind, required this.pos, required this.tier});

  final EffectKind kind;
  final V2 pos;
  final EffectTier tier;
  double age = 0;
}

class ComicEffectController {
  ComicEffectController({this.reducedMotion = false});

  bool reducedMotion;
  final List<EffectElement> elements = <EffectElement>[];

  bool get isNotEmpty => elements.isNotEmpty;

  void onEvent(
    ShotEvent event, {
    required int banksAtEvent,
    List<TargetSpec> targets = const <TargetSpec>[],
    List<bool> alive = const <bool>[],
  }) {
    if (reducedMotion) return;
    final int level = switch (event.kind) {
      ShotEventKind.bank => banksAtEvent,
      ShotEventKind.blocked => banksAtEvent,
      ShotEventKind.broke => math.min(1 + banksAtEvent, kMaxMultiplier),
    };
    final EffectTier? tier = EffectTier.forLevel(level);
    if (tier == null) return;
    V2 effectPosition = event.pos;
    if (_insideLivingTarget(effectPosition, targets, alive)) {
      if (event.kind != ShotEventKind.blocked) return;
      effectPosition = V2(event.pos.x, event.pos.y - kTargetRadius * 1.7);
      if (_insideLivingTarget(effectPosition, targets, alive)) return;
    }
    _add(
      EffectElement(
        kind: switch (event.kind) {
          ShotEventKind.bank => EffectKind.bank,
          ShotEventKind.blocked => EffectKind.blocked,
          ShotEventKind.broke => EffectKind.broke,
        },
        pos: effectPosition,
        tier: tier,
      ),
    );
  }

  void levelEnd(V2 pos) {
    if (reducedMotion) return;
    _add(
      EffectElement(
        kind: EffectKind.levelEnd,
        pos: pos,
        tier: EffectTier.forLevel(kMaxBanks - 1)!,
      ),
    );
  }

  void tick(double dt) {
    for (final EffectElement element in elements) {
      element.age += dt;
    }
    elements.removeWhere(
      (EffectElement element) => element.age > element.tier.duration,
    );
  }

  void endShot(ShotEndReason? reason) {
    if (reason == ShotEndReason.exitedBottom) clear();
  }

  void clear() => elements.clear();

  bool _insideLivingTarget(
    V2 point,
    List<TargetSpec> targets,
    List<bool> alive,
  ) {
    for (int i = 0; i < targets.length && i < alive.length; i++) {
      if (!alive[i]) continue;
      if ((point - targets[i].pos).length < kTargetRadius * 1.55) return true;
    }
    return false;
  }

  void _add(EffectElement element) {
    elements.add(element);
    if (elements.length > kMaxEffectElements) {
      elements.removeRange(0, elements.length - kMaxEffectElements);
    }
  }
}
