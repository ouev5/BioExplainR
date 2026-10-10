"""Build v0.12 from the complete-set analysis and preserved public-validation results."""
import argparse
import json
import re
import sys
import subprocess
from pathlib import Path
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import fitz
from docx.oxml import OxmlElement
from docx.oxml.ns import qn

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/"research/discovery"))
from set_validation import rows
from validation_sources import record,utc
import build_revision as renderer
from build_discovery_paper import markdown_table

SET=ROOT/"research/results/discovery_set_validation_v1"
OLD=ROOT/"docs/paper_cn_v5"
VALIDATION=ROOT/"research/results/discovery_validation_v2"


def export_set(out,source,name,specs,figures):
    text=source.read_text();digits=str.maketrans("⁰¹²³⁴⁵⁶⁷⁸⁹","0123456789")
    text=re.sub(r"10⁻([⁰¹²³⁴⁵⁶⁷⁸⁹]+)",lambda m:"10^-"+m[1].translate(digits)+"^",text)
    rendered=out/(source.stem+"_rendered.md");rendered.write_text(text)
    base=["pandoc",str(rendered),"--standalone",f"--resource-path={ROOT/'docs'}:{ROOT}"]
    ast=json.loads(subprocess.check_output(base+["-t","json"]))
    doc=renderer.native_docx(ast,out/(name+".docx"),specs,legacy_layout=False)
    for style in doc.styles:
        if style.name.startswith("Heading"):
            pr=style.element.get_or_add_pPr();existing=pr.find(qn("w:numPr"))
            if existing is not None:pr.remove(existing)
            num=OxmlElement("w:numPr");ident=OxmlElement("w:numId");ident.set(qn("w:val"),"0");num.append(ident);pr.append(num)
    for p in doc.paragraphs:
        if p.style.name.startswith("Heading") and p.text in figures:p.paragraph_format.page_break_before=True
    doc.save(out/(name+".docx"))
    subprocess.run(base+["--embed-resources",f"--css={out/'paper.css'}","-o",str(out/(name+".html"))],check=True)
    intermediate=out/"rendered_docx";intermediate.mkdir(exist_ok=True)
    subprocess.run(["libreoffice","-env:UserInstallation=file:///tmp/opencode/bioexplainr-paper-v012-lo","--headless","--convert-to","pdf","--outdir",str(intermediate),str(out/(name+".docx"))],check=True,timeout=180)
    replaced=[]
    with fitz.open(intermediate/(name+".pdf")) as pdf:
        for page in pdf:
            images=page.get_image_info(xrefs=True)
            if not images:continue
            # PDF wraps long headings and may insert spaces; compare normalized text.
            normalized=re.sub(r"\s","",page.get_text())
            matches=[caption for caption in figures if re.sub(r"\s","",caption) in normalized]
            if len(matches)!=1 or len(images)!=1:raise ValueError(f"Ambiguous figurepage{page.number+1}:{matches},images{len(images)}")
            rect=fitz.Rect(images[0]["bbox"]);page.add_redact_annot(rect,fill=(1,1,1));page.apply_redactions(images=2,graphics=0,text=0)
            with fitz.open(figures[matches[0]]) as original:page.show_pdf_page(rect,original,0,keep_proportion=True)
            replaced.append(dict(caption=matches[0],page=page.number+1,pdf=record(figures[matches[0]])))
        assert len(replaced)==len(figures)
        pdf.set_metadata(dict(title=name,author="",subject="BioExplainR v0.12 public-data exploration"))
        pdf.save(out/(name+".pdf"),garbage=4,deflate=True)
        return dict(name=name,pages=len(pdf),docx_tables=len(doc.tables),figures=len(doc.inline_shapes),vector_figures=replaced)


