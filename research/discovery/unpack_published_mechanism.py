"""GEO wraps an already compressed RDS in a second gzip layer; preserve both."""
import gzip
import hashlib
import json
from pathlib import Path
import subprocess

out=Path('research/results/discovery_mechanism_fit_v4')
source=out/'SE.processed.rds.gz';dest=out/'SE.processed.rds'
with gzip.open(source,'rb') as f:raw=f.read()
assert raw.startswith(b'\x1f\x8b')
gzip.decompress(raw) # Full inner CRC check, not silently trusting nested compression.
if dest.exists():assert dest.read_bytes()==raw
else:dest.write_bytes(raw)
(out/'nested_gzip.json').write_text(json.dumps(dict(source=source.name,source_sha256=hashlib.file_digest(source.open('rb'),'sha256').hexdigest(),
    inner=dest.name,inner_bytes=len(raw),inner_sha256=hashlib.sha256(raw).hexdigest(),outer_CRC='pass',inner_CRC='pass'),indent=2)+'\n')
subprocess.run(['Rscript','--vanilla','research/discovery/inspect_published_mechanism.R',str(out)],check=True)
