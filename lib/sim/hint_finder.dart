import 'dart:math' as math;

import 'arena.dart';
import 'geometry.dart';
import 'shot_runner.dart';

const double kHintSimulationDt = 1 / 120;
const int kHintSimulationStepGuard = 1680;

class ArenaSnapshot {
  ArenaSnapshot({
    required List<Segment> segments,
    required List<TargetSpec> targets,
    required List<bool> alive,
    required this.origin,
    required this.arenaId,
    this.samples = 361,
    this.budget = const Duration(seconds: 2),
  }) : segments = List<Segment>.unmodifiable(segments),
       targets = List<TargetSpec>.unmodifiable(targets),
       alive = List<bool>.unmodifiable(alive);

  final List<Segment> segments;
  final List<TargetSpec> targets;
  final List<bool> alive;
  final V2 origin;
  final int arenaId;
  final int samples;
  final Duration budget;
}

class HintShot {
  const HintShot({
    required this.aim,
    required this.path,
    required this.targetsDestroyed,
  });

  final V2 aim;
  final List<V2> path;
  final int targetsDestroyed;
}

HintShot? findHintShot(ArenaSnapshot snapshot) {
  if (!snapshot.alive.any((bool value) => value) || snapshot.samples <= 0) {
    return null;
  }

  final Stopwatch stopwatch = Stopwatch()..start();
  final double maxX = math.sqrt(1 - kMinAimUp * kMinAimUp);
  for (int sample = 0; sample < snapshot.samples; sample++) {
    final double fraction = snapshot.samples == 1
        ? 0.5
        : sample / (snapshot.samples - 1);
    final V2 aim = V2(-maxX + 2 * maxX * fraction, -kMinAimUp).normalized;
    final ShotRunner probe = ShotRunner(
      segments: snapshot.segments,
      targets: snapshot.targets,
      alive: List<bool>.of(snapshot.alive),
      origin: snapshot.origin,
      direction: aim,
      recordTrail: false,
    );
    final List<V2> path = <V2>[snapshot.origin];
    V2? lastBreak;
    int destroyed = 0;
    int guard = 0;
    while (probe.ball.alive && guard < kHintSimulationStepGuard) {
      probe.step(kHintSimulationDt);
      for (final ShotEvent event in probe.pending) {
        if (event.kind == ShotEventKind.bank ||
            event.kind == ShotEventKind.blocked) {
          path.add(event.pos);
        } else if (event.kind == ShotEventKind.broke) {
          destroyed++;
          lastBreak = event.pos;
        }
      }
      probe.pending.clear();
      guard++;
    }
    if (destroyed > 0 && lastBreak != null) {
      path.add(lastBreak);
      return HintShot(
        aim: aim,
        path: List<V2>.unmodifiable(path),
        targetsDestroyed: destroyed,
      );
    }
    if (stopwatch.elapsed >= snapshot.budget) return null;
  }
  return null;
}
