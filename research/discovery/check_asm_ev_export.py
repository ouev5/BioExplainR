"""Check transport boundaries and local export-evidence handoff consistency."""
import argparse
import ast
import hashlib
import importlib.metadata
import json
import re
import tempfile
import threading
import unittest
import urllib.parse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from unittest.mock import patch

from validation_sources import ROOT, utc, record, json_out

OUT = ROOT / "research/results/discovery_asm_ev_export_v1"
REPORT = ROOT / "docs/asm_ev_export_v1"


def boundaries():
    import asm_ev_sqlite as reader

    payload = bytes(range(256)) * 1024
    mode = {"value": "valid"}

    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            start, end = map(int, self.headers["Range"][6:].split("-"))
            body = payload[start:end + 1]
            self.send_response(200 if mode["value"] == "ignored" else 206)
            actual_start = start + 1 if mode["value"] == "wrong_range" else start
            self.send_header("Content-Range", f"bytes {actual_start}-{end}/{len(payload)}")
            self.send_header("ETag", '"changed"' if mode["value"] == "changed" else '"fixed"')
            self.send_header("Last-Modified", "Sat, 10 Oct 2026 00:00:00 GMT")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def log_message(self, *args):
            pass

    server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
    worker = threading.Thread(target=server.serve_forever, daemon=True)
    worker.start()
    results = []
    try:
        with tempfile.TemporaryDirectory(prefix="asm-ev-reader-boundaries-", dir="/tmp/opencode") as tmp:
            folder = Path(tmp)

            def temp_record(path):
                return dict(path=path.relative_to(folder).as_posix(), bytes=path.stat().st_size,
                            sha256=hashlib.sha256(path.read_bytes()).hexdigest())

            with patch.object(reader, "OUT", folder), patch.object(reader, "BASE", f"http://127.0.0.1:{server.server_port}/"), \
                 patch.object(reader, "record", temp_record), patch.object(reader.time, "sleep", lambda n: None):
                (folder / "sources").mkdir()
                (folder / "ranges").mkdir()
                names = ["valid", "ignored", "wrong_range", "changed", "tampered", "offline_missing"]
                (folder / "sources/files_corrected.json").write_text(json.dumps([
                    dict(fileName=name, fileSizeBytes=len(payload)) for name in names]))
                mode["value"] = "valid"
                remote = reader.RemoteFile("valid")
                assert remote.xRead(82000, 42000) == payload[42000:124000]
                offline = reader.RemoteFile("valid", offline=True)
                assert offline.xRead(82000, 42000) == payload[42000:124000]
                results.append(dict(check="real HTTP206 multi-block + offline exact bytes", status="pass"))
                with unittest.TestCase().assertRaises(Exception):
                    remote.xRead(1, len(payload))
                results.append(dict(check="reject outside-file read", status="pass"))
                for name in ["ignored", "wrong_range"]:
                    mode["value"] = name
                    with unittest.TestCase().assertRaises(IOError):
                        reader.RemoteFile(name).xRead(100, 0)
                    assert not list((folder / "ranges" / name).glob("*.bin"))
                    results.append(dict(check="reject " + name, status="pass"))
                mode["value"] = "valid"
                changed = reader.RemoteFile("changed")
                assert changed.xRead(20, 0) == payload[:20]
                mode["value"] = "changed"
                with unittest.TestCase().assertRaises(AssertionError):
                    changed.xRead(20, 65536)
                results.append(dict(check="reject changed ETag across blocks", status="pass"))
                mode["value"] = "valid"
                tampered = reader.RemoteFile("tampered")
                tampered.xRead(20, 0)
                cache = folder / "ranges/tampered/0-65535.bin"
                blob = bytearray(cache.read_bytes())
                blob[1] ^= 1
                cache.write_bytes(blob)
                with unittest.TestCase().assertRaises(AssertionError):
                    reader.RemoteFile("tampered", offline=True).xRead(20, 0)
                results.append(dict(check="reject cached-block hash corruption", status="pass"))
                with unittest.TestCase().assertRaises(ValueError):
                    reader.RemoteFile("offline_missing", offline=True).xRead(20, 0)
                results.append(dict(check="reject missing offline block", status="pass"))
    finally:
        server.shutdown()
        worker.join()
        server.server_close()
    json_out(OUT / "reader_boundary_checks.json", dict(status="pass", utc=utc(), checks=results,
        scope="Real loopback HTTP range/data-identity/cache rejection checks; not upstream whole-file verification"))
    print(json.dumps(results, indent=2))


