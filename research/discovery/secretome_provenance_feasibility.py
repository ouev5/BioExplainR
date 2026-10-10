"""Conclude bounded source feasibility from acquired original materials."""
import argparse
import json
import re
import xml.etree.ElementTree as ET
from pathlib import Path

from secretome_provenance_complete import rows
from validation_sources import utc, record, csv_out, json_out, fetch


def main(out):
    dest=out / "complete"; root=ET.parse(out / "sources/PMC12141081.xml").getroot()
    pii=next(e.text for e in root.iter("article-id") if e.get("pub-id-type")=="pii")
    url=f"https://ars.els-cdn.com/content/image/1-s2.0-{pii}-mmc1.pdf"
    json_out(dest / "feasibility_freeze.json",dict(utc=utc(),script=record(Path(__file__)),
        inputs=[record(out / "sources/PMC12141081.xml"),record(out / "sources/PXD055968_files.json")],
        supplement_url=url,rule="Use original article PII and attachment mmc1; PDF magic plus parsed text before use; no new donor effect inference"))
    path=out / "sources/EV_publisher_supplement.bin"; log=fetch(url,path,timeout=30)
    if path.exists():
        log["pdf_signature"]=path.read_bytes().startswith(b"%PDF")
        if log["pdf_signature"]:
            import fitz
            doc=fitz.open(path);text="\n".join(p.get_text() for p in doc)
            (dest / "EV_supplement_text.txt").write_text(text)
            log.update(pages=len(doc),text_characters=len(text))
    projects=rows(dest / "pride_projects.csv")
    exclude={
        "PXD029237":"16HBE支气管上皮CAR-BirA胞内互作；非ASM上清，非GC配对",
        "PXD059603":"ASM EV作用后的上皮细胞蛋白，非ASM EV自身/GC配对",
        "PXD055949":"ASM EV作用后的上皮细胞蛋白，非ASM EV自身/GC配对",
        "PXD055968":"真实人ASM EV；三非哮喘/三哮喘标签，每标签三run，无GC/vehicle因子；未取得未筛Proline定量导出表",
        "PXD015604":"严重哮喘BSM-上皮/rhinovirus研究，项目未提供GC/vehicle设计",
        "PXD015566":"BSM代谢/哮喘病组胞内蛋白，非GC配对上清",
        "PXD010036":"声处理/离心后的细胞裂解可溶/沉淀组分；supernatant不指培养上清，非GC配对",
        "PXD001471":"商业HBSMC胞内可溶蛋白/凝胶格点，非供体GC配对上清",
    }
    decisions=[]
    for r in projects:
        acc=r["accession"]
        decisions.append(dict(accession=acc,title=r["title"],current_GC_candidate_validation="not_eligible_from_acquired_metadata",
            reason=exclude[acc],identity_followup="possible_ASM_EV_after_original_export" if acc=="PXD055968" else "not_prioritized",
            source="PRIDE corrected search metadata"))
    csv_out(dest / "project_feasibility.csv",decisions)
    evidence=[dict(source="PTX3 ASM original study",reference="doi:10.1371/journal.pone.0220772;PMC6706008",
        acquired_evidence="Primary human lung-resection ASM;DEX dose/time ELISA6/12/24/48h;RU486 inhibition;three-donor figure6",
        supported="已有ASM PTX3分泌与DEX/药理GR相关文献证据；不是本轮首次发现",
        limitations="无逐供体原ELISA数值；年龄未列；five independent experiments不是五已核实供体；正文48h/图注24h、promoter方法/结果表述冲突保留；RU486非NR3C1遗传因果。旧HTPC Holm112未通过不改写"),
      dict(source="Chronic cough focused secretome",reference="doi:10.1042/BSR20171090;PMC5686396",
        acquired_evidence="11healthy/6cough;FP10nM2h pretreatment +polyIC18h;32Luminex analytes",
        supported="真实多供体ASM上清与药物背景已有材料",
        limitations="聚焦32细胞因子面板，未见ANGPTL2/FSTL3/FBN2测量，缺逐供体未筛候选表，不替代固定候选验证"),
      dict(source="Human BSM extracellular vesicles",reference="doi:10.1016/j.isci.2025.112546;PMC12141081;PXD055968",
        acquired_evidence="Biopsy/lobectomy-derived primary humanBSM EV72h collection;18run/6labels;43study participants not18proteome donors",
        supported="新可续接真实ASM细胞外蛋白来源与原样本解码取得",
        limitations="三标签/病组，无GC随机因素；所有哮喘患者ICS临床暴露不作体外GC因子。PRIDE54RAW/MSF/pdResult+FASTA+link，无未筛定量文本；2.5Mascot/Proline(2020DB)与原文3.0CHIMERYS(2023DB)冲突，完整数组未分析"),
      dict(source="HTPC original publication",reference="doi:10.3390/cells11193164;PMC9562650;PXD033504",
        acquired_evidence="Four separately processed assays;TableS2.ALL/DIFF;source methods captured",
        supported="24h差异不属于全部工作表统一解码/舍入错误；同日期其他数组或肽数归一化均未精确解释",
        limitations="存档与发表24h处理/版本原因仍未确定；非零原LFQ与发表高相关不足以复现；没有作者勘误/原Perseus工程"),
    ]
    csv_out(dest / "public_evidence_scope.csv",evidence)
    notes=[]
    for file in ["PTX3_article.xml","cough_article.xml"]:
        article=ET.parse(out / "sources" / file).getroot()
        for node in article.iter():
            if node.tag in ["fig","table-wrap"]:
                text=" ".join("".join(node.itertext()).split())
                notes.append(dict(source=file,element=node.tag,id=node.get("id",""),text=text))
    csv_out(dest / "lead_figures_tables.csv",notes)
    json_out(dest / "feasibility.json",dict(status="completed",utc=utc(),projects=len(decisions),
        GC_candidate_validation_arrays_obtained=0,EV_full_quantification_analyzed=False,
        new_candidate_significance_claims=0,supplement=log,
        scope="Acquired scoped evidence; failure/no qualifying obtained array is not proof no dataset exists"))
    print(json.dumps(dict(projects=len(decisions),supplement=log),ensure_ascii=False,indent=2))


if __name__=="__main__":
    p=argparse.ArgumentParser();p.add_argument("output",type=Path);main(p.parse_args().output.resolve())
