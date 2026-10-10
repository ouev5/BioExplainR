"""Export the independently audited common-task/mechanism/ChIP addendum to v0.10."""
import csv
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys
import fitz
from docx.oxml import OxmlElement
from docx.oxml.ns import qn

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'research'))
from export_paper import native_docx


def read(p):
    with p.open() as f:return list(csv.DictReader(f))


def main():
    performance=ROOT/'research/results/common_performance_v4'
    mechanism=ROOT/'research/results/discovery_mechanism_fit_v4'
    chip=ROOT/'research/results/discovery_chip_analysis_v1'
    audit=json.loads((performance/'audit.json').read_text());assert audit['status']=='pass'
    assert json.loads((mechanism/'audit.json').read_text())['status']=='pass'
    assert json.loads((chip/'r_audit.json').read_text())['status']=='pass'
    out=ROOT/'docs/research_followup_v1';out.mkdir();(out/'tables').mkdir()
    specs=[]
    def table(name,headers,rows,widths):
        specs.append(dict(id=name,headers=headers,rows=rows,widths_cm=widths))
        with (out/'tables'/f'{name}.csv').open('w') as f:
            w=csv.writer(f);w.writerow(headers);w.writerows(rows)
        return '\n| '+' | '.join(headers)+' |\n|'+'---|'*len(headers)+'\n'+'\n'.join('| '+' | '.join(map(str,r))+' |' for r in rows)+'\n'
    labels={'bio_offline':'BioExplainR 离线','base_r':'base R 脚本','ellmer_table':'ellmer 读表','ellmer_facts':'ellmer 读 facts','bio_client_facts':'BioExplainR 客户端'}
    summary=read(performance/'summary.csv');summary.sort(key=lambda r:list(labels).index(r['method']))
    ptable=table('F1_common_task',['方法','正确/360','覆盖/360','全正确/72','中位秒','P95秒'],
        [[labels[r['method']],r['correct'],r['covered'],r['all_correct'],f"{float(r['median_sec']):.3f}",f"{float(r['p95_sec']):.3f}"] for r in summary], [3.9,2.1,2.1,2.1,2.1,2.1])
    differences=read(performance/'paired_bootstrap.csv')
    btable=table('F2_paired_bootstrap',['对照：减去 ellmer 读表','准确率差','任务 bootstrap 95% CI'],
        [[labels[r['comparison'].split()[0]],f"{100*float(r['estimate']):.2f}个百分点",f"{100*float(r['lower']):.2f}–{100*float(r['upper']):.2f}个百分点"] for r in differences],[5.8,3.3,5.3])
    mresults=read(mechanism/'model_results_complete.csv')
    control=[r for r in mresults if r['gene']=='FKBP5' and r['contrast'] in ['DEX','KH103','MIF','Cort113']]
    mtable=table('F3_receptor_control',['FKBP5 对照效应','log2估计','95% CI','未校正 P'],
        [[r['contrast'],f"{float(r['log2_effect']):+.3f}",f"{float(r['lower']):+.3f}–{float(r['upper']):+.3f}",f"{float(r['p']):.3g}"] for r in control],[4.2,2.6,4.5,3.1])
    counts=read(chip/'peak_counts.csv')
    primary=[r for r in counts if r['gene']=='SPARCL1' and r['primary']=='True' and r['window']==('TSS_20000' if r['factor']=='GR' else 'TSS_5000')]
    ctable=table('F4_chip_primary',['原样本','因子/处理','固定窗口','q≤.05峰数'],
        [[r['gsm'],r['title'],r['window'],r['count']] for r in primary],[3.5,4.3,3.5,3.1])
    tokens=audit['tokens']
    token_text='；'.join(f"{labels[m]} 完成响应共输入{r['prompt_tokens']}、输出{r['completion_tokens']} tokens" for m,r in tokens.items())
    task_differences=read(performance/'task_bootstrap.csv')
    task_text='；'.join(f"{labels[r['comparison'].split()[0]]}相对读表的全任务正确率差为{100*float(r['estimate']):.2f}个百分点（任务bootstrap 95% CI {100*float(r['lower']):.2f}–{100*float(r['upper']):.2f}）" for r in task_differences)
    size_rows=read(performance/'size_breakdown.csv')
    size_text='；'.join(f"{labels[r['method']]} {r['n']}行目标为{r['correct']}/{r['targets']}" for r in size_rows if r['method']=='ellmer_table')
    text=f'''---
title: "BioExplainR 共同任务与候选机制后续分析"
subtitle: "中文论文 v0.10 配套研究增补 v1 · 正式执行与独立实现复核"
date: "2026-10-09"
lang: zh-CN
---

# 1 正式共同任务比较

本增补对应预先保存的共同任务方案及机制方案。已知 airway/pasilla 开发数据不能视为盲法独立生物学 gold。两个数据集各取按 feature_id 排序均匀选择的50/200行，使用 α=.01/.05/.10 与 |log2FC|>0/1，24任务×3重复×5方法，共360方法运行、1,800目标评分；每方法分母360整数、72运行。两个 facts 客户端的72对 system/user 提示逐对相同。

五个输出为 n_features、n_significant、n_up、n_down、n_na_padj；严格 padj<α 且 abs(log2FC)>τ，NA不显著。BioExplainR 离线计算、base R 用户脚本、ellmer直接读表、ellmer读取完整BioExplainR facts、BioExplainR客户端读取同facts分别评价。Qwen2.5-1.5B-Instruct Q4_K_M（固定SHA-256）由 llama.cpp b11429 CPU服务执行；temperature=0、seed=42、输出上限256 tokens、180秒请求预算、无重试、无答案修订，关闭prompt cache。顺序及2,000次24任务配对bootstrap提前冻结，预热用非研究两行fixture。计时包括输入读取/对象/提示准备、调用和解析，不含库载入、下载和启动。

表 F1 给出全目标分母与计时；失败、超时、截断/无效 JSON/缺项均留在全分母。共有 **{audit['failed_requests']} 个失败请求**。全任务正确率按每次运行的五目标均正确计。确定性步骤的极短耗时不宜解释为稳定速度优势；CPU负载/取消超时后的等待均可能影响本机计时。
{ptable}
表注：base R为用户实现基线；ellmer为通用客户端。表中全正确分母72是24任务的3重复，非72独立生物样本。

表 F2 给出读facts相对直接读表的准确率差及按24任务聚合的配对bootstrap；只反映这个开发计数/传递任务。
{btable}
全任务正确率为预定第二主终点：{task_text}。按输入规模另报：{size_text}，完整分层在size_breakdown.csv。

{token_text}。失败请求的tokens未知，不将其计为0；外部API费0，本地CPU/能耗/货币总成本未测量。两个facts组目标答案已提供，结果不证明通用推理、整篇报告质量或生物学发现能力。

来源源码核查记录了iSEE 2.14.0、SCassist/GPTCelltype/GeneAgent固定commit及README。四个专属工具不原生返回该任务五整数，标not_applicable，不记错或性能0。结果不是六工具全面排名。早期Responses API忽略seed、端口冲突和入口参数错误的中止轮保留在v1–v3，正式结果仅v4；任务/提示未按答案调优。

# 2 GR干预重分析：候选不可估计

GSE229084来自A549癌上皮细胞系，不能外推为ASM、患者或独立供体。保留Salmon/tximport发布非整数估计计数；按GEO处理和batch映射47文库（4 set，12处理/时序组），未处理组按设计排除；全基因filterByExpr默认min.count=10/min.total.count=15、TMM、voom、limma `~0+group+batch`，设计秩15、残差自由度32，35,942基因中15,437保留。三候选前给药DEX×KH-103/MIF/Cort113差中差构成预定Holm family；后给药仅描述。GEO两条DMSO标题rep2/rep3与set3/set4冲突，按batch与计数列核对保留，不补造缺失DMSO set2。作者处理对象的51个MG编号/处理/batch独立核对全部一致，缺MG_15确认；13,834共享基因×51列的705,534计数与发布矩阵一致（最大差4.66e-10），102空白/description标识无法对应并逐项保留。SPARCL1亦不在作者过滤后对象中。

**SPARCL1的47文库计数为0–4，全部候选主交互因未通过预定过滤而不可估计。** 不能据此支持或否定受体依赖，更不降低过滤阈值获得显著性。表F3显示固定FKBP5控制在DEX及干预中有可测响应，但控制不替代候选。
{mtable}
表注：DEX是DMSO背景simple effect；KH103/MIF/Cort113为前给药差中差。均为固定描述控制、未校正P，不把它们混入SPARCL1三检验family。

Python从发布计数独立核对35,942基因过滤、188候选/控制测量、GEO映射、设计/对比、logCPM、39个WLS系数、t/CI。TMM/voom/eBayes未独立重估。独立复核发现limma contrasts.fit对加权设计采用共同相关近似，已重建该近似并另导出精确加权协方差敏感性，最大SE相对差2.19%。CI导出最初误按名称索引无名字的s2.post，保存失败记录后仅修复导出；冻结RDS/拟合未改变。

# 3 ChIP峰与参考基因组核实

GSE95632为单HASM2供体细胞系培养实验。取得全部18个发布narrowPeak gzip及原文HTML，逐hash/CRC核对。原GEO写人样本/mm9的冲突完整保留。全部1,347,409峰的染色体和末端落在hg19范围内；hg18/hg38/mm9分别12,937/10,043/158,229峰越界，且mm9缺chr20–22。该全基因组坐标指纹支持**坐标核实hg19/GRCh37**，不是作者确认的更正；原文XML不可取得、出版社补充HTTP403，OCR不构成确认。

使用UCSC ncbiRefSeq四条整染色体快照，固定SPARCL1/FKBP5/TSC22D3/KLF15全部注释TSS。BED零基半开，负链TSS=txEnd−1，GR±20kb、RNAPII±5kb；基因体及±100kb公开敏感性。MACS q≤.05（−log10q≥log10(20)）保留全部命中，不选最大峰。主分析仅8个未转导vehicle/DEX样本；额外10文库作描述，不混入主条件。

表F4给出SPARCL1发布峰的主窗口计数。DEX GR两重复8/8峰逐坐标有8对重叠；RNAPII 1/1亦重叠。vehicle GR有4/2峰，两个峰重复重叠；RNAPII 0/0。这些结果支持“发布峰在候选窗口重叠”的描述，**不是差异占据统计**，不能由峰数或control不成峰推断显著增加、直接调控、enhancer连接或功能因果。
{ctable}
表注：全部坐标、距离、signalValue、q及重复重叠见原始结果表；单细胞系培养重复不增加独立供体数。

R GenomicRanges直接从原峰和原RefSeq重新构造窗口，288计数项、2,505峰窗口命中、summit/距离及16重复比较通过独立实现复核。原R审计窗口100000被默认科学计数格式变为1e+05的失败保留；包装器仅固定数字格式后通过。

# 4 可支持结论与复现入口

共同任务量化计算与语言传递分工；生物学结果则明确区分表达响应、药理干预可测性与染色质窗口重叠。A549无法检验低表达SPARCL1依赖；ASM峰可定位但不足以证明机制。没有新增湿实验、GR rescue、位点reporter/CRISPR、SPARCL1蛋白/基质/功能/临床终点；独立实现复核也不等于第三方人员科学/code sign-off。

主要结果目录：`research/results/common_performance_v4/`、`discovery_mechanism_fit_v4/`、`discovery_chip_v1/`、`discovery_chip_analysis_v1/`。方案与脚本在`research/common_performance/`和`research/discovery/`；所有输入、freeze、真实HTTP字节、scores、失败/中断、model.rds、独立审计、scientific_ledger及hash清单保留。正式论文仍为v0.10，本件为可编辑研究增补；GitHub/外部上传继续暂停。

# 参考来源

1. 共同任务方案：`research/common_performance/PROTOCOL.md`；实现修订：`IMPLEMENTATION.md`。
2. 机制方案：`research/discovery/MECHANISM_PROTOCOL.md`；GEO GSE229084、GSE95632元数据快照。
3. Gazorpak et al. 2023. doi:10.1038/s41467-023-44031-2；保存PMC10710461.xml。
4. Sasse et al. 2017. doi:10.1165/rcmb.2016-0357OC；保存PMC5576583_article.html。
5. UCSC hg18/hg19/hg38/mm9 chromosome sizes与hg19 ncbiRefSeq快照，访问UTC见acquisition记录。
'''
    source=out/'research_addendum.md';source.write_text(text)
    shutil.copyfile(ROOT/'docs/paper_cn_v4/paper.css',out/'paper.css')
    base=['pandoc',str(source),'--standalone']
    ast=json.loads(subprocess.check_output(base+['-t','json']))
    name='BioExplainR-共同任务与机制研究增补-v1'
    doc=native_docx(ast,out/f'{name}.docx',specs,legacy_layout=False)
    for style in doc.styles:
        if style.name.startswith('Heading'):
            pr=style.element.get_or_add_pPr();n=pr.find(qn('w:numPr'))
            if n is not None:pr.remove(n)
            n=OxmlElement('w:numPr');i=OxmlElement('w:numId');i.set(qn('w:val'),'0');n.append(i);pr.append(n)
    doc.save(out/f'{name}.docx')
    subprocess.run(base+['--embed-resources',f'--css={out/"paper.css"}','-o',str(out/f'{name}.html')],check=True)
    subprocess.run(['libreoffice','-env:UserInstallation=file:///tmp/opencode/bioexplainr-followup-lo','--headless','--convert-to','pdf','--outdir',str(out),str(out/f'{name}.docx')],check=True,timeout=180)
    pdf=fitz.open(out/f'{name}.pdf');pdftext='\n'.join(p.get_text() for p in pdf)
    assert all(x in pdftext for x in ['SPARCL1','GSE229084','GSE95632','hg19','不可估计']) and len(doc.tables)==4
    summary=dict(status='pass',pdf_pages=len(pdf),docx_tables=4,performance=audit,mechanism=json.loads((mechanism/'audit.json').read_text()),chip=json.loads((chip/'r_audit.json').read_text()),
        scope='Scientific result content/table audit; not manual visual review')
    (out/'audit.json').write_text(json.dumps(summary,indent=2)+'\n')
    files=[dict(path=p.relative_to(out).as_posix(),bytes=p.stat().st_size,sha256=hashlib.file_digest(p.open('rb'),'sha256').hexdigest()) for p in sorted(out.rglob('*')) if p.is_file() and p.name!='files_manifest.json']
    (out/'files_manifest.json').write_text(json.dumps(dict(files=files),indent=2)+'\n')
    print(json.dumps(dict(status='exported',directory=str(out),pages=len(pdf),tables=4),indent=2))


if __name__=='__main__':main()
