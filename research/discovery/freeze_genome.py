"""Freeze the exploratory screen before ranking the full-genome results."""
import hashlib
import json
from datetime import datetime, timezone
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]


def record(path):
    path = Path(path)
    h = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            h.update(chunk)
    return {"path": str(path.relative_to(ROOT)), "bytes": path.stat().st_size,
            "sha256": h.hexdigest()}


if __name__ == "__main__":
    out = Path(sys.argv[1])
    out.mkdir(exist_ok=False)
    paths = ["research/discovery/GENOME_PROTOCOL.md", "research/discovery/screen_genome.R",
             "research/discovery/freeze_genome.py",
             "research/results/discovery_context_v1/model.rds",
             "research/results/discovery_context_v1/counts.txt.gz",
             "research/results/discovery_context_v1/samples.csv",
             "research/results/discovery_context_v1/size_factors.csv",
             "research/results/discovery_donors_v1/tpm.txt.gz",
             "research/results/discovery_donors_v1/samples.csv",
             "research/results/discovery_donors_v1/original_supplement_verified.pdf"]
    freeze = {"frozen_utc": datetime.now(timezone.utc).isoformat(),
              "stage": "before genome ranking and selection; earlier SPARCL1 analyses known",
              "analysis": "exploratory published-data reanalysis", "files": [record(ROOT / p) for p in paths]}
    (out / "analysis_freeze.json").write_text(json.dumps(freeze, indent=2) + "\n")
    print(json.dumps({"status": "frozen", "output": str(out), "files": len(paths)}, indent=2))
