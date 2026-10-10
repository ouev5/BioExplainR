"""Independent builtin-sqlite3 and OOXML verification of EV version evidence."""
import hashlib
import json
import re
import sqlite3
import tempfile
import zipfile
import xml.etree.ElementTree as ET
from collections import Counter
from pathlib import Path

from validation_sources import ROOT, record, utc, json_out

OUT = ROOT / "research/results/discovery_asm_ev_export_v1"


def hash_blob(v):
    return dict(bytes=len(v), sha256=hashlib.sha256(v).hexdigest()) if isinstance(v, bytes) else v


def audit_database(data):
    name = data["name"]
    folder = OUT / "ranges" / name
    paths = [ROOT / r["path"] for r in data["used_ranges"]]
    last_identity = None
    ranges = []
    for path, expected in zip(paths, data["used_ranges"]):
        assert record(path) == expected
        start, end = map(int, path.stem.split("-"))
        response = json.loads(path.with_suffix(".json").read_text())
        assert response["status"] == "retrieved" and response["http_status"] == 206
        assert response["headers"]["Content-Range"] == f"bytes {start}-{end}/{data['file_bytes']}"
        assert end - start + 1 == path.stat().st_size
        identity = [response["headers"]["ETag"], response["headers"]["Last-Modified"]]
        assert identity == data["original_identity"]
        last_identity = identity
        ranges.append((start, end, path))
    with tempfile.TemporaryDirectory(prefix="asm-ev-sqlite-audit-", dir="/tmp/opencode") as tmp:
        local = Path(tmp) / name
        # Logical length matches original; only independently verified blocks are allocated.
        # This partial sparse view is NOT a new complete original database.
        with local.open("xb") as stream:
            stream.truncate(data["file_bytes"])
            for start, end, path in ranges:
                stream.seek(start)
                stream.write(path.read_bytes())
        con = sqlite3.connect(local.as_uri() + "?immutable=1&mode=ro", uri=True)
        con.execute("PRAGMA query_only=ON")
        schema = list(con.execute("SELECT type,name,tbl_name,rootpage,sql FROM sqlite_master ORDER BY type,name"))
        expected = [tuple(r[k] for k in ["type", "name", "table", "rootpage", "sql"]) for r in data["schema"]]
        assert schema == expected, name
        total_rows = 0
        for tab in data["metadata"]:
            quoted = '"' + tab["table"].replace('"', '""') + '"'
            cur = con.execute("SELECT * FROM " + quoted)
            assert [r[0] for r in cur.description] == tab["columns"]
            actual = [[hash_blob(v) for v in row] for row in cur]
            assert actual == tab["rows"], (name, tab["table"])
            assert len(actual) == tab["row_count"]
            total_rows += len(actual)
        columns = {}
        for tab in ["TargetProteinGroups", "TargetProteins", "TargetPeptideGroups"]:
            if any(r[1] == tab for r in schema):
                cols = [r[1] for r in con.execute(f'PRAGMA table_info("{tab}")')]
                columns[tab] = cols
        con.close()
    return dict(file=name, schema_records=len(schema), metadata_rows=total_rows, ranges=len(ranges),
                protein_quantitative_columns=[c for cols in columns.values() for c in cols if re.search("Abundance|Intensity|Quan|Area", c, re.I)])


