"""Condense saved searches to inspectable titles and abstract co-mentions."""
import json
import re
import sys
from pathlib import Path

from validate_response import csv_out


out = Path(sys.argv[1]); lit = out / "literature"
summary = []; fulltext_ids = set()
for label in ["PER2_ASM", "clock_ASM", "FSTL3_ASM", "LINC00607"]:
    data = json.loads((lit / (label + ".json")).read_text())
    print("\nSEARCH", label, data["hitCount"])
    for r in data["resultList"]["result"]:
        title = r.get("title", ""); abstract = re.sub("<[^>]+>", " ", r.get("abstractText", ""))
        summary.append({"search": label, "title": title, "pmcid": r.get("pmcid", ""), "doi": r.get("doi", ""), "abstract": abstract})
        if label == "LINC00607" or re.search(r"circadian|clock|glucocorticoid|budesonide|dexamethasone|smooth muscle", title, re.I):
            print(r.get("pmcid", ""), r.get("doi", ""), title)
            if label == "LINC00607" or re.search(r"PER2|PER3|TEF|FSTL3|ANGPTL2|METTL7A|MAOA", abstract, re.I):
                print(abstract)
            if r.get("pmcid"):
                fulltext_ids.add(r["pmcid"])
csv_out(lit / "focused_search_digest.csv", summary)
(lit / "focused_fulltext_ids.json").write_text(json.dumps(sorted(fulltext_ids), indent=2) + "\n")
