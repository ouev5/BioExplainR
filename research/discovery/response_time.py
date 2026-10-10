"""Test all frozen genes in the published ASM 4h/24h DEX experiment."""
import csv
import gzip
import io
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

import numpy as np

from run_discovery import test_values
from validate_response import ROOT, csv_out, holm, rows, sha, write_json


def run(out):
    if (out / "asm_time_results.csv").exists():
        raise ValueError("Refusing to overwrite time analysis")
    src = ROOT / "research/results/discovery_sparcl1_v1"
    files = [src / "GSE34313_series_matrix.txt.gz", src / "GPL6480.annot.gz",
             Path(__file__), ROOT / "research/discovery/RESPONSE_TIME_AMENDMENT.md"]
    write_json(out / "time_analysis_freeze.json", {
        "frozen_utc": datetime.now(timezone.utc).isoformat(),
        "stage": "after ASM/A549 response comparison; before full candidate time measurements",
        "files": [{"path": str(p.relative_to(ROOT)), "sha256": sha(p)} for p in files],
        "candidate_sha256": sha(out / "frozen_candidates.csv"), "tests": 24})
    with gzip.open(src / "GPL6480.annot.gz", "rt") as stream:
        annotations = list(csv.DictReader([line for line in stream if line.strip() and not line.startswith(("#", "!", "^"))], delimiter="\t"))
    with gzip.open(src / "GSE34313_series_matrix.txt.gz", "rt") as stream:
        text = stream.read()
    start = text.index("!series_matrix_table_begin\n") + len("!series_matrix_table_begin\n")
    end = text.index("!series_matrix_table_end", start)
    matrix = list(csv.DictReader(io.StringIO(text[start:end]), delimiter="\t"))
    lookup = {r["ID_REF"]: r for r in matrix}; assert len(lookup) == len(matrix)
    titles = next(csv.reader([line for line in text.splitlines() if line.startswith("!Sample_title\t")], delimiter="\t"))[1:]
    samples = list(matrix[0])[1:]; assert len(samples) == len(titles) == 10
    annotation = rows(out / "candidate_annotation.csv"); results = []; measurements = []; probes_used = []
    for a in annotation:
        g = a["feature_id"]; symbol = a["symbols"]
        probes = sorted(r["ID"] for r in annotations if symbol and r["Gene symbol"] == symbol)
        if not probes:
            for k in ["dex4h", "dex24h"]:
                results.append({"feature_id": g, "symbol": symbol, "contrast": k, "n_probes": 0,
                    "effect": "", "ci_low": "", "ci_high": "", "pvalue": 1., "permutation_p": 1.,
                    "welch_df": "", "permutations": 0, "status": "no_unambiguous_probe_not_estimable"})
            continue
        probes_used.extend([{**r, "feature_id": g} for r in annotations if r["ID"] in probes])
        values = []
        for s, t in zip(samples, titles):
            group = "untreated" if t.startswith("nodex_") else "dex4h" if t.startswith("dex4hr_") else "dex24h"
            assert t.startswith(("nodex_", "dex4hr_", "dex24hr_"))
            value = float(np.median([float(lookup[p][s]) for p in probes]))
            r = {"feature_id": g, "symbol": symbol, "sample": s, "title": t, "group": group, "value": value}
            values.append(r); measurements.append(r)
        control = np.array([r["value"] for r in values if r["group"] == "untreated"])
        for k in ["dex4h", "dex24h"]:
            treated = np.array([r["value"] for r in values if r["group"] == k])
            assert len(control) == 4 and len(treated) == 3
            results.append({"feature_id": g, "symbol": symbol, "contrast": k, "n_probes": len(probes),
                            **test_values(treated, control), "status": "estimable"})
    for r, p in zip(results, holm([r["pvalue"] for r in results])):
        r["holm_24_tests"] = float(p)
    csv_out(out / "asm_time_results.csv", results)
    csv_out(out / "asm_time_measurements.csv", measurements)
    csv_out(out / "asm_time_annotation.csv", probes_used)
    for r in results:
        if r["symbol"] in ["PER2", "PER3", "TEF", "FSTL3", "ANGPTL2", "METTL7A"]:
            print(json.dumps(r))


if __name__ == "__main__":
    run(Path(sys.argv[1]))
