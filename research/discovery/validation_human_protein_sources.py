"""Acquire primary human smooth-muscle proteomics papers and supplemental links."""
import json
import re
import sys
import urllib.request
import xml.etree.ElementTree as ET
from pathlib import Path

from validation_sources import fetch, csv_out, json_out, utc

dest = Path(sys.argv[1]).resolve() / "human_protein"
dest.mkdir(exist_ok=False)
logs = []
links = []
passages = []
for pmc in ["PMC9562650", "PMC12476226"]:
    path = dest / (pmc + ".xml")
    rec = fetch("https://www.ebi.ac.uk/europepmc/webservices/rest/" + pmc + "/fullTextXML", path, 30)
    logs.append(rec)
    if rec["status"] != "retrieved":
        continue
    root = ET.parse(path).getroot()
    for e in root.iter():
        href = e.get("{http://www.w3.org/1999/xlink}href", "")
        if href and (e.tag in ["supplementary-material", "media"] or re.search(r"\.(xlsx|zip|docx|pdf|7z)$", href)):
            links.append({"article": pmc, "tag": e.tag, "href": href, "text": " ".join("".join(e.itertext()).split())})
    for i, p in enumerate(root.iter("p")):
        text = " ".join("".join(p.itertext()).split())
        if re.search(r"PER2|PER3|METTL7A|MAOA|ANGPTL2|FSTL3|donor|patient|GR|siRNA|proteom|mass spect", text, re.I):
            passages.append({"article": pmc, "paragraph": i, "text": text})
    print(pmc, "supplements", [r["href"] for r in links if r["article"] == pmc], flush=True)
csv_out(dest / "supplement_links.csv", links, ["article", "tag", "href", "text"])
csv_out(dest / "passages.csv", passages, ["article", "paragraph", "text"])
for accession in ["PXD033514", "PXD033534"]:
    rec = fetch("https://www.ebi.ac.uk/pride/ws/archive/v2/projects/" + accession, dest / (accession + ".json"), 30)
    logs.append(rec)
json_out(dest / "source_acquisition.json", {"utc": utc(), "records": logs})
