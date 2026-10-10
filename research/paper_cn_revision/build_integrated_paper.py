"""Build v0.13 from sealed v0.12 and subsequent saved proteome evidence."""
import argparse
import json
import re
import subprocess
import sys
from pathlib import Path
import xml.etree.ElementTree as ET

import fitz
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from docx.oxml import OxmlElement
from docx.oxml.ns import qn

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "research/discovery"))
from set_validation import rows
from validation_sources import record, utc, json_out
import build_revision as renderer
from build_discovery_paper import markdown_table

OLD = ROOT / "docs/paper_cn_v6"
PAPER = ROOT / "docs/paper_cn_v7"
SECRETOME = ROOT / "research/results/discovery_secretome_v1"
PROVENANCE = ROOT / "research/results/discovery_secretome_provenance_v1/complete"
PUBLIC = ROOT / "research/results/discovery_public_proteome_v1"
EV = ROOT / "research/results/discovery_asm_ev_export_v1"
SCRIPT = Path(__file__).resolve()
PROTOCOL = SCRIPT.with_name("INTEGRATION_PROTOCOL.md")
EDITORIAL_SOURCES = [
    ROOT / "research/results/discovery_secretome_provenance_v1/sources/ev_article_metadata.json",
    ROOT / "research/results/discovery_secretome_provenance_v1/sources/PTX3_article.xml",
    ROOT / "research/results/discovery_secretome_provenance_v1/sources/cough_article.xml",
    PROVENANCE / "lead_figures_tables.csv",
]

TABLE_SOURCES = [
    ("S27", SECRETOME / "all_results.csv", "全部846个QC蛋白组；两时点统一BH，精确另列；不足配对仍保留"),
    ("S28", SECRETOME / "candidate_results.csv", "固定56×2上清候选Holm112；原缺测与不足配对保留，区别于胞内蛋白112家族"),
    ("S29", SECRETOME / "candidate_donor_effects.csv", "全部候选逐日期配对与原缺测；技术重复先平均"),
    ("S30", SECRETOME / "candidate_sensitivity.csv", "发表六标签与严格3/3技术测量；每方案另112家族"),
    ("S31", SECRETOME / "candidate_direct_time.csv", "共有标签直接72−24药物响应差；56家族，不作分泌速率"),
    ("S32", SECRETOME / "candidate_identification.csv", "蛋白组肽数、unique肽和覆盖度；识别不是药物效应"),
    ("S33", SECRETOME / "array_summary.csv", "原组／QC／技术列／日期标签及完整分母"),
    ("S34", SECRETOME / "sample_map.csv", "两个secretome原解码；不沿用胞内七标签范围"),
    ("S35", PROVENANCE / "cross_array_summary.csv", "四原数组与四发表来源、LFQ／Intensity／iBAQ；0匹配和不可测分别保留"),
    ("S36", PROVENANCE / "scale_formula_summary.csv", "六固定肽数公式诊断，0匹配不等于确定处理原因"),
    ("S37", PUBLIC / "project_eligibility_review.csv", "21气道／平滑肌文本线索逐项设计审查，非全球穷尽"),
    ("S38", PUBLIC / "search_coverage.csv", "15查询18页437命中391唯一项目；含无关负控制"),
    ("S39", PUBLIC / "HBEC_sample_decode.csv", "43样本／10个体，ICS前后×polyIC四格及3个imiquimod样本"),
    ("S40", EV / "version_evidence_complete.csv", "18单run存档PD版本／结构；部分字节检查，不是最终定量导出"),
    ("S41", EV / "required_materials.csv", "论文版本完整未预筛矩阵、workflow、肽映射、年龄及重复定义缺件"),
    ("S42", SECRETOME / "candidate_leave_one.csv", "原候选留一方向检查；PTX3 72h有方向反转，不增加独立n"),
]


def replace_once(text, old, new):
    if text.count(old) != 1:
        raise ValueError(f"Expected one source marker: {old[:80]}")
    return text.replace(old, new, 1)


def draft_json(path, data):
    if (PAPER / "manuscript_manifest.json").exists():
        raise ValueError("Refusing sealed manuscript")
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n")


def article_reference(path):
    front = ET.parse(path).getroot().find("front")
    info = front.find("article-meta")
    name = info.find("contrib-group/contrib/name")
    author = name.findtext("surname") + " " + "".join(word[0] for word in name.findtext("given-names").split())
    title = "".join(info.find("title-group/article-title").itertext()).rstrip(".")
    journal = front.findtext("journal-meta/journal-title-group/journal-title")
    date = next(e for e in info.findall("pub-date") if e.find("year") is not None)
    doi = next(e.text for e in info.findall("article-id") if e.get("pub-id-type") == "doi")
    return f"{author} et al. {title}. {journal}. {date.findtext('year')}. doi:{doi}."


