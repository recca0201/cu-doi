// Browser-side renderer mirroring lib/ui/arena_painter.dart, so the screenshots
// show what the Flutter build should look like rather than an approximation.

const Stage = {
  bgTop: '#171238', bgBottom: '#2C1F5C', frame: '#FFC24A',
  blockFill: '#0D0922', deflector: '#7BE0FF', outline: '#120E2B',
  cream: '#FFF7E6', danger: '#FF6B6B',
  targets: ['#FF6B6B', '#4ECDC4', '#FFD93D', '#A78BFA'],
};
const FONT = '"DejaVu Sans", system-ui, sans-serif';

function rgba(hex, a) {
  const r = parseInt(hex.slice(1, 3), 16), g = parseInt(hex.slice(3, 5), 16), b = parseInt(hex.slice(5, 7), 16);
  return `rgba(${r},${g},${b},${a})`;
}

const HUD_H = 64, FOOT_H = 96;

function fitFor(w, h) {
  const s = Math.min(w / kArenaWidth, h / kArenaHeight);
  return { s, dx: (w - kArenaWidth * s) / 2, dy: (h - kArenaHeight * s) / 2 };
}
const SX = (f, p) => f.dx + p.x * f.s;
const SY = (f, p) => f.dy + p.y * f.s;

function text(ctx, str, cx, cy, size, color, weight = 800) {
  ctx.font = `${weight} ${size}px ${FONT}`;
  ctx.fillStyle = color;
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.fillText(str, cx, cy);
}

function dashedPoly(ctx, pts, color, width, dash, gap) {
  ctx.save();
  ctx.strokeStyle = color; ctx.lineWidth = width; ctx.lineCap = 'round';
  ctx.setLineDash([dash, gap]);
  ctx.beginPath();
  pts.forEach((p, i) => (i ? ctx.lineTo(p[0], p[1]) : ctx.moveTo(p[0], p[1])));
  ctx.stroke();
  ctx.restore();
}

function roundRect(ctx, x, y, w, h, r) {
  ctx.beginPath();
  ctx.moveTo(x + r, y);
  ctx.arcTo(x + w, y, x + w, y + h, r);
  ctx.arcTo(x + w, y + h, x, y + h, r);
  ctx.arcTo(x, y + h, x, y, r);
  ctx.arcTo(x, y, x + w, y, r);
  ctx.closePath();
}

function drawFace(ctx, cx, cy, r, armed) {
  const ex = r * 0.36, ey = -r * 0.14;
  ctx.fillStyle = Stage.outline; ctx.strokeStyle = Stage.outline;
  if (armed) {
    for (const sx of [-1, 1]) {
      ctx.beginPath(); ctx.arc(cx + sx * ex, cy + ey, r * 0.20, 0, 7); ctx.fill();
    }
    ctx.beginPath(); ctx.arc(cx, cy + r * 0.42, r * 0.15, 0, 7); ctx.fill();
    return;
  }
  ctx.lineWidth = r * 0.15; ctx.lineCap = 'round';
  for (const sx of [-1, 1]) {
    ctx.beginPath();
    ctx.moveTo(cx + sx * ex - r * 0.16, cy + ey);
    ctx.lineTo(cx + sx * ex + r * 0.16, cy + ey);
    ctx.stroke();
  }
  ctx.lineWidth = r * 0.13;
  ctx.beginPath();
  ctx.moveTo(cx - r * 0.18, cy + r * 0.38);
  ctx.quadraticCurveTo(cx + r * 0.10, cy + r * 0.56, cx + r * 0.34, cy + r * 0.30);
  ctx.stroke();
}

