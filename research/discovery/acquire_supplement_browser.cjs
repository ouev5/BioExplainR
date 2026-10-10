// Read the public PMC download using the site's normal browser download flow.
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
(async () => {
  const out = path.resolve('research/results/discovery_donors_v1');
  const browser = await chromium.launch({ executablePath: '/usr/bin/google-chrome', headless: true, args: ['--no-sandbox'] });
  const context = await browser.newContext({ acceptDownloads: true });
  const page = await context.newPage();
  const url = 'https://pmc.ncbi.nlm.nih.gov/articles/instance/6604213/bin/rcmb.2018-0385OC_kan_data_supplement.pdf';
  try {
    const event = page.waitForEvent('download', { timeout: 120000 });
    event.catch(() => {});
    await page.goto(url, { timeout: 60000, waitUntil: 'domcontentloaded' }).catch(e => {
      console.log(String(e)); if (!String(e).includes('Download')) throw e;
    });
    console.log((await page.title()), (await page.locator('body').innerText()).slice(0, 500));
    const download = await event;
    await download.saveAs(path.join(out, 'original_supplement_verified.pdf'));
    fs.writeFileSync(path.join(out, 'supplement_browser.json'), JSON.stringify({ status: 'downloaded', url, filename: download.suggestedFilename(), utc: new Date().toISOString() }, null, 2));
    console.log('Public supplement downloaded');
  } finally { await browser.close(); }
})().catch(e => { console.error(e); process.exitCode = 1; });
