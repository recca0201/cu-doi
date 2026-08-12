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
    required this.targetIndices,
  });

  final V2 aim;
  final List<V2> path;
  final List<int> targetIndices;

  int get targetsDestroyed => targetIndices.length;
}

class _HintCandidate {
  const _HintCandidate({
    required this.aim,
    required this.path,
    required this.targetIndices,
  });

  final V2 aim;
  final List<V2> path;
  final List<int> targetIndices;
}

HintShot? findHintShot(ArenaSnapshot snapshot) {
  if (!snapshot.alive.any((bool value) => value) || snapshot.samples <= 0) {
    return null;
  }

  final Stopwatch stopwatch = Stopwatch()..start();
  final double maxX = math.sqrt(1 - kMinAimUp * kMinAimUp);
  final List<_HintCandidate?> candidates = <_HintCandidate?>[];
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
    final List<int> destroyed = <int>[];
    int guard = 0;
    while (probe.ball.alive && guard < kHintSimulationStepGuard) {
      probe.step(kHintSimulationDt);
      for (final ShotEvent event in probe.pending) {
        if (event.kind == ShotEventKind.bank ||
            event.kind == ShotEventKind.blocked) {
          path.add(event.pos);
        } else if (event.kind == ShotEventKind.broke) {
          destroyed.add(event.targetIndex);
          lastBreak = event.pos;
        }
      }
      probe.pending.clear();
      guard++;
    }
    if (destroyed.isNotEmpty && lastBreak != null) {
      path.add(lastBreak);
      candidates.add(
        _HintCandidate(
          aim: aim,
          path: List<V2>.unmodifiable(path),
          targetIndices: List<int>.unmodifiable(destroyed),
        ),
      );
    } else {
      candidates.add(null);
    }
    if (stopwatch.elapsed >= snapshot.budget) break;
  }

  // A single successful sample can sit on the very edge of a target and be
  // needlessly hard to reproduce by touch. Find the widest consecutive band
  // of sampled angles that all destroy the same target, then return its
  // midpoint. This keeps the hint deterministic while maximizing the player's
  // angular margin for error. Every highlighted target is still taken from a
  // full ShotRunner simulation of the exact returned aim.
  _HintCandidate? best;
  int bestRunLength = 0;
  for (
    int targetIndex = 0;
    targetIndex < snapshot.targets.length;
    targetIndex++
  ) {
    if (!snapshot.alive[targetIndex]) continue;
    int runStart = -1;
    for (int sample = 0; sample <= candidates.length; sample++) {
      final bool hitsTarget =
          sample < candidates.length &&
          (candidates[sample]?.targetIndices.contains(targetIndex) ?? false);
      if (hitsTarget && runStart < 0) {
        runStart = sample;
        continue;
      }
      if (hitsTarget || runStart < 0) continue;

      final int runLength = sample - runStart;
      final _HintCandidate candidate =
          candidates[runStart + (runLength - 1) ~/ 2]!;
      final bool isBetter =
          runLength > bestRunLength ||
          (runLength == bestRunLength &&
              (best == null ||
                  candidate.targetIndices.length > best.targetIndices.length));
      if (isBetter) {
        best = candidate;
        bestRunLength = runLength;
      }
      runStart = -1;
    }
  }

  if (best == null) return null;
  return HintShot(
    aim: best.aim,
    path: best.path,
    targetIndices: best.targetIndices,
  );
}