function drawArena(ctx, W, H, st) {
  const arena = kArenas[st.arenaIndex];
  const f = fitFor(W, H);
  const u = v => v * f.s;

  const L = SX(f, new V2(0, 0)), T = SY(f, new V2(0, 0));
  const R = SX(f, new V2(kArenaWidth, 0)), B = SY(f, new V2(0, kArenaHeight));

  ctx.fillStyle = rgba(Stage.frame, 0.12);
  ctx.fillRect(L, T, R - L, B - T);

  // walls: left/top/right solid, bottom dashed red (not a wall)
  ctx.strokeStyle = Stage.frame; ctx.lineWidth = u(0.9); ctx.lineCap = 'round';
  ctx.beginPath(); ctx.moveTo(L, B); ctx.lineTo(L, T); ctx.lineTo(R, T); ctx.lineTo(R, B); ctx.stroke();
  dashedPoly(ctx, [[L, B], [R, B]], rgba(Stage.danger, 0.47), u(0.6), u(2.4), u(2.0));

  for (const b of arena.blocks || []) {
    const x = SX(f, new V2(b.left, 0)), y = SY(f, new V2(0, b.top));
    const w = u(b.right - b.left), h = u(b.bottom - b.top);
    roundRect(ctx, x, y, w, h, u(1.2));
    ctx.fillStyle = Stage.blockFill; ctx.fill();
    ctx.strokeStyle = rgba(Stage.frame, 0.6); ctx.lineWidth = u(0.55); ctx.stroke();
  }

  for (const d of arena.deflectors || []) {
    for (const [col, wd] of [[rgba(Stage.deflector, 0.22), u(3.0)], [Stage.deflector, u(1.1)]]) {
      ctx.strokeStyle = col; ctx.lineWidth = wd; ctx.lineCap = 'round';
      ctx.beginPath(); ctx.moveTo(SX(f, d.a), SY(f, d.a)); ctx.lineTo(SX(f, d.b), SY(f, d.b)); ctx.stroke();
    }
  }

  if (st.ghost && st.ghost.length > 1) {
    ctx.strokeStyle = rgba(Stage.cream, 0.14); ctx.lineWidth = u(0.5);
    ctx.beginPath(); st.ghost.forEach((p, i) => (i ? ctx.lineTo(SX(f, p), SY(f, p)) : ctx.moveTo(SX(f, p), SY(f, p))));
    ctx.stroke();
  }

  if (st.trail && st.trail.length > 1) {
    ctx.strokeStyle = rgba(Stage.cream, 0.35); ctx.lineWidth = u(0.55);
    ctx.beginPath(); st.trail.forEach((p, i) => (i ? ctx.lineTo(SX(f, p), SY(f, p)) : ctx.moveTo(SX(f, p), SY(f, p))));
    ctx.stroke();
    const head = st.trail.slice(Math.max(0, st.trail.length - 26));
    ctx.strokeStyle = Stage.cream; ctx.lineWidth = u(0.95);
    ctx.beginPath(); head.forEach((p, i) => (i ? ctx.lineTo(SX(f, p), SY(f, p)) : ctx.moveTo(SX(f, p), SY(f, p))));
    ctx.stroke();
  }

  arena.targets.forEach((t, i) => {
    if (!st.alive[i]) return;
    const cx = SX(f, t.pos), cy = SY(f, t.pos), r = u(kTargetRadius);
    const base = Stage.targets[t.palette % 4];
    const armed = st.banks >= t.requiredBanks;
    if (armed) {
      ctx.fillStyle = rgba(base, 0.16);
      ctx.beginPath(); ctx.arc(cx, cy, r * 1.55, 0, 7); ctx.fill();
      ctx.strokeStyle = rgba(base, 0.59); ctx.lineWidth = u(0.5);
      ctx.beginPath(); ctx.arc(cx, cy, r * 1.24, 0, 7); ctx.stroke();
    }
    ctx.fillStyle = base;
    ctx.beginPath(); ctx.arc(cx, cy, r, 0, 7); ctx.fill();
    ctx.strokeStyle = Stage.outline; ctx.lineWidth = u(0.6);
    ctx.beginPath(); ctx.arc(cx, cy, r, 0, 7); ctx.stroke();
    drawFace(ctx, cx, cy, r, armed);
    // requirement chip
    const chx = cx + r * 0.78, chy = cy - r * 0.78, cr = r * 0.46;
    ctx.fillStyle = Stage.outline;
    ctx.beginPath(); ctx.arc(chx, chy, cr, 0, 7); ctx.fill();
    ctx.strokeStyle = armed ? Stage.frame : rgba(Stage.cream, 0.4); ctx.lineWidth = u(0.35);
    ctx.beginPath(); ctx.arc(chx, chy, cr, 0, 7); ctx.stroke();
    text(ctx, String(t.requiredBanks), chx, chy, cr * 1.25, armed ? Stage.frame : Stage.cream);
  });

  if (st.showPreview && st.preview && st.preview.length > 1) {
    const pts = st.preview.map(p => [SX(f, p), SY(f, p)]);
    dashedPoly(ctx, pts.slice(0, 2), rgba(Stage.frame, 0.54), u(0.6), u(2.2), u(1.8));
    if (pts.length > 2) dashedPoly(ctx, pts.slice(1), rgba(Stage.frame, 0.24), u(0.5), u(1.5), u(2.4));
  }

  // launcher
  const ox = SX(f, kShooterOrigin), oy = SY(f, kShooterOrigin);
  ctx.save(); ctx.translate(ox, oy); ctx.rotate(Math.atan2(st.aim.y, st.aim.x));
  roundRect(ctx, 0, -u(2.4), u(10), u(4.8), u(1.2));
  ctx.fillStyle = Stage.frame; ctx.fill();
  ctx.strokeStyle = Stage.outline; ctx.lineWidth = u(0.5); ctx.stroke();
  ctx.restore();
  ctx.fillStyle = Stage.outline; ctx.beginPath(); ctx.arc(ox, oy, u(5.2), 0, 7); ctx.fill();
  ctx.fillStyle = Stage.frame; ctx.beginPath(); ctx.arc(ox, oy, u(4.0), 0, 7); ctx.fill();

  if (st.ball) {
    const bx = SX(f, st.ball), by = SY(f, st.ball);
    ctx.fillStyle = rgba(Stage.cream, 0.2);
    ctx.beginPath(); ctx.arc(bx, by, u(kBallRadius * 2.2), 0, 7); ctx.fill();
    ctx.fillStyle = Stage.cream;
    ctx.beginPath(); ctx.arc(bx, by, u(kBallRadius), 0, 7); ctx.fill();
  }

  if (st.ball && st.banks > 0) {
    text(ctx, `BỪA ×${Math.min(1 + st.banks, kMaxMultiplier)}`, W / 2, SY(f, new V2(0, 14)), u(11), rgba(Stage.frame, 0.35));
  }

  for (const s of st.stamps) {
    const t01 = Math.min(1, s.age / 1.1);
    const x = SX(f, s.pos), y = SY(f, s.pos) - u(kTargetRadius + 3.5) - u(7) * t01;
    text(ctx, s.txt, x, y, u(s.big ? 7 : 4.6) * (1 + 0.18 * (1 - t01)), rgba(s.color, 1 - t01));
  }
}