def main_text():
    text = (OLD / "manuscript.md").read_text()
    text = text.replace("v0.12", "v0.13").replace("2026-10-09", "2026-10-10").replace("paper_cn_v6/", "paper_cn_v7/")
    text = replace_once(text, "公开数据扩展验证 · BioExplainR", "完整转录／胞内与上清蛋白证据整合 · BioExplainR")
    text = replace_once(text, "BioExplainR组织完整统计事实与范围。", "另整合已保存PXD033504完整上清数组的846项统一BH及56×2项Holm、原发表处理来源诊断和公开蛋白组设计核查。BioExplainR组织完整统计事实与范围；本稿整合不新增候选统计。")
    text = replace_once(text, "发表六标签子集72h通过、24h未通过新112项校正。", "发表六标签子集72h通过、24h未通过新112项校正。上清数组中ANGPTL2／FSTL3取得肽段识别但有效配对不足；FBN2 72h原范围+1.535（Holm112=.0127），发表六标签子集未通过（.270）。24h上清存档／发表处理差异未解决。")
    text = replace_once(text, "分析为结果后探索。", "上清蛋白识别及范围敏感线索不能升级ASM分泌或功能确认；分析为结果后探索。")
    text = replace_once(text, "补充方法S1–S8", "补充方法S1–S11")
    text = replace_once(text, "本轮完整54基因扩展", "v0.12阶段完整54基因扩展")
    text = replace_once(text, "本轮从PRIDE固实7z取得", "此前分析从PRIDE固实7z取得")
    text = replace_once(text, "本轮官方Ensembl→Entrez646324", "此前分析官方Ensembl→Entrez646324")
    text = replace_once(text, "补充图S4显示本轮无预筛", "补充图S4显示已保存无预筛")
    text = replace_once(text, "本轮又在重点候选已知后扩展", "v0.12阶段又在重点候选已知后扩展")
    text = replace_once(text, "本稿从少数候选扩展到原完整54基因", "已保存分析从少数候选扩展到原完整54基因")
    text = replace_once(text, "GSE131688h+.691", "GSE13168的8h+.691")
    text = replace_once(text, "# 2 方法", "本稿整合此前封存的发现、集合验证及后续上清／来源结果；下文“新增”指各分析阶段相对于原发现的数据扩展，不表示本次整合重新运行统计。\n\n# 2 方法")
    text = replace_once(text, "## 2.6 实际R包应用与复核", """## 2.6 完整上清数组、处理来源及公开设计核查

PXD033504为同一HTPC研究的24／72h培养上清[16]。已保存两个完整未预筛proteinGroups、原解码、参数和summary；4,170个成功HTTP206段及header覆盖完整容器，两个上游SHA1和8成员CRC通过。24h六日期标签／36技术列与发表一致；72h八日期标签／48列，比发表六标签多10.09.19与18.11.14，额外标签年龄／QC未知。两上清MaxQuant均1.6.11.0，与论文一致，区别于胞内1.6.15.0冲突。

上清QC去reverse／污染／site-only，全数组两时点466＋380＝846位置统一BH；未可估计P=1保留位置。固定原54＋PER1／NR3C1共56×2项另Holm112，只使用唯一single-gene组；LFQ0为缺测、不填补，每条件至少2/3技术值在log2尺度平均，至少三个日期配对才估计。严格3/3技术阈值与发表六标签子集各另112项Holm；共有标签直接72−24药物响应差另56项。效应为上清相对丰度，非每细胞单位时间分泌速率。上清和胞内属于同一来源，不增加独立ASM队列。完整家族与测量见补充表S27–S34，留一见S42。

来源诊断固定四原数组／原解码／发表Table S2，按Protein IDs精确匹配优先、唯一Majority IDs回退；非零log2LFQ与四位发表值容差0.000051，ALL总Intensity单独比较。另核对四数组日期／条件／重复及六个LFQ或Intensity除以肽数公式；诊断不产生效应P值、不拟合修正发表表，见S35／S36。

公开来源复核包括PRIDE15查询18页、391唯一项目及21气道／平滑肌线索（S37／S38），范围非全球穷尽。HBEC43样本用作者SRDF和community SDRF双源核对（S39）。PXD055968通过已取得部分数据库字节检查18个单run版本／结构（S40），缺件见S41；并未取得最终联合定量或启动候选身份统计。设计核查不等同新增ASM验证。

## 2.7 实际R包应用与复核""")
    text = replace_once(text, "TMM／voom／moderation未跨语言重拟合。", "已保存上清R独立复核35,016原LFQ、5,836日期组行、846／112家族、224敏感性、56直接差及26留一方向通过；四数组来源诊断R核对281,232测量／31,228 ALL位置，OOXML独立解码23,436发表测量。上清及来源诊断各实际两个context／双语报告，在线调用均0；本稿整合复用这些保存结果。TMM／voom／moderation未跨语言重拟合。")
    text = replace_once(text, "# 4 讨论", """## 3.6 完整上清候选：识别、配对不足与范围敏感线索

上清24／72h原600／531组，QC466／380组，194／153可估计；统一846项BH分别7／16通过，精确全家族0通过。固定56×2候选4项可估计、1项Holm通过，精确Holm0通过；完整分母见表4与补充表S27／S28。图4显示四重点候选的全部可用日期效应及缺测，补充图S5给完整数组背景，不把不可估计画成零效应。

ANGPTL2 24h为14条肽／13条unique肽、覆盖37.3%，仅两个合格日期配对−.453／−1.088，低于至少三配对规则；72h未检出不作阴性。FSTL3两时点各2条unique肽，有效LFQ配对均0。UniProt保存注释支持两者Secreted／信号肽身份，但不能从识别推断DEX分泌响应或特定分泌异构体。补充表S29／S32保留逐日期与识别分层。

FBN2 72h原八标签范围内7/7可测配对↑，+1.535（点态95%CI+1.112至+1.958；Holm112=.0127）；严格3/3技术测量6/6↑，+1.419（.0259）。发表六标签仅五对可测，+1.466（.270）未通过；直接72−24五共有对+1.397（Holm56=.187）未通过，精确全家族亦未确认。因此是供体范围敏感的跨组织细胞外蛋白线索，不能写成发表六成人或ASM分泌确认。PTX3 24h+.620、6/6↑，Holm112=.592未通过；72h未通过且一轮留一方向反转。敏感性与直接差见S30／S31，完整留一见S42。

四原数组来源诊断中，胞内24／72h与上清72h的非零LFQ分别4,543／14,829／2,128项全部与发表舍入一致；24h上清0/803一致。其ALL仅9/467总Intensity相等，9项均双方零，正值一致0；另外25原LFQ0却发表有限。其他数组交叉对应和六公式均未匹配，不是简单整表互换或统一偏移，处理原因仍未确认。上清72h还有320原LFQ0／发表有限值，本轮不填补。24h结果明确为存档数组重分析，不称原Perseus复现。补充表S35／S36和补充图S6展示诊断及其边界。

## 3.7 ASM EV最终导出缺件与公开来源适用性

PXD055968是患者原代BSM培养上清72h EV来源，六患者各三repeat共18run，无受控GC／vehicle因素[17]。PRIDE56项文件清单及原映射已核对；18个存档pdResult均PD3.1.0.638／CHIMERYS inferys3.0／2024库，与论文PD3.0／inferys2.1／2023及PRIDE PD2.5／Mascot／Proline／2020差异保留。每个均一RAW／一sample、CWF_ID，54张target蛋白／蛋白组／肽组表无最终丰度列；Minora／PSM强度不等于最终联合定量。部分字节结构核查不能声称整18数据库SHA1通过。正确版本的未差异预筛蛋白组×18run矩阵、workflow、缺测及肽映射、六患者年龄／成人确认和重复层级仍缺，身份检查未冻结／启动；材料请求仍为草稿、未发送（S40／S41）。选中IPA糖酵解表不能替代完整矩阵，EV检出亦不能升级GC响应或主动分泌。

公开清点15查询18页437查询命中／391唯一项目，21气道／平滑肌文本线索经设计审查，本轮未取得合格成人原代ASM受控GC上清数组；这不是数据不存在的证据。公开存档／处理表可匿名下载，联系作者仅针对尚缺材料。A549 PXD063431为癌细胞系DEX胞内蛋白；PXD003963／003965／003971为真皮成纤维细胞上清鉴定mzTab，无跨样本丰度矩阵；均不替代ASM验证（S37／S38）。

HBEC PXD029135完整表为3,072蛋白组×43样本／10个体，每人ICS前／后×polyIC四格，T2-high／low各格5／5，另3个imiquimod样本；作者及community SDRF全部对应（S39）。因此纠正历史“T2与ICS部分混杂”判断。临床ICS前后仍不是受控体外GC／vehicle，时间及临床背景未排除；组织为上皮、非ASM、非上清。样本设计纠正及来源可及性不改变PER2／METTL7A／ANGPTL2／FSTL3／FBN2候选结论。

# 4 讨论""")
    text = replace_once(text, "四原数组来源诊断中，", "已有原ASM文献报告PTX3的DEX分时上清ELISA及RU486药理支持[18]；不是本轮首次发现。原文年龄未列、五independent experiments不作五已核实供体，正文／图注24与48h及promoter叙述冲突保留；没有逐供体ELISA数组供本稿重算，也不是NR3C1遗传因果。该已有文献支持不改变HTPC PTX3全家族未通过，亦不替代PER2／METTL7A／ANGPTL2／FSTL3验证。\n\n四原数组来源诊断中，")
    text = replace_once(text, "公开清点15查询18页", "另有成人ASM慢性咳嗽研究的11健康／6咳嗽来源、32因子Luminex上清面板及FP＋polyIC条件[19]；它是特定因子面板，不是固定候选完整未筛蛋白组，不能由面板缺席转写候选阴性。\n\n公开清点15查询18页")
    text = replace_once(text, "## 4.3 后续纯计算方向", """上清检查进一步限定RNA向分泌层外推：ANGPTL2／FSTL3识别不解决有效配对不足；FBN2原范围通过但发表子集未通过，不能选有利范围作为确认。24h上清来源处理差异与72h额外标签分别影响可复现性和研究人群范围。上清相对丰度可受释放、死亡、细胞数、摄取和降解影响，原MS固定750ng上样不能给每细胞通量。PXD055968没有药物因子，HBEC为临床上皮前后，其他公开GC蛋白资料非ASM；它们回答不同问题。

## 4.3 后续纯计算方向""")
    text = replace_once(text, "进一步的跨组织、公共人群或通路分析需要针对各自估计目标的新方案。", "具体材料动作是发送既有PXD055968请求或提供原回信／附件，按版本、未预筛矩阵、原缺测、肽映射及供体重复层级验收后，再另冻结完整候选身份检查；目前没有可据以启动的最终数组。24h上清处理原因需原Perseus／版本材料。进一步的跨组织、公共人群或通路分析需要针对各自估计目标的新方案。")
    text = replace_once(text, "新增早期、时间、遗传与蛋白检查同时收紧机制表述。", "新增早期、时间、遗传与蛋白检查同时收紧机制表述。ANGPTL2／FSTL3有上清蛋白识别而药物响应未确认，FBN2为范围敏感线索；24h来源差异及ASM EV最终导出缺件仍待材料。")
    text = replace_once(text, "新稿`docs/paper_cn_v7/`包含Word／PDF／自包含HTML、表图与独立清单；复现与保存结果核验见README。", "v0.13新增整合来源为`discovery_secretome_v1/`、`discovery_secretome_provenance_v1/complete/`、`discovery_asm_ev_export_v1/`、`discovery_asm_ev_materials_v1/`及`discovery_public_proteome_v1/`。新稿`docs/paper_cn_v7/`包含Word／PDF／自包含HTML、表图与独立清单；保存结果核验见README。本稿没有新增候选效应／校正／模型拟合或新的在线模型调用。")
    ev_metadata = json.loads(EDITORIAL_SOURCES[0].read_text())["resultList"]["result"][0]
    assert ev_metadata["doi"] == "10.1016/j.isci.2025.112546"
    reference17 = "17. " + ev_metadata["authorString"].split(",")[0] + " et al. " + ev_metadata["title"] + " iScience. 2025;28:112546. doi:" + ev_metadata["doi"] + ". PMC12141081；PXD055968；引用限已核对患者EV来源、方法和存档结构。"
    references = "\n".join([reference17, "18. " + article_reference(EDITORIAL_SOURCES[1]) + " PMC6706008；已有ASM PTX3蛋白／药理文献。", "19. " + article_reference(EDITORIAL_SOURCES[2]) + " PMC5686396；已有成人ASM面板，非完整候选蛋白组。"])
    text = replace_once(text, "PXD033514／033534；PMC9562650.", "PXD033504／033514／033534；PMC9562650.\n" + references)
    text = replace_once(text, "## 图 1 原固定候选的四背景响应", """## 表 4 完整上清候选与发表范围敏感性

::: {.integrated-table-4}
:::

**表注：** 效应为DEX−control平均log2LFQ差，CI点态。上清固定112家族独立于胞内112；不可估计的Holm=1为占位，非无效应。FBN2各方案另112家族，同来源不增加独立n。

## 图 1 原固定候选的四背景响应""")
    text += """

## 图 4 上清重点候选的逐日期响应与缺测

![图4上清候选](paper_cn_v7/figures/Figure_4.png){width=16cm}

**图 4.** 原封存重点候选图：圆点为合格日期配对，方块／点态CI仅在至少三配对时展示。ANGPTL2 24h只有两配对；FSTL3没有合格配对。FBN2 72h原范围效应不等于发表六标签确认，需与表4子集结果一起解释。上下游组织、药物、时点不同，不连成分泌动力学曲线。
"""
    text = replace_once(text, "GR遗传及人源蛋白。", "GR遗传、人源胞内／上清蛋白及公开来源材料缺口。")
    return text


