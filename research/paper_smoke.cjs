const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const { pathToFileURL } = require('node:url');
const { chromium } = require('playwright');
(async () => {
  const output = process.env.BIOEXPLAINR_PAPER_RESULTS_DIR || 'research/results/browser';
  fs.mkdirSync(output, { recursive: true });
  const browser = await chromium.launch({ executablePath: '/usr/bin/google-chrome', headless: true, args: ['--no-sandbox'] });
  const page = await browser.newPage();
  const results = [];
  try {
    await page.goto(pathToFileURL(`${process.cwd()}/docs/BioExplainR-paper-draft.html`).href);
    for (const viewport of [{ width: 1440, height: 1000 }, { width: 390, height: 844 }]) {
      await page.setViewportSize(viewport);
      const facts = await page.evaluate(() => ({
        images: Array.from(document.images).map(i => ({ complete: i.complete, width: i.naturalWidth })),
        tables: document.querySelectorAll('table').length,
        width: innerWidth, scroll: document.documentElement.scrollWidth,
        hasReferences: document.body.textContent.includes('参考文献'),
        hasLimitations: document.body.textContent.includes('局限与后续研究')
      }));
       assert.equal(facts.images.length, 7);
      assert(facts.images.every(i => i.complete && i.width > 0));
       assert.equal(facts.tables, 13);
      assert(facts.scroll <= facts.width + 2, 'manuscript has horizontal overflow');
      assert(facts.hasReferences && facts.hasLimitations);
      await page.screenshot({ path: path.join(output, `paper-${viewport.width}.png`), fullPage: true });
      results.push({ viewport, facts });
    }
     await page.pdf({ path: path.join(output, 'paper-html-preview.pdf'), format: 'A4', printBackground: true,
       margin: { top: '18mm', bottom: '18mm', left: '16mm', right: '16mm' } });
    fs.writeFileSync(path.join(output, 'paper-summary.json'), JSON.stringify({ status: 'pass', results }, null, 2));
    console.log(JSON.stringify({ status: 'pass', results }, null, 2));
  } finally { await browser.close(); }
})().catch(e => { console.error(e); process.exitCode = 1; });
