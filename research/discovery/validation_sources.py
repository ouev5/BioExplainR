"""Acquire auditable, scoped public sources for adult ASM validation follow-up."""
import argparse
import csv
import gzip
import hashlib
import json
import time
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET
from html.parser import HTMLParser
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
EPMC = "https://www.ebi.ac.uk/europepmc/webservices/rest/"
ENTREZ = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/"


def utc():
    return datetime.now(timezone.utc).isoformat()


def record(path):
    path = path.resolve()
    h = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            h.update(block)
    return {"path": path.relative_to(ROOT).as_posix(), "bytes": path.stat().st_size,
            "sha256": h.hexdigest()}


def json_out(path, obj):
    if path.exists():
        raise ValueError(f"Refusing to overwrite {path}")
    path.write_text(json.dumps(obj, ensure_ascii=False, indent=2, allow_nan=False) + "\n")


def csv_out(path, data, fields=None):
    if path.exists():
        raise ValueError(f"Refusing to overwrite {path}")
    with path.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, fieldnames=fields or list(data[0]))
        writer.writeheader()
        writer.writerows(data)


def fetch(url, path, timeout=90):
    if path.exists():
        raise ValueError(f"Refusing to overwrite {path}")
    attempts = []
    for i in range(3):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "BioExplainR-public-validation/0.4"})
            with urllib.request.urlopen(req, timeout=timeout) as response:
                blob = response.read()
                status = response.status
                content_type = response.headers.get("Content-Type", "")
            path.write_bytes(blob)
            return {"status": "retrieved", "url": url, "retrieved_utc": utc(),
                    "http_status": status, "content_type": content_type,
                    "attempts": attempts, **record(path)}
        except Exception as exc:
            attempts.append({"utc": utc(), "error": str(exc), "attempt": i + 1})
            time.sleep(i + 1)
    return {"status": "failed", "url": url, "path": str(path.resolve().relative_to(ROOT)), "attempts": attempts}


GEO_QUERIES = {
    "asm_steroid": '("airway smooth muscle" OR "bronchial smooth muscle") AND '
                   '(dexamethasone OR glucocorticoid OR budesonide) AND gse[ETYP]',
    "asm_time": '("airway smooth muscle" OR "bronchial smooth muscle") AND '
                '(time OR circadian OR period OR rhythm) AND gse[ETYP]',
    "asm_gr_genetic": '("airway smooth muscle" OR "bronchial smooth muscle") AND '
                      '(NR3C1 OR "glucocorticoid receptor") AND '
                      '(knockdown OR siRNA OR CRISPR OR silencing OR knockout) AND gse[ETYP]',
    "hsm_steroid": '("Homo sapiens"[ORGN]) AND "smooth muscle" AND '
                   '(dexamethasone OR budesonide) AND gse[ETYP]',
}
LITERATURE_QUERIES = {
    "asm_clock": 'TITLE_ABS:("airway smooth muscle" OR "bronchial smooth muscle") AND '
                 'TITLE_ABS:(circadian OR PER2 OR PER3 OR clock)',
    "asm_gr_genetic": 'TITLE_ABS:("airway smooth muscle" OR "bronchial smooth muscle") AND '
                      'TITLE_ABS:("glucocorticoid receptor" OR NR3C1) AND '
                      'TITLE_ABS:(siRNA OR knockdown OR silencing OR CRISPR OR knockout)',
    "asm_steroid_time": 'TITLE_ABS:("airway smooth muscle" OR "bronchial smooth muscle") AND '
                        'TITLE_ABS:(dexamethasone OR budesonide OR glucocorticoid) AND '
                        'TITLE_ABS:(time OR temporal OR transcriptome OR profiling)',
    "per2_asm_fulltext": 'PER2 AND ("airway smooth muscle" OR "bronchial smooth muscle")',
    "secondary_asm": '(PER3 OR METTL7A OR MAOA OR ANGPTL2 OR FSTL3) AND '
                     '("airway smooth muscle" OR "bronchial smooth muscle")',
    "per2_gr_genetic": 'TITLE_ABS:(PER2) AND TITLE_ABS:(NR3C1 OR "glucocorticoid receptor") AND '
                       'TITLE_ABS:(siRNA OR knockout OR knockdown OR CRISPR)',
}


