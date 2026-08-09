// Renders every campaign arena so all 20 levels can be eyeballed at once.
// This is the closest available substitute for looking at them on a device.

const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');

const OUT = '/tmp/shots/levels';
fs.mkdirSync(OUT, { recursive: true });

(async () => {
  const browser = await chromium.launch({
    executablePath: '/opt/pw-browsers/chromium-1194/chrome-linux/chrome',
  });
  const page = await browser.newPage({
    viewport: { width: 390, height: 844 },
    deviceScaleFactor: 1,
  });
  const errors = [];
  page.on('pageerror', (e) => errors.push(String(e)));
  page.on('console', (m) => { if (m.type() === 'error') errors.push(m.text()); });

  await page.goto('file://' + path.join('/tmp/verify', 'index.html'));
  await page.waitForFunction(() => !!window.__bb);

  const count = await page.evaluate(() => window.__bb.kArenas.length);
  console.log(`rendering ${count} arenas`);

  for (let i = 0; i < count; i++) {
    await page.evaluate(({ i }) => {
      const b = window.__bb;
      // A shallow-ish default aim so the preview shows a real first leg.
      const st = b.makeState(i, i % 2 === 0 ? -32 : 32);
      b.renderFrame(document.getElementById('c'), {
        arenaIndex: i,
        aim: { x: st.aim.x, y: st.aim.y },
        alive: st.alive,
        banks: 0,
        score: 0,
        shotsLeft: b.kArenas[i].shots,
        ball: null,
        trail: [],
        ghost: [],
        stamps: [],
        showPreview: true,
        preview: st.preview.map((p) => ({ x: p.x, y: p.y })),
      });
    }, { i });
    const id = String(i + 1).padStart(2, '0');
    await page.screenshot({ path: path.join(OUT, `${id}.png`) });
  }

  // One frame mid-carom on the finale, with several targets armed, to show the
  // "armed" tell working on a busy board.
  await page.evaluate(() => {
    const b = window.__bb;
    const frames = b.captureShot(19, -34);
    let best = 0;
    frames.forEach((f, i) => {
      if (f.ball && f.banks >= 2 && f.trail.length > frames[best].trail.length) best = i;
    });
    b.renderFrame(document.getElementById('c'), frames[best]);
  });
  await page.screenshot({ path: '/tmp/shots/20-finale-midflight.png' });

  await browser.close();
  if (errors.length) {
    console.log('PAGE ERRORS:');
    errors.forEach((e) => console.log('  ' + e));
    process.exit(1);
  }
  console.log('no page errors');
})();
