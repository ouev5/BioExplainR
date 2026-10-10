"""Export the Chinese revision; preserve vector composite PDFs in the final appendix."""
import json
import subprocess
import sys
from pathlib import Path
import fitz
from docx import Document

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/"research"))
from export_paper import native_docx

OUT=ROOT/"docs/paper_cn_v1"
NAME="BioExplainR-中文论文-v0.8"


def main():
    source=OUT/"manuscript.md"
    base=["pandoc",str(source),"--standalone",f"--resource-path={ROOT/'docs'}:{ROOT}"]
    ast=json.loads(subprocess.check_output(base+["-t","json"]))
    # Give each composite and its caption one dedicated portrait page.
    for block in ast["blocks"]:
        if block["t"]=="Header":
            text="".join(i.get("c", "") for i in block["c"][2] if i["t"]=="Str")
            if text.startswith("图") and any(text.startswith(f"图{n}") for n in range(1,9)):
                block["c"][1][2].append(["paper-page-break","true"])
    doc=native_docx(ast,OUT/f"{NAME}.docx",[],legacy_layout=False)
    for p in doc.paragraphs:
        if p.style.name.startswith("Heading") and (p.text.startswith("图 ") or p.text.startswith("附录")):
            p.paragraph_format.page_break_before=True
    doc.save(OUT/f"{NAME}.docx")
    assert len(doc.tables)==0 and len(doc.inline_shapes)==8
    subprocess.run(base+["--embed-resources",f"--css={OUT/'paper.css'}","-o",str(OUT/f"{NAME}.html")],check=True)
    intermediate=OUT/"rendered_docx"
    intermediate.mkdir(exist_ok=True)
    subprocess.run(["libreoffice","-env:UserInstallation=file:///tmp/opencode/bioexplainr-paper-cn-lo",
                    "--headless","--convert-to","pdf","--outdir",str(intermediate),str(OUT/f"{NAME}.docx")],
                   check=True,timeout=120)
    pdf=fitz.open(intermediate/f"{NAME}.pdf")
    replaced=[]
    for page in pdf:
        images=page.get_image_info(xrefs=True)
        if not images:
            continue
        text=page.get_text()
        matches=[n for n in range(1,9) if f"图 {n} " in text]
        if len(matches)!=1 or len(images)!=1:
            raise ValueError(f"Ambiguous appendix figure page {page.number+1}: {matches}")
        rect=fitz.Rect(images[0]["bbox"])
        # Remove the raster preview from the final PDF, then place the original PDF.
        page.add_redact_annot(rect,fill=(1,1,1))
        page.apply_redactions(images=2,graphics=0,text=0)
        n=matches[0]
        with fitz.open(OUT/f"figures/composites/Figure_{n}.pdf") as vector:
            page.show_pdf_page(rect,vector,0,keep_proportion=True)
        replaced.append({"figure":n,"page":page.number+1,"bbox":list(rect)})
    assert sorted(r["figure"] for r in replaced)==list(range(1,9))
    pdf.set_metadata({"title":"BioExplainR 中文论文 v0.8","author":"","subject":"Chinese development manuscript with vector-PDF figure appendix"})
    final=OUT/f"{NAME}.pdf"
    pdf.save(final,garbage=4,deflate=True)
    report={"status":"pass","docx_tables":0,"docx_figures":8,"pdf_pages":len(pdf),
            "vector_composites_embedded":replaced,"pdf":final.relative_to(ROOT).as_posix()}
    (OUT/"export_report.json").write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    print(json.dumps(report,ensure_ascii=False,indent=2))
    pdf.close()


if __name__=="__main__":main()
