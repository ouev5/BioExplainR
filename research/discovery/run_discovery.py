"""Freeze a discovery-selected candidate before testing an external GEO experiment."""
import argparse
import csv
from datetime import datetime, timezone
import gzip
import hashlib
import io
import itertools
import json
from pathlib import Path
import urllib.request

import numpy as np
from scipy import stats

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
SOURCE = ROOT / "research/results/paper_cn_cases_v1/airway_de.csv"


def record(path):
    return {"path": path.name, "bytes": path.stat().st_size,
            "sha256": hashlib.sha256(path.read_bytes()).hexdigest()}


def write_json(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2, allow_nan=False) + "\n")


def table(path):
    with path.open(encoding="utf-8-sig", newline="") as f:
        return list(csv.DictReader(f))


def write_csv(path, rows):
    with path.open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)


def freeze(out):
    out.mkdir(parents=True, exist_ok=False)
    selected = sorted((r for r in table(SOURCE) if r["padj"] and
                       float(r["padj"]) < .05 and float(r["log2FoldChange"]) > 1),
                      key=lambda r: (float(r["padj"]), r["feature_id"]))[0]
    assert selected["feature_id"] == "ENSG00000152583"
    url = "https://rest.ensembl.org/lookup/id/ENSG00000152583?content-type=application/json"
    with urllib.request.urlopen(url, timeout=60) as response:
        mapping_bytes = response.read()
    mapping_path = out / "ensembl_mapping.json"
    mapping_path.write_bytes(mapping_bytes)
    mapping = json.loads(mapping_bytes)
    assert mapping["display_name"] == "SPARCL1" and mapping["species"] == "homo_sapiens"
    write_csv(out / "candidate.csv", [{"feature_id": selected["feature_id"], "symbol": "SPARCL1",
               "log2FoldChange": float(selected["log2FoldChange"]), "padj": float(selected["padj"])}])
    write_json(out / "frozen_protocol.json", {
        "frozen_utc": datetime.now(timezone.utc).isoformat(), "candidate": "SPARCL1",
        "primary_comparison": "dex24h vs untreated", "primary_test": "two-sided Welch t",
        "decision": "effect > 0 and pvalue < 0.05", "external": "GSE34313",
        "external_unit": "culture replicate in one HASM cell line, not independent donor",
        "protocol": record(HERE / "PROTOCOL.md"), "discovery_input": record(SOURCE),
        "mapping_url": url, "mapping": record(mapping_path),
        "candidate_record": record(out / "candidate.csv"),
        "timing_scope": "Metadata/platform feasibility read; candidate expression unexamined before freeze"})
    print(json.dumps({"status": "frozen", "candidate": selected}, indent=2))


def download(url, path):
    if path.exists():
        raise ValueError(f"Refusing to overwrite {path}")
    with urllib.request.urlopen(url, timeout=300) as response:
        blob = response.read()
    text = gzip.decompress(blob).decode("utf-8")  # checks stream end and CRC
    path.write_bytes(blob)
    return text, {**record(path), "url": url, "retrieved_utc": datetime.now(timezone.utc).isoformat()}


def test_values(treated, control):
    n, m = len(treated), len(control)
    effect = float(np.mean(treated) - np.mean(control))
    a, b = np.var(treated, ddof=1) / n, np.var(control, ddof=1) / m
    se = np.sqrt(a + b)
    df = (a+b)**2 / (a*a/(n-1) + b*b/(m-1))
    pvalue = float(stats.ttest_ind(treated, control, equal_var=False).pvalue)
    width = float(stats.t.ppf(.975, df) * se)
    pooled = np.r_[treated, control]
    differences = []
    for combination in itertools.combinations(range(n+m), n):
        mask = np.zeros(n+m, dtype=bool)
        mask[list(combination)] = True
        differences.append(float(np.mean(pooled[mask]) - np.mean(pooled[~mask])))
    perm = sum(abs(d) >= abs(effect) - 1e-12 for d in differences) / len(differences)
    return {"effect": effect, "pvalue": pvalue, "ci_low": effect-width, "ci_high": effect+width,
            "welch_df": float(df), "permutation_p": perm, "permutations": len(differences)}