def main():
    databases = []
    for i in range(1, 19):
        databases.append(audit_database(json.loads((OUT / f"pdresult{i:02d}_metadata.json").read_text())))
    msf = audit_database(json.loads((OUT / "msf01_metadata.json").read_text()))
    # Exact independent XML parameter checks rather than regex summaries.
    workflows = []
    for i in range(1, 19):
        data = json.loads((OUT / f"pdresult{i:02d}_metadata.json").read_text())
        tab = next(t for t in data["metadata"] if t["table"] == "Workflows")
        seen = []
        for row in tab["rows"]:
            r = dict(zip(tab["columns"], row))
            root = ET.fromstring(r["WorkflowXML"])
            if r["WorkflowType"] == "Consensus":
                assert root.get("TemplateName") == "CWF_ID"
                assert not any("Quantifier" in n.get("ProcessingNodeName", "") or "Mapper" in n.get("ProcessingNodeName", "") for n in root.iter("WorkflowNode"))
            if r["WorkflowType"] == "Processing":
                chimerys = next(n for n in root.iter("WorkflowNode") if n.get("ProcessingNodeName") == "ChimerysNode")
                params = {p.get("Name"): "".join(p.itertext()) for p in chimerys.iter("ProcessingNodeParameter")}
                assert params["FastaDatabase"] == "RP_UP000005640_Homo_sapiens_2024_01_22.fasta"
                assert params["PredictionModel"] == "inferys_3.0.0_fragmentation"
                seen.append(dict(database=params["FastaDatabase"], model=params["PredictionModel"]))
            xmlfile = OUT / "workflow_evidence" / f"pe210308_{i:02d}_{r['WorkflowType']}.xml"
            assert xmlfile.read_bytes() == r["WorkflowXML"].encode("utf-8")
        assert len(seen) == 1
        workflows.append(dict(file=data["name"], **seen[0]))
    ns = {"x": "http://schemas.openxmlformats.org/spreadsheetml/2006/main"}
    with zipfile.ZipFile(OUT / "sources/Link_between_files.xlsx") as book:
        shared = ["".join(t.itertext()) for t in ET.fromstring(book.read("xl/sharedStrings.xml")).findall("x:si", ns)]
        sheet = ET.fromstring(book.read("xl/worksheets/sheet1.xml"))
        linkage = []
        for row in sheet.findall("x:sheetData/x:row", ns):
            if int(row.get("r")) < 4:
                continue
            values = {}
            for cell in row.findall("x:c", ns):
                el = cell.find("x:v", ns)
                if el is None:
                    continue
                value = shared[int(el.text)] if cell.get("t") == "s" else el.text
                values[re.sub(r"\d", "", cell.get("r"))] = value
            if values:
                assert values["A"] == values["B"] == values["C"]
                linkage.append((values["A"], values["D"], values["E"], values["F"]))
    assert len(linkage) == 18 and len({r[1] for r in linkage}) == 6
    import csv
    saved = list(csv.DictReader((OUT / "sample_map_verified.csv").open()))
    assert linkage == [(r["run"], r["patient"], r["state"], r["replicate"]) for r in saved]
    # Check overlapping initial probe and later blocks for run01.
    probe = (OUT / "ranges/pe210308_01.pdResult.0-1048575.bin").read_bytes()
    overlap = 0
    for path in (OUT / "ranges/pe210308_01.pdResult").glob("*.bin"):
        start, end = map(int, path.stem.split("-"))
        if start < len(probe):
            blob = path.read_bytes()[:max(0, min(end + 1, len(probe)) - start)]
            assert blob == probe[start:start + len(blob)]
            overlap += len(blob)
    summary = json.loads((OUT / "complete_summary.json").read_text())
    assert summary["version_files"] == len(databases) == 18
    assert summary["protein_abundance_columns"] == sum(len(r["protein_quantitative_columns"]) for r in databases) == 0
    assert summary["candidate_identity_started"] is False and summary["full_correct_version_quantitative_export_acquired"] is False
    json_out(OUT / "independent_audit.json", dict(status="pass", utc=utc(),
        sqlite3_version=sqlite3.sqlite_version, original_result_files=databases, msf_crosscheck=msf,
        schema_records=sum(r["schema_records"] for r in databases), metadata_rows=sum(r["metadata_rows"] for r in databases),
        independently_verified_workflows=workflows, ooxml_linkage_rows=len(linkage),
        patients=6, repeats=dict(Counter(r[1] for r in linkage)), probe_overlap_bytes=overlap,
        scope="Independent builtin-sqlite3 readback on partial sparse byte views and OOXML sample mapping; no full-database integrity or candidate identification claim"))
    print(json.dumps(dict(status="pass", result_files=len(databases), metadata_rows=sum(r["metadata_rows"] for r in databases),
        schema_records=sum(r["schema_records"] for r in databases), patients=6, msf_crosscheck=msf), indent=2))


if __name__ == "__main__":
    main()
