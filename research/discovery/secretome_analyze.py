"""Complete protein-group analysis and fixed 56-gene secretome checks; no imputation."""
import argparse
import csv
import itertools
import json
import re
from pathlib import Path

import numpy as np
import openpyxl
from scipy import stats

from set_validation import rows, adjust
from validation_sources import ROOT, HERE, record, utc, csv_out, json_out

HUMAN = ROOT / "research/results/discovery_validation_v2/human_protein"
QC = ["Reverse", "Potential contaminant", "Only identified by site"]
STAT_FIELDS = ["effect", "se", "ci_low", "ci_high", "positive_donors", "negative_donors"]


def estimate(x):
    x = np.asarray(x, dtype=float)
    result = dict(n_pairs=len(x), status="estimable" if len(x) >= 3 else "insufficient_pairs",
                  **{k:"" for k in STAT_FIELDS}, pvalue=1., exact_pvalue=1.)
    if len(x) < 3:
        return result
    effect = float(x.mean())
    se = float(x.std(ddof=1)/np.sqrt(len(x)))
    if se == 0:
        p = 1. if effect == 0 else 0.
    else:
        p = float(2*stats.t.sf(abs(effect/se), len(x)-1))
    width = float(stats.t.ppf(.975, len(x)-1)*se)
    signs = np.asarray(list(itertools.product([-1, 1], repeat=len(x))))
    exact = float(np.mean(abs(signs@x/len(x)) >= abs(effect)-1e-12))
    result.update(effect=effect, se=se, ci_low=effect-width, ci_high=effect+width,
                  positive_donors=int(sum(x>0)), negative_donors=int(sum(x<0)), pvalue=p, exact_pvalue=exact)
    return result


def bh(p):
    p = np.asarray(p, dtype=float)
    order = np.argsort(p, kind="stable")
    result = np.ones(len(p))
    result[order] = np.minimum(1., np.minimum.accumulate((p[order]*len(p)/np.arange(1,len(p)+1))[::-1])[::-1])
    return result


def aliases(symbol):
    return {symbol} | ({"METTL7A"} if symbol == "TMT1A" else {"ARNTL"} if symbol == "BMAL1" else set())


def sources(out, time):
    complete = json.loads((out / f"archives/{time}h/extraction.json").read_text())
    assert complete["status"] == "pass" and complete["whole_archive_SHA1_verified"]
    for entry in complete["outputs"]:
        assert record(ROOT/entry["path"]) == {k:entry[k] for k in ["path","bytes","sha256"]}
    return {Path(e["member"]).name:ROOT/e["path"] for e in complete["outputs"]}


def parse_samples(source, time):
    mappingpath = next(path for name,path in source.items() if "samplename" in name.lower())
    text = mappingpath.read_text()
    decoding = dict(re.findall(r"(?m)^((?:\d{2}\.\d{2}\.\d{2})|\d+)\.\.\.\s*=\s*(\d{2}\.\d{2}\.\d{2})", text))
    assert decoding, text
    with source["proteinGroups.txt"].open(newline="") as stream:
        header = next(csv.reader(stream, delimiter="\t"))
    parsed = []
    for col in header:
        if not col.startswith("LFQ intensity "):
            continue
        label = col.removeprefix("LFQ intensity ")
        m = re.fullmatch(r"((?:\d{2}\.\d{2}\.\d{2})|\d+)_?(co|c|dex)([123])", label)
        assert m and m[1] in decoding, (label, decoding)
        parsed.append(dict(time_h=time, source_column=col, experiment=label, donor=decoding[m[1]],
                           raw_donor_label=m[1], condition="co" if m[2] == "c" else m[2], technical_rep=int(m[3])))
    donors = sorted({r["donor"] for r in parsed})
    assert len(parsed) == 6*len(donors)
    for d in donors:
        assert {(r["condition"],r["technical_rep"]) for r in parsed if r["donor"] == d} == \
               {(c,i) for c in ["co","dex"] for i in [1,2,3]}
    with source["summary.txt"].open(newline="") as stream:
        summary = list(csv.DictReader(stream, delimiter="\t"))
    summary = [r for r in summary if r.get("Experiment") in {s["experiment"] for s in parsed}]
    assert len(summary) == len(parsed)
    for s in parsed:
        hit = [r for r in summary if r["Experiment"] == s["experiment"]]
        assert len(hit) == 1
        s["raw_file"] = hit[0]["Raw file"]
        raw_match = re.fullmatch(r"((?:\d{2}\.\d{2}\.\d{2})|\d+)_?(co|c|dex)([123])", s["raw_file"])
        assert raw_match and decoding[raw_match[1]] == s["donor"] and raw_match[3] == str(s["technical_rep"])
        assert ("co" if raw_match[2] == "c" else raw_match[2]) == s["condition"]
        s["deposited_raw_file"] = s["raw_file"]+".raw" if "." in raw_match[1] else \
                                 f"{s['donor']}_{s['condition']}{s['technical_rep']}.raw"
    return parsed


