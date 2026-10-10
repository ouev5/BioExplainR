"""Preserve the unsealed first integration draft before editorial corrections."""
from pathlib import Path
import json
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "research/discovery"))
from validation_sources import record, utc, json_out

PAPER = ROOT / "docs/paper_cn_v7"
evidence = PAPER / "evidence"
mapping = [
    (Path(__file__).with_name("build_integrated_paper.py"), "build_integrated_initial.py"),
    (PAPER / "manuscript.md", "manuscript_initial.md"),
    (PAPER / "supplementary.md", "supplementary_initial.md"),
    (PAPER / "export_report.json", "export_report_initial.json"),
    (PAPER / "browser/audit.json", "browser_initial_audit.json"),
]
saved = []
for source, name in mapping:
    destination = evidence / name
    if destination.exists():
        raise ValueError(f"Refusing overwrite {destination}")
    destination.write_bytes(source.read_bytes())
    saved.append(dict(source=record(source), snapshot=record(destination)))
json_out(evidence / "draft_amendment.json", dict(utc=utc(), snapshots=saved,
    reasons=["First audit treated S27–S34 inclusive range as missing literal S33; expand narrative ranges in auditor",
             "Add PTX3 72h to table4 so all four estimable candidates are displayed",
             "Disambiguate previous analysis stages from manuscript-only integration and correct inherited GSE13168 spacing"],
    preserved_scope="Unsealed initial draft; no original scientific records modified"))
print(json.dumps(saved, ensure_ascii=False, indent=2))
