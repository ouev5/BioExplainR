"""Independently re-read saved pagination, table bytes and metadata; seal new evidence."""
import argparse
import ast
from collections import Counter, defaultdict
import csv
import gzip
import hashlib
import json
import math
from pathlib import Path
import re
import urllib.parse
import xml.etree.ElementTree as ET
import zipfile

from public_proteome_continue import OUT, preceding
from validation_sources import ROOT, HERE, record, json_out, utc

MANIFEST = OUT / "public_proteome_manifest.json"
CODE_NAMES = ["public_proteome_continue.py", "public_proteome_review.py", "public_proteome_resume.py",
    "public_proteome_final_sources.py", "public_proteome_finalize.py", "public_proteome_scope.py", "audit_public_proteome.py",
    "PUBLIC_PROTEOME_CONTINUATION_PROTOCOL.md", "validation_sources.py"]


def read_json(path):
    return json.loads(path.read_text())


def read_rows(path, delimiter="\t"):
    with path.open(encoding="utf-8-sig", newline="") as stream:
        return list(csv.reader(stream, delimiter=delimiter))


def check_record(r):
    assert record(ROOT / r["path"]) == r, r["path"]


def checks():
    plan = read_json(OUT / "acquisition_plan.json")
    for r in plan["imported_inputs"] + [plan["script"], plan["protocol"]]:
        check_record(r)
    freeze = read_json(OUT / "design_review_freeze.json")
    for r in freeze["source_code"] + freeze["inputs"]:
        check_record(r)
    assert not freeze["candidate_statistics_started"]
    initial=read_json(OUT/"independent_audit.json")
    exact=record(OUT/"code_snapshot/audit_public_proteome_initial.py")
    assert (exact["bytes"],exact["sha256"]) == (initial["script"]["bytes"],initial["script"]["sha256"])
    assert initial["result"]["status"] == "pass"
    # The new handoff is prepended; the entire previous root document is retained exactly.
    before = (OUT / "rgo_before_continuation.md").read_bytes()
    current = (ROOT / "rgo.md").read_bytes()
    marker = "## 最新续接：公开蛋白组数据可及性清点（2026-10-10）".encode()
    assert current[current.index(marker):] == before[before.index(marker):]
    assert current[:current.index("## 最新续接：".encode())] == before[:before.index("## 最新续接：".encode())]
    # The preceding temporary response copies still match their recorded original acquisition logs.
    for filename in ["requests.json", "lead_requests.json"]:
        entries=read_json(OUT/"imported"/filename)
        for entry in entries:
            logs=entry["requests"] if filename=="lead_requests.json" else [entry]
            for log in logs:
                if "sha256" not in log:
                    continue
                if filename=="requests.json":
                    path=OUT/"imported"/(log["label"]+".json")
                else:
                    params=urllib.parse.parse_qs(urllib.parse.urlparse(log["url"]).query)
                    kind="files" if "/files?" in log["url"] else "project"
                    path=OUT/"imported"/f"{entry['accession']}_{kind}_{params.get('page',['0'])[0]}.json"
                actual=record(path)
                assert actual["bytes"]==log["bytes"] and actual["sha256"]==log["sha256"],path
    requests = {}
    statuses = Counter()
    for path in (OUT / "requests").glob("*.json"):
        log = read_json(path)
        requests[path.name] = log
        statuses[log["status"]] += 1
        for field in ["response", "complete_file"]:
            if field in log:
                check_record(log[field])
    saved = read_json(OUT / "request_summary.json")
    assert len(requests) == saved["request_records"] == 49
    assert dict(statuses) == saved["transport_status_counts"]
    projects, coverage, memberships = {}, [], defaultdict(set)
    for s in read_json(OUT / "search_acquisition.json")["searches"]:
        ids, totals, pages = [], [], []
        for n, log in enumerate(s["records"]):
            assert log["status"] == "retrieved" and log["http_status"] == 200
            assert log == requests[log["name"] + ".request.json"]
            check_record(log["response"])
            params = urllib.parse.parse_qs(urllib.parse.urlparse(log["url"]).query)
            assert params["page"] == [str(n)] and params["pageSize"] == ["100"]
            assert params["keyword"] == [s["parameters"]["keyword"]]
            page = read_json(ROOT / log["response"]["path"])
            headers = {k.lower(): v for k, v in log["headers"].items()}
            totals.append(int(headers["total_records"]))
            pages.append(len(page))
            for p in page:
                acc = p["accession"]
                projects.setdefault(acc, p)
                memberships[acc].add(s["label"])
                ids.append(acc)
        assert len(set(totals)) == 1 and sum(pages) == totals[0]
        assert pages[-1] < 100 and all(n == 100 for n in pages[:-1])
        assert len(ids) == len(set(ids)) == s["returned"] == s["unique_accessions"]
        assert s["complete_to_short_page"]
        coverage.append(dict(keyword=s["parameters"]["keyword"], pages=len(pages), returned=len(ids),
            unique_accessions=len(set(ids)), complete=True))
    summary = read_json(OUT / "search_summary.json")
    assert coverage == summary["searches"]
    assert [projects[k] for k in sorted(projects)] == read_json(OUT / "unique_projects.json")
    assert len(projects) == summary["unique_projects"] == 391
    metadata_fields = ["title", "projectDescription", "sampleProcessingProtocol", "dataProcessingProtocol", "keywords"]
    asm_ids = set()
    for acc, p in projects.items():
        text = "\n".join(str(p.get(k, "")) for k in metadata_fields)
        if re.search(r"smooth[ -]?muscle|\bHASM\b|\bHBSMC\b", text, re.I) and re.search(r"airway|bronch|lung|trache|pulmonary|\bHASM\b|\bHBSMC\b", text, re.I):
            asm_ids.add(acc)
    with (OUT / "project_eligibility_review.csv").open(newline="") as stream:
        eligibility = list(csv.DictReader(stream))
    assert {r["accession"] for r in eligibility} == asm_ids
    assert len(eligibility) == len(asm_ids) == summary["airway_asm_text_leads"] == 21
    assert all(r["eligibility"].startswith("not_eligible") and r["reason"] for r in eligibility)
    extra_ids = set()
    for label in ["pride_dex", "pride_gc"]:
        old = {p["accession"] for p in read_json(OUT / "imported" / (label + ".json"))}
        new = {acc for acc, values in memberships.items() if label in values}
        assert set(summary["added_beyond_old_page0"][label]) == new - old
        extra_ids |= new - old
    with (OUT / "additional_page_design_review.csv").open(newline="") as stream:
        reviews = list(csv.DictReader(stream))
    assert len(extra_ids) == len(reviews) == 18
    assert {r["accession"] for r in reviews} == extra_ids
    # Independently reconstruct the entire successful table from the partial + overlapping range.
    partial = (OUT / "sources/PXD029135_median-normalized.txt").read_bytes()
    tail = (OUT / "sources/PXD029135_median_tail.bin").read_bytes()
    rng = read_json(OUT / "hbec_range_plan.json")
    tail_log = read_json(OUT / "requests/PXD029135_median_tail.request.json")
    headers = {k.lower(): v for k, v in tail_log["headers"].items()}
    assert tail_log["http_status"] == 206 and headers["etag"] == rng["if_range"]
    assert headers["content-range"] == f"bytes {rng['offset']}-{rng['total_bytes']-1}/{rng['total_bytes']}"
    assert partial[rng["offset"]:] == tail[:32768]
    raw = (OUT / "sources/PXD029135_median-normalized_complete.txt").read_bytes()
    assert raw == partial[:rng["offset"]] + tail and len(raw) == rng["total_bytes"] == 2055550
    inventory = read_json(OUT / "imported/PXD029135_inventory.json")
    f = next(p for p in inventory if p["fileName"] == "median-normalized.txt")
    assert hashlib.sha1(raw).hexdigest() == f["checksum"].zfill(40)
    table = read_rows(OUT / "sources/PXD029135_median-normalized_complete.txt")
    assert len(table) - 1 == 3072 and len(table[0]) == 46
    assert table[0][3:] == [f"Sample_{n}" for n in range(1, 44)]
    assert all(len(r) == 46 for r in table)
    finite = missing = 0
    for row in table[1:]:
        for val in row[3:]:
            if val == "NA":
                missing += 1
            else:
                assert math.isfinite(float(val))
                finite += 1
    b = read_json(OUT / "HBEC_table_design_checks.json")
    assert (finite, missing) == (b["numeric_values"], b["NA_values"]) == (73453, 58643)
    author = read_rows(OUT / "imported/PXD029135_SRDF_File.txt")
    community = read_rows(OUT / "imported/PXD029135_PXD029135_community_annotated.sdrf.tsv")
    with (OUT / "HBEC_sample_decode.csv").open(newline="") as stream:
        decoded = list(csv.DictReader(stream))
    by_assay = {r[community[0].index("assay name")]: r for r in community[1:]}
    raw_names = {p["fileName"] for p in inventory}
    individuals = defaultdict(set)
    count = Counter()
    for i, r in enumerate(author[1:]):
        assay = r[0].replace(" ", "_")
        d = decoded[i]
        c = by_assay[assay]
        assert d["assay"] == assay and d["individual"] == r[1]
        assert [d[k] for k in ["post_ICS", "polyIC", "imiquimod", "T2high"]] == r[2:]
        assert c[community[0].index("characteristics[individual]")] == r[1]
        assert c[community[0].index("characteristics[treatment]")] == ("after ICS (budesonide) treatment" if r[2] == "1" else "before ICS treatment")
        assert c[community[0].index("characteristics[compound]")] == ("poly(I:C)" if r[3]=="1" else "imiquimod" if r[4]=="1" else "not applicable")
        assert c[community[0].index("characteristics[phenotype]")] == ("T2-high asthma" if r[5]=="1" else "T2-low asthma")
        assert c[community[0].index("comment[data file]")] == d["raw_file"] in raw_names
        count[tuple(map(int, r[2:]))] += 1
        if r[4] == "0":
            individuals[r[1]].add((r[2], r[3]))
    assert len(individuals)==10 and all(v=={("0","0"),("0","1"),("1","0"),("1","1")} for v in individuals.values())
    assert sorted(count.values()) == [1,2]+[5]*8
    for item in b["main_ICS_polyIC_T2_cells"]:
        assert count[tuple(item[k] for k in ["post_ICS", "polyIC", "imiquimod", "T2high"])] == item["samples"] == 5
    # Re-read all four complete inventories and validate their header totals / response membership.
    inventory_counts = {}
    for job in read_json(OUT / "asm_inventory_plan_acquisition.json")["projects"]:
        all_files = []
        for n, log in enumerate(job["files"]["records"]):
            assert log["status"] == "retrieved" and log["http_status"] == 200
            assert log == requests[log["name"] + ".request.json"]
            all_files.extend(read_json(ROOT / log["response"]["path"]))
        acc = job["accession"]
        assert all_files == read_json(OUT / (acc + "_inventory.json"))
        totals = [int({k.lower():v for k,v in log["headers"].items()}["total_records"]) for log in job["files"]["records"]]
        assert set(totals) == {len(all_files)}
        assert len({p["accession"] for p in all_files}) == len(all_files)
        assert job["files"]["complete_to_short_page"]
        inventory_counts[acc] = len(all_files)
    assert inventory_counts == {"PXD014171":22, "PXD015604":54, "PXD029550":72, "PXD055968":56}
    key = lambda p: (p["fileName"], p["fileSizeBytes"], p["accession"], p["checksum"])
    assert sorted(map(key, read_json(OUT / "PXD055968_inventory.json"))) == sorted(map(key, read_json(OUT / "imported/PXD055968_inventory.json")))
    ev = read_json(OUT / "EV_inventory_recheck.json")
    check_record(ev["required_materials"])
    check_record(ev["author_request"])
    assert not ev["candidate_identity_started"] and not ev["author_request_sent"]
    # Local original-byte CRC/SHA1 checks, including compressed-vs-uncompressed size distinction.
    compression = {r["file"]["path"]: r for r in read_json(OUT / "mztab_compression_checks.json")["checks"]}
    for r in read_json(OUT / "imported_processed_file_checks.json")["checks"]:
        check_record(r["file"])
        data = (ROOT / r["file"]["path"]).read_bytes()
        if r["upstream_sha1"]:
            assert hashlib.sha1(data).hexdigest()==r["upstream_sha1"].zfill(40)
        if r["file"]["path"].endswith(".gz"):
            uncompressed = gzip.decompress(data)
            assert len(uncompressed) == r["expected_bytes"]
            c = compression[r["file"]["path"]]
            assert c["compressed_bytes"]==len(data) and c["uncompressed_bytes"]==len(uncompressed)
            lines = [line.split("\t") for line in uncompressed.decode().splitlines()]
            assert {k:sum(line[0]==k for line in lines) for k in ["PRT","PSM"]} == r["row_counts"]
            ph = next(line for line in lines if line[0]=="PRH")
            assert ph == r["protein_header"] and not any("abundance" in k.lower() for k in ph)
        else:
            assert len(data)==r["expected_bytes"]
            parsed = read_rows(ROOT/r["file"]["path"])
            assert len(parsed)-1==r["data_rows"] and parsed[0]==r["header"]
    for r in read_json(OUT / "metadata_file_checks.json")["checks"]:
        check_record(r["file"])
        data = (ROOT / r["file"]["path"]).read_bytes()
        assert len(data)==r["expected_bytes"]
        if r["upstream_sha1"]:
            assert hashlib.sha1(data).hexdigest()==r["upstream_sha1"].zfill(40)
    with zipfile.ZipFile(OUT / "sources/PXD015604_Link_between_files.xlsx") as z:
        assert z.testzip() is None
        ns={"s":"http://schemas.openxmlformats.org/spreadsheetml/2006/main"}
        strings=["".join(e.itertext()) for e in ET.fromstring(z.read("xl/sharedStrings.xml")).findall("s:si",ns)]
        cells={}
        for c in ET.fromstring(z.read("xl/worksheets/sheet1.xml")).findall(".//s:c",ns):
            value=c.find("s:v",ns)
            text=value.text if value is not None else ""
            cells[c.get("r")]=strings[int(text)] if c.get("t")=="s" else text
    linkage = read_json(OUT / "epithelium_linkage_readout.json")["rows"]
    assert {c["cell"]:c["value"] for row in linkage for c in row}==cells
    conditions = [c["value"] for row in linkage for c in row if c["cell"].startswith("C")]
    assert {f"{letter}{n}" for letter in "ABCDEF" for n in range(1, 4)} <= set(conditions)
    assert {f"{label} epi {n}" for label in ["Asthmatic", "Control"] for n in range(1, 5)} <= set(conditions)
    # Only parse genuinely retrieved article XML. Challenge HTML remains a failed article route.
    for name in ["PMC11161633.xml", "PMC8688760.xml"]:
        root = ET.parse(OUT / "sources" / name).getroot()
        assert root.tag=="article"
    assert "recaptcha" in (OUT / "sources/PMC5105184_article.html").read_text().lower()
    assert "reasonable request" in " ".join(ET.parse(OUT / "sources/PMC11161633.xml").getroot().itertext())
    for name in CODE_NAMES:
        path=HERE/name
        if path.suffix==".py":
            ast.parse(path.read_text(), filename=str(path))
    state = read_json(OUT / "final_status.json")
    assert state["eligible_adult_ASM_GC_arrays_obtained"]==0
    assert state["candidate_statistics_started"] is False and state["candidate_identity_started"] is False
    return dict(status="pass", queries=len(coverage), pages=sum(r["pages"] for r in coverage),
        total_query_hits=sum(r["returned"] for r in coverage), unique_projects=len(projects),
        additional_page_projects=18, airway_ASM_text_leads=21, complete_inventory_counts=inventory_counts,
        HBEC_rows=3072, HBEC_samples=43, HBEC_individuals=10, HBEC_finite_values=finite, HBEC_missing_values=missing,
        HBEC_balanced_T2_ICS_design=True, request_records=len(requests), transport_status_counts=dict(statuses),
        candidate_statistics_started=False, candidate_identity_started=False)


