"""Acquire PXD055968 version evidence before any candidate identity inspection."""
import argparse
import json
import urllib.request
from pathlib import Path

from validation_sources import ROOT, HERE, utc, record, json_out, fetch
from seal_secretome_provenance import verify as verify_prior

OUT = ROOT / "research/results/discovery_asm_ev_export_v1"
BASE = "https://ftp.pride.ebi.ac.uk/pride/data/archive/2025/11/PXD055968/"
REQUESTS = [
    ("project.json", "https://www.ebi.ac.uk/pride/ws/archive/v2/projects/PXD055968"),
    ("files.json", "https://www.ebi.ac.uk/pride/ws/archive/v2/files/byProject?accession=PXD055968&pageSize=1000&page=0"),
    ("directory.html", BASE),
    ("checksum.txt", BASE + "checksum.txt"),
    ("proteomecentral.html", "https://proteomecentral.proteomexchange.org/cgi/GetDataset?ID=PXD055968"),
]


def start():
    if OUT.exists():
        raise ValueError(f"Refusing overwrite {OUT}")
    prior = verify_prior()
    OUT.mkdir()
    (OUT / "sources").mkdir()
    (OUT / "ranges").mkdir()
    (OUT / "rgo_before_asm_ev_export.md").write_bytes((ROOT / "rgo.md").read_bytes())
    json_out(OUT / "prior_verification.json", dict(utc=utc(), result=prior))
    json_out(OUT / "acquisition_freeze.json", dict(
        utc=utc(), script=record(Path(__file__)), protocol=record(HERE / "ASM_EV_EXPORT_PROTOCOL.md"),
        snapshot=record(OUT / "rgo_before_asm_ev_export.md"), requests=REQUESTS,
        initial_database="pe210308_01.pdResult", initial_range=[0, 1048575],
        scope="Version/schema evidence only; no candidate identity or effects inspected",
        prior_manifest=record(ROOT / "docs/secretome_provenance_v1/provenance_manifest.json")))
    logs = [fetch(url, OUT / "sources" / name, timeout=30) for name, url in REQUESTS]
    json_out(OUT / "acquisition.json", dict(utc=utc(), records=logs))
    print(json.dumps(logs, ensure_ascii=False, indent=2))


def probe(name, length):
    path = OUT / "ranges" / (name + f".0-{length - 1}.bin")
    log_path = path.with_suffix(".json")
    if path.exists() or log_path.exists():
        raise ValueError(f"Refusing overwrite {path}")
    request = urllib.request.Request(BASE + name, headers={
        "Range": f"bytes=0-{length - 1}", "Accept-Encoding": "identity",
        "User-Agent": "BioExplainR-ASM-EV-version/0.4"})
    log = dict(utc=utc(), url=BASE + name, requested_range=[0, length - 1])
    try:
        with urllib.request.urlopen(request, timeout=45) as response:
            log.update(http_status=response.status, headers=dict(response.headers))
            assert response.status == 206, "Range was not honored"
            assert response.headers["Content-Range"].startswith(f"bytes 0-{length - 1}/")
            blob = response.read(length + 1)
            assert len(blob) == length
        path.write_bytes(blob)
        log.update(status="retrieved", file=record(path), sqlite_header=blob[:16].decode("ascii", "replace"),
                   whole_file_sha1_verified=False)
        if blob.startswith(b"SQLite format 3\x00"):
            size = int.from_bytes(blob[16:18], "big")
            log.update(sqlite_page_size=65536 if size == 1 else size,
                       sqlite_database_pages=int.from_bytes(blob[28:32], "big"))
    except Exception as exc:
        log.update(status="failed", error=str(exc))
    json_out(log_path, log)
    print(json.dumps(log, ensure_ascii=False, indent=2))


def inventory():
    url = "https://www.ebi.ac.uk/pride/ws/archive/v2/projects/PXD055968/files?pageSize=100&page=0"
    json_out(OUT / "inventory_amendment.json", dict(utc=utc(), script=record(Path(__file__)),
        reason="Initial files/byProject HTTP200 empty body is not a valid inventory; retain response and use projects/accession/files",
        url=url))
    log = fetch(url, OUT / "sources/files_corrected.json", timeout=30)
    if log["status"] == "retrieved":
        rows = json.loads((OUT / "sources/files_corrected.json").read_text())
        assert len(rows) < 100, "Additional API page required"
        log.update(valid_inventory=True, files=len(rows))
    json_out(OUT / "inventory_acquisition.json", log)
    print(json.dumps(log, indent=2))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="action", required=True)
    sub.add_parser("start")
    sub.add_parser("inventory")
    p = sub.add_parser("probe")
    p.add_argument("name")
    p.add_argument("--length", type=int, default=1048576)
    args = parser.parse_args()
    if args.action == "probe":
        probe(args.name, args.length)
    else:
        globals()[args.action]()
