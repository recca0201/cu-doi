// Parameter sweep to kill the degenerate "fire almost flat and let it
// ping-pong across the arena" dominant strategy found by verify.js.
//
// Three knobs:
//   maxBanks   — total bank budget per shot
//   minUp      — aim clamp; how close to horizontal the launcher may fire
//   creditMode — 'every': every reflection earns bank credit (current rule)
//                'once' : each surface earns credit at most ONCE per shot,
//                         so bouncing between the same two walls stops paying
//
// Degeneracy test: can a single shot clear the whole arena? If yes, the shot
// budget and every requiredBanks number are decoration.

const S = require('./sim.js');
const { V2, closestPointOnSegment, buildSegments, kArenas,
        kBallRadius, kTargetRadius, kShooterOrigin, kShotSpeed,
        kArenaHeight, kPointsPerTarget } = S;

const SUB = 1 / 480;
const SEG_DEBOUNCE = 0.05;
const TGT_DEBOUNCE = 0.12;

function run({ segments, targets, alive, direction, maxBanks, creditMode, maxMultiplier }) {
  let pos = kShooterOrigin;
  let vel = direction.normalized.mul(kShotSpeed);
  let banks = 0, elapsed = 0, points = 0, broke = 0;
  const segReady = new Map();
  const tgtReady = new Map();
  const credited = new Set();
  const contact = kBallRadius + kTargetRadius;

  while (true) {
    elapsed += SUB;
    pos = pos.add(vel.mul(SUB));

    for (let i = 0; i < segments.length; i++) {
      const s = segments[i];
      const closest = closestPointOnSegment(pos, s.a, s.b);
      const d = pos.sub(closest);
      const dist = d.length;
      if (dist >= kBallRadius) continue;
      const n = dist > 1e-6 ? d.mul(1 / dist) : s.fallbackNormal;
      pos = pos.add(n.mul(kBallRadius - dist + 0.02));
      const vn = vel.dot(n);
      if (vn >= 0) continue;
      vel = vel.reflect(n);
      const ready = segReady.has(i) ? segReady.get(i) : -1;
      if (elapsed >= ready) {
        segReady.set(i, elapsed + SEG_DEBOUNCE);
        if (creditMode === 'every' || !credited.has(i)) {
          credited.add(i);
          banks++;
        }
      }
    }

    for (let i = 0; i < targets.length; i++) {
      if (!alive[i]) continue;
      const t = targets[i];
      const d = pos.sub(t.pos);
      const dist = d.length;
      if (dist >= contact) continue;
      if (banks >= t.requiredBanks) {
        alive[i] = false;
        broke++;
        points += kPointsPerTarget * Math.min(1 + banks, maxMultiplier);
        continue;
      }
      const n = dist > 1e-6 ? d.mul(1 / dist) : new V2(0, -1);
      pos = pos.add(n.mul(contact - dist + 0.02));
      const vn = vel.dot(n);
      if (vn >= 0) continue;
      vel = vel.reflect(n);
      const ready = tgtReady.has(i) ? tgtReady.get(i) : -1;
      if (elapsed >= ready) tgtReady.set(i, elapsed + TGT_DEBOUNCE);
    }

    if (pos.y - kBallRadius > kArenaHeight) return { banks, points, broke, end: 'out' };
    if (banks >= maxBanks) return { banks, points, broke, end: 'banks' };
    if (elapsed > 14) return { banks, points, broke, end: 'timeout' };
  }
}

function clampWith(direction, minUp) {
  let d = direction.normalized;
  if (d.lengthSquared < 1e-9) return new V2(0, -1);
  if (d.y > -minUp) d = new V2(d.x, -minUp).normalized;
  return d;
}

const STEPS = 481;
function sweepAngles(minUp, spreadDeg) {
  const out = [];
  for (let i = 0; i < STEPS; i++) {
    const deg = -spreadDeg + (2 * spreadDeg * i) / (STEPS - 1);
    const rad = (deg * Math.PI) / 180;
    out.push({ deg, dir: clampWith(new V2(Math.sin(rad), -Math.cos(rad)), minUp) });
  }
  return out;
}

const configs = [];
for (const creditMode of ['every', 'once']) {
  for (const maxBanks of [3, 4, 5, 6, 8, 14]) {
    for (const minUp of [0.2, 0.45, 0.6, 0.75]) {
      configs.push({ creditMode, maxBanks, minUp, maxMultiplier: Math.min(1 + maxBanks, 8) });
    }
  }
}

console.log('creditMode maxBanks minUp | per-arena: bestBreak/n  bestScore  unreachable');
console.log('-'.repeat(96));

const results = [];
for (const cfg of configs) {
  const angles = sweepAngles(cfg.minUp, 85);
  const rows = [];
  let degenerate = false, anyUnreachable = false;

  for (const arena of kArenas) {
    const segments = buildSegments(arena);
    const n = arena.targets.length;
    let bestBreak = 0, bestScore = 0;
    const everBroken = new Array(n).fill(false);

    for (const a of angles) {
      const alive = new Array(n).fill(true);
      const r = run({ segments, targets: arena.targets, alive, direction: a.dir, ...cfg });
      for (let k = 0; k < n; k++) if (!alive[k]) everBroken[k] = true;
      if (r.broke > bestBreak) bestBreak = r.broke;
      if (r.points > bestScore) bestScore = r.points;
    }
    const unreachable = everBroken.filter(b => !b).length;
    if (bestBreak === n) degenerate = true;
    if (unreachable > 0) anyUnreachable = true;
    rows.push(`${bestBreak}/${n} ${String(bestScore).padStart(5)} ${unreachable ? 'UNREACH:' + unreachable : 'ok'.padEnd(9)}`);
  }

  const verdict = anyUnreachable ? 'BROKEN' : (degenerate ? 'degenerate' : 'CANDIDATE');
  results.push({ cfg, degenerate, anyUnreachable, verdict });
  console.log(
    `${cfg.creditMode.padEnd(6)} ${String(cfg.maxBanks).padStart(3)} ${String(cfg.minUp).padEnd(5)} | ` +
    rows.join(' | ') + `  => ${verdict}`
  );
}

console.log('\n=== CANDIDATES (no arena clearable in one shot, no unreachable target) ===');
const good = results.filter(r => r.verdict === 'CANDIDATE');
if (!good.length) console.log('  none — the arenas themselves need redesign, not just retuning');
for (const g of good) {
  console.log(`  creditMode=${g.cfg.creditMode} maxBanks=${g.cfg.maxBanks} minUp=${g.cfg.minUp} maxMultiplier=${g.cfg.maxMultiplier}`);
}