def draw_figures(out):
    plt.rcParams.update({"font.family":"DejaVu Sans","font.size":8.5,"pdf.fonttype":42,"axes.spines.top":False,"axes.spines.right":False})
    summary=rows(SET/"set_summary.csv");effects=rows(SET/"tpm_donor_effects.csv")
    fig,axes=plt.subplots(1,2,figsize=(11,11));fig.subplots_adjust(left=.13,right=.97,bottom=.06,top=.94,wspace=.39)
    for ax,genes in zip(axes,[summary[:27],summary[27:]]):
        for i,r in enumerate(genes):
            vals=[float(s["effect"]) for s in effects if s["feature_id"]==r["feature_id"] and s["contrast"]=="GC_control"]
            color="#247b60" if r["robust_supported"]=="True" else "#8e969b"
            if vals:
                ax.scatter(vals,[i+(j-2.5)*.035 for j in range(len(vals))],s=12,color=color,alpha=.7)
                ax.scatter([np.mean(vals)],[i],marker="s",s=19,color="#152e3b")
            else:ax.text(0,i,"not measured",va="center",fontsize=7.5,color="#757575")
        ax.set_yticks(range(27),[r["symbol"]+(" / METTL7A" if r["symbol"]=="TMT1A" else " / ARNTL" if r["symbol"]=="BMAL1" else "") for r in genes])
        for label,r in zip(ax.get_yticklabels(),genes):label.set_color("#247b60" if r["robust_supported"]=="True" else "#747b81")
        ax.invert_yaxis();ax.axvline(0,color="#b8bfc4",linestyle="--",lw=.8);ax.set_xlim(-3.3,5)
        ax.grid(axis="x",alpha=.12);ax.set_xlabel("Within-donor BUD - vehicle, log2(TPM+1)")
    fig.suptitle("Original 54-gene set: six adult ASM donors\n53 measured; 53 mean directions retained; 45 pass combined sensitivity criteria",fontsize=11)
    fig.savefig(out/"figures/Figure_2.pdf");fig.savefig(out/"figures/Figure_2.png",dpi=190);plt.close(fig)
    fig,ax=plt.subplots(figsize=(10.5,6.4));ax.axis("off")
    cards=[("Adult ASM late response","GSE94335: 13 paired donors, known overlap removed\nGSE130715: six adults, full set 45/54 supported\nPER2/PER3 lower at measured late endpoints",True),
           ("Clock-related transcription","BMAL1/NPAS2 higher; NR1D2/DBP/TEF lower\nLINC00607 newly measurable in GSE130715\nSingle endpoint: phase/amplitude not estimated",True),
           ("Early response and drug x time","4h / 8h ASM PER2: not confirmed after correction\nAdult pulse 24h drug contrast: published P=.7831\nNo individual Ct for a new time x drug estimate",False),
           ("GR evidence","A549 short-exposure pharmacological interactions\nU2OS rescue variants: PER2 not confirmed\nPER1 control does not replace candidate causality",False),
           ("Human protein","METTL7A: complete original LFQ arrays acquired\n7 raw labels / 6 published; 72h subset supported\n24h subset and exact corrections not confirmed",True),
           ("Candidate function","No adult ASM candidate contraction / Ca2+ endpoint\nGNAS, GR cAMP and fetal clock studies are distinct\nNo functional or clinical causal claim",False)]
    for i,(title,body,support) in enumerate(cards):
        col=i%2;row=i//2;x=.025+col*.5;y=.96-row*.31;color="#eaf4f0" if support else "#f1f3f5"
        ax.add_patch(plt.Rectangle((x,y-.27),.465,.265,transform=ax.transAxes,facecolor=color,edgecolor="#bdcbd1",lw=.8))
        ax.text(x+.014,y-.035,title,transform=ax.transAxes,weight="bold",fontsize=10,color="#254d5d",va="top")
        ax.text(x+.014,y-.094,body,transform=ax.transAxes,fontsize=8.6,linespacing=1.8,va="top")
    fig.subplots_adjust(left=.02,right=.98,bottom=.02,top=.98)
    fig.savefig(out/"figures/Figure_3.pdf");fig.savefig(out/"figures/Figure_3.png",dpi=190);plt.close(fig)
    protein=rows(SET/"unselected_protein/donor_effects.csv")
    fig,axes=plt.subplots(1,2,figsize=(10,4.7));fig.subplots_adjust(left=.1,right=.98,bottom=.21,top=.80,wspace=.35)
    for ax,time in zip(axes,[24,72]):
        data=[r for r in protein if r["symbol"]=="TMT1A" and int(r["time_h"])==time and r["status"]=="paired"]
        for i,r in enumerate(data):
            extra=r["donor"]=="10.09.19";ax.scatter([i],[float(r["effect"])],color="#d38638" if extra else "#247b60",s=42,marker="D" if extra else "o")
        ax.axhline(0,color="#adb9bf",lw=.8);ax.set_xticks(range(len(data)),[r["donor"] for r in data],rotation=55,ha="right",fontsize=8)
        ax.set_title(f"METTL7A/TMT1A {time}h: all seven raw labels",fontsize=10)
        ax.set_ylabel("Paired mean log2LFQ: DEX - control");ax.grid(axis="y",alpha=.12)
    fig.suptitle("Complete unselected LFQ; technical replicates averaged, zeros missing\nOrange: extra raw label absent from published six-donor subset; age/QC unresolved",fontsize=10)
    fig.savefig(out/"figures/Figure_S4.pdf");fig.savefig(out/"figures/Figure_S4.png",dpi=190);plt.close(fig)