def published_donors():
    book = openpyxl.load_workbook(HUMAN/"Table S2.xlsx", data_only=True, read_only=True)
    answer = {}
    for time, sheet in [(24,"S6_24hSecretome_DiffAbundant"),(72,"S8_72hSecretome_DiffAbundant")]:
        dates = set()
        for row in book[sheet].iter_rows(min_row=1,max_row=5,values_only=True):
            for value in row:
                if isinstance(value,str):
                    dates.update(re.findall(r"\d{2}\.\d{2}\.\d{2}",value))
        assert len(dates) == 6, (time, dates)
        answer[time] = sorted(dates)
    return answer


def design(out):
    samplemap = []
    scope_rows = []
    inputs = []
    versions = []
    inventory = rows(out/"file_inventory.csv")
    dates = published_donors()
    for time in [24,72]:
        source = sources(out,time)
        samplemap += parse_samples(source,time)
        actual = sorted({s["donor"] for s in samplemap if s["time_h"] == time})
        for donor in sorted(set(actual)|set(dates[time])):
            scope_rows.append(dict(time_h=time,donor=donor,in_original_LFQ=donor in actual,
                                   in_published_selected_headers=donor in dates[time]))
        inputs += [record(p) for p in source.values()]
        parameter = source["parameters.txt"].read_text()
        versions.append(dict(time_h=time, maxquant_version=re.search(r"(?m)^Version\t([^\r\n]+)",parameter)[1]))
    for s in samplemap:
        raw = s["deposited_raw_file"]
        assert sum(r["fileName"] == raw for r in inventory) == 1, raw
    csv_out(out/"sample_map.csv",samplemap)
    csv_out(out/"sample_scope_comparison.csv",scope_rows)
    used = {s["deposited_raw_file"] for s in samplemap}
    csv_out(out/"raw_file_scope.csv",[dict(**r,in_processed_arrays=r["fileName"] in used) for r in inventory if r["category"] == "RAW"])
    csv_out(out/"processing_versions.csv",versions)
    json_out(out/"design_freeze.json",dict(utc=utc(), script=record(Path(__file__)), inputs=inputs,
        execution_scripts=[record(HERE/p) for p in ["secretome_analyze.py","audit_secretome.R","secretome_evidence.py","report_secretome.R"]],
        sample_map=record(out/"sample_map.csv"), genes=record(out/"frozen_genes.csv"), published_donors=dates,
        timing="Decoded samples/summary/parameters and published headers inspected; candidate LFQ not read",
        primary_technical_min=2, strict_technical_min=3, minimum_pairs=3,
        candidate_family=112, direct_time_family=56, full_BH_family="All QC-passing groups x available timepoints pooled",
        scope="Paired biopsy-date donor labels, technical means, same HTPC source, extracellular abundance not secretion rate"))
    print(json.dumps(dict(samples=len(samplemap),versions=versions,published_donors=dates),indent=2))


def donor_effects(values, samplemap, minimum=2, allowed=None):
    result = []
    for donor in sorted({s["donor"] for s in samplemap}):
        if allowed is not None and donor not in allowed:
            continue
        conds = {c:[np.log2(v) for v,s in zip(values,samplemap) if s["donor"] == donor and s["condition"] == c and v>0]
                 for c in ["co","dex"]}
        good = all(len(v)>=minimum for v in conds.values())
        result.append(dict(donor=donor, control_technical_observed=len(conds["co"]), DEX_technical_observed=len(conds["dex"]),
            control_log2_mean=float(np.mean(conds["co"])) if len(conds["co"])>=minimum else "",
            DEX_log2_mean=float(np.mean(conds["dex"])) if len(conds["dex"])>=minimum else "",
            effect=float(np.mean(conds["dex"])-np.mean(conds["co"])) if good else "",
            status="paired" if good else "insufficient_LFQ"))
    return result


