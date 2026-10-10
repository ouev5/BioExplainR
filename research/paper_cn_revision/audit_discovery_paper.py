"""Validate v0.11 tables, source dependencies, scientific numbers and export geometry."""
import ast
import csv
import hashlib
import json
import re
import sys
import zipfile
from datetime import datetime, timezone
from pathlib import Path

import fitz
import numpy as np
from docx import Document
from openpyxl import load_workbook
from scipy import stats

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "research/results/discovery_stable_response_v1"
PAPER = ROOT / "docs/paper_cn_v5"
OLD_MANIFEST = ROOT / "docs/biology_discovery_v2/discovery_manifest.json"


def rows(path):
    with path.open(encoding="utf-8-sig", newline="") as stream:
        return list(csv.DictReader(stream))


def record(path):
    h = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            h.update(chunk)
    return {"path": path.relative_to(ROOT).as_posix(), "bytes": path.stat().st_size, "sha256": h.hexdigest()}


def verify_sources():
    manifest = json.loads(OLD_MANIFEST.read_text())
    n = 0
    for group in ["analysis_files", "original_inputs", "package_source"]:
        for expected in manifest[group]:
            actual_path = PAPER / "evidence/rgo_before_v011.md" if expected["path"] == "rgo.md" else ROOT / expected["path"]
            actual = record(actual_path)
            assert (actual["bytes"], actual["sha256"]) == (expected["bytes"], expected["sha256"]), expected["path"]
            n += 1
    assert record(ROOT / manifest["archive"]["path"]) == manifest["archive"]
    with zipfile.ZipFile(ROOT / manifest["archive"]["path"]) as archive:
        expected = {r["path"]: r for r in manifest["archive_members"]}
        assert len(archive.namelist()) == len(set(archive.namelist())) == len(expected)
        assert set(archive.namelist()) == set(expected) and archive.testzip() is None
        for path, entry in expected.items():
            data = archive.read(path)
            assert len(data) == entry["bytes"] and hashlib.sha256(data).hexdigest() == entry["sha256"]
    return {"status": "pass", "records": n, "archive_members": len(expected), "manifest": record(OLD_MANIFEST),
            "handoff_substitution": "Only rgo.md verified against exact pre-v0.11 snapshot; scientific inputs/scripts remain at original paths"}


def holm(values):
    p = np.asarray(values)
    order = np.argsort(p)
    adjusted = np.minimum(1, np.maximum.accumulate(p[order] * np.arange(len(p), 0, -1)))
    result = np.empty(len(p)); result[order] = adjusted
    return result