def search(out, resume=False):
    out.mkdir(exist_ok=resume)
    dest = out / "sources"
    dest.mkdir(exist_ok=resume)
    if resume:
        assert (out / "search_freeze.json").exists()
        number = 1
        while (out / f"search_resume_amendment_{number}.json").exists():
            number += 1
        json_out(out / f"search_resume_amendment_{number}.json", {"utc": utc(), "script": record(Path(__file__)),
                 "reason": "Handle missing paper title and verify saved series table on resume; reuse raw downloads; original freeze unchanged."})
    else:
        (out / "rgo_before_validation.md").write_bytes((ROOT / "rgo.md").read_bytes())
        json_out(out / "search_freeze.json", {
        "frozen_utc": utc(), "protocol": record(HERE / "VALIDATION_CONTINUATION_PROTOCOL.md"),
        "script": record(Path(__file__)), "geo_queries": GEO_QUERIES,
        "literature_queries": LITERATURE_QUERIES,
        "candidates": ["PER2", "PER3", "METTL7A", "MAOA", "ANGPTL2", "FSTL3"],
        "controls": ["FKBP5", "TSC22D3", "DUSP1"],
        "literature_page_size": 100, "max_pages": 10,
        "timing": "Prior PER2 results known; new series candidate expression not examined."})
    def acquire(url, path):
        if resume and path.exists():
            return {"status": "retrieved", "url": url, "reuse_saved_on_resume": True, **record(path)}
        return fetch(url, path)
    logs = []
    ids = set()
    for label, term in GEO_QUERIES.items():
        url = ENTREZ + "esearch.fcgi?" + urllib.parse.urlencode({
            "db": "gds", "term": term, "retmax": 1000, "retmode": "json"})
        path = dest / ("geo_" + label + ".json")
        rec = acquire(url, path)
        rec.update(label=label, query=term)
        if rec["status"] == "retrieved":
            data = json.loads(path.read_text())["esearchresult"]
            rec.update(hit_count=int(data["count"]), returned=len(data["idlist"]))
            assert int(data["count"]) == len(data["idlist"]), "GEO pagination required"
            ids.update(data["idlist"])
            print(label, rec["hit_count"], flush=True)
        logs.append(rec)
        time.sleep(.4)
    compact = []
    for uid in sorted(ids):
        url = ENTREZ + "esummary.fcgi?" + urllib.parse.urlencode({"db": "gds", "id": uid, "retmode": "json"})
        path = dest / ("geo_summary_" + uid + ".json")
        rec = acquire(url, path)
        if rec["status"] == "retrieved":
            r = json.loads(path.read_text())["result"][uid]
            row = {k: r.get(k, "") for k in ["uid", "accession", "title", "summary", "taxon", "gpl", "n_samples"]}
            row["gpl"] = str(row["gpl"])
            compact.append(row)
            print(row["accession"], row["n_samples"], row["title"], flush=True)
        logs.append(rec)
        time.sleep(.4)
    if resume and (out / "geo_series.csv").exists():
        with (out / "geo_series.csv").open(newline="") as stream:
            saved = list(csv.DictReader(stream))
        assert saved == [{k: str(v) for k, v in row.items()} for row in compact]
    else:
        csv_out(out / "geo_series.csv", compact)
    papers = {}
    for label, query in LITERATURE_QUERIES.items():
        query += " AND FIRST_PDATE:[1900-01-01 TO 2026-10-09]"
        cursor = "*"
        returned = 0
        complete = False
        for page in range(10):
            url = EPMC + "search?" + urllib.parse.urlencode({"query": query, "format": "json", "resultType": "core",
                                                          "pageSize": 100, "cursorMark": cursor})
            path = dest / f"epmc_{label}_{page + 1}.json"
            rec = acquire(url, path)
            rec.update(label=label, query=query, page=page + 1)
            logs.append(rec)
            if rec["status"] != "retrieved":
                break
            data = json.loads(path.read_text())
            results = data.get("resultList", {}).get("result", [])
            returned += len(results)
            rec.update(hit_count=data["hitCount"], returned=len(results))
            for r in results:
                key = r["source"] + ":" + r["id"]
                if key not in papers:
                    papers[key] = {"id": r["id"], "source": r["source"], "pmcid": r.get("pmcid", ""),
                                   "title": r.get("title", "[metadata title missing]"), "doi": r.get("doi", ""), "year": r.get("pubYear", ""),
                                   "abstract": r.get("abstractText", ""), "queries": []}
                papers[key]["queries"].append(label)
            if returned >= data["hitCount"]:
                complete = True
                break
            cursor = data["nextCursorMark"]
        print("literature", label, returned, "complete", complete, flush=True)
        logs[-1]["query_complete"] = complete
    csv_out(out / "literature_records.csv", [dict(r, queries="|".join(sorted(set(r["queries"])))) for r in papers.values()])
    json_out(out / "search_acquisition.json", {"completed_utc": utc(), "records": logs,
             "series": len(compact), "papers": len(papers), "scope": "Scoped indexed search; no-hit is not proof of absence."})


