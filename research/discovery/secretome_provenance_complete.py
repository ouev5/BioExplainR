"""Complete diagnostic comparisons with explicit original donor decoding and search API."""
import argparse
import csv
import json
import math
import re
import urllib.parse
import xml.etree.ElementTree as ET
from pathlib import Path

import numpy as np

from secretome_provenance import SPECS, OLD, SET, HUMAN, PRIDE_QUERIES, read_table, identity_map
from validation_sources import ROOT, HERE, EPMC, record, utc, json_out, csv_out, fetch

MAPPINGS = {
    "secretome24": OLD / "archives/24h/extracted/SampleNameEncription_Secretome24h.txt",
    "secretome72": OLD / "archives/72h/extracted/SampleNameEncription_Secretome72h.txt",
    "proteome24": SET / "protein_full_tables_small/PXD033514/extracted_verified/SampleNameEncription_Proteome24h.txt",
    "proteome72": SET / "protein_full_tables_small/PXD033534/extracted/SampleNameEncription_Proteome72h.txt",
}


def rows(path):
    with path.open(newline="") as stream:
        return list(csv.DictReader(stream))


def freeze(out):
    dest=out / "complete"; dest.mkdir()
    json_out(dest / "freeze.json",dict(utc=utc(),script=record(Path(__file__)),
        inputs=[record(p) for p in list(SPECS.values())+list(MAPPINGS.values())]+[record(out / "published_measurements.csv"),
            record(out / "all_intensity_cross_array.csv"),record(out / "literature_records.csv")],
        helpers=[record(HERE / "secretome_provenance.py"),record(HERE / "validation_sources.py")],
        correction="First cross-array run omitted numeric proteome decoding. Preserve first run; independently decode all four raw maps and repeat full comparisons. PRIDE /projects keyword ignored: four identical raw responses, use /search/projects with specificity control.",
        scope="Diagnostic only; old scientific estimates untouched",pride_queries=PRIDE_QUERIES,
        fulltext_selection="All PMC entries with asm_candidates query; or ASM queries and title contains proteom, secretom, steroid, fluticasone, glucocorticoid, dexamethasone, or extracellular matrix; plus source PMC9562650. Up to30 unique PMC, order as literature CSV."))


def analyze(out):
    dest=out / "complete"; f=json.loads((dest / "freeze.json").read_text())
    assert record(Path(__file__)) == f["script"]
    for r in f["inputs"]+f["helpers"]:
        assert record(ROOT/r["path"]) == r,r["path"]
    tables={k:read_table(p) for k,p in SPECS.items()}; lookups={k:identity_map(t) for k,t in tables.items()}
    samples=[]; maps={}
    for key,table in tables.items():
        text=MAPPINGS[key].read_text()
        decode=dict(re.findall(r"(?m)^((?:\d{2}\.\d{2}\.\d{2})|\d+)\.\.\.\s*=\s*(\d{2}\.\d{2}\.\d{2})",text))
        mapping={}
        for col in table[0]:
            if not col.startswith("LFQ intensity "):
                continue
            exp=col.removeprefix("LFQ intensity ")
            m=re.fullmatch(r"((?:\d{2}\.\d{2}\.\d{2})|\d+)_?(co|c|dex)([123])",exp)
            assert m and m[1] in decode,(key,col)
            donor,condition,rep=decode[m[1]],"co" if m[2]=="c" else m[2],int(m[3])
            assert (donor,condition,rep) not in mapping
            mapping[(donor,condition,rep)]=exp
            samples.append(dict(array=key,donor=donor,condition=condition,technical_rep=rep,experiment=exp,source_column=col))
        maps[key]=mapping
    csv_out(dest / "sample_map.csv",samples)
    comparisons=[]
    for p in rows(out / "published_measurements.csv"):
        donor,cond,rep=p["donor"],p["condition"],int(p["technical_rep"])
        for key in SPECS:
            rule,rownum,original=lookups[key](p["protein_ids"])
            exp=maps[key].get((donor,cond,rep),"")
            for measure in ["LFQ intensity","Intensity","iBAQ"]:
                col=measure+" "+exp if exp else ""
                value=float(original[col]) if original and col in original else None
                log=math.log2(value) if value is not None and value>0 else None
                published=float(p["published_log2"])
                comparisons.append(dict(**p,array=key,measure=measure,source_row=rownum,mapping=rule,source_column=col,
                    original=value if value is not None else "",original_log2=log if log is not None else "",
                    delta=log-published if log is not None else "",matches_rounding=log is not None and abs(log-published)<=.000051))
    csv_out(dest / "diff_measurement_cross_array.csv",comparisons)
    allrows=rows(out / "all_intensity_cross_array.csv"); summary=[]
    for expected in ["proteome24","proteome72","secretome24","secretome72"]:
        for key in SPECS:
            a=[r for r in allrows if r["expected_array"] == expected and r["array"]==key]
            for measure in ["LFQ intensity","Intensity","iBAQ"]:
                z=[r for r in comparisons if r["expected_array"]==expected and r["array"]==key and r["measure"]==measure]
                finite=[r for r in z if r["delta"]!=""]
                deltas=[r["delta"] for r in finite]
                summary.append(dict(expected_array=expected,array=key,measure=measure,all_rows=len(a),
                    all_resolved=sum(r["mapping"]!="unresolved" for r in a),all_intensity_equal=sum(r["equal"]=="True" for r in a),
                    all_positive_equal=sum(r["equal"]=="True" and float(r["published_intensity"])>0 for r in a),
                    selected_cells=len(z),original_nonzero=len(finite),matches_rounding=sum(r["matches_rounding"] for r in z),
                    original_zero=sum(r["original"]==0 for r in z),unmapped=sum(r["original"]=="" for r in z),
                    delta_min=min(deltas) if deltas else "",delta_max=max(deltas) if deltas else ""))
    csv_out(dest / "cross_array_summary.csv",summary)
    gene_offsets=[]
    z=[r for r in comparisons if r["expected_array"]=="secretome24" and r["array"]=="secretome24" and r["measure"]=="LFQ intensity" and r["delta"]!=""]
    for ids in sorted({r["protein_ids"] for r in z}):
        g=[r for r in z if r["protein_ids"]==ids]
        gene_offsets.append(dict(protein_ids=ids,symbol=g[0]["symbol"],nonzero=len(g),
            delta_mean=float(np.mean([r["delta"] for r in g])),delta_sd=float(np.std([r["delta"] for r in g],ddof=1)),
            delta_min=min(r["delta"] for r in g),delta_max=max(r["delta"] for r in g)))
    csv_out(dest / "secretome24_protein_offsets.csv",gene_offsets)
    json_out(dest / "analysis.json",dict(status="completed",utc=utc(),comparisons=len(comparisons),
        all_comparisons=len(allrows),samples=len(samples),summary=summary,
        note="ALL equal zeros are not positive-intensity source evidence; missing iBAQ columns unavailable not zero"))
    print(json.dumps([r for r in summary if r["measure"]=="LFQ intensity"],ensure_ascii=False,indent=2))


