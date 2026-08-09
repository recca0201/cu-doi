const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');

const OUT = '/tmp/shots';
fs.mkdirSync(OUT, { recursive: true });

(async () => {
  const browser = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium-1194/chrome-linux/chrome' });
  const page = await browser.newPage({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 2 });
  const errors = [];
  page.on('pageerror', e => errors.push(String(e)));
  page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });

  await page.goto('file://' + path.join('/tmp/verify', 'index.html'));
  await page.waitForFunction(() => !!window.__bb);

  async function shot(name, fn, arg) {
    await page.evaluate(fn, arg);
    await page.screenshot({ path: path.join(OUT, name) });
    console.log('  ->', name);
  }

  // 1. Arena 1 idle, aiming up-left. Everyone smug, chips showing "1".
  await shot('01-aim-arena1.png', () => {
    const b = window.__bb;
    const st = b.makeState(0, -28);
    b.renderFrame(document.getElementById('c'), {
      arenaIndex: 0, aim: { x: st.aim.x, y: st.aim.y }, alive: st.alive,
      banks: 0, score: 0, shotsLeft: 4, ball: null, trail: [], ghost: [],
      stamps: [], showPreview: true, preview: st.preview.map(p => ({ x: p.x, y: p.y })),
    });
  });

  // 2. The teaching moment: a straight shot bouncing off the bait target.
  await shot('02-direct-hit-rejected.png', () => {
    const b = window.__bb;
    const frames = b.captureShot(0, 0);
    const i = frames.findIndex(f => f.stamps.some(s => s.txt === 'Bắn thẳng à?'));
    b.renderFrame(document.getElementById('c'), frames[i >= 0 ? i + 6 : Math.floor(frames.length / 3)]);
  });

  // 3. Mid-carom with targets armed and the multiplier live.
  await shot('03-armed-midflight.png', () => {
    const b = window.__bb;
    const frames = b.captureShot(0, -28);
    let best = 0;
    frames.forEach((f, i) => { if (f.ball && f.banks >= 2 && f.trail.length > frames[best].trail.length) best = i; });
    b.renderFrame(document.getElementById('c'), frames[best]);
  });

  // 4. A break landing, with the points stamp.
  await shot('04-break-stamp.png', () => {
    const b = window.__bb;
    let picked = null;
    for (const deg of [-46.8, -28, -17.5, 9.4, 30, -59]) {
      const frames = b.captureShot(0, deg);
      const i = frames.findIndex(f => f.stamps.some(s => s.txt.startsWith('+')));
      if (i >= 0) { picked = frames[Math.min(i + 5, frames.length - 1)]; break; }
    }
    b.renderFrame(document.getElementById('c'), picked || b.captureShot(0, -28)[20]);
  });

  // 5 & 6. Arena 2 and 3 idle, to show the layouts.
  for (const [idx, name] of [[1, '05-arena2-layout.png'], [2, '06-arena3-layout.png']]) {
    await shot(name, ({ idx }) => {
      const b = window.__bb;
      const st = b.makeState(idx, idx === 1 ? -40 : -20);
      b.renderFrame(document.getElementById('c'), {
        arenaIndex: idx, aim: { x: st.aim.x, y: st.aim.y }, alive: st.alive,
        banks: 0, score: 0, shotsLeft: b.kArenas[idx].shots, ball: null,
        trail: [], ghost: [], stamps: [], showPreview: true,
        preview: st.preview.map(p => ({ x: p.x, y: p.y })),
      });
    }, { idx });
  }

  // Fix: the loop above needs an arg-passing variant.
  await browser.close();
  if (errors.length) { console.log('\nPAGE ERRORS:'); errors.forEach(e => console.log('  ' + e)); process.exit(1); }
  console.log('\nno page errors');
})();
