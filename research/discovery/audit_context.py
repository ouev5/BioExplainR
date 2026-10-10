"""Independent numerical audit of factorial follow-up (does not refit DESeq2)."""
import argparse
import csv
import gzip
import hashlib
import itertools
import json
from pathlib import Path

import numpy as np
from scipy import stats


def table(path):
    with path.open(encoding="utf-8-sig", newline="") as f:
        return list(csv.DictReader(f))


def check(a, b):
    assert np.isclose(float(a), float(b), rtol=1e-9, atol=1e-12), (a, b)


def adjust(p, method):
    p = np.asarray(p); order = np.argsort(p); n = len(p)
    values = (np.maximum.accumulate(p[order] * np.arange(n, 0, -1)) if method == "holm"
              else np.minimum.accumulate((p[order] * n / np.arange(1, n+1))[::-1])[::-1])
    ans = np.empty(n); ans[order] = np.minimum(1, values); return ans


def audit(out):
    manifest = json.loads((out / "input_manifest.json").read_text())
    for item in manifest["inputs"]:
        path = out / item["path"]
        assert path.stat().st_size == item["bytes"] and hashlib.sha256(path.read_bytes()).hexdigest() == item["sha256"]
    with gzip.open(out / "counts.txt.gz", "rt") as f:
        raw = list(csv.DictReader(f, delimiter="\t"))
    features = {r[next(iter(r))].split(".")[0]: r for r in raw}
    assert len(features) == len(raw)
    samples = table(out / "samples.csv")
    assert len(samples) == 31 and len({s["sample"] for s in samples}) == 31
    assert len({s["donor"] for s in samples}) == 4
    sf = {r["sample"]: float(r["size_factor"]) for r in table(out / "size_factors.csv")}
    measures = table(out / "gene_measurements.csv")
    assert len(measures) == 124
    by_cell = {}
    for r in measures:
        sample = next(s for s in samples if s["sample"] == r["sample"])
        count = float(features[r["feature_id"]][sample["count_column"]])
        check(r["raw_count"], count); check(r["normalized_count"], count / sf[r["sample"]])
        value = np.log2(count/sf[r["sample"]] + 1); check(r["log2_count_plus_one"], value)
        key = (r["symbol"], r["donor"], r["kd"], r["bud"], r["tnf"])
        assert key not in by_cell; by_cell[key] = value
    recomputed = {}
    for g in sorted({r["symbol"] for r in measures}):
        for d in sorted({s["donor"] for s in samples}):
            v = lambda k, b, t: by_cell.get((g, d, k, b, t), np.nan)
            e = {"bud_NT_noTNF": v("NT", "yes", "no")-v("NT", "no", "no"),
                 "bud_NT_TNF": v("NT", "yes", "yes")-v("NT", "no", "yes"),
                 "bud_KD_noTNF": v("KD", "yes", "no")-v("KD", "no", "no"),
                 "bud_KD_TNF": v("KD", "yes", "yes")-v("KD", "no", "yes")}
            e.update(bud_tnf_NT=e["bud_NT_TNF"]-e["bud_NT_noTNF"],
                     bud_kd_noTNF=e["bud_KD_noTNF"]-e["bud_NT_noTNF"],
                     three_way=e["bud_KD_TNF"]-e["bud_KD_noTNF"]-e["bud_NT_TNF"]+e["bud_NT_noTNF"])
            recomputed.update({(g, d, k): x for k, x in e.items()})
    donor = table(out / "donor_effects.csv")
    assert len(donor) == len(recomputed) == 112
    for r in donor:
        x = recomputed[(r["symbol"], r["donor"], r["contrast"])]
        if np.isnan(x): assert r["value"] == ""
        else: check(r["value"], x)
    sensitivity = table(out / "donor_sensitivity.csv")
    assert len(sensitivity) == 28
    for r in sensitivity:
        x = np.array([v for (g, d, c), v in recomputed.items() if g == r["symbol"] and c == r["contrast"] and np.isfinite(v)])
        n = len(x); mean = np.mean(x); se = stats.sem(x); width = stats.t.ppf(.975, n-1)*se
        flip = [np.mean(x*np.array(s)) for s in itertools.product([-1, 1], repeat=n)]
        for key, val in {"n_donors": n, "mean": mean, "ci_low": mean-width, "ci_high": mean+width,
                         "pvalue": stats.ttest_1samp(x, 0).pvalue,
                         "sign_flip_p": np.mean(np.abs(flip) >= abs(mean)-1e-12),
                         "permutations": 2**n, "positive_donors": sum(x > 0), "negative_donors": sum(x < 0)}.items():
            check(r[key], val)
    model = table(out / "model_results.csv")
    assert len(model) == 32
    for r in model:
        lfc, se = float(r["log2FoldChange"]), float(r["lfcSE"])
        check(r["stat"], lfc/se); check(r["pvalue"], 2*stats.norm.sf(abs(lfc/se)))
        check(r["ci_low"], lfc-stats.norm.ppf(.975)*se); check(r["ci_high"], lfc+stats.norm.ppf(.975)*se)
    for rows in [model, sensitivity]:
        selected = [r for r in rows if r["holm_candidate_interactions"]]
        assert len(selected) == 3 and all(r["symbol"] == "SPARCL1" for r in selected)
        for r, val in zip(selected, adjust([float(r["pvalue"]) for r in selected], "holm")):
            check(r["holm_candidate_interactions"], val)
    genome_count = 0
    for path in sorted(out.glob("genome_*.csv")):
        rows = table(path); selected = [r for r in rows if r["padj"]]
        assert len({r["feature_id"] for r in rows}) == len(rows)
        for r, val in zip(selected, adjust([float(r["pvalue"]) for r in selected], "bh")):
            check(r["padj"], val)
        genome_count += len(selected)
    result = {"status": "pass", "raw_features": len(raw), "libraries": 31, "donors": 4,
              "measurements": 124, "donor_effects": 112, "donor_tests": 28, "model_contrasts": 32,
              "genome_bh_values": genome_count,
              "scope": "Raw candidate counts, applied R size factors, donor effects/t/CI/sign flips, Wald algebra and BH/Holm; not an independent DESeq2 refit"}
    (out / "audit.json").write_text(json.dumps(result, indent=2)+"\n")
    files = [{"path": p.name, "bytes": p.stat().st_size, "sha256": hashlib.sha256(p.read_bytes()).hexdigest()}
             for p in sorted(out.iterdir()) if p.is_file() and p.name != "files_manifest.json"]
    (out / "files_manifest.json").write_text(json.dumps({"files": files}, indent=2)+"\n")
    print(json.dumps(result, indent=2))
    return result


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__); parser.add_argument("output", type=Path)
    audit(parser.parse_args().output)
