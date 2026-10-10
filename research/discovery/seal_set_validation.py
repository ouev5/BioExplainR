"""Seal v0.12 scientific/manuscript work and build a local continuation delivery."""
import argparse
import csv
import hashlib
import json
import zipfile
from pathlib import Path
from validation_sources import ROOT,HERE,record,utc,json_out
from set_integrity import prior_integrity

SOURCE=ROOT/"research/results/discovery_set_validation_v1"
PAPER=ROOT/"docs/paper_cn_v6"
MANIFEST=PAPER/"manuscript_manifest.json"
ARCHIVE=PAPER/"BioExplainR-中文论文-v0.12-附件.zip"
DELIVERY=ROOT/"docs/BioExplainR-development-delivery-0.4.0.9000-r15.zip"
LATEST=ROOT/"research/results/latest_manifest.json"


def check_archive(archive,entries):
    expected={r["path"]:r for r in entries}
    with zipfile.ZipFile(archive) as zipped:
        assert zipped.testzip() is None
        assert len(zipped.namelist())==len(set(zipped.namelist()))==len(expected)
        assert set(zipped.namelist())==set(expected)
        for path,entry in expected.items():
            data=zipped.read(path);assert len(data)==entry["bytes"] and hashlib.sha256(data).hexdigest()==entry["sha256"],path


def check_protected():
    with (ROOT/"research/results/w00_baseline/original_records.csv").open(newline="") as stream:
        protected=list(csv.DictReader(stream))
    for r in protected:
        actual=record(ROOT/r["path"]);assert actual["sha256"]==r["sha256"] and actual["bytes"]==int(r["bytes"]),r["path"]
    return len(protected)


def verify():
    manifest=json.loads(MANIFEST.read_text())
    for group in ["files","source_code","documentation","dependencies"]:
        for rec in manifest[group]:assert record(ROOT/rec["path"])==rec,rec["path"]
    assert record(ARCHIVE)==manifest["archive"]
    check_archive(ARCHIVE,manifest["archive_members"])
    latest=json.loads(LATEST.read_text())
    assert record(MANIFEST)==latest["manuscript_manifest"] and record(DELIVERY)==latest["delivery_archive"]
    check_archive(DELIVERY,latest["delivery_members"])
    prior=prior_integrity(SOURCE)
    protected=check_protected()
    print(json.dumps(dict(status="pass",files=len(manifest["files"]),source_code=len(manifest["source_code"]),
        manuscript_archive_members=len(manifest["archive_members"]),delivery_members=len(latest["delivery_members"]),
        delivery_bytes=DELIVERY.stat().st_size,original_protected_files=protected,prior_integrity=prior,scope=latest["scope"]),ensure_ascii=False,indent=2))


