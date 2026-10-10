"""Build a complete BioExplainR user guide from the package's Rd files.

The guide deliberately derives the public-function reference from NAMESPACE and
man/*.Rd so the uploaded documentation stays aligned with the installable
package.  It is a user-facing guide, not a replacement for the Rd help pages.
"""
from pathlib import Path
import re
import subprocess

from docx import Document
from docx.enum.section import WD_SECTION
from docx.enum.style import WD_STYLE_TYPE
from docx.oxml.ns import qn
from docx.shared import Cm, Pt

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs/BioExplainR-user-guide.docx"


def read_namespace_exports():
    text = (ROOT / "NAMESPACE").read_text(encoding="utf-8")
    return re.findall(r"^export\(([^)]+)\)$", text, flags=re.MULTILINE)


def balanced_value(text, marker):
    start = text.find(marker)
    if start < 0:
        return ""
    brace = text.find("{", start)
    if brace < 0:
        return ""
    depth = 0
    escaped = False
    for i in range(brace, len(text)):
        char = text[i]
        if escaped:
            escaped = False
            continue
        if char == "\\":
            escaped = True
            continue
        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return text[brace + 1:i]
    return ""


def clean_rd(value):
    value = re.sub(r"\\code\{([^{}]*)\}", r"`\1`", value)
    value = re.sub(r"\\link(?:\[[^]]+\])?\{([^{}]*)\}", r"\1", value)
    value = re.sub(r"\\pkg\{([^{}]*)\}", r"\1", value)
    value = re.sub(r"\\emph\{([^{}]*)\}", r"\1", value)
    value = re.sub(r"\\strong\{([^{}]*)\}", r"\1", value)
    value = re.sub(r"\\R\{\}", "R", value)
    value = re.sub(r"\\(url|href)\{([^{}]*)\}(?:\{([^{}]*)\})?", r"\2", value)
    value = re.sub(r"\\describe\{([^{}]*)\}", r"\1", value)
    value = re.sub(r"\\item\[([^]]+)\]", r"\n\1: ", value)
    value = re.sub(r"\\item", "\n- ", value)
    value = re.sub(r"\\[a-zA-Z]+\s*", "", value)
    value = (value.replace("\\%", "%").replace("\\_", "_").replace("\\&", "&")
             .replace("\\$", "$").replace("\\#", "#").replace("\\{", "{")
             .replace("\\}", "}").replace("\\\\", "\\"))
    value = value.replace("{", "").replace("}", "")
    value = re.sub(r"\n{3,}", "\n\n", value)
    return value.strip()


def rd_info(name):
    path = ROOT / "man" / f"{name}.Rd"
    if not path.exists():
        candidates = list((ROOT / "man").glob("*.Rd"))
        path = next((p for p in candidates if f"\\alias{{{name}}}" in p.read_text(encoding="utf-8")), path)
    if not path.exists():
        return {"title": name, "usage": f"{name}(...)" , "description": "See package help."}
    text = path.read_text(encoding="utf-8")
    return {
        "title": clean_rd(balanced_value(text, "\\title")) or name,
        "usage": clean_rd(balanced_value(text, "\\usage")) or f"{name}(...)",
        "arguments": clean_rd(balanced_value(text, "\\arguments")),
        "description": clean_rd(balanced_value(text, "\\description")),
        "details": clean_rd(balanced_value(text, "\\details")),
        "value": clean_rd(balanced_value(text, "\\value")),
        "examples": clean_rd(balanced_value(text, "\\examples")),
    }


GROUPS = [
    ("模型配置与调用", ["bio_config", "bio_configure", "bio_get_config", "bio_reset_config", "bio_presets", "bio_register_preset", "bio_unregister_preset", "bio_endpoint_url", "bio_llm_available", "bio_build_request", "bio_llm_chat", "bio_parse_response", "bio_redact"]),
    ("对象解析与解释", ["bio_context", "new_bio_context", "bio_context_payload", "bio_adapters", "bio_register_adapter", "bio_unregister_adapter", "bio_explain", "bio_validate_explanation"]),
    ("证据与来源", ["bio_evidence", "bio_evidence_register", "bio_evidence_list", "bio_evidence_clear", "bio_evidence_lookup", "bio_register_evidence_provider", "bio_fetch_evidence", "bio_evidence_for_context", "bio_evidence_providers", "bio_register_live_providers", "bio_evidence_cache_clear", "bio_go_annotations", "bio_dependency_provenance"]),
    ("图形与结果核对", ["bio_plot", "bio_plot_pca", "bio_plot_umap", "bio_plot_enrichment", "bio_plot_heatmap", "bio_cross_check", "bio_cell_proportions"]),
    ("运行记录、诊断与修复", ["bio_record", "bio_record_code", "bio_records", "bio_value", "bio_last_error", "bio_explain_error", "bio_suggest_fix", "bio_validate_fix", "bio_invariant", "inv_class", "inv_has_columns", "inv_nrow", "inv_same_nrow_as_input", "inv_factor_levels", "inv_no_na", "inv_equal"]),
    ("运行环境、项目与报告", ["bio_runtime_info", "bio_object_inventory", "bio_package_usage", "bio_project", "bio_explain_project", "bio_report"]),
    ("教学与评估", ["bio_question_bank", "bio_quiz", "bio_grade", "bio_review_rubric", "bio_benchmark", "bio_benchmark_fixes", "bio_evaluate_experts", "bio_evaluate_learning", "bio_plan_learning_study", "bio_randomize_learning_study"]),
    ("本地 Shiny 工作台", ["bio_run_app"]),
]