def metadata(out, accessions):
    out.mkdir(exist_ok=True)
    dest = out / "sources"
    dest.mkdir(exist_ok=True)
    logs = []
    rows = []
    for acc in accessions:
        bucket = acc[:-3] + "nnn"
        url = f"https://ftp.ncbi.nlm.nih.gov/geo/series/{bucket}/{acc}/soft/{acc}_family.soft.gz"
        path = dest / (acc + "_family.soft.gz")
        rec = {"status": "retrieved", "url": url, "reuse_saved_after_interruption": True, **record(path)} if path.exists() else fetch(url, path, timeout=45)
        logs.append(rec)
        if rec["status"] != "retrieved":
            continue
        text = gzip.decompress(path.read_bytes()).decode("utf-8")
        sample = ""
        meta = []
        for line in text.splitlines():
            if line.startswith("^SAMPLE = "):
                sample = line.split(" = ", 1)[1]
            if line.startswith(("^", "!Series_", "!Sample_")):
                meta.append(line)
            if line.startswith("!Sample_") and " = " in line:
                field, value = line.split(" = ", 1)
                rows.append({"study": acc, "sample": sample, "field": field[1:], "value": value})
        (dest / (acc + "_metadata.txt")).write_text("\n".join(meta) + "\n")
        print(acc, "samples", len({r["sample"] for r in rows if r["study"] == acc}), flush=True)
        for line in meta:
            if line.startswith(("!Series_title", "!Series_overall_design", "!Sample_title", "!Series_supplementary_file")):
                print(line, flush=True)
    csv_out(out / "geo_sample_metadata.csv", rows)
    json_out(out / "metadata_acquisition.json", {"records": logs, "completed_utc": utc(),
             "scope": "Metadata fields read; expression tables not used for design selection."})


class ArticleHTML(HTMLParser):
    def __init__(self):
        super().__init__()
        self.tag_stack = []
        self.current = None
        self.blocks = []
        self.tables = {}
        self.table_id = None
        self.row = None
        self.cell = None

    def handle_starttag(self, tag, attrs):
        attr = dict(attrs)
        self.tag_stack.append((tag, attr))
        if tag == "table":
            self.table_id = next((a.get("id") for t, a in reversed(self.tag_stack) if a.get("id")), "unknown")
            self.tables.setdefault(self.table_id, [])
        if tag == "tr" and self.table_id:
            self.row = []
        if tag in ("td", "th") and self.row is not None:
            self.cell = []
        if tag in ("p", "h1", "h2", "h3", "h4", "h5", "figcaption") and self.current is None:
            self.current = [tag, []]

    def handle_data(self, data):
        if self.current is not None:
            self.current[1].append(data)
        if self.cell is not None:
            self.cell.append(data)

    def handle_endtag(self, tag):
        if self.current is not None and tag == self.current[0]:
            self.blocks.append(" ".join("".join(self.current[1]).split()))
            self.current = None
        if tag in ("td", "th") and self.cell is not None:
            self.row.append(" ".join("".join(self.cell).split()))
            self.cell = None
        if tag == "tr" and self.row is not None:
            self.tables[self.table_id].append(self.row)
            self.row = None
        if tag == "table":
            self.table_id = None
        while self.tag_stack:
            popped, _ = self.tag_stack.pop()
            if popped == tag:
                break


