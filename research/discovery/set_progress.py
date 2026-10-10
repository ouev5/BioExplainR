"""Report immutable download completions without treating partial parts as acquired."""
import json
import sys
from pathlib import Path

out=Path(sys.argv[1]).resolve()
for acc in ["PXD033514","PXD033534"]:
    directory=out/"protein_full_tables_small"/acc
    logs=[]
    for path in directory.glob("*.json"):
        if path.name[0].isdigit() and ".failed" not in path.name:
            data=json.loads(path.read_text())
            if data.get("status")=="pass":logs.append(data)
    print(json.dumps(dict(project=acc,complete_parts=len(logs),acquired_bytes=sum(r["body"]["bytes"] for r in logs),
        verified_extraction=(directory/"extraction_verified.json").exists()),indent=2))
