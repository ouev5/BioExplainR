// Run with NODE_PATH pointing to an installation of playwright and pngjs.
const fs = require('node:fs');
const assert = require('node:assert/strict');
const { chromium } = require('playwright');
const { PNG } = require('pngjs');
const root = process.cwd();
const output = `${root}/research/results/browser`;
fs.mkdirSync(output, { recursive: true });
const url = process.env.BIOEXPLAINR_URL || 'http://127.0.0.1:3876';
async function select(page, id, value) {
  await page.evaluate(({ id, value }) => {
    const element = document.getElementById(id);
    if (element.selectize) element.selectize.setValue(value);
    else { element.value = value; element.dispatchEvent(new Event('change', { bubbles: true })); }
  }, { id, value });
}
async function tab(page, name) { await page.getByRole('tab', { name, exact: true }).click(); }
async function waitText(page, id, text) {
  await page.waitForFunction(({ id, text }) => document.getElementById(id)?.textContent.includes(text), { id, text }, { timeout: 120000 });
}
async function screenshot(page, name) {
  const buffer = await page.screenshot({ path: `${output}/${name}.png`, fullPage: true });
  const png = PNG.sync.read(buffer);
  let nonwhite = 0;
  const colours = new Set();
  for (let i = 0; i < png.data.length; i += 40) {
    const rgb = png.data.slice(i, i + 3);
    if (rgb.some(v => v < 240)) nonwhite++;
    colours.add(rgb.join(','));
  }
  assert(nonwhite > 1000 && colours.size > 40, `${name}: blank screenshot`);
  return { name, width: png.width, height: png.height, nonwhite, colours: colours.size };
}
(async () => {
  const browser = await chromium.launch({ executablePath: '/usr/bin/google-chrome', headless: true, args: ['--no-sandbox'] });
  const context = await browser.newContext({ viewport: { width: 1440, height: 1000 }, acceptDownloads: true });
  const page = await context.newPage();
  const errors = []; const failedAssets = []; const steps = []; const screenshots = [];
  page.on('pageerror', e => errors.push(e.message));
  page.on('response', r => { if (r.status() >= 400) failedAssets.push({ status: r.status(), url: r.url() }); });
  try {
    for (let i = 0; i < 30; i++) {
      try { const r = await fetch(url); if (r.ok) break; } catch {}
      await new Promise(resolve => setTimeout(resolve, 1000));
    }
    await page.goto(url);
    await page.waitForFunction(() => window.Shiny?.shinyapp?.$socket?.readyState === 1);
    await waitText(page, 'config_status', 'bio_config');
    screenshots.push(await screenshot(page, 'desktop-settings')); steps.push('settings-loaded');
    await tab(page, '代码执行');
    await page.locator('#code').fill('browser_result <- data.frame(log2FoldChange=c(2,-2,0), padj=c(.001,.01,.5))\nbrowser_result');
    await page.locator('#run_code').click(); await waitText(page, 'run_status', 'ok'); steps.push('recorded-code-execution');
    await tab(page, '结果自然语言分析');
    await select(page, 'analysis_object', 'airway_result');
    await page.locator('#lfc').fill('1');
    await page.locator('#analyze_object').click(); await waitText(page, 'analysis_status', 'differential_expression');
    await waitText(page, 'analysis_sections', '999'); steps.push('real-DESeq2-explanation');
    const downloadPromise = page.waitForEvent('download');
    await page.locator('#download_report').click();
    const download = await downloadPromise;
    await download.saveAs(`${output}/downloaded_report.html`);
    assert(fs.readFileSync(`${output}/downloaded_report.html`, 'utf8').includes('999')); steps.push('HTML-report-download');
    await tab(page, '常用图形');
    await select(page, 'plot_object', 'airway_expression'); await select(page, 'plot_type', 'pca');
    await select(page, 'plot_metadata', 'airway_metadata'); await page.locator('#plot_group').fill('dex');
    await page.locator('#plot_top_n').fill('500'); await page.locator('#make_plot').click();
    await waitText(page, 'plot_status', 'bio_generated_plot');
    await page.waitForFunction(() => { const i = document.querySelector('#bio_plot img'); return i?.complete && i.naturalWidth > 0; });
    const plotBuffer = await page.locator('#bio_plot').screenshot({ path: `${output}/pca-rendered.png` });
    const plotPNG = PNG.sync.read(plotBuffer); let coloured = 0;
    for (let i = 0; i < plotPNG.data.length; i += 4) {
      if (Math.max(...plotPNG.data.slice(i, i + 3)) - Math.min(...plotPNG.data.slice(i, i + 3)) > 30) coloured++;
    }
    assert(coloured > 100, 'PCA image has no coloured points'); steps.push('PCA-plot-render-and-workspace-save');
    screenshots.push(await screenshot(page, 'desktop-plot'));
    await tab(page, '结果自然语言分析');
    await select(page, 'analysis_object', 'bio_generated_plot'); await select(page, 'source_object', 'airway_expression');
    await page.locator('#analyze_object').click(); await waitText(page, 'analysis_status', 'plot: pass'); steps.push('PCA-source-cross-check');
    screenshots.push(await screenshot(page, 'desktop-analysis'));
    if (process.env.BIOEXPLAINR_LIVE_MODEL === '1') {
      await select(page, 'analysis_object', 'airway_result'); await select(page, 'source_object', '');
      await page.locator('#use_llm').check();
      await page.locator('#analyze_object').click(); await waitText(page, 'analysis_status', 'claims:');
      await waitText(page, 'analysis_sections', 'evidence_used'); steps.push('DeepSeek-browser-explanation');
      const liveReportPromise = page.waitForEvent('download');
      await page.locator('#download_report').click();
      const liveReport = await liveReportPromise;
      await liveReport.saveAs(`${output}/deepseek_downloaded_report.html`);
      const reportText = fs.readFileSync(`${output}/deepseek_downloaded_report.html`, 'utf8');
      assert(reportText.includes('deepseek-flash'));
      assert(reportText.includes('<td>preset</td><td>deepseek</td>'));
      fs.writeFileSync(`${output}/live_model_status.txt`, await page.locator('#analysis_status').innerText());
      await page.locator('#use_llm').uncheck();
    }
    for (const object of ['pbmc_sce', 'pbmc_seurat']) {
      await select(page, 'analysis_object', object); await select(page, 'source_object', '');
      await page.locator('#analyze_object').click(); await waitText(page, 'analysis_status', object);
      await waitText(page, 'analysis_sections', '2700'); steps.push(`${object}-explanation`);
    }
    const other = await context.newPage(); await other.goto(url);
    await other.waitForFunction(() => window.Shiny?.shinyapp?.$socket?.readyState === 1);
    await other.waitForFunction(() => document.getElementById('analysis_object')?.options.length > 0);
    assert(!await other.evaluate(() => Array.from(document.getElementById('analysis_object').options).some(o => o.value === 'browser_result')));
    steps.push('two-browser-session-isolation'); await other.close();
    await page.setViewportSize({ width: 390, height: 844 });
    await tab(page, '代码执行'); screenshots.push(await screenshot(page, 'mobile-code'));
    const overflow = await page.evaluate(() => ({ width: innerWidth, scroll: document.documentElement.scrollWidth }));
    assert(overflow.scroll <= overflow.width + 2, JSON.stringify(overflow)); steps.push('mobile-no-horizontal-overflow');
    assert.equal(errors.length, 0, JSON.stringify(errors));
    assert.equal(failedAssets.length, 0, JSON.stringify(failedAssets));
    fs.writeFileSync(`${output}/summary.json`, JSON.stringify({ url, steps, screenshots, plotColouredPixels: coloured, errors, failedAssets, status: 'pass' }, null, 2));
    for (const name of ['failure.json', 'failure.png']) {
      fs.rmSync(`${output}/${name}`, { force: true });
    }
    console.log(JSON.stringify({ status: 'pass', steps, screenshots }, null, 2));
  } catch (error) {
    fs.writeFileSync(`${output}/failure.json`, JSON.stringify({ error: error.message, steps, errors, failedAssets }, null, 2));
    await page.screenshot({ path: `${output}/failure.png`, fullPage: true });
    throw error;
  } finally { await browser.close(); }
})().catch(e => { console.error(e); process.exitCode = 1; });
