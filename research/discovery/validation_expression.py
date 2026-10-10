"""Freeze and test new paired ASM datasets without treating cultures as donors."""
import argparse
import csv
import gzip
import io
import itertools
import json
import re
import urllib.parse
from pathlib import Path

import numpy as np
from scipy import stats

from validation_sources import ROOT, HERE, utc, record, csv_out, json_out, fetch

GENES = {"PER2": "8864", "PER3": "8863", "METTL7A": "25840", "MAOA": "4128",
         "ANGPTL2": "23452", "FSTL3": "10272", "FKBP5": "2289", "TSC22D3": "1831",
         "DUSP1": "1843", "GNAS": "2778", "NR3C1": "2908"}
CONTRASTS = ["GC_control", "GC_perturbed", "GC_x_perturbation", "perturbation_vehicle"]


def rows(path):
    with path.open(newline="", encoding="utf-8-sig") as stream:
        return list(csv.DictReader(stream))


def samples(out):
    data = []
    ages = json.loads((out / "PMC7027561_tables.json").read_text())["fsb220198-tbl-0001"]
    demographics = {r[0]: r[1:] for r in ages[1:]}
    for study in ["GSE130715", "GSE13168"]:
        text = (out / "sources" / (study + "_metadata.txt")).read_text()
        for chunk in text.split("^SAMPLE = ")[1:]:
            gsm = chunk.splitlines()[0]
            fields = {}
            for line in chunk.splitlines()[1:]:
                if " = " in line:
                    key, value = line.split(" = ", 1)
                    fields.setdefault(key, []).append(value)
            title = fields["!Sample_title"][0]
            if study == "GSE130715":
                description = next(x for x in fields["!Sample_description"] if x.startswith("N"))
                match = re.match(r"^(N\d{6}K?)", description)
                assert match, description
                donor = match[1]
                condition = next(x.split(": ", 1)[1] for x in fields["!Sample_characteristics_ch1"] if x.startswith("treatment condition:"))
                gc = int("budesonide" in condition)
                perturb = int("GNAS" in condition)
                age, sex, race = demographics[donor]
                sample_key = fields["!Sample_description"][0]
                dose = "BUD 1 uM 24h (original article; GEO omits dose)"
            else:
                match = re.fullmatch(r"(GFP|PKI)_(.+)_donor(\d)", title)
                assert match, title
                perturb = int(match[1] == "PKI")
                condition = match[2]
                donor = "donor" + match[3]
                gc = int("Flu" in condition)
                age, sex, race = "", "", ""
                sample_key = gsm
                dose = "FP 10 nM; 30min pretreatment + 8h stimulation"
            baseline = condition in ["basal", "Flu"] if study == "GSE13168" else True
            data.append({"study": study, "sample": gsm, "title": title, "sample_key": sample_key,
                         "donor": donor, "age": age, "sex": sex, "race": race, "gc": gc,
                         "perturbation": perturb, "condition": condition,
                         "in_primary_subset": baseline, "dose_duration": dose})
    return data


