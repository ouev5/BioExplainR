"""Freeze the follow-up protocol, then acquire public counts and design metadata."""
import argparse
from datetime import datetime, timezone
import gzip
import hashlib
import json
from pathlib import Path
import urllib.request

HERE = Path(__file__).resolve().parent


def record(path):
    return {"path": path.name, "bytes": path.stat().st_size,
            "sha256": hashlib.sha256(path.read_bytes()).hexdigest()}


def write_json(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2, allow_nan=False) + "\n")


def fetch(url, path):
    request = urllib.request.Request(url, headers={"User-Agent": "BioExplainR-public-reanalysis/1.0"})
    with urllib.request.urlopen(request, timeout=300) as response:
        blob = response.read()
    if path.suffix == ".gz":
        gzip.decompress(blob)  # validate complete stream and CRC
    path.write_bytes(blob)
    return {**record(path), "url": url, "retrieved_utc": datetime.now(timezone.utc).isoformat()}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    out = args.output
    out.mkdir(parents=True, exist_ok=False)
    write_json(out / "frozen_protocol.json", {
        "frozen_utc": datetime.now(timezone.utc).isoformat(),
        "protocol": record(HERE / "CONTEXT_PROTOCOL.md"),
        "scripts": [record(HERE / name) for name in
                    ["prepare_context.py", "run_context.R", "audit_context.py"]],
        "candidate": "ENSG00000152583 / SPARCL1",
        "timing": "Series metadata and paper read; GSE146017 expression/results unread in this session",
        "previous_results_known": "airway and GSE34313 SPARCL1 response",
        "claim": "Context-dependent response, not first SPARCL1 glucocorticoid response"})
    base = "https://ftp.ncbi.nlm.nih.gov/geo/series/GSE146nnn/GSE146017"
    inputs = [fetch(base + "/suppl/GSE146017_CEBPD_htseq_gene.txt.gz", out / "counts.txt.gz"),
              fetch(base + "/matrix/GSE146017_series_matrix.txt.gz", out / "series_matrix.txt.gz")]
    with gzip.open(out / "counts.txt.gz", "rt") as f:
        (out / "count_header.txt").write_text(f.readline())
    with gzip.open(out / "series_matrix.txt.gz", "rt") as f:
        (out / "sample_metadata.txt").write_text("".join(line for line in f if line.startswith("!Sample_")))
    for pmcid in ["PMC4057123", "PMC9331514"]:
        inputs.append(fetch(f"https://www.ebi.ac.uk/europepmc/webservices/rest/{pmcid}/fullTextXML",
                            out / f"{pmcid}.xml"))
    # Explicit query and dated response document the limited novelty review.
    query = "SPARCL1 AND (CEBPD OR budesonide OR (TNF AND glucocorticoid)) AND FIRST_PDATE:[1900-01-01 TO 2026-10-08]"
    from urllib.parse import urlencode
    url = "https://www.ebi.ac.uk/europepmc/webservices/rest/search?" + urlencode({"query": query, "format": "json", "pageSize": 25})
    inputs.append(fetch(url, out / "novelty_search.json"))
    write_json(out / "input_manifest.json", {"inputs": inputs, "freeze": record(out / "frozen_protocol.json")})
    print(json.dumps({"status": "acquired", "files": inputs}, indent=2))


if __name__ == "__main__":
    main()