def seal():
    for path in [MANIFEST,ARCHIVE,DELIVERY,LATEST]:
        if path.exists():raise ValueError(f"Refusingoverwrite{path}")
    prior=prior_integrity(SOURCE)
    protected=check_protected()
    for path in [PAPER/"audit.json",PAPER/"browser_final_v2/audit.json",SOURCE/"numeric_audit.json",SOURCE/"sensitivity_audit.json",
                 SOURCE/"r_tpm_audit.json",SOURCE/"bioexplainr_workflow.json",SOURCE/"unselected_protein/r_audit.json",
                 SOURCE/"unselected_protein/final_audit.json",SOURCE/"unselected_protein/bioexplainr_workflow.json"]:
        assert json.loads(path.read_text())["status"]=="pass",path
    files=[record(p) for directory in [SOURCE,PAPER] for p in sorted(directory.rglob("*")) if p.is_file()]
    paths=set(HERE.glob("*set*.py"))|set(HERE.glob("*set*.R"))|{HERE/"SET_VALIDATION_PROTOCOL.md"}
    paths.add(HERE/"requirements-set.txt")
    paths |= set((ROOT/"research/paper_cn_revision").glob("*set*.py"))|set((ROOT/"research/paper_cn_revision").glob("*set*.cjs"))
    paths |= {ROOT/"research/export_paper.py",ROOT/"research/paper_cn_revision/build_revision.py",ROOT/"research/paper_cn_revision/build_discovery_paper.py"}
    paths |= {ROOT/"DESCRIPTION",ROOT/"NAMESPACE"}|set((ROOT/"R").glob("*.R"))
    paths |= {HERE/"validation_sources.py",HERE/"validation_integrity.py"}
    source_code=[record(p) for p in sorted(paths)]
    docs=[record(ROOT/p) for p in ["rgo.md","README.md","docs/index.html","docs/USER_ACTIONS_REQUIRED.md"]]
    dependency_paths={ROOT/"docs/biology_validation_v2/validation_manifest.json",ROOT/"docs/paper_cn_v5/manuscript_manifest.json",
        ROOT/"docs/biology_discovery_v2/discovery_manifest.json",ROOT/"research/results/current_manifest.json"}
    frozen=json.loads((SOURCE/"analysis_freeze.json").read_text())
    dependency_paths |= {ROOT/r["path"] for r in frozen["inputs"]}
    for entry in json.loads((PAPER/"assets_manifest.json").read_text())["copied_tables"]+json.loads((PAPER/"assets_manifest.json").read_text())["figure_sources"]:
        dependency_paths.add(ROOT/entry["source"]["path"])
    dependencies=[record(p) for p in sorted(dependency_paths)]
    # Portable reports retain full extracted original tables; duplicate networkparts/all-genemodels remain locally indexed.
    excluded=[];included=[]
    for r in files:
        path=Path(r["path"])
        network=any(part in path.parts for part in ["protein_archives","protein_archives_inspected","protein_full_tables","protein_full_tables_small"])
        extracted="extracted_verified" in path.parts or "extracted" in path.parts
        keep=not (network and not extracted and path.suffix==".bin" or path.name=="count_model.rds")
        (included if keep else excluded).append(r)
    members={r["path"]:r for r in included+source_code+docs+dependencies}
    with zipfile.ZipFile(ARCHIVE,"x",compression=zipfile.ZIP_DEFLATED,compresslevel=6) as archive:
        for r in members.values():archive.write(ROOT/r["path"],arcname=r["path"])
    data=dict(status="sealed",utc=utc(),files=files,source_code=source_code,documentation=docs,dependencies=dependencies,
        archive=record(ARCHIVE),archive_members=list(members.values()),excluded_duplicate_or_model_files=excluded,
        prior_integrity=prior,original_protected_files=protected,original_protected_files_unchanged=True,
        online_model_calls=0,new_wet_experiments=0,human_signoff="notperformed")
    json_out(MANIFEST,data)
    # r15 is an explicit continuation bundle: preceding portable validation + new manuscript/science;
    # large source matrices/parts remain indexed with restoration URLs rather than silently represented as present.
    delivery={r["path"]:r for r in members.values()}
    delivery[MANIFEST.relative_to(ROOT).as_posix()]=record(MANIFEST)
    old=json.loads((ROOT/"docs/biology_validation_v2/validation_manifest.json").read_text())
    old_archive=ROOT/old["archive"]["path"]
    old_members={r["path"]:r for r in old["archive_members"]}
    with zipfile.ZipFile(DELIVERY,"x",compression=zipfile.ZIP_DEFLATED,compresslevel=6) as archive:
        for r in delivery.values():archive.write(ROOT/r["path"],arcname=r["path"])
        with zipfile.ZipFile(old_archive) as historical:
            for path,r in old_members.items():
                if path in delivery:continue
                blob=historical.read(path);assert hashlib.sha256(blob).hexdigest()==r["sha256"]
                archive.writestr(path,blob);delivery[path]=r
    json_out(LATEST,dict(status="sealed_local_continuation",utc=utc(),version="v0.12",manuscript_manifest=record(MANIFEST),
        delivery_archive=record(DELIVERY),delivery_members=list(delivery.values()),
        scope="Currentv0.12 continuation manuscript/science plus priorportablevalidation; not replacement of baseline12wholeproject audit",
        historical_baseline=record(ROOT/"research/results/current_manifest.json"),prior_integrity=prior,
        primary=dict(frozen=54,measured=53,robust_supported=45),publication="paused",excluded_files_count=len(excluded)))
    verify()


if __name__=="__main__":
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument("action",choices=["seal","verify"])
    globals()[parser.parse_args().action]()
