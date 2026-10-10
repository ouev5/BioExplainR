"""Download the remaining accessible processed files from saved PRIDE inventories."""
import argparse
from collections import Counter
from concurrent.futures import ThreadPoolExecutor
import csv
import gzip
import hashlib
import json
from pathlib import Path
import re
import subprocess
import time
import zipfile

from validation_sources import ROOT, record, utc, json_out, csv_out

OUT = ROOT / "research/results/discovery_public_download_v1"
PUBLIC = ROOT / "research/results/discovery_public_proteome_v1"
PAPER = ROOT / "docs/paper_cn_v7"
SCRIPT = Path(__file__).resolve()
CHUNK = 512 * 1024
SELECTION = {
    "PXD029028": ["pepide_matrix.csv", "peptide_annotations.csv",
                  "PXD029028_community_annotated.sdrf.tsv"],
    "PXD014171": ["proteinGroups.txt"],
    "PXD015566": ["Linkbetweenfiles.xlsx"],
}
FIBROBLAST = ["PXD003963", "PXD003965", "PXD003971"]


def inventory_path(acc):
    folder = PUBLIC if acc == "PXD014171" else PUBLIC / "imported"
    return folder / (acc + "_inventory.json")


def read_json(path):
    return json.loads(path.read_text())


def check_record(item):
    assert record(ROOT / item["path"]) == item, item["path"]


def prepare():
    if OUT.exists():
        raise ValueError(f"Refusing overwrite: {OUT}")
    OUT.mkdir()
    for name in ["sources", "requests", "ranges"]:
        (OUT / name).mkdir()
    snapshot = OUT / "rgo_before_download.md"
    snapshot.write_bytes((ROOT / "rgo.md").read_bytes())
    prior = read_json(PAPER / "manuscript_manifest.json")
    expected = next(r for r in prior["documentation"] if r["path"] == "rgo.md")
    assert (record(snapshot)["bytes"], record(snapshot)["sha256"]) == (expected["bytes"], expected["sha256"])
    inputs, jobs, reuse = [], [], []
    for acc in list(SELECTION) + FIBROBLAST:
        path = inventory_path(acc)
        inputs.append(record(path))
        files = read_json(path)
        names = SELECTION.get(acc, [f["fileName"] for f in files if f["fileName"].endswith(".pride.mztab.gz")])
        for name in sorted(names):
            source = next(f for f in files if f["fileName"] == name)
            url = next(p["value"] for p in source["publicFileLocations"] if p["name"] == "FTP Protocol")
            saved = PUBLIC / "imported" / (acc + "_" + name)
            item = dict(project=acc, name=name, expected=source, url=url.replace("ftp://", "https://"))
            if saved.exists():
                reuse.append(dict(item, file=record(saved)))
            else:
                jobs.append(item)
    for acc, name, saved in [
        ("PXD063431", "240221_PB_ProteomeDiscoverer_all_Proteins_A549.txt", PUBLIC / "imported/PXD063431_240221_PB_ProteomeDiscoverer_all_Proteins_A549.txt"),
        ("PXD029135", "median-normalized.txt", PUBLIC / "sources/PXD029135_median-normalized_complete.txt"),
    ]:
        path = inventory_path(acc)
        inputs.append(record(path))
        source = next(f for f in read_json(path) if f["fileName"] == name)
        reuse.append(dict(project=acc, name=name, expected=source, file=record(saved)))
    for name in ["PXD029028_meta_data.csv", "PXD029028_DDA_sample_ID.csv"]:
        inputs.append(record(PUBLIC / "imported" / name))
    json_out(OUT / "download_plan.json", dict(utc=utc(), script=record(SCRIPT), inputs=inputs,
        snapshot=record(snapshot), previous_manifest=record(PAPER / "manuscript_manifest.json"),
        jobs=jobs, reused=reuse, skipped_project="PXD055968", author_request_sent=False,
        request_max_seconds=60, connect_timeout_seconds=10, chunk_bytes=CHUNK,
        scope="Processed tables, peptide mapping and sample metadata; acquisition and structural checks only"))
    print(json.dumps(dict(new_files=len(jobs), reused_files=len(reuse), skipped_project="PXD055968"), indent=2))


def check_plan():
    plan = read_json(OUT / "download_plan.json")
    for r in plan["inputs"] + [plan["script"], plan["snapshot"], plan["previous_manifest"]]:
        check_record(r)
    for item in plan["reused"]:
        check_record(item["file"])
    return plan


