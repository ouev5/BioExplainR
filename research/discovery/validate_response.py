"""External paired-donor tests for the already frozen context-retained genes."""
import csv
import gzip
import hashlib
import itertools
import json
import sys
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path

import numpy as np
from scipy import stats

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "research/results/discovery_donors_v1"


def rows(path):
    with Path(path).open(newline="") as stream:
        return list(csv.DictReader(stream))


def csv_out(path, values, fields=None):
    with Path(path).open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, fieldnames=fields or list(values[0]))
        writer.writeheader()
        writer.writerows(values)


def sha(path):
    h = hashlib.sha256()
    with Path(path).open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def write_json(path, data):
    Path(path).write_text(json.dumps(data, indent=2, ensure_ascii=False, allow_nan=False) + "\n")


def holm(ps):
    p = np.asarray(ps); order = np.argsort(p)
    adjusted = np.minimum(1, np.maximum.accumulate(p[order] * np.arange(len(p), 0, -1)))
    result = np.empty(len(p)); result[order] = adjusted
    return result


def one_sample(x):
    x = np.asarray(x); n = len(x)
    mean = float(x.mean()); width = float(stats.t.ppf(.975, n - 1) * stats.sem(x))
    signs = np.array(list(itertools.product([-1, 1], repeat=n)))
    perm = signs @ x / n
    return {"effect": mean, "ci_low": mean - width, "ci_high": mean + width,
            "pvalue": float(stats.ttest_1samp(x, 0).pvalue),
            "exact_p": float(np.mean(np.abs(perm) >= abs(mean) - 1e-12)),
            "permutations": len(perm), "n_a": n, "n_b": 0,
            "positive_donors": int(sum(x > 0)), "negative_donors": int(sum(x < 0))}


def between(a, b):
    a, b = np.asarray(a), np.asarray(b); n, m = len(a), len(b)
    effect = float(a.mean() - b.mean()); va, vb = a.var(ddof=1) / n, b.var(ddof=1) / m
    df = (va + vb) ** 2 / (va ** 2 / (n - 1) + vb ** 2 / (m - 1))
    width = float(stats.t.ppf(.975, df) * np.sqrt(va + vb))
    x = np.r_[a, b]; perm = []
    for indexes in itertools.combinations(range(n + m), n):
        mask = np.zeros(n + m, dtype=bool); mask[list(indexes)] = True
        perm.append(x[mask].mean() - x[~mask].mean())
    return {"effect": effect, "ci_low": effect - width, "ci_high": effect + width,
            "pvalue": float(stats.ttest_ind(a, b, equal_var=False).pvalue),
            "exact_p": float(np.mean(np.abs(perm) >= abs(effect) - 1e-12)),
            "permutations": len(perm), "n_a": n, "n_b": m,
            "positive_donors": "", "negative_donors": ""}


