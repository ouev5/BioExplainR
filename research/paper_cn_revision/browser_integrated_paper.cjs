const {chromium} = require('playwright');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const paper = path.resolve(process.argv[2] || 'docs/paper_cn_v7');
const output = path.resolve(process.argv[3] || path.join(paper, 'browser'));
const root = path.resolve(__dirname, '../..');
(async () => {
  fs.mkdirSync(output);
  const browser = await chromium.launch({executablePath: '/usr/bin/google-chrome', headless: true, args: ['--no-sandbox']});
  const results = [];
  const inputs = [];
  try {
    for (const [name, images, tables] of [['BioExplainR-中文论文-v0.13', 4, 4], ['BioExplainR-补充材料-v0.13', 6, 5]]) {
      const filename = path.join(paper, name + '.html');
      const bytes = fs.readFileSync(filename);
      inputs.push({path: path.relative(root, filename), bytes: bytes.length, sha256: crypto.createHash('sha256').update(bytes).digest('hex')});
      for (const width of [1440, 390]) {
        const page = await browser.newPage({viewport: {width, height: 980}});
        const errors = [];
        page.on('pageerror', e => errors.push(String(e)));
        await page.goto('file://' + path.join(paper, name + '.html'));
        const state = await page.evaluate(() => ({
          images: [...document.images].map(i => i.complete && i.naturalWidth > 0),
          tables: document.querySelectorAll('table').length,
          overflow: document.documentElement.scrollWidth > innerWidth + 1,
          externalResources: [...document.images].some(i => !i.src.startsWith('data:')),
          required: ['PER2', 'FBN2', 'PXD055968', '846', '803', '391', '5／5', '未发送'].every(s => document.body.textContent.includes(s))
        }));
        if (state.images.length !== images || state.images.some(s => !s) || state.tables !== tables || state.overflow || state.externalResources || !state.required || errors.length) {
          throw Error(JSON.stringify({name, width, state, errors}));
        }
        await page.screenshot({path: path.join(output, (images === 4 ? 'main' : 'supplement') + '-' + width + '.png'), fullPage: true});
        results.push({name, width, ...state, errors});
        await page.close();
      }
    }
  } finally {
    await browser.close();
  }
  const result = {status: 'pass', inputs, results, scope: 'Actual desktop/mobile DOM, self-contained images, required scope and overflow; no human review'};
  fs.writeFileSync(path.join(output, 'audit.json'), JSON.stringify(result, null, 2) + '\n');
  console.log(JSON.stringify(result, null, 2));
})().catch(e => {console.error(e); process.exitCode = 1;});
