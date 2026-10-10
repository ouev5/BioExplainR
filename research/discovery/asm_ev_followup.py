"""Resolve public export routes and material gaps from saved original EV workflows."""
import argparse
import csv
import json
import re
import urllib.parse
import xml.etree.ElementTree as ET
from collections import Counter
from pathlib import Path

from asm_ev_export import OUT, BASE
from validation_sources import ROOT, utc, record, json_out, csv_out, fetch

PRIOR = ROOT / "research/results/discovery_secretome_provenance_v1"
REQUESTS = [
    ("article_current.xml", "https://www.ebi.ac.uk/europepmc/webservices/rest/PMC12141081/fullTextXML"),
    ("pmc_oa_manifest.xml", "https://www.ncbi.nlm.nih.gov/pmc/utils/oa/oa.fcgi?id=PMC12141081"),
    ("datacite_accession.json", "https://api.datacite.org/dois?query=PXD055968"),
    ("datacite_article_doi.json", "https://api.datacite.org/dois?" + urllib.parse.urlencode({"query": '"10.1016/j.isci.2025.112546"'})),
    ("crossref_article.json", "https://api.crossref.org/works/10.1016/j.isci.2025.112546"),
    ("zenodo_accession.json", "https://zenodo.org/api/records?" + urllib.parse.urlencode({"q": '"PXD055968"', "size": 100})),
    ("figshare_article_doi.json", "https://api.figshare.com/v2/articles?" + urllib.parse.urlencode({"resource_doi": "10.1016/j.isci.2025.112546"})),
    ("Link_between_files.xlsx", BASE + "Link_between_files.xlsx"),
]


def acquire():
    json_out(OUT / "export_routes_freeze.json", dict(utc=utc(), script=record(Path(__file__)), requests=REQUESTS,
        reason="18 archived results are single-run PD3.1 CHIMERYS identification workflows; inspect official article links and bounded repository routes for final cross-run export",
        scope="No candidate or differential-abundance lookup"))
    logs = []
    for name, url in REQUESTS:
        log = fetch(url, OUT / "sources" / name, timeout=20)
        if log["status"] == "retrieved":
            path = OUT / "sources" / name
            try:
                if name.startswith("datacite"):
                    value = json.loads(path.read_text())
                    log.update(valid_response=True, hits=value["meta"]["total"])
                elif name.startswith("crossref"):
                    value = json.loads(path.read_text())["message"]
                    log.update(valid_response=True, DOI=value["DOI"], relations=value.get("relation", {}), links=value.get("link", []))
                elif name.startswith("zenodo"):
                    log.update(valid_response=True, hits=json.loads(path.read_text())["hits"]["total"])
                elif name.endswith("xml"):
                    ET.parse(path)
                    log["valid_response"] = True
            except Exception as exc:
                log.update(valid_response=False, parsing_error=str(exc))
        logs.append(log)
    json_out(OUT / "export_routes_acquisition.json", dict(utc=utc(), records=logs))
    print(json.dumps(logs, ensure_ascii=False, indent=2))


