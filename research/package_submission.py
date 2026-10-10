"""Package current documents and development source with audited member hashes."""
import argparse
import hashlib
import json
from pathlib import Path
import zipfile

ROOT = Path(__file__).resolve().parents[1]
DEFAULT = ROOT / "docs/BioExplainR-development-delivery-0.4.0.9000-r7.zip"


def sha256(content):
    return hashlib.sha256(content).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--audit", type=Path, required=True)
    parser.add_argument("--output", type=Path, default=DEFAULT)
    parser.add_argument("--verify-only", action="store_true")
    parser.add_argument("--revision", action="store_true", help="Include v0.9 revision and discovery evidence")
    parser.add_argument("--result", type=Path, default=ROOT / "research/results/w00_baseline/paper-cn-delivery-audit-result.json")
    args = parser.parse_args()
    output = args.output.resolve()
    result_path = args.result.resolve()
    if not output.is_relative_to(ROOT) or output.name == "BioExplainR-submission-bundle.zip":
        raise ValueError("Use a new project-relative delivery path; the historical archive is protected")
    if not result_path.is_relative_to(ROOT) or not result_path.parent.is_dir() or result_path.exists():
        raise ValueError("Use a new project-relative integrity result path with an existing parent")
    if args.verify_only:
        verify(output, result_path)
        return
    if output.exists():
        raise ValueError("Delivery exists; use --verify-only or choose a new output name")
    audit_path = args.audit.resolve()
    audit = json.loads(audit_path.read_text(encoding="utf-8"))
    if audit.get("status") != "pass":
        raise ValueError("Document audit did not pass")
    documents = [ROOT / "docs" / name for name in [
        "BioExplainR-paper-draft.docx", "BioExplainR-paper-draft.pdf", "BioExplainR-paper-draft.html",
        "BioExplainR-supplementary.docx", "BioExplainR-supplementary.pdf", "BioExplainR-supplementary.html",
        "PAPER_DRAFT.md", "SUPPLEMENTARY_MATERIAL.md", "SUBMISSION_README.md", "paper_tables.json",
        "supplementary_tables.json", "paper.css", "BioExplainR-user-guide.docx",
        "DATA_CONTRACTS.md", "MIGRATION.md", "REPRODUCTION.md", "W13_RELEASE_CHECKLIST.md",
        "DEVELOPMENT_DELIVERY.md", "INSTALLATION.md", "ENHANCEMENT_TASKS.md",
        "implementation_records/CONTINUATION_REVIEW.md", "implementation_records/PUBLIC_CASE_CONTINUATION.md",
        "implementation_records/REVIEW_CONTINUATION.md", "implementation_records/W13.md", "ETHICS_AND_HUMAN_EVALUATION.md"]]
    documents += [ROOT / "docs/USER_ACTIONS_REQUIRED.md"]
    documents += sorted((ROOT / "docs").glob("*.md"))
    documents += sorted((ROOT / "docs/implementation_records").glob("*.md"))
    documents += sorted(path for path in (ROOT / "docs/submission_assets").iterdir() if path.is_file())
    documents += sorted(path for path in (ROOT / "docs/paper_cn_v1").rglob("*")
                        if path.is_file() and "rendered_docx" not in path.parts)
    documents += [audit_path, ROOT / "research/results/reference_audit.json", ROOT / "README.md",
                  ROOT / "BioExplainR_0.4.0.9000.tar.gz"]
    documents += sorted(path for path in (ROOT / "research/study_materials").rglob("*")
                        if path.is_file() and path.name != "investigator_answer_key.json")
    # Include engineering reproducibility entry points, not controlled labels.
    for directory in ["tools", "research/frozen_benchmark", "research/w12_challenges", "research/multiomics", "research/paper_cn", ".github"]:
        documents += [path for path in (ROOT / directory).rglob("*") if path.is_file() and "__pycache__" not in path.parts]
    documents += [ROOT / "research/test_frozen_benchmark.py"]
    documents += [ROOT / name for name in ["DESCRIPTION", "NAMESPACE", "LICENSE", ".Rbuildignore", ".gitignore"]]
    for directory in ["R", "man", "inst", "tests"]:
        documents += [path for path in (ROOT / directory).rglob("*") if path.is_file()]
    documents += [ROOT / "research" / name for name in ["package_submission.py", "audit_submission.py", "paper_smoke.cjs", "shiny_acceptance.cjs", "export_paper.py", "prepare_real_data.R"]]
    # Public cached source objects are needed by the new offline development cases.
    documents += [ROOT / "research/cache/real_objects.rds"]
    documents += [ROOT / "research/results/w00_baseline" / name for name in [
        "system_packages.tsv", "SpatialExperiment_1.12.0.tar.gz", "continuation-environment-result.json",
        "continuation-optional-dependencies.csv", "continuation-r-packages.csv", "continuation-system-packages.tsv",
        "continuation-00check.log", "acceptance-source.txt", "acceptance-package-check.txt",
        "continuation-core-smoke.json", "continuation-isolation-result.json", "continuation-bwrap-offline-smoke-status.txt",
        "continuation-api-inventory.csv", "acceptance-http-result.json", "acceptance-shiny-browser/summary.json",
        "acceptance-sandbox-result.json", "acceptance-legacy-api-result.json"]]
    documents += sorted(path for path in (ROOT / "research/results/w00_baseline").glob("improvement-*")
                        if path.is_file())
    # The packaging command's own log and outer integrity result are written later.
    documents += sorted(path for path in (ROOT / "research/results/w00_baseline").glob("review-*")
                        if path.is_file() and not path.name.startswith(("review-delivery", "review-final-audit")))
    documents += sorted(path for path in (ROOT / "research/results/w00_baseline").glob("review-*/*")
                        if path.is_file())
    documents += sorted(path for path in (ROOT / "research/results/miniacc_development_v1").rglob("*")
                        if path.is_file())
    documents += sorted(path for path in (ROOT / "research/results/miniacc_installed_review").rglob("*")
                        if path.is_file())
    documents += sorted(path for path in (ROOT / "research/results/paper_cn_cases_v1").rglob("*") if path.is_file())
    documents += sorted(path for path in (ROOT / "research/results/w00_baseline").glob("paper-cn-*")
                        if path.is_file() and not path.name.startswith(("paper-cn-delivery", "paper-cn-final-audit")))
    documents += sorted(path for path in (ROOT / "research/results/w00_baseline").glob("paper-cn-*/*") if path.is_file())
    documents += [ROOT / "research/manage_baseline.py", ROOT / "research/audit_current_results.py",
                   ROOT / "research/audit_results.R", ROOT / "research/test_current_audit.py", ROOT / "research/README.md"]
    if args.revision:
        documents += [ROOT / "CITATION.cff", ROOT / "NEWS.md"]
        for directory in ["docs/paper_cn_v2", "research/paper_cn_revision", "research/discovery", "research/results/discovery_sparcl1_v1"]:
            documents += [p for p in (ROOT / directory).rglob("*") if p.is_file()
                          and "__pycache__" not in p.parts and "rendered_docx" not in p.parts]
        documents += [p for p in (ROOT / "research/results/w00_baseline").glob("revision-*")
                      if p.is_file() and not p.name.startswith(("revision-delivery", "revision-final-audit"))]
        documents += [p for p in (ROOT / "research/results/w00_baseline").glob("revision-*/*") if p.is_file()]
    documents = sorted(set(documents))
    for path in documents:
        if not path.resolve().is_relative_to(ROOT) or not path.is_file() or path.resolve() in {output, result_path}:
            raise ValueError(f"Missing, self-referencing or non-project member: {path}")
    rows = []
    with zipfile.ZipFile(output, "x", compression=zipfile.ZIP_DEFLATED) as archive:
        for path in documents:
            content = path.read_bytes()
            name = path.relative_to(ROOT).as_posix()
            archive.writestr(name, content)
            rows.append({"path": name, "bytes": len(content), "sha256": sha256(content)})
        manifest = {"manifest_version": "1.0", "status": "development_delivery",
                    "package_version": "0.4.0.9000", "paper_results_version": "0.3.1 historical + 0.4.0.9000 development cases",
                     "current_chinese_manuscript": ("docs/paper_cn_v2/BioExplainR-中文论文-v0.9.pdf" if args.revision
                                                    else "docs/paper_cn_v1/BioExplainR-中文论文-v0.8.pdf"),
                    "audit": audit_path.relative_to(ROOT).as_posix(), "members": rows,
                    "boundaries": ["Not a release or submission-ready sign-off",
                                    ("Fixed SPARCL1 candidate and external single-cell-line experiment included; no new expert evaluation" if args.revision
                                     else "Public miniACC development case included; no new independent scientific or expert evaluation"),
                                   "User experience/learning study deferred; expert evaluation follows software/case/material readiness",
                                   "Historical user guide describes 0.3.1; development addendum is DEVELOPMENT_DELIVERY.md"],
                    "hash_policy": "Per-member SHA-256; this manifest and enclosing ZIP excluded to avoid self-reference"}
        archive.writestr("delivery_manifest.json", json.dumps(manifest, ensure_ascii=False, indent=2) + "\n")
    verify(output, result_path)


