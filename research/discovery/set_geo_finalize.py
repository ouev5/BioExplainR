"""Finish metadata eligibility check without conducting an inapplicable GR x drug test."""
import concurrent.futures
import json
import subprocess
import sys
from pathlib import Path
from validation_sources import record,utc,csv_out,json_out

out=Path(sys.argv[1]).resolve();dest=out/"public_sources/probes"
logs=[]
for acc in ["GSM1044672","GSM1044673","GSM1044676"]:
    path=dest/(acc+"_retry.txt");url="https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc="+acc+"&targ=self&form=text&view=full"
    p=subprocess.run(["curl","--silent","--show-error","--location","--retry","2","--connect-timeout","10","--max-time","30",url],capture_output=True)
    path.write_bytes(p.stdout);logs.append(dict(url=url,utc=utc(),returncode=p.returncode,stderr=p.stderr.decode(errors="replace"),**record(path)))
json_out(dest/"metadata_retry.json",dict(utc=utc(),script=record(Path(__file__)),records=logs))
samples=[]
for n in range(1044671,1044683):
    acc="GSM"+str(n);path=dest/(acc+"_retry.txt") if (dest/(acc+"_retry.txt")).exists() else dest/(acc+".txt")
    text=path.read_text();assert text.startswith("^SAMPLE = "+acc),acc
    fields={}
    for line in text.splitlines():
        if " = " in line and line.startswith("!Sample_"):
            k,v=line.split(" = ",1);fields.setdefault(k,[]).append(v)
    treatment=fields["!Sample_treatment_protocol_ch1"][0]
    assert all(word in treatment for word in ["8-bromo-cAMP","progesterone","cortisone","four days"])
    characteristics=fields["!Sample_characteristics_ch1"]
    samples.append(dict(sample=acc,title=fields["!Sample_title"][0],
        patient=next(v for v in characteristics if v.startswith("patient #:")),
        age=next(v for v in characteristics if v.startswith("age:")),
        treatment=next(v for v in characteristics if v.startswith("treatment:")),
        common_cocktail=treatment,source=record(path)["path"]))
assert len(samples)==12 and len({s["patient"] for s in samples})==4
csv_out(out/"public_sources/GSE42538_design_complete.csv",samples)
json_out(out/"public_sources/GSE42538_eligibility.json",dict(status="excluded_for_target_interaction",utc=utc(),samples=12,donors=4,
    tissue="human endometrial stromal cells",design="4donors x NT/GR/MRsiRNA, all decidualized4days with cAMP/progesterone/cortisone",
    reason="No matched no-cocktail/no-GC arms; cannot estimate NR3C1 x GC direct interaction; not adult ASM",
    candidate_statistics_performed=False,metadata_complete=True))
print("GSE42538 all12samples checked; no full drug-factor control, excluded from target interaction")
