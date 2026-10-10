"""Read-only, offline audit of the indexed current results (no model calls)."""
import argparse
import csv
from datetime import datetime, timezone
import hashlib
import itertools
import json
import math
from pathlib import Path
import re
import sys
import tarfile
import zipfile

ROOT = Path(__file__).resolve().parents[1]


def require(condition, message):
    if not condition:
        raise ValueError(message)


def resolve(root, name):
    path = root / name
    require(not Path(name).is_absolute() and path.resolve().is_relative_to(root.resolve()),
            f"Inventory path is not project-relative: {name}")
    require(path.is_file(), f"Missing file: {name}")
    return path


def read_json(path):
    return json.loads(path.read_text(encoding="utf-8"))


def read_csv(path):
    with path.open(encoding="utf-8", newline="") as handle:
        return list(csv.DictReader(handle))


def verify_file(root, item):
    path = resolve(root, item["path"])
    require(path.stat().st_size == int(item["bytes"]), f"Size mismatch: {item['path']}")
    require(hashlib.sha256(path.read_bytes()).hexdigest() == item["sha256"],
            f"SHA-256 mismatch: {item['path']}")


def verify_inventory(root, item):
    verify_file(root, item)
    records = read_csv(resolve(root, item["path"]))
    require(len({row["path"] for row in records}) == len(records), f"Duplicate inventory path: {item['path']}")
    for row in records:
        verify_file(root, row)
    return len(records)


def boolean(value):
    require(value in [True, False, "TRUE", "FALSE"], f"Invalid boolean: {value}")
    return value is True or value == "TRUE"


def close(a, b):
    return math.isclose(float(a), float(b), rel_tol=1e-8, abs_tol=1e-10)


def matches(expected, value):
    if value is None:
        return False
    if isinstance(expected, (int, float)) and not isinstance(expected, bool):
        try:
            number = float(value)
        except (ValueError, TypeError):
            return False
        return math.isfinite(number) and abs(number - expected) <= (1e-6 if expected == 0 else abs(expected) * 1e-6)
    r_character = lambda x: ("TRUE" if x else "FALSE") if isinstance(x, bool) else str(x)
    return r_character(expected) == r_character(value)


def unique(rows, fields, label):
    keys = {tuple(row[field] for field in fields) for row in rows}
    require(len(keys) == len(rows), f"Duplicate {label} key")
    return keys


