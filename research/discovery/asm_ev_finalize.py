"""Exact schema-column evidence and final material request gates for ASM EV export."""
import argparse
import csv
import json
import re
import sqlite3
import xml.etree.ElementTree as ET
from pathlib import Path

from asm_ev_export import OUT
from validation_sources import ROOT, utc, record, json_out, csv_out, fetch


def final_routes():
    requests = [
        ("px_announcement.xml", "https://proteomecentral.proteomexchange.org/cgi/GetDataset?ID=PXD055968.0-1&outputMode=XML&test=no"),
        ("publisher_article.html", "https://www.sciencedirect.com/science/article/pii/S2589004225008077"),
        ("zenodo_article_doi.json", "https://zenodo.org/api/records?q=10.1016%2Fj.isci.2025.112546&size=20"),
    ]
    json_out(OUT / "final_routes_freeze.json", dict(utc=utc(), script=record(Path(__file__)), requests=requests,
        scope="Official version announcement and explicit DOI-linked repository routes; no candidate results"))
    logs = [fetch(url, OUT / "sources" / name, timeout=20) for name, url in requests]
    json_out(OUT / "final_routes_acquisition.json", dict(utc=utc(), records=logs))
    print(json.dumps(logs, ensure_ascii=False, indent=2))


def final():
    columns = []
    for i in range(1, 19):
        data = json.loads((OUT / f"pdresult{i:02d}_metadata.json").read_text())
        con = sqlite3.connect(":memory:")
        for r in data["schema"]:
            if r["type"] != "table":
                continue
            if r["name"] == "sqlite_sequence":
                names = ["name", "seq"]
            else:
                con.execute(r["sql"])
                quoted = '"' + r["name"].replace('"', '""') + '"'
                names = [r[1] for r in con.execute("PRAGMA table_info(" + quoted + ")")]
            columns.append(dict(file=data["name"], table=r["name"], columns="|".join(names),
                quantitative_named_columns="|".join(c for c in names if re.search("Abundance|Intensity|Quan|Area", c, re.I))))
        con.close()
    proteins = [r for r in columns if r["table"] in {"TargetProteinGroups", "TargetProteins", "TargetPeptideGroups"}]
    assert len(proteins) == 54 and not any(r["quantitative_named_columns"] for r in proteins)
    precursor = [r for r in columns if r["table"] in {"LcmsFeatures", "LcmsPeaks", "PrecursorInfoItems", "TargetPsms"}]
    assert any(r["quantitative_named_columns"] for r in precursor)
    csv_out(OUT / "schema_columns_exact.csv", columns)
    csv_out(OUT / "protein_columns_exact.csv", proteins)
    comparisons = [
        dict(item="Proteome Discoverer", pride="2.5", article="3.0", archived_result="3.1.0.638 (18/18)", status="three-way version difference; final paper analysis version unresolved"),
        dict(item="Search engine", pride="Mascot2.5", article="CHIMERYS", archived_result="CHIMERYS (18/18)", status="archive supports CHIMERYS, not the Mascot metadata"),
        dict(item="Prediction model", pride="not stated", article="inferys_2.1 fragmentation", archived_result="inferys_3.0.0_fragmentation (18/18)", status="article/archive difference"),
        dict(item="Search database", pride="UniProt September3 2020 / 75793 entries", article="UniProt September2023 / 82408 entries", archived_result="RP_UP000005640_Homo_sapiens_2024_01_22.fasta (18/18)", status="archive workflow differs from both; submitted standalone FASTA is 2023_09_13"),
        dict(item="Peptide charge", pride="not stated", article="2-4", archived_result="1-6 (18/18)", status="article/archive difference"),
        dict(item="Protein peptide requirement", pride="at least2 specific", article="master proteins quantified by at least2 unique", archived_result="CWF_ID minimum peptide sequences1 (18/18)", status="ID filter differs in meaning from final quantified filter; cannot substitute"),
        dict(item="Cross-run quantification", pride="Proline / median ratios / 5% background missing inference", article="Minora + mapper + precursor quantifier / total peptide amount / lower5% random imputation", archived_result="single raw per result; Minora detection; CWF_ID; no final protein abundance columns or mapper/quantifier", status="final quantified array and workflow not acquired"),
    ]
    csv_out(OUT / "processing_version_comparison.csv", comparisons)
    routes = []
    for name in ["acquisition.json", "inventory_acquisition.json", "export_routes_acquisition.json", "export_routes_resume_acquisition.json", "final_routes_acquisition.json"]:
        value = json.loads((OUT / name).read_text())
        for log in value.get("records", [value]):
            routes.append(dict(url=log["url"], status=log["status"], response=log.get("path", ""),
                               attempts=len(log.get("attempts", [])), detail=log.get("parsing_error", "")))
    for r in routes:
        path = ROOT / r["response"] if r["response"] else None
        if path and path.is_file():
            if "datacite" in path.name:
                r["detail"] = f"DataCite indexed hits={json.loads(path.read_text())['meta']['total']}"
            elif "zenodo" in path.name:
                r["detail"] = f"Zenodo indexed hits={json.loads(path.read_text())['hits']['total']}"
            elif path.name == "publisher_article.xml":
                root = ET.parse(path).getroot()
                r["detail"] = f"XML metadata only; originalText elements={len([e for e in root.iter() if e.tag.split('}')[-1] == 'originalText'])}"
            elif path.name == "files.json":
                r["status"] = "invalid_inventory_http200_empty"
                r["detail"] = "empty body retained; corrected file inventory has56 entries"
    csv_out(OUT / "public_routes_summary.csv", routes)
    summary = json.loads((OUT / "complete_summary.json").read_text())
    audit = json.loads((OUT / "independent_audit.json").read_text())
    assert audit["status"] == "pass"
    gaps = [
        dict(material="Unfiltered final master-protein/protein-group quantitative export", requirement="All proteins and all18 mapped runs; original and normalized abundance; zero/NA/imputation flags; protein accessions/group members and unique peptides", status="not acquired", reason="all18 submitted pdResult files are single-run CWF_ID results with no protein abundance columns"),
        dict(material="Paper-version final joint workflow and processing identity", requirement="Actual PD/Proline release, processing+consensus workflow, search database SHA, inferys model, grouping/FDR/filter/normalization/missing-data settings", status="unresolved", reason="PD2.5 vs3.0 vs3.1, inferys2.1 vs3.0, 2020 vs2023 vs2024 database differences"),
        dict(material="Original peptide/PSM-to-protein evidence and quantification mapping", requirement="Unique/shared peptides, validated confidence/q values, master/group membership, cross-run mapping", status="final version not acquired", reason="candidate identity check must be bound to correct quantified array/version"),
        dict(material="Six-patient minimal metadata and repeat definitions", requirement="Deidentified age or adult status for595/614/615/BA184/BA185/BA186; definition of triplicate culture/extraction/injection; any exclusions", status="partially acquired", reason="six patients/three repeats each mapped; per-patient ages and repeat type not defined in original linkage"),
    ]
    csv_out(OUT / "required_materials.csv", gaps)
    source_paths = [OUT / f"pdresult{i:02d}_metadata.json" for i in range(1, 19)]
    source_paths += [OUT / "sources/project.json", OUT / "sources/files_corrected.json", OUT / "sources/checksum.txt", OUT / "sources/Link_between_files.xlsx",
                     OUT / "sources/article_current.xml", OUT / "independent_audit.json", OUT / "schema_columns_exact.csv"]
    json_out(OUT / "final_evidence_freeze.json", dict(utc=utc(), inputs=[record(p) for p in source_paths],
        source_code=[record(p) for p in sorted((ROOT / "research/discovery").glob("*asm_ev*.py"))],
        protocol=record(ROOT / "research/discovery/ASM_EV_EXPORT_PROTOCOL.md"),
        note="Post-acquisition evidence freeze, not a prospective candidate analysis freeze", candidate_identity_started=False))
    json_out(OUT / "final_status.json", dict(status="blocked_missing_final_export", utc=utc(), version_inspection="completed",
        **{k: summary[k] for k in ["version_files", "versions", "search_databases", "prediction_models", "patients", "file_inventory"]},
        independent_audit="pass", protein_tables_with_no_abundance=54, exact_schema_tables=len(columns),
        required_materials=gaps, correct_full_export_acquired=False, candidate_identity_started=False,
        author_contact="draft_only_not_sent", publication="paused", online_model_calls=0))
    print(json.dumps(dict(status="blocked_missing_final_export", exact_schema_tables=len(columns),
                         protein_tables_without_abundance=len(proteins), independent_audit="pass"), indent=2))


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("action", choices=["final_routes", "final"])
    globals()[p.parse_args().action]()