def run(out):
    if (out / "external_results.csv").exists():
        raise ValueError("Refusing to overwrite external results")
    frozen = json.loads((out / "candidate_freeze.json").read_text())
    assert sha(out / "frozen_candidates.csv") == frozen["candidate_file_sha256"]
    candidates = rows(out / "frozen_candidates.csv"); ids = {r["feature_id"] for r in candidates}
    discovery = rows(ROOT / "research/results/discovery_context_v1/samples.csv")
    exclude = {r["donor"] for r in discovery}
    all_md = rows(SOURCE / "samples.csv"); md = [r for r in all_md if r["donor"] not in exclude]
    assert len(md) == 26 and len({r["donor"] for r in md}) == 13
    assert len({r["donor"] for r in md if r["disease"] == "non_asthma"}) == 4
    assert not (exclude & {r["donor"] for r in md})
    write_json(out / "external_analysis_freeze.json", {
        "frozen_utc": datetime.now(timezone.utc).isoformat(), "stage": "before selected TPM extraction",
        "scripts": [{"path": str(Path(__file__).relative_to(ROOT)), "sha256": sha(__file__)}],
        "candidate_sha256": sha(out / "frozen_candidates.csv"),
        "tpm_sha256": sha(SOURCE / "tpm.txt.gz"), "sample_mapping_sha256": sha(SOURCE / "samples.csv"),
        "excluded_overlapping_donors": sorted({r["donor"] for r in all_md if r["donor"] in exclude}),
        "independent_units": 13, "candidate_genes": len(ids), "tests_in_family": len(ids) * 4})
    csv_out(out / "external_samples.csv", md)
    sums = defaultdict(float); annotations = defaultdict(set); transcript = []; seen = set(); total = 0
    with gzip.open(SOURCE / "tpm.txt.gz", "rt") as stream:
        header = stream.readline().split()
        assert header == ["target_id", "sample", "est_counts", "tpm", "eff_len", "len", "condition", "ens_gene", "ext_gene"]
        for line in stream:
            total += 1; v = line.split()
            gene = v[7].split(".")[0]
            if gene not in ids:
                continue
            assert len(v) == 9
            key = (v[0], v[1]); assert key not in seen; seen.add(key)
            value = float(v[3]); assert np.isfinite(value) and value >= 0
            sums[(gene, v[1])] += value; annotations[gene].add(v[8])
            transcript.append(dict(zip(header, v)))
    csv_out(out / "external_transcript_measurements.csv", transcript)
    annotation = [{"feature_id": c["feature_id"], "symbols": "|".join(sorted(annotations[c["feature_id"]]))}
                  for c in candidates]
    csv_out(out / "candidate_annotation.csv", annotation)
    measurements = []; donor_effects = []; results = []; sensitivity = []
    for c in candidates:
        g = c["feature_id"]; symbol = "|".join(sorted(annotations[g]))
        if not annotations[g]:
            for name in ["non_asthma", "fatal_asthma", "all13", "fatal_asthma_minus_non_asthma_response"]:
                contrast = name if name.endswith("response") else name + "_BUD_vs_vehicle"
                results.append({"feature_id": g, "symbol": "", "contrast": contrast,
                    "effect": "", "ci_low": "", "ci_high": "", "pvalue": 1.0, "exact_p": 1.0,
                    "permutations": 0, "n_a": 0, "n_b": 0, "positive_donors": "", "negative_donors": "",
                    "status": "gene_absent_from_external_annotation_not_estimable"})
            continue
        for s in md:
            assert (g, s["tpm_column"]) in sums
            tpm = sums[(g, s["tpm_column"])]
            measurements.append({"feature_id": g, "symbol": symbol, **s, "tpm": tpm,
                                 "log2_tpm_plus_one": float(np.log2(tpm + 1))})
        effects = []
        for d in sorted({s["donor"] for s in md}):
            pair = [s for s in md if s["donor"] == d]
            assert len(pair) == 2 and {s["treatment"] for s in pair} == {"BUD", "vehicle"}
            a = next(s for s in pair if s["treatment"] == "BUD")
            b = next(s for s in pair if s["treatment"] == "vehicle")
            av, bv = sums[(g, a["tpm_column"])], sums[(g, b["tpm_column"])]
            r = {"feature_id": g, "symbol": symbol, "donor": d, "disease": a["disease"],
                 "bud_tpm": av, "vehicle_tpm": bv,
                 **{f"effect_pc{pc:g}": float(np.log2(av + pc) - np.log2(bv + pc)) for pc in [1, .5, .1]}}
            effects.append(r); donor_effects.append(r)
        groups = {name: [r["effect_pc1"] for r in effects if r["disease"] == name]
                  for name in ["non_asthma", "fatal_asthma"]}
        groups["all13"] = [r["effect_pc1"] for r in effects]
        for name, x in groups.items():
            results.append({"feature_id": g, "symbol": symbol, "contrast": name + "_BUD_vs_vehicle", **one_sample(x)})
        results.append({"feature_id": g, "symbol": symbol, "contrast": "fatal_asthma_minus_non_asthma_response",
                        **between(groups["fatal_asthma"], groups["non_asthma"])})
        for pc in [1, .5, .1]:
            x = np.array([r[f"effect_pc{pc:g}"] for r in effects])
            loo = np.array([np.delete(x, i).mean() for i in range(len(x))])
            sensitivity.append({"feature_id": g, "symbol": symbol, "pseudocount": pc,
                "mean": float(x.mean()), "positive_donors": int(sum(x > 0)), "negative_donors": int(sum(x < 0)),
                "loo_min": float(loo.min()), "loo_max": float(loo.max()),
                "same_direction_all_loo": bool(np.all(np.sign(loo) == int(c["direction"])))})
    for r, pt, pe in zip(results, holm([r["pvalue"] for r in results]), holm([r["exact_p"] for r in results])):
        r["holm_all_tests"] = float(pt); r["holm_exact_all_tests"] = float(pe)
    csv_out(out / "external_gene_measurements.csv", measurements)
    csv_out(out / "external_donor_effects.csv", donor_effects)
    for r in results:
        r.setdefault("status", "estimable")
    csv_out(out / "external_results.csv", results)
    csv_out(out / "external_sensitivity.csv", sensitivity)
    write_json(out / "external_run.json", {"status": "completed", "original_transcript_rows": total,
        "selected_transcript_rows": len(transcript), "genes": len(ids), "libraries": len(md), "paired_donors": 13,
        "non_asthma": 4, "fatal_asthma": 9, "tests": len(results),
        "finished_utc": datetime.now(timezone.utc).isoformat()})
    for r in results:
        if r["contrast"].startswith("all13"):
            print(json.dumps(r, ensure_ascii=False))


if __name__ == "__main__":
    run(Path(sys.argv[1]))
