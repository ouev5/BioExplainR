const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { chromium } = require('playwright');
const { PNG } = require('pngjs');
const output = process.env.BIOEXPLAINR_ACCEPTANCE_OUTPUT;
const url = process.env.BIOEXPLAINR_URL;
async function select(page, id, value) {
  await page.evaluate(({ id, value }) => document.getElementById(id).selectize.setValue(value), { id, value });
}
async function waitText(page, id, text) {
  await page.waitForFunction(({ id, text }) => document.getElementById(id)?.textContent.includes(text), { id, text });
}
async function tab(page, value) {
  await page.locator(`a[data-value="${value}"]`).click();
}
(async () => {
  const browser = await chromium.launch({ executablePath: '/usr/bin/google-chrome', headless: true, args: ['--no-sandbox'] });
  const context = await browser.newContext({ viewport: { width: 1440, height: 1000 }, acceptDownloads: true });
  const page = await context.newPage();
  const errors = [];
  page.on('pageerror', error => errors.push(error.message));
  const checks = [];
  const viewports = [];
  try {
    await page.goto(url);
    await page.waitForFunction(() => window.Shiny?.shinyapp?.$socket?.readyState === 1);
    await waitText(page, 'config_status', 'bio_config');
    await tab(page, 'analysis');
    await select(page, 'analysis_object', 'checked_en');
    await page.locator('#analyze_object').click();
    await waitText(page, 'analysis_status', 'claims: partial');
    await waitText(page, 'typed_claims', 'fixture_count');
    await waitText(page, 'evidence_relations', 'no claim-level relation');
    await page.locator('#payload_preview summary').click();
    const payload = await page.locator('#payload_preview pre').innerText();
    assert.equal(JSON.parse(payload).facts.n_features, 3);
    await page.locator('#runtime_manifest summary').click();
    assert.equal(await page.evaluate(() => window.untrustedEvidence), undefined);
    checks.push('typed-evidence-payload-manifest-and-escaping');
    const downloaded = page.waitForEvent('download');
    await page.locator('#download_report').click();
    await (await downloaded).saveAs(path.join(output, 'report-en.html'));
    const report = fs.readFileSync(path.join(output, 'report-en.html'), 'utf8');
    assert(report.includes('fixture_count') && report.includes('&lt;script&gt;'));
    checks.push('downloaded-report-content');
    for (const viewport of [{ width: 1440, height: 1000 }, { width: 390, height: 844 }]) {
      await page.setViewportSize(viewport);
      const bounds = await page.evaluate(() => ({ width: innerWidth, scroll: document.documentElement.scrollWidth }));
      assert(bounds.scroll <= bounds.width + 2, JSON.stringify(bounds));
      const image = await page.screenshot({ path: path.join(output, `shiny-${viewport.width}.png`), fullPage: true });
      const png = PNG.sync.read(image);
      let visible = 0;
      for (let i = 0; i < png.data.length; i += 40) if (png.data[i] < 235) visible++;
      assert(visible > 1000);
      viewports.push({ viewport, bounds, visiblePixels: visible });
    }
    await tab(page, 'model');
    await select(page, 'language', 'zh');
    await waitText(page, 'txt_tab_analysis', '结果自然语言分析');
    await tab(page, 'analysis');
    await select(page, 'analysis_object', 'checked_zh');
    await page.locator('#analyze_object').click();
    await waitText(page, 'typed_claims', 'fixture_count');
    await waitText(page, 'analysis_sections', '类型化声明');
    const zhDownload = page.waitForEvent('download');
    await page.locator('#download_report').click();
    await (await zhDownload).saveAs(path.join(output, 'report-zh.html'));
    assert(fs.readFileSync(path.join(output, 'report-zh.html'), 'utf8').includes('lang="zh-CN"'));
    checks.push('Chinese-labels-and-download');
    await select(page, 'analysis_object', 'fixture_mae');
    await page.locator('#analyze_object').click();
    await waitText(page, 'sample_alignment', 'required_columns');
    assert(!(await page.locator('#sample_alignment').innerText()).includes('PRIVATE_SAMPLE'));
    checks.push('MAE-alignment-findings');
    await select(page, 'analysis_object', 'miniacc_project');
    await page.locator('#analyze_object').click();
    await waitText(page, 'analysis_status', 'project');
    await waitText(page, 'project_coverage_counts', '43');
    await waitText(page, 'project_relations', 'direction');
    assert(!(await page.locator('#analysis_sections').innerText()).includes('TCGA-'));
    const projectDownload = page.waitForEvent('download');
    await page.locator('#download_report').click();
    await (await projectDownload).saveAs(path.join(output, 'miniacc-project-zh.html'));
    const projectReport = fs.readFileSync(path.join(output, 'miniacc-project-zh.html'), 'utf8');
    assert(projectReport.includes('n_complete_units') && projectReport.includes('direction') && !/TCGA-[A-Z0-9]{2}-[A-Z0-9]{4}/.test(projectReport));
    await page.setViewportSize({ width: 1440, height: 1000 });
    await page.screenshot({ path: path.join(output, 'miniacc-project-desktop.png'), fullPage: true });
    await page.setViewportSize({ width: 390, height: 844 });
    assert(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth + 2));
    await page.screenshot({ path: path.join(output, 'miniacc-project-mobile.png'), fullPage: true });
    checks.push('real-miniacc-project-coverage-relations-report-mobile');
    await tab(page, 'plots');
    await select(page, 'plot_object', 'fixture_expression');
    await select(page, 'plot_type', 'pca');
    await page.locator('#make_plot').click();
    await waitText(page, 'plot_status', 'bio_generated_plot');
    await page.waitForFunction(() => document.getElementById('download_plot')?.getAttribute('href')?.includes('/download/'));
    const plotDownload = page.waitForEvent('download');
    await page.locator('#download_plot').click();
    await (await plotDownload).saveAs(path.join(output, 'generated-pca.pdf'));
    assert(fs.readFileSync(path.join(output, 'generated-pca.pdf')).subarray(0, 5).toString() === '%PDF-');
    await page.screenshot({ path: path.join(output, 'plot-pdf-download.png'), fullPage: true });
    checks.push('generated-plot-vector-PDF-download');
    await tab(page, 'code');
    await page.locator('#code').fill('only_this_browser <- 42');
    await page.locator('#run_code').click();
    await waitText(page, 'run_status', 'ok');
    const other = await context.newPage();
    await other.goto(url);
    await other.waitForFunction(() => document.getElementById('analysis_object')?.options.length > 0);
    assert(!await other.evaluate(() => Array.from(document.getElementById('analysis_object').options).some(x => x.value === 'only_this_browser')));
    await other.close();
    checks.push('two-session-workspace-isolation');
    assert.equal(errors.length, 0, JSON.stringify(errors));
    fs.writeFileSync(path.join(output, 'summary.json'), JSON.stringify({ status: 'pass', checks, viewports, errors }, null, 2));
    console.log(JSON.stringify({ status: 'pass', checks, viewports }, null, 2));
  } catch (error) {
    fs.writeFileSync(path.join(output, 'failure.json'), JSON.stringify({ error: error.message, checks, errors }, null, 2));
    await page.screenshot({ path: path.join(output, 'failure.png'), fullPage: true });
    throw error;
  } finally {
    await browser.close();
  }
})().catch(error => { console.error(error); process.exitCode = 1; });