def article_html(out, pmcs, suffix=""):
    logs = []
    passages = []
    for pmc in pmcs:
        path = out / "sources" / (pmc + "_article" + suffix + ".html")
        rec = fetch("https://pmc.ncbi.nlm.nih.gov/articles/" + pmc + "/" + ("?report=xml" if suffix else ""), path)
        logs.append(rec)
        if rec["status"] != "retrieved":
            continue
        parser = ArticleHTML()
        parser.feed(path.read_text())
        valid = (pmc in path.read_text() and len(parser.blocks) > 30 and
                 any("METHODS" in p.upper() or "MATERIALS" in p.upper() for p in parser.blocks))
        rec["validated_article"] = valid
        if not valid:
            continue
        csv_out(out / (pmc + "_paragraphs.csv"), [{"article": pmc, "paragraph": i, "text": p} for i, p in enumerate(parser.blocks)])
        json_out(out / (pmc + "_tables.json"), parser.tables)
        import re
        for i, p in enumerate(parser.blocks):
            if re.search(r"PER2|PER3|FSTL3|donor|adult|siRNA|knockdown|NR3C1|rescue|12.hour|24.hour", p, re.I):
                passages.append({"article": pmc, "paragraph": i, "text": p})
        print(pmc, "valid article", valid, "paragraphs", len(parser.blocks), "tables", list(parser.tables), flush=True)
    csv_out(out / ("article_html_passages" + suffix + ".csv"), passages, ["article", "paragraph", "text"])
    json_out(out / ("article_html_acquisition" + suffix + ".json"), {"records": logs, "completed_utc": utc()})


def fulltext(out, pmcs):
    dest = out / "sources"
    logs = []
    passages = []
    for pmc in pmcs:
        path = dest / (pmc + ".xml")
        rec = fetch(EPMC + pmc + "/fullTextXML", path, timeout=45)
        logs.append(rec)
        if rec["status"] != "retrieved":
            # PMC BioC provides a separate text interface for non-OA author manuscripts.
            path = dest / (pmc + "_bioc.xml")
            rec = fetch("https://www.ncbi.nlm.nih.gov/research/bionlp/RESTful/pmcoa.cgi/BioC_xml/" + pmc + "/unicode", path)
            logs.append(rec)
        if rec["status"] != "retrieved":
            continue
        try:
            root = ET.parse(path).getroot()
        except ET.ParseError as exc:
            rec["parse_error"] = str(exc)
            continue
        if list(root.iter("passage")):
            blocks = [" ".join(" ".join(t.text or "" for t in p.iter("text")).split()) for p in root.iter("passage")]
        else:
            blocks = [" ".join("".join(p.itertext()).split()) for p in root.iter("p")]
        import re
        for i, block in enumerate(blocks):
            if re.search(r"PER2|PER3|METTL7A|MAOA|ANGPTL2|FSTL3|donor|adult|fetal|siRNA|knockdown|NR3C1|GSE\d+|time.point|circadian|calcium|rescue", block, re.I):
                passages.append({"article": pmc, "paragraph": i, "text": block})
        rec["parsed_passages"] = len(blocks)
        print(pmc, "parsed passages", len(blocks), flush=True)
    csv_out(out / "fulltext_passages.csv", passages, ["article", "paragraph", "text"])
    json_out(out / "fulltext_acquisition.json", {"records": logs, "completed_utc": utc()})


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=["search", "metadata", "fulltext", "article_html", "article_alt"])
    parser.add_argument("output", type=Path)
    parser.add_argument("identifiers", nargs="*")
    parser.add_argument("--resume", action="store_true")
    args = parser.parse_args()
    args.output = args.output.resolve()
    if args.action == "search":
        search(args.output, args.resume)
    elif args.action == "article_alt":
        article_html(args.output, args.identifiers, "_alt")
    else:
        globals()[args.action](args.output, args.identifiers)
