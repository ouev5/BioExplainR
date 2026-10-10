"""Probe corrected official archive routes, preserving prior failed responses."""
import json
from asm_ev_export import OUT
from validation_sources import fetch, utc, record, json_out
from pathlib import Path


def main():
    requests = [
        ("pmc_oa_manifest_corrected.xml", "https://pmc.ncbi.nlm.nih.gov/utils/oa/oa.fcgi?id=PMC12141081"),
        ("zenodo_accession_corrected.json", "https://zenodo.org/api/records?q=PXD055968&size=20"),
        ("publisher_article.xml", "https://api.elsevier.com/content/article/PII:S2589004225008077?httpAccept=text/xml"),
    ]
    json_out(OUT / "export_routes_resume_freeze.json", dict(utc=utc(), script=record(Path(__file__)),
        requests=requests, reason="NCBI legacy OA path404; use PMC host. Check unquoted Zenodo query and DOI-bound publisher XML; preserve original failures",
        candidate_lookups=0))
    logs = [fetch(url, OUT / "sources" / name, timeout=20) for name, url in requests]
    json_out(OUT / "export_routes_resume_acquisition.json", dict(utc=utc(), records=logs))
    print(json.dumps(logs, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