def main_experiment(root):
    base = root / "research/results/main_scale_480"
    protocol = read_json(base / "experiment_manifest.json")
    cases = read_json(base / "case_manifest.json")
    reference = read_json(base / "reference_facts.json")
    require(set(cases) == set(reference), "Main case/reference IDs differ")
    targets = {(case, fact) for case, values in reference.items() for fact in values}
    for case, spec in cases.items():
        require(set(spec["target_facts"]) == set(reference[case]), f"Main target mismatch: {case}")
    require(len(cases) == protocol["n_cases"] and len(targets) == protocol["n_facts"], "Main manifest counts differ")
    scores = read_csv(base / "fact_scores.csv")
    calls = read_csv(base / "model_calls.csv")
    score_keys = unique(scores, ["case", "fact", "method", "replicate"], "main score")
    call_keys = unique(calls, ["case", "method", "replicate"], "main call")
    repeats = [str(i) for i in range(1, protocol["replicates"] + 1)]
    require(score_keys == {(c, f, m, r) for (c, f), m, r in itertools.product(targets, protocol["methods"], repeats)},
            "Main missing/unexpected fact evaluations")
    require(call_keys == set(itertools.product(cases, protocol["methods"], repeats)), "Main missing/unexpected requests")
    call_map = {(r["case"], r["method"], r["replicate"]): r for r in calls}
    stored_scores = {}
    for case, method, repeat in call_keys:
        prefix = base / "model" / f"{case}__{method}__{repeat}"
        response = read_json(prefix.with_suffix(".json"))
        prompt = read_json(Path(str(prefix) + "__prompt.json"))
        require(response["case"] == case and response["method"] == method and str(response["replicate"]) == repeat,
                f"Main response identity mismatch: {prefix.name}")
        require(isinstance(prompt.get("system"), str) and isinstance(prompt.get("user"), str), "Invalid saved prompt")
        call = call_map[case, method, repeat]
        require(boolean(call["success"]) == ("error" not in response["response"]), "Call success mismatch")
        require(boolean(call["structured"]) == (response.get("parsed") is not None), "Structured status mismatch")
        require(call["model_reported"] == response["response"].get("model", "NA"), "Reported model mismatch")
        require(call["validation"] == response["validation"]["status"], "Validation status mismatch")
        response_keys = unique(response["scores"], ["fact"], "response score")
        require({key[0] for key in response_keys} == set(reference[case]), "Missing response score")
        claims = (response.get("parsed") or {}).get("claims", [])
        for score in response["scores"]:
            hits = [cl for cl in claims if isinstance(cl, dict) and cl.get("fact") == score["fact"]]
            value = hits[0].get("value") if len(hits) == 1 else None
            require(value == score.get("value"), "Saved claim/score value mismatch")
            require(score["expected"] == reference[case][score["fact"]], "Saved expected/reference mismatch")
            require(score["answered"] == (value is not None), "Saved answered mismatch")
            require(score["correct"] == matches(score["expected"], value), "Saved correctness mismatch")
            stored_scores[case, score["fact"], method, repeat] = score
    for row in scores:
        saved = stored_scores[row["case"], row["fact"], row["method"], row["replicate"]]
        require(boolean(row["correct"]) == saved["correct"] and boolean(row["answered"]) == saved["answered"],
                "CSV/response score mismatch")
        expected = reference[row["case"]][row["fact"]]
        require(matches(expected, row["expected"]), "CSV expected/reference mismatch")
        if saved["value"] is not None:
            require(matches(saved["value"], row["value"]), "CSV value/response mismatch")
    results = []
    summary = read_csv(base / "ablation_summary.csv")
    unique(summary, ["method"], "main summary")
    require({r["method"] for r in summary} == set(protocol["methods"]), "Main summary methods mismatch")
    for method in protocol["methods"]:
        rows = [r for r in scores if r["method"] == method]
        cc = [r for r in calls if r["method"] == method]
        correct, answered = sum(boolean(r["correct"]) for r in rows), sum(boolean(r["answered"]) for r in rows)
        computed = {"method": method, "expected": len(rows), "correct": correct, "answered": answered,
                    "accuracy": correct / len(rows), "coverage": answered / len(rows),
                    "answered_accuracy": correct / answered if answered else None,
                    "calls": len(cc), "api_success": sum(boolean(r["success"]) for r in cc),
                    "structured": sum(boolean(r["structured"]) for r in cc)}
        for saved in [next(r for r in summary if r["method"] == method),
                      next(r for r in protocol["summary"] if r["method"] == method)]:
            for key in set(computed) - {"method", "answered"}:
                require(close(saved[key], computed[key]), f"Main summary mismatch: {method}.{key}")
        computed["correct_by_repeat"] = {r: sum(boolean(s["correct"]) for s in rows if s["replicate"] == r) for r in repeats}
        results.append(computed)
    return {"cases": len(cases), "unique_target_facts": len(targets), "requests": len(calls),
            "score_rows": len(scores), "methods": results, "score_policy": "saved protocol relative tolerance 1e-6"}


