"""Frozen, scoped protein-set analysis of two already downloaded epithelial tables."""
import argparse
from collections import Counter
import csv
import itertools
import json
import math
from pathlib import Path
import re
import sys

import numpy as np
from scipy import stats

from validation_sources import ROOT, record, utc, json_out, csv_out

OUT = ROOT / "research/results/discovery_epithelial_protein_v1"
PUBLIC = ROOT / "research/results/discovery_public_proteome_v1"
DOWNLOAD = ROOT / "research/results/discovery_public_download_v1"
SET = ROOT / "research/results/discovery_set_validation_v1"
HERE = Path(__file__).resolve().parent
A549 = PUBLIC / "imported/PXD063431_240221_PB_ProteomeDiscoverer_all_Proteins_A549.txt"
HBEC = PUBLIC / "sources/PXD029135_median-normalized_complete.txt"
SRDF = PUBLIC / "imported/PXD029135_SRDF_File.txt"
CONTRASTS = ["ICS_unstimulated", "ICS_polyIC", "ICS_x_polyIC"]
ALIASES = {"TMT1A": {"TMT1A", "METTL7A"}, "BMAL1": {"BMAL1", "ARNTL"}}
CODE = ["EPITHELIAL_PROTEIN_PROTOCOL.md", "epithelial_protein.py",
        "audit_epithelial_protein.R", "report_epithelial_protein.R",
        "finish_epithelial_protein.py", "validation_sources.py"]


def rows(path, delimiter=","):
    with path.open(encoding="utf-8-sig", newline="") as stream:
        return list(csv.DictReader(stream, delimiter=delimiter))


def prior_check():
    # The previous seal predates the latest prepended rgo section. Exact snapshot only.
    import download_public_data as prior
    original = prior.check_record
    def with_snapshot(item):
        if item["path"] == "rgo.md":
            assert dict(record(DOWNLOAD / "rgo_before_download.md"), path="rgo.md") == item
        else:
            original(item)
    prior.check_record = with_snapshot
    try:
        prior.verify()
    finally:
        prior.check_record = original
    manifest = json.loads((DOWNLOAD / "download_manifest.json").read_text())
    checks = json.loads((DOWNLOAD / "file_checks.json").read_text())
    return dict(status="pass", manifest=record(DOWNLOAD / "download_manifest.json"),
                sealed_files=len(manifest["files"]), complete_files=len(checks["entries"]),
                v013_bound_records=manifest["prior_integrity"]["checked_records"],
                scope="Previous download seal and v0.13 bound records/archive; exact old rgo snapshot")


def freeze():
    if OUT.exists():
        raise ValueError(f"Refusing overwrite: {OUT}")
    previous = prior_check()
    OUT.mkdir()
    (OUT / "rgo_before_epithelial.md").write_bytes((ROOT / "rgo.md").read_bytes())
    genes = rows(SET / "unselected_protein/frozen_genes.csv")
    directions = {r["feature_id"]: r["discovery_direction"] for r in rows(SET / "annotation.csv")}
    for g in genes:
        g["discovery_direction"] = directions.get(g["feature_id"], "")
    assert len(genes) == len({g["feature_id"] for g in genes}) == 56
    csv_out(OUT / "frozen_genes.csv", genes)
    sample = rows(PUBLIC / "HBEC_sample_decode.csv")
    author = rows(SRDF, "\t")
    assert len(sample) == len(author) == 43
    for s, a in zip(sample, author):
        assert s["assay"] == a["Sample name"].replace(" ", "_")
        assert s["individual"] == a["Exp. ID"]
        assert [s[k] for k in ["post_ICS", "polyIC", "imiquimod", "T2high"]] == list(a.values())[2:]
    main = [s for s in sample if s["imiquimod"] == "0"]
    ids = sorted({s["individual"] for s in main})
    assert len(main) == 40 and len(ids) == 10
    for donor in ids:
        assert {(s["post_ICS"], s["polyIC"]) for s in main if s["individual"] == donor} == set(itertools.product("01", repeat=2))
    csv_out(OUT / "HBEC_samples.csv", main)
    paths = [A549, HBEC, SRDF, PUBLIC / "HBEC_sample_decode.csv",
             PUBLIC / "imported/PXD029135_PXD029135_community_annotated.sdrf.tsv",
             PUBLIC / "imported/PXD063431_project_0.json", PUBLIC / "imported/PXD029135_project_0.json",
             SET / "unselected_protein/frozen_genes.csv", SET / "annotation.csv"]
    json_out(OUT / "analysis_freeze.json", dict(utc=utc(), prior=previous,
        inputs=[record(p) for p in paths], source_code=[record(HERE / n) for n in CODE],
        genes=record(OUT / "frozen_genes.csv"), samples=record(OUT / "HBEC_samples.csv"),
        snapshot=record(OUT / "rgo_before_epithelial.md"),
        timing="Prior ASM/HTPC effects known; only first noncandidate epithelial rows/header and metadata inspected; no new candidate abundance inspected",
        family_sizes={"A549_primary":56, "HBEC_primary":56, "HBEC_secondary":112},
        online_model_calls=0, author_contact=False, PXD055968="skipped_by_user"))
    print("Frozen 56 positions and two epithelial datasets before candidate extraction")


