"""Seal new provenance follow-up with exact historical documentation snapshot."""
import argparse
import ast
import json
import zipfile
from pathlib import Path

from validation_sources import ROOT,HERE,utc,record,json_out
from seal_set_validation import check_archive,check_protected
from seal_secretome import previous as older_previous

SOURCE=ROOT / "research/results/discovery_secretome_provenance_v1"
REPORT=ROOT / "docs/secretome_provenance_v1"
MANIFEST=REPORT / "provenance_manifest.json"
ARCHIVE=REPORT / "分泌蛋白组-来源诊断与ASM公开证据-附件.zip"


def previous():
    path=ROOT / "docs/secretome_validation_v1/secretome_manifest.json"
    old=json.loads(path.read_text())
    n=0
    for group in ["files","source_code","dependencies","documentation"]:
        for r in old[group]:
            p=SOURCE / "rgo_before_provenance.md" if r["path"]=="rgo.md" else ROOT / r["path"]
            actual=record(p)
            assert (actual["sha256"],actual["bytes"])==(r["sha256"],r["bytes"]),r["path"]
            n+=1
    assert record(ROOT / old["archive"]["path"])==old["archive"]
    check_archive(ROOT / old["archive"]["path"],old["archive_members"])
    return dict(status="pass",secretome_records=n,secretome_archive_members=len(old["archive_members"]),
        secretome_manifest=record(path),protected=check_protected(),nested=older_previous(),
        snapshot_policy="Only preceding secretome rgo dependency uses exact pre-provenance snapshot; all previous science original paths/hash")


def verify():
    m=json.loads(MANIFEST.read_text())
    for group in ["files","source_code","dependencies","documentation"]:
        seen=set()
        for r in m[group]:
            assert r["path"] not in seen;seen.add(r["path"])
            assert record(ROOT / r["path"])==r,r["path"]
    assert record(ARCHIVE)==m["archive"]
    check_archive(ARCHIVE,m["archive_members"])
    old=previous()
    result=dict(status="pass",files=len(m["files"]),source_code=len(m["source_code"]),
        archive_members=len(m["archive_members"]),archive_bytes=m["archive"]["bytes"],
        previous_evidence=old,scope=m["scope"])
    print(json.dumps(result,ensure_ascii=False,indent=2))
    return result


def seal():
    for p in [MANIFEST,ARCHIVE]:
        if p.exists():raise ValueError(f"Refusing overwrite {p}")
    old=previous()
    for p in [REPORT / "audit.json",REPORT / "browser_final/audit.json",SOURCE / "complete/r_audit.json",
        SOURCE / "complete/independent_audit.json",SOURCE / "complete/report_final/bioexplainr_workflow.json",
        SOURCE / "complete/EV_selected_table_audit.json"]:
        assert json.loads(p.read_text())["status"]=="pass",p
    code=set(HERE.glob("*secretome_provenance*.py"))|set(HERE.glob("*secretome_provenance*.R"))
    code|={HERE / "SECRETOME_PROVENANCE_PROTOCOL.md",HERE / "validation_sources.py",HERE / "seal_set_validation.py",
        HERE / "seal_secretome.py",HERE / "set_integrity.py"}
    code|=set((ROOT / "R").glob("*.R"))|{ROOT / "DESCRIPTION",ROOT / "NAMESPACE"}
    for path in code:
        if path.suffix==".py":ast.parse(path.read_text(),filename=str(path))
    source_code=[record(p) for p in sorted(code)]
    dependencies={}
    for name in ["freeze.json","complete/freeze.json","complete/diagnostic_freeze.json"]:
        f=json.loads((SOURCE / name).read_text())
        for r in f["inputs"]:dependencies[r["path"]]=r
    dependencies=list(dependencies.values())
    for r in dependencies:assert record(ROOT / r["path"])==r
    files=[record(p) for folder in [SOURCE,REPORT] for p in sorted(folder.rglob("*")) if p.is_file()]
    docs=[record(ROOT / "rgo.md")]
    members={r["path"]:r for r in files+source_code+dependencies+docs}
    with zipfile.ZipFile(ARCHIVE,"x",compression=zipfile.ZIP_DEFLATED,compresslevel=6) as z:
        for r in members.values():z.write(ROOT / r["path"],arcname=r["path"])
    json_out(MANIFEST,dict(status="sealed",utc=utc(),files=files,source_code=source_code,dependencies=dependencies,
        documentation=docs,archive=record(ARCHIVE),archive_members=list(members.values()),previous_evidence=old,
        scope="Four original/published HTPC array source diagnostics and bounded ASM public material feasibility; no new GC candidate protein validation or full PXD055968 quantified array analysis",
        publication="paused",online_model_calls=0,new_wet_experiments=0))
    result=verify()
    json_out(REPORT / "verification.json",dict(utc=utc(),result=result,
        note="Verificationrecord outside sealedmember list to avoid selfhash recursion; verify() rechecks all indexed evidence"))


if __name__=="__main__":
    p=argparse.ArgumentParser(description=__doc__);p.add_argument("action",choices=["previous","seal","verify"])
    a=p.parse_args();result=globals()[a.action]()
    if a.action=="previous":print(json.dumps(result,ensure_ascii=False,indent=2))
