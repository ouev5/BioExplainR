"""Review acquired repository metadata and retain bounded HAL PDF attempts."""
import argparse
from collections import Counter
import json
from html.parser import HTMLParser
from pathlib import Path
import re
import subprocess
import xml.etree.ElementTree as ET

from asm_ev_materials import OUT, DOI
from validation_sources import ROOT, utc, record, json_out, csv_out


class Links(HTMLParser):
    def __init__(self):
        super().__init__()
        self.downloads = set()

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag == "a" and "/file/" in attrs.get("href", ""):
            self.downloads.add(attrs["href"])


def pdf():
    dest = OUT / "sources/hal_author_article_curl.bin"
    if dest.exists():
        raise ValueError(f"Refusing overwrite {dest}")
    url = "https://hal.science/hal-05063440v1/file/celle%20et%20al.%202025.pdf"
    command = ["curl", "--location", "--max-time", "60", "--connect-timeout", "15",
        "--fail-with-body", "--silent", "--show-error", "--user-agent", "BioExplainR-final-materials/0.4", url]
    json_out(OUT / "hal_pdf_curl_plan.json", dict(utc=utc(), script=record(Path(__file__)),
        command=command, source=record(OUT / "sources/hal_record_full.json"),
        reason="Two urllib attempts interrupted at 45s/180s without a saved body; bounded total curl timeout",
        candidate_identity_started=False))
    started = utc()
    proc = subprocess.run(command, capture_output=True, timeout=75)
    dest.write_bytes(proc.stdout)
    log = dict(started_utc=started, completed_utc=utc(), command=command, exit_code=proc.returncode,
        url=url, response=record(dest), stderr=proc.stderr.decode("utf-8", "replace"),
        status="retrieved" if proc.returncode == 0 else "failed_or_partial")
    if proc.returncode == 0 and proc.stdout.startswith(b"%PDF-"):
        text = subprocess.run(["pdftotext", "-layout", str(dest), "-"], capture_output=True, timeout=30)
        log["text_extract_exit_code"] = text.returncode
        if text.returncode == 0:
            path = OUT / "hal_author_article_text.txt"
            path.write_bytes(text.stdout)
            log["text"] = record(path)
    json_out(OUT / "hal_pdf_curl_acquisition.json", log)
    print(json.dumps(log, ensure_ascii=False, indent=2))


