"""Published-label-only direct response sensitivity, preserving original primary outputs."""
import json
import sys
from pathlib import Path
from set_validation import rows,estimate,adjust
from validation_sources import record,utc,csv_out,json_out

out=Path(sys.argv[1]).resolve()/"unselected_protein"
json_out(out/"direct_subset_amendment.json",dict(utc=utc(),script=record(Path(__file__)),
    timing="After raw7labeldirectresults, exploratory extra-label exclusion sensitivity",
    purpose="Do not let unresolvedextra10.09.19label silently determine direct72-24 result; retain originalraw6 andpublishedselected5 estimates separately",
    family=56,limit="SeparateLCgradients/MaxQuantassays,time/batchnotseparable; difference in estimated drugresponse is not absolute protein accumulation kinetics"))
scope=rows(out/"donor_scope.csv");allowed={int(r["time_h"]):set(r["published_selected_labels"].split("|")) for r in scope}
effects=rows(out/"donor_effects.csv");data=[];don=[]
for g in rows(out/"frozen_genes.csv"):
    bytime={t:{r["donor"]:float(r["effect"]) for r in effects if r["feature_id"]==g["feature_id"] and int(r["time_h"])==t and r["status"]=="paired" and r["donor"] in allowed[t]} for t in [24,72]}
    shared=sorted(set(bytime[24])&set(bytime[72]));x=[bytime[72][d]-bytime[24][d] for d in shared]
    for d,v in zip(shared,x):don.append(dict(feature_id=g["feature_id"],symbol=g["symbol"],donor=d,effect=v))
    r=dict(feature_id=g["feature_id"],symbol=g["symbol"],status="estimable" if len(x)>=3 else "insufficient_pairs")
    if len(x)>=3:r.update(estimate(x))
    else:
        r.update({k:"" for k in ["n_donors","effect","se","ci_low","ci_high","positive_donors","negative_donors"]});r.update(pvalue=1.,exact_pvalue=1.)
    data.append(r)
for r,p,e in zip(data,adjust([r["pvalue"] for r in data]),adjust([r["exact_pvalue"] for r in data])):r.update(holm56=float(p),exact_holm56=float(e))
csv_out(out/"direct_published_labels.csv",data);csv_out(out/"direct_published_donor_effects.csv",don)
print(json.dumps([r for r in data if r["symbol"]=="TMT1A"],indent=2))
