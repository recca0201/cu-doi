// Full BFS on the surviving candidate configs: how many shots does a perfect
// player actually need, and what is the ceiling score? Needed to set honest
// star thresholds rather than guessed ones.

const S = require('./sim.js');
const { V2, closestPointOnSegment, buildSegments, kArenas,
        kBallRadius, kTargetRadius, kShooterOrigin, kShotSpeed,
        kArenaHeight, kPointsPerTarget } = S;

const SUB = 1 / 480, SEG_DEBOUNCE = 0.05, TGT_DEBOUNCE = 0.12;

function run({ segments, targets, alive, direction, maxBanks, maxMultiplier }) {
  let pos = kShooterOrigin;
  let vel = direction.normalized.mul(kShotSpeed);
  let banks = 0, elapsed = 0, points = 0, broke = 0;
  const segReady = new Map(), tgtReady = new Map();
  const contact = kBallRadius + kTargetRadius;

  for (;;) {
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
      if (elapsed >= ready) { segReady.set(i, elapsed + SEG_DEBOUNCE); banks++; }
    }

    for (let i = 0; i < targets.length; i++) {
      if (!alive[i]) continue;
      const t = targets[i];
      const d = pos.sub(t.pos);
      const dist = d.length;
      if (dist >= contact) continue;
      if (banks >= t.requiredBanks) {
        alive[i] = false; broke++;
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

const STEPS = 721, SPREAD = 85;
function angles(minUp) {
  const out = [];
  for (let i = 0; i < STEPS; i++) {
    const deg = -SPREAD + (2 * SPREAD * i) / (STEPS - 1);
    const rad = (deg * Math.PI) / 180;
    out.push({ deg, dir: clampWith(new V2(Math.sin(rad), -Math.cos(rad)), minUp) });
  }
  return out;
}

function popcount(x) { let c = 0; while (x) { c += x & 1; x >>= 1; } return c; }

function analyse(arena, cfg, angleList) {
  const segments = buildSegments(arena);
  const n = arena.targets.length;
  const full = (1 << n) - 1;
  const cache = new Map();

  function expand(mask) {
    if (cache.has(mask)) return cache.get(mask);
    const out = [];
    for (const a of angleList) {
      const alive = [];
      for (let i = 0; i < n; i++) alive.push((mask & (1 << i)) !== 0);
      const r = run({ segments, targets: arena.targets, alive, direction: a.dir, ...cfg });
      let next = 0;
      for (let k = 0; k < n; k++) if (alive[k]) next |= (1 << k);
      if (next !== mask) out.push({ mask: next, points: r.points, deg: a.deg, banks: r.banks });
    }
    cache.set(mask, out);
    return out;
  }

  // Best score reachable in <= arena.shots shots, and min shots to full clear.
  const best = new Map([[full, { shots: 0, score: 0 }]]);
  const order = [full];
  let clearShots = null, clearBest = 0, ceiling = 0;

  while (order.length) {
    const mask = order.shift();
    const cur = best.get(mask);
    if (cur.shots >= arena.shots) continue;
    for (const tr of expand(mask)) {
      const score = cur.score + tr.points;
      const shots = cur.shots + 1;
      if (score > ceiling) ceiling = score;
      const prev = best.get(tr.mask);
      if (!prev || shots < prev.shots || (shots === prev.shots && score > prev.score)) {
        best.set(tr.mask, { shots, score });
        order.push(tr.mask);
      }
      if (tr.mask === 0) {
        if (clearShots === null || shots < clearShots) { clearShots = shots; clearBest = score; }
        else if (shots === clearShots && score > clearBest) clearBest = score;
      }
    }
  }

  let heroBreak = 0, heroScore = 0, heroDeg = null;
  for (const tr of expand(full)) {
    const b = n - popcount(tr.mask);
    if (b > heroBreak || (b === heroBreak && tr.points > heroScore)) {
      heroBreak = b; heroScore = tr.points; heroDeg = tr.deg.toFixed(1);
    }
  }

  return { clearShots, clearBest, ceiling, heroBreak, heroScore, heroDeg, n };
}

const candidates = [
  { maxBanks: 5, minUp: 0.6, maxMultiplier: 6 },
  { maxBanks: 6, minUp: 0.6, maxMultiplier: 7 },
  { maxBanks: 8, minUp: 0.6, maxMultiplier: 8 },
];

for (const cfg of candidates) {
  const angleList = angles(cfg.minUp);
  const maxDeg = Math.max(...angleList.map(a => Math.abs(Math.atan2(a.dir.x, -a.dir.y) * 180 / Math.PI)));
  console.log(`\n############ maxBanks=${cfg.maxBanks} minUp=${cfg.minUp} maxMult=${cfg.maxMultiplier} ` +
              `(góc tối đa ${maxDeg.toFixed(1)}° so với thẳng đứng) ############`);
  for (const arena of kArenas) {
    const r = analyse(arena, { maxBanks: cfg.maxBanks, maxMultiplier: cfg.maxMultiplier }, angleList);
    console.log(`  Màn ${arena.id} (${arena.shots} cú, ${r.n} mục tiêu): ` +
      `dọn sạch tối thiểu ${r.clearShots === null ? 'KHÔNG THỂ' : r.clearShots + ' cú'}` +
      `, điểm khi dọn sạch nhanh nhất ${r.clearBest}` +
      `, trần điểm trong ngân sách ${r.ceiling}` +
      `, cú đơn mạnh nhất phá ${r.heroBreak}/${r.n} (${r.heroScore}đ, góc ${r.heroDeg}°)`);
    console.log(`      mốc sao hiện tại ${arena.starThresholds.join('/')}  ->  đề xuất ` +
      `${Math.round(r.ceiling * 0.45 / 50) * 50}/${Math.round(r.ceiling * 0.7 / 50) * 50}/${Math.round(r.ceiling * 0.92 / 50) * 50}`);
  }
}
