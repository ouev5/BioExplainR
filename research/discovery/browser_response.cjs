const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
const root = path.resolve(__dirname, '../..');
const dest = path.join(root, 'docs/biology_discovery_v2/browser');
(async () => {
  fs.mkdirSync(dest);
  const browser = await chromium.launch({ executablePath: '/usr/bin/google-chrome', headless: true, args: ['--no-sandbox'] });
  const results = [];
  try {
    for (const width of [1440, 390]) {
      const page = await browser.newPage({ viewport: { width, height: 980 } });
      const errors = [];
      page.on('pageerror', e => errors.push(String(e)));
      await page.goto('file://' + path.join(root, 'docs/biology_discovery_v2/BioExplainR-生物学发现-结果报告-v1.html'));
      const state = await page.evaluate(() => ({
        images: [...document.images].map(i => i.complete && i.naturalWidth > 0),
        tables: document.querySelectorAll('table').length,
        overflow: document.documentElement.scrollWidth > innerWidth + 1,
        required: ['PER2', 'PER3', '54', '82,227', '不可估计', 'LINC00607'].every(t => document.body.textContent.includes(t))
      }));
      if (state.images.length !== 5 || state.images.some(i => !i) || state.tables !== 3 || state.overflow || !state.required || errors.length)
        throw Error(JSON.stringify({ width, ...state, errors }));
      await page.screenshot({ path: path.join(dest, 'report-' + width + '.png'), fullPage: true });
      results.push({ width, images: 5, tables: 3, overflow: false, errors, required_content: true });
      await page.close();
    }
  } finally { await browser.close(); }
  fs.writeFileSync(path.join(dest, 'audit.json'), JSON.stringify({ status: 'pass', results, visual_review: 'not performed; model cannot read images' }, null, 2) + '\n');
  console.log(JSON.stringify({ status: 'pass', results }, null, 2));
})().catch(e => { console.error(e); process.exitCode = 1; });
