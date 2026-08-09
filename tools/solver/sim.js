// Faithful transliteration of prototypes/ban_bua_ricochet/lib/sim/*.dart
//
// Line-for-line where possible so that a divergence here means a divergence in
// the Dart. This exists because there is no Dart toolchain available: it lets
// the mechanic and the arena balance be verified before anyone installs
// anything. It does NOT verify that the Dart compiles.

// ---------- geometry.dart ----------

class V2 {
  constructor(x, y) { this.x = x; this.y = y; }
  add(o) { return new V2(this.x + o.x, this.y + o.y); }
  sub(o) { return new V2(this.x - o.x, this.y - o.y); }
  mul(s) { return new V2(this.x * s, this.y * s); }
  dot(o) { return this.x * o.x + this.y * o.y; }
  get lengthSquared() { return this.x * this.x + this.y * this.y; }
  get length() { return Math.sqrt(this.lengthSquared); }
  get normalized() {
    const l = this.length;
    if (l < 1e-9) return new V2(0, 0);
    return new V2(this.x / l, this.y / l);
  }
  reflect(n) { return this.sub(n.mul(2 * this.dot(n))); }
}

const SurfaceKind = { wall: 'wall', block: 'block', deflector: 'deflector' };

class Segment {
  constructor(a, b, kind = SurfaceKind.wall) { this.a = a; this.b = b; this.kind = kind; }
  get fallbackNormal() {
    const d = this.b.sub(this.a).normalized;
    return new V2(-d.y, d.x);
  }
}

function closestPointOnSegment(p, a, b) {
  const ab = b.sub(a);
  const len2 = ab.lengthSquared;
  if (len2 < 1e-12) return a;
  let t = p.sub(a).dot(ab) / len2;
  if (t < 0) t = 0;
  if (t > 1) t = 1;
  return a.add(ab.mul(t));
}

// ---------- arena.dart ----------

const kArenaWidth = 100;
const kArenaHeight = 160;
const kBallRadius = 2.2;
const kTargetRadius = 4.6;
const kShotSpeed = 132;
const kMaxBanks = 5;
const kMaxMultiplier = 6;
const kPointsPerTarget = 100;
const kShooterOrigin = new V2(kArenaWidth / 2, 150);

function target(x, y, requiredBanks, palette = 0) {
  return { pos: new V2(x, y), requiredBanks, palette };
}

function block(left, top, right, bottom) {
  return { left, top, right, bottom };
}

function blockSegments(b) {
  const tl = new V2(b.left, b.top);
  const tr = new V2(b.right, b.top);
  const br = new V2(b.right, b.bottom);
  const bl = new V2(b.left, b.bottom);
  return [
    new Segment(tl, tr, SurfaceKind.block),
    new Segment(tr, br, SurfaceKind.block),
    new Segment(br, bl, SurfaceKind.block),
    new Segment(bl, tl, SurfaceKind.block),
  ];
}

function arenaWalls() {
  return [
    new Segment(new V2(0, 0), new V2(0, kArenaHeight)),
    new Segment(new V2(kArenaWidth, 0), new V2(kArenaWidth, kArenaHeight)),
    new Segment(new V2(0, 0), new V2(kArenaWidth, 0)),
  ];
}

function buildSegments(arena) {
  const out = arenaWalls();
  for (const b of arena.blocks || []) out.push(...blockSegments(b));
  for (const d of arena.deflectors || []) out.push(new Segment(d.a, d.b, SurfaceKind.deflector));
  return out;
}

// ---------- shot_runner.dart ----------

const ShotEndReason = { exitedBottom: 'exitedBottom', banksExhausted: 'banksExhausted', timeout: 'timeout' };
const ShotEventKind = { bank: 'bank', blocked: 'blocked', broke: 'broke' };

const _substep = 1 / 480;
const _segDebounce = 0.05;
const _targetDebounce = 0.12;

class ShotRunner {
  constructor({ segments, targets, alive, origin, direction, recordTrail = true }) {
    this.segments = segments;
    this.targets = targets;
    this.alive = alive;
    this.recordTrail = recordTrail;
    this.ball = { pos: origin, vel: direction.normalized.mul(kShotSpeed), alive: true };
    this.banks = 0;
    this.elapsed = 0;
    this.endReason = null;
    this.trail = [];
    this.pending = [];
    this._segReadyAt = new Map();
    this._targetReadyAt = new Map();
  }

  get multiplier() {
    const m = 1 + this.banks;
    return m > kMaxMultiplier ? kMaxMultiplier : m;
  }