def review():
    inputs = [p for p in sorted((OUT / "sources").iterdir()) if p.is_file()]
    inputs += list(sorted(OUT.glob("*acquisition.json")))
    json_out(OUT / "review_freeze.json", dict(utc=utc(), script=record(Path(__file__)),
        inputs=[record(p) for p in inputs], candidate_identity_started=False,
        scope="Post-acquisition source review, not candidate identity freeze"))
    logs = []
    for name in ["acquisition.json", "hal_followup_plan_acquisition.json"]:
        logs.extend(json.loads((OUT / name).read_text())["records"])
    routes = []
    for log in logs:
        row = dict(name=log["name"], url=log["url"], status=log["status"],
            http_status=log.get("http_status", ""), response=log.get("response", {}).get("path", ""),
            detail=log.get("error", ""))
        if log["status"] == "retrieved" and log["name"].startswith("hal_") and log["name"].endswith(".json"):
            response = json.loads((ROOT / row["response"]).read_text())["response"]
            assert response["numFound"] == len(response["docs"]), "HAL pagination required"
            row["detail"] = f'Valid HAL response: indexed hits={response["numFound"]}'
        elif log["status"] == "retrieved" and log["name"].startswith("rdg_"):
            value = json.loads((ROOT / row["response"]).read_text())
            assert value["status"] == "OK"
            data = value["data"]
            assert data["total_count"] == len(data["items"]), "RDG pagination required"
            row["detail"] = f'Valid RDG response: indexed hits={data["total_count"]}'
        routes.append(row)
    curl = json.loads((OUT / "hal_pdf_curl_acquisition.json").read_text())
    routes.append(dict(name="hal_author_article_curl.bin", url=curl["url"], status=curl["status"],
        http_status="", response=curl["response"]["path"], detail=f'curl exit={curl["exit_code"]}; {curl["stderr"]}'))
    csv_out(OUT / "public_routes_review.csv", routes)

    inventories, scope = [], []
    for acc in ["PXD055968", "PXD055949", "PXD059603"]:
        value = json.loads((OUT / "sources" / (acc + "_files.json")).read_text())
        project = json.loads((OUT / "sources" / (acc + "_project.json")).read_text())
        assert project["accession"] == acc
        log = next(r for r in logs if r["name"] == acc + "_files.json")
        headers = {k.lower(): v for k, v in log["headers"].items()}
        assert len(value) == int(headers["total_records"]) < 100
        assert len({r["fileName"] for r in value}) == len(value)
        assert all(acc in r["projectAccessions"] for r in value)
        counts = Counter(Path(r["fileName"]).suffix for r in value)
        for r in value:
            inventories.append(dict(project=acc, name=r["fileName"], bytes=r["fileSizeBytes"],
                category=r["fileCategory"]["value"],
                url="|".join(x["value"] for x in r["publicFileLocations"] if x["value"].startswith("ftp://"))))
        scope.append(dict(project=acc, title=project["title"], files=len(value),
            extensions=json.dumps(dict(sorted(counts.items())), sort_keys=True),
            scope="BSM EV preparations" if acc == "PXD055968" else "EV-challenged bronchial epithelium; not BSM EV array",
            table_candidates="|".join(r["fileName"] for r in value if Path(r["fileName"]).suffix.lower() in {".csv", ".tsv", ".xlsx", ".txt"})))
    old = json.loads((ROOT / "research/results/discovery_asm_ev_export_v1/sources/files_corrected.json").read_text())
    fresh = json.loads((OUT / "sources/PXD055968_files.json").read_text())
    stable = lambda rows: sorted((r["fileName"], r["fileSizeBytes"], r["accession"]) for r in rows)
    assert stable(old) == stable(fresh), "PXD055968 inventory changed: inspect before accepting"
    csv_out(OUT / "related_project_inventory.csv", inventories)
    csv_out(OUT / "related_project_scope.csv", scope)

    doc = json.loads((OUT / "sources/hal_record_full.json").read_text())["response"]["docs"][0]
    assert doc["doiId_s"] == DOI and doc["halId_s"] == "hal-05063440"
    parser = Links()
    parser.feed((OUT / "sources/hal_record_page.html").read_text())
    normalize = lambda url: url.replace("hal-05063440v1/", "hal-05063440/")
    assert {normalize(u) for u in parser.downloads} == set(doc["files_s"])
    tei = ET.fromstring(doc["label_xml"])
    refs = [dict(tag=e.tag.rsplit("}", 1)[-1], **e.attrib) for e in tei.iter() if "target" in e.attrib]
    json_out(OUT / "hal_source_review.json", dict(doi=DOI, hal_id=doc["halId_s"], version=doc["version_i"],
        modified=doc["modifiedDate_tdate"], file_list=doc["files_s"], page_download_links=sorted(parser.downloads),
        metadata_fields=len(doc), tei_targets=refs, pdf_status=curl["status"],
        note="Repository metadata version/date is not a final proteomics workflow version"))
    if "text" in curl:
        text = (ROOT / curl["text"]["path"]).read_text()
        excerpts = []
        for page, content in enumerate(text.split("\f"), 1):
            for match in re.finditer(r"Proteome Discoverer|inferys|PXD055968|lead contact|upon request|missing values|unique peptides", content, re.I):
                excerpts.append(dict(page=page, term=match.group(), text=content[max(0, match.start()-200):match.end()+1000]))
        csv_out(OUT / "hal_article_methods_passages.csv", excerpts, ["page", "term", "text"])
    json_out(OUT / "review_summary.json", dict(utc=utc(), status="source_review_completed",
        completed_requests=len(routes), interrupted_pdf_attempts=2, project_files=len(inventories),
        PXD055968_inventory_unchanged=True, related_project_scope=scope,
        hal_article_records=1, hal_listed_files=len(doc["files_s"]),
        correct_full_export_acquired=False, candidate_identity_started=False,
        author_contact="draft_only_not_sent", publication="paused"))
    print(json.dumps(dict(completed_requests=len(routes), project_scope=scope,
        hal_listed_files=doc["files_s"], pdf_status=curl["status"]), ensure_ascii=False, indent=2))


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("action", choices=["pdf", "review"])
    globals()[p.parse_args().action]()
