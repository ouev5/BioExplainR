"""Prepare source-driven follow-up plans and derive design-only table checks."""
import argparse
import csv
import gzip
import hashlib
import io
import json
import re
import textwrap
import urllib.parse
import xml.etree.ElementTree as ET
from pathlib import Path

from public_proteome_continue import OUT, check_frozen, project_text, ASM, LUNG
from validation_sources import ROOT, utc, record, json_out, csv_out


def prepare():
    check_frozen()
    projects = json.loads((OUT / "unique_projects.json").read_text())
    summary = json.loads((OUT / "search_summary.json").read_text())
    extra = set(sum(summary["added_beyond_old_page0"].values(), []))
    sections = []
    for p in projects:
        text = project_text(p)
        if p["accession"] in extra or ASM.search(text) and LUNG.search(text):
            sections.append("## " + p["accession"] + " — " + p["title"])
            for k in ["organisms", "organismsPart", "projectDescription", "sampleProcessingProtocol"]:
                sections.append("\n" + k + ":\n" + textwrap.fill(str(p.get(k, "")), width=100))
    (OUT / "design_metadata_readout.md").write_text("\n\n".join(sections) + "\n")
    rows = [dict(accession=p["accession"], title=p["title"],
        gc_lung_text_match=bool(LUNG.search(project_text(p)) and re.search(r"dexamethasone|budesonide|glucocorticoid|fluticasone|hydrocortisone", project_text(p), re.I))) for p in projects]
    csv_out(OUT / "all_project_titles.csv", rows)
    requests = []
    inventory = json.loads((OUT / "imported/PXD029135_inventory.json").read_text())
    f = next(p for p in inventory if p["fileName"] == "median-normalized.txt")
    ftp = next(p["value"] for p in f["publicFileLocations"] if p["name"] == "FTP Protocol")
    requests.append(dict(name="PXD029135_median-normalized.txt", url=ftp.replace("ftp://", "https://"), expected_file=f))
    articles = ["PMC11161633", "PMC11299423", "PMC5105184", "PMC9361782"]
    for pmc in articles:
        requests.append(dict(name=pmc + ".xml", url=f"https://www.ebi.ac.uk/europepmc/webservices/rest/{pmc}/fullTextXML"))
    epmc_query = urllib.parse.urlencode(dict(query="EXT_ID:32299863 AND SRC:MED", format="json", resultType="core"))
    requests.append(dict(name="intrapulmonary_article.json", url="https://www.ebi.ac.uk/europepmc/webservices/rest/search?" + epmc_query))
    requests.append(dict(name="intrapulmonary_crossref.json", url="https://api.crossref.org/works/10.1183/13993003.02178-2019"))
    for label, keyword in [("zedoarondiol", "zedoarondiol"), ("tas2r", "TAS2R"), ("intrapulmonary_asm", "Intrapulmonary airway smooth muscle")]:
        requests.append(dict(name="targeted_" + label + ".json", url="https://www.ebi.ac.uk/pride/ws/archive/v2/search/projects?" + urllib.parse.urlencode(dict(keyword=keyword, pageSize=100, page=0))))
    json_out(OUT / "processed_and_article_plan.json", dict(utc=utc(), script=record(Path(__file__)),
        source_evidence=[record(OUT / "imported/PXD029135_inventory.json"), record(OUT / "imported/papers_asm_protein_summary.json"),
            record(OUT / "imported/papers_lung_gc_protein_summary.json")], requests=requests,
        reason="Restore missing table with upstream integrity; inspect ASM/fetal secretome article data-availability and actual sample designs"))
    json_out(OUT / "asm_inventory_plan.json", dict(utc=utc(), script=record(Path(__file__)),
        source_evidence=[record(OUT / "unique_projects.json")],
        projects=["PXD014171", "PXD015604", "PXD029550", "PXD055968"],
        reason="Additional airway-remodelling or smooth-muscle identity leads and recheck existing EV complete inventory"))


def review():
    check_frozen()
    plan = json.loads((OUT / "processed_and_article_plan.json").read_text())
    table_path = OUT / "sources/PXD029135_median-normalized.txt"
    checks = []
    if table_path.exists():
        item = plan["requests"][0]["expected_file"]
        raw = table_path.read_bytes()
        rows = list(csv.reader(io.StringIO(raw.decode("utf-8-sig")), delimiter="\t"))
        checks.append(dict(file=record(table_path), expected_bytes=item["fileSizeBytes"], size_matches=len(raw) == item["fileSizeBytes"],
            upstream_sha1=item["checksum"], sha1=hashlib.sha1(raw).hexdigest(), sha1_matches=hashlib.sha1(raw).hexdigest() == item["checksum"].zfill(40),
            data_rows=len(rows)-1, columns=len(rows[0]), header=rows[0], row_width_counts={str(n): sum(len(r)==n for r in rows[1:]) for n in sorted({len(r) for r in rows[1:]})}))
    json_out(OUT / "processed_table_checks.json", dict(utc=utc(), checks=checks))
    passages, links = [], []
    for item in plan["requests"]:
        if not item["name"].endswith(".xml"):
            continue
        path = OUT / "sources" / item["name"]
        log = json.loads((OUT / "requests" / (item["name"] + ".request.json")).read_text())
        if log["status"] != "retrieved":
            continue
        root = ET.fromstring(path.read_bytes())
        for e in root.iter():
            if e.tag in ["p", "table-wrap", "supplementary-material"]:
                text = " ".join("".join(e.itertext()).split())
                if re.search(r"proteom|mass spectrom|data availab|\bPXD|\bGSE|dexamethasone|budesonide|donor", text, re.I):
                    passages.append(dict(article=item["name"], section=e.tag, text=text))
            href = e.get("{http://www.w3.org/1999/xlink}href")
            if href and e.tag in ["ext-link", "supplementary-material", "media"]:
                links.append(dict(article=item["name"], tag=e.tag, href=href, text=" ".join("".join(e.itertext()).split())))
    csv_out(OUT / "article_links.csv", links, fields=["article", "tag", "href", "text"])
    csv_out(OUT / "article_design_passages.csv", passages, fields=["article", "section", "text"])
    output = ["# 原全文设计与数据可及性段落"]
    for r in passages:
        output.extend(["## " + r["article"] + " / " + r["section"], textwrap.fill(r["text"], 100)])
    (OUT / "article_design_readout.md").write_text("\n\n".join(output) + "\n")
    print(json.dumps(checks, ensure_ascii=False, indent=2))
    print(json.dumps(links, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("action", choices=["prepare", "review"])
    globals()[p.parse_args().action]()
