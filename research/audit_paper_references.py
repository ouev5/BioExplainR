"""Retrieve DOI metadata so manuscript reference details are inspectable."""
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
import json
from pathlib import Path
import re

import requests

ROOT = Path(__file__).resolve().parents[1]


def lookup(item):
    number, doi = item
    for attempt in range(3):
        try:
            response = requests.get(f"https://api.crossref.org/works/{doi}", timeout=35)
            response.raise_for_status()
            work = response.json()["message"]
            return {"reference": int(number), "doi": doi, "status": "resolved",
                    "title": work.get("title", []), "container": work.get("container-title", []),
                    "type": work.get("type"), "volume": work.get("volume"),
                    "page": work.get("page", work.get("article-number")),
                    "published": work.get("published", work.get("issued")),
                    "published_print": work.get("published-print"),
                    "first_author": work.get("author", [None])[0]}
        except Exception as error:
            if attempt == 2:
                return {"reference": int(number), "doi": doi, "status": "unresolved", "error": str(error)}


def main():
    text = (ROOT / "docs/PAPER_DRAFT.md").read_text(encoding="utf-8")
    references = re.findall(r"^(\d+)\. .*?doi: \[([^]]+)\]", text, re.MULTILINE)
    with ThreadPoolExecutor(max_workers=6) as pool:
        audit = list(pool.map(lookup, references))
    output = {"checked_utc": datetime.now(timezone.utc).isoformat(),
              "scope": "DOI resolution and bibliographic metadata; not full-text design verification", "references": audit}
    (ROOT / "research/results/reference_audit.json").write_text(json.dumps(output, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    for item in audit:
        print(json.dumps({key: item.get(key) for key in ["reference", "status", "title", "volume", "page", "published"]}, ensure_ascii=False))
    assert all(item["status"] == "resolved" for item in audit)


if __name__ == "__main__":
    main()
