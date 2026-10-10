// Check self-contained report content at desktop and mobile widths.
const {chromium}=require('playwright');const fs=require('fs');const path=require('path');
(async()=>{
  const root=path.resolve(process.argv[2]);const out=path.join(root,'browser');
  if(fs.existsSync(out))throw new Error('Refusing overwrite browser evidence');fs.mkdirSync(out);
  const browser=await chromium.launch({executablePath:'/usr/bin/google-chrome',headless:true,args:['--no-sandbox']});
  const evidence=[];
  for(const width of [1440,390]){
    const page=await browser.newPage({viewport:{width,height:1000}});const errors=[];
    page.on('pageerror',e=>errors.push(String(e)));
    await page.goto('file://'+path.join(root,'BioExplainR-公开数据验证-结果增补-v1.html'));
    const result=await page.evaluate(()=>({width:innerWidth,scrollWidth:document.documentElement.scrollWidth,tables:document.querySelectorAll('table').length,
      images:[...document.querySelectorAll('img')].map(i=>({loaded:i.complete&&i.naturalWidth>0,source:i.src.startsWith('data:image/png;base64,')})),
      boundary:document.body.textContent.includes('0.7831')&&document.body.textContent.includes('未确认')}));
    if(result.scrollWidth>width||result.tables!==4||result.images.length!==3||result.images.some(i=>!i.loaded||!i.source)||errors.length||!result.boundary)throw new Error(JSON.stringify({result,errors}));
    await page.screenshot({path:path.join(out,'report-'+width+'.png'),fullPage:true});evidence.push({...result,errors});await page.close();
  }
  await browser.close();fs.writeFileSync(path.join(out,'audit.json'),JSON.stringify({status:'pass',utc:new Date().toISOString(),viewports:evidence},null,2),{flag:'wx'});
  console.log('Report desktop/mobile browser audit pass');
})().catch(e=>{console.error(e);process.exitCode=1;});
