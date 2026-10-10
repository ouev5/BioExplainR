"""Append final recorded results and preserve earlier ledger as a dated stage."""
import json
import sys
from pathlib import Path
from set_validation import rows
from validation_sources import record,utc,json_out

out=Path(sys.argv[1]).resolve();count=rows(out/"count_results.csv");tpm=rows(out/"tpm_results.csv")
interactions={method:[r for r in table if r["contrast"]=="GC_x_perturbation" and float(r["holm"])<.05] for method,table in [("tpm",tpm),("count",count)]}
protein=out/"unselected_protein"
json_out(out/"scientific_ledger_final.json",dict(status="completed_public_data_set_and_unselected_protein",utc=utc(),
    previous_stage=record(out/"scientific_ledger.json"),set_counts=json.loads((out/"numeric_audit.json").read_text())["set_counts"],
    secondary_GNAS_interactions={k:[dict(feature_id=r["feature_id"],symbol=r["symbol"],effect=r["effect"],holm162=r["holm"]) for r in v] for k,v in interactions.items()},
    protein=dict(original_groups=[int(next(r["raw_groups"] for r in rows(protein/"detection.csv") if r["time_h"]==str(t))) for t in [24,72]],raw_donor_labels_per_assay=7,published_donors_per_assay=6,
        new_donor_independence="sameHTPCsource; extra10.09.19age/QCunverified",tests=112,estimable=11,Holm_pass=4,
        raw_LFQ_measurements=924,complete_HTTP_parts=2998,member_CRCs=6,
        conflicts=["raw7/published6labels","MaxQuant1.6.15/reported1.6.11","2rawLFQzeroswithpublishedfinitevalues"],
        exact_fullfamily="notconfirmed",direct_time_scope="exploratoryresponsecontrast across separatelyprocessedassays,notproteinaccumulation"),
    actual_BioExplainR_contexts=5,online_model_calls=0,wet_experiments=0,
    report="docs/paper_cn_v6/README.md",GSE42538="complete12samplemetadata,excludednosteroidfactor,notASM",
    source_audits=[record(protein/name) for name in ["r_audit.json","r_sensitivity_audit.json","final_audit.json","bioexplainr_workflow.json"]]))
print(json.dumps(interactions,ensure_ascii=False,indent=2))
