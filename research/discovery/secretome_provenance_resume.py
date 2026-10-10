"""Resume interrupted public acquisition and inspect the ASM extracellular-vesicle lead."""
import argparse
import json
import re
import urllib.parse
import xml.etree.ElementTree as ET
from pathlib import Path

from secretome_provenance_complete import rows
from validation_sources import EPMC, record, utc, fetch, csv_out, json_out


def main(out):
    dest=out / "complete"
    json_out(dest / "resume_freeze.json",dict(utc=utc(),script=record(Path(__file__)),
        reason="Source acquisition interrupted by120s execution timeout, existing raw responses preserved, no completion assumed",
        new_requests=["PRIDE project/file list PXD055968 (actual ASM EV identity lead, not GC effect)",
            "EPMC exact DOI10.3390/cells11193164 core metadata for source/correction links"],
        scope="Unselected ASM EV identification if public full protein table obtainable; no glucocorticoid response validation"))
    logs=[]
    selected=json.loads((dest / "fulltext_requests.json").read_text())["selected"]
    for pmc in selected:
        path=out / f"sources/{pmc}.xml"; url=EPMC+pmc+"/fullTextXML"
        log=dict(status="retrieved",url=url,reused_after_interruption=True,**record(path)) if path.exists() else fetch(url,path,timeout=15)
        logs.append(log)
        if log["status"]=="retrieved":
            try:
                assert ET.parse(path).getroot().tag=="article"
            except Exception as exc:
                log["parse_error"]=str(exc)
    for label,url in [
        ("PXD055968", "https://www.ebi.ac.uk/pride/ws/archive/v2/projects/PXD055968"),
        ("PXD055968_files", "https://www.ebi.ac.uk/pride/ws/archive/v2/projects/PXD055968/files?pageSize=100&page=0"),
        ("original_article_metadata", EPMC+"search?"+urllib.parse.urlencode(dict(query='DOI:10.3390/cells11193164',format="json",resultType="core"))),
    ]:
        path=out / f"sources/{label}.json";logs.append(fetch(url,path,timeout=30))
    passages=[];links=[]
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
            if re.search(r"PXD\d+|PRIDE|ProteomeXchange|ANGPTL2|FSTL3|FBN2|secretom|mass spectrom|multiplex|data availability",text,re.I):
                passages.append(dict(pmcid=pmc,paragraph=i,text=text))
        for el in root.iter():
            if el.tag in ["ext-link","supplementary-material","media"]:
                href=el.get("{http://www.w3.org/1999/xlink}href","")
                if href:
                    links.append(dict(pmcid=pmc,tag=el.tag,url=href,text=" ".join("".join(el.itertext()).split())))
    csv_out(dest / "fulltext_passages.csv",passages,fields=["pmcid","paragraph","text"])
    csv_out(dest / "fulltext_links.csv",links,fields=["pmcid","tag","url","text"])
    papers=rows(out / "literature_records.csv")
    (dest / "literature_titles.txt").write_text("\n".join(f"{r['id']} | {r['pmcid']} | {r['title']} | {r['queries']}" for r in papers)+"\n")
    json_out(dest / "source_acquisition_resume.json",dict(status="completed",utc=utc(),records=logs,
        pmc_requested=len(selected),pmc_parsed=sum((out/f"sources/{p}.xml").exists() for p in selected),
        previous_corrected_pride="Five raw corrected search responses and saved project table preserved, first process interrupted before final source log"))
    print(json.dumps(dict(papers=len(papers),pmc_requested=len(selected),passages=len(passages),links=len(links)),indent=2))


if __name__=="__main__":
    p=argparse.ArgumentParser();p.add_argument("output",type=Path);main(p.parse_args().output.resolve())
