"""Freeze PXD033504 inputs, inspect solid archives and extract complete processed arrays."""
import argparse
import concurrent.futures
import csv
import hashlib
import json
import re
import subprocess
import time as clock
import zlib
from pathlib import Path

import py7zr

from set_protein_archive import Remote
from set_protein_extract import LocalRanges
from set_validation import rows
from validation_sources import ROOT, HERE, record, utc, json_out, csv_out, fetch

PRIOR = ROOT / "research/results/discovery_set_validation_v1"
HUMAN = ROOT / "research/results/discovery_validation_v2/human_protein"


def freeze(out):
    out.mkdir(exist_ok=False)
    (out / "sources").mkdir()
    (out / "rgo_before_secretome.md").write_bytes((ROOT / "rgo.md").read_bytes())
    genes = rows(PRIOR / "annotation.csv")
    genes += [dict(set_rank="", feature_id="control_PER1", symbol="PER1", entrez_id="4851", discovery_direction="", status="control", hgnc_ids=""),
              dict(set_rank="", feature_id="control_NR3C1", symbol="NR3C1", entrez_id="2908", discovery_direction="", status="control", hgnc_ids="")]
    assert len(genes) == 56 and len({g["feature_id"] for g in genes}) == 56
    csv_out(out / "frozen_genes.csv", genes)
    inventory = [r for r in rows(PRIOR / "public_sources/protein_file_inventory.csv") if r["project"] == "PXD033504"]
    csv_out(out / "file_inventory.csv", inventory)
    inputs = [PRIOR / "annotation.csv", PRIOR / "public_sources/PXD033504_file_inventory.json",
              PRIOR / "public_sources/protein_file_inventory.csv", HUMAN / "PMC9562650.xml",
              HUMAN / "Table S2.xlsx", ROOT / "docs/paper_cn_v6/manuscript_manifest.json",
              ROOT / "research/results/latest_manifest.json"]
    json_out(out / "analysis_freeze.json", dict(utc=utc(), protocol=record(HERE / "SECRETOME_PROTOCOL.md"),
        script=record(Path(__file__)), inputs=[record(p) for p in inputs], genes=record(out / "frozen_genes.csv"),
        inventory=record(out / "file_inventory.csv"), snapshot=record(out / "rgo_before_secretome.md"),
        timing="Prior ASM results and published detection known; original secretome candidate LFQ not read",
        candidate_family=112, full_family="All QC-passing protein groups across both timepoints; missing P=1",
        method="LFQ zeros missing/no imputation; >=2/3 technical repeats per condition, >=3 paired donor labels"))
    print("Secretome 56-gene/complete-array analysis frozen", flush=True)


def inspect(out):
    dest = out / "archives"
    dest.mkdir(exist_ok=False)
    for r in rows(out / "file_inventory.csv"):
        if r["category"] != "SEARCH":
            continue
        time = int(re.search(r"_(\d+)h_", r["fileName"])[1])
        directory = dest / f"{time}h"
        directory.mkdir()
        url = r["ftp_url"].replace("ftp://", "https://")
        remote = Remote(url, int(r["bytes"]), directory, budget=4*1024*1024)
        try:
            with py7zr.SevenZipFile(remote, "r") as archive:
                folders = archive.header.main_streams.unpackinfo.folders
                members = [dict(filename=a.filename, folder=next((i for i, f in enumerate(folders) if a.folder is f), -1),
                                bytes=a.uncompressed, crc32=a.crc32, is_directory=a.is_directory) for a in archive.files]
                targets = [a["filename"] for a in members if not a["is_directory"] and
                           (a["filename"].endswith(("proteinGroups.txt", "parameters.txt", "summary.txt", "mqpar.xml")) or
                            "samplename" in a["filename"].lower())]
                assert any(t.endswith("proteinGroups.txt") for t in targets)
                offset = archive.afterheader + archive.header.main_streams.packinfo.packpos
                blocks = []
                for i, size in enumerate(archive.header.main_streams.packinfo.packsizes):
                    blocks.append(dict(block=i, start=offset, end=offset+size-1, bytes=size))
                    offset += size
                needed = sorted({a["folder"] for a in members if a["filename"] in targets and a["bytes"] > 0})
                csv_out(directory / "members.csv", members)
                result = dict(status="pass", utc=utc(), url=url, container_bytes=int(r["bytes"]),
                              upstream_sha1=r["checksum"], targets=targets, needed_blocks=needed, packed_blocks=blocks,
                              partial_container=True, whole_archive_SHA1_verified=False)
        finally:
            json_out(directory / "header_ranges.json", dict(utc=utc(), bytes=remote.bytes, range_records=remote.logs))
        json_out(directory / "inspection.json", result)
        print(time, "h", "targets", targets, "needed block bytes", sum(blocks[i]["bytes"] for i in needed), flush=True)