def handoff():
    paths = list((ROOT / "research/discovery").glob("*asm_ev*.py"))
    syntax = []
    for path in paths:
        ast.parse(path.read_text(), filename=str(path))
        syntax.append(record(path))
    links = []
    texts = [REPORT / "README.md", OUT / "FINDINGS.md", OUT / "EXECUTION_NOTES.md", OUT / "AUTHOR_MATERIAL_REQUEST.md"]
    deferred = {REPORT / "export_manifest.json", REPORT / "PXD055968-export-evidence.zip"}
    for path in texts:
        text = path.read_text()
        for target in re.findall(r"\]\(([^)]+)\)", text):
            if "://" in target:
                continue
            resolved = (path.parent / urllib.parse.unquote(target.split("#")[0])).resolve()
            assert resolved.is_relative_to(ROOT)
            if resolved not in deferred:
                assert resolved.exists(), (path, target)
            links.append(dict(source=str(path.relative_to(ROOT)), target=str(resolved.relative_to(ROOT)),
                              exists=resolved.exists(), generated_at_seal=resolved in deferred))
    state = json.loads((OUT / "final_status.json").read_text())
    summary = json.loads((OUT / "complete_summary.json").read_text())
    audit = json.loads((OUT / "independent_audit.json").read_text())
    assert state["status"] == "blocked_missing_final_export" and state["correct_full_export_acquired"] is False
    assert state["candidate_identity_started"] is False
    assert summary["version_files"] == 18 and summary["patients"] == 6
    assert audit["status"] == "pass" and len(audit["original_result_files"]) == 18
    request = (OUT / "AUTHOR_MATERIAL_REQUEST.md").read_text()
    project = json.loads((OUT / "sources/project.json").read_text())
    for person in project["submitters"] + project["labPIs"]:
        assert person["email"] in request
    for expected in ["未发送", "3.1.0.638", "2024_01_22", "inferys_3.0.0", "595", "BA186"]:
        assert expected in request
    root_text = (ROOT / "rgo.md").read_text()
    assert root_text.index("PXD055968完整定量导出版本核实") < root_text.index("分泌蛋白来源诊断与新ASM")
    assert "seal_asm_ev_export.py verify" in root_text
    protected_docs = json.loads((ROOT / "docs/secretome_provenance_v1/provenance_manifest.json").read_text())["documentation"]
    previous_rgo = next(r for r in protected_docs if r["path"] == "rgo.md")
    snapshot = record(OUT / "rgo_before_asm_ev_export.md")
    assert (snapshot["bytes"], snapshot["sha256"]) == (previous_rgo["bytes"], previous_rgo["sha256"])
    for path in paths + texts + [ROOT / "research/discovery/ASM_EV_EXPORT_PROTOCOL.md", ROOT / "research/discovery/requirements-asm-ev.txt"]:
        for i, line in enumerate(path.read_text().splitlines(), 1):
            assert line == line.rstrip(), (path, i, "trailing whitespace")
    json_out(OUT / "handoff_check.json", dict(status="pass", utc=utc(), syntax=syntax, local_links=links,
        snapshot=snapshot, scientific_status=state["status"], candidate_identity_started=False,
        note="Local Markdown and evidence consistency check; archive/manifest links are generated and verified by seal"))
    versions = dict(python=__import__("sys").version)
    for pkg in ["apsw", "openpyxl"]:
        try:
            versions[pkg] = importlib.metadata.version(pkg)
        except importlib.metadata.PackageNotFoundError:
            versions[pkg] = "not loaded in checker environment"
    json_out(OUT / "checker_environment.json", versions)
    print(json.dumps(dict(status="pass", syntax_files=len(syntax), links=len(links), scientific_status=state["status"]), indent=2))


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("action", choices=["boundaries", "handoff"])
    globals()[p.parse_args().action]()
