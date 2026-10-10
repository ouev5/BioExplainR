"""Resume interrupted HGNC acquisition with exact-ID REST records."""
import concurrent.futures
import json
import subprocess
import sys
from pathlib import Path

from set_validation import rows
from validation_sources import ROOT, record, utc, csv_out, json_out

out=Path(sys.argv[1]).resolve()
freeze=json.loads((out/"analysis_freeze.json").read_text())
for rec in freeze["inputs"]+freeze["scripts"]+[freeze["set"],freeze["samples"]]:
    assert record(ROOT/rec["path"])==rec,rec["path"]
resume=len(sys.argv)>2 and sys.argv[2]=="--resume"
json_out(out/("annotation_retry_amendment.json" if resume else "annotation_resume_amendment.json"),dict(utc=utc(),script=record(Path(__file__)),
    reason="Original Google HGNC full-table transfer exceeded 360s and left no file; repeated freeze correctly refused existing directory. Use official exact-Ensembl HGNC REST records, preserving all mapping rules, original freeze, set and samples.",
    network_budget="curl connect10/max30 seconds per exact ID, four concurrent requests; failed response and return code saved",
    timing="No new candidate TPM/count extraction yet"))
def acquire(g):
    fid=g["feature_id"];url="https://rest.genenames.org/fetch/ensembl_gene_id/"+fid
    path=out/"sources"/(fid+".json")
    if resume and path.exists() and path.stat().st_size:
        data=json.loads(path.read_text())["response"]
        docs=[r for r in data["docs"] if r.get("ensembl_gene_id")==fid and r.get("status")=="Approved"]
        ids=sorted({str(r["entrez_id"]) for r in docs if r.get("entrez_id")})
        log=dict(url=url,status="retrieved",reused_saved_response=True,**record(path))
        return log,dict(set_rank=g["set_rank"],feature_id=fid,symbol="|".join(sorted({r["symbol"] for r in docs})),
            entrez_id=ids[0] if len(ids)==1 else "",discovery_direction=g["direction"],
            status="mapped" if len(ids)==1 else "missing_or_ambiguous",hgnc_ids="|".join(r["hgnc_id"] for r in docs))
    if resume:
        path=out/"sources"/(fid+"_retry.json")
    command=["curl","--silent","--show-error","--location","--connect-timeout","10","--max-time","30","-H","Accept: application/json",url]
    p=subprocess.run(command,capture_output=True)
    path.write_bytes(p.stdout)
    log=dict(url=url,utc=utc(),returncode=p.returncode,stderr=p.stderr.decode(errors="replace"),**record(path))
    try:
        data=json.loads(p.stdout)["response"];assert data["numFound"]==len(data["docs"])
        docs=[r for r in data["docs"] if r.get("ensembl_gene_id")==fid and r.get("status")=="Approved"]
        ids=sorted({str(r["entrez_id"]) for r in docs if r.get("entrez_id")})
        log["status"]="retrieved" if p.returncode==0 else "failed"
    except Exception as exc:
        docs=[];ids=[];log.update(status="failed",parse_error=str(exc))
    mapping=dict(set_rank=g["set_rank"],feature_id=fid,symbol="|".join(sorted({r["symbol"] for r in docs})),
        entrez_id=ids[0] if len(ids)==1 else "",discovery_direction=g["direction"],
        status="mapped" if len(ids)==1 else "missing_or_ambiguous",hgnc_ids="|".join(r["hgnc_id"] for r in docs))
    return log,mapping
with concurrent.futures.ThreadPoolExecutor(max_workers=4) as executor:
    results=list(executor.map(acquire,rows(out/"frozen_set.csv")))
logs=[r[0] for r in results];mapping=[r[1] for r in results]
json_out(out/("annotation_acquisition_retry.json" if resume else "annotation_acquisition_rest.json"),dict(utc=utc(),records=logs))
assert all(r["status"]=="retrieved" for r in logs),"Failed HGNC requests; inspect acquisition log before annotation freeze"
for r in mapping:
    if r["entrez_id"] and sum(s["entrez_id"]==r["entrez_id"] for s in mapping)>1:
        r["status"]="shared_entrez_ambiguous"
csv_out(out/"annotation.csv",mapping)
json_out(out/"annotation_freeze.json",dict(utc=utc(),annotation=record(out/"annotation.csv"),
    records=[{k:r[k] for k in ["path","bytes","sha256"]} for r in logs],
    rule="Unique approved official HGNC exact Ensembl-to-Entrez; ambiguous and missing retain family slot"))
print(json.dumps({"mapped":sum(r["status"]=="mapped" for r in mapping),"frozen":len(mapping)},indent=2))
