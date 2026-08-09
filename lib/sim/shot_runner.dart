import 'arena.dart';
import 'geometry.dart';

enum ShotEndReason {
  /// Came back down past the launcher. The usual way a shot dies.
  exitedBottom,

  /// Hit [kMaxBanks]. Fizzles in place.
  banksExhausted,

  /// Safety valve — should not happen in a sane arena.
  timeout,
}

enum ShotEventKind {
  /// Reflected off a wall, block or deflector. Raises the BỪA multiplier.
  bank,

  /// Touched a target that required more banks than the shot had. The target
  /// survives, reflects the ball, and gloats.
  blocked,

  /// Broke a target.
  broke,
}

class ShotEvent {
  ShotEvent(
    this.kind,
    this.pos, {
    this.bankCount = 0,
    this.targetIndex = -1,
    this.points = 0,
  });

  final ShotEventKind kind;
  final V2 pos;
  final int bankCount;
  final int targetIndex;
  final int points;
}

class Ball {
  Ball(this.pos, this.vel);

  V2 pos;
  V2 vel;
  bool alive = true;
}

/// Simulates one shot from launch to death.
///
/// The rule that makes this not a bubble shooter lives in [_resolveTargets]:
/// a target is only destructible once [banks] has reached its
/// `requiredBanks`. Everything else here is bookkeeping.
///
/// Integration is fixed-substep (1/480s) rather than swept-analytic. At
/// [kShotSpeed] that is 0.275 logical units of travel per substep against a
/// ball radius of 2.2, so tunnelling is impossible by an 8x margin. Swept
/// collision would be more elegant and considerably easier to get subtly
/// wrong; for a prototype, brute force that is obviously correct wins.
class ShotRunner {
  ShotRunner({
    required this.segments,
    required this.targets,
    required this.alive,
    required V2 origin,
    required V2 direction,
    this.recordTrail = true,
  }) : ball = Ball(origin, direction.normalized * kShotSpeed);

  final List<Segment> segments;
  final List<TargetSpec> targets;

  /// Mutated in place when targets break — the caller owns this list and reads
  /// it back after the shot. Pass a copy if you do not want that.
  final List<bool> alive;

  final bool recordTrail;
  final Ball ball;

  int banks = 0;
  double elapsed = 0;
  ShotEndReason? endReason;

  final List<V2> trail = <V2>[];

  /// Drained by the presentation layer each frame.
  final List<ShotEvent> pending = <ShotEvent>[];

  /// Contact debounce, keyed by segment / target index, storing the [elapsed]
  /// time after which that surface may register again. Without this, a ball
  /// resting in a corner racks up dozens of phantom banks.
  final Map<int, double> _segReadyAt = <int, double>{};
  final Map<int, double> _targetReadyAt = <int, double>{};

  static const double _substep = 1 / 480;
  static const double _segDebounce = 0.05;
  static const double _targetDebounce = 0.12;

  int get multiplier {
    final int m = 1 + banks;
    return m > kMaxMultiplier ? kMaxMultiplier : m;
  }

  int get aliveTargetCount {
    int n = 0;
    for (final bool a in alive) {
      if (a) n++;
    }
    return n;
  }

  /// Advances by [dt] seconds of wall clock, in fixed substeps.
  void step(double dt) {
    if (!ball.alive) return;
    // A backgrounded app can hand us a huge dt. Clamp rather than simulate a
    // second of flight in one frame.
    double remaining = dt > 0.05 ? 0.05 : dt;
    while (remaining > 0 && ball.alive) {
      final double h = remaining < _substep ? remaining : _substep;
      _advance(h);
      remaining -= h;
    }
    if (recordTrail) {
      trail.add(ball.pos);
    }
  }

  void _advance(double h) {
    elapsed += h;
    ball.pos = ball.pos + ball.vel * h;

    _resolveSegments();
    _resolveTargets();

    if (ball.pos.y - kBallRadius > kArenaHeight) {
      ball.alive = false;
      endReason = ShotEndReason.exitedBottom;
    } else if (banks >= kMaxBanks) {
      ball.alive = false;
      endReason = ShotEndReason.banksExhausted;
    } else if (elapsed > 14) {
      ball.alive = false;
      endReason = ShotEndReason.timeout;
    }
  }

