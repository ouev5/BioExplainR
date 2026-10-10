"""Unpaired early ASM contrasts from original RPKM, without inferred donor pairing."""
import csv
import gzip
import json
import sys
from pathlib import Path
import numpy as np
from scipy import stats
from validation_sources import csv_out,json_out,record,utc
from validation_expression import holm

out=Path(sys.argv[1]).resolve();dest=out/"asm_early"
with (out/"gr_public/gene_mapping.csv").open(newline="") as stream:mapping=list(csv.DictReader(stream))
json_out(dest/"id_mapping_amendment.json",{"utc":utc(),"mapping":record(out/"gr_public/gene_mapping.csv"),
    "reason":"Published input labels are stable Ensembl IDs, not symbols. Use frozen human mappings; coordinates and incorrectmm9 summary unused.",
    "timing":"Input headers shown; candidate effects not calculated."})
measure=[];tables={}
for group in ["UT","DEX","17","17DEX"]:
    with gzip.open(dest/"sources"/("GSE135730_SMC_"+group+".txt.gz"),"rt") as stream:
        data=list(csv.DictReader(stream,delimiter="\t"))
    index={r["geneID"]:r for r in data};assert len(index)==len(data)
    columns=[k for k in data[0] if k.startswith("SMC_")];assert len(columns)==3
    tables[group]=index
    for g in mapping:
        if g["feature_id"] not in index:continue
        for col in columns:
            raw=float(index[g["feature_id"]][col]);assert raw>=0 and np.isfinite(raw)
            measure.append({"symbol":g["symbol"],"feature_id":g["feature_id"],"sample":col,"group":group,
                            "RPKM":raw,"value":float(np.log2(raw+1))})
results=[]
for g in mapping:
    vals={k:np.asarray([r["value"] for r in measure if r["symbol"]==g["symbol"] and r["group"]==k]) for k in tables}
    for contrast,coefficient in [("DEX_noIL17",{"DEX":1,"UT":-1}),("DEX_withIL17",{"17DEX":1,"17":-1}),
                                 ("DEX_x_IL17",{"17DEX":1,"17":-1,"DEX":-1,"UT":1})]:
        r={"symbol":g["symbol"],"feature_id":g["feature_id"],"contrast":contrast,"status":"estimable",
           "effect":"","se":"","ci_low":"","ci_high":"","df":"","pvalue":1.}
        if not all(len(vals[k])==3 for k in coefficient):r["status"]="missing_annotation"
        else:
            effect=sum(c*np.mean(vals[k]) for k,c in coefficient.items())
            variance=[np.var(vals[k],ddof=1)/3 for k in coefficient]
            se=np.sqrt(sum(variance));df=sum(variance)**2/sum(v*v/2 for v in variance)
            width=stats.t.ppf(.975,df)*se;p=2*stats.t.sf(abs(effect/se),df)
            r.update(effect=float(effect),se=float(se),ci_low=float(effect-width),ci_high=float(effect+width),df=float(df),pvalue=float(p))
        results.append(r)
for r,p in zip(results,holm([r["pvalue"] for r in results])):r["holm_33"]=float(p)
csv_out(dest/"early_measurements.csv",measure)
csv_out(dest/"early_results.csv",results)
json_out(dest/"early_run.json",{"status":"completed","utc":utc(),"measurements":len(measure),"tests":len(results),
    "gene_rows":{k:len(v) for k,v in tables.items()},"scope":"PublishedRPKM earlyASM culture-level effects; age/donoridentityunknown, no independentadulttimeinteractionclaim"})
for r in results:
    if r["symbol"] in ["PER2","PER1"]:print(r,flush=True)
