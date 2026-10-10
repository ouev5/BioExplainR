"""Preserve failed downloads; recover the HBEC table using a checked range."""
import argparse
import hashlib
import json
import re
import urllib.request
from pathlib import Path

from public_proteome_continue import OUT, fetch, check_frozen
from validation_sources import utc, record, json_out


def prepare():
    check_frozen()
    partial = OUT / "sources/PXD029135_median-normalized.txt"
    log = json.loads((OUT / "requests/PXD029135_median-normalized.txt.request.json").read_text())
    assert record(partial) == log["response"]
    size = int(log["headers"]["Content-Length"])
    offset = partial.stat().st_size - 32768
    json_out(OUT / "hbec_range_plan.json", dict(utc=utc(), script=record(Path(__file__)),
        source_evidence=[record(partial), record(OUT / "requests/PXD029135_median-normalized.txt.request.json")],
        url=log["url"], range=f"bytes={offset}-{size-1}", offset=offset, total_bytes=size,
        if_range=log["headers"]["ETag"], overlap_bytes=32768, output="sources/PXD029135_median-normalized_complete.txt"))
    requests = []
    for pmc in ["PMC11299423", "PMC5105184", "PMC9361782"]:
        requests.append(dict(name=pmc + "_article.html", url=f"https://pmc.ncbi.nlm.nih.gov/articles/{pmc}/"))
    for acc, names in [("PXD014171", ["summary.txt", "PXD014171_community_annotated.sdrf.tsv"]),
                       ("PXD015604", ["Link_between_files.xlsx"])]:
        inventory = json.loads((OUT / (acc + "_inventory.json")).read_text())
        for name in names:
            f = next(p for p in inventory if p["fileName"] == name)
            url = next(p["value"] for p in f["publicFileLocations"] if p["name"] == "FTP Protocol").replace("ftp://", "https://")
            requests.append(dict(name=acc + "_" + name, url=url, expected_file=f))
    json_out(OUT / "alternative_sources_plan.json", dict(utc=utc(), script=record(Path(__file__)),
        source_evidence=[record(OUT / "processed_and_article_plan.json"), record(OUT / "PXD014171_inventory.json"), record(OUT / "PXD015604_inventory.json")],
        reason="Three XML HTTP500 alternatives; lesion-sample and epithelial-co-culture metadata only", requests=requests))
    for name in ["article_34950134.json", "intrapulmonary_article.json", "intrapulmonary_crossref.json"]:
        path = OUT / ("imported" if name.startswith("article_") else "sources") / name
        data = json.loads(path.read_text())
        if "resultList" in data:
            p = data["resultList"]["result"][0]
            print(json.dumps(dict(name=name, pmcid=p.get("pmcid"), fulltext=p.get("fullTextUrlList")), ensure_ascii=False, indent=2))
        else:
            print(json.dumps(dict(name=name, link=data["message"].get("link"), url=data["message"].get("URL")), indent=2))


def recover():
    planpath = OUT / "hbec_range_plan.json"
    plan = json.loads(planpath.read_text())
    assert record(Path(__file__)) == plan["script"]
    for r in plan["source_evidence"]:
        assert record(Path(__file__).resolve().parents[2] / r["path"]) == r
    path = OUT / "sources/PXD029135_median_tail.bin"
    logpath = OUT / "requests/PXD029135_median_tail.request.json"
    if path.exists() or logpath.exists():
        raise ValueError("Refusing overwrite range recovery")
    log = dict(utc=utc(), url=plan["url"], requested_range=plan["range"])
    data = b""
    try:
        req = urllib.request.Request(plan["url"], headers={"Range": plan["range"], "If-Range": plan["if_range"],
            "Accept-Encoding": "identity", "User-Agent": "BioExplainR-public-proteome/0.4"})
        with urllib.request.urlopen(req, timeout=30) as response:
            log.update(http_status=response.status, headers=dict(response.headers))
            data = response.read(plan["total_bytes"] + 1)
        assert log["http_status"] == 206
        headers = {k.lower(): v for k, v in log["headers"].items()}
        assert headers["content-range"] == f"bytes {plan['offset']}-{plan['total_bytes']-1}/{plan['total_bytes']}"
        assert headers["etag"] == plan["if_range"]
        assert len(data) == plan["total_bytes"] - plan["offset"]
        partial = (OUT / "sources/PXD029135_median-normalized.txt").read_bytes()
        assert partial[plan["offset"]:] == data[:plan["overlap_bytes"]]
        complete = partial[:plan["offset"]] + data
        expected = json.loads((OUT / "processed_and_article_plan.json").read_text())["requests"][0]["expected_file"]
        assert len(complete) == expected["fileSizeBytes"]
        assert hashlib.sha1(complete).hexdigest() == expected["checksum"].zfill(40)
        dest = OUT / plan["output"]
        if dest.exists():
            raise ValueError("Refusing overwrite complete table")
        dest.write_bytes(complete)
        log.update(status="retrieved_and_reconstructed", complete_file=record(dest), upstream_sha1_matches=True,
            overlap_bytes=plan["overlap_bytes"], plan=record(planpath))
    except Exception as exc:
        log.update(status="failed_or_partial", error=repr(exc))
    if data:
        path.write_bytes(data)
        log["response"] = record(path)
    log["completed_utc"] = utc()
    json_out(logpath, log)
    print(json.dumps(log, indent=2))


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("action", choices=["prepare", "recover"])
    globals()[p.parse_args().action]()