  void _resolveSegments() {
    for (int i = 0; i < segments.length; i++) {
      final Segment s = segments[i];
      final V2 closest = closestPointOnSegment(ball.pos, s.a, s.b);
      final V2 d = ball.pos - closest;
      final double dist = d.length;
      if (dist >= kBallRadius) continue;

      final V2 n = dist > 1e-6 ? d * (1 / dist) : s.fallbackNormal;

      // Depenetrate first, then reflect only if we are actually moving into
      // the surface. Reflecting an outbound velocity is how balls get stuck.
      ball.pos = ball.pos + n * (kBallRadius - dist + 0.02);
      final double vn = ball.vel.dot(n);
      if (vn >= 0) continue;

      ball.vel = ball.vel.reflect(n);

      if (elapsed >= (_segReadyAt[i] ?? -1.0)) {
        banks++;
        _segReadyAt[i] = elapsed + _segDebounce;
        pending.add(ShotEvent(ShotEventKind.bank, closest, bankCount: banks));
      }
    }
  }

  void _resolveTargets() {
    final double contact = kBallRadius + kTargetRadius;
    for (int i = 0; i < targets.length; i++) {
      if (!alive[i]) continue;
      final TargetSpec t = targets[i];
      final V2 d = ball.pos - t.pos;
      final double dist = d.length;
      if (dist >= contact) continue;

      if (banks >= t.requiredBanks) {
        alive[i] = false;
        pending.add(
          ShotEvent(
            ShotEventKind.broke,
            t.pos,
            bankCount: banks,
            targetIndex: i,
            points: kPointsPerTarget * multiplier,
          ),
        );
        // Punch through: velocity is untouched, so one carom can rake a line
        // of eligible targets. This is the payoff shot the name promises.
        continue;
      }

      // Not earned yet. Bounce off — and note this does NOT count as a bank.
      // Ricocheting off a smug target earns you nothing.
      final V2 n = dist > 1e-6 ? d * (1 / dist) : const V2(0, -1);
      ball.pos = ball.pos + n * (contact - dist + 0.02);
      final double vn = ball.vel.dot(n);
      if (vn >= 0) continue;
      ball.vel = ball.vel.reflect(n);

      if (elapsed >= (_targetReadyAt[i] ?? -1.0)) {
        _targetReadyAt[i] = elapsed + _targetDebounce;
        pending.add(ShotEvent(ShotEventKind.blocked, t.pos, targetIndex: i));
      }
    }
  }
}

/// Aim preview: the polyline the shot would follow for its first [maxBanks]
/// bounces, and no further.
///
/// The current production game highlights every bubble a shot will pop, which
/// removes most of the aiming skill. This deliberately shows geometry only,
/// truncated — enough to learn how reflection works, not enough to hand the
/// player the solution.
List<V2> previewPath({
  required List<Segment> segments,
  required List<TargetSpec> targets,
  required List<bool> alive,
  required V2 origin,
  required V2 direction,
  int maxBanks = 2,
}) {
  final ShotRunner probe = ShotRunner(
    segments: segments,
    targets: targets,
    alive: List<bool>.of(alive),
    origin: origin,
    direction: direction,
    recordTrail: false,
  );

  final List<V2> points = <V2>[origin];
  const double dt = 1 / 120;
  int guard = 0;
  int vertices = 0;

  // Both banks AND blocked target contacts are vertices. Leaving blocked
  // contacts out is a trap: the polyline then runs straight through a target
  // the shot will actually bounce off, so the preview points somewhere the
  // ball never goes.
  while (probe.ball.alive && vertices < maxBanks && guard < 1500) {
    probe.step(dt);
    for (final ShotEvent e in probe.pending) {
      if (e.kind == ShotEventKind.bank || e.kind == ShotEventKind.blocked) {
        points.add(e.pos);
        vertices++;
      }
    }
    probe.pending.clear();
    guard++;
  }
  points.add(probe.ball.pos);
  return points;
}

/// Minimum upward component of any shot: the launcher may fire at most ~59°
/// away from vertical.
///
/// This is the single most important balance constant in the prototype. A
/// brute-force sweep showed that allowing near-horizontal fire (the original
/// 0.2, i.e. ~78°) let a flat shot ping-pong across the arena and clear every
/// level in one shot. Tightening the cone is what forces a player to solve the
/// geometry rather than spray it.
const double kMinAimUp = 0.6;

/// Clamps an aim direction so the launcher cannot fire flat or downward.
V2 clampAim(V2 direction) {
  V2 d = direction.normalized;
  if (d.lengthSquared < 1e-9) return const V2(0, -1);
  if (d.y > -kMinAimUp) {
    d = V2(d.x, -kMinAimUp).normalized;
  }
  return d;
}