def freeze(out):
    data = samples(out)
    csv_out(out / "expression_sample_map.csv", data)
    old = rows(ROOT / "research/results/discovery_donors_v1/samples.csv")
    overlap = []
    old_ids = {r["donor"] for r in old}
    for r in data:
        if r["study"] == "GSE130715" and r["gc"] == 0 and r["perturbation"] == 0:
            overlap.append({"donor": r["donor"], "age": r["age"], "exact_overlap_GSE94335": r["donor"] in old_ids,
                            "alias_independence": "exact labels differ; undisclosed aliases cannot be fully excluded"})
    csv_out(out / "new_donor_overlap.csv", overlap)
    json_out(out / "expression_design_freeze.json", {
        "utc": utc(), "script": record(Path(__file__)), "protocol": record(HERE / "VALIDATION_CONTINUATION_PROTOCOL.md"),
        "sample_map": record(out / "expression_sample_map.csv"), "genes_entrez": GENES, "contrasts": CONTRASTS,
        "primary": "Within-donor mean difference of published log2(TPM+1) / GCRMA log2 values; two-sided one-sample t",
        "family": "Each dataset: 11 genes x 4 contrasts = 44 Holm tests, missing P=1",
        "exact": "All 2^n donor sign flips; paired exchangeability assumption; Holm across same family",
        "GSE130715": {"donors": 6, "libraries": 24, "ages": "19-54, all six adult", "perturbation": "GNAS, NOT NR3C1",
                       "dose": "1 uM BUD 24h, single endpoint", "scale": "published TPM; no count-model log2FC claim"},
        "GSE13168": {"primary_donors": ["donor2", "donor3", "donor4"], "primary_arrays": 12,
                      "published_arrays": 54, "perturbation": "genetically expressed PKA inhibitor PKI, NOT NR3C1",
                      "scale": "GCRMA log2 values", "age": "not disclosed; adult status not verified",
                      "subset": "basal vs Flu, GFP vs PKI; inflammation arms preserved, not tested in this freeze"},
        "missing": "No probe/ID -> status missing_annotation, P=1, CI empty; do not substitute genes",
        "independence": "No exact overlap among six new labels and saved GSE94335 labels; do not sum donor counts; GSE13168 aliases unknown",
        "timing": "Metadata, original article and published statistical tables read; new candidate arrays/TPM not read."})
    print("Expression design frozen: six adult GNAS donors and three paired PKI donors", flush=True)


def acquire(out):
    assert (out / "expression_design_freeze.json").exists()
    urls = [
        ("GSE130715_tpm.txt.gz", "https://ftp.ncbi.nlm.nih.gov/geo/series/GSE130nnn/GSE130715/suppl/GSE130715_Gs_HASM.tpm.txt.gz"),
        ("GSE130715_counts.txt.gz", "https://ftp.ncbi.nlm.nih.gov/geo/series/GSE130nnn/GSE130715/suppl/GSE130715_Gs_HASM.featurecounts.txt.gz"),
        ("GPL96.annot.gz", "https://ftp.ncbi.nlm.nih.gov/geo/platforms/GPLnnn/GPL96/annot/GPL96.annot.gz"),
        ("gene_id_verification.json", "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi?" + urllib.parse.urlencode({"db": "gene", "id": ",".join(GENES.values()), "retmode": "json"})),
    ]
    logs = []
    for name, url in urls:
        path = out / "sources" / name
        rec = {"status": "retrieved", "url": url, "reuse_saved_after_timeout": True, **record(path)} if path.exists() else fetch(url, path, timeout=30)
        if rec["status"] == "retrieved" and name.endswith(".gz"):
            text = gzip.decompress(path.read_bytes()).decode("utf-8-sig")
            rec["gzip_crc_complete"] = True
            print(name, "bytes", rec["bytes"], "header", text.splitlines()[0][:1500], flush=True)
        logs.append(rec)
        # Keep incremental acquisition evidence if a subsequent command is interrupted.
        label = "expression_acquisition_step_" + str(len(logs))
        logpath = out / (label + ".json")
        if logpath.exists():
            logpath = out / (label + "_resume.json")
        json_out(logpath, {"utc": utc(), "records": logs})
    json_out(out / "expression_input_manifest.json", {"utc": utc(), "records": logs})


def holm(pvalues):
    p = np.asarray(pvalues)
    order = np.argsort(p, kind="stable")
    answer = np.ones(len(p))
    answer[order] = np.minimum(1, np.maximum.accumulate(p[order] * np.arange(len(p), 0, -1)))
    return answer


