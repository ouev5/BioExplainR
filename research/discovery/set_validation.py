"""Freeze and analyze the original 54-gene set using six adult paired donors."""
import argparse
import csv
import gzip
import io
import itertools
import json
from pathlib import Path

import numpy as np
from scipy import stats

from validation_sources import ROOT, HERE, record, utc, fetch, csv_out, json_out

OLD = ROOT / "research/results/discovery_validation_v2"
DISCOVERY = ROOT / "research/results/discovery_stable_response_v1"
HGNC = "https://storage.googleapis.com/public-download-files/hgnc/tsv/tsv/hgnc_complete_set.txt"
CONTRASTS = ["GC_control", "GC_perturbed", "GC_x_perturbation", "perturbation_vehicle"]


def rows(path):
    with path.open(encoding="utf-8-sig", newline="") as stream:
        return list(csv.DictReader(stream))


def adjust(p):
    p = np.asarray(p, dtype=float)
    order = np.argsort(p, kind="stable")
    result = np.ones(len(p))
    result[order] = np.minimum(1, np.maximum.accumulate(p[order] * np.arange(len(p), 0, -1)))
    return result


def estimate(values):
    x = np.asarray(values, dtype=float)
    se = float(np.std(x, ddof=1) / np.sqrt(len(x)))
    effect = float(np.mean(x))
    assert len(x) >= 2 and se > 0
    width = float(stats.t.ppf(.975, len(x) - 1) * se)
    signs = np.asarray(list(itertools.product([-1, 1], repeat=len(x))))
    exact = float(np.mean(np.abs(signs @ x / len(x)) >= abs(effect) - 1e-12))
    return dict(n_donors=len(x), effect=effect, se=se, ci_low=effect-width,
                ci_high=effect+width, pvalue=float(stats.ttest_1samp(x, 0).pvalue),
                exact_pvalue=exact, positive_donors=int(sum(x > 0)), negative_donors=int(sum(x < 0)))


def freeze(out):
    from seal_validation import verify
    verify()
    out.mkdir(exist_ok=False)
    (out / "sources").mkdir()
    (out / "rgo_before_set_validation.md").write_bytes((ROOT / "rgo.md").read_bytes())
    genes = [dict(rank=i+1, **r) for i, r in enumerate(rows(DISCOVERY / "stable_response_screen.csv"))
             if r["priority_pass"] == "TRUE"]
    # rank is original complete screen position; expose compact set rank separately.
    for i, r in enumerate(genes, 1):
        r["set_rank"] = i
    assert len(genes) == 54 and len({r["feature_id"] for r in genes}) == 54
    csv_out(out / "frozen_set.csv", genes)
    sample = [r for r in rows(OLD / "expression_sample_map.csv") if r["study"] == "GSE130715"]
    assert len(sample) == 24 and len({r["donor"] for r in sample}) == 6
    csv_out(out / "samples.csv", sample)
    input_paths = [DISCOVERY / "stable_response_screen.csv", OLD / "expression_sample_map.csv",
                   OLD / "sources/GSE130715_tpm.txt.gz", OLD / "sources/GSE130715_counts.txt.gz",
                   OLD / "sources/GSE130715_metadata.txt", ROOT / "docs/biology_validation_v2/validation_manifest.json"]
    script_paths = [HERE / name for name in ["SET_VALIDATION_PROTOCOL.md", "set_validation.py", "set_validation_models.R", "audit_set_validation.py"]]
    json_out(out / "analysis_freeze.json", dict(utc=utc(), inputs=[record(p) for p in input_paths],
        scripts=[record(p) for p in script_paths], set=record(out / "frozen_set.csv"), samples=record(out / "samples.csv"),
        hgnc_url=HGNC, contrasts=CONTRASTS, primary_family=54, secondary_family=162,
        timing="Known prior six-candidate results; new 54-gene extraction not performed; exploratory expansion"))
    rec = fetch(HGNC, out / "sources/hgnc_complete_set.txt", timeout=90)
    json_out(out / "annotation_acquisition.json", dict(utc=utc(), records=[rec]))
    assert rec["status"] == "retrieved", rec
    annotation = list(csv.DictReader(
        io.StringIO((out / "sources/hgnc_complete_set.txt").read_text()), delimiter="\t"))
    mapping = []
    for g in genes:
        matches = [a for a in annotation if a["ensembl_gene_id"] == g["feature_id"] and a["status"] == "Approved"]
        ids = sorted({a["entrez_id"] for a in matches if a["entrez_id"]})
        symbols = sorted({a["symbol"] for a in matches})
        mapping.append(dict(set_rank=g["set_rank"], feature_id=g["feature_id"],
            symbol="|".join(symbols), entrez_id=ids[0] if len(ids) == 1 else "",
            discovery_direction=g["direction"], status="mapped" if len(ids) == 1 else "missing_or_ambiguous",
            hgnc_ids="|".join(a["hgnc_id"] for a in matches)))
    for r in mapping:
        if r["entrez_id"] and sum(s["entrez_id"] == r["entrez_id"] for s in mapping) > 1:
            r["status"] = "shared_entrez_ambiguous"
    csv_out(out / "annotation.csv", mapping)
    json_out(out / "annotation_freeze.json", dict(utc=utc(), annotation=record(out / "annotation.csv"),
        original_hgnc=record(out / "sources/hgnc_complete_set.txt"), rule="Unique approved HGNC Ensembl-to-Entrez; ambiguous and missing retain family slot"))
    print("54-gene analysis and annotation frozen", flush=True)