def common_task(root):
    base = root / "research/results/common_task_scale_480"
    protocol = read_json(base / "common_task_manifest.json")
    reference = read_json(root / "research/results/reference_facts_scale_480.json")
    targets = {(case, fact) for case, values in reference.items() for fact in values}
    require(set(reference) == set(protocol["cases"]) and len(reference) == protocol["n_cases"] and
            len(targets) == protocol["n_facts"], "Common task manifest counts differ")
    scores = read_csv(base / "common_task_fact_scores.csv")
    calls = read_csv(base / "common_task_calls.csv")
    summary = read_csv(base / "common_task_summary.csv")
    methods = {r["method"] for r in summary}
    unique(summary, ["method"], "common summary")
    require(unique(scores, ["case", "fact", "method"], "common score") ==
            {(c, f, m) for (c, f), m in itertools.product(targets, methods)}, "Common missing/unexpected scores")
    require(unique(calls, ["case", "method"], "common call") == set(itertools.product(reference, methods)),
            "Common missing/unexpected calls")
    results = []
    for saved in summary:
        method = saved["method"]
        rows = [r for r in scores if r["method"] == method]
        cc = [r for r in calls if r["method"] == method]
        statuses = sorted({r["status"] for r in cc})
        require(all(r["status"] == saved["status"] for r in rows + cc), "Common status mismatch")
        if saved["mode"] == "openai_compatible":
            for call in cc:
                file = base / f"{method.replace(':', '__')}__{call['case']}.json"
                response = read_json(file)
                require(("error" not in response) == (call["status"] == "executed"), "Common response/call status mismatch")
                parsed = json.loads(response["text"].strip().removeprefix("```json").removesuffix("```").strip())
                for row in [r for r in rows if r["case"] == call["case"]]:
                    claims = parsed.get("claims", [])
                    hits = [cl for cl in claims if cl.get("fact", cl.get("path")) == row["fact"]]
                    value = hits[0].get("value", hits[0].get("_value")) if len(hits) == 1 else None
                    require(boolean(row["answered"]) == (value is not None), "Common response/answered mismatch")
                    require(value is None or matches(value, row["value"]), "Common response/CSV value mismatch")
        for row in rows:
            expected = reference[row["case"]][row["fact"]]
            require(matches(expected, row["expected"]), "Common expected/reference mismatch")
            require(boolean(row["correct"]) == (boolean(row["answered"]) and matches(expected, row["value"])),
                    "Common stored correctness mismatch")
        correct, answered = sum(boolean(r["correct"]) for r in rows), sum(boolean(r["answered"]) for r in rows)
        for key, value in {"expected": len(rows), "correct": correct, "answered": answered,
                           "accuracy": correct / len(rows), "coverage": answered / len(rows)}.items():
            require(close(saved[key], value), f"Common summary mismatch: {method}.{key}")
        results.append({"method": method, "mode": saved["mode"], "statuses": statuses,
                        "case_records": len(cc), "expected": len(rows), "correct": correct, "answered": answered})
    return {"cases": len(reference), "unique_target_facts": len(targets), "call_records": len(calls),
            "score_rows": len(scores), "methods": results,
            "note": "Call records include deterministic, replay and not-configured methods; they are not all API requests"}


def supporting_results(root):
    datasets = read_json(root / "research/results/public_datasets/dataset_tests.json")["primary_datasets"]
    unique(datasets, ["dataset"], "dataset")
    checks = read_csv(root / "research/results/related_tools/pasilla_fact_checks.csv")
    require(all(boolean(r["pass"]) and close(r["actual"], r["expected"]) for r in checks), "Pasilla reference mismatch")
    human = root / "research/results/human_evaluation"
    spec = read_json(human / "human_evaluation_manifest.json")
    experts = read_csv(human / "expert_dimension_summary.csv")
    users = read_csv(human / "user_feature_summary.csv")
    expert_overall = next(r for r in experts if r["dimension"] == "overall")
    user_overall = next(r for r in users if r["feature_id"] == "overall")
    dimensions = [r for r in experts if r["dimension"] != "overall"]
    features = [r for r in users if r["feature_id"] != "overall"]
    require(len(dimensions) == spec["expert_dimensions"] and len(features) == spec["student_features"], "Human dimensions mismatch")
    for rows, overall, field, total in [(dimensions, expert_overall, "mean", spec["expert_scores"]),
                                        (features, user_overall, "mean_score", spec["student_scores"])]:
        require(sum(int(r["n"]) for r in rows) == int(overall["n"]) == total, "Human aggregate count mismatch")
        require(abs(sum(float(r[field]) * int(r["n"]) for r in rows) / total - float(overall[field])) < 1e-6,
                "Human aggregate mean mismatch")
    require(spec["expert_scores"] == spec["expert_raters"] * spec["expert_cases"] * spec["expert_dimensions"], "Expert manifest count mismatch")
    require(spec["student_scores"] == spec["student_participants"] * spec["student_features"], "User manifest count mismatch")
    for field in ["useful_yes", "useful_no"]:
        require(sum(int(r[field]) for r in features) == int(user_overall[field]) == spec[f"student_{field}"], "User useful count mismatch")
    agreement = read_csv(human / "expert_agreement_summary.csv")[0]
    require(close(agreement["exact_agreement_percent"], spec["expert_exact_agreement_percent"]), "Agreement mismatch")
    return {"public_datasets": {"count": len(datasets), "statuses": {r["dataset"]: r["status"] for r in datasets},
                                "scope": "saved object ingestion tests, not rerun"},
            "pasilla": {"checks": len(checks), "passed": sum(boolean(r["pass"]) for r in checks)},
            "human_evaluation": {"expert_scores": spec["expert_scores"], "user_scores": spec["student_scores"],
                                 "expert_mean": float(expert_overall["mean"]), "user_mean": float(user_overall["mean_score"]),
                                 "status": "aggregate_consistency_only", "raw_ratings": "unavailable_in_project",
                                 "note": "No independent recomputation of SD, agreement or individual scores"}}