def table_spec(name, widths):
    data = rows(PAPER / "tables" / (name + ".csv"))
    return dict(id=name, headers=list(data[0]), rows=[list(r.values()) for r in data], widths_cm=widths)


def secretome_table():
    output = []
    candidates = rows(SECRETOME / "candidate_results.csv")
    sensitivity = rows(SECRETOME / "candidate_sensitivity.csv")
    selected = [(next(r for r in candidates if r["symbol"] == gene and r["time_h"] == time), "主分析")
                for gene, time in [("ANGPTL2", "24"), ("ANGPTL2", "72"), ("FSTL3", "24"),
                                   ("FSTL3", "72"), ("PTX3", "24"), ("PTX3", "72"), ("FBN2", "24"), ("FBN2", "72")]]
    selected += [(next(r for r in sensitivity if r["symbol"] == "FBN2" and r["time_h"] == "72" and r["analysis"] == kind), label)
                 for kind, label in [("strict_three", "严格3/3"), ("published_six", "发表六标签")]]
    for r, label in selected:
        measurable = r["status"] == "estimable"
        output.append({"基因/时点": r["symbol"] + "/" + r["time_h"] + "h", "范围": label, "配对n": r["n_pairs"],
            "效应": f'{float(r["effect"]):+.3f}' if measurable else "不可估计",
            "点态95%CI": f'{float(r["ci_low"]):+.3f}至{float(r["ci_high"]):+.3f}' if measurable else "—",
            "Holm112 P": f'{float(r["holm112"]):.3g}', "状态": "可估计" if measurable else "未检出" if r["status"] == "not_detected" else "配对不足"})
    return output