function drawChrome(ctx, W, H, st) {
  const arena = kArenas[st.arenaIndex];
  const g = ctx.createLinearGradient(0, 0, 0, H);
  g.addColorStop(0, Stage.bgTop); g.addColorStop(1, Stage.bgBottom);
  ctx.fillStyle = g; ctx.fillRect(0, 0, W, H);

  ctx.textAlign = 'left'; ctx.textBaseline = 'middle';
  ctx.font = `800 15px ${FONT}`; ctx.fillStyle = Stage.cream;
  ctx.fillText(`Màn ${arena.id} · ${arena.name}`, 14, 24);
  ctx.font = `700 12px ${FONT}`; ctx.fillStyle = Stage.frame;
  ctx.fillText(`Còn ${st.shotsLeft} cú bắn`, 14, 44);

  ctx.textAlign = 'right';
  ctx.font = `900 20px ${FONT}`; ctx.fillStyle = Stage.cream;
  ctx.fillText(String(st.score), W - 14, 24);
  ctx.font = `700 12px ${FONT}`;
  ctx.fillStyle = st.banks > 0 ? Stage.frame : Stage.cream;
  ctx.fillText(st.banks > 0 ? `BỪA ×${Math.min(1 + st.banks, kMaxMultiplier)}` : 'điểm', W - 14, 44);

  // footer — hint only, matching lib/ui/screens/game_screen.dart. (An earlier
  // version drew a stage-picker chip row here; the Flutter screen has no such
  // row, so the screenshots were showing UI that does not exist.)
  const fy = H - FOOT_H;
  text(ctx, arena.hint, W / 2, fy + 30, 12, Stage.cream, 700);
}

// ---------------------------------------------------------------------
// harness: play a scripted shot and expose frames
// ---------------------------------------------------------------------

function makeState(arenaIndex, aimDeg) {
  const arena = kArenas[arenaIndex];
  const rad = (aimDeg * Math.PI) / 180;
  const aim = clampAim(new V2(Math.sin(rad), -Math.cos(rad)));
  const alive = new Array(arena.targets.length).fill(true);
  return {
    arenaIndex, aim, alive, banks: 0, score: 0,
    shotsLeft: arena.shots, ball: null, trail: [], ghost: [], stamps: [],
    showPreview: true,
    preview: previewPathJS(buildSegments(arena), arena.targets, alive, aim),
  };
}

