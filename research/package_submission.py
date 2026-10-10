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
    parser.add_argument("--revision", action="store_true", help="Include revised manuscript and discovery evidence")
    parser.add_argument("--biology-followup", action="store_true", help="Include v0.10 factorial/paired-donor evidence; index the excluded raw TPM input")
    parser.add_argument("--preparation-checkpoint", action="store_true", help="Include unfinished common-performance/mechanism preparation and honest status records")
    parser.add_argument("--formal-followup", action="store_true", help="Include formal common-task scores and receptor/ChIP analysis addendum with independent audits")
    parser.add_argument("--paper-directory", default="docs/paper_cn_v2")
    parser.add_argument("--paper-version", default="v0.9")
    parser.add_argument("--result", type=Path, default=ROOT / "research/results/w00_baseline/paper-cn-delivery-audit-result.json")
    args = parser.parse_args()
    if args.biology_followup and (not args.revision or args.paper_version != "v0.10"):
        raise ValueError("Biology follow-up requires --revision and --paper-version v0.10")
    if args.preparation_checkpoint and not args.biology_followup:
        raise ValueError("Preparation checkpoint requires --biology-followup")
    if args.formal_followup and not args.preparation_checkpoint:
        raise ValueError("Formal follow-up retains the preceding preparation checkpoint")
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
    excluded_inputs = []
    if args.revision:
        documents += [ROOT / "CITATION.cff", ROOT / "NEWS.md", ROOT / "docs/index.html"]
        for directory in ["docs/paper_cn_v2", "research/paper_cn_revision", "research/discovery", "research/results/discovery_sparcl1_v1"]:
            documents += [p for p in (ROOT / directory).rglob("*") if p.is_file()
                          and "__pycache__" not in p.parts and "rendered_docx" not in p.parts]
        if args.paper_directory != "docs/paper_cn_v2":
            current_paper = (ROOT / args.paper_directory).resolve()
            if not current_paper.is_relative_to(ROOT / "docs") or not current_paper.is_dir():
                raise ValueError("Use a current manuscript directory under docs")
            documents += [p for p in current_paper.rglob("*") if p.is_file() and "rendered_docx" not in p.parts]
        documents += [p for p in (ROOT / "research/results/w00_baseline").glob("revision-*")
                      if p.is_file() and not p.name.startswith(("revision-delivery", "revision-final-audit", "revision-links-delivery", "revision-links-final-audit"))]
        documents += [p for p in (ROOT / "research/results/w00_baseline").glob("revision-*/*") if p.is_file()]
    if args.biology_followup:
        from audit_current_results import candidate_followup
        if candidate_followup(ROOT) != audit.get("candidate_followup"):
            raise ValueError("Document and saved follow-up summaries differ")
        for directory in ["docs/paper_cn_v3", "research/results/discovery_context_v1", "research/results/discovery_donors_v1"]:
            documents += [p for p in (ROOT / directory).rglob("*") if p.is_file()
                          and "rendered_docx" not in p.parts and "__pycache__" not in p.parts
                          and not any(part.endswith(".parts") for part in p.parts)
                          and p.name != "tpm.txt.gz" and not p.name.endswith(".incomplete")]
        documents += [p for p in (ROOT / "research/results/w00_baseline").glob("biology-*")
                      if p.is_file() and not p.name.startswith("biology-delivery")]
        raw = ROOT / "research/results/discovery_donors_v1/tpm.txt.gz"
        download = json.loads(raw.with_name("range_download.json").read_text())
        excluded_inputs.append({"path": raw.relative_to(ROOT).as_posix(),
                                "bytes": download["bytes"], "sha256": download["sha256"],
                                "url": download["url"], "reason": "Large raw input; retained locally and reacquirable by exact SHA-256",
                                "download_command": ["python3", "research/discovery/download_ranges.py", download["url"],
                                                     raw.relative_to(ROOT).as_posix(), "--preserve-report"],
                                "input_manifest": "research/results/discovery_donors_v1/input_manifest.json"})
    if args.preparation_checkpoint:
        for directory in ["research/common_performance", "research/results/common_performance_checkpoint_v1",
                          "research/results/discovery_mechanism_v1"]:
            documents += [p for p in (ROOT / directory).rglob("*") if p.is_file()
                          and "__pycache__" not in p.parts and not p.name.endswith(".incomplete")]
        for prefix in ["performance-", "mechanism-", "followup-checkpoint-"]:
            documents += [p for p in (ROOT / "research/results/w00_baseline").glob(prefix + "*") if p.is_file()]
    if args.formal_followup:
        for directory in ["docs/research_followup_v1", "research/results/common_performance_v4", "research/results/common_performance_applicability_v1",
                          "research/results/discovery_mechanism_fit_v4", "research/results/discovery_chip_v1", "research/results/discovery_chip_analysis_v1",
                          "research/results/common_performance_v1", "research/results/common_performance_v2", "research/results/common_performance_v3",
                          "research/results/discovery_mechanism_fit_v1", "research/results/discovery_mechanism_fit_v2", "research/results/discovery_mechanism_fit_v3"]:
            documents += [p for p in (ROOT / directory).rglob("*") if p.is_file() and "__pycache__" not in p.parts and "rendered_docx" not in p.parts
                          and not p.name.endswith('.incomplete') and not any(part.endswith('.parts') for part in p.parts)]
        documents += [p for p in (ROOT / "research/results/w00_baseline").glob("continuation-*")
                      if p.is_file() and not p.name.startswith("continuation-formal-delivery")]
        documents += [ROOT / "research/results/paper_cn_cases_v1/airway_de.csv",ROOT / "research/results/related_tools/pasilla_volcano.csv",
                      ROOT / "research/cache/pasilla/inst/extdata/pasilla_gene_counts.tsv"]
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
                      "current_chinese_manuscript": (f"{args.paper_directory}/BioExplainR-中文论文-{args.paper_version}.pdf" if args.revision
                                                    else "docs/paper_cn_v1/BioExplainR-中文论文-v0.8.pdf"),
                     "audit": audit_path.relative_to(ROOT).as_posix(), "members": rows,
                     "excluded_inputs": excluded_inputs,
                     "boundaries": ["Not a release or submission-ready sign-off",
                                    ("Fixed SPARCL1 candidate and external single-cell-line experiment included; no new expert evaluation" if args.revision
                                     else "Public miniACC development case included; no new independent scientific or expert evaluation"),
                                   "User experience/learning study deferred; expert evaluation follows software/case/material readiness",
                                    "Historical user guide describes 0.3.1; development addendum is DEVELOPMENT_DELIVERY.md"],
                    "hash_policy": "Per-member SHA-256; this manifest and enclosing ZIP excluded to avoid self-reference"}
        if args.biology_followup:
            manifest["boundaries"] += ["SPARCL1 follow-up: 16 positive paired donors; group difference and three candidate interactions unsupported",
                                       "Follow-up experiments share at least three named culture cell lines; donor counts are not pooled",
                                       "Previously reported response; no first-discovery or causal/protein claim"]
        if args.preparation_checkpoint:
            manifest["preparation_checkpoint"] = "research/results/common_performance_checkpoint_v1/checkpoint.json"
            manifest["boundaries"] += ["Previous checkpoint records preparation_partial: zero calls/scores/fits at that captured time",
                                        "Temporary model/runtime/library are not in ZIP; exact asset hashes are in checkpoint.json",
                                        "Incomplete transport artifacts excluded; no benchmark or mechanism completion inferred"]
        if args.formal_followup:
            manifest["formal_followup"] = "docs/research_followup_v1/README.md"
            manifest["boundaries"] += ["Formal common-task study is a developmental counting/transmission benchmark, not six-tool comprehensive ranking",
                "A549 SPARCL1 fails fixed expression filter; candidate receptor interactions are not estimable",
                "ChIP uses coordinate-verified hg19; GEO mm9 conflict and lack of author confirmation retained; peak overlaps not differential occupancy tests"]
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
        from audit_current_results import verify_file
        for row in manifest.get("excluded_inputs", []):
            if row["path"] in archive.namelist():
                raise ValueError("Excluded input was included in the ZIP")
            verify_file(ROOT, row)
    result = {"status": "pass", "scope": "current development delivery member/content integrity",
              "archive": {"path": output.relative_to(ROOT).as_posix(), "bytes": output.stat().st_size,
                          "sha256": sha256(output.read_bytes())}, "members": len(rows) + 1,
              "member_manifest": rows, "excluded_inputs": manifest.get("excluded_inputs", [])}
    result_path.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Verified {len(rows) + 1} members: {output.relative_to(ROOT)}")
    print(f"Bytes: {result['archive']['bytes']}; SHA-256: {result['archive']['sha256']}")


if __name__ == "__main__":
    main()
