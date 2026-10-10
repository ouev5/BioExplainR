const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
const root = path.resolve(__dirname, '../..');
const paper = path.resolve(process.argv[2] || path.join(root, 'docs/paper_cn_v5'));
const output = path.resolve(process.argv[3] || path.join(paper, 'browser_final'));
(async () => {
  fs.mkdirSync(output);
  const browser = await chromium.launch({ executablePath: '/usr/bin/google-chrome', headless: true, args: ['--no-sandbox'] });
  const results = [];
  try {
    for (const [name, figures, tables] of [['BioExplainR-中文论文-v0.11', 3, 2], ['BioExplainR-补充材料-v0.11', 2, 4]]) {
      for (const width of [1440, 390]) {
        const page = await browser.newPage({ viewport: { width, height: 980 } });
        const errors = [];
        page.on('pageerror', error => errors.push(String(error)));
        await page.goto('file://' + path.join(paper, name + '.html'));
        const state = await page.evaluate(() => ({
          images: [...document.images].map(image => image.complete && image.naturalWidth > 0),
          tables: document.querySelectorAll('table').length,
          overflow: document.documentElement.scrollWidth > innerWidth + 1,
          required: ['PER2', '109,636', '不可估计', '18h'].every(text => document.body.textContent.replace(/\s/g, '').includes(text)),
          externalResources: [...document.images].some(image => !image.src.startsWith('data:')),
        }));
        if (state.images.length !== figures || state.images.some(ok => !ok) || state.tables !== tables || state.overflow ||
            !state.required || state.externalResources || errors.length) {
          throw Error(JSON.stringify({ name, width, ...state, errors }));
        }
        await page.screenshot({ path: path.join(output, (tables === 2 ? 'main' : 'supplement') + '-' + width + '.png'), fullPage: true });
        results.push({ name, width, ...state, errors });
        await page.close();
      }
    }
  } finally { await browser.close(); }
  const result = { status: 'pass', results, scope: 'DOM content, image loading and viewport geometry; no human visual review' };
  fs.writeFileSync(path.join(output, 'audit.json'), JSON.stringify(result, null, 2) + '\n');
  console.log(JSON.stringify(result, null, 2));
})().catch(error => { console.error(error); process.exitCode = 1; });