def build(out,refresh=False):
    if (out/"manuscript_manifest.json").exists():raise ValueError("Refusing sealed manuscript")
    if (out/"export_report.json").exists() and not refresh:raise ValueError("Use --refresh only unsealed draft")
    for name in ["figures","tables","evidence"]:(out/name).mkdir(exist_ok=refresh)
    (out/"paper.css").write_bytes((OLD/"paper.css").read_bytes())
    renderer.OUT=out;renderer.VERSION="v0.12"
    # Old electronic tables retain original bytes, including corrected original-family values.
    copied=[]
    for p in sorted((OLD/"tables").glob("*")):
        if p.suffix not in [".csv",".xlsx"] or p.name.startswith(("Table_1.","Table_2.")):continue
        target=out/"tables"/p.name;target.write_bytes(p.read_bytes());copied.append(dict(new=record(target),source=record(p)))
    counts=json.loads((SET/"numeric_audit.json").read_text())["set_counts"]
    dataset_headers=["来源","单位／规模","处理与估计目标"]
    dataset_values=[
        ["GSE146017","4供体／31文库","18hBUD；NT/CEBPD×TNF；全基因交互/响应"],
        ["GSE94335","13配对供体／26文库","24hBUD；3已知共享培养系排除；旧12候选"],
        ["GSE130715","6成人19–54岁／24文库","24hBUD×GNAS；完整54基因响应检查"],
        ["GSE229084／34313","A549四batch；HASM1单培养系","药理交互／直接暴露条件差，非成人轨迹"],
        ["GSE13168／135730","3配对供体；匿名3培养/条件","8hFP/PKI；4hDEX/IL17；年龄界限保留"],
        ["Bartman2021成人","33–77岁来源池；n4–6/条件","DEX30min脉冲后12/16/20/24h；原Tukey表"],
        ["GSE342887／342771","U2OS单细胞系；18/17文库","GR-KO rescue WT/AF2/IDR；缺empty-KO"],
        ["PXD033514／033534","HTPC六供体；3技术重复先平均","DEX24/72h；跨组织人源蛋白"]]
    count_headers=["检查层级","通过／54冻结","可测分母及解释"]
    count_values=[["可测",str(counts["tpm_measurable"])+"/54","53/54；LINC03140缺测"],
        ["平均方向一致",str(counts["same_direction"])+"/54","53/53可测"],
        ["全部六供体预期方向",str(counts["all_six_expected"])+"/54","50/53可测"],
        ["配对t／Holm54",str(counts["tpm_pass"])+"/54","45/53可测；点态CI"],
        ["计数模型／Holm54",str(counts["count_pass"])+"/54","51/53可估计；同六供体"],
        ["TPM／计数留一方向",f'{counts["tpm_sensitivity_direction"]}/{counts["count_leave_one_direction"]}',"各52/53；非独立重复"],
        ["综合支持",str(counts["robust_supported"])+"/54","45/53；两模型/六供体/全部敏感性"],
        ["精确符号翻转／Holm54",str(counts["exact_holm_pass"])+"/54","最小双侧P=.03125；未确认"]]
    summary=rows(SET/"set_summary.csv")
    focus=[r for r in summary if r["symbol"] in ["PER2","PER3","TEF","BMAL1","NPAS2","NR1D2","DBP","LINC00607"]]
    focus_headers=["基因","TPM配对差","点态95%CI","Holm54 P","计数效应","计数Holm54 P"]
    focus_values=[[r["symbol"],f'{float(r["tpm_effect"]):.3f}',f'{float(r["tpm_ci_low"]):.3f}至{float(r["tpm_ci_high"]):.3f}',
                   f'{float(r["tpm_holm54"]):.3g}',f'{float(r["count_effect"]):.3f}',f'{float(r["count_holm54"]):.3g}'] for r in focus]
    specs=[]
    for i,(headers,values,widths) in enumerate([(dataset_headers,dataset_values,[3.2,4.5,9.3]),(count_headers,count_values,[5.7,3.3,8]),
                                              (focus_headers,focus_values,[2,2.5,4,2.5,3,3])],1):
        renderer.external_table(f"Table_{i}",headers,values,"v0.12 source-bound estimates; pointwise CI, separate families")
        specs.append(dict(id=f"set_{i}",headers=headers,rows=values,widths_cm=widths))
    text=(out/"manuscript.md").read_text()
    for i,spec in enumerate(specs,1):
        marker=f"::: {{.set-table-{i}}}\n:::";assert text.count(marker)==1
        text=text.replace(marker,markdown_table(spec["headers"],spec["rows"]))
    (out/"manuscript_expanded.md").write_text(text)
    figure_sources=[]
    for name,source in [("Figure_1",OLD/"figures/Figure_1"),("Figure_S1",OLD/"figures/Figure_2"),
                        ("Figure_S2",OLD/"figures/Figure_3"),
                        ("Figure_S3",ROOT/"docs/biology_validation_v2/figures/Figure_2_GR_genetics")]:
        for ext in ["pdf","png"]:
            original=source.with_suffix("."+ext);target=out/"figures"/(name+"."+ext)
            target.write_bytes(original.read_bytes());figure_sources.append(dict(new=record(target),source=record(original)))
    draw_figures(out)
    table_sources=[]
    for label,paths,note in [
        ("S14",[SET/"tpm_results.csv",SET/"count_results.csv"],"原完整54主/162次级比较；TPM/count两表合并增加method字段"),
        ("S15",[SET/"tpm_donor_effects.csv"],"全部53可测基因×6供体×4比较"),
        ("S16",[SET/"tpm_sensitivity.csv"],"三伪计数、六次TPM留一；计数留一另S16b"),
        ("S16b",[SET/"count_leave_one_donor.csv"],"六次新计数模型留一，原54位置/不可估计保留"),
        ("S17",[SET/"set_summary.csv"],"完整54条汇总，缺测及未满足综合标准保留"),
        ("S19",[VALIDATION/"expression_results.csv"],"前轮新增ASM11基因×4×2来源=88，原44family"),
        ("S20",[VALIDATION/"gr_public/gr_results.csv"],"成熟/新生RNA各55family，平行样本非独立人数"),
        ("S21",[VALIDATION/"human_protein/human_selected_results.csv"],"原选中蛋白数组，供体重算22family；不是新无选择数组"),
        ("S22",[SET/"public_sources/protein_file_inventory.csv"],"PRIDE公开完整文件清单；搜索输出包含proteinGroups，实际传输见原acquisition而非将列出当取得"),
        ("S23",[SET/"unselected_protein/results.csv"],"完整未预筛LFQ数组56基因×2时点112family，原七标签/发表六供体冲突保留"),
        ("S24",[SET/"unselected_protein/published_label_sensitivity.csv"],"发表六标签子集在原LFQ重算，另112Holm；同生物学来源"),
        ("S24b",[SET/"unselected_protein/direct_time_results.csv"],"六原共有标签药物响应直接72-24；56family，跨assay/LC梯度"),
        ("S24c",[SET/"unselected_protein/direct_published_labels.csv"],"仅五发表共有标签直接差，56family；结果后敏感性"),
        ("S24d",[SET/"unselected_protein/donor_scope.csv"],"每时点七原标签与六发表标签、额外10.09.19年龄/QC未核实"),
        ("S25",[SET/"unselected_protein/measurements.csv"],"原proteinGroups924LFQ测量，0作缺测，不填补；唯一蛋白组"),
        ("S25b",[SET/"unselected_protein/published_raw_cell_comparison.csv"],"144原/发表测量，142非零匹配舍入、2原零但发表有限值"),
    ]:
        data=[]
        if label=="S14":
            for method,path in zip(["tpm","count"],paths):
                for r in rows(path):data.append(dict(method=method,**{k:r.get(k,"") for k in ["feature_id","symbol","entrez_id","contrast","family","status","effect","se","ci_low","ci_high","pvalue","holm","exact_pvalue","exact_holm"]}))
        else:data=rows(paths[0])
        headers=list(data[0]);renderer.external_table("Table_"+label,headers,[[r[h] for h in headers] for r in data],note)
        table_sources.append(dict(label=label,sources=[record(p) for p in paths],rows=len(data),note=note))
    family_headers=["阶段","主family","次级family","估计量与时序"]
    family_values=[["54基因TPM","54Holm；精确另54","162Holm；精确另162","六候选结果已知后扩展"],
                   ["54基因count","54Holm","162Holm","同六供体新TMM/voom；精确WLS"],
                   ["新增早期ASM","44/33Holm","按各原设计","年龄/供体界限保留"],
                   ["GR遗传","每RNA55Holm","两RNA不合并人员","变体rescue；无空KO"],
                   ["人蛋白选中数组","22Holm","直接时间差11Holm","技术重复先平均，选择限制"]]
    family_values += [["人蛋白完整原LFQ","112Holm；精确另112","发表标签子集另112","原七标签/发表六供体，0缺测不填补"],
                      ["原人蛋白直接时间差","56Holm；精确另56","发表共有标签另56","探索性、跨assay/LC梯度；不称累积"]]
    renderer.external_table("Table_S18",family_headers,family_values,"Each stage separate; no global confirmatory family")
    # Retain original supplemental text/tables with clearly dated historical scope.
    supplement=(OLD/"supplementary.md").read_text().split("# 补充图",1)[0]
    supplement=supplement.replace("BioExplainR 中文论文 v0.11：补充材料","BioExplainR 中文论文 v0.12：补充材料")
    supplement=supplement.replace("参考文献[1–11]与主稿一致","原参考文献[1–11]与新主稿一致")
    supplement=supplement.replace("# 补充方法","S1–S6及S13为原v0.11阶段方案、方法和背景的保存文字；其中“本轮/本稿”指当时版本，最新54基因与公开验证状态见新增S7–S8及v0.12主稿。原图S1/S2已在本版替换为下文明确标注的保存图稿；原源图仍在v0.11目录。\n\n# 补充方法",1)
    supplement += "\n\n# S7 完整54基因扩展方法与新检验家族\n\n"
    protocol=(ROOT/"research/discovery/SET_VALIDATION_PROTOCOL.md").read_text().split("\n",1)[1]
    supplement += re.sub(r"^## ","### ",protocol,flags=re.M)
    supplement += "\n\n新模型28,395基因保留14,692、秩9/df15，六留一各秩8/df12。原TPM复核1,272测量/212检验；Python原count1,272测量/1,060WLS/2,385TPM敏感性/324计数留一方向。新项目4context，在线调用0。新增各家族见S18。\n"
    supplement += "\n# S8 最新公开验证与范围追踪\n\n前轮公开验证统计完整保留于discovery_validation_v2及独立报告，已再次核验原依赖与数字。新数据只能增加相应估计目标的证据。完整蛋白采集及GSE42538条件核查以新研究PUBLIC_SOURCES_FINDINGS.md为准。\n"
    findings=SET/"PUBLIC_SOURCES_FINDINGS.md"
    if findings.exists():supplement += "\n"+findings.read_text().split("\n",1)[1]+"\n"
    supplement += "\n# 新补充表及来源\n"
    for item in table_sources:supplement += f'\n## 补充表 {item["label"]}\n\n{item["note"]}；{item["rows"]}行。`tables/Table_{item["label"]}.csv`及同名XLSX，来源：'+"；".join(f'`{r["path"]}`' for r in item["sources"])+"。\n"
    supplement += "\n## 补充表 S18 新家族与阶段\n\n原54主/162次级、原ASM44/33、GR55、人蛋白选中22/11和原完整112/56分开报告；不互换校正P。\n\n## 补充表 S26 完整原LFQ与子集/直接差摘要\n\nS8内嵌六行表对应Table_S26.csv/XLSX，给出METTL7A各估计目标、CI、校正和供体分母；统计源S23/S24/S24b/S24c。\n"
    images=[("Figure_S1","补充图 S1 旧13供体固定候选响应","旧12候选分母及13供体配对；点态CI，缺测原位置保留。"),
            ("Figure_S2","补充图 S2 A549药理及暴露条件差","原48/12/24families，短/长DEX安排总窗口均18h。"),
            ("Figure_S3","补充图 S3 GR遗传交叉检验","U2OS预印本rescue变体，无空KO；PER1控制不替代PER2。"),
            ("Figure_S4","补充图 S4 完整原LFQ的METTL7A逐供体标签","原七日期标签与发表六供体冲突，橙色额外标签年龄/QC未知；0缺测无填补、技术重复先平均，精确全family未确认。")]
    supplement += "\n# 补充图\n"
    for name,heading,note in images:supplement+=f"\n## {heading}\n\n![{heading}]({out.name}/figures/{name}.png){{width=16cm}}\n\n{note}\n"
    (out/"supplementary.md").write_text(supplement)
    historical_specs=[]
    for filename in ["F1_common_task","F2_paired_bootstrap","F3_receptor_control","F4_chip_primary"]:
        data=rows(out/"tables"/(filename+".csv"));headers=list(data[0]);values=[list(r.values()) for r in data]
        historical_specs.append(dict(id=filename,headers=headers,rows=values,widths_cm=[17/len(headers)]*len(headers)))
    public_tables=re.findall(r"\n(\|[^\n]+\|\n\|[-| ]+\|\n(?:\|[^\n]+\|\n)+)",findings.read_text())
    assert len(public_tables)==1
    parsed=[[cell.strip() for cell in line.strip("|").split("|")] for line in public_tables[0].strip().splitlines()]
    headers,values=parsed[0],parsed[2:]
    historical_specs.append(dict(id="protein_summary",headers=headers,rows=values,widths_cm=[5.3,2,4,3.7,2]))
    renderer.external_table("Table_S26",headers,values,"Originalproteinstatistics and labelsubset/directsensitivities; same source, notnewdonors; exactHolmnotconfirmed")
    main_figures={heading:out/"figures"/(name+".pdf") for name,heading in [
        ("Figure_1","图 1 原固定候选的四背景响应"),("Figure_2","图 2 完整54基因的六成人逐供体响应"),("Figure_3","图 3 候选证据层级与未确认范围")]}
    main=export_set(out,out/"manuscript_expanded.md","BioExplainR-中文论文-v0.12",specs,main_figures)
    additional=export_set(out,out/"supplementary.md","BioExplainR-补充材料-v0.12",historical_specs,
                               {heading:out/"figures"/(name+".pdf") for name,heading,note in images})
    (out/"export_report.json").write_text(json.dumps(dict(status="pass",utc=utc(),main=main,supplement=additional,
        scope="New54gene analysis + preserved public validation manuscript integration; originals retained"),ensure_ascii=False,indent=2)+"\n")
    (out/"assets_manifest.json").write_text(json.dumps(dict(copied_tables=copied,figure_sources=figure_sources,
        table_sources=table_sources,files=[record(p) for folder in [out/"figures",out/"tables"] for p in sorted(folder.rglob("*")) if p.is_file()]),ensure_ascii=False,indent=2)+"\n")
    print(json.dumps(dict(main=main,supplement=additional),ensure_ascii=False,indent=2))


if __name__=="__main__":
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument("--directory",type=Path,default=ROOT/"docs/paper_cn_v6");parser.add_argument("--refresh",action="store_true")
    a=parser.parse_args();build(a.directory.resolve(),a.refresh)
