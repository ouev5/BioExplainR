"""Independent count/WLS audit and transparent complete-set summary."""
import argparse
import csv
import gzip
import io
import json
from pathlib import Path

import numpy as np
from scipy import stats

from set_validation import OLD, rows, adjust
from validation_sources import csv_out, json_out, record, utc


def close(a,b):
    assert np.isclose(float(a),float(b),rtol=1e-7,atol=1e-9), (a,b)


def audit(out):
    mapping=rows(out/"annotation.csv"); tpm=rows(out/"tpm_results.csv"); count=rows(out/"count_results.csv")
    assert len(mapping)==54 and len(tpm)==len(count)==216
    assert json.loads((out/"r_tpm_audit.json").read_text())["status"]=="pass"
    text=gzip.decompress((OLD/"sources/GSE130715_counts.txt.gz").read_bytes()).decode("utf-8-sig")
    data=list(csv.DictReader(io.StringIO(text),delimiter="\t"));key=next(iter(data[0]));index={r[key]:r for r in data}
    samples=rows(out/"samples.csv")
    original_cols={s["sample"]:[k for k in data[0] if s["sample_key"] in k] for s in samples}
    assert all(len(c)==1 for c in original_cols.values())
    design=rows(out/"count_design.csv");names=[k for k in design[0] if k!="sample"]
    x=np.asarray([[float(r[k]) for k in names] for r in design]);assert np.linalg.matrix_rank(x)==9
    contrasts=rows(out/"count_contrasts.csv");assert [r["coefficient"] for r in contrasts]==names
    wls=rows(out/"count_wls_inputs.csv");checks=raw_checks=0
    for r in wls:
        close(r["raw_count"],index[r["entrez_id"]][original_cols[r["sample"]][0]]);raw_checks+=1
    for r in count:
        if r["status"]!="estimable":
            assert r["effect"]=="" and float(r["pvalue"])==1
            continue
        z={a["sample"]:a for a in wls if a["feature_id"]==r["feature_id"]}
        y=np.asarray([float(z[s["sample"]]["logCPM"]) for s in design]);w=np.asarray([float(z[s["sample"]]["weight"]) for s in design])
        cov=np.linalg.inv(x.T@(x*w[:,None]));beta=cov@x.T@(w*y);c=np.asarray([float(s[r["contrast"]]) for s in contrasts])
        first=next(iter(z.values()));s2=float(first["s2_post"]);df=float(first["df_total"])
        effect=c@beta;se=np.sqrt(c@cov@c*s2);width=stats.t.ppf(.975,df)*se
        for key,val in zip(["effect","se","ci_low","ci_high","pvalue"],[effect,se,effect-width,effect+width,2*stats.t.sf(abs(effect/se),df)]):
            close(r[key],val);checks+=1
    for family in ["primary_54","secondary_162"]:
        for table in [tpm,count]:
            z=[r for r in table if r["family"]==family]
            for r,p in zip(z,adjust([float(r["pvalue"]) for r in z])):close(r["holm"],p)
    effects=rows(out/"tpm_donor_effects.csv");sens=rows(out/"tpm_sensitivity.csv");loo=rows(out/"count_leave_one_donor.csv")
    summary=[]
    for g in mapping:
        a=next(r for r in tpm if r["feature_id"]==g["feature_id"] and r["contrast"]=="GC_control")
        b=next(r for r in count if r["feature_id"]==g["feature_id"] and r["contrast"]=="GC_control")
        direction=int(g["discovery_direction"])
        measured=a["status"]=="estimable";counted=b["status"]=="estimable"
        same=measured and np.sign(float(a["effect"]))==direction
        per=[float(r["effect"]) for r in effects if r["feature_id"]==g["feature_id"] and r["contrast"]=="GC_control"]
        stable=measured and len(per)==6 and all(np.sign(v)==direction for v in per)
        ss=[r for r in sens if r["feature_id"]==g["feature_id"]]
        ll=[r for r in loo if r["feature_id"]==g["feature_id"]]
        tpass=same and float(a["holm"])<.05
        cpass=counted and np.sign(float(b["effect"]))==direction and float(b["holm"])<.05
        loo_pass=len(ll)==6 and all(r["direction_matches"]=="TRUE" for r in ll)
        sensitivity_pass=len(ss)==9 and all(r["direction_matches"]=="True" for r in ss)
        summary.append(dict(set_rank=g["set_rank"],feature_id=g["feature_id"],symbol=g["symbol"],entrez_id=g["entrez_id"],
            discovery_direction=direction,tpm_status=a["status"],tpm_effect=a["effect"],tpm_ci_low=a["ci_low"],tpm_ci_high=a["ci_high"],
            tpm_holm54=a["holm"],exact_holm54=a["exact_holm"],count_status=b["status"],count_effect=b["effect"],
            count_ci_low=b["ci_low"],count_ci_high=b["ci_high"],count_holm54=b["holm"],same_direction=bool(same),
            all_six_expected=bool(stable),tpm_pass=bool(tpass),count_pass=bool(cpass),
            tpm_sensitivity_direction=bool(sensitivity_pass),count_leave_one_direction=bool(loo_pass),
            robust_supported=bool(tpass and cpass and stable and sensitivity_pass and loo_pass)))
    csv_out(out/"set_summary.csv",summary)
    totals={k:sum(bool(r[k]) for r in summary) for k in ["same_direction","all_six_expected","tpm_pass","count_pass","tpm_sensitivity_direction","count_leave_one_direction","robust_supported"]}
    totals.update(frozen=54,tpm_measurable=sum(r["tpm_status"]=="estimable" for r in summary),
                  count_estimable=sum(r["count_status"]=="estimable" for r in summary),
                  exact_holm_pass=sum(float(r["exact_holm54"])<.05 for r in summary))
    result=dict(status="pass",utc=utc(),raw_count_measurements=raw_checks,exact_WLS_numeric_checks=checks,
        set_counts=totals,primary_tests=54,secondary_tests=162,
        scope="Independent raw count and WLS arithmetic; R moderation retained; new result-after-known-candidates expansion")
    json_out(out/"numeric_audit.json",result)
    print(json.dumps(result,ensure_ascii=False,indent=2))


if __name__=="__main__":
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument("output",type=Path)
    audit(parser.parse_args().output.resolve())
