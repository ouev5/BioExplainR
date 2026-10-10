// Save public attachments through the site's ordinary browser download flow.
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
(async () => {
  const out = path.resolve(process.argv[2], 'human_protein');
  const browser = await chromium.launch({executablePath:'/usr/bin/google-chrome',headless:true,args:['--no-sandbox']});
  const context = await browser.newContext({acceptDownloads:true});
  const logs=[];
  for(const [file,id,name] of [['browser_supplement.zip','9562650','cells-11-03164-s001.zip'],['browser_clock_supplement.docx','12476226','ANDR-13-1970-s001.docx']]){
    const target=path.join(out,file);
    if(fs.existsSync(target)) throw new Error('Refusing to overwrite '+file);
    const page=await context.newPage();
    const url=`https://pmc.ncbi.nlm.nih.gov/articles/instance/${id}/bin/${name}`;
    try{
      const event=page.waitForEvent('download',{timeout:90000});event.catch(()=>{});
      await page.goto(url,{timeout:45000,waitUntil:'domcontentloaded'}).catch(e=>{if(!String(e).includes('Download'))throw e;});
      const download=await event;
      await download.saveAs(target);
      logs.push({status:'downloaded',url,path:file,filename:download.suggestedFilename(),utc:new Date().toISOString()});
      console.log(file,'downloaded');
    }catch(e){logs.push({status:'failed',url,error:String(e),utc:new Date().toISOString()});console.log(file,String(e));}
    finally{await page.close();}
  }
  const logpath=path.join(out,'browser_acquisition.json');
  fs.writeFileSync(logpath,JSON.stringify(logs,null,2),{flag:'wx'});
  await browser.close();
})().catch(e=>{console.error(e);process.exitCode=1;});
