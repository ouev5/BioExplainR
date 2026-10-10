"""Freeze mapped TMT comparisons, download complete protein table, keep missing genes."""
import argparse
import csv
import json
import re
from pathlib import Path

from validation_sources import utc, record, csv_out, json_out, fetch


def freeze(out):
    dest = out / "protein_public"
    with (dest / "lab_schemeTMT.csv").open(encoding="utf-8", errors="replace", newline="") as stream:
        scheme = list(csv.DictReader(stream))
    with (dest / "protein_study_information.txt").open(newline="") as stream:
        study = list(csv.DictReader(stream, delimiter="\t"))
    sample_map = []
    for r in scheme:
        if r["label"] == "126":
            continue
        # Only the encoding-damaged nonbreaking prefix is removed. Conditions
        # are verified independently against Proteome Discoverer metadata.
        m = re.search(r"(DMSO|CORT) (31|43)h \+\s*(1|3)h v(\d)", r["Condition"])
        assert m, r
        drug, phase, duration, replicate = m.groups()
        matched = [s for s in study if s["Quan Channel"] == r["label"] and f"TMT{r['Plex']}_TP" in s["Sample Identifier"]]
        assert matched and {s["Sample Group"] for s in matched} == {f"{drug} {phase}h {duration}h"}
        sample_map.append({"sample": next(iter({s["Sample"] for s in matched})), "plex": r["Plex"],
                           "label": r["label"], "drug": drug, "phase_label": phase, "duration_h": duration,
                           "replicate_label": replicate, "original_sample_number": r[next(iter(r))],
                           "starred_in_source": "*" in r[next(iter(r))]})
    assert len(sample_map) == len({(r["plex"], r["label"]) for r in sample_map}) == 32
    csv_out(dest / "protein_sample_map.csv", sample_map)
    json_out(dest / "protein_design_freeze.json", {
        "utc": utc(), "script": record(Path(__file__)), "sample_map": record(dest / "protein_sample_map.csv"),
        "candidates": ["PER2", "PER3", "METTL7A", "MAOA", "ANGPTL2", "FSTL3"],
        "controls": ["PER1", "FKBP5", "TSC22D3", "DUSP1", "NR3C1"],
        "protein_rule": "Use unique exact gene symbol or listed METTL7A/TMT1A alias in table; high-confidence protein with >=2 unique peptides; no imputation",
        "estimands": "CORT-DMSO log2 normalized protein abundance, separately phase31/43 and 1/3h; four contrasts x11 =44 Holm",
        "primary_test": "Unpaired Welch t on culture replicates; v labels do not establish paired blocks",
        "sample29": "Asterisk source meaning unknown, include primary and omit only in sensitivity with original flag retained",
        "phase_label": "31h/43h are source labels, not claimed CORT exposure lengths; 1h/3h treatment durations",
        "plex": "Duration confounded with TMT plex, so no direct 3h-1h abundance test",
        "species_conflict": "PRIDE organism Homo sapiens but search database protocol Mus musculus; verify actual protein accession descriptions before tissue/species claim",
        "scope": "Published processed quantitative protein table, no raw MS spectrum re-search; cell origin still to verify; no function inference from abundance alone",
        "timing": "Scheme and metadata read, protein candidate table not yet read."})


def acquire(out):
    dest = out / "protein_public"
    files = json.loads((dest / "pride_files.json").read_text())
    wanted = [f for f in files if f["fileName"].endswith("_Anna_TMT_TP_Proteins.txt")]
    assert len(wanted) == 1
    f = wanted[0]
    url = next(u["value"] for u in f["publicFileLocations"] if u["name"] == "FTP Protocol").replace("ftp://", "https://")
    path = dest / "original_proteins.txt"
    rec = fetch(url, path, 120)
    if rec["status"] == "retrieved":
        assert path.stat().st_size == f["fileSizeBytes"]
        rec["PRIDE_size_verified"] = True
        with path.open(encoding="utf-8-sig") as stream:
            print(stream.readline(), flush=True)
    json_out(dest / "protein_acquisition.json", rec)


def inspect(out):
    dest = out / "protein_public"
    fields = ["Accession", "Description", "Gene Symbol", "Entrez Gene ID", "Master", "Contaminant",
              "Protein FDR Confidence Combined", "Number of Unique Peptides", "Number of Protein Unique Peptides"]
    wanted = {"PER2", "PER3", "METTL7A", "TMT1A", "MAOA", "ANGPTL2", "FSTL3", "PER1", "FKBP5", "TSC22D3", "DUSP1", "NR3C1"}
    data = []
    species = {}
    count = 0
    with (dest / "original_proteins.txt").open(newline="", encoding="utf-8-sig") as stream:
        for r in csv.DictReader(stream, delimiter="\t"):
            count += 1
            match = re.search(r"OS=(.+?) (?:OX=|GN=|PE=)", r["Description"])
            sp = match[1] if match else "unassigned"
            species[sp] = species.get(sp, 0) + 1
            if r["Gene Symbol"].upper() in wanted:
                data.append({k: r[k] for k in fields})
    csv_out(dest / "protein_annotation_inspection.csv", data, fields)
    json_out(dest / "protein_species_inspection.json", {"utc": utc(), "rows": count, "species_counts": species,
             "scope": "Annotation/QC inspected without candidate quantitative response calculation."})
    for r in data:
        print(r, flush=True)
    print("Protein species", species, flush=True)