def analyze(out):
    csv.field_size_limit(10*1024*1024)
    frozen = json.loads((out/"design_freeze.json").read_text())
    for r in frozen["inputs"]:
        assert record(ROOT/r["path"]) == r
    for r in frozen["execution_scripts"]:
        assert record(ROOT/r["path"]) == r
    assert record(out/"sample_map.csv") == frozen["sample_map"] and record(out/"frozen_genes.csv") == frozen["genes"]
    samples, genes = rows(out/"sample_map.csv"), rows(out/"frozen_genes.csv")
    full, qc, measurements, effects, candidate, detection, sensitivity, leave_one = [],[],[],[],[],[],[],[]
    candidate_effects, candidate_measurements = [],[]
    dates = frozen["published_donors"]
    for time in [24,72]:
        local = [s for s in samples if int(s["time_h"]) == time]
        source = sources(out,time)
        with source["proteinGroups.txt"].open(newline="") as stream:
            table = list(csv.DictReader(stream,delimiter="\t"))
        groups = {}
        for row_number,r in enumerate(table,2):
            group_id = f"{time}h:{row_number}"
            failed = [k for k in QC if r[k] == "+"]
            info = dict(group_id=group_id,time_h=time,source_row=row_number,protein_ids=r["Protein IDs"],gene_names=r["Gene names"],
                        QC_status="exclude" if failed else "pass",QC_reason="|".join(failed))
            qc.append(info)
            if failed:
                continue
            values = [float(r[s["source_column"]]) for s in local]
            assert np.all(np.isfinite(values)) and min(values)>=0
            d = donor_effects(values,local)
            stat = estimate([v["effect"] for v in d if v["status"] == "paired"])
            full.append(dict(**info,**stat))
            groupmeasure = [dict(**(info | s),raw_LFQ=v,log2_LFQ=float(np.log2(v)) if v>0 else "") for v,s in zip(values,local)]
            groupeffects = [dict(**info,**x) for x in d]
            measurements += groupmeasure
            effects += groupeffects
            groups[group_id] = dict(info=info,values=values,stat=stat,effects=groupeffects,measurements=groupmeasure)
        for gene in genes:
            names = aliases(gene["symbol"])
            token = [r for r in qc if r["time_h"] == time and set(r["gene_names"].split(";"))&names]
            matches = [g for g in groups.values() if g["info"]["gene_names"] in names]
            detection_status = "unique_group" if len(matches) == 1 else "ambiguous_groups" if len(matches)>1 else \
                               "non_singleton_only" if any(r["QC_status"] == "pass" for r in token) else \
                               "QC_excluded_only" if token else "not_detected"
            g = matches[0] if len(matches) == 1 else None
            base = dict(feature_id=gene["feature_id"],symbol=gene["symbol"],set_rank=gene["set_rank"],
                        discovery_direction=gene["discovery_direction"],time_h=time,group_id=g["info"]["group_id"] if g else "")
            detection.append(dict(**base,detection_status=detection_status,singleton_groups=len(matches),token_matching_groups=len(token),
                                  token_matches="|".join(r["group_id"]+":"+r["QC_status"]+":"+r["gene_names"] for r in token)))
            stat = dict(g["stat"]) if g else estimate([])
            if g is None:
                stat["status"] = detection_status
            candidate.append(dict(**base,**stat))
            if g:
                candidate_measurements += [dict(feature_id=gene["feature_id"],symbol=gene["symbol"],**m) for m in g["measurements"]]
                candidate_effects += [dict(feature_id=gene["feature_id"],symbol=gene["symbol"],**e) for e in g["effects"]]
                x = [e for e in g["effects"] if e["status"] == "paired"]
                if len(x)>=3:
                    for e in x:
                        remaining = [float(v["effect"]) for v in x if v["donor"] != e["donor"]]
                        leave_one.append(dict(**base,excluded_donor=e["donor"],n_remaining=len(remaining),
                                              mean_effect=float(np.mean(remaining)),matches_main_direction=np.sign(np.mean(remaining)) == np.sign(stat["effect"])))
            for kind,minimum,allowed in [("published_six",2,dates[str(time)]),("strict_three",3,None)]:
                d = donor_effects(g["values"],local,minimum,allowed) if g else []
                s = estimate([v["effect"] for v in d if v["status"] == "paired"])
                if g is None:
                    s["status"] = detection_status
                sensitivity.append(dict(**base,analysis=kind,**s))
    for r,b,e in zip(full,bh([r["pvalue"] for r in full]),bh([r["exact_pvalue"] for r in full])):
        r.update(pooled_BH=float(b),exact_pooled_BH=float(e),family_size=len(full))
    for table in [candidate]+[[r for r in sensitivity if r["analysis"] == kind] for kind in ["published_six","strict_three"]]:
        assert len(table) == 112
        for r,p,e in zip(table,adjust([r["pvalue"] for r in table]),adjust([r["exact_pvalue"] for r in table])):
            r.update(holm112=float(p),exact_holm112=float(e))
    direct, direct_effects = [],[]
    for gene in genes:
        eligible = [r for r in candidate_effects if r["feature_id"] == gene["feature_id"] and r["status"] == "paired"]
        donors = sorted({r["donor"] for r in eligible})
        values = []
        for donor in donors:
            matched = {int(r["time_h"]):float(r["effect"]) for r in eligible if r["donor"] == donor}
            if set(matched) == {24,72}:
                delta = matched[72]-matched[24]
                values.append(delta)
                direct_effects.append(dict(feature_id=gene["feature_id"],symbol=gene["symbol"],donor=donor,
                                           response_24h=matched[24],response_72h=matched[72],effect=delta))
        direct.append(dict(feature_id=gene["feature_id"],symbol=gene["symbol"],contrast="72h_minus_24h_response",**estimate(values)))
    for r,p,e in zip(direct,adjust([r["pvalue"] for r in direct]),adjust([r["exact_pvalue"] for r in direct])):
        r.update(holm56=float(p),exact_holm56=float(e))
    for name,table in [("group_QC.csv",qc),("all_measurements.csv",measurements),("all_donor_effects.csv",effects),
                       ("all_results.csv",full),("candidate_detection.csv",detection),("candidate_results.csv",candidate),
                       ("candidate_measurements.csv",candidate_measurements),("candidate_donor_effects.csv",candidate_effects),
                       ("candidate_sensitivity.csv",sensitivity),("candidate_leave_one.csv",leave_one),
                       ("candidate_direct_time.csv",direct),("candidate_direct_donor_effects.csv",direct_effects)]:
        csv_out(out/name,table)
    summary = []
    for time in [24,72]:
        z = [r for r in full if r["time_h"] == time]
        c = [r for r in candidate if r["time_h"] == time]
        summary.append(dict(time_h=time,raw_groups=sum(r["time_h"] == time for r in qc),QC_groups=len(z),
            donor_labels=len({s["donor"] for s in samples if int(s["time_h"]) == time}),technical_columns=sum(int(s["time_h"]) == time for s in samples),
            estimable_groups=sum(r["status"] == "estimable" for r in z),pooled_BH_significant=sum(r["pooled_BH"] < .05 for r in z),
            exact_BH_significant=sum(r["exact_pooled_BH"] < .05 for r in z),candidate_unique_groups=sum(r["time_h"] == time and r["detection_status"] == "unique_group" for r in detection),
            candidate_estimable=sum(r["status"] == "estimable" for r in c),candidate_Holm_significant=sum(r["holm112"] < .05 for r in c)))
    csv_out(out/"array_summary.csv",summary)
    json_out(out/"analysis_run.json",dict(status="completed",utc=utc(),script=record(Path(__file__)),
        full_family=len(full),candidate_family=112,summary=summary,raw_measurements=len(measurements),
        estimable_candidates=sum(r["status"] == "estimable" for r in candidate),
        scope="Full unselected MaxQuant secretome arrays, paired labels, no imputation, cross-tissue same source"))
    print(json.dumps(dict(summary=summary,focus=[r for r in candidate if r["symbol"] in ["ANGPTL2","FSTL3"]]),indent=2))


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("action",choices=["design","analyze"])
    p.add_argument("output",type=Path)
    a = p.parse_args()
    globals()[a.action](a.output.resolve())
