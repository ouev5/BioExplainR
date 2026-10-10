"""Predefined multi-donor candidate response using published TPM, not count inference."""
import argparse
import csv
from datetime import datetime, timezone
import gzip
import io
import itertools
import json
from pathlib import Path
import subprocess
import hashlib

import numpy as np
from scipy import stats

from prepare_context import fetch, record, write_json
from audit_context import adjust

HERE = Path(__file__).resolve().parent
GENES = {"SPARCL1": "ENSG00000152583", "FKBP5": "ENSG00000096060", "TSC22D3": "ENSG00000157514"}


def write_csv(path, rows):
    with path.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0])); w.writeheader(); w.writerows(rows)


def acquire(out):
    resuming = out.exists()
    if resuming:
        assert not (out / "input_manifest.json").exists(), "Only resume an interrupted acquisition"
    else:
        out.mkdir(parents=True, exist_ok=False)
    if not resuming: write_json(out / "frozen_protocol.json", {
        "frozen_utc": datetime.now(timezone.utc).isoformat(), "protocol": record(HERE / "DONOR_PROTOCOL.md"),
        "scripts": [record(HERE / n) for n in ["run_donors.py", "audit_donors.R"]],
        "timing": "Series metadata read; candidate expression unread; GSE146017 negative interactions known"})
    base = "https://ftp.ncbi.nlm.nih.gov/geo/series/GSE94nnn/GSE94335"
    url = base + "/suppl/GSE94335_PostQC_all_sample_TPM.txt.gz"
    path = out / "tpm.txt.gz"
    if not (out / "range_download.json").exists():
        subprocess.run(["curl", "--silent", "--show-error", "--fail", "--connect-timeout", "30", "--max-time", "600",
                        "--output", str(path), url], check=True)
    with gzip.open(path, "rb") as stream:
        while stream.read(1024*1024): pass  # check complete stream without duplicating decompressed file
    inputs = [{**record(path), "url": url, "retrieved_utc": datetime.now(timezone.utc).isoformat()},
              fetch(base + "/matrix/GSE94335_series_matrix.txt.gz", out / "series_matrix.txt.gz")]
    inputs.append(fetch("https://www.ebi.ac.uk/europepmc/webservices/rest/search?query=EXT_ID:30694689&resultType=core&format=json",
                        out / "paper_metadata.json"))
    inputs.append(fetch("https://www.ebi.ac.uk/europepmc/webservices/rest/PMC6604213/fullTextXML", out / "PMC6604213.xml"))
    write_json(out / "acquisition_refinement.json", {"reason": "urllib full download exceeded harness 360-second timeout; curl transfer used",
        "protocol_unchanged": True, "original_freeze_preserved": True, "script": record(HERE / "run_donors.py")})
    write_json(out / "input_manifest.json", {"inputs": inputs})
    with gzip.open(out / "tpm.txt.gz", "rt") as f:
        (out / "tpm_header.txt").write_text(f.readline())
    with gzip.open(out / "series_matrix.txt.gz", "rt") as f:
        (out / "sample_metadata.txt").write_text("".join(line for line in f if line.startswith(("!Sample_title", "!Sample_geo_accession", "!Sample_characteristics"))))
    print(json.dumps({"status": "acquired", "inputs": inputs}, indent=2))


def one_sample(x):
    n = len(x); mean = np.mean(x); width = stats.t.ppf(.975, n-1)*stats.sem(x)
    perms = np.array([np.mean(x*np.array(s)) for s in itertools.product([-1, 1], repeat=n)])
    return {"effect": float(mean), "ci_low": float(mean-width), "ci_high": float(mean+width),
            "pvalue": float(stats.ttest_1samp(x, 0).pvalue),
            "permutation_p": float(np.mean(np.abs(perms) >= abs(mean)-1e-12)), "permutations": len(perms)}


def between(a, b):
    n, m = len(a), len(b); effect = np.mean(a)-np.mean(b)
    aa, bb = np.var(a, ddof=1)/n, np.var(b, ddof=1)/m
    df = (aa+bb)**2/(aa*aa/(n-1)+bb*bb/(m-1)); width = stats.t.ppf(.975, df)*np.sqrt(aa+bb)
    x = np.r_[a, b]; perm = []
    for inds in itertools.combinations(range(n+m), n):
        mask = np.zeros(n+m, bool); mask[list(inds)] = True
        perm.append(np.mean(x[mask])-np.mean(x[~mask]))
    return {"effect": float(effect), "ci_low": float(effect-width), "ci_high": float(effect+width),
            "pvalue": float(stats.ttest_ind(a, b, equal_var=False).pvalue),
            "permutation_p": float(np.mean(np.abs(perm) >= abs(effect)-1e-12)), "permutations": len(perm)}