def validate(out):
    frozen = json.loads((out / "frozen_protocol.json").read_text())
    assert record(HERE / "PROTOCOL.md") == frozen["protocol"]
    assert record(out / "candidate.csv") == frozen["candidate_record"]
    assert record(SOURCE) == frozen["discovery_input"]
    if (out / "validation_results.csv").exists():
        raise ValueError("Use a new directory for a new run")
    base = "https://ftp.ncbi.nlm.nih.gov/geo"
    matrix_text, matrix_record = download(
        base + "/series/GSE34nnn/GSE34313/matrix/GSE34313_series_matrix.txt.gz", out / "GSE34313_series_matrix.txt.gz")
    annotation_text, annotation_record = download(
        base + "/platforms/GPL6nnn/GPL6480/annot/GPL6480.annot.gz", out / "GPL6480.annot.gz")
    lines = [line for line in annotation_text.splitlines() if not line.startswith(("#", "!", "^")) and line.strip()]
    annotations = list(csv.DictReader(lines, delimiter="\t"))
    probes = sorted(r["ID"] for r in annotations if r["Gene symbol"] == "SPARCL1")
    assert probes, "No unambiguous SPARCL1 probes"
    start = matrix_text.index("!series_matrix_table_begin\n") + len("!series_matrix_table_begin\n")
    end = matrix_text.index("!series_matrix_table_end", start)
    expression_rows = list(csv.DictReader(io.StringIO(matrix_text[start:end]), delimiter="\t"))
    assert len({r["ID_REF"] for r in expression_rows}) == len(expression_rows)
    titles = next(csv.reader([line for line in matrix_text.splitlines() if line.startswith("!Sample_title\t")], delimiter="\t"))[1:]
    samples = list(expression_rows[0])[1:]
    assert len(samples) == len(titles) == 10 and len(set(samples)) == 10
    chosen = [r for r in expression_rows if r["ID_REF"] in probes]
    assert len(chosen) == len(probes)
    measurements = []
    for sample, title in zip(samples, titles):
        group = "untreated" if title.startswith("nodex_") else "dex4h" if title.startswith("dex4hr_") else "dex24h"
        assert title.startswith(("nodex_", "dex4hr_", "dex24hr_"))
        for row in chosen:
            measurements.append({"sample": sample, "title": title, "group": group,
                                 "probe_id": row["ID_REF"], "symbol": "SPARCL1", "value": float(row[sample])})
    assert all(np.isfinite(r["value"]) for r in measurements)
    write_csv(out / "probe_measurements.csv", measurements)
    write_csv(out / "selected_annotation.csv", [r for r in annotations if r["ID"] in probes])
    values = [{"sample": s, "title": t, "group": next(r["group"] for r in measurements if r["sample"] == s),
               "value": float(np.median([r["value"] for r in measurements if r["sample"] == s]))}
              for s, t in zip(samples, titles)]
    write_csv(out / "gene_measurements.csv", values)
    control = np.array([r["value"] for r in values if r["group"] == "untreated"])
    results = []
    for group in ["dex24h", "dex4h"]:
        treated = np.array([r["value"] for r in values if r["group"] == group])
        assert len(treated) == 3 and len(control) == 4
        results.append({"symbol": "SPARCL1", "comparison": f"{group} vs untreated",
                        "role": "primary" if group == "dex24h" else "secondary",
                        "n_control": len(control), "n_treated": len(treated),
                        "n_probes": len(probes), **test_values(treated, control)})
    p = np.array([r["pvalue"] for r in results]); order = np.argsort(p)
    adjusted = np.minimum(1, np.maximum.accumulate(p[order] * np.array([2, 1])))
    for index, val in zip(order, adjusted):
        results[index]["holm_two_timepoints"] = float(val)
    write_csv(out / "validation_results.csv", results)
    metadata = [s for s in matrix_text.splitlines() if s.startswith("!")]
    (out / "geo_metadata.txt").write_text("\n".join(metadata) + "\n")
    write_json(out / "input_manifest.json", {"downloaded": [matrix_record, annotation_record],
               "freeze": record(out / "frozen_protocol.json"), "n_matrix_rows": len(expression_rows),
               "probes": probes, "processed_scale": "published processed units; not re-normalized",
               "independence": "external experiment, single cell line; donor overlap not verifiable"})
    write_json(out / "summary.json", {"status": "completed", "candidate": "SPARCL1", "results": results,
               "primary_supported": results[0]["effect"] > 0 and results[0]["pvalue"] < .05,
               "online_model_calls": 0, "novelty": "candidate prioritization and external reanalysis, not first biological discovery",
               "external_scope": "Single-cell-line culture replication; no donor-independent inference",
               "finished_utc": datetime.now(timezone.utc).isoformat()})
    print(json.dumps(results, indent=2))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=["freeze", "validate"])
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    globals()[args.action](args.output)