def evidence_figure():
    plt.rcParams.update({"font.family": "DejaVu Sans", "font.size": 8.5, "pdf.fonttype": 42})
    fig, ax = plt.subplots(figsize=(10.5, 8.3))
    ax.axis("off")
    cards = [
        ("Adult ASM late transcription", "Full 54-gene set: 45/54 combined support\nPER2/PER3 lower; six adults in GSE130715\nSmall-n exact full family not confirmed", True),
        ("Clock-related transcription", "BMAL1/NPAS2 up; NR1D2/DBP/TEF down\nLINC00607 measurable in new source\nNo phase, amplitude or contraction estimate", True),
        ("Early response / drug x time", "Early adult ASM PER2 not confirmed\nAdult pulse 24h drug P=.7831 (published)\nA549 / HASM1 conditions are distinct", False),
        ("GR genetic evidence", "U2OS rescue PER2 interaction not confirmed\nPER1 control does not establish PER2 causality\nNo empty-KO arm; GNAS is a different target", False),
        ("Human intracellular protein", "HTPC METTL7A: complete raw LFQ acquired\n72h published subset passes; 24h does not\nRaw label / MaxQuant version conflicts retained", True),
        ("HTPC extracellular candidates", "ANGPTL2 / FSTL3 identified, pairs insufficient\nFBN2 72h raw Holm=.0127; subset=.270\n24h stored / published processing unresolved", False),
        ("ASM EV material gap", "PXD055968: six patients, 18 repeated runs\nNo controlled GC; final joint matrix missing\nIdentity check not started; request unsent", False),
        ("Other public GC proteomes", "HBEC: balanced T2 / ICS paired design\nClinical epithelium, not controlled ASM GC\nA549 / dermal secretome cannot replace ASM", False),
    ]
    for i, (title, body, supported) in enumerate(cards):
        x, y = .02 + (i % 2) * .50, .985 - (i // 2) * .246
        ax.add_patch(plt.Rectangle((x, y - .222), .465, .218, transform=ax.transAxes,
                                  facecolor="#eaf4f0" if supported else "#f1f3f5", edgecolor="#bdcbd1", lw=.8))
        ax.text(x + .014, y - .022, title, transform=ax.transAxes, weight="bold", fontsize=10, color="#254d5d", va="top")
        ax.text(x + .014, y - .071, body, transform=ax.transAxes, fontsize=8.5, linespacing=1.8, va="top")
    fig.subplots_adjust(left=.02, right=.98, bottom=.02, top=.98)
    for ext in ["pdf", "png"]:
        fig.savefig(PAPER / "figures" / ("Figure_3." + ext), dpi=190)
    plt.close(fig)


def supplement_text():
    text = (OLD / "supplementary.md").read_text().replace("v0.12", "v0.13").replace("paper_cn_v6/", "paper_cn_v7/")
    text = replace_once(text, 'date: "2026-10-09"', 'date: "2026-10-10"')
    text = replace_once(text, "# 补充方法", "本版保留v0.12历史分析文字与原统计家族；新增S9–S11为已保存上清／来源及设计核查的整合说明。本稿没有新的候选统计，旧阶段的“本轮”不指本次稿件整合。\n\n# 补充方法")
    extra = """# S9 完整上清数组与原发表处理范围

上清PXD033504原24h六标签／36列、72h八标签／48列，两个MaxQuant1.6.11.0。完整600／531原组、466／380QC组，846统一BH；194／153可估计、7／16参数BH通过、精确BH0。固定56×2独立Holm112，4可估计、1参数通过、精确0。LFQ0缺测，每条件≥2/3技术测量、至少3日期配对，严格3/3及发表六标签另112家族，直接差56家族。各家族与胞内112分开，不能合并选择最佳P。

ANGPTL2 24h两合格配对−.453／−1.088，14肽／13unique、37.3%覆盖，72h未检出；FSTL3各2unique但有效配对0。Secreted注释来自原UniProt保存响应，不替代本轮药物统计。FBN2 72h主7对+1.535，严格6对+1.419，发表子集5对+1.466且Holm=.270；直接差+1.397、Holm56=.187未通过。上清相对丰度非每细胞通量，同HTPC来源不增加ASM独立队列。

原独立R核对35,016测量、5,836供体组行、846／112校正、224敏感性、56直接差、26留一通过。已保存BioExplainR两个context／双语报告，完整分母通过。全部结果S27–S34／S42，原数组／freeze／错误仍由secretome_manifest绑定。

# S10 四数组来源诊断

原胞内24／72h及上清24／72h四数组、168列与Table S2固定比较。相应非零LFQ4,543／14,829／803／2,128位置，前三个匹配数依次4,543／14,829／0，最后2,128。24h上清ALL9/467相等全为零，正值0；非零偏移非统一常数，其他三个数组交叉LFQ和六肽数公式均0匹配。不能从高相关或拟合偏移宣称找到处理机制，更不能修改原发表值。72h上清320原LFQ0／发表有限保留，不填补。

R重建281,232逐测量、31,228 ALL位置、4,968公式及168列；Python原OOXML重读23,436发表测量，均为同来源核验。S35／S36提供摘要，补充图S6复用原匹配图；24h存档数组结果不是Perseus原结果复现。

# S11 公开蛋白来源设计与材料待办

PRIDE15查询18页437命中、391唯一项目，21气道／平滑肌文本线索经审查；全部请求／错误／部分下载在public_proteome新封存。未取得合格成人ASM受控GC上清矩阵不表示不存在。A549癌细胞系、HBEC临床上皮、真皮成纤维细胞鉴定表不能作ASM候选差异验证。

HBEC43样本／10人，每人ICS前后×polyIC四格；T2-high／low各格5／5，另3imiquimod样本。作者SRDF／community SDRF全部对应，纠正T2与ICS部分混杂的旧判断。临床纵向变化不能单独归因GC，非受控vehicle、非ASM、非上清，未作候选统计（S37–S39）。

PXD055968六患者18run无GC因子；18单runPD3.1／inferys3.0／2024与论文和项目版本不同，54张target表无最终丰度列。缺未预筛18run联合矩阵、原缺测、最终workflow与肽映射、患者年龄／成人确认及repeat层级，候选身份尚未启动（S40／S41）。公开PRIDE文件可匿名下载；既有作者材料请求未发送。收到原件后先按MATERIALS_RECEIPT验收，再另冻身份检查，不把单run feature强度伪装发表数组。GitHub／外部上传仍暂停。

已有ASM PTX3原文支持DEX上清／RU486药理关系，但无逐供体原ELISA重算且年龄／时点／promoter冲突保留；成人咳嗽32因子上清面板不是全固定候选数组。原方法／图注／表格在来源研究lead_figures_tables.csv；主稿参考文献[18,19]来自已保存原XML。它们是已有文献背景，不是本稿新发现或候选功能实验。

"""
    text = replace_once(text, "# 新补充表及来源", extra + "# 新补充表及来源")
    for label, path, note in TABLE_SOURCES:
        text = replace_once(text, "# 补充图\n", f"## 补充表 {label}\n\n{note}；{len(rows(path))}行，`tables/Table_{label}.csv`及XLSX。来源：`{path.relative_to(ROOT)}`。\n\n# 补充图\n")
    text += """

## 补充图 S5 完整上清数组的效应与统一BH

![补充图S5](paper_cn_v7/figures/Figure_S5.png){width=16cm}

复用原secretome图：846位置统一BH、194／153可估计；未可估计仍在分母内，不画作零效应。各点是protein group，不将多gene组分配给单基因。

## 补充图 S6 四数组与发表非零LFQ一致性

![补充图S6](paper_cn_v7/figures/Figure_S6.png){width=16cm}

复用原来源诊断图。24h上清0/803而其他对应数组全部舍入一致；图示匹配率不是候选效应或处理原因检验，不修正发表值。
"""
    return text


def export(source, name, specs, figures):
    text = source.read_text()
    digits = str.maketrans("⁰¹²³⁴⁵⁶⁷⁸⁹", "0123456789")
    text = re.sub(r"10⁻([⁰¹²³⁴⁵⁶⁷⁸⁹]+)", lambda m: "10^-" + m[1].translate(digits) + "^", text)
    rendered = PAPER / (source.stem + "_rendered.md")
    rendered.write_text(text)
    command = ["pandoc", str(rendered), "--standalone", f"--resource-path={ROOT / 'docs'}:{ROOT}"]
    ast = json.loads(subprocess.check_output(command + ["-t", "json"]))
    doc = renderer.native_docx(ast, PAPER / (name + ".docx"), specs, legacy_layout=False)
    for style in doc.styles:
        if style.name.startswith("Heading"):
            pr = style.element.get_or_add_pPr()
            existing = pr.find(qn("w:numPr"))
            if existing is not None:
                pr.remove(existing)
            num = OxmlElement("w:numPr")
            ident = OxmlElement("w:numId")
            ident.set(qn("w:val"), "0")
            num.append(ident)
            pr.append(num)
    for p in doc.paragraphs:
        if p.style.name.startswith("Heading") and p.text in figures:
            p.paragraph_format.page_break_before = True
    doc.save(PAPER / (name + ".docx"))
    subprocess.run(command + ["--embed-resources", f"--css={PAPER / 'paper.css'}", "-o", str(PAPER / (name + ".html"))], check=True)
    intermediate = PAPER / "rendered_docx"
    intermediate.mkdir(exist_ok=True)
    process = subprocess.run(["libreoffice", "-env:UserInstallation=file:///tmp/opencode/paper-v013-lo", "--headless", "--convert-to", "pdf", "--outdir", str(intermediate), str(PAPER / (name + ".docx"))], capture_output=True, text=True, timeout=180)
    attempt = len(list(PAPER.glob(source.stem + "_export_log*.json"))) + 1
    json_out(PAPER / f"{source.stem}_export_log_attempt_{attempt}.json", dict(utc=utc(), returncode=process.returncode, stdout=process.stdout, stderr=process.stderr))
    process.check_returncode()
    replaced = []
    with fitz.open(intermediate / (name + ".pdf")) as pdf:
        for page in pdf:
            images = page.get_image_info(xrefs=True)
            if not images:
                continue
            compact = re.sub(r"\s", "", page.get_text())
            matches = [caption for caption in figures if re.sub(r"\s", "", caption) in compact]
            if len(matches) != 1 or len(images) != 1:
                raise ValueError(f"Ambiguous figure page {page.number + 1}: {matches}, {len(images)} images")
            rect = fitz.Rect(images[0]["bbox"])
            page.add_redact_annot(rect, fill=(1, 1, 1))
            page.apply_redactions(images=2, graphics=0, text=0)
            with fitz.open(figures[matches[0]]) as original:
                page.show_pdf_page(rect, original, 0, keep_proportion=True)
            replaced.append(dict(caption=matches[0], page=page.number + 1, pdf=record(figures[matches[0]])))
        assert len(replaced) == len(figures)
        pdf.set_metadata(dict(title=name, author="", subject="BioExplainR v0.13 saved-evidence integration"))
        pdf.save(PAPER / (name + ".pdf"), garbage=4, deflate=True)
        return dict(name=name, pages=len(pdf), docx_tables=len(doc.tables), figures=len(doc.inline_shapes), vector_figures=replaced)


def build(refresh=False):
    if (PAPER / "manuscript_manifest.json").exists():
        raise ValueError("Refusing sealed manuscript")
    if PAPER.exists() and not refresh:
        raise ValueError("Use --refresh only for this unsealed draft")
    if not refresh:
        import audit_public_proteome
        result = audit_public_proteome.verify()
        PAPER.mkdir()
        for name in ["evidence", "tables", "figures"]:
            (PAPER / name).mkdir()
        (PAPER / "evidence/rgo_before_integration.md").write_bytes((ROOT / "rgo.md").read_bytes())
        json_out(PAPER / "evidence/initial_verification.json", dict(utc=utc(), result=result))
        inputs = [OLD / "manuscript_manifest.json", PUBLIC / "public_proteome_manifest.json",
                  OLD / "manuscript.md", OLD / "supplementary.md", PROTOCOL] + [p for _, p, _ in TABLE_SOURCES]
        json_out(PAPER / "integration_freeze.json", dict(utc=utc(), script=record(SCRIPT), inputs=[record(p) for p in inputs],
            scope="Saved-evidence manuscript integration; no new candidate statistics", new_candidate_statistics=False))
    frozen = json.loads((PAPER / "integration_freeze.json").read_text())
    for r in frozen["inputs"]:
        assert record(ROOT / r["path"]) == r
    copied = []
    for p in sorted((OLD / "tables").glob("*")):
        if p.suffix in [".csv", ".xlsx"] and p.stem != "Table_1":
            target = PAPER / "tables" / p.name
            target.write_bytes(p.read_bytes())
            copied.append(dict(new=record(target), source=record(p)))
    (PAPER / "paper.css").write_bytes((OLD / "paper.css").read_bytes())
    renderer.OUT, renderer.VERSION = PAPER, "v0.13"
    dataset = rows(OLD / "tables/Table_1.csv")
    dataset += [dict(zip(dataset[0], values)) for values in [
        ["PXD033504", "上清24h六／72h八日期标签", "同HTPC来源DEX；原八标签与发表六标签分别检查"],
        ["PXD055968", "六患者／18重复run", "原代BSM EV，无GC；最终联合定量仍缺"],
        ["PXD029135／063431", "10 HBEC个体／A549培养", "临床ICS前后／癌细胞系DEX，均非ASM"]]]
    renderer.external_table("Table_1", list(dataset[0]), [list(r.values()) for r in dataset], "v0.13单位与估计目标；不同组织和重复不相加")
    display = secretome_table()
    renderer.external_table("Table_4", list(display[0]), [list(r.values()) for r in display], "保存上清统计与子集；各112family分开，CI点态；原缺测不转阴性")
    sources = []
    for label, path, note in TABLE_SOURCES:
        data = rows(path)
        renderer.external_table("Table_" + label, list(data[0]), [list(r.values()) for r in data], note)
        sources.append(dict(label=label, source=record(path), rows=len(data), note=note))
    figure_sources = []
    for name, source in [(name, OLD / "figures" / name) for name in ["Figure_1", "Figure_2", "Figure_S1", "Figure_S2", "Figure_S3", "Figure_S4"]] + [
        ("Figure_4", ROOT / "docs/secretome_validation_v1/figures/Figure_1_candidates"),
        ("Figure_S5", ROOT / "docs/secretome_validation_v1/figures/Figure_2_complete_array"),
        ("Figure_S6", ROOT / "docs/secretome_provenance_v1/figures/Figure_1_match")]:
        for ext in ["pdf", "png"]:
            original = source.with_suffix("." + ext)
            target = PAPER / "figures" / (name + "." + ext)
            target.write_bytes(original.read_bytes())
            figure_sources.append(dict(new=record(target), source=record(original)))
    evidence_figure()
    main = main_text()
    specs = [table_spec("Table_1", [3.2, 4.5, 9.3]), table_spec("Table_2", [5.7, 3.3, 8]),
             table_spec("Table_3", [2, 2.5, 4, 2.5, 3, 3]), table_spec("Table_4", [2.3, 2.2, 1.1, 2, 4.4, 2.2, 2.8])]
    (PAPER / "manuscript.md").write_text(main)
    expanded = main
    for i, spec in enumerate(specs, 1):
        marker = f"::: {{.set-table-{i}}}\n:::" if i < 4 else "::: {.integrated-table-4}\n:::"
        expanded = replace_once(expanded, marker, markdown_table(spec["headers"], spec["rows"]))
    (PAPER / "manuscript_expanded.md").write_text(expanded)
    (PAPER / "supplementary.md").write_text(supplement_text())
    main_figures = {caption: PAPER / "figures" / (name + ".pdf") for name, caption in [
        ("Figure_1", "图 1 原固定候选的四背景响应"), ("Figure_2", "图 2 完整54基因的六成人逐供体响应"),
        ("Figure_3", "图 3 候选证据层级与未确认范围"), ("Figure_4", "图 4 上清重点候选的逐日期响应与缺测")]}
    supplement_figures = {caption: PAPER / "figures" / (name + ".pdf") for name, caption in [
        ("Figure_S1", "补充图 S1 旧13供体固定候选响应"), ("Figure_S2", "补充图 S2 A549药理及暴露条件差"),
        ("Figure_S3", "补充图 S3 GR遗传交叉检验"), ("Figure_S4", "补充图 S4 完整原LFQ的METTL7A逐供体标签"),
        ("Figure_S5", "补充图 S5 完整上清数组的效应与统一BH"), ("Figure_S6", "补充图 S6 四数组与发表非零LFQ一致性")]}
    historic = [table_spec(name, [17 / len(rows(PAPER / "tables" / (name + ".csv"))[0])] * len(rows(PAPER / "tables" / (name + ".csv"))[0]))
                for name in ["F1_common_task", "F2_paired_bootstrap", "F3_receptor_control", "F4_chip_primary"]]
    historic.append(table_spec("Table_S26", [5.3, 2, 4, 3.7, 2]))
    result = dict(status="pass", utc=utc(), main=export(PAPER / "manuscript_expanded.md", "BioExplainR-中文论文-v0.13", specs, main_figures),
                  supplement=export(PAPER / "supplementary.md", "BioExplainR-补充材料-v0.13", historic, supplement_figures),
                  scope="Integration of previously sealed statistics and source/design corrections; no new tests")
    draft_json(PAPER / "export_report.json", result)
    draft_json(PAPER / "assets_manifest.json", dict(copied_tables=copied, figure_sources=figure_sources, table_sources=sources,
        editorial_sources=[record(p) for p in EDITORIAL_SOURCES],
        files=[record(p) for folder in [PAPER / "figures", PAPER / "tables"] for p in sorted(folder.glob("*")) if p.is_file()]))
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--refresh", action="store_true")
    build(parser.parse_args().refresh)
