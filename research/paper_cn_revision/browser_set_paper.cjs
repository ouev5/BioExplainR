const {chromium}=require('playwright');
const fs=require('fs');
const path=require('path');
const paper=path.resolve(process.argv[2]);
const output=path.resolve(process.argv[3]||path.join(paper,'browser'));
(async()=>{
  fs.mkdirSync(output);
  const browser=await chromium.launch({executablePath:'/usr/bin/google-chrome',headless:true,args:['--no-sandbox']});
  const results=[];
  try {
    for(const [name,images,tables] of [['BioExplainR-中文论文-v0.12',3,3],['BioExplainR-补充材料-v0.12',4,5]]) {
      for(const width of [1440,390]) {
        const page=await browser.newPage({viewport:{width,height:980}});const errors=[];
        page.on('pageerror',e=>errors.push(String(e)));
        await page.goto('file://'+path.join(paper,name+'.html'));
        const state=await page.evaluate(()=>({images:[...document.images].map(i=>i.complete&&i.naturalWidth>0),
          tables:document.querySelectorAll('table').length,overflow:document.documentElement.scrollWidth>innerWidth+1,
          externalResources:[...document.images].some(i=>!i.src.startsWith('data:')),
          required:['PER2','54','结果后探索','GNAS'].every(s=>document.body.textContent.includes(s))}));
        if(state.images.length!==images||state.images.some(s=>!s)||state.tables!==tables||state.overflow||state.externalResources||!state.required||errors.length)throw Error(JSON.stringify({name,width,state,errors}));
        await page.screenshot({path:path.join(output,(tables===3?'main':'supplement')+'-'+width+'.png'),fullPage:true});
        results.push({name,width,...state,errors});await page.close();
      }
    }
  } finally {await browser.close();}
  const result={status:'pass',results,scope:'Actual1440/390DOM,image loading,JS andgeometry; no humanreview'};
  fs.writeFileSync(path.join(output,'audit.json'),JSON.stringify(result,null,2)+'\n');console.log(JSON.stringify(result,null,2));
})().catch(e=>{console.error(e);process.exitCode=1;});
