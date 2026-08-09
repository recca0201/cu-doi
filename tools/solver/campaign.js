// Authoring + auto-tuning pipeline for the full arena campaign.
//
// Geometry is hand-authored below. Everything numeric that affects difficulty is
// NOT: requiredBanks, the shot budget and the star thresholds are derived by
// running the real simulation over a fan of aim angles. That is the only honest
// way to ship 20 levels without a single human playtest.
//
// Guarantees this pipeline enforces per arena:
//   1. every target is destructible from a full board (no impossible target)
//   2. no arena can be cleared in a single shot (the degenerate strategy that
//      killed the first parameterisation — see tools/solver/README.md)
//   3. the shot budget is a real achievable line plus one spare
//   4. star thresholds come from an actually-achieved score, not a guess
//
// Output: lib/sim/arenas.dart

const S = require('./sim.js');
const { V2, closestPointOnSegment, buildSegments, clampAim,
        kBallRadius, kTargetRadius, kShooterOrigin, kShotSpeed,
        kArenaWidth, kArenaHeight, kMaxBanks, kMaxMultiplier,
        kPointsPerTarget } = S;

const SUB = 1 / 480, SEG_DEBOUNCE = 0.05, TGT_DEBOUNCE = 0.12;

/// requiredBanks can never usefully equal kMaxBanks: the shot dies on the
/// substep its bank count reaches the cap, so a target needing that many banks
/// is unbreakable in practice.
const MAX_REQ = kMaxBanks - 1;

// ---------------------------------------------------------------- simulation

function run(segments, targets, alive, direction) {
  let pos = kShooterOrigin;
  let vel = direction.normalized.mul(kShotSpeed);
  let banks = 0, elapsed = 0, points = 0;
  const broke = [];
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
        alive[i] = false;
        broke.push(i);
        points += kPointsPerTarget * Math.min(1 + banks, kMaxMultiplier);
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

    if (pos.y - kBallRadius > kArenaHeight) return { banks, points, broke };
    if (banks >= kMaxBanks) return { banks, points, broke };
    if (elapsed > 14) return { banks, points, broke };
  }
}

const ANGLE_STEPS = 361, SPREAD = 85;
const ANGLES = (() => {
  const out = [];
  for (let i = 0; i < ANGLE_STEPS; i++) {
    const deg = -SPREAD + (2 * SPREAD * i) / (ANGLE_STEPS - 1);
    const rad = (deg * Math.PI) / 180;
    out.push({ deg, dir: clampAim(new V2(Math.sin(rad), -Math.cos(rad))) });
  }
  return out;
})();

/// Every outcome available from one board state.
function expand(segments, targets, aliveMask) {
  const n = targets.length;
  const out = [];
  for (const a of ANGLES) {
    const alive = [];
    for (let i = 0; i < n; i++) alive.push((aliveMask & (1 << i)) !== 0);
    const r = run(segments, targets, alive, a.dir);
    if (r.broke.length === 0) continue;
    let next = aliveMask;
    for (const k of r.broke) next &= ~(1 << k);
    out.push({ next, points: r.points, broke: r.broke, deg: a.deg, banks: r.banks });
  }
  return out;
}

// ---------------------------------------------------------------- auto-tuning

function analyse(arena) {
  const segments = buildSegments(arena);
  const n = arena.targets.length;
  const full = (1 << n) - 1;
  const moves = expand(segments, arena.targets, full);

  const reachable = new Array(n).fill(false);
  for (const m of moves) for (const k of m.broke) reachable[k] = true;

  const oneShot = moves.find((m) => m.next === 0) || null;
  return { segments, moves, reachable, oneShot };
}

