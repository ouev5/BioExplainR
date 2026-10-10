// Desktop/mobile checks for the self-contained result report.
const {chromium}=require('playwright');const fs=require('fs');const path=require('path');
(async()=>{
  const root=path.resolve(process.argv[2]);const out=path.join(root,'browser');
  if(fs.existsSync(out))throw new Error('Refusing overwrite');fs.mkdirSync(out);
  const browser=await chromium.launch({executablePath:'/usr/bin/google-chrome',headless:true,args:['--no-sandbox']});
  const checks=[];
  for(const width of [1440,390]){
    const page=await browser.newPage({viewport:{width,height:1000}});const errors=[];
    page.on('pageerror',e=>errors.push(String(e)));
    await page.goto('file://'+path.join(root,'PXD033504-完整分泌蛋白组-结果报告.html'));
    const r=await page.evaluate(()=>({width:innerWidth,scrollWidth:document.documentElement.scrollWidth,
      tables:document.querySelectorAll('table').length,
      images:[...document.querySelectorAll('img')].map(i=>({loaded:i.complete&&i.naturalWidth>0,selfContained:i.src.startsWith('data:image/png;base64,')})),
      facts:['ANGPTL2','FSTL3','Holm112','缺测','分泌速率','112'].every(s=>document.body.textContent.includes(s))}));
    if(r.scrollWidth>width||r.tables!==3||r.images.length!==2||r.images.some(i=>!i.loaded||!i.selfContained)||!r.facts||errors.length)throw new Error(JSON.stringify({r,errors}));
    await page.screenshot({path:path.join(out,'report-'+width+'.png'),fullPage:true});checks.push({...r,errors});await page.close();
  }
  await browser.close();fs.writeFileSync(path.join(out,'audit.json'),JSON.stringify({status:'pass',utc:new Date().toISOString(),viewports:checks},null,2),{flag:'wx'});
  console.log('Secretome desktop/mobile audit pass');
})().catch(e=>{console.error(e);process.exitCode=1;});