CORE_FUNCTIONS = [
    "bio_configure", "bio_context", "bio_explain", "bio_report", "bio_record",
    "bio_explain_error", "bio_suggest_fix", "bio_validate_fix", "bio_project",
    "bio_run_app",
]

GROUP_LABELS = {
    "模型配置与调用": "进阶：模型配置与调用",
    "对象解析与解释": "进阶：对象解析与适配器",
    "证据与来源": "进阶：证据与来源",
    "图形与结果核对": "进阶：图形与结果核对",
    "运行记录、诊断与修复": "进阶：运行记录、诊断与修复",
    "运行环境、项目与报告": "进阶：运行环境、项目与报告",
    "教学与评估": "扩展：教学与评估接口",
    "本地 Shiny 工作台": "核心入口：本地 Shiny 工作台",
}


def configure_doc():
    doc = Document()
    section = doc.sections[0]
    section.top_margin = section.bottom_margin = Cm(1.8)
    section.left_margin = section.right_margin = Cm(2.0)
    styles = doc.styles
    styles["Normal"].font.name = "Calibri"
    styles["Normal"]._element.rPr.rFonts.set(qn("w:eastAsia"), "Noto Sans CJK SC")
    styles["Normal"].font.size = Pt(10.5)
    styles["Normal"].paragraph_format.space_after = Pt(5)
    for style_name, size in [("Title", 20), ("Heading 1", 15), ("Heading 2", 12), ("Heading 3", 10.5)]:
        style = styles[style_name]
        style.font.name = "Calibri"
        style._element.rPr.rFonts.set(qn("w:eastAsia"), "Noto Sans CJK SC")
        style.font.size = Pt(size)
        style.paragraph_format.keep_with_next = True
    if "Code Guide" not in [s.name for s in styles]:
        code = styles.add_style("Code Guide", WD_STYLE_TYPE.PARAGRAPH)
        code.font.name = "DejaVu Sans Mono"
        code._element.rPr.rFonts.set(qn("w:eastAsia"), "Noto Sans CJK SC")
        code.font.size = Pt(8.5)
        code.paragraph_format.left_indent = Cm(.5)
        code.paragraph_format.space_after = Pt(5)
    return doc


def add_code(doc, text):
    paragraph = doc.add_paragraph(style="Code Guide")
    paragraph.add_run(text.strip())


def add_bullets(doc, text):
    for line in text.splitlines():
        line = line.strip()
        if line:
            doc.add_paragraph(line, style="List Bullet")


