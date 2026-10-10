"""Verify previous evidence using precise document snapshot; seal new secretome locally."""
import argparse
import hashlib
import json
import zipfile
from pathlib import Path

from validation_sources import ROOT, HERE, record, utc, json_out
from seal_set_validation import check_archive, check_protected
from set_integrity import prior_integrity

SOURCE = ROOT/"research/results/discovery_secretome_v1"
REPORT = ROOT/"docs/secretome_validation_v1"
MANIFEST = REPORT/"secretome_manifest.json"
ARCHIVE = REPORT/"PXD033504-完整分泌蛋白组-附件.zip"


def previous():
    path = ROOT/"docs/paper_cn_v6/manuscript_manifest.json"
    prior = json.loads(path.read_text())
    for group in ["files","source_code","documentation","dependencies"]:
        for r in prior[group]:
            p = SOURCE/"rgo_before_secretome.md" if r["path"] == "rgo.md" else ROOT/r["path"]
            actual = record(p)
            assert (actual["sha256"],actual["bytes"]) == (r["sha256"],r["bytes"]),r["path"]
    assert record(ROOT/prior["archive"]["path"]) == prior["archive"]
    check_archive(ROOT/prior["archive"]["path"],prior["archive_members"])
    latest = json.loads((ROOT/"research/results/latest_manifest.json").read_text())
    assert record(path) == latest["manuscript_manifest"]
    assert record(ROOT/latest["delivery_archive"]["path"]) == latest["delivery_archive"]
    check_archive(ROOT/latest["delivery_archive"]["path"],latest["delivery_members"])
    nested = prior_integrity(ROOT/"research/results/discovery_set_validation_v1")
    return dict(status="pass",v012_files=len(prior["files"]),original_protected_files=check_protected(),
                snapshot_policy="Only v0.12 root rgo dependency uses exact pre-secretome snapshot; original scientific paths/hash unchanged",
                nested=nested)


def seal():
    for p in [MANIFEST,ARCHIVE]:
        if p.exists():
            raise ValueError(f"Refusing overwrite {p}")
    old = previous()
    for p in [SOURCE/"r_numeric_audit.json",SOURCE/"r_diagnostics_audit.json",SOURCE/"bioexplainr_workflow.json",REPORT/"audit.json",REPORT/"browser/audit.json"]:
        assert json.loads(p.read_text())["status"] == "pass",p
    files = [record(p) for folder in [SOURCE,REPORT] for p in sorted(folder.rglob("*")) if p.is_file()]
    scripts = [record(p) for p in sorted(set(HERE.glob("*secretome*.py"))|set(HERE.glob("*secretome*.R"))|
        {HERE/"SECRETOME_PROTOCOL.md",HERE/"browser_secretome.cjs",HERE/"set_protein_archive.py",HERE/"set_protein_extract.py",
         HERE/"set_validation.py",HERE/"validation_sources.py",HERE/"seal_set_validation.py",HERE/"set_integrity.py"})]
    scripts += [record(p) for p in sorted((ROOT/"R").glob("*.R"))]+[record(ROOT/"DESCRIPTION"),record(ROOT/"NAMESPACE")]
    frozen = json.loads((SOURCE/"analysis_freeze.json").read_text())
    dependencies = frozen["inputs"]
    for r in dependencies:
        assert record(ROOT/r["path"]) == r
    docs = [record(ROOT/"rgo.md")]
    included, excluded = [],[]
    for r in files:
        p = Path(r["path"])
        omit = "archives" in p.parts and p.suffix == ".bin"
        (excluded if omit else included).append(r)
    members = {r["path"]:r for r in included+scripts+dependencies+docs}
    with zipfile.ZipFile(ARCHIVE,"x",compression=zipfile.ZIP_DEFLATED,compresslevel=6) as zipped:
        for r in members.values():
            zipped.write(ROOT/r["path"],arcname=r["path"])
    json_out(MANIFEST,dict(status="sealed",utc=utc(),files=files,source_code=scripts,dependencies=dependencies,documentation=docs,
        archive=record(ARCHIVE),archive_members=list(members.values()),excluded_network_parts=excluded,
        previous_evidence=old,scientific_scope="Complete PXD033504 processed secretome arrays and fixed56genes; same HTPC cohort, no new independent ASM protein or causal function",
        publication="paused",online_model_calls=0,new_wet_experiments=0))
    verify()


def verify():
    m = json.loads(MANIFEST.read_text())
    for group in ["files","source_code","dependencies","documentation"]:
        for r in m[group]:
            assert record(ROOT/r["path"]) == r,r["path"]
    assert record(ARCHIVE) == m["archive"]
    check_archive(ARCHIVE,m["archive_members"])
    old = previous()
    print(json.dumps(dict(status="pass",files=len(m["files"]),source_code=len(m["source_code"]),
        archive_members=len(m["archive_members"]),archive_bytes=ARCHIVE.stat().st_size,
        previous_evidence=old,scope=m["scientific_scope"]),ensure_ascii=False,indent=2))


if __name__ == "__main__":
    p=argparse.ArgumentParser(description=__doc__);p.add_argument("action",choices=["previous","seal","verify"])
    a=p.parse_args(); result=globals()[a.action]()
    if result is not None: print(json.dumps(result,ensure_ascii=False,indent=2))
