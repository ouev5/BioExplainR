"""Verify the concise manuscript, supplement, comparison table and discovery provenance."""
import argparse
import csv
import hashlib
import json
from pathlib import Path
import re
import sys

import fitz
from docx import Document
from docx.oxml.ns import qn
from openpyxl import load_workbook

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "docs/paper_cn_v2"
VERSION = "v0.9"
VERSION_REFERENCES = {"v0.9": 30, "v0.9.1": 30, "v0.10": 32}
MAIN_FIGURES = {"v0.9": 2, "v0.9.1": 2, "v0.10": 3}
SUPPLEMENT_TABLES = {"v0.9": 10, "v0.9.1": 10, "v0.10": 13}
sys.path.insert(0, str(ROOT / "research"))
sys.path.insert(0, str(ROOT / "research/discovery"))
from paper_cn.audit_manuscript import geometry
from audit_saved import audit as discovery_audit


def read_rows(path):
    with path.open(encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))


def main():
    global OUT, VERSION
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--directory", type=Path, default=OUT)
    parser.add_argument("--version", default=VERSION)
    args = parser.parse_args()
    OUT = args.directory.resolve(); VERSION = args.version
    manifest = json.loads((OUT / "assets_manifest.json").read_text())
    for row in manifest["files"]:
        p = ROOT / row["path"]
        assert len(p.read_bytes()) == row["bytes"] and hashlib.sha256(p.read_bytes()).hexdigest() == row["sha256"]
    text = (OUT / "manuscript_expanded.md").read_text()
    body, refs = text.split("# 参考文献\n", 1)
    references = re.findall(r"^(\d+)\. ", refs, re.M)
    assert references == [str(n) for n in range(1, VERSION_REFERENCES[VERSION]+1)]
    cited = set()
    for expression in re.findall(r"\[([\d,，–—\- ]+)\]", body):
        for part in re.split(r"[,，]", expression):
            limits = re.split(r"[–—\-]", part.strip())
            cited.update(range(int(limits[0]), int(limits[-1])+1))
    assert cited == set(range(1, VERSION_REFERENCES[VERSION]+1))
    assert "1.1.1" not in text and "CRISPR2" not in text and "CRISPLD2" in text
    comparison = json.loads((Path(__file__).parent / "tool_comparison.json").read_text())
    expected = [comparison["headers"]] + comparison["rows"]
    with (OUT / "tables/Table_1.csv").open(encoding="utf-8-sig") as f: assert list(csv.reader(f)) == expected
    doc = Document(OUT / f"BioExplainR-中文论文-{VERSION}.docx")
    assert len(doc.tables) == 1 and len(doc.inline_shapes) == MAIN_FIGURES[VERSION]
    assert [[cell.text for cell in row.cells] for row in doc.tables[0].rows] == expected
    narrative = "\n".join(p.text for p in doc.paragraphs).split("参考文献", 1)[0]
    linked = []
    links_path = OUT / "figure_table_links.json"
    if links_path.exists():
        links = json.loads(links_path.read_text())
        assert links["version"] == VERSION
        expected_ids = {"图 1", "表 1"} | {f"图 {n}" for n in range(2, MAIN_FIGURES[VERSION]+1)} \
            | {f"补充图 S{n}" for n in range(1, 9)} | {f"补充表 S{n}" for n in range(1, SUPPLEMENT_TABLES[VERSION]+1)}
        assert len(links["entries"]) == len(expected_ids)
        assert {r["id"] for r in links["entries"]} == expected_ids
        paragraphs = body.split("\n\n")
        for entry in links["entries"]:
            paragraph = next(p for p in paragraphs if entry["paragraph_anchor"] in p)
            assert entry["citation"] in paragraph
            assert entry["paragraph_anchor"] in narrative and entry["citation"] in narrative
            assert all(entry[k] for k in ["introduction", "result_or_design", "interpretation"])
            linked.append({"id": entry["id"], "section": entry["section"], "status": "pass"})
        supplement_text = (OUT / "supplementary.md").read_text()
        assert not re.search(r"(?<!补充)表\s+[1-9]", supplement_text), "Stale main-table references in supplement"
    headings = [p.text for p in doc.paragraphs if p.style.name.startswith("Heading")]
    assert len(headings) == len(set(headings)) and not any(re.match(r"^(\d\.){3}", h) for h in headings)
    for style in doc.styles:
        if style.name.startswith("Heading"):
            assert style.element.find(".//" + qn("w:numId")).get(qn("w:val")) == "0"
    for name in ["Table_1"] + [f"Table_S{n}" for n in range(1, SUPPLEMENT_TABLES[VERSION]+1)]:
        with (OUT / f"tables/{name}.csv").open(encoding="utf-8-sig") as f: data = list(csv.reader(f))
        book = load_workbook(OUT / f"tables/{name}.xlsx", read_only=True, data_only=True)
        xlsx = list(book.worksheets[0].values)
        assert len(data) == len(xlsx)
        for a, b in zip(data, xlsx):
            for v, w in zip(a, b):
                if isinstance(w, (float, int)):
                    assert abs(float(v)-w) <= max(1e-14, abs(w)*1e-12)
                else: assert v == ("" if w is None else w)
        book.close()
    reports = json.loads((OUT / "export_report.json").read_text())
    pdfs = {}
    for key, count, shapes in [("main", 1, MAIN_FIGURES[VERSION]), ("supplement", 0, 8)]:
        report = reports[key]; name = report["name"]
        document = Document(OUT / f"{name}.docx")
        assert len(document.tables) == count and len(document.inline_shapes) == shapes
        with fitz.open(OUT / f"{name}.pdf") as pdf:
            content = "\n".join(p.get_text() for p in pdf)
            assert len(pdf) == report["pages"] and "CRISPR2" not in content and "1.1.1" not in content
            if key == "main" and linked:
                main_pdf_body = re.sub(r"\s", "", content.split("参考文献", 1)[0])
                for entry in links["entries"]:
                    assert re.sub(r"\s", "", entry["citation"]) in main_pdf_body, entry["id"]
            for row in report["vector_figures"]:
                assert len(pdf[row["page"]-1].get_drawings()) > 0
            for page in pdf:
                for block in page.get_text("dict")["blocks"]:
                    for line in block.get("lines", []):
                        for span in line["spans"]:
                            assert page.rect.contains(fitz.Rect(span["bbox"])), (name, page.number+1, span["text"])
            pdfs[key] = {"pages": len(pdf), "tables": count, "figures": shapes}
    compression = json.loads((OUT / "compression.json").read_text())
    assert compression["core_contributions"] == 4 and compression["current_body"] < compression["v0_8_body"] * .6
    discovery = discovery_audit()
    # Sensitive magnitudes are read from the saved results, not inferred from plot labels.
    result = json.loads((ROOT / "research/results/discovery_sparcl1_v1/summary.json").read_text())["results"][0]
    assert f"{result['effect']:.3f}" in body and "单一细胞系" in body and "DOI 尚未建立" in body
    figures = [geometry(OUT / "figures/Figure_2.pdf")]
    biology = None
    if VERSION == "v0.10":
        figures.append(geometry(OUT / "figures/Figure_3.pdf"))
        ledger = json.loads((ROOT / "research/results/discovery_context_v1/scientific_ledger.json").read_text())
        assert ledger["status"] == "pass" and ledger["candidate_interactions_supported"] == 0
        context = read_rows(ROOT / "research/results/discovery_context_v1/model_results.csv")
        donors = read_rows(ROOT / "research/results/discovery_donors_v1/results.csv")
        interactions = [r for r in context if r["symbol"] == "SPARCL1" and r["holm_candidate_interactions"]]
        assert len(interactions) == 3 and min(float(r["holm_candidate_interactions"]) for r in interactions) >= .05
        assert [(int(r["positive_donors"]), round(float(r["effect"]), 3)) for r in donors[:2]] == [(7, 3.514), (9, 3.598)]
        assert (round(float(donors[2]["effect"]), 3), round(float(donors[2]["holm_three_tests"]), 3)) == (0.084, 0.859)
        # Report only saved magnitudes; assert prose matches the audited values.
        assert f"{float(donors[2]['effect']):.3f}" in body and f"{float(interactions[0]['holm_candidate_interactions']):.3f}" in body
        assert "不主张首次发现" in body and "3.89×10⁻⁴" in body and "16供体全部上调" in body
        for panel in ["图 3A", "图 3B", "图 3C", "图 3D"]:
            assert panel in body, panel
        biology = {"paired_donors": 16, "positive_donors": 16, "candidate_interactions_tested": 3,
                   "candidate_interactions_supported": 0, "asthma_response_difference_supported": False,
                   "shared_culture_cell_lines": ledger["named_donor_overlap_between_followups"],
                   "novelty": ledger["novelty"]}
    audit = {"status": "pass", "references": VERSION_REFERENCES[VERSION], "figures": MAIN_FIGURES[VERSION],
             "docx_tables": 1, "external_tables": 1+SUPPLEMENT_TABLES[VERSION],
             "pdf_pages": pdfs["main"]["pages"], "supplement": pdfs["supplement"],
             "comparison_tools": 6, "body_reduction_percent": round(100*(1-compression["current_body"]/compression["v0_8_body"]), 2),
             "discovery": discovery, "geometry": figures, "candidate_followup": biology,
             "figure_table_narrative_links": linked,
             "heading_numbering": "disabled inherited Word numbering; literal numbers only",
             "visual_scope": "Automated PDF text bounds/figure geometry and document content, not independent human review"}
    (OUT / "audit.json").write_text(json.dumps(audit, ensure_ascii=False, indent=2)+"\n")
    print(json.dumps(audit, ensure_ascii=False, indent=2))


if __name__ == "__main__": main()
