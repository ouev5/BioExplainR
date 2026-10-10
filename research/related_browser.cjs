const { chromium } = require('playwright');
const fs = require('node:fs');
const assert = require('node:assert/strict');
(async () => {
  const browser = await chromium.launch({executablePath: '/usr/bin/google-chrome', headless: true, args: ['--no-sandbox']});
  const page = await browser.newPage({viewport: {width: 1440, height: 1000}});
  const errors = [];
  page.on('pageerror', e => errors.push(e.message));
  try {
    for (let n = 0; n < 30; n++) {
      try { await page.goto('http://127.0.0.1:18980'); break; } catch { await page.waitForTimeout(1000); }
    }
    await page.waitForSelector('#ReducedDimensionPlot1 img', {timeout: 90000});
    await page.waitForTimeout(3000);
    const facts = await page.evaluate(() => ({title: document.title,
      panel: document.querySelector('#ReducedDimensionPlot1')?.innerText || '',
      type: document.querySelector('#ReducedDimensionPlot1_Type')?.value || null,
      x_axis: document.querySelector('#ReducedDimensionPlot1_XAxis')?.value || null,
      y_axis: document.querySelector('#ReducedDimensionPlot1_YAxis')?.value || null,
      color_by: document.querySelector('#ReducedDimensionPlot1_ColorByColumnData')?.value || null,
      plots: [...document.querySelectorAll('#ReducedDimensionPlot1 img')].map(i => ({loaded:i.complete, width:i.naturalWidth, height:i.naturalHeight}))}));
    assert(facts.plots.some(i => i.loaded && i.width > 100));
    assert.equal(facts.type, 'UMAP');
    assert.equal(facts.x_axis, '1');
    assert.equal(facts.y_axis, '2');
    assert.equal(errors.length, 0);
    await page.screenshot({path: 'research/results/related_tools/iSEE_PBMC3k.png', fullPage:true});
    fs.writeFileSync('research/results/related_tools/iSEE_browser.json', JSON.stringify({status:'pass', facts, errors}, null, 2));
  } finally { await browser.close(); }
})().catch(e => {console.error(e); process.exitCode = 1;});
