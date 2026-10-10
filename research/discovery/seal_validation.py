"""Seal new public validation files without changing prior scientific manifests."""
import argparse
import hashlib
import json
import zipfile
from pathlib import Path

from validation_sources import ROOT, HERE, record, json_out, utc

SOURCE = ROOT / "research/results/discovery_validation_v2"
REPORT = ROOT / "docs/biology_validation_v2"
MANIFEST = REPORT / "validation_manifest.json"
ARCHIVE = REPORT / "BioExplainR-公开数据验证-附件.zip"


def verify():
    manifest = json.loads(MANIFEST.read_text())
    for group in ["files", "source_code", "documentation", "historical_dependencies"]:
        for entry in manifest[group]:
            assert record(ROOT / entry["path"]) == entry, entry["path"]
    assert record(ARCHIVE) == manifest["archive"]
    entries = {r["path"]: r for r in manifest["archive_members"]}
    with zipfile.ZipFile(ARCHIVE) as archive:
        assert archive.testzip() is None and len(archive.namelist()) == len(set(archive.namelist())) == len(entries)
        assert set(archive.namelist()) == set(entries)
        for path, entry in entries.items():
            data = archive.read(path)
            assert len(data) == entry["bytes"] and hashlib.sha256(data).hexdigest() == entry["sha256"], path
    # Historical scientific and manuscript hashes are checked against precise
    # document snapshots; old file entries are never rewritten.
    from validation_integrity import old_integrity
    historical = old_integrity(SOURCE)
    result = {"status": "pass", "files": len(manifest["files"]), "source_code": len(manifest["source_code"]),
              "archive_members": len(entries), "archive_bytes": ARCHIVE.stat().st_size,
              "archive_sha256": manifest["archive"]["sha256"], "historical_integrity": historical}
    print(json.dumps(result, ensure_ascii=False, indent=2))


def seal():
    if MANIFEST.exists() or ARCHIVE.exists():
        raise ValueError("Refusing to overwrite sealed validation")
    for path in [REPORT / "audit.json", REPORT / "browser/audit.json", SOURCE / "r_expression_audit.json",
                 SOURCE / "asm_early/r_early_audit.json", SOURCE / "gr_public/python_numeric_audit.json",
                 SOURCE / "protein_public/r_protein_audit.json", SOURCE / "human_protein/r_human_protein_audit.json"]:
        assert json.loads(path.read_text())["status"] == "pass", path
    paths = []
    for directory in [SOURCE, REPORT, ROOT / "research/results/discovery_validation_v1", ROOT / "docs/biology_validation_v1"]:
        paths.extend(p for p in directory.rglob("*") if p.is_file())
    files = [record(p) for p in sorted(paths)]
    scripts = sorted(set(HERE.glob("*validation*.py")) | set(HERE.glob("*validation*.R")) | set(HERE.glob("*validation*.cjs")))
    scripts += [HERE / "VALIDATION_CONTINUATION_PROTOCOL.md", HERE / "VALIDATION_DRYLAB_AMENDMENT.md"]
    source_code = [record(p) for p in sorted(set(scripts))]
    source_code += [record(ROOT / "DESCRIPTION"), record(ROOT / "NAMESPACE")]
    source_code += [record(p) for p in sorted((ROOT / "R").glob("*.R"))]
    docs = [record(ROOT / "rgo.md")]
    dependencies = [record(ROOT / name) for name in ["docs/paper_cn_v5/manuscript_manifest.json", "docs/biology_discovery_v2/discovery_manifest.json",
                    "docs/paper_cn_v5/BioExplainR-中文论文-v0.11-附件.zip", "research/results/discovery_stable_response_v1/candidate_annotation.csv",
                    "research/results/discovery_donors_v1/samples.csv"]]
    # Avoid duplicating raw download chunks and large all-genome fitted RDS in
    # a portable report bundle; full files remain bound by the local manifest.
    excluded = []
    included = []
    for entry in files:
        path = Path(entry["path"])
        if "protein_ranges" in path.parts or path.name.endswith("_model.rds") or path.name == "voom_model.rds":
            excluded.append({**entry, "reason": "Large fitted all-gene object or duplicate downloaded range; local full hash bound"})
        else:
            included.append(entry)
    members = included + source_code + docs
    assert len({r["path"] for r in members}) == len(members)
    with zipfile.ZipFile(ARCHIVE, "x", compression=zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        for entry in members:
            archive.write(ROOT / entry["path"], arcname=entry["path"])
    manifest = {"status": "sealed", "utc": utc(), "scope": "Newpublic-data validation, reports, scripts and explicit historical snapshot checks; no projectwide acceptance",
                "files": files, "source_code": source_code, "documentation": docs, "historical_dependencies": dependencies,
                "archive": record(ARCHIVE), "archive_members": members, "excluded_bundle_files": excluded,
                "old_rgo_snapshot": record(SOURCE / "rgo_before_validation.md"), "old_manifests_rewritten": False,
                "human_personnel_signoff": "not performed", "new_wet_experiments": 0, "online_model_calls": 0}
    json_out(MANIFEST, manifest)
    verify()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__); parser.add_argument("action", choices=["seal", "verify"])
    globals()[parser.parse_args().action]()