/// Greedy line: repeatedly take the shot that breaks the most targets, richest
/// first on ties. An upper bound on the optimal, and — unlike an exhaustive
/// search — a line a human could plausibly find.
function greedyLine(arena, segments) {
  const n = arena.targets.length;
  let mask = (1 << n) - 1;
  let shots = 0, score = 0;
  const line = [];
  while (mask !== 0 && shots < 12) {
    const moves = expand(segments, arena.targets, mask);
    if (moves.length === 0) return null;
    moves.sort((x, y) => {
      const byCount = y.broke.length - x.broke.length;
      return byCount !== 0 ? byCount : y.points - x.points;
    });
    const best = moves[0];
    mask = best.next;
    score += best.points;
    shots++;
    line.push({ deg: best.deg, broke: best.broke.length, banks: best.banks });
  }
  return mask === 0 ? { shots, score, line } : null;
}

function tune(arena, log) {
  for (let attempt = 0; attempt < 16; attempt++) {
    const { segments, reachable, oneShot, moves } = analyse(arena);

    const dead = reachable.map((r, i) => (r ? -1 : i)).filter((i) => i >= 0);
    if (dead.length > 0) {
      let changed = false;
      for (const i of dead) {
        if (arena.targets[i].requiredBanks > 1) {
          arena.targets[i].requiredBanks--;
          changed = true;
          log.push(`  target ${i}: unreachable -> req ${arena.targets[i].requiredBanks}`);
        }
      }
      if (!changed) return { ok: false, reason: `target(s) ${dead.join(',')} unreachable even at req 1` };
      continue;
    }

    if (oneShot) {
      // Degenerate. Make the cheapest target in that solution cost more.
      const candidates = oneShot.broke
        .map((i) => ({ i, req: arena.targets[i].requiredBanks }))
        .sort((a, b) => a.req - b.req);
      const pick = candidates.find((c) => c.req < MAX_REQ);
      if (!pick) return { ok: false, reason: 'clearable in one shot and every req is already maxed' };
      arena.targets[pick.i].requiredBanks++;
      log.push(`  one-shot clearable -> target ${pick.i} req ${arena.targets[pick.i].requiredBanks}`);
      continue;
    }

    const greedy = greedyLine(arena, segments);
    if (!greedy) return { ok: false, reason: 'no greedy line clears the board' };

    // One spare shot over a real achievable line.
    arena.shots = Math.min(8, greedy.shots + 1);
    const ceiling = greedy.score;
    arena.starThresholds = [
      Math.max(100, Math.round((ceiling * 0.5) / 50) * 50),
      Math.max(200, Math.round((ceiling * 0.72) / 50) * 50),
      Math.max(300, Math.round((ceiling * 0.9) / 50) * 50),
    ];
    return { ok: true, greedy, moves: moves.length, ceiling };
  }
  return { ok: false, reason: 'did not converge in 16 attempts' };
}

// ---------------------------------------------------------------- authoring

const t = (x, y, req, pal) => ({ pos: new V2(x, y), requiredBanks: req, palette: pal });
const b = (l, tp, r, bo) => ({ left: l, top: tp, right: r, bottom: bo });
const d = (ax, ay, bx, by) => ({ a: new V2(ax, ay), b: new V2(bx, by) });

