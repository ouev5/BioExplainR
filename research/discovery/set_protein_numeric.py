"""Analyze unselected MaxQuant LFQ arrays using actual donor labels and fixed families."""
import argparse
import csv
import json
import re
from pathlib import Path
import numpy as np
from set_validation import rows,estimate,adjust
from validation_sources import record,utc,csv_out,json_out


def freeze(out):
    dest=out/"unselected_protein";dest.mkdir(exist_ok=False)
    genes=[dict(feature_id=r["feature_id"],symbol=r["symbol"],set_rank=r["set_rank"]) for r in rows(out/"annotation.csv")]
    genes += [dict(feature_id="control_PER1",symbol="PER1",set_rank=""),dict(feature_id="control_NR3C1",symbol="NR3C1",set_rank="")]
    csv_out(dest/"frozen_genes.csv",genes)
    json_out(dest/"design_freeze.json",dict(utc=utc(),script=record(Path(__file__)),genes=record(dest/"frozen_genes.csv"),
        timing="OriginalselectedMETTL7Aresults known, first5noncandidate24hrawrows andmetadata read; new unselected candidateLFQ not inspected",
        units="All available decoded biopsy-date donor labels, three technical replicates per donor/condition; do not count technical measurements as n",
        quality="Exclude Reverse+, Potentialcontaminant+, Onlyidentifiedbysite+; exact singleton Gene names + aliasMETTL7A/TMT1A, BMAL1/ARNTL; multiple matchinggroups ambiguous not selected",
        missing="LFQ<=0 missing, noimputation; require >=2 of3 observed each donor/condition, mean log2LFQ acrossavailabletechnical repeats; min3 paired donors",
        family="56genes x2timepoints =112two-sided pairedt/Holm; exactsignflips another112. MissingP=1/emptyCI, notnull",
        scale="OriginalMaxQuantLFQ, no claim reproducing Perseusprocessedselection values",
        scope="Cross-tissueHTPC, same biological source aspreviousselectedtable, notnewindependentcohort; newfullarrayreanalysis; noASMproteinclaim"))
    print("Unselected56gene x2timepoints protein design frozen")


