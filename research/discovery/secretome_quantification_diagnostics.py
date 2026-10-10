"""Distinguish MS identification, raw intensity and usable LFQ; inspect published scale."""
import argparse
import csv
import json
import math
from pathlib import Path

import numpy as np

from secretome_analyze import sources
from set_validation import rows
from validation_sources import record, utc, csv_out, json_out


def main(out):
    csv.field_size_limit(10*1024*1024)
    json_out(out/"quantification_diagnostic_freeze.json",dict(utc=utc(),script=record(Path(__file__)),
        timing="PrimaryLFQcandidate results and original/publishedselected mismatch known; per-sample unnormalized Intensity not yet inspected",
        scope="Diagnostic identification/intensity support and scale comparison only; no replacement for primaryLFQ, no additional significance claims"))
    candidate=rows(out/"candidate_detection.csv")
    samplemap=rows(out/"sample_map.csv")
    selected=rows(out/"published_selected_cell_comparison.csv")
    inventories=rows(out/"published_inventory_comparison.csv")
    identification,measurements,comparison,allcompare=[],[],[],[]
    for time in [24,72]:
        with sources(out,time)["proteinGroups.txt"].open(newline="") as stream:
            table=list(csv.DictReader(stream,delimiter="\t"))
        s=[s for s in samplemap if int(s["time_h"])==time]
        for g in candidate:
            if int(g["time_h"]) != time or g["detection_status"] != "unique_group":
                continue
            r=table[int(g["group_id"].split(":")[1])-2]
            identification.append(dict(feature_id=g["feature_id"],symbol=g["symbol"],time_h=time,group_id=g["group_id"],
                protein_ids=r["Protein IDs"],peptides=r["Peptides"],razor_unique_peptides=r["Razor + unique peptides"],
                unique_peptides=r["Unique peptides"],sequence_coverage_percent=r["Sequence coverage [%]"],
                total_intensity=r["Intensity"],score=r["Score"],protein_names=r["Protein names"]))
            for sample in s:
                exp=sample["experiment"]
                measurements.append(dict(feature_id=g["feature_id"],symbol=g["symbol"],group_id=g["group_id"],**sample,
                    raw_Intensity=float(r["Intensity "+exp]),raw_LFQ=float(r[sample["source_column"]]),
                    identified_peptides=int(r["Peptides "+exp]),razor_unique_peptides=int(r["Razor + unique peptides "+exp]),
                    unique_peptides=int(r["Unique peptides "+exp])))
        for cell in selected:
            if int(cell["time_h"])!=time:
                continue
            r=table[int(cell["group_id"].split(":")[1])-2]
            sample=next(s for s in s if s["donor"]==cell["donor"] and s["condition"]==cell["condition"] and s["technical_rep"]==cell["technical_rep"])
            value=float(r["Intensity "+sample["experiment"]]); published=float(cell["published_log2"])
            log2=math.log2(value) if value>0 else None
            comparison.append(dict(**cell,raw_Intensity=value,log2_Intensity=log2 if log2 is not None else "",
                Intensity_matches_published=log2 is not None and abs(log2-published)<=.000051,
                raw_log2_minus_published=float(cell["raw_log2"])-published if cell["raw_log2"] else ""))
        for inv in inventories:
            if int(inv["time_h"])!=time:
                continue
            matches=[r for r in table if r["Protein IDs"]==inv["published_protein_ids"] or r["Majority protein IDs"]==inv["published_protein_ids"]]
            if len(matches)!=1:
                allcompare.append(dict(**inv,total_intensity_raw="",intensity_equal="",matching_rule="unresolved"))
            else:
                r=matches[0];value=float(r["Intensity"]);published=float(inv["published_total_intensity"])
                allcompare.append(dict(**inv,total_intensity_raw=value,intensity_equal=value==published,
                    matching_rule="exact_Protein_IDs" if r["Protein IDs"]==inv["published_protein_ids"] else "exact_Majority_IDs"))
    csv_out(out/"candidate_identification.csv",identification)
    csv_out(out/"candidate_raw_intensity_diagnostics.csv",measurements)
    csv_out(out/"published_scale_diagnostics.csv",comparison)
    csv_out(out/"published_total_intensity_comparison.csv",allcompare)
    summary=[]
    for time in [24,72]:
        z=[r for r in comparison if int(r["time_h"])==time]
        offsets=[float(r["raw_log2_minus_published"]) for r in z if r["raw_log2_minus_published"]!=""]
        a=[r for r in allcompare if int(r["time_h"])==time]
        summary.append(dict(time_h=time,selected_cells=len(z),log2_Intensity_matches=sum(r["Intensity_matches_published"] for r in z),
            nonzeroLFQ_offset_min=min(offsets),nonzeroLFQ_offset_max=max(offsets),
            published_all_rows=len(a),exact_or_Majority_resolved=sum(r["matching_rule"]!="unresolved" for r in a),
            total_intensity_equal=sum(r["intensity_equal"] is True for r in a)))
    json_out(out/"quantification_diagnostics_run.json",dict(status="completed",utc=utc(),script=record(Path(__file__)),summary=summary,
        scope="Raw identification/intensity evidence only, not normalizedLFQ response or imputed candidate significance"))
    print(json.dumps(summary,indent=2))


if __name__=="__main__":
    p=argparse.ArgumentParser();p.add_argument("output",type=Path)
    main(p.parse_args().output.resolve())
