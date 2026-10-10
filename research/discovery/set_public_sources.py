"""Bounded, preserved public protein-file inventory and GEO feasibility metadata."""
import concurrent.futures
import json
import subprocess
import sys
from pathlib import Path

from validation_sources import record,utc,json_out,csv_out

out=Path(sys.argv[1]).resolve()/"public_sources"
out.mkdir(exist_ok=False)
queries=[]
for accession in ["PXD033514","PXD033534","PXD033504"]:
    queries.append((accession+"_files.json","https://www.ebi.ac.uk/pride/ws/archive/v2/files/byProject?accession="+accession+"&pageSize=100&page=0"))
queries.append(("GSE42538_metadata.txt","https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE42538&targ=self&form=text&view=full"))
json_out(out/"source_freeze.json",dict(utc=utc(),script=record(Path(__file__)),queries=queries,
    objective="Find unselected per-sample human protein arrays and assess GR genetic x drug factor design; no candidate testing before metadata review"))
def get(item):
    name,url=item;path=out/name
    p=subprocess.run(["curl","--silent","--show-error","--location","--connect-timeout","10","--max-time","45",url],capture_output=True)
    path.write_bytes(p.stdout)
    return dict(url=url,utc=utc(),returncode=p.returncode,stderr=p.stderr.decode(errors="replace"),**record(path))
with concurrent.futures.ThreadPoolExecutor(max_workers=4) as executor:
    logs=list(executor.map(get,queries))
json_out(out/"acquisition.json",dict(utc=utc(),records=logs))
inventory=[]
for name,url in queries[:3]:
    path=out/name
    try:
        data=json.loads(path.read_text());print(name,"keys",list(data) if isinstance(data,dict) else "array",flush=True)
        json_out(out/(name.replace("_files.json","_inspection.json")),dict(status="parsed",structure="dict" if isinstance(data,dict) else "list",
            top_keys=list(data) if isinstance(data,dict) else [],source=record(path)))
    except Exception as exc:
        print(name,"parse failure",str(exc),flush=True)
print("Public source inventories acquired; metadata design remains to review",flush=True)
