"""Independently rederive GR raw measurements, weighted fits, intervals and Holm."""
import csv
import gzip
import json
import sys
from pathlib import Path

import numpy as np
from scipy import stats

from validation_sources import json_out, utc

out = Path(sys.argv[1]).resolve() / "gr_public"


def rows(path):
    with path.open(newline="") as stream:
        return list(csv.DictReader(stream))


def close(a, b):
    assert np.isclose(float(a), float(b), rtol=1e-7, atol=1e-9), (a, b)


samples = rows(out / "sample_map.csv")
raw = {}
for s in samples:
    with gzip.open(out / "sources" / s["filename"], "rt") as stream:
        data = list(csv.reader(stream, delimiter="\t"))
    assert len(data) == len({r[0] for r in data}) == 60680
    raw[s["sample"]] = {r[0]: int(r[1]) for r in data}
measured = rows(out / "gr_candidate_counts.csv")
for r in measured:
    assert int(r["count"]) == raw[r["sample"]][r["feature_id"]]
weighted = rows(out / "gr_wls_inputs.csv")
results = rows(out / "gr_results.csv")
numeric = 0
for study in ["GSE342887", "GSE342771"]:
    design = rows(out / (study + "_design.csv"))
    columns = [k for k in design[0] if k != "sample"]
    x = np.asarray([[float(r[k]) for k in columns] for r in design])
    assert np.linalg.matrix_rank(x) == 6
    contrasts = rows(out / (study + "_contrasts.csv"))
    assert [r["coefficient"] for r in contrasts] == columns
    for r in [r for r in results if r["study"] == study and r["status"] == "estimable"]:
        wls = {s["sample"]: s for s in weighted if s["study"] == study and s["symbol"] == r["symbol"]}
        w = np.asarray([float(wls[s["sample"]]["weight"]) for s in design])
        y = np.asarray([float(wls[s["sample"]]["logCPM"]) for s in design])
        cov = np.linalg.inv(x.T @ (x * w[:, None]))
        beta = cov @ x.T @ (w*y)
        c = np.asarray([float(s[r["contrast"]]) for s in contrasts])
        s2 = float(next(iter(wls.values()))["s2_post"])
        df = float(next(iter(wls.values()))["df_total"])
        effect = c @ beta
        se = np.sqrt(c @ cov @ c * s2)
        width = stats.t.ppf(.975, df)*se
        p = 2*stats.t.sf(abs(effect/se), df)
        for key, value in zip(["effect", "se", "ci_low", "ci_high", "pvalue"], [effect, se, effect-width, effect+width, p]):
            close(value, r[key])
            numeric += 1
    rr = [r for r in results if r["study"] == study]
    p = np.asarray([float(r["pvalue"]) for r in rr])
    order = np.argsort(p)
    adjusted = np.ones(55)
    adjusted[order] = np.minimum(1, np.maximum.accumulate(p[order]*np.arange(55, 0, -1)))
    for r, hp in zip(rr, adjusted):
        close(hp, r["holm_55"])
json_out(out / "python_numeric_audit.json", {"status": "pass", "utc": utc(), "raw_count_measurements": len(measured),
         "numeric_checks": numeric, "tests": len(results), "holm_families": 2,
         "scope": "Re-read original gene counts, independently solve weighted least squares and recompute t/CI/Holm from exported voom weights and moderation; no independent voom/eBayes refit"})
print("GR raw-count/WLS/CI/Holm audit pass", len(measured), numeric, flush=True)