def request(job, start=None):
    label = job["project"] + "_" + job["name"]
    if start is not None:
        label += f".{start}"
    body = OUT / "ranges" / (label + ".bin")
    headers = OUT / "requests" / (label + ".headers.txt")
    logpath = OUT / "requests" / (label + ".json")
    if any(p.exists() for p in [body, headers, logpath]):
        raise ValueError(f"Refusing overwrite request: {label}")
    args = ["curl", "--silent", "--show-error", "--location", "--fail", "--connect-timeout", "10",
            "--max-time", "60", "--header", "Accept-Encoding: identity", "--user-agent",
            "BioExplainR-public-download/0.4", "--dump-header", str(headers), "--output", str(body)]
    size = job["expected"]["fileSizeBytes"]
    end = min(start + CHUNK, size) - 1 if start is not None else None
    if start is not None:
        args += ["--range", f"{start}-{end}"]
    args.append(job["url"])
    begun = time.monotonic()
    log = dict(utc=utc(), url=job["url"], start=start, end=end)
    result = subprocess.run(args, capture_output=True, text=True, timeout=65)
    log.update(exit_code=result.returncode, stderr=result.stderr, seconds=time.monotonic() - begun,
               completed_utc=utc(), headers=record(headers))
    if body.exists():
        log["response"] = record(body)
    content = headers.read_text().lower()
    status = re.findall(r"^http/\S+\s+(\d+)", content, re.M)
    log["http_status"] = int(status[-1]) if status else None
    valid = result.returncode == 0 and body.exists()
    if start is not None:
        valid = valid and log["http_status"] == 206 and body.stat().st_size == end - start + 1
        valid = valid and f"content-range: bytes {start}-{end}/{size}" in content
    else:
        valid = valid and log["http_status"] == 200
    log["status"] = "retrieved" if valid else "failed_or_partial"
    json_out(logpath, log)
    return log


def integrity(path, expected):
    blob = path.read_bytes()
    actual_sha1 = hashlib.sha1(blob).hexdigest()
    checksum = expected.get("checksum")
    matches = actual_sha1 == checksum.zfill(40) if checksum else None
    expanded = gzip.decompress(blob) if path.name.endswith(".gz") else blob
    valid = len(expanded) == expected["fileSizeBytes"] and matches is not False
    return dict(file=record(path), valid=valid, sha1=actual_sha1, upstream_sha1_matches=matches,
                stored_bytes=len(blob), uncompressed_bytes=len(expanded), gzip_crc_pass=path.name.endswith(".gz"))


def acquire():
    plan = check_plan()
    if (OUT / "acquisition.json").exists():
        raise ValueError("Acquisition already recorded")

    def one(job):
        size = job["expected"]["fileSizeBytes"]
        ranged = size > 1024 * 1024 and not job["name"].endswith(".gz")
        if ranged:
            with ThreadPoolExecutor(max_workers=6) as pool:
                logs = list(pool.map(lambda start: request(job, start), range(0, size, CHUNK)))
        else:
            logs = [request(job)]
        dest = OUT / "sources" / (job["project"] + "_" + job["name"])
        item = dict(project=job["project"], name=job["name"], ranged=ranged, requests=logs)
        if all(log["status"] == "retrieved" for log in logs):
            with dest.open("xb") as stream:
                for log in logs:
                    stream.write((ROOT / log["response"]["path"]).read_bytes())
            item["integrity"] = integrity(dest, job["expected"])
            item["status"] = "verified" if item["integrity"]["valid"] else "integrity_failed"
        else:
            item["status"] = "failed_or_partial"
        print(job["project"] + " / " + job["name"] + " / " + item["status"], flush=True)
        return item

    with ThreadPoolExecutor(max_workers=3) as pool:
        results = list(pool.map(one, plan["jobs"]))
    json_out(OUT / "acquisition.json", dict(utc=utc(), results=results))


def table_check(path):
    if path.name.endswith(".xlsx"):
        with zipfile.ZipFile(path) as archive:
            assert archive.testzip() is None
            return dict(type="xlsx", zip_crc_pass=True, sheets=[n for n in archive.namelist() if n.startswith("xl/worksheets/sheet")])
    blob = gzip.decompress(path.read_bytes()) if path.name.endswith(".gz") else path.read_bytes()
    text = blob.decode("utf-8-sig")
    if path.name.endswith(".mztab.gz"):
        lines = [line.split("\t") for line in text.splitlines() if line]
        headers = {r[0]: r for r in lines if r[0] in ["PRH", "PSH"]}
        for kind, header in [("PRT", "PRH"), ("PSM", "PSH")]:
            assert all(len(r) == len(headers[header]) for r in lines if r[0] == kind)
        return dict(type="mzTab_identification", rows=dict(Counter(r[0] for r in lines)), protein_header=headers["PRH"],
                    protein_abundance_columns=[s for s in headers["PRH"] if "abundance" in s.lower()])
    delimiter = "," if path.name.endswith(".csv") else "\t"
    rows = [r for r in csv.reader(text.splitlines(), delimiter=delimiter) if r]
    assert rows and all(len(r) == len(rows[0]) for r in rows)
    return dict(type="delimited_table", data_rows=len(rows) - 1, columns=len(rows[0]), header=rows[0])