def paper(root):
    base = root / "docs/submission_assets"
    rows = read_csv(base / "supplementary_manifest.csv")
    unique(rows, ["path"], "supplementary archive")
    with zipfile.ZipFile(base / "supplementary_records.zip") as archive:
        require(set(archive.namelist()) == {r["path"] for r in rows} and len(archive.namelist()) == len(rows),
                "Supplementary ZIP membership mismatch")
        for row in rows:
            value = archive.read(row["path"])
            require(len(value) == int(row["bytes"]) and hashlib.sha256(value).hexdigest() == row["sha256"],
                    f"Supplementary ZIP hash mismatch: {row['path']}")
    audit = read_json(root / "research/results/submission-audit.json")
    require(audit["status"] == "pass" and audit["bundle_records"] == len(rows), "Saved submission audit mismatch")
    return {"supplementary_records": len(rows), "figure_pdfs": len(list(base.glob("Figure*.pdf"))),
            "references": audit["references"], "saved_audit_status": audit["status"],
            "geometry_audit_rerun": False}


def audit(root, manifest_path):
    manifest = read_json(manifest_path)
    counts = {}
    for name, group in manifest["groups"].items():
        counts[name] = verify_inventory(root, group["inventory"])
        require(counts[name] == group["file_count"], f"Inventory count mismatch: {name}")
    for name, item in {"source": manifest["source"]["inventory"],
                       "package_source": manifest["source"]["package_inventory"],
                       "documentation": manifest["documentation"], "baseline": manifest["baseline_artifacts"],
                       "original": manifest["original_record_inventory"]}.items():
        counts[name] = verify_inventory(root, item)
    verify_file(root, manifest["environment"])
    verify_file(root, manifest["source"]["archive"])
    if "continuation_environment" in manifest:
        verify_file(root, manifest["continuation_environment"])
    if "review_environment" in manifest:
        verify_file(root, manifest["review_environment"])
    delivery = manifest.get("delivery_bundle", {})
    if delivery.get("status") == "development_delivery_verified":
        verify_file(root, delivery["inspection"])
        inspection = read_json(resolve(root, delivery["inspection"]["path"]))
        require(inspection["status"] == "pass", "Delivery audit did not pass")
        verify_file(root, inspection["archive"])
        with zipfile.ZipFile(resolve(root, inspection["archive"]["path"])) as archive:
            rows = inspection["member_manifest"]
            require(set(archive.namelist()) == {r["path"] for r in rows} | {"delivery_manifest.json"}, "Delivery membership mismatch")
            for row in rows:
                verify_file(root, row)
                require(hashlib.sha256(archive.read(row["path"])).hexdigest() == row["sha256"], "Delivery member hash mismatch")
    for key, inventory in [("code_hash", "inventory"), ("package_code_hash", "package_inventory")]:
        rows = read_csv(resolve(root, manifest["source"][inventory]["path"]))
        for row in rows:
            row["bytes"] = int(row["bytes"])
        value = hashlib.sha256(json.dumps(rows, sort_keys=True, separators=(",", ":")).encode()).hexdigest()
        require(value == manifest["source"][key], f"Source content hash mismatch: {key}")
    result = {"status": "pass", "mode": "current", "audited_utc": datetime.now(timezone.utc).isoformat(),
              "manifest_sha256": hashlib.sha256(manifest_path.read_bytes()).hexdigest(),
              "verified_file_counts": counts, "main_experiment": main_experiment(root),
              "common_task": common_task(root), "supporting": supporting_results(root), "paper": paper(root)}
    require(manifest["saved_result_summary"] == {key: result[key] for key in
            ["main_experiment", "common_task", "supporting", "paper"]}, "Current manifest summary differs from saved results")
    checks = manifest.get("checks", {})
    def recorded_log(name, fallback):
        entry = checks.get(name, {})
        path = entry.get("log", {}).get("path") if isinstance(entry, dict) else None
        return (resolve(root, path).read_text() if path and resolve(root, path).is_file()
                else (root / fallback).read_text())
    records = manifest.get("software_check_records", {})
    source_log = recorded_log(records.get("source", "w13-source-check"), "research/results/w00_baseline/source-check.txt")
    check_log = recorded_log(records.get("package", "w13-package-check"), "research/results/w00_baseline/package-check.txt")
    require("Status: OK" in check_log, "Restored-environment package check not OK")
    totals = re.search(r"nb\s+failed\s+skipped\s+error\s+warning\s+passed\s+([\d\s]+)", source_log)
    require(totals is not None, "Source test totals missing")
    numbers = [int(n) for n in totals[1].split()]
    require(len(numbers) == 6 and numbers[1] == numbers[3] == numbers[4] == 0, "Source check failed or warned")
    with tarfile.open(resolve(root, manifest["source"]["archive"]["path"])) as archive:
        for row in read_csv(resolve(root, manifest["source"]["package_inventory"]["path"])):
            if row["path"] == "DESCRIPTION":
                continue  # R CMD build appends Packaged metadata to DESCRIPTION.
            value = archive.extractfile(f"BioExplainR/{row['path']}").read()
            require(hashlib.sha256(value).hexdigest() == row["sha256"], f"Source archive mismatch: {row['path']}")
    result["software"] = {"package_check": "Status: OK",
                          "source_totals": dict(zip(["nb", "failed", "skipped", "error", "warning", "passed"], numbers)),
                          "source_archive": "matches indexed package files (build metadata excluded)",
                           "git_commit": manifest["git"]["commit_sha"]}
    if "miniacc_development" in manifest["groups"]:
        from multiomics.audit_miniacc import audit as audit_miniacc
        result["miniacc_development"] = {}
        for name in manifest["groups"]["miniacc_development"]["entrypoints"]:
            base = root / name
            require(not Path(name).is_absolute() and base.resolve().is_relative_to(root.resolve()) and base.is_dir(),
                    f"Run path is not a project-relative directory: {name}")
            result["miniacc_development"][name] = audit_miniacc(base)
    if "paper_cn" in manifest:
        verify_file(root, manifest["paper_cn"]["audit"])
        chinese = read_json(resolve(root, manifest["paper_cn"]["audit"]["path"]))
        revision = manifest["paper_cn"].get("version") == "v0.9"
        require(chinese["status"] == "pass" and chinese["figures"] == (2 if revision else 8)
                and chinese["docx_tables"] == (1 if revision else 0), "Chinese manuscript audit did not pass")
        cases = read_csv(root / "research/results/paper_cn_cases_v1/scenario_checks.csv")
        require(len(cases) == 15 and all(r["expected"] == r["actual"] for r in cases), "Chinese paper scenarios mismatch")
        keys = (["status", "references", "figures", "external_tables", "docx_tables", "pdf_pages", "supplement",
                 "comparison_tools", "body_reduction_percent", "discovery"] if revision else
                ["status", "references", "figures", "panel_pdfs", "composite_pdfs", "external_tables",
                 "docx_tables", "pdf_pages", "airway_independent_numeric_rechecks", "development_scenarios"])
        result["paper_cn"] = {key: chinese[key] for key in keys}
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=ROOT)
    parser.add_argument("--manifest", default="research/results/current_manifest.json")
    parser.add_argument("--output", type=Path)
    options = parser.parse_args()
    try:
        result = audit(options.root, resolve(options.root, options.manifest))
    except (ValueError, KeyError, StopIteration, OSError, json.JSONDecodeError, zipfile.BadZipFile) as error:
        result = {"status": "fail", "mode": "current", "error": str(error)}
    if options.output:
        options.output.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0 if result["status"] == "pass" else 1


if __name__ == "__main__":
    sys.exit(main())
