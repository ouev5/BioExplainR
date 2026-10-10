"""Search public genetic and protein validation datasets with saved query evidence."""
import argparse
import json
import time
import urllib.parse
from pathlib import Path

from validation_sources import ENTREZ, EPMC, fetch, json_out, csv_out, record, utc

QUERIES = {
    "human_gr_genetic": '"Homo sapiens"[ORGN] AND (NR3C1 OR "glucocorticoid receptor") AND '
                        '(knockout OR knockdown OR CRISPR OR siRNA OR depleted) AND gse[ETYP]',
    "gr_genetic_dex": '(NR3C1 OR "glucocorticoid receptor") AND '
                      '(knockout OR knockdown OR CRISPR OR siRNA) AND dexamethasone AND gse[ETYP]',
    "asm_protein": '("airway smooth muscle" OR "bronchial smooth muscle") AND '
                   '(proteomic OR proteomics OR protein) AND gse[ETYP]',
}
LITERATURE = {
    "gc_proteomics": 'TITLE_ABS:(dexamethasone OR glucocorticoid OR budesonide) AND '
                     'TITLE_ABS:(proteomics OR proteomic) AND TITLE_ABS:(A549 OR smooth OR lung OR airway OR PER2)',
    "per2_gr_function": 'TITLE_ABS:(PER2) AND TITLE_ABS:(glucocorticoid OR dexamethasone) AND '
                        'TITLE_ABS:(protein OR knockout OR knockdown OR reporter OR function)',
}


def acquire(url, path):
    return {"status": "retrieved", "url": url, "reuse_saved": True, **record(path)} if path.exists() else fetch(url, path, 30)


def run(out):
    sources = out / "cross_sources"
    sources.mkdir(exist_ok=True)
    if not (out / "cross_search_freeze.json").exists():
        json_out(out / "cross_search_freeze.json", {"utc": utc(), "script": record(Path(__file__)),
                 "geo_queries": QUERIES, "literature_queries": LITERATURE,
                 "reason": "User requests public datasets instead of wet experiments; genetic GR can be cross-tissue support only."})
    logs = []
    ids = set()
    for label, query in QUERIES.items():
        url = ENTREZ + "esearch.fcgi?" + urllib.parse.urlencode({"db": "gds", "term": query, "retmax": 1000, "retmode": "json"})
        path = sources / (label + ".json")
        rec = acquire(url, path)
        logs.append(rec)
        if rec["status"] == "retrieved":
            r = json.loads(path.read_text())["esearchresult"]
            assert int(r["count"]) == len(r["idlist"])
            ids.update(r["idlist"])
            print(label, r["count"], flush=True)
        time.sleep(.4)
    data = []
    # One compact response per series avoids multi-record sample payloads.
    for uid in sorted(ids):
        url = ENTREZ + "esummary.fcgi?" + urllib.parse.urlencode({"db": "gds", "id": uid, "retmode": "json"})
        path = sources / ("series_" + uid + ".json")
        rec = acquire(url, path)
        logs.append(rec)
        if rec["status"] == "retrieved":
            r = json.loads(path.read_text())["result"][uid]
            data.append({k: str(r.get(k, "")) for k in ["accession", "title", "summary", "taxon", "gpl", "n_samples"]})
            print(r["accession"], r["n_samples"], r["title"], flush=True)
        time.sleep(.4)
    csv_out(out / "cross_geo_series.csv", data)
    papers = []
    for label, query in LITERATURE.items():
        query += " AND FIRST_PDATE:[1900-01-01 TO 2026-10-09]"
        cursor = "*"
        returned = 0
        for page in range(10):
            url = EPMC + "search?" + urllib.parse.urlencode({"query": query, "format": "json", "resultType": "core", "pageSize": 100, "cursorMark": cursor})
            path = sources / f"{label}_{page + 1}.json"
            rec = acquire(url, path)
            logs.append(rec)
            if rec["status"] != "retrieved":
                break
            r = json.loads(path.read_text())
            records = r.get("resultList", {}).get("result", [])
            returned += len(records)
            for p in records:
                papers.append({"query": label, "id": p["id"], "pmcid": p.get("pmcid", ""), "title": p.get("title", ""),
                               "doi": p.get("doi", ""), "abstract": p.get("abstractText", "")})
            if returned >= r["hitCount"]:
                rec["query_complete"] = True
                break
            cursor = r["nextCursorMark"]
        print(label, "records", returned, flush=True)
    csv_out(out / "cross_literature.csv", papers)
    json_out(out / "cross_search_acquisition.json", {"utc": utc(), "records": logs})


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", type=Path)
    run(parser.parse_args().output.resolve())