def check_freeze():
    data = json.loads((OUT / "analysis_freeze.json").read_text())
    for item in data["inputs"] + data["source_code"] + [data[k] for k in ["genes", "samples", "snapshot"]]:
        assert record(ROOT / item["path"]) == item, item["path"]
    return data


def numeric(s):
    if s.strip().lower() in {"", "na", "nan", "null"}:
        return None
    x = float(s)
    assert math.isfinite(x), s
    return x


def adjustment(values, method):
    p = np.asarray(values, dtype=float)
    order = np.argsort(p, kind="stable")
    if method == "holm":
        adjusted = np.maximum.accumulate(p[order] * np.arange(len(p), 0, -1))
    else:
        adjusted = np.minimum.accumulate((p[order] * len(p) / np.arange(1, len(p) + 1))[::-1])[::-1]
    result = np.ones(len(p))
    result[order] = np.minimum(adjusted, 1.)
    return result.tolist()


def blank(n1=0, n2=0):
    return dict(status="insufficient_observations", n_control=n1, n_treated=n2, n_pairs=0,
        effect="", se="", df="", ci_low="", ci_high="", pvalue=1., exact_pvalue=1.,
        positive_units=0, negative_units=0)


def welch(control, treated):
    c, t = np.asarray(control), np.asarray(treated)
    result = blank(len(c), len(t))
    if min(len(c), len(t)) < 3:
        return result
    var_c, var_t = c.var(ddof=1) / len(c), t.var(ddof=1) / len(t)
    se = float(np.sqrt(var_c + var_t))
    if se == 0:
        result["status"] = "zero_variance_unestimable"
        return result
    df = float((var_c + var_t)**2 / (var_c**2 / (len(c)-1) + var_t**2 / (len(t)-1)))
    effect = float(t.mean() - c.mean())
    width = float(stats.t.ppf(.975, df) * se)
    all_values = np.r_[c, t]
    permutation = []
    for indexes in itertools.combinations(range(len(all_values)), len(t)):
        mask = np.zeros(len(all_values), dtype=bool)
        mask[list(indexes)] = True
        permutation.append(float(all_values[mask].mean() - all_values[~mask].mean()))
    result.update(status="estimable", effect=effect, se=se, df=df, ci_low=effect-width,
        ci_high=effect+width, pvalue=float(2 * stats.t.sf(abs(effect / se), df)),
        exact_pvalue=float(np.mean(np.abs(permutation) >= abs(effect) - 1e-12)))
    return result