def audit():
    sources = verify_sources()
    assets = json.loads((PAPER / "assets_manifest.json").read_text())
    for entry in assets["files"]:
        assert record(ROOT / entry["path"]) == entry, entry["path"]
    for entry in assets["figures"]:
        assert entry["new"]["sha256"] == entry["source"]["sha256"]
    for entry in assets["supplementary_tables"]:
        original = rows(ROOT / entry["source"]["path"])
        if entry["filtered"]:
            original = [r for r in original if r["priority_pass"] == "TRUE"]
        assert rows(PAPER / f'tables/Table_{entry["label"]}.csv') == original, entry["label"]
    spreadsheets = 0
    for path in (PAPER / "tables").glob("Table_*.xlsx"):
        data = rows(path.with_suffix(".csv"))
        workbook = load_workbook(path, data_only=True)
        values = list(workbook["Data"].values)
        assert list(values[0]) == list(data[0])
        assert [["" if v is None else str(v) for v in r] for r in values[1:]] == [list(r.values()) for r in data], path
        spreadsheets += 1

    external = rows(SOURCE / "external_results.csv")
    assert len(external) == 48 and sum(r["status"] == "estimable" for r in external) == 44
    for field, adjusted in [("pvalue", "holm_all_tests"), ("exact_p", "holm_exact_all_tests")]:
        assert np.allclose(holm([float(r[field]) for r in external]), [float(r[adjusted]) for r in external])
    effects = rows(SOURCE / "external_donor_effects.csv")
    assert len(effects) == 143
    measurable = [r for r in external if r["contrast"] == "all13_BUD_vs_vehicle" and r["status"] == "estimable"]
    for entry in measurable:
        values = [float(r["effect_pc1"]) for r in effects if r["feature_id"] == entry["feature_id"]]
        assert len(values) == 13
        assert np.isclose(np.mean(values), float(entry["effect"]))
        assert np.isclose(stats.ttest_1samp(values, 0).pvalue, float(entry["pvalue"]), rtol=1e-8, atol=1e-20)
        assert float(entry["holm_all_tests"]) < .05 and float(entry["holm_exact_all_tests"]) < .05
    summary = rows(SOURCE / "evidence_summary.csv")
    table2 = rows(PAPER / "tables/Table_2.csv")
    assert len(summary) == len(table2) == 12
    for original, display in zip(summary, table2):
        assert display["基因"] == original["symbol"]
        if original["external_effect"]:
            assert abs(float(display["13供体差"]) - float(original["external_effect"])) < .00051
            for field, key in [("t Holm P", "external_Holm"), ("精确Holm P", "external_exact_Holm")]:
                assert np.isclose(float(display[field]), float(original[key]), rtol=.006, atol=1e-18)
            low, high = display["95%CI"].split("至")
            assert abs(float(low) - float(original["external_ci_low"])) < .00051
            assert abs(float(high) - float(original["external_ci_high"])) < .00051
        else:
            assert display["13供体差"] == "不可估计" and display["t Holm P"] == "1（占位）"
    # Direct contrasts and original sample labels corroborate the exposure wording.
    temporal = rows(SOURCE / "direct_temporal_results.csv")
    assert len(temporal) == 24
    assert np.allclose(holm([float(r["pvalue"]) for r in temporal]), [float(r["holm_24_tests"]) for r in temporal])
    per2 = {r["study"]: r for r in temporal if r["symbol"] == "PER2"}
    assert round(float(per2["ASM"]["effect"]), 3) == -1.651 and round(float(per2["A549"]["effect"]), 3) == -.917
    sample_map = rows(ROOT / "research/results/discovery_mechanism_fit_v4/sample_map.csv")
    for group, required in [("pre_DMSO", ["16h DMSO", "2h DEX"]), ("post_DMSO", ["2h DEX", "16h DEX"])]:
        subset = [r for r in sample_map if r["group"] == group]
        assert len(subset) == 4 and all(all(word in r["treatment"] for word in required) for r in subset)
    main_text = (PAPER / "manuscript_expanded.md").read_text()
    body, refs_and_figures = main_text.split("# 参考文献", 1)
    cited = set()
    for match in re.findall(r"\[([\d,–\-]+)\]", body):
        for part in match.split(","):
            if "–" in part or "-" in part:
                start, end = re.split("[–-]", part); cited.update(range(int(start), int(end) + 1))
            else:
                cited.add(int(part))
    assert cited == set(range(1, 12)), cited
    assert len(re.findall(r"^\d+\. ", refs_and_figures.split("# 图表", 1)[0], re.M)) == 11
    required = ["109,636", "11/12", "点态", "非前瞻性注册", "总培养处理窗口均为 18 h", "不证明", "不可估计"]
    for word in required:
        assert word in main_text, word
    narrative = re.sub(r"\s", "", body)
    expected_links = ["图1", "图2", "图3", "表1", "表2", "补充图S1", "补充图S2"]
    expected_links += ["补充表S1", "补充表S1b"] + [f"补充表S{i}" for i in range(2, 13)]
    # Each historical table is cited explicitly in the methods paragraph.
    for label in ["S13a", "S13b", "S13c", "S13d"]:
        assert label in narrative
    for label in expected_links:
        assert label in narrative, label
    document_results = []
    exports = json.loads((PAPER / "export_report.json").read_text())
    for name, expected_tables, expected_images, part in [
        ("BioExplainR-中文论文-v0.11", 2, 3, "main"), ("BioExplainR-补充材料-v0.11", 4, 2, "supplement")]:
        doc = Document(PAPER / f"{name}.docx")
        assert len(doc.tables) == expected_tables and len(doc.inline_shapes) == expected_images
        if part == "main":
            for i, table in enumerate(doc.tables, 1):
                data = rows(PAPER / f"tables/Table_{i}.csv")
                assert [[c.text for c in r.cells] for r in table.rows] == [list(data[0])] + [list(r.values()) for r in data]
        else:
            filenames = ["F1_common_task", "F2_paired_bootstrap", "F3_receptor_control", "F4_chip_primary"]
            for table, filename in zip(doc.tables, filenames):
                data = rows(PAPER / f"tables/{filename}.csv")
                assert [[c.text for c in r.cells] for r in table.rows] == [list(data[0])] + [list(r.values()) for r in data]
        pdf = fitz.open(PAPER / f"{name}.pdf")
        assert len(pdf) == exports[part]["pages"]
        spans = 0
        for page in pdf:
            for block in page.get_text("dict")["blocks"]:
                for line in block.get("lines", []):
                    for span in line["spans"]:
                        spans += 1
                        assert (page.rect + (-1, -1, 1, 1)).contains(fitz.Rect(span["bbox"])), (name, page.number + 1, span["text"])
        pdf_text = "".join(page.get_text() for page in pdf)
        for word in ["PER2", "不可估计", "109,636"]:
            assert word in pdf_text
        for entry in exports[part]["vector_figures"]:
            page = pdf[entry["page"] - 1]
            # Matplotlib's heatmap PDF contains one raster field plus vector labels.
            # Verify preservation of the source PDF, rather than require zero images.
            with fitz.open(ROOT / entry["pdf"]["path"]) as original:
                assert len(page.get_drawings()) >= len(original[0].get_drawings()) > 0
                assert sorted(info["digest"] for info in page.get_image_info(hashes=True)) == sorted(
                    info["digest"] for info in original[0].get_image_info(hashes=True)), entry["caption"]
        document_results.append({"name": name, "pages": len(pdf), "tables": expected_tables,
                                 "figures": expected_images, "text_spans": spans, "vector_embedding": True})
        pdf.close()
    for script in ["build_discovery_paper.py", "audit_discovery_paper.py", "seal_discovery_paper.py"]:
        path = Path(__file__).parent / script
        if path.exists():
            ast.parse(path.read_text(), filename=str(path))
    for path in list(PAPER.glob("*.md")) + list(Path(__file__).parent.glob("*discovery_paper.py")):
        assert all(line == line.rstrip() for line in path.read_text().splitlines()), path
    result = {"status": "pass", "created_utc": datetime.now(timezone.utc).isoformat(), "source_dependencies": sources,
              "candidate_table_rows": 12, "external_measurable_candidates": 11, "frozen_denominator": 12,
              "external_tests": 48, "external_donor_effects": 143, "direct_exposure_tests": 24,
              "csv_xlsx_pairs": spreadsheets, "reference_count": 11, "figure_table_links": 24,
              "documents": document_results, "scope": "Saved source integrity, paired-test arithmetic, table data, references and PDF geometry; no new fitted analysis or human review"}
    if not (PAPER / "manuscript_manifest.json").exists():
        (PAPER / "audit.json").write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    if len(sys.argv) > 1:
        PAPER = Path(sys.argv[1]).resolve()
    audit()
