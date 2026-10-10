"""Keep raw/published donor and processing conflicts explicit; add labeled sensitivities."""
import json
import sys
from pathlib import Path
import numpy as np
from set_validation import rows,estimate,adjust
from validation_sources import ROOT,record,utc,csv_out,json_out

out=Path(sys.argv[1]).resolve();dest=out/"unselected_protein"
old=ROOT/"research/results/discovery_validation_v2/human_protein"
json_out(dest/"donor_processing_amendment.json",dict(utc=utc(),script=record(Path(__file__)),
    reason="Rawfullarrays contain7biopsydate labels eachtime, paper and selectedtables report6; extra10.09.19atboth times. OriginalparametersMaxQuant1.6.15.0 differspaper/PRIDE1.6.11.0. Preserveconflicts, noauthorconfirmedexclusion.",
    timing="After rawcandidateproteinresults; labelsubset/directtime exploratorysensitivities, notconfirmatory",
    analyses="Same56x2=112family recomputed on publishedselected donorlabels; direct72-24onlysharedeligible rawlabels,56Holm family; separatefromprimary112",
    independence="Do not call7newadultdonors or add raw7 andselected6; subsetusesmetadata donorlabels not outcome selection"))
map=rows(dest/"sample_map.csv");eff=rows(dest/"donor_effects.csv");genes=rows(dest/"frozen_genes.csv")
original=rows(old/"human_selected_donor_effects.csv")
scope=[];sensitivity=[];direct=[];de=[]
for time in [24,72]:
    rawlabels=sorted({r["donor"] for r in map if int(r["time_h"])==time})
    labels=sorted({r["donor"] for r in original if int(r["time_h"])==time})
    scope.append(dict(time_h=time,raw_donor_labels="|".join(rawlabels),published_selected_labels="|".join(labels),
        additional_raw_labels="|".join(sorted(set(rawlabels)-set(labels))),
        raw_samples=42,published_selected_samples=36,status="unresolvedraw_vs_publishedscope",adult_age_for_additional_label="unverified"))
    for g in genes:
        rr=[r for r in eff if r["feature_id"]==g["feature_id"] and int(r["time_h"])==time and r["donor"] in labels and r["status"]=="paired"]
        r=dict(feature_id=g["feature_id"],symbol=g["symbol"],time_h=time,status="estimable" if len(rr)>=3 else "insufficient_pairs",analysis="published_label_subset_on_rawLFQ")
        if len(rr)>=3:r.update(estimate([float(s["effect"]) for s in rr]))
        else:
            r.update({k:"" for k in ["n_donors","effect","se","ci_low","ci_high","positive_donors","negative_donors"]});r.update(pvalue=1.,exact_pvalue=1.)
        sensitivity.append(r)
for r,p,e in zip(sensitivity,adjust([r["pvalue"] for r in sensitivity]),adjust([r["exact_pvalue"] for r in sensitivity])):r.update(holm112=float(p),exact_holm112=float(e))
for g in genes:
    bytime={t:{r["donor"]:float(r["effect"]) for r in eff if r["feature_id"]==g["feature_id"] and int(r["time_h"])==t and r["status"]=="paired"} for t in [24,72]}
    common=sorted(set(bytime[24])&set(bytime[72]));values=[bytime[72][d]-bytime[24][d] for d in common]
    for d,x in zip(common,values):de.append(dict(feature_id=g["feature_id"],symbol=g["symbol"],donor=d,effect=x))
    r=dict(feature_id=g["feature_id"],symbol=g["symbol"],status="estimable" if len(values)>=3 else "insufficient_pairs")
    if len(values)>=3:r.update(estimate(values))
    else:
        r.update({k:"" for k in ["n_donors","effect","se","ci_low","ci_high","positive_donors","negative_donors"]});r.update(pvalue=1.,exact_pvalue=1.)
    direct.append(r)
for r,p,e in zip(direct,adjust([r["pvalue"] for r in direct]),adjust([r["exact_pvalue"] for r in direct])):r.update(holm56=float(p),exact_holm56=float(e))
compare=[]
for r in rows(old/"human_selected_measurements.csv"):
    symbol="TMT1A" if r["symbol"]=="METTL7A" else r["symbol"]
    raw=next(s for s in rows(dest/"measurements.csv") if s["symbol"]==symbol and s["time_h"]==r["time_h"] and s["donor"]==r["donor"] and s["condition"]==r["drug"] and s["technical_rep"]==r["technical_replicate"])
    compare.append(dict(time_h=r["time_h"],symbol=symbol,donor=r["donor"],condition=r["drug"],technical_rep=r["technical_replicate"],
        published_logLFQ=r["value"],rawLFQ=raw["raw_LFQ"],raw_logLFQ=raw["log2_LFQ"],
        difference=float(raw["log2_LFQ"])-float(r["value"]) if raw["log2_LFQ"] else "",raw_missing=not bool(raw["log2_LFQ"])))
for name,data in [("donor_scope.csv",scope),("published_label_sensitivity.csv",sensitivity),("direct_time_results.csv",direct),("direct_time_donor_effects.csv",de),("published_raw_cell_comparison.csv",compare)]:csv_out(dest/name,data)
json_out(dest/"sensitivity_run.json",dict(status="completed",utc=utc(),published_raw_cells=len(compare),
    rawmissing_in_published=sum(r["raw_missing"] for r in compare),subset_family=112,direct_family=56,
    scope="Explicit7raw/6published/MaxQuantversion conflicts retained; separate exploratory estimands on same biological source"))
print(json.dumps([r for r in sensitivity+direct if r["symbol"]=="TMT1A"],indent=2))
