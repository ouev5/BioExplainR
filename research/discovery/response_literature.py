"""Save scoped Europe PMC searches and original-paper candidate mentions."""
import json
import re
import sys
import time
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET
from datetime import datetime, timezone
from pathlib import Path

from validate_response import ROOT, csv_out, rows, sha, write_json


def fetch(url, path):
    for attempt in range(3):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "BioExplainR-public-reanalysis/0.4"})
            with urllib.request.urlopen(req, timeout=45) as response:
                blob = response.read()
            path.write_bytes(blob)
            return {"status": "retrieved", "url": url, "path": path.name, "sha256": sha(path),
                    "retrieved_utc": datetime.now(timezone.utc).isoformat()}
        except Exception as exc:
            error = str(exc)
            time.sleep(1)
    return {"status": "failed", "url": url, "error": error, "path": path.name}


def run(out):
    dest = out / "literature"; dest.mkdir(exist_ok=False)
    ann = rows(out / "candidate_annotation.csv"); mentions = []
    articles = [ROOT / "research/results/discovery_context_v1/PMC9331514.xml",
                ROOT / "research/results/discovery_donors_v1/PMC6604213.xml",
                ROOT / "research/results/discovery_context_v1/PMC4057123.xml"]
    for p in articles:
        root = ET.parse(p).getroot()
        paragraphs = [" ".join("".join(e.itertext()).split()) for e in root.iter("p")]
        for a in ann:
            if not a["symbols"]:
                continue
            for i, text in enumerate(paragraphs):
                if re.search(r"(?<![\w-])" + re.escape(a["symbols"]) + r"(?![\w-])", text, re.I):
                    mentions.append({"article": p.stem, "symbol": a["symbols"], "paragraph_index": i, "text": text})
    csv_out(dest / "original_paper_mentions.csv", mentions, fields=["article", "symbol", "paragraph_index", "text"])
    queries = [(a["symbols"], f'({a["symbols"]}) AND (glucocorticoid OR dexamethasone OR budesonide)')
               for a in ann if a["symbols"]]
    queries += [("LINC00607", 'LINC00607 AND (glucocorticoid OR dexamethasone OR budesonide)'),
                ("PER2_ASM", 'PER2 AND ("airway smooth muscle" OR "bronchial smooth muscle")'),
                ("clock_ASM", '(PER2 OR PER3 OR TEF OR circadian) AND "airway smooth muscle" AND (glucocorticoid OR dexamethasone OR budesonide)'),
                ("FSTL3_ASM", '(FSTL3 OR ANGPTL2 OR METTL7A OR MAOA) AND "airway smooth muscle" AND (glucocorticoid OR dexamethasone OR budesonide)')]
    log = []
    for label, query in queries:
        url = "https://www.ebi.ac.uk/europepmc/webservices/rest/search?" + urllib.parse.urlencode({
            "query": query, "format": "json", "resultType": "core", "pageSize": 100})
        path = dest / (label + ".json"); rec = fetch(url, path); rec.update(label=label, query=query)
        if rec["status"] == "retrieved":
            data = json.loads(path.read_text()); rec["hit_count"] = data["hitCount"]
            rec["returned"] = len(data.get("resultList", {}).get("result", []))
            print(label, rec["hit_count"])
        log.append(rec)
    lookup_url = "https://rest.ensembl.org/lookup/id/ENSG00000235770?content-type=application/json"
    lookup = fetch(lookup_url, dest / "LINC00607_ensembl.json")
    write_json(out / "literature_search.json", {"searches": log, "mapping": lookup,
        "original_papers": [{"path": str(p.relative_to(ROOT)), "sha256": sha(p)} for p in articles],
        "scope": "Europe PMC indexed metadata/abstract/full-text-search; returned first 100 core records. No-hit is not proof of novelty."})


if __name__ == "__main__":
    run(Path(sys.argv[1]))
