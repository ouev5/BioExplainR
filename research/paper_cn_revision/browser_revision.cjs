const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');
const root = path.resolve(__dirname, '../..');
const out = process.env.BIOEXPLAINR_REVISION_BROWSER || path.join(root, 'research/results/w00_baseline/revision-paper-browser');
(async () => {
  fs.mkdirSync(out, { recursive: false });
  const browser = await chromium.launch({ executablePath: '/usr/bin/google-chrome', headless: true, args: ['--no-sandbox'] });
  const results = [];
  try {
    for (const width of [1440, 390]) {
      for (const [name, figures, tables] of [['BioExplainR-中文论文-v0.9', 2, 1], ['BioExplainR-补充材料-v0.9', 8, 0]]) {
        const page = await browser.newPage({ viewport: { width, height: 980 } });
        const errors = [];
        page.on('pageerror', error => errors.push(String(error)));
        await page.goto('file://' + path.join(root, 'docs/paper_cn_v2', name + '.html'));
        const state = await page.evaluate(() => ({
          images: [...document.images].map(i => ({ loaded: i.complete && i.naturalWidth > 0 })),
          tables: document.querySelectorAll('table').length,
          overflow: document.documentElement.scrollWidth > innerWidth + 1,
          text: document.body.textContent,
        }));
        if (state.images.length !== figures || state.images.some(i => !i.loaded) || state.tables !== tables || state.overflow || errors.length)
          throw Error(JSON.stringify({ name, width, ...state, errors }));
        if (name.includes('中文论文') && !['iSEE', 'SCassist', 'GeneAgent', 'ellmer', 'GPTCelltype', 'SPARCL1'].every(s => state.text.includes(s)))
          throw Error('Missing comparison or discovery content');
        await page.screenshot({ path: path.join(out, `${name}-${width}.png`), fullPage: true });
        results.push({ name, width, images: figures, tables, overflow: false, errors });
        await page.close();
      }
    }
  } finally { await browser.close(); }
  fs.writeFileSync(path.join(out, 'summary.json'), JSON.stringify({ status: 'pass', results }, null, 2) + '\n');
  console.log(JSON.stringify({ status: 'pass', results }, null, 2));
})().catch(error => { console.error(error); process.exitCode = 1; });
