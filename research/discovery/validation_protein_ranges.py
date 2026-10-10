"""Acquire the full PRIDE protein table with verified, resumable byte ranges."""
from concurrent.futures import ThreadPoolExecutor, as_completed
import hashlib
import json
import sys
import time
import urllib.request
from pathlib import Path

from validation_sources import json_out, record, utc

dest = Path(sys.argv[1]).resolve() / "protein_public"
url = "https://ftp.pride.ebi.ac.uk/pride/data/archive/2026/09/PXD081613/1898311467_Anna_TMT_TP_Proteins.txt"
size = 37713383
path = dest / "original_proteins.txt"
parts = dest / "protein_ranges"
parts.mkdir(exist_ok=True)
if path.exists():
    raise ValueError("Refusing to overwrite full protein table")
with urllib.request.urlopen(urllib.request.Request(url, method="HEAD"), timeout=30) as response:
    assert int(response.headers["Content-Length"]) == size
    modified = response.headers.get("Last-Modified")
identity = {"url": url, "bytes": size, "modified": modified, "chunk_size": 524288}
if (parts / "source.json").exists():
    assert json.loads((parts / "source.json").read_text()) == identity
else:
    json_out(parts / "source.json", identity)


def get(start):
    end = min(size, start + identity["chunk_size"]) - 1
    part = parts / str(start)
    if part.exists():
        assert part.stat().st_size == end - start + 1
        return record(part)
    errors = []
    for attempt in range(4):
        try:
            req = urllib.request.Request(url, headers={"Range": f"bytes={start}-{end}"})
            with urllib.request.urlopen(req, timeout=30) as response:
                assert response.status == 206
                assert response.headers["Content-Range"] == f"bytes {start}-{end}/{size}"
                assert response.headers.get("Last-Modified") == modified
                data = response.read()
            assert len(data) == end - start + 1
            part.write_bytes(data)
            return {"start": start, "end": end, "retrieved_utc": utc(), "errors": errors, **record(part)}
        except Exception as exc:
            errors.append(str(exc))
            time.sleep(attempt + 1)
    raise RuntimeError((start, errors))


starts = list(range(0, size, identity["chunk_size"]))
records = []
with ThreadPoolExecutor(max_workers=8) as pool:
    for i, future in enumerate(as_completed([pool.submit(get, start) for start in starts]), 1):
        records.append(future.result())
        if i % 10 == 0 or i == len(starts):
            print("Protein verified ranges", i, "/", len(starts), flush=True)
with path.open("xb") as stream:
    for start in starts:
        stream.write((parts / str(start)).read_bytes())
assert path.stat().st_size == size
json_out(dest / "protein_range_acquisition.json", {"status": "pass", "utc": utc(), "identity": identity,
         "ranges": len(records), "records": records, "input": record(path), "validation": "Full PRIDE listed size; each206 Content-Range/Last-Modified; no upstream checksum provided"})
with path.open() as stream:
    print(stream.readline(), flush=True)