function previewPathJS(segments, targets, alive, direction) {
  const probe = new ShotRunner({ segments, targets, alive: alive.slice(), origin: kShooterOrigin, direction, recordTrail: false });
  const pts = [kShooterOrigin];
  let guard = 0, vertices = 0;
  while (probe.ball.alive && vertices < 2 && guard < 1500) {
    probe.step(1 / 120);
    for (const e of probe.pending) {
      if (e.kind === ShotEventKind.bank || e.kind === ShotEventKind.blocked) { pts.push(e.pos); vertices++; }
    }
    probe.pending.length = 0;
    guard++;
  }
  pts.push(probe.ball.pos);
  return pts;
}

/// Simulates one shot at 60fps and returns a frame array of render states.
function captureShot(arenaIndex, aimDeg, extraFrames = 40) {
  const arena = kArenas[arenaIndex];
  const st = makeState(arenaIndex, aimDeg);
  const frames = [JSON.parse(JSON.stringify({ ...st, aim: { x: st.aim.x, y: st.aim.y } }))];

  const runner = new ShotRunner({
    segments: buildSegments(arena), targets: arena.targets,
    alive: st.alive, origin: kShooterOrigin, direction: st.aim, recordTrail: true,
  });
  st.shotsLeft--;
  st.showPreview = false;

  let guard = 0;
  while (guard < 900) {
    if (runner.ball.alive) runner.step(1 / 60);
    for (const e of runner.pending) {
      if (e.kind === ShotEventKind.broke) {
        st.score += e.points;
        st.stamps.push({ txt: `+${e.points}`, pos: e.pos, color: Stage.cream, big: true, age: 0 });
      } else if (e.kind === ShotEventKind.blocked) {
        st.stamps.push({ txt: 'Bắn thẳng à?', pos: e.pos, color: Stage.danger, big: false, age: 0 });
      } else if (e.bankCount === 1) {
        st.stamps.push({ txt: 'DỘI!', pos: e.pos, color: Stage.frame, big: false, age: 0 });
      }
    }
    runner.pending.length = 0;
    st.stamps.forEach(s => (s.age += 1 / 60));
    st.stamps = st.stamps.filter(s => s.age <= 1.1);
    st.banks = runner.banks;
    st.ball = runner.ball.alive ? runner.ball.pos : null;
    st.trail = runner.trail.slice();

    frames.push({
      arenaIndex: st.arenaIndex, aim: { x: st.aim.x, y: st.aim.y }, alive: st.alive.slice(),
      banks: st.banks, score: st.score, shotsLeft: st.shotsLeft,
      ball: st.ball ? { x: st.ball.x, y: st.ball.y } : null,
      trail: st.trail.map(p => ({ x: p.x, y: p.y })), ghost: [],
      stamps: st.stamps.map(s => ({ ...s, pos: { x: s.pos.x, y: s.pos.y } })),
      showPreview: false, preview: [],
    });

    guard++;
    if (!runner.ball.alive) { extraFrames--; if (extraFrames <= 0) break; }
  }
  return frames;
}

function renderFrame(canvas, fr) {
  const W = canvas.width / (window.devicePixelRatio || 1);
  const H = canvas.height / (window.devicePixelRatio || 1);
  const ctx = canvas.getContext('2d');
  ctx.setTransform(1, 0, 0, 1, 0, 0);
  ctx.scale(window.devicePixelRatio || 1, window.devicePixelRatio || 1);
  const st = {
    ...fr,
    aim: new V2(fr.aim.x, fr.aim.y),
    ball: fr.ball ? new V2(fr.ball.x, fr.ball.y) : null,
    trail: (fr.trail || []).map(p => new V2(p.x, p.y)),
    ghost: (fr.ghost || []).map(p => new V2(p.x, p.y)),
    preview: (fr.preview || []).map(p => new V2(p.x, p.y)),
    stamps: (fr.stamps || []).map(s => ({ ...s, pos: new V2(s.pos.x, s.pos.y) })),
  };
  drawChrome(ctx, W, H, st);
  ctx.save();
  ctx.beginPath(); ctx.rect(0, HUD_H, W, H - HUD_H - FOOT_H); ctx.clip();
  ctx.translate(0, HUD_H);
  drawArena(ctx, W, H - HUD_H - FOOT_H, st);
  ctx.restore();
}

window.__bb = { captureShot, makeState, renderFrame, kArenas, V2, clampAim, previewPathJS, buildSegments, kShooterOrigin };