def complete():
    # Keep preliminary regex-based output intact; corrected evidence uses SQLite DDL
    # identifier extraction for BOTH double-quoted and bracket-quoted identifiers.
    rows = []
    parameters = []
    schema_columns = []
    nodes = []
    for i in range(1, 19):
        data = json.loads((OUT / f"pdresult{i:02d}_metadata.json").read_text())
        tables = {t["table"]: [dict(zip(t["columns"], r)) for r in t["rows"]] for t in data["metadata"]}
        processing = next(r for r in tables["Workflows"] if r["WorkflowType"] == "Processing")
        consensus = next(r for r in tables["Workflows"] if r["WorkflowType"] == "Consensus")
        proc = ET.fromstring(processing["WorkflowXML"])
        cons = ET.fromstring(consensus["WorkflowXML"])
        selected = {}
        for kind, root in [("Processing", proc), ("Consensus", cons)]:
            for node in root.iter("WorkflowNode"):
                nodes.append(dict(file=data["name"], workflow=kind, name=node.get("ProcessingNodeName"),
                                  friendly_name=node.get("FriendlyName")))
                for p in node.iter("ProcessingNodeParameter"):
                    if p.get("Name") in {"FastaDatabase", "PredictionModel", "MinimumPeptideCharge", "MaximumPeptideCharge", "TargetFPRHigh",
                                         "TargetPeptideFPRHigh", "NumberOfPeptidesRequiredFilter", "ProcessingMode"}:
                        value = "".join(p.itertext()).strip()
                        parameters.append(dict(file=data["name"], workflow=kind, node=node.get("ProcessingNodeName"),
                                               parameter=p.get("Name"), value=value))
                        selected[p.get("Name")] = value
        quant_columns = {}
        protein_columns = {}
        for r in data["schema"]:
            if r["type"] != "table":
                continue
            columns = re.findall(r'(?:"([^"]+)"|\[([^\]]+)\])\s+(?:int64|int|double|BLOB|\[varchar\]|\[int\]|\[varchar\])', r["sql"], re.I)
            names = [a or b for a, b in columns]
            quant = [n for n in names if re.search("Abundance|Intensity|Quan|Area", n, re.I)]
            if quant:
                quant_columns[r["name"]] = quant
            if r["name"] in {"TargetProteinGroups", "TargetProteins", "TargetPeptideGroups"}:
                protein_columns[r["name"]] = names
            schema_columns.append(dict(file=data["name"], table=r["name"], columns="|".join(names), quantitative_named_columns="|".join(quant)))
        raw = [r for r in tables["WorkflowInputFiles"] if r["FileType"] == "XcaliburRawfile"]
        study = ET.fromstring(tables["AnalysisDefinition"][0]["AnalysisDefinitionXML"])
        row = dict(file=data["name"], software="|".join(sorted({r["SoftwareVersion"] for r in tables["SchemaInfo"]})),
            raw_file=raw[0]["FileName"].split("\\")[-1], raw_bytes=raw[0]["FileSize"], samples=len(tables["StudyInformation"]),
            consensus_template=cons.get("TemplateName"), processing_template=proc.get("TemplateName"),
            search_database=selected["FastaDatabase"], prediction_model=selected["PredictionModel"],
            minimum_charge=selected["MinimumPeptideCharge"], maximum_charge=selected["MaximumPeptideCharge"],
            minimum_peptide_sequences=selected["NumberOfPeptidesRequiredFilter"],
            consensus_quantifier_nodes=sum("Quantifier" in n["name"] or "Mapper" in n["name"] for n in nodes if n["file"] == data["name"] and n["workflow"] == "Consensus"),
            protein_abundance_columns=sum(bool(re.search("Abundance|Intensity|Quan|Area", c, re.I)) for tab in protein_columns.values() for c in tab),
            precursor_intensity_tables="|".join(sorted(t for t in quant_columns if t in {"LcmsFeatures", "LcmsPeaks", "PrecursorInfoItems", "TargetPsms"})),
            study_factors=len(study.findall("./StudyDefinition/Factors/*")),
            whole_file_sha1_verified=False, full_final_export=False)
        rows.append(row)
    files = json.loads((OUT / "sources/files_corrected.json").read_text())
    names = {r["fileName"] for r in files}
    assert {r["raw_file"] for r in rows} == {r["fileName"] for r in files if r["fileName"].endswith(".raw")}
    assert all(next(f["fileSizeBytes"] for f in files if f["fileName"] == r["raw_file"]) == r["raw_bytes"] for r in rows)
    checksums = dict(line.split("\t")[0].split("\\")[-1:] + line.split("\t")[1:] for line in (OUT / "sources/checksum.txt").read_text().splitlines() if "\t" in line)
    assert set(checksums) == names
    import openpyxl
    book = openpyxl.load_workbook(OUT / "sources/Link_between_files.xlsx", read_only=True, data_only=True)
    linkage = []
    for row in list(book.worksheets[0].values)[3:]:
        run, msf, pdresult, patient, state, replicate = row
        assert run == msf == pdresult
        linkage.append(dict(run=run, patient=str(patient), state=state, replicate=replicate,
                            age="not provided for this patient", independent_unit="patient"))
    assert len(linkage) == 18 and len({r["patient"] for r in linkage}) == 6
    assert {r["raw_file"][:-4] for r in rows} == {r["run"] for r in linkage}
    manifest_sha1 = __import__("hashlib").sha1((OUT / "sources/Link_between_files.xlsx").read_bytes()).hexdigest()
    assert manifest_sha1 == checksums["Link_between_files.xlsx"]
    current_xml = ET.parse(OUT / "sources/article_current.xml").getroot()
    links = [dict(tag=e.tag, href=e.get("{http://www.w3.org/1999/xlink}href"), text=" ".join("".join(e.itertext()).split()))
             for e in current_xml.iter() if e.tag in {"media", "ext-link", "supplementary-material"} and e.get("{http://www.w3.org/1999/xlink}href")]
    media = {r["href"] for r in links if r["tag"] == "media"}
    csv_out(OUT / "version_evidence_complete.csv", rows)
    csv_out(OUT / "schema_columns_complete.csv", schema_columns)
    csv_out(OUT / "workflow_parameters_complete.csv", parameters)
    csv_out(OUT / "sample_map_verified.csv", linkage)
    csv_out(OUT / "article_links_current.csv", links)
    csv_out(OUT / "PXD055968_file_inventory_verified.csv", [dict(file=f["fileName"], bytes=f["fileSizeBytes"], category=f["fileCategory"]["value"], upstream_sha1=checksums[f["fileName"]]) for f in files])
    notes = dict(status="pass", utc=utc(), version_files=len(rows), versions=sorted({r["software"] for r in rows}),
        search_databases=sorted({r["search_database"] for r in rows}), prediction_models=sorted({r["prediction_model"] for r in rows}),
        samples=18, patients=6, per_patient_repeats=dict(Counter(r["patient"] for r in linkage)),
        file_inventory=56, file_categories=dict(Counter(f["fileCategory"]["value"] for f in files)),
        protein_abundance_columns=sum(r["protein_abundance_columns"] for r in rows),
        consensus_quantifier_nodes=sum(r["consensus_quantifier_nodes"] for r in rows),
        original_file_bytes=sum(f["fileSizeBytes"] for f in files), submitted_pdresult_bytes=sum(f["fileSizeBytes"] for f in files if f["fileName"].endswith(".pdResult")),
        linkage_sha1_verified=manifest_sha1, article_supplement_links=sorted(media),
        full_correct_version_quantitative_export_acquired=False, candidate_identity_started=False,
        reason="Submitted results are 18 single-run identification-only consensus workflows, with precursor features but no final protein abundance columns or cross-run mapper/quantifier; final paper-version export not acquired",
        scope="Structural version/source evidence only; no protein result rows, no candidate lookup, no disease or GC hypothesis tests")
    json_out(OUT / "complete_summary.json", notes)
    print(json.dumps(notes, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("action", choices=["acquire", "complete"])
    globals()[p.parse_args().action]()