def analyze(out):
    if (out / "results.csv").exists(): raise ValueError("Refusing to overwrite prior analysis")
    frozen = json.loads((out / "frozen_protocol.json").read_text())
    assert record(HERE / "DONOR_PROTOCOL.md") == frozen["protocol"]
    with gzip.open(out / "series_matrix.txt.gz", "rt") as f:
        lines = f.read().splitlines()
    metadata = [next(csv.reader([line], delimiter="\t")) for line in lines if line.startswith("!Sample_")]
    get = lambda key: next(r[1:] for r in metadata if r[0] == key)
    titles, samples = get("!Sample_title"), get("!Sample_geo_accession")
    characteristics = [r[1:] for r in metadata if r[0] == "!Sample_characteristics_ch1"]
    # A strict metadata-only parser is added after inspecting published fields.
    from donor_design import parse_design
    write_json(out / "design_amendment_freeze.json", {"frozen_utc": datetime.now(timezone.utc).isoformat(),
        "phase": "Published format/sample mapping inspected; candidate TPM and tests unread",
        "amendment": record(HERE / "DONOR_DESIGN_AMENDMENT.md"),
        "scripts": [record(HERE / n) for n in ["run_donors.py", "donor_design.py", "audit_donors.R"]]})
    selected_rows = []; observed = set(); total_rows = 0
    with gzip.open(out / "tpm.txt.gz", "rt") as f:
        columns = f.readline().split()
        assert columns == ["target_id", "sample", "est_counts", "tpm", "eff_len", "len", "condition", "ens_gene", "ext_gene"]
        for line in f:
            vals = line.split(); assert len(vals) == len(columns)
            total_rows += 1; observed.add(vals[1])
            if vals[7].split(".")[0] in GENES.values(): selected_rows.append(dict(zip(columns, vals)))
    write_json(out / "observed_sample_index.json", {"samples": sorted(observed), "n_samples": len(observed), "rows": total_rows})
    md = parse_design(out, titles, samples, characteristics, observed)
    write_csv(out / "samples.csv", md)
    assert len({(r["target_id"], r["sample"]) for r in selected_rows}) == len(selected_rows)
    write_csv(out / "transcript_measurements.csv", selected_rows)
    measurements = []
    for g, feature in GENES.items():
        for s in md:
            matched = [r for r in selected_rows if r["ens_gene"].split(".")[0] == feature and r["sample"] == s["tpm_column"]]
            assert matched
            value = sum(float(r["tpm"]) for r in matched); assert np.isfinite(value) and value >= 0
            measurements.append({"symbol": g, "feature_id": feature, **s, "tpm": value, "log2_tpm_plus_one": float(np.log2(value+1))})
    write_csv(out / "gene_measurements.csv", measurements)
    donor_effects = []
    for g in GENES:
        for d in sorted({s["donor"] for s in md}):
            pair = [r for r in measurements if r["symbol"] == g and r["donor"] == d]
            if len(pair) != 2 or {r["treatment"] for r in pair} != {"vehicle", "BUD"}: continue
            a = next(r for r in pair if r["treatment"] == "BUD"); b = next(r for r in pair if r["treatment"] == "vehicle")
            donor_effects.append({"symbol": g, "donor": d, "disease": a["disease"],
                                  "bud_tpm": a["tpm"], "vehicle_tpm": b["tpm"],
                                  **{f"effect_pc{pc:g}": float(np.log2(a["tpm"]+pc)-np.log2(b["tpm"]+pc)) for pc in [1, .5, .1]}})
    write_csv(out / "donor_effects.csv", donor_effects)
    selected = [r for r in donor_effects if r["symbol"] == "SPARCL1"]
    groups = {group: np.array([r["effect_pc1"] for r in selected if r["disease"] == group]) for group in ["non_asthma", "fatal_asthma"]}
    results = [{"contrast": g+"_BUD_vs_vehicle", "n_donors_a": len(x), "n_donors_b": 0,
                "positive_donors": int(sum(x > 0)), "negative_donors": int(sum(x < 0)), **one_sample(x)} for g, x in groups.items()]
    results.append({"contrast": "fatal_asthma_minus_non_asthma_response", "n_donors_a": len(groups["fatal_asthma"]),
                    "n_donors_b": len(groups["non_asthma"]), "positive_donors": "", "negative_donors": "",
                    **between(groups["fatal_asthma"], groups["non_asthma"])})
    for row, val in zip(results, adjust([r["pvalue"] for r in results], "holm")): row["holm_three_tests"] = float(val)
    write_csv(out / "results.csv", results)
    write_json(out / "summary.json", {"status": "completed", "dataset": "GSE94335", "original_transcript_sample_rows": total_rows,
        "published_samples_used": len(md), "paired_donors": len(selected), "results": results,
        "estimator": "BUD-vehicle donor difference in log2(TPM+1); not RNA-seq count-model log2FC",
        "finished_utc": datetime.now(timezone.utc).isoformat()})
    print(json.dumps(results, indent=2))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__); parser.add_argument("action", choices=["acquire", "analyze"])
    parser.add_argument("output", type=Path); args = parser.parse_args(); globals()[args.action](args.output)
