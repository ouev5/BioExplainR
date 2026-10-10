"""Seal this manuscript separately from older project and scientific manifests."""
import hashlib
import json
import sys
import zipfile
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PAPER = ROOT / "docs/paper_cn_v5"
MANIFEST = PAPER / "manuscript_manifest.json"
ARCHIVE = PAPER / "BioExplainR-中文论文-v0.11-附件.zip"
SCRIPTS = ["build_discovery_paper.py", "audit_discovery_paper.py", "browser_discovery_paper.cjs", "seal_discovery_paper.py"]
DOCS = ["rgo.md", "SESSION_HANDOFF.md", "README.md", "docs/index.html", "docs/paper_cn_v4/README.md"]


def record(path):
    h = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            h.update(chunk)
    return {"path": path.relative_to(ROOT).as_posix(), "bytes": path.stat().st_size, "sha256": h.hexdigest()}


def verify():
    manifest = json.loads(MANIFEST.read_text())
    for group in ["files", "documentation", "dependencies"]:
        for entry in manifest[group]:
            assert record(ROOT / entry["path"]) == entry, entry["path"]
    old = json.loads((ROOT / "docs/biology_discovery_v2/discovery_manifest.json").read_text())
    scientific = 0
    for group in ["analysis_files", "original_inputs", "package_source"]:
        for entry in old[group]:
            path = PAPER / "evidence/rgo_before_v011.md" if entry["path"] == "rgo.md" else ROOT / entry["path"]
            actual = record(path)
            assert (actual["bytes"], actual["sha256"]) == (entry["bytes"], entry["sha256"]), entry["path"]
            scientific += 1
    assert record(ROOT / old["archive"]["path"]) == old["archive"]
    assert record(ARCHIVE) == manifest["archive"]
    expected = {entry["path"]: entry for entry in manifest["archive_members"]}
    with zipfile.ZipFile(ARCHIVE) as archive:
        assert len(archive.namelist()) == len(set(archive.namelist())) == len(expected)
        assert set(archive.namelist()) == set(expected) and archive.testzip() is None
        for path, entry in expected.items():
            data = archive.read(path)
            assert len(data) == entry["bytes"] and hashlib.sha256(data).hexdigest() == entry["sha256"]
    print(json.dumps({"status": "pass", "manuscript_files": len(manifest["files"]),
                     "documentation_files": len(manifest["documentation"]), "scientific_dependency_records": scientific,
                     "archive_members": len(expected), "archive_bytes": ARCHIVE.stat().st_size,
                     "archive_sha256": manifest["archive"]["sha256"], "manifest_sha256": record(MANIFEST)["sha256"]}, indent=2))


def seal():
    if MANIFEST.exists() or ARCHIVE.exists():
        raise ValueError("Refusing to overwrite a sealed manuscript")
    for path in [PAPER / "audit.json", PAPER / "browser_final/audit.json", PAPER / "export_report.json"]:
        assert json.loads(path.read_text())["status"] == "pass", path
    paths = [p for p in PAPER.rglob("*") if p.is_file() and "rendered_docx" not in p.parts]
    paths += [ROOT / "research/paper_cn_revision" / name for name in SCRIPTS]
    files = [record(p) for p in sorted(paths)]
    docs = [record(ROOT / name) for name in DOCS]
    dependencies = [record(ROOT / name) for name in [
        "docs/biology_discovery_v2/discovery_manifest.json", "docs/research_followup_v1/research_addendum.md",
        "research/paper_cn_revision/build_revision.py", "research/export_paper.py",
        "research/results/discovery_mechanism_fit_v4/sample_map.csv"]]
    members = files + docs
    assert len({r["path"] for r in members}) == len(members)
    with zipfile.ZipFile(ARCHIVE, "x", compression=zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        for entry in members:
            archive.write(ROOT / entry["path"], arcname=entry["path"])
    manifest = {"status": "sealed", "created_utc": datetime.now(timezone.utc).isoformat(),
                "scope": "v0.11 biology-led manuscript and documentation only; original science externally hash-bound",
                "files": files, "documentation": docs, "dependencies": dependencies,
                "archive": record(ARCHIVE), "archive_members": members,
                "old_handoff_snapshot": "docs/paper_cn_v5/evidence/rgo_before_v011.md",
                "original_science": "Old manifest retained; only its rgo.md entry uses the exact historical snapshot",
                "fresh_research_run": False, "human_visual_scientific_review": "pending"}
    MANIFEST.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n")
    verify()


if __name__ == "__main__":
    {"seal": seal, "verify": verify}[sys.argv[1]]()