def paired(values):
    x = np.asarray(values)
    result = blank()
    result.update(n_control=len(x), n_treated=len(x), n_pairs=len(x),
                  positive_units=int(sum(x > 0)), negative_units=int(sum(x < 0)))
    if len(x) < 3:
        return result
    se = float(x.std(ddof=1) / np.sqrt(len(x)))
    if se == 0:
        result["status"] = "zero_variance_unestimable"
        return result
    effect = float(x.mean())
    width = float(stats.t.ppf(.975, len(x)-1) * se)
    signs = np.asarray(list(itertools.product([-1, 1], repeat=len(x))))
    result.update(status="estimable", effect=effect, se=se, df=len(x)-1, ci_low=effect-width,
        ci_high=effect+width, pvalue=float(2 * stats.t.sf(abs(effect / se), len(x)-1)),
        exact_pvalue=float(np.mean(np.abs(signs @ x / len(x)) >= abs(effect) - 1e-12)))
    return result


def a549_table():
    raw = rows(A549, "\t")
    columns = [f"A549_{condition}_{i}" for condition in ["NT", "dexa"] for i in [1,3,4,5]]
    data = []
    for line, r in enumerate(raw, 2):
        q, unique = numeric(r["Exp q-value Combined"]), numeric(r["Number of Unique Peptides"])
        qc = r["Contaminant"].strip().lower() == "false" and q is not None and q <= .01 and unique is not None and unique >= 1
        v = [numeric(r[c]) for c in columns]
        assert all(x is None or x >= 0 for x in v)
        data.append(dict(dataset="A549", source_row=line, protein_ids=r["Accession"],
            gene=r["Gene Name"].strip(), qc=qc, reason="pass" if qc else "contaminant_qvalue_or_unique_peptides",
            raw=v, values=[math.log2(x) if x is not None and x > 0 else None for x in v],
            unique_peptides=unique, identification_qvalue=q))
    reference = [d["values"] for d in data if d["qc"] and all(x is not None for x in d["values"])]
    assert len(reference) > 100
    medians = np.median(reference, axis=0)
    offsets = medians - medians.mean()
    for d in data:
        d["normalized"] = [x-float(offsets[i]) if x is not None else None for i, x in enumerate(d["values"])]
    return data, columns, dict(reference_rows=len(reference), medians=medians.tolist(), offsets=offsets.tolist())


def hbec_table():
    raw = rows(HBEC, "\t")
    samples = rows(OUT / "HBEC_samples.csv")
    columns = [s["assay"] for s in samples]
    data = []
    for line, r in enumerate(raw, 2):
        tokens = r["Protein.IDs"].split(";")
        clean = not any(t.startswith(("CON__", "CONTAM_", "REV__")) for t in tokens)
        parts = [p.strip() for p in r["Fasta.headers"].split(";") if p.strip()]
        names, parsed = set(), True
        for part in parts:
            match = re.match(r"^NX_\S+\s+\S+\s+(\S+)\s+", part)
            if not match:
                parsed = False
            else:
                names.add(match[1])
        consistent = parsed and len(names) == 1 and len(parts) > 0
        qc = clean and consistent
        reason = "contaminant_or_reverse" if not clean else "missing_or_mixed_gene_annotation" if not consistent else "pass"
        data.append(dict(dataset="HBEC", source_row=line, protein_ids=r["Protein.IDs"],
            gene=next(iter(names)) if consistent else "|".join(sorted(names)), qc=qc, reason=reason,
            raw=[numeric(r[c]) for c in columns], values=[numeric(r[c]) for c in columns]))
    return data, samples


def hbec_effects(data, samples, contrast):
    individuals = sorted({s["individual"] for s in samples})
    values = {d:{} for d in individuals}
    for s, val in zip(samples, data["values"]):
        values[s["individual"]][int(s["post_ICS"]), int(s["polyIC"])] = val
    effects = {}
    for d, v in values.items():
        keys = [(0,0),(1,0)] if contrast == CONTRASTS[0] else [(0,1),(1,1)] if contrast == CONTRASTS[1] else list(itertools.product(range(2), repeat=2))
        if all(v[k] is not None for k in keys):
            effects[d] = v[1,0]-v[0,0] if contrast == CONTRASTS[0] else v[1,1]-v[0,1] if contrast == CONTRASTS[1] else v[1,1]-v[0,1]-v[1,0]+v[0,0]
    return effects


