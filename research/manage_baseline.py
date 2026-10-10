"""Capture W00 baseline evidence using only the Python standard library."""
import argparse
import csv
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import platform
import shutil
import subprocess
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "research/results/w00_baseline"


def now():
    return datetime.now(timezone.utc).isoformat()


def record(path):
    return {"path": path.relative_to(ROOT).as_posix(), "bytes": path.stat().st_size,
            "sha256": hashlib.sha256(path.read_bytes()).hexdigest()}


def write_json(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def write_inventory(path, files):
    rows = [record(file) for file in sorted(set(files)) if file.is_file()]
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=["path", "bytes", "sha256"])
        writer.writeheader()
        writer.writerows(rows)
    return rows


def snapshot():
    target = OUT / "original_records.csv"
    if target.exists():
        raise ValueError("Original-record inventory already exists; refusing to overwrite")
    files = [p for p in (ROOT / "research/results").rglob("*")
             if OUT not in p.parents]
    files += list((ROOT / "docs/submission_assets").rglob("*"))
    files += list((ROOT / "docs").glob("BioExplainR-*"))
    rows = write_inventory(target, files)
    print(f"Saved pre-change inventory: {len(rows)} files")


def run(label, command):
    if not label or any(c not in "abcdefghijklmnopqrstuvwxyz0123456789-_" for c in label):
        raise ValueError("Use a lowercase ASCII execution label")
    log, metadata = OUT / f"{label}.txt", OUT / f"{label}.json"
    if log.exists() or metadata.exists():
        raise ValueError("Execution record exists; use a new label")
    started = now()
    with log.open("w", encoding="utf-8") as handle:
        process = subprocess.Popen(command, cwd=ROOT, stdout=subprocess.PIPE,
                                   stderr=subprocess.STDOUT, text=True, errors="replace")
        for line in process.stdout:
            handle.write(line)
            handle.flush()
            print(line, end="", flush=True)
        code = process.wait()
    write_json(metadata, {"command": command, "working_directory": ".", "started_utc": started,
                          "finished_utc": now(), "exit_code": code,
                          "status": "pass" if code == 0 else "fail", "log": record(log)})
    return code


def environment():
    tools = {}
    for name, args in {"R": ["--version"], "python3": ["--version"], "node": ["--version"],
                       "npm": ["--version"], "pandoc": ["--version"],
                       "libreoffice": ["--version"], "google-chrome": ["--version"]}.items():
        executable = shutil.which(name)
        result = subprocess.run([executable, *args], capture_output=True, text=True) if executable else None
        tools[name] = {"path": executable, "status": "available" if result and result.returncode == 0 else "missing",
                       "version": result.stdout.strip() if result else None}
    packages = subprocess.run(["dpkg-query", "-W", "-f=${Package}\t${Version}\n"],
                              capture_output=True, text=True, check=True)
    (OUT / "system_packages.tsv").write_text(packages.stdout, encoding="utf-8")
    write_json(OUT / "environment.json", {"captured_utc": now(), "platform": platform.platform(),
               "tools": tools, "system_packages": record(OUT / "system_packages.tsv"),
               "r_packages": record(OUT / "r_packages.csv"),
               "r_session": record(OUT / "r_environment.txt"),
               "supplemental_tools": record(OUT / "supplemental_tools.json"),
               "restoration_spec": "tools/restore-baseline.sh",
               "clean_environment_reproduction": "not_run (W13)"})
    print("Captured tool versions and installed system/R package inventories")


