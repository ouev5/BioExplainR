"""Save and extract focused prior literature, including existing clock biology."""
import json
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

from response_literature import fetch
from validate_response import csv_out, write_json

out = Path(sys.argv[1]); lit = out / "literature"; records = []; mentions = []
for pmc in ["PMC8294620", "PMC9879848", "PMC2701960", "PMC12063231"]:
    path = lit / (pmc + ".xml")
    rec = fetch("https://www.ebi.ac.uk/europepmc/webservices/rest/" + pmc + "/fullTextXML", path)
    records.append(rec)
    if rec["status"] != "retrieved":
        continue
    root = ET.parse(path).getroot()
    for i, p in enumerate(root.iter("p")):
        text = " ".join("".join(p.itertext()).split())
        if re.search(r"\b(PER2|PER3|LINC00607|FSTL3|ANGPTL2|METTL7A|MAOA)\b", text, re.I):
            mentions.append({"article": pmc, "paragraph": i, "text": text})
            if pmc == "PMC8294620" and re.search("dex|glucocorticoid", text, re.I):
                print(pmc, text)
csv_out(lit / "focused_fulltext_mentions.csv", mentions)
write_json(out / "focused_fulltext_acquisition.json", {"records": records})