def measure(out):
    import numpy as np
    from scipy import stats
    from validation_expression import holm
    dest = out / "protein_public"
    # Ortholog amendment declared after annotation inspection but before
    # quantitative responses. Never relabel a mouse search as human proteins.
    json_out(dest / "ortholog_analysis_amendment.json", {
        "utc": utc(), "script": record(Path(__file__)),
        "reason": "Actual table contains mouse annotated accessions, consistent with Mus musculus database protocol; PRIDE human organism conflict remains unresolved.",
        "rule": "Case-insensitive frozen-symbol / TMT1A ortholog names, mouse accession, master/high/noncontaminant and >=2 group-unique peptides",
        "claim": "Mouse-annotated processed proteomics; biological sample species/cell line not author-confirmed; supporting comparison only, not human ASM protein validation",
        "primary_units": "Unpaired culture labels, four per condition; exclude neither starred29 nor any observed value in primary",
        "missing": "All missing candidates retained as P=1 placeholder; no quantitative imputation"})
    with (dest / "original_proteins.txt").open(encoding="utf-8-sig", newline="") as stream:
        table = list(csv.DictReader(stream, delimiter="\t"))
    with (dest / "protein_sample_map.csv").open(newline="") as stream:
        samples = list(csv.DictReader(stream))
    genes = ["PER2", "PER3", "METTL7A", "MAOA", "ANGPTL2", "FSTL3", "PER1", "FKBP5", "TSC22D3", "DUSP1", "NR3C1"]
    measures = []
    annotations = []
    results = []
    for gene in genes:
        aliases = {gene, "TMT1A"} if gene == "METTL7A" else {gene}
        matches = [r for r in table if r["Gene Symbol"].upper() in aliases and "OX=10090" in r["Description"]
                   and r["Master"] == "IsMasterProtein" and r["Contaminant"] == "False"
                   and r["Protein FDR Confidence Combined"] == "High" and int(r["Number of Unique Peptides"]) >= 2]
        assert len(matches) <= 1, (gene, len(matches))
        annotations.append({"symbol": gene, "status": "measured_mouse_annotation" if matches else "not_detected_under_rule",
                            "accession": matches[0]["Accession"] if matches else "", "description": matches[0]["Description"] if matches else "",
                            "group_unique_peptides": matches[0]["Number of Unique Peptides"] if matches else ""})
        for s in samples:
            if not matches:
                continue
            group = f"{s['drug']} {s['phase_label']}h {s['duration_h']}h"
            key = f"Abundances Normalized {'F13' if s['plex'] == '1' else 'F15'} {s['label']} Sample {group}"
            raw = matches[0][key]
            measures.append({"symbol": gene, "accession": matches[0]["Accession"], **s, "raw_abundance": raw,
                             "log2_abundance": float(np.log2(float(raw))) if raw and float(raw) > 0 else "",
                             "source_column": key})
        for phase in ["31", "43"]:
            for duration in ["1", "3"]:
                for sensitivity in ["primary_all32", "omit_source_star29"]:
                    rr = [r for r in measures if r["symbol"] == gene and r["phase_label"] == phase and r["duration_h"] == duration
                          and r["log2_abundance"] != "" and (sensitivity == "primary_all32" or r["starred_in_source"] != "True")]
                    x = [r["log2_abundance"] for r in rr if r["drug"] == "CORT"]
                    y = [r["log2_abundance"] for r in rr if r["drug"] == "DMSO"]
                    result = {"symbol": gene, "phase_label": phase, "duration_h": duration, "sensitivity": sensitivity,
                              "status": "estimable" if len(x) >= 2 and len(y) >= 2 else "not_detected_or_insufficient",
                              "n_CORT": len(x), "n_DMSO": len(y), "effect": "", "se": "", "ci_low": "", "ci_high": "", "df": "", "pvalue": 1.}
                    if result["status"] == "estimable":
                        a, b = np.var(x, ddof=1)/len(x), np.var(y, ddof=1)/len(y)
                        se = np.sqrt(a+b)
                        df = (a+b)**2/(a*a/(len(x)-1)+b*b/(len(y)-1))
                        effect = np.mean(x)-np.mean(y)
                        width = stats.t.ppf(.975, df)*se
                        result.update(effect=float(effect), se=float(se), ci_low=float(effect-width), ci_high=float(effect+width),
                                      df=float(df), pvalue=float(stats.ttest_ind(x, y, equal_var=False).pvalue))
                    results.append(result)
    for sensitivity in ["primary_all32", "omit_source_star29"]:
        rr = [r for r in results if r["sensitivity"] == sensitivity]
        assert len(rr) == 44
        for r, hp in zip(rr, holm([r["pvalue"] for r in rr])):
            r["holm_44"] = float(hp)
    csv_out(dest / "protein_candidate_annotation.csv", annotations)
    csv_out(dest / "protein_measurements.csv", measures)
    csv_out(dest / "protein_results.csv", results)
    json_out(dest / "protein_run.json", {"status": "completed", "utc": utc(), "original_rows": len(table),
             "quantified_genes": len({r["symbol"] for r in measures}), "frozen_genes": 11, "measurements": len(measures),
             "tests": len(results), "scope": "Mouse-annotated processed table; human metadata conflict unresolved; no new MS search or human ASM causal proof"})
    for r in results:
        if r["sensitivity"] == "primary_all32" and r["status"] == "estimable":
            print(r, flush=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=["freeze", "acquire", "inspect", "measure"])
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    globals()[args.action](args.output.resolve())
