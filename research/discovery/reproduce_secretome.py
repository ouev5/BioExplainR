"""Rerun numerical secretome analyses in a new directory from hash-verified saved arrays."""
import argparse
import json
import shutil
import subprocess
import sys
from pathlib import Path

from seal_secretome import SOURCE, verify
from validation_sources import ROOT, HERE, record, utc, json_out


def main(out):
    verify()
    out.mkdir(exist_ok=False)
    for name in ["frozen_genes.csv","file_inventory.csv"]:
        shutil.copyfile(SOURCE/name,out/name)
    (out/"archives").mkdir()
    for time in [24,72]:
        directory=out/f"archives/{time}h"; directory.mkdir()
        shutil.copyfile(SOURCE/f"archives/{time}h/extraction.json",directory/"extraction.json")
    json_out(out/"reproduction_freeze.json",dict(utc=utc(),script=record(Path(__file__)),
        source_manifest=record(ROOT/"docs/secretome_validation_v1/secretome_manifest.json"),
        scope="Same saved full processed arrays, new extraction/design/statistics/independent R/BioExplainR execution, not new independent evidence"))
    commands=[
        [sys.executable,str(HERE/"secretome_analyze.py"),"design",str(out)],
        [sys.executable,str(HERE/"secretome_analyze.py"),"analyze",str(out)],
        ["Rscript",str(HERE/"audit_secretome.R"),str(out)],
        ["Rscript",str(HERE/"report_secretome.R"),str(out)]]
    logs=[]
    for i,command in enumerate(commands,1):
        start=utc(); p=subprocess.run(command,cwd=ROOT,capture_output=True,text=True)
        path=out/f"command_{i}.log";path.write_text(p.stdout+p.stderr)
        logs.append(dict(command=command,start_utc=start,end_utc=utc(),returncode=p.returncode,log=record(path)))
        assert p.returncode==0,p.stdout+p.stderr
    names=["sample_map.csv","sample_scope_comparison.csv","raw_file_scope.csv","processing_versions.csv","group_QC.csv","all_measurements.csv","all_donor_effects.csv","all_results.csv",
           "candidate_detection.csv","candidate_results.csv","candidate_measurements.csv","candidate_donor_effects.csv",
           "candidate_sensitivity.csv","candidate_leave_one.csv","candidate_direct_time.csv","candidate_direct_donor_effects.csv","array_summary.csv"]
    for name in names:
        assert (out/name).read_bytes()==(SOURCE/name).read_bytes(),name
    json_out(out/"reproduction_audit.json",dict(status="pass",utc=utc(),commands=logs,byte_identical_numeric_tables=len(names),
        independent_R=json.loads((out/"r_numeric_audit.json").read_text()),
        scope="Actual same-source rerun; no new independent cohort; original results untouched"))
    print("Secretome same-source reproduction pass:",len(names),"identical numeric tables")


if __name__=="__main__":
    p=argparse.ArgumentParser(description=__doc__);p.add_argument("output",type=Path)
    main(p.parse_args().output.resolve())
