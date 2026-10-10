"""Verify preceding validation against its precise handoff snapshot; scientific files stay at original paths."""
import hashlib
import json
import zipfile
from validation_sources import ROOT,record


def paper_integrity(source):
    paper=ROOT/"docs/paper_cn_v5";old=json.loads((paper/"manuscript_manifest.json").read_text())
    snapshots={"rgo.md":ROOT/"research/results/discovery_validation_v2/rgo_before_validation.md",
        "README.md":source/"README_before_set_validation.md","docs/index.html":source/"index_before_set_validation.html"}
    n=0
    for group in ["files","documentation","dependencies"]:
        for entry in old[group]:
            path=snapshots.get(entry["path"],ROOT/entry["path"]);actual=record(path)
            assert (actual["bytes"],actual["sha256"])==(entry["bytes"],entry["sha256"]),entry["path"];n+=1
    assert record(ROOT/old["archive"]["path"])==old["archive"]
    with zipfile.ZipFile(ROOT/old["archive"]["path"]) as archive:
        assert archive.testzip() is None
        for entry in old["archive_members"]:
            data=archive.read(entry["path"]);assert len(data)==entry["bytes"] and hashlib.sha256(data).hexdigest()==entry["sha256"]
    scientific=json.loads((ROOT/"docs/biology_discovery_v2/discovery_manifest.json").read_text());scientific_n=0
    for group in ["analysis_files","original_inputs","package_source"]:
        for entry in scientific[group]:
            path=paper/"evidence/rgo_before_v011.md" if entry["path"]=="rgo.md" else ROOT/entry["path"]
            actual=record(path);assert (actual["bytes"],actual["sha256"])==(entry["bytes"],entry["sha256"]),entry["path"];scientific_n+=1
    assert record(ROOT/scientific["archive"]["path"])==scientific["archive"]
    return dict(status="pass",v011_records=n,v011_archive_members=len(old["archive_members"]),original_science_records=scientific_n,
        snapshot_policy="Explicitrgo/README/indexhistoricaldocumentsnapshots only; alloriginalsciencepaths/hash remain")


def prior_integrity(source):
    manifest=json.loads((ROOT/"docs/biology_validation_v2/validation_manifest.json").read_text())
    n=0
    for group in ["files","source_code","documentation","historical_dependencies"]:
        for entry in manifest[group]:
            path=source/"rgo_before_set_validation.md" if entry["path"]=="rgo.md" else ROOT/entry["path"]
            actual=record(path);assert (actual["bytes"],actual["sha256"])==(entry["bytes"],entry["sha256"]),entry["path"]
            n+=1
    assert record(ROOT/manifest["archive"]["path"])==manifest["archive"]
    with zipfile.ZipFile(ROOT/manifest["archive"]["path"]) as archive:
        assert archive.testzip() is None
        expected={r["path"]:r for r in manifest["archive_members"]}
        assert len(archive.namelist())==len(set(archive.namelist()))==len(expected) and set(archive.namelist())==set(expected)
        for path,entry in expected.items():
            data=archive.read(path);assert len(data)==entry["bytes"] and hashlib.sha256(data).hexdigest()==entry["sha256"]
    return dict(status="pass",validation_records=n,validation_archive_members=len(expected),
        preceding_paper_and_science=paper_integrity(source),
        snapshot_policy="Validationrgo uses startsnapshot; nestedv011rgo/README/index use preciseversioned snapshots; alloriginalsciencepaths/hash unchanged")
