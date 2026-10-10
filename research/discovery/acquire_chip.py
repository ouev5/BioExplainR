"""Save primary ChIP source, every published uninfected peak, and download failures."""
import argparse
from datetime import datetime,timezone
import gzip
import hashlib
import json
from pathlib import Path
import re
import subprocess
from mechanism_design import metadata, ROOT, SOURCE


def fetch(url,p):
    command=['curl','-fLsS','--connect-timeout','15','--max-time','90','--retry','1','-o',str(p),url]
    z=subprocess.run(command,capture_output=True,text=True)
    if z.returncode: return dict(url=url,status='failed',exit_code=z.returncode,error=z.stderr)
    if p.name.endswith('.gz'):
        with gzip.open(p,'rb') as f:
            while f.read(1024*1024): pass
    return dict(url=url,status='downloaded',path=p.name,bytes=p.stat().st_size,sha256=hashlib.file_digest(p.open('rb'),'sha256').hexdigest(),utc=datetime.now(timezone.utc).isoformat())


def main():
    ap=argparse.ArgumentParser();ap.add_argument('output',type=Path); ap.add_argument('--resume',action='store_true'); a=ap.parse_args(); out=a.output; out.mkdir(exist_ok=a.resume)
    manifest=out/'acquisition.json'; records=json.loads(manifest.read_text()) if manifest.exists() else []
    def get(url,name):
        if any(r.get('path')==name and r['status']=='downloaded' for r in records): return
        records.append(fetch(url,out/name)); manifest.write_text(json.dumps(records,indent=2)+'\n')
    get('https://pmc.ncbi.nlm.nih.gov/articles/PMC5576583/','PMC5576583.html')
    get('https://pmc.ncbi.nlm.nih.gov/articles/PMC5576583/pdf/rcmb.2016-0357OC.pdf','PMC5576583.pdf')
    get('https://www.ebi.ac.uk/europepmc/webservices/rest/PMC5576583/fullTextXML','PMC5576583.xml')
    # GEO contains eight uninfected GR/RNAPII ChIP peak libraries, plus inputs/other data.
    rows=[]
    for s in metadata(SOURCE/'chip_metadata.txt'):
        for url in s['!Sample_supplementary_file_1']:
            if url=='NONE' or not url.endswith('.narrowPeak.gz'): continue
            url=url.replace('ftp://','https://'); name=url.rsplit('/',1)[1]
            rows.append(dict(gsm=s['gsm'],title=s['!Sample_title'][0],file=name))
            get(url,name)
    (out/'peak_samples.json').write_text(json.dumps(rows,indent=2)+'\n')
    html=(out/'PMC5576583.html').read_text() if (out/'PMC5576583.html').exists() else ''
    links=sorted(set(re.findall(r'href="([^"]*(?:supp|bin/)[^"]*)"',html)))
    (out/'supplement_links.json').write_text(json.dumps(links,indent=2)+'\n')
    print(json.dumps(dict(peak_samples=rows,supplement_links=links,acquisition=records),indent=2))


if __name__=='__main__': main()