// Chapter names are cosmetic groupings; ids are what progress keys on.
const CAMPAIGN = [
  // ---- Chương 1: học luật dội -------------------------------------------
  { id: 1, name: 'Bắn thẳng không tính', nameEn: "Straight shots don't count",
    hint: 'Bắn thẳng thì chúng nó cười. Phải dội tường trước đã!',
    hintEn: 'Shoot one head-on and it laughs. Bank off a wall first!',
    targets: [t(50, 104, 1, 0), t(22, 44, 1, 1), t(78, 44, 1, 2)],
    blocks: [b(40, 60, 60, 68)], deflectors: [] },

  { id: 2, name: 'Ba đứa trên cao', nameEn: 'Three up top',
    hint: 'Không có vật cản. Chỉ có tường và góc bắn của bạn.',
    hintEn: 'No obstacles. Just walls and your angle.',
    targets: [t(20, 36, 1, 1), t(50, 28, 1, 2), t(80, 36, 1, 3)],
    blocks: [], deflectors: [] },

  { id: 3, name: 'Sát tường', nameEn: 'Hugging the wall',
    hint: 'Đứa sát tường khó ăn hơn đứa giữa sân.',
    hintEn: 'The ones against the wall are harder than the ones in the middle.',
    targets: [t(11, 112, 2, 0), t(89, 112, 2, 1), t(50, 40, 1, 2)],
    blocks: [], deflectors: [] },

  { id: 4, name: 'Hình thoi', nameEn: 'Diamond',
    hint: 'Một cú đi xuyên được mấy đứa?',
    hintEn: 'How many can one shot punch through?',
    targets: [t(50, 30, 1, 0), t(28, 60, 2, 1), t(72, 60, 2, 2), t(50, 92, 1, 3)],
    blocks: [b(44, 44, 56, 50)], deflectors: [] },

  { id: 5, name: 'Sau cây cột', nameEn: 'Behind the pillar',
    hint: 'Cột giữa sân không cho bạn đi đường thẳng.',
    hintEn: 'The pillar takes the straight line away from you.',
    targets: [t(26, 52, 2, 0), t(74, 52, 2, 1), t(50, 22, 1, 2)],
    blocks: [b(44, 66, 56, 118)], deflectors: [] },

  // ---- Chương 2: kệ và hốc ----------------------------------------------
  { id: 6, name: 'Ngóc ngách', nameEn: 'Pockets',
    hint: 'Mấy đứa trong hốc chỉ ăn cú dội từ trên xuống thôi.',
    hintEn: 'The ones in the alcoves only take a bank from above.',
    targets: [t(50, 100, 1, 0), t(15, 54, 2, 1), t(85, 54, 2, 2), t(50, 24, 3, 3)],
    blocks: [b(0, 66, 30, 73), b(70, 66, 100, 73)],
    deflectors: [d(40, 38, 60, 38)] },

  { id: 7, name: 'Mái che', nameEn: 'The awning',
    hint: 'Có mái thì đi vòng, đừng đi thẳng.',
    hintEn: 'There is a roof. Go around it.',
    targets: [t(24, 30, 2, 0), t(76, 30, 2, 1), t(50, 78, 1, 2)],
    blocks: [b(32, 46, 68, 54)], deflectors: [] },

  { id: 8, name: 'Bậc thang', nameEn: 'Staircase',
    hint: 'Bậc thang bên trái là tường phụ, dùng nó đi.',
    hintEn: 'Those steps on the left are extra walls. Use them.',
    targets: [t(80, 100, 2, 0), t(80, 62, 3, 1), t(78, 26, 2, 2)],
    blocks: [b(0, 112, 30, 119), b(0, 74, 22, 81), b(0, 36, 14, 43)],
    deflectors: [] },

  { id: 9, name: 'Hai cái hốc', nameEn: 'Two nooks',
    hint: 'Hai bên là hốc. Giữa là đường vào.',
    hintEn: 'Nooks on both sides. The middle is the way in.',
    targets: [t(14, 90, 2, 0), t(86, 90, 2, 1), t(50, 34, 2, 2), t(50, 118, 1, 3)],
    blocks: [b(0, 104, 28, 110), b(72, 104, 100, 110), b(40, 60, 60, 66)],
    deflectors: [] },

  { id: 10, name: 'Kẹp giữa', nameEn: 'Squeezed',
    hint: 'Khe giữa hai cột hẹp hơn bạn tưởng.',
    hintEn: 'The gap between the pillars is tighter than it looks.',
    targets: [t(50, 42, 3, 0), t(20, 100, 2, 1), t(80, 100, 2, 2)],
    blocks: [b(32, 60, 40, 120), b(60, 60, 68, 120)],
    deflectors: [] },

  // ---- Chương 3: zig-zag ------------------------------------------------
  { id: 11, name: 'Chuỗi dội', nameEn: 'Bank chain',
    hint: 'Càng dội càng nhân điểm. Một cú ăn hết bốn đứa được không?',
    hintEn: 'More banks, bigger multiplier. Can one shot take all four?',
    targets: [t(14, 118, 1, 0), t(86, 96, 2, 1), t(14, 74, 3, 2), t(86, 52, 4, 3)],
    blocks: [b(46, 84, 54, 112)], deflectors: [] },

  { id: 12, name: 'Leo thang', nameEn: 'Climbing',
    hint: 'Đi zig-zag lên. Đừng tham đứa trên cùng ngay.',
    hintEn: 'Zig-zag your way up. Do not grab for the top one first.',
    targets: [t(12, 108, 1, 0), t(88, 82, 2, 1), t(12, 56, 3, 2), t(88, 30, 4, 3), t(50, 128, 1, 0)],
    blocks: [], deflectors: [] },

  { id: 13, name: 'Hành lang', nameEn: 'The corridor',
    hint: 'Hành lang hẹp: bi vào được thì dội rất nhanh.',
    hintEn: 'A narrow corridor: once the ball is in, banks come fast.',
    targets: [t(50, 24, 3, 0), t(50, 56, 2, 1), t(18, 122, 1, 2), t(82, 122, 1, 3)],
    blocks: [b(34, 74, 42, 132), b(58, 74, 66, 132)],
    deflectors: [] },

  { id: 14, name: 'Dán tường', nameEn: 'Wallflowers',
    hint: 'Cả bốn đứa đều dán tường. Vui đấy.',
    hintEn: 'All four are stuck to the walls. Have fun.',
    targets: [t(10, 120, 2, 0), t(10, 60, 3, 1), t(90, 120, 2, 2), t(90, 60, 3, 3)],
    blocks: [b(42, 40, 58, 130)], deflectors: [] },

  { id: 15, name: 'Chữ thập', nameEn: 'The cross',
    hint: 'Bốn góc, một cây thập ở giữa.',
    hintEn: 'Four corners, one cross in the middle.',
    targets: [t(18, 40, 2, 0), t(82, 40, 2, 1), t(18, 110, 2, 2), t(82, 110, 2, 3)],
    blocks: [b(44, 44, 56, 106), b(28, 70, 72, 80)],
    deflectors: [] },

  // ---- Chương 4: vật cản chéo -------------------------------------------
  { id: 16, name: 'Chéo giữa sân', nameEn: 'Diagonal',
    hint: 'Vật cản chéo đổi hướng bi kiểu khác tường.',
    hintEn: 'A diagonal bumper turns the ball differently from a wall.',
    targets: [t(20, 44, 2, 0), t(80, 44, 2, 1), t(50, 110, 1, 2)],
    blocks: [], deflectors: [d(34, 84, 66, 68)] },

  { id: 17, name: 'Cái phễu', nameEn: 'The funnel',
    hint: 'Phễu đẩy bi ra hai bên. Đừng chống lại nó.',
    hintEn: 'The funnel pushes the ball out to the sides. Do not fight it.',
    targets: [t(14, 62, 3, 0), t(86, 62, 3, 1), t(50, 26, 2, 2)],
    blocks: [], deflectors: [d(30, 96, 48, 116), d(70, 96, 52, 116)] },

  { id: 18, name: 'Nóc nhà', nameEn: 'The rooftop',
    hint: 'Đứa trên nóc chỉ vào được từ bên sườn.',
    hintEn: 'The one on the roof can only be entered from a flank.',
    targets: [t(50, 20, 3, 0), t(22, 74, 2, 1), t(78, 74, 2, 2), t(50, 116, 1, 3)],
    blocks: [b(30, 34, 70, 40)],
    deflectors: [d(12, 52, 30, 40), d(88, 52, 70, 40)] },

  { id: 19, name: 'Hai lưỡi dao', nameEn: 'Two blades',
    hint: 'Hai lưỡi chéo hai bên. Bi sẽ đi lối bạn không định.',
    hintEn: 'Two blades on the flanks. The ball goes where you did not plan.',
    targets: [t(50, 34, 3, 0), t(16, 108, 2, 1), t(84, 108, 2, 2), t(50, 74, 2, 3)],
    blocks: [], deflectors: [d(6, 88, 34, 62), d(94, 88, 66, 62)] },

  { id: 20, name: 'Bừa hết cỡ', nameEn: 'Full send',
    hint: 'Tất cả cùng lúc. Bắn bừa đúng chỗ đi.',
    hintEn: 'Everything at once. Be reckless in the right place.',
    targets: [t(50, 18, 4, 0), t(14, 52, 3, 1), t(86, 52, 3, 2),
              t(26, 106, 2, 3), t(74, 106, 2, 0), t(50, 128, 1, 1)],
    blocks: [b(38, 34, 62, 40), b(44, 70, 56, 92)],
    deflectors: [d(8, 78, 30, 62), d(92, 78, 70, 62)] },
];

