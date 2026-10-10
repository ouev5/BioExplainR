"""Donor-level reanalysis of exposed selected protein arrays, with scope retained."""
import csv
import json
import re
import sys
from pathlib import Path
import numpy as np
import openpyxl
from validation_sources import csv_out,json_out,utc,record
from validation_expression import summary,holm

dest=Path(sys.argv[1]).resolve()/"human_protein"
json_out(dest/"selected_array_reanalysis_freeze.json",{
    "utc":utc(),"script":record(Path(__file__)),"timing":"Post-extraction exploratory: selected METTL7A/FKBP5 intensities and published effects already seen.",
    "genes":["PER2","PER3","METTL7A","MAOA","ANGPTL2","FSTL3","PER1","FKBP5","TSC22D3","DUSP1","NR3C1"],
    "response_family":"11 frozen genes x24/72h cellular proteome=22Holm. Unavailable per-sample arrays retained as P=1 placeholder, not null evidence.",
    "technical_units":"Mean of three published log2 LFQ intensities per donor/condition. One paired difference per donor; n=6.",
    "direct_family":"11 genes x72h-minus24h within-donor response difference, 11Holm; five matching donor labels. Distinct assay scales cancel within each time response; technical batches/time remain confounded.",
    "conditional_selection":"Arrays supplied only on original differential lists. Recalculated inference conditional on published selection; not a new unselected protein screen or causal proof.",
    "missing":"No imputation or significance-based substitutions; no selected row -> arrays_unavailable, effect/CIempty, P=1placeholder."})
genes=json.loads((dest/"selected_array_reanalysis_freeze.json").read_text())["genes"]
w=openpyxl.load_workbook(dest/"Table S2.xlsx",data_only=True,read_only=True)
measure=[];donors=[];results=[];published=[]
for time,sheet in [(24,"S2_24hProteome_DiffAbundant"),(72,"S4_72hProteome_DiffAbundant")]:
    data=list(w[sheet].iter_rows(values_only=True));head=data[3]
    cols=[]
    for i,v in enumerate(head):
        if isinstance(v,str):
            m=re.fullmatch(r"(\d{2}\.\d{2}\.\d{2})(co|dex)([123])",v)
            if m:cols.append((i,m[1],m[2],m[3]))
    assert len(cols)==36
    for gene in genes:
        hit=[(i,r) for i,r in enumerate(data,1) if r[1]==gene]
        assert len(hit)<=1
        differences=[]
        if hit:
            original_row,r=hit[0]
            assert r[2]==r[7],"Require unambiguous protein group"
            published.append({"time_h":time,"symbol":gene,"accession":r[2],"published_effect":r[5],"published_pvalue":r[3],
                              "published_qvalue":r[4],"source_sheet":sheet,"source_row":original_row})
            for col,d,drug,rep in cols:
                assert r[col] is not None and np.isfinite(float(r[col]))
                measure.append({"time_h":time,"symbol":gene,"accession":r[2],"donor":d,"drug":drug,"technical_replicate":rep,
                                "value":float(r[col]),"source_sheet":sheet,"source_row":original_row,"source_column":col+1})
            for d in sorted({c[1] for c in cols}):
                x=[m["value"] for m in measure if m["symbol"]==gene and m["time_h"]==time and m["donor"]==d and m["drug"]=="dex"]
                y=[m["value"] for m in measure if m["symbol"]==gene and m["time_h"]==time and m["donor"]==d and m["drug"]=="co"]
                assert len(x)==len(y)==3
                effect=float(np.mean(x)-np.mean(y));differences.append(effect)
                donors.append({"time_h":time,"symbol":gene,"donor":d,"effect":effect,"n_technical_per_condition":3})
        result={"time_h":time,"symbol":gene,"status":"estimable_selected_array" if differences else "arrays_unavailable",
                "n_donors":0,"effect":"","se":"","ci_low":"","ci_high":"","df":"","pvalue":1.,"exact_pvalue":1.,"positive_donors":0,"negative_donors":0}
        if differences:result.update(summary(differences))
        results.append(result)
for r,p,ep in zip(results,holm([r["pvalue"] for r in results]),holm([r["exact_pvalue"] for r in results])):
    r.update(holm_22=float(p),exact_holm_22=float(ep))
direct=[];direct_donors=[]
for gene in genes:
    early={r["donor"]:r["effect"] for r in donors if r["symbol"]==gene and r["time_h"]==24}
    late={r["donor"]:r["effect"] for r in donors if r["symbol"]==gene and r["time_h"]==72}
    shared=sorted(set(early)&set(late));differences=[late[d]-early[d] for d in shared]
    r={"symbol":gene,"status":"estimable_selected_array" if differences else "arrays_unavailable","n_donors":0,
       "effect":"","se":"","ci_low":"","ci_high":"","df":"","pvalue":1.,"exact_pvalue":1.,"positive_donors":0,"negative_donors":0}
    if differences:r.update(summary(differences))
    direct.append(r)
    for d,v in zip(shared,differences):direct_donors.append({"symbol":gene,"donor":d,"effect_72_minus24":v})
for r,p,ep in zip(direct,holm([r["pvalue"] for r in direct]),holm([r["exact_pvalue"] for r in direct])):
    r.update(holm_11=float(p),exact_holm_11=float(ep))
csv_out(dest/"human_selected_measurements.csv",measure)
csv_out(dest/"human_selected_donor_effects.csv",donors)
csv_out(dest/"human_selected_results.csv",results)
csv_out(dest/"human_published_results.csv",published)
csv_out(dest/"human_direct_donor_effects.csv",direct_donors)
csv_out(dest/"human_direct_results.csv",direct)
json_out(dest/"human_numeric_run.json",{"status":"completed","utc":utc(),"measurements":len(measure),"response_tests":22,"direct_tests":11,
         "scope":"Selected arrays only; donor-level post-extraction exploratory reanalysis, cross-tissue human protein support"})
for r in results+direct:
    if r["status"]=="estimable_selected_array":print(r,flush=True)