def measure(out):
    frozen = json.loads((out / "analysis_freeze.json").read_text())
    for rec in frozen["inputs"] + frozen["scripts"]:
        assert record(ROOT / rec["path"]) == rec, rec["path"]
    mapping = rows(out / "annotation.csv")
    assert record(out / "annotation.csv") == json.loads((out / "annotation_freeze.json").read_text())["annotation"]
    samples = rows(out / "samples.csv")
    text = gzip.decompress((OLD / "sources/GSE130715_tpm.txt.gz").read_bytes()).decode("utf-8-sig")
    table = list(csv.DictReader(io.StringIO(text), delimiter="\t"))
    key = next(iter(table[0])); index = {r[key]: r for r in table}
    assert len(index) == len(table) == 28395
    columns = {s["sample"]: [k for k in table[0] if s["sample_key"] in k] for s in samples}
    assert all(len(c) == 1 for c in columns.values())
    measurements, effects, results, sensitivity = [], [], [], []
    for gene in mapping:
        values = {}
        measurable = gene["status"] == "mapped" and gene["entrez_id"] in index
        if measurable:
            for s in samples:
                raw = float(index[gene["entrez_id"]][columns[s["sample"]][0]])
                assert np.isfinite(raw) and raw >= 0
                values.setdefault(s["donor"], {})[int(s["gc"]), int(s["perturbation"])] = raw
                measurements.append(dict(feature_id=gene["feature_id"], symbol=gene["symbol"], entrez_id=gene["entrez_id"],
                    sample=s["sample"], donor=s["donor"], gc=s["gc"], kd=s["perturbation"],
                    raw_TPM=raw, log2_TPM_plus1=float(np.log2(raw+1)), source_column=columns[s["sample"]][0]))
            assert all(len(v) == 4 for v in values.values())
        local = {c: [] for c in CONTRASTS}
        for donor, raw in sorted(values.items()):
            v = {k: np.log2(x+1) for k, x in raw.items()}
            x = [v[1,0]-v[0,0], v[1,1]-v[0,1], v[1,1]-v[0,1]-v[1,0]+v[0,0], v[0,1]-v[0,0]]
            for c, effect in zip(CONTRASTS, x):
                local[c].append(float(effect))
                effects.append(dict(feature_id=gene["feature_id"], symbol=gene["symbol"], donor=donor, contrast=c, effect=float(effect)))
        for c in CONTRASTS:
            base = dict(feature_id=gene["feature_id"], symbol=gene["symbol"], entrez_id=gene["entrez_id"],
                set_rank=gene["set_rank"], discovery_direction=gene["discovery_direction"], contrast=c,
                family="primary_54" if c == "GC_control" else "secondary_162",
                status="estimable" if measurable else "missing_annotation_or_input")
            if measurable:
                base.update(estimate(local[c]))
            else:
                base.update({k: "" for k in ["n_donors", "effect", "se", "ci_low", "ci_high", "positive_donors", "negative_donors"]})
                base.update(pvalue=1., exact_pvalue=1.)
            results.append(base)
        if measurable:
            for pseudocount in [.1, .5, 1.]:
                x = [float(np.log2(v[1,0]+pseudocount)-np.log2(v[0,0]+pseudocount)) for v in values.values()]
                sensitivity.append(dict(feature_id=gene["feature_id"], symbol=gene["symbol"], kind="pseudocount",
                    parameter=pseudocount, **estimate(x), direction_matches=np.sign(np.mean(x)) == int(gene["discovery_direction"])))
            for donor in sorted(values):
                x = [float(np.log2(v[1,0]+1)-np.log2(v[0,0]+1)) for d, v in values.items() if d != donor]
                sensitivity.append(dict(feature_id=gene["feature_id"], symbol=gene["symbol"], kind="leave_one_donor",
                    parameter=donor, **estimate(x), direction_matches=np.sign(np.mean(x)) == int(gene["discovery_direction"])))
    for family in ["primary_54", "secondary_162"]:
        subset = [r for r in results if r["family"] == family]
        for r, p, e in zip(subset, adjust([r["pvalue"] for r in subset]), adjust([r["exact_pvalue"] for r in subset])):
            r.update(holm=float(p), exact_holm=float(e))
    csv_out(out / "tpm_measurements.csv", measurements)
    csv_out(out / "tpm_donor_effects.csv", effects)
    csv_out(out / "tpm_results.csv", results)
    csv_out(out / "tpm_sensitivity.csv", sensitivity)
    json_out(out / "tpm_run.json", dict(status="completed", utc=utc(), script=record(Path(__file__)),
        original_genes=28395, measurements=len(measurements), comparisons=len(results),
        mapped_genes=len(measurements)//24, family_sizes=[54, 162], donors=6, online_model_calls=0))
    print(json.dumps({"measurements": len(measurements), "mapped": len(measurements)//24, "tests": len(results)}))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=["freeze", "measure"])
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    globals()[args.action](args.output.resolve())
