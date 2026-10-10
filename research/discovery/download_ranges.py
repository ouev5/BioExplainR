"""Resume a large public GEO input using verified HTTP byte ranges."""
import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime, timezone
import gzip
import hashlib
import json
from pathlib import Path
import time
import urllib.request


def download(url, path, workers=12, preserve_report=False):
    report_path = path.parent / "range_download.json"
    saved_report = json.loads(report_path.read_text()) if preserve_report else None
    if preserve_report and (path.exists() or saved_report["url"] != url):
        raise ValueError("Restore a missing sealed input from its recorded URL")
    request = urllib.request.Request(url, method="HEAD")
    with urllib.request.urlopen(request, timeout=60) as response:
        size = int(response.headers["Content-Length"])
        modified = response.headers["Last-Modified"]
    if saved_report is not None and (saved_report["bytes"] != size or saved_report["last_modified"] != modified):
        raise ValueError("Remote source differs from the sealed input identity")
    chunk_size = 512*1024
    chunks = path.parent / (path.name + ".parts")
    chunks.mkdir(exist_ok=True)
    identity = {"url": url, "bytes": size, "last_modified": modified, "chunk_size": chunk_size}
    index = chunks / "source.json"
    if index.exists(): assert json.loads(index.read_text()) == identity
    else: index.write_text(json.dumps(identity, indent=2)+"\n")
    if path.exists():
        # Failed serial input is kept as evidence, never interpreted as a complete input.
        assert not (path.parent / (path.name + ".incomplete")).exists()
        path.rename(path.parent / (path.name + ".incomplete"))

    def get(start):
        end = min(start+chunk_size, size)-1; part = chunks / str(start)
        if part.exists():
            if part.stat().st_size == end-start+1:
                return start
            partial = chunks / (str(start) + ".incomplete")
            assert not partial.exists()
            part.rename(partial)
        for attempt in range(3):
            try:
                req = urllib.request.Request(url, headers={"Range": f"bytes={start}-{end}"})
                with urllib.request.urlopen(req, timeout=120) as r:
                    assert r.status == 206 and r.headers["Content-Range"] == f"bytes {start}-{end}/{size}"
                    assert r.headers["Last-Modified"] == modified
                    blob = r.read()
                assert len(blob) == end-start+1
                part.write_bytes(blob)
                return start
            except Exception:
                if attempt == 2: raise
                time.sleep(2*(attempt+1))
    starts = list(range(0, size, chunk_size))
    with ThreadPoolExecutor(max_workers=workers) as pool:
        for n, result in enumerate(as_completed([pool.submit(get, s) for s in starts]), 1):
            result.result()
            if n % 20 == 0 or n == len(starts): print(f"Verified ranges {n}/{len(starts)}", flush=True)
    with path.open("xb") as f:
        for start in starts: f.write((chunks / str(start)).read_bytes())
    assert path.stat().st_size == size
    with gzip.open(path, "rb") as f:
        while f.read(1024*1024): pass
    report = {**identity, "sha256": hashlib.sha256(path.read_bytes()).hexdigest(), "ranges": len(starts),
               "workers": workers, "gzip_crc": "pass", "finished_utc": datetime.now(timezone.utc).isoformat()}
    if saved_report is not None:
        if report["sha256"] != saved_report["sha256"]:
            raise ValueError("Restored input SHA-256 differs from the sealed input")
    else:
        report_path.write_text(json.dumps(report, indent=2)+"\n")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__); p.add_argument("url"); p.add_argument("path", type=Path)
    p.add_argument("--workers", type=int, default=12)
    p.add_argument("--preserve-report", action="store_true", help="Restore a missing sealed input, verify its exact SHA-256 and preserve the historical range report")
    args = p.parse_args(); download(args.url, args.path, args.workers, args.preserve_report)