  step(dt) {
    if (!this.ball.alive) return;
    let remaining = dt > 0.05 ? 0.05 : dt;
    while (remaining > 0 && this.ball.alive) {
      const h = remaining < _substep ? remaining : _substep;
      this._advance(h);
      remaining -= h;
    }
    if (this.recordTrail) this.trail.push(this.ball.pos);
  }

  _advance(h) {
    this.elapsed += h;
    this.ball.pos = this.ball.pos.add(this.ball.vel.mul(h));
    this._resolveSegments();
    this._resolveTargets();
    if (this.ball.pos.y - kBallRadius > kArenaHeight) {
      this.ball.alive = false;
      this.endReason = ShotEndReason.exitedBottom;
    } else if (this.banks >= kMaxBanks) {
      this.ball.alive = false;
      this.endReason = ShotEndReason.banksExhausted;
    } else if (this.elapsed > 14) {
      this.ball.alive = false;
      this.endReason = ShotEndReason.timeout;
    }
  }

  _resolveSegments() {
    for (let i = 0; i < this.segments.length; i++) {
      const s = this.segments[i];
      const closest = closestPointOnSegment(this.ball.pos, s.a, s.b);
      const d = this.ball.pos.sub(closest);
      const dist = d.length;
      if (dist >= kBallRadius) continue;
      const n = dist > 1e-6 ? d.mul(1 / dist) : s.fallbackNormal;
      this.ball.pos = this.ball.pos.add(n.mul(kBallRadius - dist + 0.02));
      const vn = this.ball.vel.dot(n);
      if (vn >= 0) continue;
      this.ball.vel = this.ball.vel.reflect(n);
      const ready = this._segReadyAt.has(i) ? this._segReadyAt.get(i) : -1.0;
      if (this.elapsed >= ready) {
        this.banks++;
        this._segReadyAt.set(i, this.elapsed + _segDebounce);
        this.pending.push({ kind: ShotEventKind.bank, pos: closest, bankCount: this.banks, points: 0, targetIndex: -1 });
      }
    }
  }

  _resolveTargets() {
    const contact = kBallRadius + kTargetRadius;
    for (let i = 0; i < this.targets.length; i++) {
      if (!this.alive[i]) continue;
      const t = this.targets[i];
      const d = this.ball.pos.sub(t.pos);
      const dist = d.length;
      if (dist >= contact) continue;

      if (this.banks >= t.requiredBanks) {
        this.alive[i] = false;
        this.pending.push({
          kind: ShotEventKind.broke, pos: t.pos, bankCount: this.banks,
          targetIndex: i, points: kPointsPerTarget * this.multiplier,
        });
        continue;
      }

      const n = dist > 1e-6 ? d.mul(1 / dist) : new V2(0, -1);
      this.ball.pos = this.ball.pos.add(n.mul(contact - dist + 0.02));
      const vn = this.ball.vel.dot(n);
      if (vn >= 0) continue;
      this.ball.vel = this.ball.vel.reflect(n);
      const ready = this._targetReadyAt.has(i) ? this._targetReadyAt.get(i) : -1.0;
      if (this.elapsed >= ready) {
        this._targetReadyAt.set(i, this.elapsed + _targetDebounce);
        this.pending.push({ kind: ShotEventKind.blocked, pos: t.pos, bankCount: 0, targetIndex: i, points: 0 });
      }
    }
  }
}

function clampAim(direction) {
  let d = direction.normalized;
  if (d.lengthSquared < 1e-9) return new V2(0, -1);
  if (d.y > -0.6) d = new V2(d.x, -0.6).normalized;
  return d;
}

/// Flies one shot to death. Returns {broke:[indices], points, banks, endReason, trail}
function fly({ segments, targets, alive, direction, presetBanks = 0, recordTrail = false, maxSeconds = 20 }) {
  const r = new ShotRunner({ segments, targets, alive, origin: kShooterOrigin, direction, recordTrail });
  r.banks = presetBanks;
  let t = 0;
  while (r.ball.alive && t < maxSeconds) { r.step(1 / 120); t += 1 / 120; }
  const broke = r.pending.filter(e => e.kind === ShotEventKind.broke);
  return {
    runner: r,
    broke: broke.map(e => e.targetIndex),
    points: broke.reduce((a, e) => a + e.points, 0),
    blocked: r.pending.filter(e => e.kind === ShotEventKind.blocked).length,
    banks: r.banks,
    endReason: r.endReason,
    trail: r.trail,
  };
}

// ---------- arenas.dart ----------

