"""Resume original evidence comparison with MaxQuant's long peptide fields supported."""
import csv
import sys
from pathlib import Path

from secretome_evidence import compare
from validation_sources import record, utc, json_out

out = Path(sys.argv[1]).resolve()
json_out(out/"evidence_parser_amendment.json",dict(utc=utc(),script=record(Path(__file__)),
    reason="Original comparison exceeded Python default131072 CSV field limit on full MaxQuant peptide IDs; no comparison outputs written",
    change="Set10MiB field limit only; original frozen analysis/evidence scripts and all numeric outputs preserved"))
csv.field_size_limit(10*1024*1024)
compare(out)
