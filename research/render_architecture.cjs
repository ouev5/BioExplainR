const fs = require('node:fs');
const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ executablePath: '/usr/bin/google-chrome', headless: true, args: ['--no-sandbox'] });
  const page = await browser.newPage({ viewport: { width: 1400, height: 720 }, deviceScaleFactor: 2 });
  try {
    const svg = fs.readFileSync('docs/figures/bioexplainr-architecture.svg', 'utf8');
    await page.setContent(`<html><body style="margin:0">${svg}</body></html>`);
    await page.locator('svg').screenshot({ path: 'docs/figures/bioexplainr-architecture.png' });
    console.log('Architecture figure rendered to docs/figures/bioexplainr-architecture.png');
  } finally { await browser.close(); }
})().catch(error => { console.error(error); process.exitCode = 1; });