def run_checks():
    result = checks()
    json_out(OUT / "independent_audit.json", dict(utc=utc(), script=record(Path(__file__)), result=result))
    print(json.dumps(result, indent=2))


def seal():
    if MANIFEST.exists():
        raise ValueError("Refusing overwrite manifest")
    result=checks()
    prior=preceding()
    json_out(MANIFEST, dict(status="sealed", utc=utc(), files=[record(p) for p in sorted(OUT.rglob("*")) if p.is_file()],
        source_code=[record(HERE/n) for n in CODE_NAMES], documentation=[record(ROOT/"rgo.md")],
        dependencies=[record(ROOT/"research/results/discovery_asm_ev_materials_v1/handoff_manifest.json")],
        checks=result, prior_verification=prior, candidate_statistics_started=False, candidate_identity_started=False,
        author_request_sent=False, publication="paused", snapshot_policy="Latest handoff root rgo uses hash-matched pre-public-search snapshot; all other prior scientific paths/hash original"))
    result=verify()
    json_out(OUT/"verification.json", dict(utc=utc(), result=result, note="Verification output excluded from own manifest"))


def verify():
    m=read_json(MANIFEST)
    for group in ["files", "source_code", "documentation", "dependencies"]:
        for r in m[group]:
            check_record(r)
    result=checks()
    assert result==m["checks"]
    result=dict(result, sealed_files=len(m["files"]), previous_evidence=preceding())
    print(json.dumps({k:v for k,v in result.items() if k!="previous_evidence"}, indent=2))
    return result


if __name__=="__main__":
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument("action", choices=["check", "seal", "verify"])
    args=p.parse_args()
    {"check":run_checks,"seal":seal,"verify":verify}[args.action]()
