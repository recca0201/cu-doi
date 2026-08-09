// 1) Re-runs the assertions from test/shot_runner_test.dart against the JS port.
// 2) Brute-force searches every arena for a full-clear solution within budget.
//
// (2) is the part an emulator could not have told us without hours of manual
// play, and it is the highest-risk unknown in the prototype: the arenas were
// authored without ever being played.

const S = require('./sim.js');
const { V2, fly, buildSegments, arenaWalls, kArenas, target,
        kShooterOrigin, kMaxBanks, kMaxMultiplier, kPointsPerTarget,
        ShotEndReason, closestPointOnSegment, kBallRadius, kTargetRadius,
        kArenaWidth, clampAim, ShotRunner } = S;

let pass = 0, fail = 0;
const failures = [];

function check(name, cond, detail = '') {
  if (cond) { pass++; }
  else { fail++; failures.push(`${name}${detail ? ' — ' + detail : ''}`); }
}

// =====================================================================
// PART 1 — the rule
// =====================================================================

console.log('\n=== PART 1: mechanic assertions (mirrors shot_runner_test.dart) ===\n');

{
  const alive = [true];
  const r = fly({ segments: arenaWalls(), targets: [target(50, 100, 1)], alive, direction: new V2(0, -1) });
  check('direct hit does NOT break a req-1 target', alive[0] === true);
  check('a blocked event is emitted (player is told why)', r.blocked > 0, `blocked=${r.blocked}`);
  check('bouncing off an un-earned target earns no bank', r.banks === 0, `banks=${r.banks}`);
  check('shot then leaves via the open bottom', r.endReason === ShotEndReason.exitedBottom, `${r.endReason}`);
}

{
  const alive = [true];
  const r = fly({ segments: arenaWalls(), targets: [target(50, 100, 1)], alive, direction: new V2(0, -1), presetBanks: 1 });
  check('same shot breaks the target once 1 bank is banked', alive[0] === false);
  check('one bank means x2 points', r.points === kPointsPerTarget * 2, `points=${r.points}`);
  check('breaking punches through and keeps flying', r.banks >= 2, `banks=${r.banks}`);
}

{
  const alive = [true, true, true];
  const r = fly({
    segments: arenaWalls(),
    targets: [target(50, 120, 1), target(50, 100, 1), target(50, 80, 1)],
    alive, direction: new V2(0, -1), presetBanks: 1,
  });
  check('one shot rakes a line of eligible targets', alive.every(a => a === false), `alive=${alive}`);
  check('three break events', r.broke.length === 3, `broke=${r.broke.length}`);
}

{
  const r = fly({ segments: arenaWalls(), targets: [], alive: [], direction: new V2(0, -1) });
  check('one wall contact counts exactly once (debounce works)', r.banks === 1, `banks=${r.banks}`);
}

{
  const r = fly({ segments: arenaWalls(), targets: [], alive: [], direction: new V2(1, -0.22) });
  check('a shallow shot dies on the bank budget, not on the safety timeout',
    r.endReason !== ShotEndReason.timeout, `${r.endReason} banks=${r.banks}`);
  check('bank budget is respected', r.banks <= kMaxBanks, `banks=${r.banks}`);
}

{
  check('cannot aim downward', clampAim(new V2(0, 1)).y < 0);
  check('cannot aim flat', clampAim(new V2(1, 0)).y < 0);
  const rr = new ShotRunner({ segments: arenaWalls(), targets: [], alive: [], origin: kShooterOrigin, direction: new V2(0, -1) });
  rr.banks = 500;
  check('multiplier is capped', rr.multiplier === kMaxMultiplier, `${rr.multiplier}`);
}

// arena data coherence (mirrors the Dart 'arena data' group)
for (const a of kArenas) {
  for (const t of a.targets) {
    check(`arena ${a.id}: no target breakable with zero banks`, t.requiredBanks >= 1);
    check(`arena ${a.id}: target inside arena horizontally`,
      t.pos.x > kTargetRadius && t.pos.x < kArenaWidth - kTargetRadius);
    check(`arena ${a.id}: target not on top of the launcher`,
      t.pos.y < kShooterOrigin.y - kTargetRadius * 2);
  }
  for (const s of buildSegments(a)) {
    check(`arena ${a.id}: launcher not embedded in a surface`,
      kShooterOrigin.sub(closestPointOnSegment(kShooterOrigin, s.a, s.b)).length > kBallRadius * 1.5);
  }
}

console.log(`  ${pass} passed, ${fail} failed`);
if (failures.length) failures.forEach(f => console.log(`  FAIL: ${f}`));

// =====================================================================
// PART 2 — is each arena actually solvable?
// =====================================================================

console.log('\n=== PART 2: arena solvability (brute force) ===');

const ANGLE_STEPS = 721;          // -85deg .. +85deg from vertical
const SPREAD_DEG = 85;

function directionFor(i) {
  const deg = -SPREAD_DEG + (2 * SPREAD_DEG * i) / (ANGLE_STEPS - 1);
  const rad = (deg * Math.PI) / 180;
  return clampAim(new V2(Math.sin(rad), -Math.cos(rad)));
}

