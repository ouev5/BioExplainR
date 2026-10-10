"""Download human smooth-muscle protein supplement; freeze before quantitative read."""
import json
import sys
import zipfile
from pathlib import Path
from validation_sources import fetch, json_out, record, utc

dest = Path(sys.argv[1]).resolve() / "human_protein"
json_out(dest / "human_protein_freeze.json", {
    "utc": utc(), "script": record(Path(__file__)),
    "source": "PMC9562650 TableS2 all identified proteins plus original sample intensities, four assays",
    "candidates": ["PER2", "PER3", "METTL7A", "MAOA", "ANGPTL2", "FSTL3"],
    "controls": ["PER1", "FKBP5", "TSC22D3", "DUSP1", "NR3C1"],
    "unit": "six human testicular peritubular donors, age29-55; three technical replicates per condition are averaged, not independent people",
    "primary": "DEX-control within-donor log2 published normalized intensity; 11genes x4assays=44Holm; no imputation; unambiguous exact symbol and same stable protein group across samples",
    "time": "24h and72h separate acquisition datasets; no cross-time claim unless paired source donor mapping/scale allow direct response contrast",
    "scope": "Human smooth-muscle-like cells in testis, NOT airway; no candidate causal/function validation from abundance",
    "timing": "Original article and dataset metadata read, TableS2 quantitative values not examined"})
logs = []
for name, url in [
    ("original_supplement.zip", "https://pmc.ncbi.nlm.nih.gov/articles/instance/9562650/bin/cells-11-03164-s001.zip"),
    ("clock_supplement.docx", "https://pmc.ncbi.nlm.nih.gov/articles/instance/12476226/bin/ANDR-13-1970-s001.docx"),
]:
    rec = fetch(url, dest / name, 30)
    logs.append(rec)
    if rec["status"] == "retrieved":
        rec["valid_zip_container"] = zipfile.is_zipfile(dest / name)
    print(name, rec["status"], rec.get("valid_zip_container"), flush=True)
json_out(dest / "supplement_acquisition.json", {"utc": utc(), "records": logs})
