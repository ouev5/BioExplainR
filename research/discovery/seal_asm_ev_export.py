"""Seal ASM EV export-version evidence with exact historical rgo snapshot."""
import argparse
import ast
import json
import zipfile
from pathlib import Path

from validation_sources import ROOT, HERE, record, utc, json_out
from seal_set_validation import check_archive, check_protected
from seal_secretome_provenance import previous as older_previous

SOURCE = ROOT / "research/results/discovery_asm_ev_export_v1"
REPORT = ROOT / "docs/asm_ev_export_v1"
MANIFEST = REPORT / "export_manifest.json"
ARCHIVE = REPORT / "PXD055968-export-evidence.zip"


def previous():
    path = ROOT / "docs/secretome_provenance_v1/provenance_manifest.json"
    old = json.loads(path.read_text())
    n = 0
    for group in ["files", "source_code", "dependencies", "documentation"]:
        for r in old[group]:
            p = SOURCE / "rgo_before_asm_ev_export.md" if r["path"] == "rgo.md" else ROOT / r["path"]
            actual = record(p)
            assert (actual["bytes"], actual["sha256"]) == (r["bytes"], r["sha256"]), r["path"]
            n += 1
    assert record(ROOT / old["archive"]["path"]) == old["archive"]
    check_archive(ROOT / old["archive"]["path"], old["archive_members"])
    return dict(status="pass", provenance_records=n, provenance_archive_members=len(old["archive_members"]),
        prior_manifest=record(path), protected=check_protected(), nested=older_previous(),
        snapshot_policy="Only preceding provenance root rgo documentation uses exact pre-export snapshot; all other prior science original paths/hash")


def verify():
    m = json.loads(MANIFEST.read_text())
    for group in ["files", "source_code", "dependencies", "documentation"]:
        seen = set()
        for r in m[group]:
            assert r["path"] not in seen
            seen.add(r["path"])
            assert record(ROOT / r["path"]) == r, r["path"]
    assert record(ARCHIVE) == m["archive"]
    check_archive(ARCHIVE, m["archive_members"])
    prior = previous()
    assert json.loads((SOURCE / "final_status.json").read_text())["status"] == "blocked_missing_final_export"
    result = dict(status="pass", files=len(m["files"]), source_code=len(m["source_code"]),
        archive_members=len(m["archive_members"]), archive_bytes=m["archive"]["bytes"],
        previous_evidence=prior, scientific_status="blocked_missing_final_export",
        candidate_identity_started=False, scope=m["scope"])
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return result


def seal():
    for p in [MANIFEST, ARCHIVE, REPORT / "verification.json"]:
        if p.exists():
            raise ValueError(f"Refusing overwrite {p}")
    prior = previous()
    for p in [SOURCE / "independent_audit.json", SOURCE / "handoff_check.json", SOURCE / "reader_boundary_checks.json"]:
        assert json.loads(p.read_text())["status"] == "pass", p
    freeze = json.loads((SOURCE / "final_evidence_freeze.json").read_text())
    for r in freeze["inputs"] + freeze["source_code"] + [freeze["protocol"]]:
        assert record(ROOT / r["path"]) == r, r["path"]
    files = [record(p) for folder in [SOURCE, REPORT] for p in sorted(folder.rglob("*")) if p.is_file() and "__pycache__" not in p.parts]
    code = set(HERE.glob("*asm_ev*.py")) | {HERE / "ASM_EV_EXPORT_PROTOCOL.md", HERE / "requirements-asm-ev.txt"}
    code |= {HERE / n for n in ["validation_sources.py", "seal_secretome_provenance.py", "seal_set_validation.py", "seal_secretome.py", "set_integrity.py"]}
    for p in code:
        if p.suffix == ".py":
            ast.parse(p.read_text(), filename=str(p))
    source_code = [record(p) for p in sorted(code)]
    dependencies = [record(ROOT / p) for p in [
        "docs/secretome_provenance_v1/provenance_manifest.json",
        "research/results/discovery_secretome_provenance_v1/sources/EV_publisher_supplement_normalized.bin",
        "research/results/discovery_secretome_provenance_v1/complete/EV_supplement_scope.csv",
        "research/results/discovery_secretome_provenance_v1/complete/EV_selected_table_audit.json"]]
    docs = [record(ROOT / "rgo.md")]
    members = {r["path"]: r for r in files + source_code + dependencies + docs}
    with zipfile.ZipFile(ARCHIVE, "x", compression=zipfile.ZIP_DEFLATED, compresslevel=6) as z:
        for r in members.values():
            z.write(ROOT / r["path"], arcname=r["path"])
    json_out(MANIFEST, dict(status="sealed", utc=utc(), files=files, source_code=source_code,
        dependencies=dependencies, documentation=docs, archive=record(ARCHIVE), archive_members=list(members.values()),
        previous_evidence=prior, scientific_status="blocked_missing_final_export", candidate_identity_started=False,
        scope="18 submitted pdResult version/schema and single MSF metadata checks via partial original byte ranges; final correct-version joint quantitative export not acquired; no candidate identity or GC analysis",
        publication="paused", author_contact="draft_only_not_sent", online_model_calls=0))
    value = verify()
    json_out(REPORT / "verification.json", dict(utc=utc(), result=value,
        note="Verification output outside own sealedmember list; verify rechecks all indexed evidence"))


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("action", choices=["previous", "seal", "verify"])
    a = p.parse_args()
    value = globals()[a.action]()
    if a.action == "previous":
        print(json.dumps(value, ensure_ascii=False, indent=2))
