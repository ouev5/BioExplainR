"""Acquire original supplement and expose tables needed for sample pairing."""
import json
from pathlib import Path
import re
import urllib.request
import xml.etree.ElementTree as ET

OUT = Path("research/results/discovery_donors_v1")
tree = ET.parse(OUT / "PMC6604213.xml")
(OUT / "paper_tables.txt").write_text("\n\n".join(" ".join(el.itertext()) for el in tree.iter("table-wrap"))+"\n")
url = "https://pmc.ncbi.nlm.nih.gov/articles/PMC6604213/"
with urllib.request.urlopen(url, timeout=60) as r: html = r.read().decode()
links = sorted(set(re.findall(r'href="([^"]*(?:supplement|Supplement|supp|_data_)[^"]*)"', html)))
(OUT / "supplement_links.json").write_text(json.dumps({"url": url, "links": links}, indent=2)+"\n")
print(json.dumps(links, indent=2))