def inspect_bundle():
    path = ROOT / "docs/BioExplainR-submission-bundle.zip"
    changed, missing = [], []
    with zipfile.ZipFile(path) as archive:
        require_unique = len(archive.namelist()) == len(set(archive.namelist()))
        corrupt = archive.testzip()
        for name in archive.namelist():
            local = ROOT / name
            if Path(name).is_absolute() or not local.resolve().is_relative_to(ROOT.resolve()):
                raise ValueError("Archive contains a non-project path")
            if not local.is_file():
                missing.append(name)
            elif hashlib.sha256(archive.read(name)).hexdigest() != record(local)["sha256"]:
                changed.append(name)
        count = len(archive.namelist())
    write_json(OUT / "bundle_inspection.json", {"archive": record(path), "members": count,
               "zip_integrity": "pass" if corrupt is None and require_unique else "fail",
               "changed_vs_current_tree": changed, "missing_vs_current_tree": missing,
               "status": "historical_stale" if changed or missing else "members_match_current_tree",
               "note": "Existing submission bundle is preserved; no claim of current source/reproduction coverage"})
    print(f"Inspected existing ZIP: {count} members, {len(changed)} changed, {len(missing)} missing")


def manifest():
    groups = {
        "main_experiment": ["research/results/main_scale_480"],
        "common_task": ["research/results/common_task_scale_480",
                        "research/results/reference_facts_scale_480.json",
                        "research/results/reference_facts_scale_480_manifest.json"],
        "public_datasets": ["research/results/public_datasets"],
        "human_evaluation": ["research/results/human_evaluation"],
        "related_tools": ["research/results/related_tools"],
        "miniacc_development": ["research/results/miniacc_development_v1", "research/results/miniacc_installed_review"],
        "paper_cn_cases": ["research/results/paper_cn_cases_v1", "research/cache/real_objects.rds"],
        "paper_cn_revision": ["docs/paper_cn_v1"],
        "paper_cn_v09": ["docs/paper_cn_v2"],
        "paper_cn_v091": ["docs/paper_cn_v3"],
        "paper_cn_v010": ["docs/paper_cn_v4"],
        "discovery_sparcl1": ["research/results/discovery_sparcl1_v1"],
        "discovery_context": ["research/results/discovery_context_v1"],
        "discovery_donors": ["research/results/discovery_donors_v1"],
        "common_performance_preparation": ["research/results/common_performance_checkpoint_v1"],
        "mechanism_preparation": ["research/results/discovery_mechanism_v1"],
        "common_performance_formal": ["research/results/common_performance_v4", "research/results/common_performance_applicability_v1"],
        "mechanism_fit": ["research/results/discovery_mechanism_fit_v4"],
        "chip_verification": ["research/results/discovery_chip_v1", "research/results/discovery_chip_analysis_v1"],
        "followup_research_report": ["docs/research_followup_v1"],
        "paper": ["docs/PAPER_DRAFT.md", "docs/SUPPLEMENTARY_MATERIAL.md", "docs/paper_tables.json",
                  "docs/supplementary_tables.json", "docs/paper.css", "docs/submission_assets",
                  "research/results/submission-audit.json", "research/results/reference_audit.json"],
    }
    groups["paper"] += [p.relative_to(ROOT).as_posix() for p in (ROOT / "docs").glob("BioExplainR-*")
                        if "submission-bundle" not in p.name]
    claimed = set()
    entries = {}
    for name, roots in groups.items():
        files = []
        for item in roots:
            path = ROOT / item
            if not path.exists():
                raise FileNotFoundError(item)
            files.extend(path.rglob("*") if path.is_dir() else [path])
        rows = write_inventory(OUT / f"{name}_files.csv", files)
        claimed.update(row["path"] for row in rows)
        entries[name] = {"entrypoints": roots, "inventory": record(OUT / f"{name}_files.csv"), "file_count": len(rows),
                         "mode": "saved_results", "rerun_experiment": False}
        if name in {"common_performance_preparation", "mechanism_preparation"}:
            entries[name]["mode"] = "preparation_partial"
            entries[name]["note"] = "Inputs/status only; no new performance scores or mechanism fit"
    historical = [p for p in (ROOT / "research/results").rglob("*")
                  if p.is_file() and OUT not in p.parents and p.name != "current_manifest.json"
                  and p.relative_to(ROOT).as_posix() not in claimed]
    rows = write_inventory(OUT / "historical_files.csv", historical)
    entries["historical"] = {"inventory": record(OUT / "historical_files.csv"), "file_count": len(rows),
                             "mode": "historical", "rerun_experiment": False,
                             "entrypoints": ["research/results/experiment_manifest.json",
                                             "research/results/pilot_precision/experiment_manifest.json",
                                             "research/results/common_task/common_task_manifest.json"],
                             "note": "Directories remain in place; see docs/REPRODUCTION.md for classification"}
    source = [ROOT / p for p in ["DESCRIPTION", "NAMESPACE", "LICENSE", "LICENSE.md", ".Rbuildignore", ".gitignore", "CITATION.cff", "NEWS.md"]]
    for directory in ["R", "man", "inst", "tests", "tools", ".github", "research"]:
        source += [p for p in (ROOT / directory).rglob("*") if p.is_file()
                   and "__pycache__" not in p.parts
                   and not any(part in p.relative_to(ROOT).parts for part in ["results", "cache", "study_materials"])]
    rows = write_inventory(OUT / "source_files.csv", source)
    source_count = len(rows)
    code_hash = hashlib.sha256(json.dumps(rows, sort_keys=True, separators=(",", ":")).encode()).hexdigest()
    package_files = [ROOT / p for p in ["DESCRIPTION", "NAMESPACE", "LICENSE"]]
    for directory in ["R", "man", "inst", "tests"]:
        package_files += [p for p in (ROOT / directory).rglob("*") if p.is_file()]
    package_rows = write_inventory(OUT / "package_source_files.csv", package_files)
    package_hash = hashlib.sha256(json.dumps(package_rows, sort_keys=True, separators=(",", ":")).encode()).hexdigest()
    docs = [ROOT / "README.md", ROOT / "SESSION_HANDOFF.md", ROOT / "docs/index.html"] + list((ROOT / "docs").rglob("*.md"))
    write_inventory(OUT / "documentation_files.csv", docs)
    git = subprocess.run(["git", "rev-parse", "--verify", "HEAD"], cwd=ROOT, capture_output=True, text=True)
    status = subprocess.run(["git", "status", "--short"], cwd=ROOT, capture_output=True, text=True, check=True)
    version = next(line.split(":", 1)[1].strip() for line in (ROOT / "DESCRIPTION").read_text().splitlines()
                   if line.startswith("Version:"))
    checks = {p.stem: json.loads(p.read_text()) for p in OUT.glob("*.json")
              if p.stem not in ["environment", "current_audit", "historical_audit", "bundle_inspection",
                                "audit-current", "audit-historical"]
              and "command" in json.loads(p.read_text())}
    artifacts = [p for p in OUT.iterdir() if p.is_file() and p.name not in
                 ["current_audit.json", "historical_audit.json", "audit-current.txt", "audit-current.json",
                  "audit-historical.txt", "audit-historical.json", "manifest_files.csv"]]
    artifacts += [p for p in (OUT / "paper_browser").glob("*") if p.is_file()]
    artifacts += [p for p in OUT.glob("continuation-*/*") if p.is_file()]
    artifacts += [p for p in OUT.glob("acceptance-*/*") if p.is_file()]
    artifacts += [p for p in OUT.glob("review-*/*") if p.is_file()]
    artifacts += [p for p in OUT.glob("paper-cn-*/*") if p.is_file()]
    artifacts += [p for p in OUT.glob("revision-*/*") if p.is_file()]
    artifacts += [p for p in OUT.glob("biology-*") if p.is_file()]
    if (OUT / "continuation-bwrap-offline-smoke-status.txt").is_file():
        artifacts += [OUT / "continuation-bwrap-offline-smoke-status.txt"]
    artifacts += [OUT / "BioExplainR.Rcheck/00check.log", OUT / "BioExplainR.Rcheck/00install.out",
                  OUT / "BioExplainR.Rcheck/tests/testthat.Rout"]
    write_inventory(OUT / "manifest_files.csv", artifacts)
    from audit_current_results import main_experiment, common_task, supporting_results, paper
    result_summary = {"main_experiment": main_experiment(ROOT), "common_task": common_task(ROOT),
                      "supporting": supporting_results(ROOT), "paper": paper(ROOT)}
    write_json(ROOT / "research/results/current_manifest.json", {
"manifest_version": "development-baseline-12", "created_utc": now(), "package_version": version,
          "scope": "Stored v0.10 plus formal common-task/GR-intervention/ChIP research addendum; previous preparation checkpoint retained in historical scope; GitHub publication paused by owner",
        "git": {"commit_sha": git.stdout.strip() if git.returncode == 0 else None,
                "state": "uncommitted_baseline" if git.returncode else "working_tree",
                "status": status.stdout.splitlines()},
        "source": {"inventory": record(OUT / "source_files.csv"), "code_hash": code_hash,
                   "package_inventory": record(OUT / "package_source_files.csv"), "package_code_hash": package_hash,
                   "archive": record(ROOT / f"BioExplainR_{version}.tar.gz"),
                   "hash_policy": "SHA-256 of UTF-8 canonical JSON inventory (sorted paths, size and file SHA-256)"},
        "documentation": record(OUT / "documentation_files.csv"),
        "environment": record(OUT / "environment.json"), "groups": entries,
        "saved_result_summary": result_summary,
          "software_check_records": {"source": "revision-source", "package": "revision-package-check"},
          "continuation_environment": record(OUT / "continuation-environment-result.json"),
          "review_environment": record(OUT / "review-environment-result.json"),
         "user_actions": "docs/USER_ACTIONS_REQUIRED.md",
         "audit_entrypoints": {"current": "R --vanilla --slave -f research/audit_results.R --args --mode=current",
                              "historical": "R --vanilla --slave -f research/audit_results.R --args --mode=historical",
                              "current_output": "research/results/w00_baseline/current_audit.json",
                              "historical_output": "research/results/w00_baseline/historical_audit.json"},
        "baseline_artifacts": record(OUT / "manifest_files.csv"), "checks": checks,
        "original_record_inventory": record(OUT / "original_records.csv"),
          "delivery_bundle": {"path": "docs/BioExplainR-development-delivery-0.4.0.9000-r14.zip", "status": "development_delivery_verified",
                                "inspection": record(OUT / "handoff-formal-docs-delivery-audit-result.json")},
"paper_cn": {"path": "docs/paper_cn_v4", "audit": record(ROOT / "docs/paper_cn_v4/audit.json"),
                         "version": "v0.10", "human_evaluation": "not_in_manuscript; deferred placeholders"},
         "historical_delivery_bundle": {"path": "docs/BioExplainR-submission-bundle.zip", "status": "historical_stale_preserved",
                                         "inspection": record(OUT / "bundle_inspection.json")},
          "boundaries": ["Earlier stored experiments were audited offline; new formal follow-up has separate execution records", "No new expert or user study",
                          "Common-task developmental benchmark; A549 SPARCL1 filtered/not_estimable; ChIP coordinate-verified hg19 without author confirmation",
                        "No Git commit/release/DOI is inferred", "W10/W11 external scientific materials are not complete",
                         "0.4.0.9000 is a development snapshot; GitHub publication paused by owner (earlier creation permission error retained)",
                         "SPARCL1 validation is an external single-cell-line experiment, not donor-independent confirmation",
                         "SPARCL1 follow-up: 16 paired donors positive in GSE94335, group difference and three candidate interactions unsupported",
                         "GSE94335/GSE146017 share at least three named culture cell lines; donor counts are not pooled",
                         "SPARCL1 glucocorticoid response was reported previously (Himes 2014; Kan 2019); no first-discovery claim"]})
    print(f"Built current_manifest.json: {source_count} source files; code hash {code_hash}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=["snapshot", "environment", "inspect_bundle", "manifest", "run"])
    parser.add_argument("args", nargs=argparse.REMAINDER)
    options = parser.parse_args()
    OUT.mkdir(parents=True, exist_ok=True)
    if options.action == "run":
        label, *command = options.args
        if command and command[0] == "--":
            command = command[1:]
        return run(label, command)
    globals()[options.action]()
    return 0


if __name__ == "__main__":
    sys.exit(main())