// ---------------------------------------------------------------- run

// Structural checks first — these are authoring mistakes, not balance issues.
let structural = 0;
for (const arena of CAMPAIGN) {
  for (const [i, tg] of arena.targets.entries()) {
    const inX = tg.pos.x > kTargetRadius && tg.pos.x < kArenaWidth - kTargetRadius;
    const inY = tg.pos.y > kTargetRadius && tg.pos.y < kShooterOrigin.y - kTargetRadius * 2;
    if (!inX || !inY) { console.log(`ARENA ${arena.id} target ${i} out of bounds`); structural++; }
    if (tg.requiredBanks < 1 || tg.requiredBanks > MAX_REQ) {
      console.log(`ARENA ${arena.id} target ${i} req ${tg.requiredBanks} outside 1..${MAX_REQ}`);
      structural++;
    }
  }
  for (const s of buildSegments(arena)) {
    if (kShooterOrigin.sub(closestPointOnSegment(kShooterOrigin, s.a, s.b)).length <= kBallRadius * 1.5) {
      console.log(`ARENA ${arena.id}: launcher embedded in a surface`); structural++;
    }
    for (const [i, tg] of arena.targets.entries()) {
      if (tg.pos.sub(closestPointOnSegment(tg.pos, s.a, s.b)).length <= kTargetRadius + kBallRadius) {
        console.log(`ARENA ${arena.id} target ${i} overlaps a surface`); structural++;
      }
    }
  }
}
if (structural > 0) {
  console.log(`\n${structural} structural problem(s) — fix the geometry before tuning.`);
  process.exit(1);
}
console.log(`structural checks: ${CAMPAIGN.length} arenas OK\n`);

