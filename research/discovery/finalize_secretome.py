"""Summarize actual secretome evidence, missingness and independent-check scope."""
import argparse
import importlib.metadata
import json
from pathlib import Path

from set_validation import rows
from validation_sources import record, utc, csv_out, json_out


def finalize(out):
    candidates=rows(out/"candidate_results.csv")
    full=rows(out/"all_results.csv")
    cross=rows(out/"candidate_cross_evidence.csv")
    effects=rows(out/"candidate_donor_effects.csv")
    detection=rows(out/"candidate_detection.csv")
    sensitivity=rows(out/"candidate_sensitivity.csv")
    summaries=rows(out/"array_summary.csv")
    audit=json.loads((out/"r_numeric_audit.json").read_text())
    workflow=json.loads((out/"bioexplainr_workflow.json").read_text())
    assert audit["status"]==workflow["status"]=="pass"
    supported=[r for r in cross if r["same_direction_corrected_support"]=="True"]
    contrary=[r for r in cross if r["direction_concordance"]=="opposite"]
    missingness=[]
    for r in candidates:
        e=[v for v in effects if v["feature_id"]==r["feature_id"] and v["time_h"]==r["time_h"]]
        d=next(v for v in detection if v["feature_id"]==r["feature_id"] and v["time_h"]==r["time_h"])
        missingness.append(dict(feature_id=r["feature_id"],symbol=r["symbol"],time_h=r["time_h"],
            detection_status=d["detection_status"],status=r["status"],n_pairs=r["n_pairs"],
            paired_donors="|".join(v["donor"] for v in e if v["status"]=="paired"),
            missing_pair_donors="|".join(v["donor"]+":co"+v["control_technical_observed"]+":dex"+v["DEX_technical_observed"] for v in e if v["status"]!="paired")))
    csv_out(out/"candidate_missingness_summary.csv",missingness)
    selected=sorted([r for r in full if r["status"]=="estimable" and float(r["pooled_BH"])<.05],
                    key=lambda r:(float(r["pooled_BH"]),int(r["time_h"]),r["group_id"]))
    csv_out(out/"all_BH_significant.csv",selected,fields=list(full[0]))
    lines=["# PXD033504完整分泌蛋白组：实际结果", "", "本轮探索性处理数组重分析；LFQ0缺测、不填补；日期供体配对、技术重复先聚合。", "",
           "## 完整分母", "", "|时点|原/QC组|日期标签/技术列|可估计|统一BH通过|候选可估计/56|", "|---|---|---|---|---|---|"]
    for r in summaries:
        lines.append(f"|{r['time_h']}h|{r['raw_groups']}/{r['QC_groups']}|{r['donor_labels']}/{r['technical_columns']}|{r['estimable_groups']}|{r['pooled_BH_significant']}|{r['candidate_estimable']}/56|")
    lines += ["",f"全数组统一BH family={len(full)}；固定56×2 Holm112，{sum(r['status']=='estimable' for r in candidates)}可估计、{sum(float(r['holm112'])<.05 for r in candidates)}校正通过。",
              f"完整精确BH通过{sum(float(r['exact_pooled_BH'])<.05 for r in full)}；候选精确Holm通过{sum(float(r['exact_holm112'])<.05 for r in candidates)}。缺测P=1只保留家族位置，不是蛋白阴性。", "", "## 重点与全部可估计候选", "",
              "|基因|时点|状态/n|效应|点态95%CI|Holm112|↑/↓|", "|---|---|---|---|---|---|---|"]
    for r in candidates:
        if r["status"]=="estimable" or r["symbol"] in ["ANGPTL2","FSTL3"]:
            fmt=lambda s: f"{float(s):+.3f}" if s!="" else "缺测"
            lines.append(f"|{r['symbol']}|{r['time_h']}h|{r['status']}/{r['n_pairs']}|{fmt(r['effect'])}|{fmt(r['ci_low'])}至{fmt(r['ci_high'])}|{float(r['holm112']):.4g}|{r['positive_donors']}/{r['negative_donors']}|")
    lines += ["", "## 与ASM转录方向的关系", "",
              "候选Holm112通过且与原ASM发现同向："+(", ".join(r["symbol"]+" "+r["time_h"]+"h" for r in supported) or "无")+"。",
              "可估计但与ASM转录反向："+(", ".join(r["symbol"]+" "+r["time_h"]+"h" for r in contrary) or "无")+"。",
              "这些是跨组织/药物/剂量/尺度线索，不是匹配ASM RNA-分泌多组学或功能因果。", "", "## 重点敏感性", ""]
    lines += ["ANGPTL2 24h两合格标签效应−.453/−1.088，仅n=2；FSTL3两时点LFQ有效配对0。两者有肽段识别/Secreted注释，不确认药物响应。",
              "FBN2 72h主7对/严格6对Holm通过，但发表六标签只有5可测、Holm112=.270未通过；支持依赖原八标签范围，不能声称发表六成人确认。",
              "24h非零803选中技术测量均不匹配发表log2值、ALL仅9/467总Intensity一致；原LFQ−发表值非固定偏移，不称原Perseus复现。72h2128非零匹配、320原零发表有限。"]
    for r in sensitivity:
        if r["symbol"] in ["ANGPTL2","FSTL3"]:
            effect=f"{float(r['effect']):+.3f}" if r["effect"] else "不可估计"
            lines.append(f"- {r['symbol']} {r['time_h']}h {r['analysis']}：n={r['n_pairs']}，效应{effect}，Holm112={float(r['holm112']):.4g}。")
    lines += ["", "## 核验与证据范围", "",
              f"独立R核对{audit['raw_measurements']:,}LFQ测量、{audit['donor_rows']:,}供体组行、{len(full)}全组family、112候选、224敏感性、56直接差及{audit['leave_one_rows']}留一方向通过。",
              f"实际BioExplainR{workflow['package_version']}：2context/双语HTML，完整family事实核对通过、在线调用0。",
              "UniProt Q9UKU9/O95633的Secreted与信号肽注释原响应保存，支持可分泌蛋白身份；不提供本轮药物效应或ASM候选功能验证。",
              "上清LFQ是相对细胞外丰度，不是每细胞绝对分泌速率；两时点独立处理且标签构成不同，直接时间差不证明累积动力学。",
              "原全数组/发表选中表同来源，不增加新队列。全部发表逐格差异与LFQ0/有限发表值冲突保留。",
              "新报告docs/secretome_validation_v1；复现/保存核验见README。旧v0.12精确rgo依赖用开始快照，其余原科学路径/hash；2,905原保护文件逐hash核验。"]
    (out/"FINDINGS.md").write_text("\n".join(lines)+"\n")
    json_out(out/"scientific_ledger.json",dict(status="completed_public_secretome_reanalysis",utc=utc(),script=record(Path(__file__)),
        full_family=len(full),candidate_family=112,candidate_estimable=sum(r["status"]=="estimable" for r in candidates),
        candidate_significant=sum(float(r["holm112"])<.05 for r in candidates),same_direction_corrected_support=supported,
        opposite_direction_estimable=contrary,independent_numeric_R=audit,workflow=workflow,
        new_independent_ASM_protein_donors=0,new_wet_experiments=0,online_model_calls=0,
        interpretation="Human HTPC extracellular relative abundance, same prior source; secretion rate/GR candidate dependence/ASM function not established"))
    json_out(out/"python_environment.json",dict(utc=utc(),packages={p:importlib.metadata.version(p) for p in
        ["numpy","scipy","openpyxl","matplotlib","py7zr","python-docx","PyMuPDF"]}))
    print("Secretome actual findings saved; same-direction corrected support:",len(supported))


if __name__=="__main__":
    p=argparse.ArgumentParser();p.add_argument("output",type=Path)
    finalize(p.parse_args().output.resolve())
