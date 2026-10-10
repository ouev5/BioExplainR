const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { chromium } = require('playwright');
(async () => {
  const output = 'research/results/w00_baseline/paper-cn-live-browser';
  fs.mkdirSync(output);
  const browser = await chromium.launch({ executablePath: '/usr/bin/google-chrome', headless: true, args: ['--no-sandbox'] });
  const page = await browser.newPage({ acceptDownloads: true });
  const errors = [];
  page.on('pageerror', e => errors.push(e.message));
  const select = async (id, value) => page.evaluate(({ id, value }) => document.getElementById(id).selectize.setValue(value), { id, value });
  const tab = async name => page.locator(`a[data-value="${name}"]`).click();
  try {
    await page.goto('http://127.0.0.1:3888');
    await page.waitForFunction(() => window.Shiny?.shinyapp?.$socket?.readyState === 1);
    await tab('code');
    await page.locator('#code').fill('paper_miniacc <- readRDS("research/results/miniacc_installed_review/project.rds")\npaper_pca_input <- matrix(seq_len(24), 6)');
    await page.locator('#run_code').click();
    await page.waitForFunction(() => document.getElementById('run_status')?.textContent.includes('ok'));
    await tab('analysis');
    await select('analysis_object', 'paper_miniacc');
    await page.locator('#analyze_object').click();
    await page.waitForFunction(() => document.getElementById('project_coverage_counts')?.textContent.includes('43'));
    await tab('plots');
    await select('plot_object', 'paper_pca_input');
    await select('plot_type', 'pca');
    await page.locator('#make_plot').click();
    await page.waitForFunction(() => document.getElementById('download_plot')?.getAttribute('href')?.includes('/download/'));
    const download = page.waitForEvent('download');
    await page.locator('#download_plot').click();
    await (await download).saveAs(path.join(output, 'live-generated-pca.pdf'));
    assert(fs.readFileSync(path.join(output, 'live-generated-pca.pdf')).subarray(0, 5).toString() === '%PDF-');
    assert.equal(errors.length, 0);
    const summary = { status: 'pass', url: 'http://127.0.0.1:3888', checks: ['current-source-miniacc-project', 'current-source-PDF-download'], errors };
    fs.writeFileSync(path.join(output, 'summary.json'), JSON.stringify(summary, null, 2));
    console.log(JSON.stringify(summary, null, 2));
  } finally { await browser.close(); }
})().catch(e => { console.error(e); process.exitCode = 1; });