def summary(x):
    x = np.asarray(x, dtype=float)
    n = len(x)
    effect = float(np.mean(x))
    se = float(np.std(x, ddof=1) / np.sqrt(n))
    assert n >= 2 and se > 0
    width = float(stats.t.ppf(.975, n - 1) * se)
    perm = [np.mean(x * np.asarray(signs)) for signs in itertools.product([-1, 1], repeat=n)]
    return {"n_donors": n, "effect": effect, "se": se, "ci_low": effect - width, "ci_high": effect + width,
            "pvalue": float(stats.ttest_1samp(x, 0).pvalue),
            "exact_pvalue": sum(abs(v) >= abs(effect) - 1e-12 for v in perm) / len(perm),
            "positive_donors": int(sum(x > 0)), "negative_donors": int(sum(x < 0)), "df": n - 1}


def measure(out):
    freeze = json.loads((out / "expression_design_freeze.json").read_text())
    assert record(out / "expression_sample_map.csv") == freeze["sample_map"]
    samples_all = rows(out / "expression_sample_map.csv")
    gene_verification = json.loads((out / "sources/gene_id_verification.json").read_text())["result"]
    mapping = []
    for symbol, gene in GENES.items():
        aliases = {gene_verification[gene]["name"]} | {x.strip() for x in gene_verification[gene].get("otheraliases", "").split(",")}
        assert symbol in aliases, (symbol, gene)
        assert gene_verification[gene]["organism"]["taxid"] == 9606
        mapping.append({"frozen_symbol": symbol, "entrez_id": gene, "current_symbol": gene_verification[gene]["name"],
                        "aliases": gene_verification[gene].get("otheraliases", ""), "mapping_rule": "exact current symbol or listed NCBI alias"})
    csv_out(out / "gene_alias_verification.csv", mapping)
    measurements = []
    annotations = []
    text = gzip.decompress((out / "sources/GSE130715_tpm.txt.gz").read_bytes()).decode("utf-8-sig")
    table = list(csv.DictReader(io.StringIO(text), delimiter="\t"))
    print("TPM rows", len(table), "columns", list(table[0])[:8], flush=True)
    index = {r[next(iter(r))]: r for r in table}
    assert len(index) == len(table)
    keys = list(table[0])
    for symbol, gene in GENES.items():
        if gene not in index:
            annotations.append({"study": "GSE130715", "symbol": symbol, "feature_id": gene, "status": "missing_annotation"})
            continue
        annotations.append({"study": "GSE130715", "symbol": symbol, "feature_id": gene, "status": "mapped"})
        for s in samples_all:
            if s["study"] != "GSE130715":
                continue
            matches = [k for k in keys[1:] if s["sample_key"] in k]
            assert len(matches) == 1, (s["sample_key"], matches)
            raw = float(index[gene][matches[0]])
            assert np.isfinite(raw) and raw >= 0
            measurements.append({"study": s["study"], "sample": s["sample"], "donor": s["donor"], "gc": s["gc"],
                                 "perturbation": s["perturbation"], "symbol": symbol, "feature_id": gene,
                                 "raw_value": raw, "value": float(np.log2(raw + 1)), "scale": "log2(TPM+1)", "source_column": matches[0]})
    annottext = gzip.decompress((out / "sources/GPL96.annot.gz").read_bytes()).decode("utf-8")
    lines = [l for l in annottext.splitlines() if not l.startswith(("#", "!", "^")) and l.strip()]
    annot = list(csv.DictReader(lines, delimiter="\t"))
    # Complete original family SOFT was acquired for metadata; now read its
    # sample expression tables, never previously used for candidate selection.
    soft = gzip.decompress((out / "sources/GSE13168_family.soft.gz").read_bytes()).decode("utf-8")
    matrix_index = {}
    for chunk in soft.split("^SAMPLE = ")[1:]:
        sample = chunk.splitlines()[0]
        table_text = chunk.split("!sample_table_begin\n")[1].split("!sample_table_end")[0]
        expr = list(csv.DictReader(io.StringIO(table_text), delimiter="\t"))
        assert len(expr) == len({r["ID_REF"] for r in expr}) == 22283
        for r in expr:
            matrix_index.setdefault(r["ID_REF"], {})[sample] = r["VALUE"]
    primary = [s for s in samples_all if s["study"] == "GSE13168" and s["in_primary_subset"] == "True" and s["donor"] != "donor1"]
    assert len(primary) == 12
    for symbol, gene in GENES.items():
        probes = [a["ID"] for a in annot if a["Gene symbol"] == symbol]
        annotations.append({"study": "GSE13168", "symbol": symbol, "feature_id": "|".join(probes),
                            "status": "mapped" if probes else "missing_annotation"})
        for s in primary:
            for probe in probes:
                value = float(matrix_index[probe][s["sample"]])
                assert np.isfinite(value) and -5 < value < 25, "Expected published GCRMA log2 scale"
                measurements.append({"study": s["study"], "sample": s["sample"], "donor": s["donor"], "gc": s["gc"],
                                     "perturbation": s["perturbation"], "symbol": symbol, "feature_id": probe,
                                     "raw_value": value, "value": value, "scale": "GCRMA log2", "source_column": s["sample"]})
    csv_out(out / "expression_probe_measurements.csv", measurements)
    csv_out(out / "expression_annotation.csv", annotations)
    aggregate = []
    for study in ["GSE130715", "GSE13168"]:
        for symbol in GENES:
            for s in samples_all:
                if s["study"] != study:
                    continue
                match = [r for r in measurements if r["study"] == study and r["symbol"] == symbol and r["sample"] == s["sample"]]
                if match:
                    aggregate.append({"study": study, "symbol": symbol, "sample": s["sample"], "donor": s["donor"],
                                      "gc": s["gc"], "perturbation": s["perturbation"], "n_probes": len(match),
                                      "value": float(np.median([r["value"] for r in match])), "scale": match[0]["scale"]})
    csv_out(out / "expression_gene_measurements.csv", aggregate)
    effects = []
    results = []
    for study in ["GSE130715", "GSE13168"]:
        for symbol in GENES:
            rr = [r for r in aggregate if r["study"] == study and r["symbol"] == symbol]
            donors = sorted({r["donor"] for r in rr})
            local = {k: [] for k in CONTRASTS}
            for d in donors:
                v = {(int(r["gc"]), int(r["perturbation"])): r["value"] for r in rr if r["donor"] == d}
                assert len(v) == 4
                contrasts = [v[1, 0] - v[0, 0], v[1, 1] - v[0, 1],
                             v[1, 1] - v[0, 1] - v[1, 0] + v[0, 0], v[0, 1] - v[0, 0]]
                for c, value in zip(CONTRASTS, contrasts):
                    local[c].append(value)
                    effects.append({"study": study, "symbol": symbol, "donor": d, "contrast": c, "effect": value})
            for c in CONTRASTS:
                result = {"study": study, "symbol": symbol, "contrast": c, "status": "estimable" if donors else "missing_annotation"}
                result.update(summary(local[c]) if donors else {k: "" for k in ["n_donors", "effect", "se", "ci_low", "ci_high", "positive_donors", "negative_donors", "df"]})
                if not donors:
                    result.update(pvalue=1., exact_pvalue=1.)
                results.append(result)
        rr = [r for r in results if r["study"] == study]
        for r, hp, ep in zip(rr, holm([r["pvalue"] for r in rr]), holm([r["exact_pvalue"] for r in rr])):
            r.update(holm_44=float(hp), exact_holm_44=float(ep))
    csv_out(out / "expression_donor_effects.csv", effects)
    csv_out(out / "expression_results.csv", results)
    json_out(out / "expression_run.json", {"status": "completed", "utc": utc(), "script": record(Path(__file__)),
             "measurements": len(measurements), "gene_measurements": len(aggregate), "tests": len(results),
             "datasets": 2, "family_tests": 44, "online_model_calls": 0, "fresh_wet_experiment": False})
    for r in results:
        if r["symbol"] in ["PER2", "PER3", "FSTL3", "GNAS"]:
            print(r, flush=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=["freeze", "acquire", "measure"])
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    globals()[args.action](args.output.resolve())
