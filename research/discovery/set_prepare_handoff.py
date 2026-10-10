"""Preserve exact old documentation dependencies before updating current navigation."""
import json
import sys
from pathlib import Path
from validation_sources import ROOT,record,utc,json_out
from validation_integrity import old_integrity

out=Path(sys.argv[1]).resolve();result=old_integrity(ROOT/"research/results/discovery_validation_v2")
json_out(out/"prior_integrity_before_navigation.json",dict(utc=utc(),**result))
old=json.loads((ROOT/"docs/paper_cn_v5/manuscript_manifest.json").read_text())
snapshots=[]
for path,name in [(ROOT/"README.md","README_before_set_validation.md"),(ROOT/"docs/index.html","index_before_set_validation.html")]:
    expected=next(r for r in old["documentation"] if r["path"]==path.relative_to(ROOT).as_posix())
    assert record(path)==expected
    target=out/name
    if target.exists():raise ValueError("Refusingoverwrite"+str(target))
    target.write_bytes(path.read_bytes());snapshots.append(dict(original=expected,snapshot=record(target)))
json_out(out/"navigation_snapshot_manifest.json",dict(utc=utc(),snapshots=snapshots,
    policy="Only updated current README/index dependencies use exactoldbyte snapshots; originalsciencefilehashes stay unchanged"))
print("Pre-navigation historical integrity and exact README/index snapshots saved")