const kArenas = [
  {
    id: 1, name: "Bắn thẳng không tính", shots: 3,
    hint: "Bắn thẳng thì chúng nó cười. Phải dội tường trước đã!",
    targets: [target(50, 104, 1, 0), target(22, 44, 1, 1), target(78, 44, 1, 2)],
    blocks: [block(40, 60, 60, 68)],
    deflectors: [],
    starThresholds: [750, 1100, 1350],
  },
  {
    id: 2, name: "Ba đứa trên cao", shots: 3,
    hint: "Không có vật cản. Chỉ có tường và góc bắn của bạn.",
    targets: [target(20, 36, 3, 1), target(50, 28, 2, 2), target(80, 36, 3, 3)],
    blocks: [],
    deflectors: [],
    starThresholds: [750, 1100, 1350],
  },
  {
    id: 3, name: "Sát tường", shots: 3,
    hint: "Đứa sát tường khó ăn hơn đứa giữa sân.",
    targets: [target(11, 112, 2, 0), target(89, 112, 2, 1), target(50, 40, 1, 2)],
    blocks: [],
    deflectors: [],
    starThresholds: [550, 800, 1000],
  },
  {
    id: 4, name: "Hình thoi", shots: 3,
    hint: "Một cú đi xuyên được mấy đứa?",
    targets: [target(50, 30, 1, 0), target(28, 60, 2, 1), target(72, 60, 2, 2), target(50, 92, 1, 3)],
    blocks: [block(44, 44, 56, 50)],
    deflectors: [],
    starThresholds: [850, 1200, 1550],
  },
  {
    id: 5, name: "Sau cây cột", shots: 3,
    hint: "Cột giữa sân không cho bạn đi đường thẳng.",
    targets: [target(26, 52, 2, 0), target(74, 52, 2, 1), target(50, 22, 1, 2)],
    blocks: [block(44, 66, 56, 118)],
    deflectors: [],
    starThresholds: [650, 950, 1150],
  },
  {
    id: 6, name: "Ngóc ngách", shots: 4,
    hint: "Mấy đứa trong hốc chỉ ăn cú dội từ trên xuống thôi.",
    targets: [target(50, 100, 1, 0), target(15, 54, 2, 1), target(85, 54, 2, 2), target(50, 24, 3, 3)],
    blocks: [block(0, 66, 30, 73), block(70, 66, 100, 73)],
    deflectors: [{ a: new V2(40, 38), b: new V2(60, 38) }],
    starThresholds: [950, 1350, 1700],
  },
  {
    id: 7, name: "Mái che", shots: 3,
    hint: "Có mái thì đi vòng, đừng đi thẳng.",
    targets: [target(24, 30, 2, 0), target(76, 30, 2, 1), target(50, 78, 2, 2)],
    blocks: [block(32, 46, 68, 54)],
    deflectors: [],
    starThresholds: [700, 1000, 1250],
  },
  {
    id: 8, name: "Bậc thang", shots: 3,
    hint: "Bậc thang bên trái là tường phụ, dùng nó đi.",
    targets: [target(80, 100, 2, 0), target(80, 62, 3, 1), target(78, 26, 2, 2)],
    blocks: [block(0, 112, 30, 119), block(0, 74, 22, 81), block(0, 36, 14, 43)],
    deflectors: [],
    starThresholds: [700, 1000, 1250],
  },
  {
    id: 9, name: "Hai cái hốc", shots: 3,
    hint: "Hai bên là hốc. Giữa là đường vào.",
    targets: [target(14, 90, 2, 0), target(86, 90, 2, 1), target(50, 34, 2, 2), target(50, 118, 1, 3)],
    blocks: [block(0, 104, 28, 110), block(72, 104, 100, 110), block(40, 60, 60, 66)],
    deflectors: [],
    starThresholds: [900, 1300, 1600],
  },
  {
    id: 10, name: "Kẹp giữa", shots: 4,
    hint: "Khe giữa hai cột hẹp hơn bạn tưởng.",
    targets: [target(50, 42, 3, 0), target(20, 100, 2, 1), target(80, 100, 2, 2)],
    blocks: [block(32, 60, 40, 120), block(60, 60, 68, 120)],
    deflectors: [],
    starThresholds: [750, 1100, 1350],
  },
  {
    id: 11, name: "Chuỗi dội", shots: 3,
    hint: "Càng dội càng nhân điểm. Một cú ăn hết bốn đứa được không?",
    targets: [target(14, 118, 1, 0), target(86, 96, 2, 1), target(14, 74, 3, 2), target(86, 52, 4, 3)],
    blocks: [block(46, 84, 54, 112)],
    deflectors: [],
    starThresholds: [800, 1150, 1450],
  },
  {
    id: 12, name: "Leo thang", shots: 4,
    hint: "Đi zig-zag lên. Đừng tham đứa trên cùng ngay.",
    targets: [target(12, 108, 1, 0), target(88, 82, 2, 1), target(12, 56, 3, 2), target(88, 30, 4, 3), target(50, 128, 1, 0)],
    blocks: [],
    deflectors: [],
    starThresholds: [1150, 1650, 2050],
  },
  {
    id: 13, name: "Hành lang", shots: 4,
    hint: "Hành lang hẹp: bi vào được thì dội rất nhanh.",
    targets: [target(50, 24, 3, 0), target(50, 56, 2, 1), target(18, 122, 1, 2), target(82, 122, 1, 3)],
    blocks: [block(34, 74, 42, 132), block(58, 74, 66, 132)],
    deflectors: [],
    starThresholds: [900, 1300, 1600],
  },
  {
    id: 14, name: "Dán tường", shots: 3,
    hint: "Cả bốn đứa đều dán tường. Vui đấy.",
    targets: [target(10, 120, 2, 0), target(10, 60, 3, 1), target(90, 120, 2, 2), target(90, 60, 3, 3)],
    blocks: [block(42, 40, 58, 130)],
    deflectors: [],
    starThresholds: [900, 1300, 1600],
  },
  {
    id: 15, name: "Chữ thập", shots: 3,
    hint: "Bốn góc, một cây thập ở giữa.",
    targets: [target(18, 40, 2, 0), target(82, 40, 2, 1), target(18, 110, 2, 2), target(82, 110, 2, 3)],
    blocks: [block(44, 44, 56, 106), block(28, 70, 72, 80)],
    deflectors: [],
    starThresholds: [900, 1300, 1600],
  },
  {
    id: 16, name: "Chéo giữa sân", shots: 3,
    hint: "Vật cản chéo đổi hướng bi kiểu khác tường.",
    targets: [target(20, 44, 2, 0), target(80, 44, 2, 1), target(50, 110, 1, 2)],
    blocks: [],
    deflectors: [{ a: new V2(34, 84), b: new V2(66, 68) }],
    starThresholds: [750, 1100, 1350],
  },
  {
    id: 17, name: "Cái phễu", shots: 3,
    hint: "Phễu đẩy bi ra hai bên. Đừng chống lại nó.",
    targets: [target(14, 62, 3, 0), target(86, 62, 3, 1), target(50, 26, 2, 2)],
    blocks: [],
    deflectors: [{ a: new V2(30, 96), b: new V2(48, 116) }, { a: new V2(70, 96), b: new V2(52, 116) }],
    starThresholds: [750, 1100, 1350],
  },
  {
    id: 18, name: "Nóc nhà", shots: 4,
    hint: "Đứa trên nóc chỉ vào được từ bên sườn.",
    targets: [target(50, 20, 3, 0), target(22, 74, 2, 1), target(78, 74, 2, 2), target(50, 116, 1, 3)],
    blocks: [block(30, 34, 70, 40)],
    deflectors: [{ a: new V2(12, 52), b: new V2(30, 40) }, { a: new V2(88, 52), b: new V2(70, 40) }],
    starThresholds: [950, 1350, 1700],
  },
  {
    id: 19, name: "Hai lưỡi dao", shots: 4,
    hint: "Hai lưỡi chéo hai bên. Bi sẽ đi lối bạn không định.",
    targets: [target(50, 34, 3, 0), target(16, 108, 2, 1), target(84, 108, 2, 2), target(50, 74, 2, 3)],
    blocks: [],
    deflectors: [{ a: new V2(6, 88), b: new V2(34, 62) }, { a: new V2(94, 88), b: new V2(66, 62) }],
    starThresholds: [800, 1150, 1450],
  },
  {
    id: 20, name: "Bừa hết cỡ", shots: 5,
    hint: "Tất cả cùng lúc. Bắn bừa đúng chỗ đi.",
    targets: [target(50, 18, 4, 0), target(14, 52, 3, 1), target(86, 52, 3, 2), target(26, 106, 2, 3), target(74, 106, 2, 0), target(50, 128, 1, 1)],
    blocks: [block(38, 34, 62, 40), block(44, 70, 56, 92)],
    deflectors: [{ a: new V2(8, 78), b: new V2(30, 62) }, { a: new V2(92, 78), b: new V2(70, 62) }],
    starThresholds: [1300, 1850, 2350],
  },
];

module.exports = {
  V2, Segment, SurfaceKind, closestPointOnSegment,
  kArenaWidth, kArenaHeight, kBallRadius, kTargetRadius, kShotSpeed,
  kMaxBanks, kMaxMultiplier, kPointsPerTarget, kShooterOrigin,
  ShotRunner, ShotEndReason, ShotEventKind, clampAim, fly,
  buildSegments, arenaWalls, blockSegments, kArenas, target, block,
};