def verify(output, result_path):
    with zipfile.ZipFile(output) as archive:
        if archive.testzip() is not None or len(archive.namelist()) != len(set(archive.namelist())):
            raise ValueError("Corrupt or duplicate ZIP members")
        manifest = json.loads(archive.read("delivery_manifest.json"))
        rows = manifest["members"]
        if len(rows) != len({row["path"] for row in rows}) or set(archive.namelist()) != {row["path"] for row in rows} | {"delivery_manifest.json"}:
            raise ValueError("Delivery membership mismatch")
        for row in rows:
            path = ROOT / row["path"]
            if Path(row["path"]).is_absolute() or not path.resolve().is_relative_to(ROOT):
                raise ValueError("Unsafe archive path")
            content = archive.read(row["path"])
            if len(content) != row["bytes"] or sha256(content) != row["sha256"] or content != path.read_bytes():
                raise ValueError(f"Member differs from audited current tree: {row['path']}")
    result = {"status": "pass", "scope": "current development delivery member/content integrity",
              "archive": {"path": output.relative_to(ROOT).as_posix(), "bytes": output.stat().st_size,
                          "sha256": sha256(output.read_bytes())}, "members": len(rows) + 1,
              "member_manifest": rows}
    result_path.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Verified {len(rows) + 1} members: {output.relative_to(ROOT)}")
    print(f"Bytes: {result['archive']['bytes']}; SHA-256: {result['archive']['sha256']}")


if __name__ == "__main__":
    main()