def build():
    exports = read_namespace_exports()
    docs = {name: rd_info(name) for name in exports}
    doc = configure_doc()
    doc.add_heading("BioExplainR 用户使用说明", 0)
    doc.add_paragraph("版本 0.3.1；任务导向版使用指南；生成日期 2026-10-05")
    doc.add_paragraph("本指南先给出最小工作流，再把其余公开函数按进阶、扩展和教学模块归类。完整函数签名仍以包内的 R help 页面为准；本文件不重复粘贴每个 alias 的完整 Rd 文本。")

    doc.add_heading("1. 软件定位与最小可用接口", 1)
    doc.add_paragraph("BioExplainR 是已有生物信息学 R 对象的解释与检查层。它先在 R 中从完整输入计算事实，再由本地模板或用户配置的模型组织语言。模型不替代差异表达计数、阈值筛选、方差解释率、细胞数或其他统计计算。")
    doc.add_paragraph("默认模型输入是有界 JSON 摘要：确定性 facts、来源状态、不确定性和有限 top-feature 预览。默认不发送完整表达矩阵、细胞条码、样本/患者名称或 API key。")
    doc.add_paragraph("初学者先记住下面 10 个函数；它们覆盖配置、对象解释、报告、运行记录、错误诊断、修复验证、项目整合和网页入口。")
    quick_table = doc.add_table(rows=1, cols=3)
    quick_table.style = "Light Shading Accent 1"
    for cell, text in zip(quick_table.rows[0].cells, ["函数", "什么时候用", "最小示例"]):
        cell.text = text
    quick_rows = [
        ("bio_configure", "设置 local 或模型连接", "bio_configure(\"local\")"),
        ("bio_context", "从对象计算可检查事实", "ctx <- bio_context(res)"),
        ("bio_explain", "生成离线或模型组织的解释", "ex <- bio_explain(ctx, use_llm = FALSE)"),
        ("bio_report", "导出 HTML/Markdown 报告", "bio_report(ex, file = \"report.html\")"),
        ("bio_record", "记录一段 R 代码及状态", "run <- bio_record({ result <- 1 + 1; result })"),
        ("bio_explain_error", "解释一次失败的运行", "bio_explain_error(run)"),
        ("bio_suggest_fix", "给出未验证修复建议", "bio_suggest_fix(run)"),
        ("bio_validate_fix", "按显式不变量检查修复", "bio_validate_fix(quote(...), invariants = ...)"),
        ("bio_project", "组织多个有依赖的结果", "project <- bio_project(list(...))"),
        ("bio_run_app", "启动本地 Shiny 工作台", "bio_run_app()"),
    ]
    for row in quick_rows:
        cells = quick_table.add_row().cells
        for cell, text in zip(cells, row): cell.text = text

    doc.add_heading("2. 安装与 5 分钟快速上手", 1)
    doc.add_paragraph("从本地源码包安装。代码块使用普通 R 语法，可直接复制到干净 R session；注释统一为中文。")
    add_code(doc, "install.packages(\"BioExplainR_0.3.1.tar.gz\", repos = NULL, type = \"source\")\nlibrary(BioExplainR)\npackageVersion(\"BioExplainR\")")
    doc.add_paragraph("已有 DESeq2 结果时，最短流程如下。完整数据分析和设计判断仍由用户负责。")
    add_code(doc, "library(BioExplainR)\nbio_configure(\"local\")\nres <- DESeq2::results(dds, contrast = c(\"condition\", \"treated\", \"control\"))\nex <- bio_explain(res, species = \"Homo sapiens\",\n                  contrast = \"treated vs control\", use_llm = FALSE)\nbio_report(ex, file = \"report.html\")")
    doc.add_paragraph("如果只有普通差异表达 data.frame，也可以直接传给 bio_explain()。R 仍会先计算 facts；来源包不明确时，结果会标记为 inferred 或 unknown。")
    add_code(doc, "deg <- data.frame(log2FoldChange = c(2.1, -1.5, 0.2, 3),\n                  pvalue = c(1e-5, 1e-3, 0.5, 0.01),\n                  padj = c(4e-4, 0.01, 0.8, 0.06),\n                  row.names = c(\"IL6\", \"SOX2\", \"ACTB\", \"CXCL8\"))\nctx <- bio_context(deg, thresholds = list(padj = 0.05, lfc = 1))\nctx$facts\nex <- bio_explain(ctx, use_llm = FALSE)\nbio_report(ex, file = \"bioexplainr_report.html\")")

    doc.add_heading("3. 对象、语言和模型配置", 1)
    doc.add_paragraph("bio_context() 可自动识别 DESeq2、limma、edgeR、富集结果、Seurat、SingleCellExperiment、SummarizedExperiment、Biobase ExpressionSet、prcomp、ggplot 和矩阵。只有在普通表格有歧义时才需要 analysis_type；多系数 limma 拟合必须提供 coefficient。bio_plot_pca() 的参数名 scale. 保持与 stats::prcomp 一致，表示是否按特征标准化。")
    add_code(doc, "# 默认 English；需要中文时显式选择 language = \"zh\"\nex_en <- bio_explain(deg, language = \"en\", use_llm = FALSE)\nex_zh <- bio_explain(deg, language = \"zh\", use_llm = FALSE)\n\n# 模型配置只使用环境变量中的 key\nbio_configure(\"openai_compatible\",\n              base_url = \"https://your-proxy.example/v1\",\n              api_key_env = \"BIOEXPLAINR_API_KEY\",\n              model = \"your-model-id\")\nbio_llm_available(reason = TRUE)\nbio_get_config()\nbio_reset_config()")

    doc.add_heading("4. 图形、证据和项目报告", 1)
    add_code(doc, "pca_plot <- bio_plot_pca(expression_matrix, metadata = sample_info, group = \"condition\")\nembedding <- bio_plot_umap(umap_coordinates, metadata = cell_metadata, group = \"cluster\")\ndot <- bio_plot_enrichment(ora, top_n = 20)\nheat <- bio_plot_heatmap(expression_matrix, top_n = 30)\ncheck <- bio_cross_check(volcano_plot, deg)\n\nev <- bio_evidence(\"GO\", id = \"GO:0006954\",\n                   title = \"inflammatory response\",\n                   claim = \"user-checked annotation\", type = \"database\")\nex_ev <- bio_explain(ctx, evidence = list(ev), use_llm = FALSE)\n\nproject <- bio_project(list(deg = ex, plot = bio_explain(pca_plot, use_llm = FALSE)),\n                       dependencies = list(plot = \"deg\"))\nbio_report(bio_explain_project(project), file = \"project.html\")")
    doc.add_paragraph("公共检索必须显式调用 bio_fetch_evidence()；命中记录不等于论文全文支持。图形核对只检查保存的映射和源对象范围，不替代统计或视觉审查。")

    doc.add_heading("5. 记录、常见错误与修复", 1)
    add_code(doc, "run <- bio_record({\n  # 在这里写入需要记录的分析代码\n  result <- mean(c(1, 2, 3))\n  result\n}, purpose = \"示例计算\")\n\nbio_records()\nbio_last_error()\nbio_explain_error(run)\nbio_suggest_fix(run)\n\ncoldata <- data.frame(condition = c(\"treated\", \"control\", \"treated\", \"control\"))\nv <- bio_validate_fix(\n  quote({ coldata$condition <- relevel(factor(coldata$condition), ref = \"control\"); coldata }),\n  inputs = list(coldata = coldata),\n  invariants = list(inv_factor_levels(\"condition\", c(\"control\", \"treated\")),\n                    inv_same_nrow_as_input(\"coldata\")))\nv$status")
    for title, detail in [
        ("无法识别对象类型", "先运行 class(x) 和 names(x)，再用 analysis_type 明确选择；普通 data.frame 的列名不能证明其来源包。"),
        ("use_llm = TRUE 但没有配置", "先运行 bio_configure(\"local\") 使用离线解释，或提供 base_url、model 和 api_key_env；不要把 key 写进脚本。"),
        ("bio_fetch_evidence() 网络失败", "检查网络、来源 ID 和服务状态；先保存用户提供的证据对象，或在无网络模式下跳过检索。"),
        ("bio_validate_fix() 不变量失败", "先查看 result$status、invariants 和 output_summary；运行成功不代表满足行数、因子水平或列结构要求。"),
        ("bio_report() 路径或乱码错误", "使用可写的绝对路径，确认目录存在；在 UTF-8 R session 中重新导出，并检查报告中的来源和语言。"),
    ]:
        doc.add_heading(title, 3)
        doc.add_paragraph(detail)
    doc.add_paragraph("bio_validate_fix() 在独立 R 进程运行，但不是操作系统安全沙箱。代码仍可能读写文件和访问网络；不要直接运行未经阅读的模型生成代码。")

    doc.add_heading("6. Shiny 工作台与安全边界", 1)
    add_code(doc, "install.packages(\"shiny\")\nlibrary(BioExplainR)\nbio_run_app(host = \"127.0.0.1\", launch.browser = TRUE)")
    doc.add_paragraph("默认 host = 127.0.0.1，只监听本机。若改为 0.0.0.0 或公网 IP，必须由用户自行配置认证、TLS 和反向代理；Shiny 不是多租户隔离。不同浏览器连接的工作区可分开，但仍共享 R 进程的包、网络和文件权限。")

    doc.add_heading("7. 进阶、扩展与教学模块", 1)
    doc.add_paragraph("其余公开函数按任务分组列出。每个函数只保留一次短条目；同一 Rd 文件中的 alias 不重复展开。需要完整参数、返回值和边界条件时，请运行 ?函数名。教学函数不属于核心解释流程，正式软件使用建议先阅读核心章节。")
    assigned = set(CORE_FUNCTIONS)
    for title, names in GROUPS:
        label = GROUP_LABELS.get(title, title)
        visible = [name for name in names if name in docs and name not in assigned]
        if not visible:
            continue
        doc.add_heading(label, 2)
        for name in visible:
            assigned.add(name)
            info = docs[name]
            doc.add_paragraph(f"{name}：{info['title']}")
            add_code(doc, info["usage"])
    remaining = [name for name in exports if name not in assigned]
    if remaining:
        doc.add_heading("扩展：其他导出函数", 2)
        for name in remaining:
            info = docs[name]
            doc.add_paragraph(f"{name}：{info['title']}")
            add_code(doc, info["usage"])

    doc.add_heading("8. 运行前检查清单", 1)
    doc.add_paragraph("先确认对象 class、物种、样本/供体、比较方向、批次和阈值；再查看 ctx$facts、ctx$uncertainty 和 ctx$provenance。模型组织的文字不等于独立真值；发布报告前应人工核对自由文本、证据适用性和实验设计。")
    doc.add_paragraph("许可证：MIT。包版本：BioExplainR 0.3.1。服务器验证环境：R 4.3.3。")
    doc.save(OUT)
    print(f"Wrote {OUT} with {len(exports)} exported-function entries")


if __name__ == "__main__":
    build()
