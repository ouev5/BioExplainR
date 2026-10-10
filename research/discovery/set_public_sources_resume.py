"""Save corrected PRIDE API inventory and sample-level GSE42538 metadata."""
import concurrent.futures
import json
import subprocess
import sys
from pathlib import Path
from validation_sources import record,utc,json_out,csv_out

out=Path(sys.argv[1]).resolve()/"public_sources"
queries=[(a+"_file_inventory.json","https://www.ebi.ac.uk/pride/ws/archive/v2/projects/"+a+"/files?pageSize=100&page=0")
         for a in ["PXD033514","PXD033534","PXD033504"]]
queries += [("GSE42538_full_metadata.txt","https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE42538&targ=all&form=text&view=full")]
json_out(out/"source_resume_amendment.json",dict(utc=utc(),script=record(Path(__file__)),queries=queries,
    reason="Initial incorrect PRIDE file endpoint returned empty bodies; use projects/accession/files and retain failed inputs"))
def get(item):
    name,url=item;path=out/name
    p=subprocess.run(["curl","--silent","--show-error","--location","--connect-timeout","10","--max-time","45",url],capture_output=True)
    path.write_bytes(p.stdout)
    return dict(url=url,utc=utc(),returncode=p.returncode,stderr=p.stderr.decode(errors="replace"),**record(path))
with concurrent.futures.ThreadPoolExecutor(max_workers=4) as executor:logs=list(executor.map(get,queries))
json_out(out/"acquisition_corrected.json",dict(utc=utc(),records=logs))
inventory=[]
for name,url in queries[:3]:
    data=json.loads((out/name).read_text());assert isinstance(data,list) and len(data)<100,"Pagination needed"
    assert len({r["fileName"] for r in data})==len(data)
    for r in data:
        inventory.append(dict(project=name.split("_")[0],fileName=r["fileName"],bytes=r["fileSizeBytes"],
            category=r["fileCategory"]["value"],checksum=r["checksum"],
            ftp_url=next(a["value"] for a in r["publicFileLocations"] if a["value"].startswith("ftp:"))))
csv_out(out/"protein_file_inventory.csv",inventory)
json_out(out/"protein_file_inventory_summary.json",dict(status="complete_first_page_lt100",projects={a:sum(r["project"]==a for r in inventory) for a in ["PXD033514","PXD033534","PXD033504"]},
    search_outputs=[r for r in inventory if r["category"]!="RAW"]))
print(json.dumps([r for r in inventory if r["category"]!="RAW"],indent=2))