def acquire(out):
    dest=out / "complete"; logs=[]; projects=[]
    queries=PRIDE_QUERIES+["BioExplainR_unrelated_negative_control_9f3f"]
    for i,query in enumerate(queries,1):
        url="https://www.ebi.ac.uk/pride/ws/archive/v2/search/projects?"+urllib.parse.urlencode(dict(keyword=query,pageSize=100,page=0))
        path=out / f"sources/pride_corrected_{i}.json"
        log=fetch(url,path,timeout=30);log.update(query=query)
        logs.append(log)
        if log["status"]=="retrieved":
            data=json.loads(path.read_text()); assert isinstance(data,list)
            log.update(returned=len(data),bounded_search=len(data)<100,negative_control=i==5)
            for r in data:
                projects.append(dict(query=query,accession=r["accession"],title=r["title"],
                    description=r.get("projectDescription",""),sample_protocol=r.get("sampleProcessingProtocol",""),
                    data_protocol=r.get("dataProcessingProtocol",""),metadata=json.dumps(r,ensure_ascii=False)))
    csv_out(dest / "pride_projects.csv",projects,fields=["query","accession","title","description","sample_protocol","data_protocol","metadata"])
    assert not any(r["query"]==queries[-1] for r in projects),"PRIDE negative control not empty"
    papers=rows(out / "literature_records.csv")
    selected=[]
    for r in papers:
        if not r["pmcid"]:
            continue
        include="asm_candidates" in r["queries"] or ("asm_" in r["queries"] and
            re.search(r"proteom|secretom|steroid|fluticasone|glucocorticoid|dexamethasone|extracellular matrix",r["title"],re.I)) or r["pmcid"]=="PMC9562650"
        if include and r["pmcid"] not in selected:
            selected.append(r["pmcid"])
    selected=selected[:30]
    json_out(dest / "fulltext_requests.json",dict(utc=utc(),selected=selected,rule=json.loads((dest / "freeze.json").read_text())["fulltext_selection"]))
    for pmc in selected:
        path=out / f"sources/{pmc}.xml"
        log=fetch(EPMC+pmc+"/fullTextXML",path,timeout=30);logs.append(log)
        if log["status"]=="retrieved":
            try:
                root=ET.parse(path).getroot()
                assert root.tag=="article"
            except Exception as exc:
                log["parse_error"]=str(exc)
    json_out(dest / "source_acquisition.json",dict(utc=utc(),records=logs,fulltext_requested=len(selected)))
    index="\n".join(f"{r['id']} | {r['pmcid']} | {r['title']} | {r['queries']}" for r in papers)+"\n"
    (dest / "literature_titles.txt").write_text(index)
    passages=[]
    for pmc in selected:
        path=out / f"sources/{pmc}.xml"
        if not path.exists():
            continue
        try:
            root=ET.parse(path).getroot()
        except ET.ParseError:
            continue
        for i,p in enumerate(root.iter("p"),1):
            text=" ".join("".join(p.itertext()).split())
            if re.search(r"PXD\d+|PRIDE|ProteomeXchange|ANGPTL2|FSTL3|FBN2|secretom|mass spectrom|multiplex|Data Availability|data availability",text,re.I):
                passages.append(dict(pmcid=pmc,paragraph=i,text=text))
    csv_out(dest / "fulltext_passages.csv",passages,fields=["pmcid","paragraph","text"])
    print(json.dumps(dict(project_hits=len(projects),unique_projects=len({r['accession'] for r in projects}),
        papers=len(papers),fulltext_requested=len(selected),passages=len(passages)),indent=2))


if __name__=="__main__":
    p=argparse.ArgumentParser(description=__doc__);p.add_argument("action",choices=["freeze","analyze","acquire"]);p.add_argument("output",type=Path)
    a=p.parse_args();globals()[a.action](a.output.resolve())