def summarize():
    plan = check_plan()
    acquired = read_json(OUT / "acquisition.json")["results"]
    entries = []
    for job, result in zip(plan["jobs"], acquired):
        assert (job["project"], job["name"]) == (result["project"], result["name"])
        if result["status"] == "verified":
            path = ROOT / result["integrity"]["file"]["path"]
            entries.append(dict(project=job["project"], name=job["name"], acquisition="new_download",
                                integrity=integrity(path, job["expected"]), structure=table_check(path)))
    for item in plan["reused"]:
        path = ROOT / item["file"]["path"]
        entries.append(dict(project=item["project"], name=item["name"], acquisition="reused_local",
                            integrity=integrity(path, item["expected"]), structure=table_check(path)))
    assert all(item["integrity"]["valid"] for item in entries)
    json_out(OUT / "file_checks.json", dict(utc=utc(), entries=entries,
        new_verified=sum(r["status"] == "verified" for r in acquired),
        failed_or_partial=[dict(project=r["project"], name=r["name"], status=r["status"]) for r in acquired if r["status"] != "verified"]))
    csv_out(OUT / "download_index.csv", [dict(project=r["project"], name=r["name"], acquisition=r["acquisition"],
        path=r["integrity"]["file"]["path"], bytes=r["integrity"]["stored_bytes"],
        sha256=r["integrity"]["file"]["sha256"], upstream_sha1_matches=r["integrity"]["upstream_sha1_matches"],
        data_rows=r["structure"].get("data_rows", r["structure"].get("rows", {}).get("PRT", "")),
        columns=r["structure"].get("columns", ""), type=r["structure"]["type"]) for r in entries])
    print(json.dumps(dict(complete_files=len(entries), new_files=sum(r["acquisition"] == "new_download" for r in entries)), indent=2))


def prior_integrity():
    """Read-only check of v0.13's bound files and archive with the exact old rgo."""
    manifest = read_json(PAPER / "manuscript_manifest.json")
    snapshot = OUT / "rgo_before_download.md"
    count = 0
    for group in ["files", "source_code", "documentation", "dependencies"]:
        for item in manifest[group]:
            if item["path"] == "rgo.md":
                actual = dict(record(snapshot), path="rgo.md")
                assert actual == item
            else:
                check_record(item)
            count += 1
    check_record(manifest["archive"])
    current, before = (ROOT / "rgo.md").read_bytes(), snapshot.read_bytes()
    marker = "## 最新续接：论文v0.13".encode()
    assert current[current.index(marker):] == before[before.index(marker):]
    return dict(status="pass", checked_records=count, archive_sha256=manifest["archive"]["sha256"],
                scope="v0.13 bound files/archive; full layered audit passed before downloads")


def seal():
    prior = prior_integrity()
    json_out(OUT / "download_manifest.json", dict(utc=utc(), status="sealed",
        files=[record(p) for p in sorted(OUT.rglob("*")) if p.is_file()],
        source_code=[record(SCRIPT), record(SCRIPT.with_name("validation_sources.py"))],
        documentation=[record(ROOT / "rgo.md")], prior_integrity=prior,
        candidate_statistics_started=False, author_request_sent=False,
        PXD055968_status="skipped_by_user; final_export_still_missing"))


def verify():
    manifest = read_json(OUT / "download_manifest.json")
    for group in ["files", "source_code", "documentation"]:
        for item in manifest[group]:
            check_record(item)
    plan = check_plan()
    expected = {(j["project"], j["name"]): j["expected"] for j in plan["jobs"] + plan["reused"]}
    checks = read_json(OUT / "file_checks.json")
    for item in checks["entries"]:
        path = ROOT / item["integrity"]["file"]["path"]
        assert integrity(path, expected[item["project"], item["name"]]) == item["integrity"]
        assert table_check(path) == item["structure"]
    assert prior_integrity() == manifest["prior_integrity"]
    result = dict(status="pass", sealed_files=len(manifest["files"]), complete_files=len(checks["entries"]),
                  new_downloads=checks["new_verified"], failed_or_partial=checks["failed_or_partial"],
                  PXD055968="skipped_by_user", candidate_statistics_started=False)
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=["prepare", "acquire", "summarize", "seal", "verify"])
    globals()[parser.parse_args().action]()
