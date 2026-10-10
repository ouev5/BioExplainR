"""Acquire explicit ASM EV source and file linkage without reading candidate effects."""
import argparse
import json
import urllib.parse
import xml.etree.ElementTree as ET
from pathlib import Path
from validation_sources import EPMC, utc, record, json_out, csv_out, fetch


def main(out):
    dest=out / "complete"; files=json.loads((out / "sources/PXD055968_files.json").read_text())
    inventory=[]
    for r in files:
        urls=[v["value"].replace("ftp://","https://") for v in r["publicFileLocations"] if v["value"].startswith("ftp://")]
        inventory.append(dict(fileName=r["fileName"],bytes=r["fileSizeBytes"],category=r["fileCategory"]["value"],url=urls[0] if urls else ""))
    csv_out(dest / "PXD055968_files.csv",inventory)
    requests=[("ev_article_metadata.json",EPMC+"search?"+urllib.parse.urlencode(dict(query="EXT_ID:40487443 AND SRC:MED",format="json",resultType="core"))),
        ("PXD055968_Link_between_files.xlsx",next(r["url"] for r in inventory if r["fileName"]=="Link_between_files.xlsx")),
        ("PTX3_article.xml",EPMC+"PMC6706008/fullTextXML"),
        ("cough_article.xml",EPMC+"PMC5686396/fullTextXML")]
    json_out(dest / "lead_freeze.json",dict(utc=utc(),script=record(Path(__file__)),requests=requests,
        scope="Public material feasibility and candidate identification only; article metadata inspected, no new protein candidate array read"))
    logs=[]
    for name,url in requests:
        path=out / "sources" / name
        logs.append(fetch(url,path,timeout=30))
    path=out / "sources/ev_article_metadata.json"
    if path.exists():
        r=json.loads(path.read_text())["resultList"]["result"][0]
        if r.get("pmcid"):
            path=out / f"sources/{r['pmcid']}.xml"
            logs.append(fetch(EPMC+r["pmcid"]+"/fullTextXML",path,timeout=30))
            if path.exists():
                root=ET.parse(path).getroot()
                links=[];passages=[]
                for el in root.iter():
                    href=el.get("{http://www.w3.org/1999/xlink}href","")
                    if el.tag in ["supplementary-material","media","ext-link"] and href:
                        links.append(dict(tag=el.tag,url=href,text=" ".join("".join(el.itertext()).split())))
                for i,p in enumerate(root.iter("p"),1):
                    passages.append(dict(paragraph=i,text=" ".join("".join(p.itertext()).split())))
                csv_out(dest / "ev_article_links.csv",links)
                csv_out(dest / "ev_article_passages.csv",passages)
    json_out(dest / "lead_acquisition.json",dict(utc=utc(),records=logs))
    print(json.dumps(inventory,indent=2))


if __name__=="__main__":
    p=argparse.ArgumentParser();p.add_argument("output",type=Path);main(p.parse_args().output.resolve())