function maskToAlive(mask, n) {
  const alive = [];
  for (let i = 0; i < n; i++) alive.push((mask & (1 << i)) !== 0);
  return alive;
}

function solve(arena) {
  const segments = buildSegments(arena);
  const n = arena.targets.length;
  const fullMask = (1 << n) - 1;

  // transitions[mask] = array of {mask, points, angleIdx, banks}
  const transitions = new Map();

  function expand(mask) {
    if (transitions.has(mask)) return transitions.get(mask);
    const out = [];
    for (let i = 0; i < ANGLE_STEPS; i++) {
      const alive = maskToAlive(mask, n);
      const r = fly({ segments, targets: arena.targets, alive, direction: directionFor(i), maxSeconds: 14 });
      let next = 0;
      for (let k = 0; k < n; k++) if (alive[k]) next |= (1 << k);
      if (next !== mask) out.push({ mask: next, points: r.points, angleIdx: i, banks: r.banks });
    }
    transitions.set(mask, out);
    return out;
  }

  // Which single targets can be taken at all, from a full board?
  const singleReach = new Array(n).fill(null);
  for (const tr of expand(fullMask)) {
    for (let k = 0; k < n; k++) {
      if ((fullMask & (1 << k)) && !(tr.mask & (1 << k)) && singleReach[k] === null) {
        singleReach[k] = { angle: (-SPREAD_DEG + (2 * SPREAD_DEG * tr.angleIdx) / (ANGLE_STEPS - 1)).toFixed(1), banks: tr.banks };
      }
    }
  }

  // BFS on (mask) minimising shots, then track best score at the goal.
  const bestShots = new Map([[fullMask, 0]]);
  const bestScore = new Map([[fullMask, 0]]);
  const queue = [fullMask];
  let solvedIn = null, solvedScore = 0;

  while (queue.length) {
    const mask = queue.shift();
    const used = bestShots.get(mask);
    if (used >= arena.shots) continue;
    for (const tr of expand(mask)) {
      const score = bestScore.get(mask) + tr.points;
      const known = bestShots.has(tr.mask) ? bestShots.get(tr.mask) : Infinity;
      if (used + 1 < known) {
        bestShots.set(tr.mask, used + 1);
        bestScore.set(tr.mask, score);
        queue.push(tr.mask);
      } else if (used + 1 === known && score > (bestScore.get(tr.mask) || 0)) {
        bestScore.set(tr.mask, score);
      }
      if (tr.mask === 0) {
        if (solvedIn === null || used + 1 < solvedIn) { solvedIn = used + 1; solvedScore = score; }
        else if (used + 1 === solvedIn && score > solvedScore) solvedScore = score;
      }
    }
  }

  // Best single-shot score achievable from a full board (the "hero carom").
  let heroScore = 0, heroBroke = 0, heroAngle = null;
  for (const tr of expand(fullMask)) {
    if (tr.points > heroScore) {
      heroScore = tr.points;
      heroBroke = n - popcount(tr.mask);
      heroAngle = (-SPREAD_DEG + (2 * SPREAD_DEG * tr.angleIdx) / (ANGLE_STEPS - 1)).toFixed(1);
    }
  }

  return { singleReach, solvedIn, solvedScore, heroScore, heroBroke, heroAngle };
}

function popcount(x) { let c = 0; while (x) { c += x & 1; x >>= 1; } return c; }

for (const arena of kArenas) {
  const t0 = Date.now();
  const res = solve(arena);
  console.log(`\n--- Màn ${arena.id}: ${arena.name} (ngân sách ${arena.shots} cú) ---`);
  arena.targets.forEach((t, k) => {
    const sr = res.singleReach[k];
    console.log(`  target ${k} @(${t.pos.x},${t.pos.y}) cần ${t.requiredBanks} dội: ` +
      (sr ? `OK (góc ${sr.angle}°, ${sr.banks} dội)` : `KHÔNG THỂ PHÁ từ bàn đầy  <-- LỖI THIẾT KẾ`));
  });
  if (res.solvedIn === null) {
    console.log(`  DỌN SẠCH: KHÔNG THỂ trong ${arena.shots} cú  <-- LỖI THIẾT KẾ`);
  } else {
    const stars = arena.starThresholds.filter(t => res.solvedScore >= t).length;
    console.log(`  DỌN SẠCH: được, tối thiểu ${res.solvedIn}/${arena.shots} cú, điểm tốt nhất ~${res.solvedScore} (${stars}/3 sao)`);
    console.log(`  mốc sao: ${arena.starThresholds.join(' / ')}`);
  }
  console.log(`  cú đơn mạnh nhất: ${res.heroScore} điểm, phá ${res.heroBroke} mục tiêu (góc ${res.heroAngle}°)`);
  console.log(`  (${((Date.now() - t0) / 1000).toFixed(1)}s)`);
}

console.log(`\n=== TỔNG: ${pass} assertion passed, ${fail} failed ===`);