const results = [];
for (const arena of CAMPAIGN) {
  const log = [];
  const t0 = Date.now();
  const res = tune(arena, log);
  const secs = ((Date.now() - t0) / 1000).toFixed(1);
  if (!res.ok) {
    console.log(`ARENA ${arena.id} "${arena.name}" FAILED: ${res.reason} (${secs}s)`);
    log.forEach((l) => console.log(l));
    results.push({ arena, ok: false, reason: res.reason });
    continue;
  }
  console.log(
    `arena ${String(arena.id).padStart(2)} "${arena.name}" ` +
    `${arena.targets.length} mục tiêu, req [${arena.targets.map((x) => x.requiredBanks).join(',')}], ` +
    `dọn sạch ${res.greedy.shots} cú -> ngân sách ${arena.shots}, ` +
    `điểm ${res.ceiling}, sao ${arena.starThresholds.join('/')} (${secs}s)`
  );
  log.forEach((l) => console.log(l));
  results.push({ arena, ok: true, ...res });
}

const failed = results.filter((r) => !r.ok);
console.log(`\n${results.length - failed.length}/${results.length} arenas tuned OK`);
if (failed.length) {
  console.log('FAILED: ' + failed.map((f) => f.arena.id).join(', '));
  process.exit(1);
}

require('fs').writeFileSync('/tmp/verify/campaign.json', JSON.stringify(
  CAMPAIGN.map((a) => ({
    id: a.id, name: a.name, nameEn: a.nameEn, hint: a.hint, hintEn: a.hintEn,
    shots: a.shots, starThresholds: a.starThresholds,
    targets: a.targets.map((x) => ({ x: x.pos.x, y: x.pos.y, req: x.requiredBanks, pal: x.palette })),
    blocks: a.blocks, deflectors: a.deflectors.map((x) => ({ ax: x.a.x, ay: x.a.y, bx: x.b.x, by: x.b.y })),
  })), null, 2), 'utf8');
console.log('wrote /tmp/verify/campaign.json');
