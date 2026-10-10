"""Freeze early ASM RPKM checks and retain mapping/design limitations."""
import gzip
import json
import sys
from pathlib import Path
from validation_sources import fetch,json_out,record,utc
dest=Path(sys.argv[1]).resolve()/"asm_early"
json_out(dest/"design_freeze.json",{
    "utc":utc(),"script":record(Path(__file__)),"study":"GSE135730",
    "genes":["PER2","PER3","METTL7A","MAOA","ANGPTL2","FSTL3","PER1","FKBP5","TSC22D3","DUSP1","NR3C1"],
    "design":"4h untreated/IL17A/DEX/both, three stated biological replicates per condition, no donor identifiers or verified ages",
    "treatment":"DEX1ug/ml,IL17A100ng/ml; source primary humanASM; assembly summary incorrectly says mm9",
    "analysis":"If per-library RPKM are supplied, unpaired Welch log2(RPKM+1) GC simple effects and interaction, 33Holm; if only condition mean, report descriptive ratios without P/CI.",
    "mapping":"Exact unambiguous published gene symbol; retain all selected rows and gene-level median if multiple transcripts; do not map genomic coordinates to guessed assembly",
    "scope":"Early ASM experimental check, not new independent adult donor time series; cannot pair anonymous replicate numbers without source evidence.",
    "timing":"Metadata examined, candidate RPKM unexamined."})
logs=[]
for group in ["UT","DEX","17","17DEX"]:
    name="GSE135730_SMC_"+group+".txt.gz"
    url="https://ftp.ncbi.nlm.nih.gov/geo/series/GSE135nnn/GSE135730/suppl/"+name
    rec=fetch(url,dest/"sources"/name,30);logs.append(rec)
    if rec["status"]=="retrieved":
        text=gzip.decompress((dest/"sources"/name).read_bytes()).decode("utf-8-sig")
        rec["gzip_crc_complete"]=True
        print(group,text.splitlines()[:2],flush=True)
json_out(dest/"input_manifest.json",{"utc":utc(),"records":logs})
