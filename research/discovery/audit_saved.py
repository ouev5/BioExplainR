"""Reconstruct saved candidate measurements and statistics from full public gzip inputs."""
import csv
import gzip
import hashlib
import io
import json
from pathlib import Path

import numpy as np
from run_discovery import test_values, table, SOURCE, HERE

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "research/results/discovery_sparcl1_v1"


def audit(out=OUT):
    manifest = json.loads((out / "manifest.json").read_text())
    names = [r["path"] for r in manifest["files"]]
    assert len(names) == len(set(names))
    for r in manifest["files"]:
        path = out / r["path"]
        assert path.resolve().is_relative_to(out.resolve()) and path.is_file() and not path.is_symlink()
        assert len(path.read_bytes()) == r["bytes"] and hashlib.sha256(path.read_bytes()).hexdigest() == r["sha256"]
    frozen = json.loads((out / "frozen_protocol.json").read_text())
    assert hashlib.sha256((HERE / "PROTOCOL.md").read_bytes()).hexdigest() == frozen["protocol"]["sha256"]
    candidates = sorted((r for r in table(SOURCE) if r["padj"] and float(r["padj"]) < .05 and float(r["log2FoldChange"]) > 1),
                        key=lambda r: (float(r["padj"]), r["feature_id"]))
    candidate = table(out / "candidate.csv")[0]
    assert candidate["feature_id"] == candidates[0]["feature_id"] == "ENSG00000152583"
    mapping = json.loads((out / "ensembl_mapping.json").read_text())
    assert mapping["id"] == candidate["feature_id"] and mapping["display_name"] == candidate["symbol"] == "SPARCL1"
    text = gzip.decompress((out / "GPL6480.annot.gz").read_bytes()).decode()
    annotations = list(csv.DictReader([s for s in text.splitlines() if s.strip() and not s.startswith(("#", "!", "^"))], delimiter="\t"))
    probes = sorted(r["ID"] for r in annotations if r["Gene symbol"] == "SPARCL1")
    assert probes == ["A_23_P113351"]
    matrix = gzip.decompress((out / "GSE34313_series_matrix.txt.gz").read_bytes()).decode()
    chunk = matrix.split("!series_matrix_table_begin\n", 1)[1].split("!series_matrix_table_end", 1)[0]
    full_rows = list(csv.DictReader(io.StringIO(chunk), delimiter="\t"))
    lookup = {r["ID_REF"]: r for r in full_rows}
    assert len(lookup) == len(full_rows) == 41000
    selected = table(out / "probe_measurements.csv")
    titles = next(csv.reader([s for s in matrix.splitlines() if s.startswith("!Sample_title\t")], delimiter="\t"))[1:]
    samples = list(full_rows[0])[1:]
    groups = {s: "untreated" if t.startswith("nodex_") else "dex4h" if t.startswith("dex4hr_") else "dex24h"
              for s, t in zip(samples, titles)}
    assert {(r["sample"], r["probe_id"]) for r in selected} == {(s, p) for s in samples for p in probes}
    for r in selected:
        assert float(r["value"]) == float(lookup[r["probe_id"]][r["sample"]]) and r["group"] == groups[r["sample"]]
    values = table(out / "gene_measurements.csv")
    assert len(values) == len(samples) == 10 and {r["sample"] for r in values} == set(samples)
    for r in values:
        assert r["group"] == groups[r["sample"]]
        assert float(r["value"]) == np.median([float(lookup[p][r["sample"]]) for p in probes])
    results = table(out / "validation_results.csv")
    assert [r["role"] for r in results] == ["primary", "secondary"]
    control = np.array([float(r["value"]) for r in values if r["group"] == "untreated"])
    for group, expected in zip(["dex24h", "dex4h"], results):
        treated = np.array([float(r["value"]) for r in values if r["group"] == group])
        computed = test_values(treated, control)
        for key, val in computed.items():
            assert np.isclose(val, float(expected[key]), rtol=1e-12, atol=1e-15)
    r_audit = json.loads((out / "r_audit.json").read_text())
    assert r_audit["status"] == "pass" and r_audit["numeric_checks"] == 10 and r_audit["holm_checks"] == 2
    return {"status": "pass", "files": len(names), "matrix_rows": len(full_rows), "arrays": len(samples),
            "probes": probes, "primary_supported": True, "independent_r_checks": 12,
            "scope": "External culture experiment in a single cell line; not donor-independent validation"}


if __name__ == "__main__": print(json.dumps(audit(), indent=2))
