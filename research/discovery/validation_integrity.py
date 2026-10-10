"""Standard-library historical verification with explicitly versioned rgo snapshots."""
import hashlib
import json
import zipfile
from validation_sources import ROOT, record


def old_integrity(source):
    paper = ROOT / "docs/paper_cn_v5"
    old = json.loads((paper / "manuscript_manifest.json").read_text())
    n = 0
    for group in ["files", "documentation", "dependencies"]:
        for entry in old[group]:
            path = source / "rgo_before_validation.md" if entry["path"] == "rgo.md" else ROOT / entry["path"]
            actual = record(path)
            assert (actual["bytes"], actual["sha256"]) == (entry["bytes"], entry["sha256"]), entry["path"]
            n += 1
    assert record(ROOT / old["archive"]["path"]) == old["archive"]
    with zipfile.ZipFile(ROOT / old["archive"]["path"]) as archive:
        assert archive.testzip() is None
        for entry in old["archive_members"]:
            data = archive.read(entry["path"])
            assert hashlib.sha256(data).hexdigest() == entry["sha256"]
    scientific = json.loads((ROOT / "docs/biology_discovery_v2/discovery_manifest.json").read_text())
    scientific_n = 0
    for group in ["analysis_files", "original_inputs", "package_source"]:
        for entry in scientific[group]:
            path = paper / "evidence/rgo_before_v011.md" if entry["path"] == "rgo.md" else ROOT / entry["path"]
            actual = record(path)
            assert (actual["bytes"], actual["sha256"]) == (entry["bytes"], entry["sha256"]), entry["path"]
            scientific_n += 1
    return {"v011_records": n, "v011_archive_members": len(old["archive_members"]), "original_science_records": scientific_n,
            "rgo_snapshot_policy": "v011exactstartsnapshot; pre-v011scientificsnapshot; all scientificfilesoriginalpath/hash"}
