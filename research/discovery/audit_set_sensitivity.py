"""Recompute all TPM sensitivity estimates and check full-set provenance."""
import json
import sys
from pathlib import Path
import numpy as np
from scipy import stats
from set_validation import rows,adjust
from validation_sources import ROOT,record,utc,json_out

out=Path(sys.argv[1]).resolve();frozen=json.loads((out/"analysis_freeze.json").read_text())
for rec in frozen["inputs"]+frozen["scripts"]+[frozen["set"],frozen["samples"]]:assert record(ROOT/rec["path"])==rec,rec["path"]
annotation=json.loads((out/"annotation_freeze.json").read_text())
for rec in annotation["records"]+[annotation["annotation"]]:assert record(ROOT/rec["path"])==rec
mapping=rows(out/"annotation.csv");measure=rows(out/"tpm_measurements.csv");checks=0
for r in rows(out/"tpm_sensitivity.csv"):
    subset=[s for s in measure if s["feature_id"]==r["feature_id"] and s["kd"]=="0"]
    donors=sorted({s["donor"] for s in subset});pseudo=float(r["parameter"]) if r["kind"]=="pseudocount" else 1.
    if r["kind"]=="leave_one_donor":donors.remove(r["parameter"])
    x=[]
    for d in donors:
        v={s["gc"]:float(s["raw_TPM"]) for s in subset if s["donor"]==d}
        x.append(np.log2(v["1"]+pseudo)-np.log2(v["0"]+pseudo))
    tt=stats.ttest_1samp(x,0);se=np.std(x,ddof=1)/np.sqrt(len(x));width=stats.t.ppf(.975,len(x)-1)*se
    for key,value in zip(["effect","se","ci_low","ci_high","pvalue"],[np.mean(x),se,np.mean(x)-width,np.mean(x)+width,tt.pvalue]):
        assert np.isclose(float(r[key]),value,rtol=1e-7,atol=1e-9);checks+=1
    direction=int(next(g["discovery_direction"] for g in mapping if g["feature_id"]==r["feature_id"]))
    assert (r["direction_matches"]=="True")==bool(np.sign(np.mean(x))==direction)
loo=rows(out/"count_leave_one_donor.csv");assert len(loo)==324
for donor in sorted({r["excluded_donor"] for r in loo}):
    z=[r for r in loo if r["excluded_donor"]==donor];assert len(z)==54
    for r,p in zip(z,adjust([float(r["pvalue"]) for r in z])):
        assert np.isclose(float(r["holm"]),p)
        direction=int(next(g["discovery_direction"] for g in mapping if g["feature_id"]==r["feature_id"]))
        expected=bool(r["effect"]) and np.sign(float(r["effect"]))==direction
        assert (r["direction_matches"]=="TRUE")==expected
json_out(out/"sensitivity_audit.json",dict(status="pass",utc=utc(),TPM_numeric_checks=checks,
    count_omission_rows=324,provenance_inputs=len(frozen["inputs"]),
    scope="Recompute TPM pseudo/omission t and CI; verify count omission directions/Holm, not cross-language re-fit TMM/voom"))
print("All TPM sensitivity, count-omission direction/Holm and frozen provenance checks passed")
