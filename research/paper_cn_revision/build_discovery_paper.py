"""Export the biology-led v0.11 draft from sealed response results, without refitting."""
import argparse
import csv
import hashlib
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "research/results/discovery_stable_response_v1"
sys.path.insert(0, str(Path(__file__).parent))
import build_revision as renderer


def rows(path):
    with path.open(encoding="utf-8-sig", newline="") as stream:
        return list(csv.DictReader(stream))


def write_json(path, data):
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n")


def record(path):
    h = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            h.update(chunk)
    return {"path": path.relative_to(ROOT).as_posix(), "bytes": path.stat().st_size,
            "sha256": h.hexdigest()}


def number(value):
    return f"{float(value):.3f}" if value else "不可估计"


def pvalue(value):
    return f"{float(value):.3g}"


def markdown_table(headers, values):
    return "\n".join(["| " + " | ".join(headers) + " |", "|" + "---|" * len(headers)] +
                     ["| " + " | ".join(str(v).replace("|", "\\|") for v in row) + " |" for row in values])


def build(out, refresh=False):
    out = out.resolve()
    if (not out.is_relative_to(ROOT / "docs") or (out / "manuscript_manifest.json").exists() or
            (out / "export_report.json").exists() and not refresh):
        raise ValueError("Use a new, prepared manuscript directory under docs")
    for name in ["manuscript.md", "paper.css", "ISSUES.md"]:
        if not (out / name).is_file():
            raise ValueError(f"Missing source: {name}")
    (out / "figures").mkdir(exist_ok=refresh)
    (out / "tables").mkdir(exist_ok=refresh)
    (out / "evidence").mkdir(exist_ok=refresh)
    # Preserve the root handoff already bound by the older sealed analysis.
    snapshot = out / "evidence/rgo_before_v011.md"
    if not snapshot.exists():
        historical = ROOT / "docs/paper_cn_v5/evidence/rgo_before_v011.md"
        source_handoff = historical if historical.exists() else ROOT / "rgo.md"
        original_manifest = json.loads((ROOT / "docs/biology_discovery_v2/discovery_manifest.json").read_text())
        expected = next(r for r in original_manifest["analysis_files"] if r["path"] == "rgo.md")
        assert record(source_handoff)["sha256"] == expected["sha256"], "Use the preserved historical handoff"
        snapshot.write_bytes(source_handoff.read_bytes())
    renderer.OUT = out
    renderer.VERSION = "v0.11"
    table_specs = []
    dataset_headers = ["来源", "实验单位／规模", "处理", "主要估计量"]
    dataset_values = [
        ["GSE146017", "4供体／31文库／27,409基因", "BUD18h；NT/KD×无TNF/TNF", "计数log2FC；交互；四背景响应"],
        ["GSE94335", "13配对供体／26文库（4非哮喘、9致死性哮喘）", "BUD24h；已知3共享细胞系排除", "供体log2(TPM+1)配对差及病组差"],
        ["GSE229084", "A549单细胞系／4batch／47文库", "总窗口18h；DEX暴露2h/18h；3药物", "log2表达效应／药物差中差／暴露条件差"],
        ["GSE34313", "HASM1单细胞系／4未处理+3短+3长数组", "DEX4h/24h；无逐时匹配vehicle", "processed表达差；培养重复Welch"],
    ]
    summary = rows(SOURCE / "evidence_summary.csv")
    candidate_headers = ["基因", "四背景log2FC", "13供体差", "95%CI", "t Holm P", "精确Holm P", "方向"]
    candidate_values = []
    for row in summary:
        measured = bool(row["external_effect"])
        candidate_values.append([
            row["symbol"], number(row["discovery_min_log2FC"]) + "至" + number(row["discovery_max_log2FC"]),
            number(row["external_effect"]),
            number(row["external_ci_low"]) + "至" + number(row["external_ci_high"]) if measured else "不可估计",
            pvalue(row["external_Holm"]) if measured else "1（占位）",
            pvalue(row["external_exact_Holm"]) if measured else "1（占位）",
            f'{row["external_positive"]}↑/{row["external_negative"]}↓' if measured else "缺测",
        ])
    for i, (headers, values, widths) in enumerate([
        (dataset_headers, dataset_values, [2.4, 4.8, 5.1, 4.7]),
        (candidate_headers, candidate_values, [2.1, 3, 1.8, 3.1, 2.3, 2.3, 1.4]),
    ], 1):
        renderer.external_table(f"Table_{i}", headers, values, "Saved public-data estimates; units are not pooled")
        table_specs.append({"id": f"biology_{i}", "headers": headers, "rows": values, "widths_cm": widths})
    text = (out / "manuscript.md").read_text()
    # Make local sources portable to a new manuscript directory as well.
    text = text.replace("paper_cn_v5/figures/", out.name + "/figures/")
    for i, spec in enumerate(table_specs, 1):
        marker = f"::: {{.discovery-table-{i}}}\n:::"
        if text.count(marker) != 1:
            raise ValueError(f"Missing unique table marker {i}")
        text = text.replace(marker, markdown_table(spec["headers"], spec["rows"]))
    (out / "manuscript_expanded.md").write_text(text)
    figure_map = [
        ("Figure_1", "Figure_1_context_response", "图 1 固定候选的四背景响应"),
        ("Figure_2", "Figure_2_external_donors", "图 2 已知重叠排除后的供体配对响应"),
        ("Figure_3", "Figure_4_PER2_GR_time", "图 3 PER2 的 A549 药理干预与暴露条件差异"),
        ("Figure_S1", "Figure_3_paired_measurements", "补充图 S1 重点候选的逐供体测量"),
        ("Figure_S2", "Figure_5_clock_time_arrays", "补充图 S2 HASM1 的 PER2/PER3 暴露条件"),
    ]
    asset_sources = []
    for new_name, old_name, heading in figure_map:
        for ext in ["pdf", "png"]:
            original = SOURCE / "figures" / f"{old_name}.{ext}"
            dest = out / "figures" / f"{new_name}.{ext}"
            dest.write_bytes(original.read_bytes())
            asset_sources.append({"new": record(dest), "source": record(original), "heading": heading})

    supplementary_tables = [
        ("S1", "54基因完整筛选与留一方向", "stable_response_screen.csv",
         "保留全部priority_pass基因，按原最弱Wald统计量排序；留一只检验方向。"),
        ("S2", "12候选四背景模型", "candidate_context_effects.csv",
         "48行；DESeq2与voom各以109,636项校正，供体数可能为3或4。"),
        ("S3", "外部响应及病组差", "external_results.csv",
         "48项原分母；44可估计，缺测P=1为占位；参数和精确各自Holm。"),
        ("S4", "外部逐供体效应", "external_donor_effects.csv",
         "11可测候选×13供体=143行；第12候选缺测在表S3保留校正位置，TPM差不当作count log2FC。"),
        ("S5", "伪计数及留一供体敏感性", "external_sensitivity.csv",
         "参数敏感性与方向，不增加独立供体数量。"),
        ("S6", "A549全部候选DEX及药物交互", "gr_candidate_results.csv",
         "12×4=48项Holm；原过滤、精确逐基因WLS协方差及保存moderation。"),
        ("S7", "A549长暴露边际结果", "gr_late_results.csv",
         "12项Holm；结果后探索，18h指DEX暴露时长。"),
        ("S8", "HASM1全部候选两处理时长", "asm_time_results.csv",
         "24项Holm；共享未处理组，全部精确探针，精确置换不确认全家族时间结果。"),
        ("S9", "两实验直接暴露条件差", "direct_temporal_results.csv",
         "24项Holm，HASM1 DEX24h−4h、A549 post_DMSO−pre_DMSO；非纵向曲线。"),
        ("S10", "完整候选证据摘要", "evidence_summary.csv",
         "全部固定候选，保留缺测及不重复，实验尺度不混合。"),
        ("S11", "外部原基因级测量", "external_gene_measurements.csv",
         "11可测基因×26文库=286测量，供体配对不是文库独立检验。"),
    ]
    table_inventory = []
    for label, title, filename, note in supplementary_tables:
        data = rows(SOURCE / filename)
        if label == "S1":
            data = [r for r in data if r["priority_pass"] == "TRUE"]
        headers = list(data[0])
        renderer.external_table("Table_" + label, headers, [[r[h] for h in headers] for r in data], note)
        table_inventory.append({"label": label, "title": title, "note": note, "rows": len(data),
                                "source": record(SOURCE / filename), "filtered": label == "S1"})
    data = rows(SOURCE / "all_priority_leave_one_donor_out.csv")
    headers = list(data[0])
    renderer.external_table("Table_S1b", headers, [[r[h] for h in headers] for r in data],
                            "54 genes x 4 contexts x 4 leave-one-donor-out fits; direction sensitivity, not independent replication")
    table_inventory.insert(1, {"label": "S1b", "title": "54基因全部留一供体估计", "rows": len(data),
                              "note": "54基因×4背景×4留一拟合，方向敏感性不作为独立实验。",
                              "source": record(SOURCE / "all_priority_leave_one_donor_out.csv"), "filtered": False})

    family_headers = ["阶段", "family项数", "校正", "主要估计目标", "时序与缺失"]
    family_values = [
        ["全基因交互", "82,227", "统一BH", "3交互×27,409基因", "初始扫描；缺失P=1"],
        ["四背景响应DESeq2", "109,636", "统一BH", "4响应×27,409基因", "阴性扫描后探索；非逐背景"],
        ["四背景响应voom", "109,636", "独立一个BH家族", "同来源另一统计模型", "同样本；非独立供体验证"],
        ["外部参数", "48", "Holm", "12候选×4响应/组差", "候选冻结后；缺测4项P=1"],
        ["外部精确", "48", "另一个Holm家族", "同样4对比，符号/标签枚举", "符号可交换假设；缺测不移除"],
        ["A549短暴露/GR药理", "48", "Holm", "12候选×DEX/3药物交互", "原过滤不放宽"],
        ["A549长暴露", "12", "Holm", "长DEX暴露−DMSO", "初步结果后探索"],
        ["HASM1边际", "24", "Holm", "12候选×2时长", "共享未处理；参数及置换"],
        ["直接暴露条件差", "24", "Holm", "12候选×2实验", "边际结果后追加；非严格时间×药物"],
    ]
    renderer.external_table("Table_S12", family_headers, family_values,
                            "Families are stage-specific; confidence intervals are pointwise, not simultaneous")

    supplement = ['---\ntitle: "BioExplainR 中文论文 v0.11：补充材料"\ndate: "2026-10-09"\nlang: zh-CN\n---',
                  "本补充对应生物学主线初稿。S1–S6为分析阶段与复现细节；S13保留前轮共同任务与SPARCL1核验的背景及边界。旧v0.10软件主稿与图表仍独立保留。参考文献[1–11]与主稿一致，S13来源在该节单列。", "# 补充方法"]
    for i, (title, filename) in enumerate([
        ("初始全基因交互方案", "GENOME_PROTOCOL.md"),
        ("四背景响应及候选固定", "RESPONSE_PROTOCOL.md"),
        ("外部供体映射修订", "DONOR_DESIGN_AMENDMENT.md"),
        ("暴露时长探索增补", "RESPONSE_TIME_AMENDMENT.md"),
        ("原执行失败与修订", None),
    ], 1):
        original = SOURCE / "EXECUTION_NOTES.md" if filename is None else ROOT / "research/discovery" / filename
        excerpt = original.read_text().split("\n", 1)[1]
        excerpt = re.sub(r"^## ", "### ", excerpt, flags=re.M)
        supplement.extend([f"## S{i} {title}", "以下为当时方案/修订原文；本稿口径澄清见S6。" +
                           ("该修订先恢复7+9供体，本轮再排除3个已知重叠得到4+9。" if i == 3 else ""), excerpt])
    supplement.extend(["## S6 本稿澄清、检验家族与实现复核",
        "四背景校正每模型统一109,636项；A549短/长DEX暴露总培养窗口均18h，直接对比post_DMSO−pre_DMSO；HASM1缺各时点匹配vehicle。补充表S12列每个校正家族。全部区间为点态95%CI，多个探索阶段未作整体确认性控制。完整问题与完成标准见ISSUES.md。",
        "保存环境：R4.3.3、DESeq2 1.42.0、edgeR4.0.16、limma3.58.1；BioExplainR0.4.0.9000以实际源码载入，9 context、0在线调用。原numeric_audit.json与external_r_audit.json记录原计数/数组/WLS及原TPM独立实现核验；不称跨语言重新估计所有拟合参数。原analysis/candidate/gr/time/direct_temporal_freeze.json保留阶段和实际UTC。新稿audit及manifest绑定表/图/原封存输入，复核无需重新拟合。",
        "# 补充结果", "## 原始测量与暴露条件",
        "补充图S1展示PER2、PER3、METTL7A、MAOA、ANGPTL2、FSTL3全部13供体测量，供体效应与原测量见补充表S4/S11。补充图S2展示HASM1的PER2/PER3各数组，未处理4、DEX4h3、24h3；直接条件差见补充表S9，参数显著与精确检验限制分别报告。",
        "## 补充表及来源"])
    for item in table_inventory:
        supplement.extend([f'### 补充表 {item["label"]} {item["title"]}',
                           f'{item["note"]} 共{item["rows"]}行。文件：`tables/Table_{item["label"]}.csv`及同名XLSX；来源：`{item["source"]["path"]}`。'])
    supplement.extend(["### 补充表 S12 检验家族与时序", "9阶段定义见`tables/Table_S12.csv`与XLSX。缺失占位、结果后追加及同来源模型均明确标注；不把这些阶段合并为一次预注册研究。",
                       "# S13 前轮共同任务与 SPARCL1/ChIP 背景"])
    old_addendum = ROOT / "docs/research_followup_v1/research_addendum.md"
    background = old_addendum.read_text().split("# 1 正式共同任务比较", 1)[1]
    background = "## S13.1 正式共同任务比较" + background
    background = background.replace("# 2 GR干预重分析：候选不可估计", "## S13.2 SPARCL1的GR检验不可估计")
    background = background.replace("# 3 ChIP峰与参考基因组核实", "## S13.3 ChIP峰与参考基因组核实")
    background = background.replace("# 4 可支持结论与复现入口", "## S13.4 背景结果边界")
    background = background.replace("# 参考来源", "## S13.5 背景参考来源")
    for i, suffix in enumerate(["a", "b", "c", "d"], 1):
        background = background.replace(f"表 F{i}", f"补充表 S13{suffix}").replace(f"表F{i}", f"补充表S13{suffix}")
    background = background.replace("正式论文仍为v0.10，本件为可编辑研究增补", "以上为前轮v0.10配套研究增补的历史结果，本稿为v0.11生物学主线")
    supplement.extend(["本节来自保存的前轮研究增补，未产生新性能运行或SPARCL1／ChIP统计。其软件指标不能作为PER2生物学机制证据。下列四内嵌表原数值保留，电子表复用原CSV，文件F1_common_task、F2_paired_bootstrap、F3_receptor_control、F4_chip_primary分别对应S13a–d。", background])
    for p in sorted((ROOT / "docs/research_followup_v1/tables").glob("*")):
        if p.suffix not in [".csv", ".xlsx"]:
            continue
        (out / "tables" / p.name).write_bytes(p.read_bytes())
    # Render the four historical Markdown tables with the existing native Word renderer.
    historical_specs = []
    historical_tables = re.findall(r"\n(\|[^\n]+\|\n\|[-| ]+\|\n(?:\|[^\n]+\|\n)+)", background)
    if len(historical_tables) != 4:
        raise ValueError("Expected four saved background tables")
    for i, table in enumerate(historical_tables):
        lines = table.strip().splitlines()
        values = [[cell.strip() for cell in line.strip("|").split("|")] for line in lines]
        headers, data = values[0], values[2:]
        historical_specs.append({"id": f"background_{i}", "headers": headers, "rows": data,
                                 "widths_cm": [17 / len(headers)] * len(headers)})
    supplement.append("# 补充图")
    for name, old_name, heading in figure_map[3:]:
        note = ("每线为一个供体，同一供体两文库不计为两人。各基因使用log2(TPM+1)原测量，全部候选测量见表S11。" if name == "Figure_S1" else
                "单HASM1细胞系培养重复；共享未处理组不是各时点匹配vehicle。参数直接差通过校正，精确置换全family不能确认，非节律相位/振幅证据。")
        supplement.extend(["## " + heading, f"![{heading}]({out.name}/figures/{name}.png){{width=16cm}}", note])
    (out / "supplementary.md").write_text("\n\n".join(supplement) + "\n")
    main = renderer.export(out / "manuscript_expanded.md", "BioExplainR-中文论文-v0.11", table_specs,
                           {heading: out / f"figures/{name}.pdf" for name, old_name, heading in figure_map[:3]})
    additional = renderer.export(out / "supplementary.md", "BioExplainR-补充材料-v0.11", historical_specs,
                                 {heading: out / f"figures/{name}.pdf" for name, old_name, heading in figure_map[3:]})
    write_json(out / "export_report.json", {"status": "pass", "created_utc": datetime.now(timezone.utc).isoformat(),
               "main": main, "supplement": additional, "research_refitted": False,
               "figure_mode": "Original vector PDFs embedded in final PDF; PNG previews in DOCX/HTML"})
    write_json(out / "assets_manifest.json", {"figures": asset_sources, "supplementary_tables": table_inventory,
               "files": [record(p) for sub in ["figures", "tables"] for p in sorted((out / sub).rglob("*")) if p.is_file()],
               "background_source": record(old_addendum)})
    print(json.dumps({"main": main, "supplement": additional}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--directory", type=Path, default=ROOT / "docs/paper_cn_v5")
    parser.add_argument("--refresh", action="store_true", help="Re-export this unsealed draft after source edits")
    args = parser.parse_args()
    build(args.directory, args.refresh)
