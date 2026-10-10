"""Summarize anonymized expert and student rating workbooks.

The source files are supplied at run time and are not copied into the project.
Only aggregate scores, counts, and agreement summaries are written.
"""
import argparse
import csv
import io
import json
import statistics
import zipfile
from collections import defaultdict
from pathlib import Path

from openpyxl import load_workbook


def write_csv(path, rows, fields):
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields)
        writer.writeheader()
        writer.writerows(rows)


def mean_sd(values):
    return statistics.mean(values), statistics.stdev(values) if len(values) > 1 else 0.0


def read_user(path):
    workbook = load_workbook(io.BytesIO(Path(path).read_bytes()), data_only=True)
    sheet = workbook["Feature_Ratings"]
    headers = [cell.value for cell in sheet[1]]
    return [dict(zip(headers, row)) for row in sheet.iter_rows(min_row=2, values_only=True)]


def read_experts(path):
    rows = []
    with zipfile.ZipFile(path) as archive:
        names = sorted(name for name in archive.namelist() if name.endswith(".xlsx"))
        for name in names:
            workbook = load_workbook(io.BytesIO(archive.read(name)), data_only=True)
            sheet = workbook["Ratings"]
            headers = [cell.value for cell in sheet[1]]
            rows.extend(dict(zip(headers, row)) for row in sheet.iter_rows(min_row=2, values_only=True))
    return rows


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--user-workbook", required=True)
    parser.add_argument("--expert-archive", required=True)
    parser.add_argument("--output-dir", required=True)
    args = parser.parse_args()
    output = Path(args.output_dir)
    users = read_user(args.user_workbook)
    experts = read_experts(args.expert_archive)
    assert len(users) == 150 and len(set(row["student_id"] for row in users)) == 30
    assert len(experts) == 720 and len(set(row["rater_id"] for row in experts)) == 3
    assert all(row["score_0_to_100"] is not None and row["useful_1_yes_2_no"] in (1, 2) for row in users)
    assert all(row["score_0_to_2"] in (1, 2) for row in experts)

    expert_rows = []
    for dimension in sorted(set(row["dimension"] for row in experts)):
        values = [row["score_0_to_2"] for row in experts if row["dimension"] == dimension]
        mean, sd = mean_sd(values)
        expert_rows.append({"dimension": dimension, "n": len(values), "mean": round(mean, 6),
                            "sd": round(sd, 6), "min": min(values), "max": max(values)})
    overall_mean, overall_sd = mean_sd([row["score_0_to_2"] for row in experts])
    expert_rows.append({"dimension": "overall", "n": len(experts), "mean": round(overall_mean, 6),
                        "sd": round(overall_sd, 6), "min": min(row["score_0_to_2"] for row in experts),
                        "max": max(row["score_0_to_2"] for row in experts)})
    write_csv(output / "expert_dimension_summary.csv", expert_rows,
              ["dimension", "n", "mean", "sd", "min", "max"])

    user_rows = []
    for feature_id in sorted(set(row["feature_id"] for row in users)):
        selected = [row for row in users if row["feature_id"] == feature_id]
        scores = [row["score_0_to_100"] for row in selected]
        useful = sum(row["useful_1_yes_2_no"] == 1 for row in selected)
        mean, sd = mean_sd(scores)
        user_rows.append({"feature_id": feature_id, "feature": selected[0]["feature"], "n": len(scores),
                          "mean_score": round(mean, 6), "sd_score": round(sd, 6), "min_score": min(scores),
                          "max_score": max(scores), "useful_yes": useful, "useful_no": len(scores) - useful,
                          "useful_percent": round(100 * useful / len(scores), 6)})
    scores = [row["score_0_to_100"] for row in users]
    useful = sum(row["useful_1_yes_2_no"] == 1 for row in users)
    mean, sd = mean_sd(scores)
    user_rows.append({"feature_id": "overall", "feature": "全部功能", "n": len(scores),
                      "mean_score": round(mean, 6), "sd_score": round(sd, 6), "min_score": min(scores),
                      "max_score": max(scores), "useful_yes": useful, "useful_no": len(scores) - useful,
                      "useful_percent": round(100 * useful / len(scores), 6)})
    write_csv(output / "user_feature_summary.csv", user_rows,
              ["feature_id", "feature", "n", "mean_score", "sd_score", "min_score", "max_score",
               "useful_yes", "useful_no", "useful_percent"])

    cell_values = defaultdict(dict)
    for row in experts:
        cell_values[(row["case_id"], row["dimension"])][row["rater_id"]] = row["score_0_to_2"]
    exact = sum(len(set(values.values())) == 1 for values in cell_values.values())
    within_one = sum(max(values.values()) - min(values.values()) <= 1 for values in cell_values.values())
    agreement = [{"unit": "case_dimension", "n": len(cell_values),
                  "exact_agreement_percent": round(100 * exact / len(cell_values), 6),
                  "within_one_point_percent": round(100 * within_one / len(cell_values), 6)}]
    write_csv(output / "expert_agreement_summary.csv", agreement,
              ["unit", "n", "exact_agreement_percent", "within_one_point_percent"])

    manifest = {
        "expert_raters": 3,
        "expert_cases": 30,
        "expert_dimensions": 8,
        "expert_scores": len(experts),
        "student_participants": 30,
        "student_features": 5,
        "student_scores": len(users),
        "student_useful_yes": useful,
        "student_useful_no": len(users) - useful,
        "expert_exact_agreement_percent": round(100 * exact / len(cell_values), 6),
        "expert_within_one_point_percent": round(100 * within_one / len(cell_values), 6),
        "source_note": "Aggregated from evaluator-uploaded workbooks; individual source files and comments are not copied into the project.",
    }
    output.mkdir(parents=True, exist_ok=True)
    (output / "human_evaluation_manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(manifest, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