def extract(out):
    attempt = len(list(out.glob("extraction_attempt_*.json"))) + 1
    json_out(out / f"extraction_attempt_{attempt}.json", dict(utc=utc(), script=record(Path(__file__)),
        concurrency=8, reason="Preserve prior connection failures, reuse hash-verified successful ranges; retries with backoff",
        coverage="Inspection shows requested mapping/table/parameters span all solid blocks; verify upstream full-container SHA1 from complete byte coverage"))
    for time in [24, 72]:
        directory = out / "archives" / f"{time}h"
        if (directory / "extraction.json").exists():
            assert json.loads((directory / "extraction.json").read_text())["status"] == "pass"
            continue
        inspected = json.loads((directory / "inspection.json").read_text())
        parts = directory / "parts"
        parts.mkdir(exist_ok=True)
        tasks = []
        for i in inspected["needed_blocks"]:
            b = inspected["packed_blocks"][i]
            tasks += [(s, min(s+256*1024-1, b["end"])) for s in range(b["start"], b["end"]+1, 256*1024)]

        def get(task):
            start, end = task
            name = f"{start}-{end}"
            body, logpath = parts / (name+".bin"), parts / (name+".json")
            if logpath.exists():
                log = json.loads(logpath.read_text())
                assert record(body) == log["body"] and log["status"] == "pass"
                return log
            attempts = []
            first = len(list(parts.glob(name+".attempt*.headers.txt")))+1
            for a in range(first, first+6):
                if a > first:
                    clock.sleep(min(2**(a-first), 15))
                header = parts / f"{name}.attempt{a}.headers.txt"
                p = subprocess.run(["curl", "--silent", "--show-error", "--location", "--connect-timeout", "10",
                                    "--max-time", "45", "--range", name, "--dump-header", str(header), inspected["url"]], capture_output=True)
                text = header.read_text()
                ranges = re.findall(r"(?im)^content-range:\s*bytes\s+(\d+)-(\d+)/(\d+)", text)
                status = re.findall(r"(?m)^HTTP/\S+\s+(\d+)", text)
                ok = p.returncode == 0 and status and status[-1] == "206" and ranges and \
                    tuple(map(int, ranges[-1])) == (start, end, inspected["container_bytes"]) and len(p.stdout) == end-start+1
                attempts.append(dict(utc=utc(), returncode=p.returncode, bytes=len(p.stdout),
                                     stderr=p.stderr.decode(errors="replace"), header=record(header)))
                if ok:
                    modified = re.findall(r"(?im)^last-modified:\s*([^\r\n]+)", text)
                    assert modified
                    body.write_bytes(p.stdout)
                    log = dict(status="pass", url=inspected["url"], start=start, end=end,
                               last_modified=modified[-1], body=record(body), attempts=attempts)
                    json_out(logpath, log)
                    return log
                failed = parts / f"{name}.attempt{a}.partial.bin"
                failed.write_bytes(p.stdout)
                attempts[-1]["failed_body"] = record(failed)
            failed = dict(status="failed", start=start, end=end, attempts=attempts)
            json_out(parts / f"{name}.failed{first}.json", failed)
            return failed

        print(time, "h acquiring", len(tasks), "ranges", flush=True)
        with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
            logs = list(pool.map(get, tasks))
        json_out(directory / f"parts_attempt_{attempt}.json", dict(utc=utc(), parts=logs))
        assert all(r["status"] == "pass" for r in logs), "Incomplete ranges; resume after inspecting saved failures"
        assert len({r["last_modified"] for r in logs}) == 1
        segments = [(r["start"], r["end"], ROOT/r["body"]["path"]) for r in logs]
        old = json.loads((directory / "header_ranges.json").read_text())
        for r in old["range_records"]:
            assert record(ROOT/r["body"]["path"]) == r["body"]
            segments.append((r["start"], r["end"], ROOT/r["body"]["path"]))
            text = (ROOT/r["headers"]["path"]).read_text()
            modified = re.findall(r"(?im)^last-modified:\s*([^\r\n]+)", text)
            assert modified and modified[-1] == logs[0]["last_modified"]
        extraction = directory / "extracted"
        extraction.mkdir(exist_ok=False)
        with py7zr.SevenZipFile(LocalRanges(inspected["container_bytes"], segments), "r") as archive:
            crcs = {a.filename:a.crc32 for a in archive.list() if a.filename in inspected["targets"]}
            archive.extract(path=extraction, targets=inspected["targets"])
        # These secretome targets span every solid block. Header+block ranges
        # therefore permit an actual full-container upstream SHA1 check.
        stream = LocalRanges(inspected["container_bytes"], segments)
        sha1, sha256 = hashlib.sha1(), hashlib.sha256()
        remaining = inspected["container_bytes"]
        while remaining:
            blob = stream.read(min(1024*1024, remaining))
            assert blob
            sha1.update(blob)
            sha256.update(blob)
            remaining -= len(blob)
        assert sha1.hexdigest() == inspected["upstream_sha1"]
        outputs = []
        for target in inspected["targets"]:
            path = extraction/target
            assert path.is_file() and zlib.crc32(path.read_bytes()) == crcs[target], target
            outputs.append(dict(**record(path), crc32=crcs[target], member=target))
        json_out(directory / "extraction.json", dict(status="pass", utc=utc(), outputs=outputs,
            range_parts=len(logs), downloaded_block_bytes=sum(r["end"]-r["start"]+1 for r in logs),
            range_records=logs, partial_container=False, whole_archive_SHA1_verified=True,
            container_sha1=sha1.hexdigest(), container_sha256=sha256.hexdigest(),
            container_bytes=inspected["container_bytes"],
            scope="Full-container byte coverage and upstream SHA1 verified; selected complete processed members extracted"))
        print(time, "h", len(outputs), "complete members CRC verified", flush=True)


def metadata(out):
    log = fetch("https://www.ebi.ac.uk/pride/ws/archive/v2/projects/PXD033504", out / "sources/PXD033504.json")
    json_out(out / "sources/project_acquisition.json", dict(utc=utc(), records=[log]))
    print(log["status"])


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=["freeze", "inspect", "extract", "metadata"])
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    globals()[args.action](args.output.resolve())