def analyze():
    check_freeze()
    if (OUT / "run.json").exists():
        raise ValueError("Analysis already completed")
    genes = rows(OUT / "frozen_genes.csv")
    a, acols, normalization = a549_table()
    h, samples = hbec_table()
    csv_out(OUT / "A549_normalization.csv", [dict(column=c, reference_rows=normalization["reference_rows"],
        median=m, offset=o) for c,m,o in zip(acols, normalization["medians"], normalization["offsets"])])
    qc = [dict(dataset=d["dataset"], source_row=d["source_row"], protein_ids=d["protein_ids"],
        gene=d["gene"], qc_pass=d["qc"], reason=d["reason"]) for d in a+h]
    csv_out(OUT / "protein_row_qc.csv", qc)
    global_results, full_index = [], {}
    for d in a+h:
        if not d["qc"]:
            continue
        for contrast in ["DEX_48h"] if d["dataset"] == "A549" else CONTRASTS:
            result = welch([x for x in d["normalized"][:4] if x is not None], [x for x in d["normalized"][4:] if x is not None]) if d["dataset"] == "A549" else paired(list(hbec_effects(d, samples, contrast).values()))
            r = dict(dataset=d["dataset"], source_row=d["source_row"], protein_ids=d["protein_ids"], gene=d["gene"], contrast=contrast, **result)
            global_results.append(r)
            full_index[d["dataset"], d["source_row"], contrast] = r
    for dataset in ["A549", "HBEC"]:
        subset = [r for r in global_results if r["dataset"] == dataset]
        for r, p in zip(subset, adjustment([r["pvalue"] for r in subset], "BH")):
            r["global_BH"] = p
            r["global_family_size"] = len(subset)
    csv_out(OUT / "all_protein_results.csv", global_results)
    detection, measurements, effects, results, sensitivity, stratified = [], [], [], [], [], []
    t2 = {s["individual"]: s["T2high"] for s in samples}
    for dataset, table in [("A549",a),("HBEC",h)]:
        for g in genes:
            alias = ALIASES.get(g["symbol"], {g["symbol"]})
            matched = [d for d in table if d["qc"] and d["gene"] in alias]
            candidates = [d for d in table if d["gene"] in alias]
            identity = "unique_group" if len(matched)==1 else "ambiguous_groups" if matched else "excluded_by_QC" if candidates else "not_detected"
            detection.append(dict(dataset=dataset, **g, identity_status=identity, qc_matches=len(matched),
                matched_rows="|".join(str(d["source_row"]) for d in matched),
                matched_protein_ids="|".join(d["protein_ids"] for d in matched),
                excluded_rows="|".join(str(d["source_row"]) for d in candidates if not d["qc"])))
            d = matched[0] if len(matched)==1 else None
            if d:
                for i, (raw, val) in enumerate(zip(d["raw"], d["normalized"] if dataset == "A549" else d["values"])):
                    column = acols[i] if dataset == "A549" else samples[i]["assay"]
                    measurements.append(dict(dataset=dataset, **g, source_row=d["source_row"], protein_ids=d["protein_ids"],
                        column=column, raw_value=raw if raw is not None else "", analysis_value=val if val is not None else "",
                        individual="" if dataset == "A549" else samples[i]["individual"],
                        scale="median_centered_log2_intensity" if dataset == "A549" else "supplied_median_normalized_units"))
            for contrast in ["DEX_48h"] if dataset == "A549" else CONTRASTS:
                family = "A549_primary_56" if dataset == "A549" else "HBEC_primary_56" if contrast == CONTRASTS[0] else "HBEC_secondary_112"
                if d:
                    base = full_index[dataset,d["source_row"],contrast]
                    r = {k:base[k] for k in blank()}
                    global_bh = base["global_BH"]
                else:
                    r, global_bh = blank(), ""
                    r["status"] = identity
                r.update(dataset=dataset, **g, contrast=contrast, family=family,
                    source_row=d["source_row"] if d else "", protein_ids=d["protein_ids"] if d else "",
                    global_BH=global_bh, direction_matches=(int(np.sign(r["effect"])) == int(g["discovery_direction"])) if r["effect"] != "" and g["discovery_direction"] else "")
                results.append(r)
                if dataset == "A549":
                    unscaled = welch([x for x in d["values"][:4] if x is not None], [x for x in d["values"][4:] if x is not None]) if d else blank()
                    if not d: unscaled["status"] = identity
                    sensitivity.append(dict(dataset=dataset, **g, contrast=contrast, kind="original_log2_no_extra_normalization", parameter="all_wells", **unscaled))
                else:
                    local = hbec_effects(d,samples,contrast) if d else {}
                    for donor in sorted(t2):
                        effects.append(dict(dataset=dataset, **g, contrast=contrast, individual=donor, T2high=t2[donor],
                            effect=local.get(donor,""), status="paired" if donor in local else "missing_pair_or_identity"))
                    for donor in local:
                        remaining = [x for key,x in local.items() if key!=donor]
                        sensitivity.append(dict(dataset=dataset, **g, contrast=contrast, kind="leave_one_individual", parameter=donor, **paired(remaining)))
                    for phenotype in ["0","1"]:
                        vals = [v for donor,v in local.items() if t2[donor]==phenotype]
                        stratified.append(dict(dataset=dataset, **g, contrast=contrast, T2high=phenotype, n_individuals=len(vals),
                            effect=float(np.mean(vals)) if vals else "", scope="descriptive_only_no_group_test"))
    for family in sorted({r["family"] for r in results}):
        subset = [r for r in results if r["family"]==family]
        for field, target in [("pvalue","holm"),("exact_pvalue","exact_holm")]:
            for r,p in zip(subset, adjustment([r[field] for r in subset], "holm")):
                r[target] = p
    original = [r for r in sensitivity if r["dataset"]=="A549"]
    for r,p in zip(original, adjustment([r["pvalue"] for r in original],"holm")):
        r["holm_sensitivity_56"] = p
    for r in sensitivity:
        r.setdefault("holm_sensitivity_56", "")
    for name,data in [("detection.csv",detection),("measurements.csv",measurements),("individual_effects.csv",effects),
                      ("candidate_results.csv",results),("sensitivity.csv",sensitivity),("T2_descriptive.csv",stratified)]:
        csv_out(OUT/name, data)
    summary = []
    for dataset,contrast in [("A549","DEX_48h")]+[("HBEC",c) for c in CONTRASTS]:
        subset = [r for r in results if r["dataset"]==dataset and r["contrast"]==contrast]
        global_subset = [r for r in global_results if r["dataset"]==dataset and r["contrast"]==contrast]
        summary.append(dict(dataset=dataset, contrast=contrast, frozen_positions=len(subset),
            unique_groups=sum(r["dataset"]==dataset and r["identity_status"]=="unique_group" for r in detection),
            estimable=sum(r["status"]=="estimable" for r in subset), holm_pass=sum(r["holm"]<.05 for r in subset),
            exact_holm_pass=sum(r["exact_holm"]<.05 for r in subset),
            global_QC_tests=len(global_subset), global_estimable=sum(r["status"]=="estimable" for r in global_subset),
            global_BH_pass=sum(r["global_BH"]<.05 for r in global_subset),
            scope="A549 culture wells, non-ASM" if dataset=="A549" else "HBEC clinical before/after association, non-ASM"))
    csv_out(OUT / "summary.csv", summary)
    json_out(OUT / "run.json", dict(status="completed", utc=utc(), script=record(Path(__file__)),
        raw_rows={"A549":len(a),"HBEC":len(h)}, QC_counts={key:dict(Counter(d["reason"] for d in table)) for key,table in [("A549",a),("HBEC",h)]},
        candidate_tests=len(results), measurements=len(measurements), individual_positions=len(effects),
        global_tests=len(global_results), family_sizes=[56,56,112],
        python=sys.version, numpy=np.__version__, scipy=__import__("scipy").__version__, online_model_calls=0))
    print(json.dumps(summary, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("action", choices=["freeze", "analyze"])
    globals()[p.parse_args().action]()
