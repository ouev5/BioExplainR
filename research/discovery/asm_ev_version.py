"""Inspect every submitted EV result's workflow without candidate/abundance lookups."""
import argparse
import json
import re
import xml.etree.ElementTree as ET
from concurrent.futures import ProcessPoolExecutor, as_completed
from pathlib import Path

from asm_ev_export import OUT
from asm_ev_sqlite import inspect
from validation_sources import utc, record, json_out, csv_out

TABLES = ["SchemaInfo", "WorkflowInputFiles", "Workflows", "StudyInformation", "AnalysisDefinition", "DataTypesColumns"]
VERSION_TABLES = TABLES[:-1]


def batch():
    json_out(OUT / "batch_freeze.json", dict(utc=utc(), script=record(Path(__file__)),
        reader=record(Path(__file__).with_name("asm_ev_sqlite.py")), files=[f"pe210308_{i:02d}.pdResult" for i in range(2, 19)],
        tables=TABLES, blocksize=262144, limit_per_file_bytes=67108864,
        scope="All18 version/sample/schema metadata, no candidate lookup, no protein or peptide result rows"))
    logs = []
    for i in range(2, 19):
        name = f"pe210308_{i:02d}.pdResult"
        try:
            result = inspect(name, f"pdresult{i:02d}_metadata", TABLES, blocksize=262144)
            logs.append(dict(name=name, status="pass", file=record(OUT / f"pdresult{i:02d}_metadata.json"),
                             cached_bytes=result["cached_bytes"]))
        except Exception as exc:
            logs.append(dict(name=name, status="failed", utc=utc(), error=str(exc)))
            print(name, str(exc), flush=True)
    json_out(OUT / "batch_acquisition.json", dict(utc=utc(), records=logs))


def resume_file(i):
    name = f"pe210308_{i:02d}.pdResult"
    try:
        result = inspect(name, f"pdresult{i:02d}_metadata", VERSION_TABLES, blocksize=262144)
        return dict(name=name, status="pass", file=record(OUT / f"pdresult{i:02d}_metadata.json"),
                    cached_bytes=result["cached_bytes"])
    except Exception as exc:
        return dict(name=name, status="failed", utc=utc(), error=str(exc))


def resume(label="batch_resume"):
    missing = [i for i in range(2, 19) if not (OUT / f"pdresult{i:02d}_metadata.json").exists()]
    json_out(OUT / (label + "_freeze.json"), dict(utc=utc(), script=record(Path(__file__)),
        reader=record(Path(__file__).with_name("asm_ev_sqlite.py")), missing=missing, tables=VERSION_TABLES,
        reason="600s execution cutoff; retain completed metadata and cached ranges; version/sample/workflow tables suffice without DataTypesColumns rows",
        workers=4, range_timeout_seconds=15, candidate_lookups=0))
    logs = []
    with ProcessPoolExecutor(max_workers=4) as pool:
        jobs = {pool.submit(resume_file, i): i for i in missing}
        for job in as_completed(jobs):
            value = job.result()
            logs.append(value)
            print(json.dumps(value), flush=True)
    json_out(OUT / (label + "_acquisition.json"), dict(utc=utc(), records=logs))


def summarize():
    rows = []
    nodes = []
    columns = []
    evidence = OUT / "workflow_evidence"
    evidence.mkdir()
    for i in range(1, 19):
        path = OUT / f"pdresult{i:02d}_metadata.json"
        data = json.loads(path.read_text())
        tables = {r["table"]: r for r in data["metadata"]}
        row = dict(file=data["name"], original_bytes=data["file_bytes"], cached_bytes=data["cached_bytes"],
            software_versions="|".join(sorted({r[3] for r in tables["SchemaInfo"]["rows"]})),
            raw_files="|".join(r[3].split("\\")[-1] for r in tables["WorkflowInputFiles"]["rows"] if r[8] == "XcaliburRawfile"),
            study_samples=tables["StudyInformation"]["row_count"], workflows=tables["Workflows"]["row_count"],
            quantification_nodes="", chimerys=False, fasta_databases="", prediction_models="",
            quantification_schema_columns="", study_quantitation_methods=0, original_sha1_verified=False)
        raw_nodes = []
        for wf in tables["Workflows"]["rows"]:
            obj = dict(zip(tables["Workflows"]["columns"], wf))
            root = ET.fromstring(obj["WorkflowXML"])
            xmlpath = evidence / f"pe210308_{i:02d}_{obj['WorkflowType']}.xml"
            xmlpath.write_text(obj["WorkflowXML"], encoding="utf-8")
            for node in root.iter("WorkflowNode"):
                pars = []
                for param in node.iter("ProcessingNodeParameter"):
                    pars.append(dict(attributes=param.attrib, text="".join(param.itertext()).strip()))
                nodes.append(dict(file=data["name"], workflow=obj["WorkflowType"], name=node.get("ProcessingNodeName"),
                                  friendly_name=node.get("FriendlyName"), parameters=json.dumps(pars, ensure_ascii=False)))
                raw_nodes.append(node.get("FriendlyName", ""))
        row["chimerys"] = any("CHIMERYS" in n.upper() for n in raw_nodes)
        row["quantification_nodes"] = "|".join(n for n in raw_nodes if re.search("Minora|Quantifi|Quantit|Mapper", n, re.I))
        fulltext = " ".join(r[10] for r in tables["Workflows"]["rows"])
        row["fasta_databases"] = "|".join(sorted(set(re.findall(r"[A-Za-z0-9_.-]+\.fasta", fulltext))))
        row["prediction_models"] = "|".join(sorted(set(re.findall(r"inferys_[A-Za-z0-9_.-]+", fulltext))))
        definition = ET.fromstring(tables["AnalysisDefinition"]["rows"][0][1])
        (evidence / f"pe210308_{i:02d}_AnalysisDefinition.xml").write_text(tables["AnalysisDefinition"]["rows"][0][1], encoding="utf-8")
        row["study_quantitation_methods"] = len(list(definition.iter("QuantitationMethod")))
        for r in data["schema"]:
            if r["type"] == "table":
                terms = re.findall(r"\[[^\]]*(?:Abundance|Intensity|Quan)[^\]]*\]", r["sql"], re.I)
                if terms:
                    columns.append(dict(file=data["name"], table=r["name"], column_terms="|".join(terms)))
        row["quantification_schema_columns"] = "|".join(r["table"] + ":" + r["column_terms"] for r in columns if r["file"] == data["name"])
        rows.append(row)
    csv_out(OUT / "version_evidence.csv", rows)
    csv_out(OUT / "workflow_nodes.csv", nodes)
    csv_out(OUT / "quantification_schema_columns.csv", columns, ["file", "table", "column_terms"])
    json_out(OUT / "version_summary.json", dict(status="pass", utc=utc(), files=len(rows),
        versions=sorted({r["software_versions"] for r in rows}), single_sample_files=sum(r["study_samples"] == 1 for r in rows),
        chimerys_files=sum(r["chimerys"] for r in rows), quantification_nodes=sorted({r["quantification_nodes"] for r in rows}),
        whole_original_databases_verified=0, candidate_lookups=0, rows=rows))
    print(json.dumps(rows, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("action", choices=["batch", "resume", "summarize"])
    p.add_argument("--label", default="batch_resume")
    a = p.parse_args()
    resume(a.label) if a.action == "resume" else globals()[a.action]()
