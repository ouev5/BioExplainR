"""Save alternate transfer probes and sample metadata for feasibility decisions."""
import concurrent.futures
import json
import subprocess
import sys
from pathlib import Path
from validation_sources import record,utc,json_out,csv_out

out=Path(sys.argv[1]).resolve()/"public_sources";dest=out/"probes";dest.mkdir(exist_ok=False)
queries=[]
for label,host in [("ebi","https://ftp.ebi.ac.uk/pride-archive"),("pride","https://ftp.pride.ebi.ac.uk/pride/data/archive")]:
    queries.append((label+"_range.bin",host+"/2023/03/PXD033514/HTPCsProteome_24h_1uMdex.7z","1712825077-1713873652"))
for n in range(1044671,1044683):
    acc="GSM"+str(n);queries.append((acc+".txt","https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc="+acc+"&targ=self&form=text&view=full",None))
json_out(dest/"freeze.json",dict(utc=utc(),queries=queries,script=record(Path(__file__)),
    reason="8MiB protein ranges repeatedly timed out; test alternate EBIhost and1MiBbudget; GEOall response truncated in platform before samples, request each actualGSM"))
def get(item):
    name,url,span=item;path=dest/name;header=dest/(name+".headers.txt")
    cmd=["curl","--silent","--show-error","--location","--connect-timeout","10","--max-time","40","--dump-header",str(header)]
    if span:cmd += ["--range",span]
    p=subprocess.run(cmd+[url],capture_output=True);path.write_bytes(p.stdout)
    return dict(utc=utc(),url=url,range=span,returncode=p.returncode,stderr=p.stderr.decode(errors="replace"),body=record(path),headers=record(header))
with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:logs=list(pool.map(get,queries))
json_out(dest/"acquisition.json",dict(utc=utc(),records=logs))
samples=[]
for n in range(1044671,1044683):
    acc="GSM"+str(n);text=(dest/(acc+".txt")).read_text()
    for line in text.splitlines():
        if line.startswith(("!Sample_title","!Sample_characteristics_ch1","!Sample_treatment_protocol")):
            key,value=line.split(" = ",1);samples.append(dict(sample=acc,field=key,value=value))
csv_out(dest/"GSE42538_sample_design.csv",samples)
print(json.dumps([dict(path=r["body"]["path"],bytes=r["body"]["bytes"],returncode=r["returncode"]) for r in logs],indent=2))
