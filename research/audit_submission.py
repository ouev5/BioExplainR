"""Check deliverable structure, quantitative consistency and document geometry."""
import argparse
import csv
import hashlib
import json
from pathlib import Path
import re
import zipfile

from docx import Document
from openpyxl import load_workbook
import pymupdf
from PIL import Image, ImageStat

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs/submission_assets"


def cell_text(value):
    return "" if value is None else str(value)


def pdf_geometry(path):
    pages = []
    with pymupdf.open(path) as pdf:
        for index, page in enumerate(pdf):
            lines = []
            outside = []
            for block in page.get_text("dict")["blocks"]:
                for line in block.get("lines", []):
                    text = "".join(span["text"] for span in line["spans"])
                    lines.append(text)
                    x0, y0, x1, y1 = line["bbox"]
                    if x0 < -1 or y0 < -1 or x1 > page.rect.width+1 or y1 > page.rect.height+1:
                        outside.append(text)
            pixmap = page.get_pixmap(matrix=pymupdf.Matrix(.4, .4), alpha=False)
            image = Image.frombytes("RGB", (pixmap.width, pixmap.height), pixmap.samples)
            extrema = ImageStat.Stat(image).extrema
            assert any(low < 230 for low, high in extrema), f"Blank page: {path}:{index+1}"
            assert not outside, f"Text outside PDF page: {path}:{index+1}: {outside}"
            pages.append({"page": index+1, "width": round(page.rect.width, 2), "height": round(page.rect.height, 2),
                          "lines": len(lines), "images": len(page.get_image_info()),
                          "first_text": lines[:2], "last_text": lines[-2:], "outside_text": outside})
    return pages


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=ROOT / "research/results/submission-audit.json")
    args = parser.parse_args()
    document = Document(ROOT / "docs/BioExplainR-paper-draft.docx")
    text = "\n".join(paragraph.text for paragraph in document.paragraphs)
    body = text.split("附录 A：")[0]
    for number in range(1, 5):
        assert f"图 {number}" in body
        assert f"图 {number}." in text
    for number in range(2, 9):
        assert f"表 {number}" in body
    assert "表 1" in body and "表 1a" not in body and "表 1b" not in body
    assert "补充图 S1" in body and "补充表 S1" in body
    assert "P_adj" not in text, "Expected typeset adjusted P-value notation"
    assert "自由文本" in body and "lfcShrink()" in body
    assert len(document.inline_shapes) == 7
    assert len(document.tables) == 13
    assert len(document.sections) == 5
    reference_section = text.split("参考文献", 1)[1].split("附录 A：", 1)[0]
    # Pandoc stores numeric reference labels separately, so count paragraph entries.
    reference_paragraphs = [p for p in document.paragraphs if "doi:" in p.text or "[软件文档]" in p.text or "[公开数据集]" in p.text or "[服务文档]" in p.text or "1802.03426" in p.text]
    assert len(reference_paragraphs) == 38, len(reference_paragraphs)
    assert len(re.findall(r"^\d+\. ", (ROOT / "docs/PAPER_DRAFT.md").read_text(encoding="utf-8"), re.MULTILINE)) == 38

    specs = json.loads((OUT / "tables_rendered.json").read_text(encoding="utf-8"))["tables"]
    table_audit = []
    for table, spec in zip(document.tables, specs):
        expected = [spec["headers"]] + [[str(value) for value in row] for row in spec["rows"]]
        actual = [[cell.text for cell in row.cells] for row in table.rows]
        assert expected == actual
        workbook = load_workbook(OUT / spec["file"], data_only=True)
        excel = [[cell_text(value) for value in row] for row in workbook["Display"].values]
        assert expected == excel
        assert workbook["Caption_Notes"]["B2"].value == spec["title"]
        assert workbook["Caption_Notes"]["B3"].value == spec["note"]
        table_audit.append({"id": spec["id"], "rows": len(spec["rows"]), "word_excel_identical": True})

    # No inline tables or images should precede the appendix heading.
    appendix_found = False
    for element in document.element.body:
        combined = "".join(element.itertext())
        if "附录 A：正文引用图表" in combined:
            appendix_found = True
        if element.tag.endswith("}tbl") or list(element.iter("{http://schemas.openxmlformats.org/wordprocessingml/2006/main}drawing")):
            assert appendix_found

    figures = []
    for path in sorted(OUT.glob("Figure*.pdf")):
        pages = pdf_geometry(path)
        assert len(pages) == 1
        with pymupdf.open(path) as pdf:
            fonts = pdf[0].get_fonts()
            if path.name not in {"Figure_S1A_workbench.pdf", "Figure_S1B_workbench.pdf"}:
                assert len(pdf[0].get_text()) > 40
                assert fonts and all(pdf.extract_font(font[0])[3] for font in fonts)
        figures.append({"file": path.name, "pages": pages, "fonts_embedded": bool(fonts)})

    bundle = OUT / "supplementary_records.zip"
    with (OUT / "supplementary_manifest.csv").open(encoding="utf-8", newline="") as handle:
        manifest = list(csv.DictReader(handle))
    with zipfile.ZipFile(bundle) as archive:
        assert set(archive.namelist()) == {record["path"] for record in manifest}
        for record in manifest:
            content = archive.read(record["path"])
            assert len(content) == int(record["bytes"])
            assert hashlib.sha256(content).hexdigest() == record["sha256"]
        assert sum(name.startswith("research/results/model/") for name in archive.namelist()) == 108
        assert sum(name.startswith("research/results/pilot_precision/model/") for name in archive.namelist()) == 108
        assert sum(name.startswith("research/results/main_scale_480/model/") and not name.endswith("__prompt.json") for name in archive.namelist()) == 1080
        assert sum(name.startswith("research/results/main_scale_480/model/") and name.endswith("__prompt.json") for name in archive.namelist()) == 1080

    main_pdf = pdf_geometry(ROOT / "docs/BioExplainR-paper-draft.pdf")
    supplementary_pdf = pdf_geometry(ROOT / "docs/BioExplainR-supplementary.pdf")
    supplementary = Document(ROOT / "docs/BioExplainR-supplementary.docx")
    supplementary_specs = json.loads((ROOT / "docs/submission_assets/supplementary_tables_rendered.json").read_text(encoding="utf-8"))["tables"]
    assert len(supplementary.tables) == len(supplementary_specs) == 4
    assert len(supplementary.inline_shapes) == 2
    for table, spec in zip(supplementary.tables, supplementary_specs):
        expected = [spec["headers"]] + [[str(value) for value in row] for row in spec["rows"]]
        assert [[cell.text for cell in row.cells] for row in table.rows] == expected
        workbook = load_workbook(OUT / spec["file"], data_only=True)
        assert [[cell_text(value) for value in row] for row in workbook["Display"].values] == expected
    with pymupdf.open(ROOT / "docs/BioExplainR-paper-draft.pdf") as pdf:
        all_pdf_text = "\n".join(page.get_text() for page in pdf)
        for spec in specs:
            hits = [page for page in pdf if spec["title"] in page.get_text()]
            assert len(hits) == 1, spec["title"]
            page = hits[0]
            normalized = re.sub(r"\s+", "", all_pdf_text if spec["id"] == "8" else page.get_text())
            assert "表注：" in normalized and "来源：" in normalized, spec["title"]
            search_text = re.sub(r"\s+", "", all_pdf_text if spec["id"] in ("8", "S5") else page.get_text())
            for row in spec["rows"]:
                for value in row:
                    assert re.sub(r"\s+", "", str(value)) in search_text, (spec["title"], value)
            if spec["id"] == "1":
                assert page.rect.width > page.rect.height
            if spec["id"] == "8":
                assert len(spec["rows"]) == 480
                assert sum(spec["title"] in page.get_text() for page in pdf) == 1
        assert sum(len(page.get_image_info()) for page in pdf) == 7
        assert all(len(page.get_image_info()) == 0 for page in list(pdf)[:10])
    reference_audit = json.loads((ROOT / "research/results/reference_audit.json").read_text(encoding="utf-8"))
    assert all(item["status"] == "resolved" for item in reference_audit["references"])
    result = {"status": "pass", "docx_paragraphs": len(document.paragraphs), "references": 38,
              "appendix_figures": sum(1 for path in OUT.glob("Figure_[1-4]_*.pdf")),
              "supplementary_figures": sum(1 for path in OUT.glob("Figure_S*.pdf")), "appendix_tables": table_audit,
               "supplementary_tables": 4, "figure_pdfs": figures,
              "main_pdf_pages": main_pdf, "supplementary_pdf_pages": supplementary_pdf,
              "bundle_records": len(manifest),
              "bundle_sha256": None,
              "bundle_sha256_note": "Not embedded: the archive contains this audit JSON and would be self-referential. Verify the external archive with sha256sum.",
              "resolved_dois": len(reference_audit["references"]), "tables_complete_on_single_pages": True,
              "visual_review": "Not performed: this model cannot view images. Geometry, fonts, nonblank pixels and content consistency checked."}
    args.output.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f'Passed: {result["references"]} references, {result["appendix_figures"]} appendix figures, '
          f'{len(table_audit)} matching Word/Excel tables, {len(manifest)} bundle records')
    print(f'Main PDF: {len(main_pdf)} pages; supplementary PDF: {len(supplementary_pdf)} pages')
    for page in main_pdf:
        print(json.dumps(page, ensure_ascii=False))


if __name__ == "__main__":
    main()
