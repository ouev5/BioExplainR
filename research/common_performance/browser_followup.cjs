// Actual desktop/mobile report DOM verification; tables may scroll within containers.
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
const { pathToFileURL } = require('url');
(async () => {
  const directory = path.resolve('docs/research_followup_v1');
  const html = fs.readdirSync(directory).find(x => x.endsWith('.html'));
  const browser = await chromium.launch({ executablePath: process.env.BIOEXPLAINR_CHROME || '/usr/bin/google-chrome', headless: true,
    args: ['--no-sandbox','--disable-dev-shm-usage'] });
  const results=[];
  try {
    for (const width of [1440,390]) {
      const page=await browser.newPage({viewport:{width,height:1000}});const errors=[];
      page.on('pageerror', e=>errors.push(String(e)));
      await page.goto(pathToFileURL(path.join(directory,html)).href);
      const result=await page.evaluate(()=>({tables:document.querySelectorAll('table').length,
        overflow:document.documentElement.scrollWidth>window.innerWidth+1,
        required:['SPARCL1','GSE229084','GSE95632','hg19','不可估计','180秒'].every(x=>document.body.innerText.includes(x))}));
      result.width=width;result.errors=errors;
      if(result.tables!==4||result.overflow||!result.required||errors.length) throw Error(JSON.stringify(result));
      results.push(result);await page.close();
    }
    fs.writeFileSync(path.join(directory,'browser_audit.json'),JSON.stringify({status:'pass',results},null,2)+'\n');
    console.log(JSON.stringify(results,null,2));
  } finally {await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
