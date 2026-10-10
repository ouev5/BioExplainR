"""Recompute coverage, paired effects, BH adjustments and signs without R."""
import csv
import hashlib
import itertools
import json
import math
from pathlib import Path, PurePosixPath
import statistics
import sys


REQUIRED_FILES = {
    "alignment_summary.json", "clinical_groups.csv", "cohort_payload.json",
    "direction_findings.csv", "engineering_checks.csv", "facts.json",
    "feature_results.csv", "input_miniACC.rds", "modality_coverage.csv",
    "packages.csv", "paired_measurements.csv", "pairwise_coverage.csv", "project.rds",
    "PROTOCOL.md", "relations.csv", "report-en.html", "report-zh.html", "sample_map.csv",
    "sessionInfo.txt", "source_help.txt", "source_metadata.json", "source_package.txt", "summary.json",
}


def require(ok, message):
    if not ok:
        raise ValueError(message)


def audit(base):
    base = base.resolve()

    def rows(name, fields, key):
        with (base / name).open(newline="", encoding="utf-8") as handle:
            reader = csv.DictReader(handle)
            require(reader.fieldnames is not None and len(reader.fieldnames) == len(set(reader.fieldnames))
                    and set(fields) <= set(reader.fieldnames), f"Invalid columns: {name}")
            data = list(reader)
        require(all(None not in r and all(r[k] is not None for k in fields) for r in data),
                f"Malformed row: {name}")
        keys = [tuple(r[k] for k in key) for r in data]
        require(all(all(v for v in k) for k in keys) and len(keys) == len(set(keys)),
                f"Missing or duplicate key: {name}")
        return data

    manifest = json.loads((base / "manifest.json").read_text(encoding="utf-8"))
    require(manifest.get("status") == "pass", "Run manifest did not pass")
    modern = manifest.get("manifest_version") == "2.0"
    require(modern or "manifest_version" not in manifest, "Unsupported manifest version")
    require(not modern or manifest.get("path_base") == "run_directory", "Invalid path base")
    names, parents = [], set()
    for item in manifest["files"]:
        raw = item["path"]
        path = PurePosixPath(raw)
        require(isinstance(raw, str) and raw == path.as_posix() and "\\" not in raw
                and not path.is_absolute() and ".." not in path.parts, "Unsafe artifact path")
        require(not modern or len(path.parts) == 1, "Artifact must be run-relative")
        names.append(path.name)
        parents.add(path.parent)
        local = base / path.name
        require(not local.is_symlink() and local.is_file(), f"Missing or unsafe artifact: {path.name}")
        require(local.stat().st_size == item["bytes"], f"Size mismatch: {path.name}")
        require(hashlib.sha256(local.read_bytes()).hexdigest() == item["sha256"], f"Hash mismatch: {path.name}")
    # Legacy paths carry a single original directory prefix. Resolve by member name
    # inside the supplied run, so copied archives never read the original tree.
    require(len(parents) == 1 and len(names) == len(set(names)), "Duplicate or inconsistent manifest members")
    require(set(names) == REQUIRED_FILES, "Incomplete manifest membership")
    require({p.name for p in base.iterdir()} == REQUIRED_FILES | {"manifest.json"}, "Run membership mismatch")

    summary = json.loads((base / "summary.json").read_text(encoding="utf-8"))
    clinical = rows("clinical_groups.csv", ["biological_unit", "stage", "group"], ["biological_unit"])
    units = {r["biological_unit"] for r in clinical}
    require(len(units) == summary["n_primary_units"], "Primary units mismatch")
    for r in clinical:
        expected = "early" if r["stage"] in {"stage i", "stage ii"} else (
            "late" if r["stage"] in {"stage iii", "stage iv"} else "")
        require(r["group"] == expected, "Clinical stage/group mismatch")
    maps = rows("sample_map.csv", ["modality", "source_id", "biological_unit"], ["modality", "source_id"])
    present = {}
    for r in maps:
        require(r["biological_unit"] in units, "Mapped unit outside primary cohort")
        present.setdefault(r["modality"], set()).add(r["biological_unit"])
    require(len(present) == summary["n_modalities"], "Modality count mismatch")
    coverage = rows("modality_coverage.csv", ["modality", "n_units", "n_missing"], ["modality"])
    require({r["modality"] for r in coverage} == set(present), "Coverage membership mismatch")
    for r in coverage:
        n = len(present[r["modality"]])
        require(n == int(r["n_units"]) and len(units) - n == int(r["n_missing"]), "Coverage mismatch")
    pairs = rows("pairwise_coverage.csv", ["from", "to", "n_shared", "n_from_only", "n_to_only"], ["from", "to"])
    expected_pairs = {frozenset(pair) for pair in itertools.combinations(present, 2)}
    actual_pairs = [frozenset((r["from"], r["to"])) for r in pairs]
    require(len(actual_pairs) == len(expected_pairs) and set(actual_pairs) == expected_pairs,
            "Pair coverage membership mismatch")
    for r in pairs:
        a, b = present[r["from"]], present[r["to"]]
        require((len(a & b), len(a - b), len(b - a)) ==
                tuple(int(r[k]) for k in ["n_shared", "n_from_only", "n_to_only"]), "Pair coverage mismatch")
    complete = len(set.intersection(*present.values()))
    unmeasured = len(units - set.union(*present.values()))
    require(complete == summary["n_complete_all_modalities"], "Complete units mismatch")
    require(unmeasured == summary["n_unmeasured_units"], "Unmeasured units mismatch")
    alignment = json.loads((base / "alignment_summary.json").read_text(encoding="utf-8"))
    require(alignment["status"] == "pass" and
            (alignment["n_primary_units"], alignment["n_complete_units"], alignment["n_unmeasured_units"]) ==
            (len(units), complete, unmeasured), "Alignment summary mismatch")
    stage = {r["biological_unit"]: r["group"] for r in clinical}
    for modality in ["RNASeq2GeneNorm", "RPPAArray"]:
        rr = [r for r in maps if r["modality"] == modality]
        require(len(rr) == len({r["biological_unit"] for r in rr}), "Ambiguous paired mapping")
    paired = present["RNASeq2GeneNorm"] & present["RPPAArray"] & {u for u, g in stage.items() if g}
    require(len(paired) == summary["n_paired_known_stage"], "Paired cohort mismatch")
    for g in ["early", "late"]:
        require(sum(stage[u] == g for u in paired) == summary[f"n_{g}"], "Group count mismatch")
    measurements = rows("paired_measurements.csv", ["feature_id", "biological_unit", "group", "rna", "protein"],
                        ["feature_id", "biological_unit"])
    result_fields = ["feature_id", "n_early", "n_late", "n_excluded_nonfinite", "direction"] + [
        f"{m}_{k}" for m in ["rna", "protein"] for k in ["effect", "p", "padj"]]
    results = rows("feature_results.csv", result_fields, ["feature_id"])
    features = {r["feature_id"] for r in results}
    require(len(results) == summary["n_common_features"], "Feature count mismatch")
    require({(r["feature_id"], r["biological_unit"]) for r in measurements} ==
            set(itertools.product(features, paired)), "Measurement membership mismatch")
    signs = {"same": 0, "opposite": 0, "unverified": 0}
    effects_checked = 0
    for result in results:
        rr = [r for r in measurements if r["feature_id"] == result["feature_id"]]
        require(all(r["group"] == stage[r["biological_unit"]] for r in rr), "Group assignment mismatch")
        finite = [r for r in rr if r["rna"] and r["protein"] and
                  math.isfinite(float(r["rna"])) and math.isfinite(float(r["protein"]))]
        require(len(rr) - len(finite) == int(result["n_excluded_nonfinite"]), "Nonfinite exclusion mismatch")
        for g in ["early", "late"]:
            require(sum(r["group"] == g for r in finite) == int(result[f"n_{g}"]), "Feature denominator mismatch")
        effects = []
        for modality in ["rna", "protein"]:
            a = [float(r[modality]) for r in finite if r["group"] == "early"]
            b = [float(r[modality]) for r in finite if r["group"] == "late"]
            effect = statistics.mean(b) - statistics.mean(a) if a and b else math.nan
            saved = float(result[f"{modality}_effect"]) if result[f"{modality}_effect"] else math.nan
            require((math.isnan(effect) and math.isnan(saved)) or
                    math.isclose(effect, saved, rel_tol=1e-10, abs_tol=1e-12), "Effect mismatch")
            effects.append(effect)
            effects_checked += 1
        a, b = effects
        sign = "unverified" if not all(math.isfinite(v) and v != 0 for v in effects) else (
            "same" if (a > 0) == (b > 0) else "opposite")
        require(sign == result["direction"], "Direction mismatch")
        signs[sign] += 1
    require(signs == summary["direction"], "Direction summary mismatch")
    for modality in ["rna", "protein"]:
        valid = sorted((float(r[f"{modality}_p"]), i) for i, r in enumerate(results) if r[f"{modality}_p"])
        # R p.adjust defaults n to the full vector length, including missing entries.
        adjusted = {}
        current = 1.0
        for rank in range(len(valid), 0, -1):
            p, i = valid[rank - 1]
            require(math.isfinite(p) and 0 <= p <= 1, "Invalid p value")
            current = min(current, p * len(results) / rank)
            adjusted[i] = current
        for i, r in enumerate(results):
            require(bool(r[f"{modality}_padj"]) == (i in adjusted), "Missing BH mismatch")
            if i in adjusted:
                require(math.isclose(adjusted[i], float(r[f"{modality}_padj"]), rel_tol=1e-10, abs_tol=1e-12),
                        "BH mismatch")
        require(sum(v < .05 for v in adjusted.values()) == summary[f"{modality}_bh_below_005"],
                "BH summary mismatch")
    relations = rows("relations.csv", ["id", "from", "to", "from_fact", "to_fact", "feature_id", "expected"], ["id"])
    require(len(relations) == len(features) and {r["feature_id"] for r in relations} == features,
            "Relation membership mismatch")
    facts = json.loads((base / "facts.json").read_text(encoding="utf-8"))
    for modality in ["rna", "protein"]:
        require((facts[modality]["n_features"], facts[modality]["n_paired_units"],
                 facts[modality]["n_early"], facts[modality]["n_late"]) ==
                (len(features), len(paired), summary["n_early"], summary["n_late"]), "Fact denominator mismatch")
    findings = rows("direction_findings.csv", ["id", "check", "status", "detail"], ["id", "check"])
    checks_per_relation = {"scope_dataset_id", "scope_comparison_id", "scope_species", "scope_tissue",
                           "scope_sample_level", "orientation_numerator", "orientation_denominator",
                           "feature_identity", "direction"}
    require({(r["id"], r["check"]) for r in findings} ==
            set(itertools.product([r["id"] for r in relations], checks_per_relation)), "Findings membership mismatch")
    for relation in relations:
        require(relation["from"] == "rna" and relation["to"] == "protein" and
                relation["expected"] == "same", "Unexpected development relation")
        feature = next(r for r in results if r["feature_id"] == relation["feature_id"])
        for modality, field in [("rna", "from_fact"), ("protein", "to_fact")]:
            expected_value = float(feature[f"{modality}_effect"]) if feature[f"{modality}_effect"] else None
            saved_value = facts[modality].get(relation[field])
            require((saved_value is None and expected_value is None) or
                    (isinstance(saved_value, (int, float)) and expected_value is not None and
                     math.isclose(saved_value, expected_value, rel_tol=1e-10, abs_tol=1e-12)), "Relation fact mismatch")
        expected = "unverified" if feature["direction"] == "unverified" else (
            "pass" if feature["direction"] == relation["expected"] else "fail")
        for finding in [r for r in findings if r["id"] == relation["id"]]:
            require(finding["status"] == (expected if finding["check"] == "direction" else "pass"),
                    "Direction findings mismatch")
    checks = rows("engineering_checks.csv", ["case", "expected", "actual"], ["case"])
    expected_checks = {"observed_sample_map": "pass", "observed_direction": "pass",
                       "injected_wrong_direction": "fail", "injected_reversed_comparison": "fail",
                       "injected_missing_scope": "unverified", "injected_wrong_feature": "fail"}
    require({r["case"] for r in checks} == set(expected_checks) and len(checks) == summary["engineering_checks"],
            "Engineering check membership mismatch")
    require(all(r["actual"] == r["expected"] == expected_checks[r["case"]] for r in checks), "Engineering check mismatch")
    return {"status": "pass", "scope": "Independent Python recomputation; same development data, no expert gold",
            "files_verified": len(manifest["files"]), "effects_recomputed": effects_checked,
            "features": len(results), "paired_units": len(paired), "direction": signs,
            "artifact_paths": "run-relative; legacy directory prefixes supported without original-tree access",
            "pvalue_scope": "BH recomputed from saved R Wilcoxon p values; Wilcoxon statistic not independently recomputed"}


if __name__ == "__main__":
    print(json.dumps(audit(Path(sys.argv[1])), indent=2))
