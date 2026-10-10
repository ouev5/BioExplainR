const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { chromium } = require('playwright');

(async () => {
  const output = process.env.BIOEXPLAINR_PAPER_CN_BROWSER;
  fs.mkdirSync(output, { recursive: false });
  const browser = await chromium.launch({ executablePath: '/usr/bin/google-chrome', headless: true, args: ['--no-sandbox'] });
  const page = await browser.newPage();
  const errors = [];
  page.on('pageerror', e => errors.push(e.message));
  const results = [];
  try {
    await page.goto(`file://${path.resolve('docs/paper_cn_v1/BioExplainR-中文论文-v0.8.html')}`);
    for (const viewport of [{ width: 1440, height: 1000 }, { width: 390, height: 844 }]) {
      await page.setViewportSize(viewport);
      const result = await page.evaluate(() => ({ width: innerWidth, scroll: document.documentElement.scrollWidth,
        figures: Array.from(document.images).map(i => ({ loaded: i.complete && i.naturalWidth > 0, width: i.clientWidth })),
        tables: document.querySelectorAll('table').length, hasFuture: document.body.innerText.includes('用户使用体验与可用性') }));
      assert(result.scroll <= result.width + 2);
      assert.equal(result.figures.length, 8);
      assert(result.figures.every(i => i.loaded && i.width <= result.width));
      assert.equal(result.tables, 0);
      assert(result.hasFuture);
      await page.screenshot({ path: path.join(output, `manuscript-${viewport.width}.png`), fullPage: true });
      results.push({ viewport, ...result });
    }
    assert.equal(errors.length, 0);
    const summary = { status: 'pass', results, errors };
    fs.writeFileSync(path.join(output, 'summary.json'), JSON.stringify(summary, null, 2));
    console.log(JSON.stringify(summary, null, 2));
  } finally { await browser.close(); }
})().catch(e => { console.error(e); process.exitCode = 1; });