def measure(out):
    csv.field_size_limit(10*1024*1024)
    dest=out/"unselected_protein";genes=rows(dest/"frozen_genes.csv");results=[];measurements=[];effects=[];inventory=[];sample_map=[];inputs=[]
    for acc,time in [("PXD033514",24),("PXD033534",72)]:
        directory=out/"protein_full_tables_small"/acc
        recpath=directory/("extraction_verified.json" if (directory/"extraction_verified.json").exists() else "extraction.json")
        completion=json.loads(recpath.read_text());assert completion["status"]=="pass",recpath
        data_entry=next(r for r in completion["outputs"] if r["member"].endswith("proteinGroups.txt"))
        from validation_sources import ROOT
        tablepath=ROOT/data_entry["path"];inputs.append(record(tablepath))
        with tablepath.open(newline="") as stream:
            reader=csv.DictReader(stream,delimiter="\t");headers=reader.fieldnames;data=list(reader)
        columns=[k for k in headers if k.startswith("LFQ intensity ")]
        mapping_entry=next(r for r in completion["outputs"] if "SampleNameEncription" in r["member"])
        mapping_path=ROOT/mapping_entry["path"];inputs.append(record(mapping_path));mappingtext=mapping_path.read_text()
        decoding=dict(re.findall(r"(?m)^(\d+)\.\.\.\s*=\s*(\d{2}\.\d{2}\.\d{2})",mappingtext))
        parsed={}
        for col in columns:
            label=col.removeprefix("LFQ intensity ");match=re.fullmatch(r"(\d+)(co|c|dex)([123])",label)
            assert match and match[1] in decoding,(col,decoding)
            parsed[col]=dict(time_h=time,source_project=acc,source_column=col,donor=decoding[match[1]],raw_donor_label=match[1],condition="co" if match[2]=="c" else match[2],technical_rep=int(match[3]))
            sample_map.append(parsed[col])
        donors=sorted({r["donor"] for r in parsed.values()})
        assert len(columns)==len(donors)*6
        for d in donors:
            assert {(s["condition"],s["technical_rep"]) for s in parsed.values() if s["donor"]==d}=={(c,i) for c in ["co","dex"] for i in [1,2,3]}
        passed={i for i,r in enumerate(data,2) if not any(r.get(k,"")=="+" for k in ["Reverse","Potential contaminant","Only identified by site"])}
        for gene in genes:
            aliases={gene["symbol"]}
            if gene["symbol"]=="TMT1A":aliases.add("METTL7A")
            if gene["symbol"]=="BMAL1":aliases.add("ARNTL")
            matches=[(i,r) for i,r in enumerate(data,2) if i in passed and r["Gene names"] in aliases]
            status="unique_group" if len(matches)==1 else "not_detected" if not matches else "ambiguous_groups"
            inventory.append(dict(time_h=time,project=acc,feature_id=gene["feature_id"],symbol=gene["symbol"],status=status,
                matched_groups="|".join(r["Protein IDs"] for i,r in matches),raw_groups=len(data),QC_groups=len(passed),raw_donor_labels=len(donors)))
            donor_values={d:{c:[] for c in ["co","dex"]} for d in donors}
            if len(matches)==1:
                source_row,r=matches[0]
                for col,s in parsed.items():
                    raw=float(r[col]);assert np.isfinite(raw) and raw>=0
                    if raw>0:donor_values[s["donor"]][s["condition"]].append(float(np.log2(raw)))
                    measurements.append(dict(feature_id=gene["feature_id"],symbol=gene["symbol"],**s,
                        raw_LFQ=raw,log2_LFQ=float(np.log2(raw)) if raw>0 else "",source_row=source_row,protein_ids=r["Protein IDs"]))
            values=[]
            for d,conds in donor_values.items():
                eligible=len(conds["co"])>=2 and len(conds["dex"])>=2
                effect=float(np.mean(conds["dex"])-np.mean(conds["co"])) if eligible else ""
                effects.append(dict(feature_id=gene["feature_id"],symbol=gene["symbol"],time_h=time,donor=d,
                    control_technical_observed=len(conds["co"]),DEX_technical_observed=len(conds["dex"]),effect=effect,status="paired" if eligible else "insufficient_LFQ"))
                if eligible:values.append(effect)
            r=dict(feature_id=gene["feature_id"],symbol=gene["symbol"],time_h=time,status="estimable" if len(values)>=3 else status if status!="unique_group" else "insufficient_pairs")
            if len(values)>=3:r.update(estimate(values))
            else:
                r.update({k:"" for k in ["n_donors","effect","se","ci_low","ci_high","positive_donors","negative_donors"]});r.update(pvalue=1.,exact_pvalue=1.)
            results.append(r)
    for r,p,e in zip(results,adjust([r["pvalue"] for r in results]),adjust([r["exact_pvalue"] for r in results])):r.update(holm112=float(p),exact_holm112=float(e))
    for name,data in [("sample_map.csv",sample_map),("detection.csv",inventory),("measurements.csv",measurements),("donor_effects.csv",effects),("results.csv",results)]:csv_out(dest/name,data)
    json_out(dest/"run.json",dict(status="completed",utc=utc(),script=record(Path(__file__)),inputs=inputs,
        raw_technical_columns=len(sample_map),tests=112,estimable=sum(r["status"]=="estimable" for r in results),
        significant=sum(r["holm112"]<.05 for r in results),
        scope="UnselectedoriginalMaxQuantfullarrays, allactualdonorlabels; sameHTPCsource; technicalrepeatsaveraged; zerosmissing/noimputation"))
    print(json.dumps([r for r in results if r["symbol"] in ["TMT1A","PER2","FKBP5","NR3C1"]],indent=2))


if __name__=="__main__":
    p=argparse.ArgumentParser();p.add_argument("action",choices=["freeze","measure"]);p.add_argument("output",type=Path)
    a=p.parse_args();globals()[a.action](a.output.resolve())
