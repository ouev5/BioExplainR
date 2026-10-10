"""Reproduce the full-set statistics in a new directory from verified saved public inputs."""
import argparse
import json
import subprocess
import sys
from pathlib import Path
from validation_sources import ROOT,HERE,record,utc,csv_out,json_out
from set_validation import rows,measure
from set_integrity import prior_integrity


def run(out):
    source=ROOT/"research/results/discovery_set_validation_v1"
    prior_integrity(source)
    manifest=json.loads((ROOT/"docs/paper_cn_v6/manuscript_manifest.json").read_text())
    for rec in manifest["files"]+manifest["source_code"]+manifest["dependencies"]:
        assert record(ROOT/rec["path"])==rec,rec["path"]
    if not out.is_relative_to(ROOT/"research/results") or out.exists():raise ValueError("Use a new output directory under research/results")
    out.mkdir();(out/"sources").mkdir()
    original=json.loads((source/"analysis_freeze.json").read_text())
    for name in ["frozen_set.csv","samples.csv","annotation.csv"]:(out/name).write_bytes((source/name).read_bytes())
    mapping=json.loads((source/"annotation_freeze.json").read_text())
    # Saved official exact-ID responses are content-bound inputs, not new network retrievals.
    inputs=original["inputs"]
    json_out(out/"analysis_freeze.json",dict(utc=utc(),inputs=inputs,scripts=original["scripts"],
        set=record(out/"frozen_set.csv"),samples=record(out/"samples.csv"),contrasts=original["contrasts"],
        primary_family=54,secondary_family=162,timing="Same-source numeric reproduction ofknownfull-set results, notnewindependentvalidation",runner=record(Path(__file__))))
    json_out(out/"annotation_freeze.json",dict(utc=utc(),annotation=record(out/"annotation.csv"),records=mapping["records"],
        rule=mapping["rule"],saved_official_mapping_reused=True))
    measure(out)
    commands=[["Rscript","--vanilla",str(HERE/"set_validation_models.R"),str(out)],
              [sys.executable,str(HERE/"audit_set_validation.py"),str(out)],
              [sys.executable,str(HERE/"audit_set_sensitivity.py"),str(out)],
              ["Rscript","--vanilla",str(HERE/"report_set_validation.R"),str(out)]]
    logs=[]
    for i,command in enumerate(commands,1):
        start=utc();p=subprocess.run(command,capture_output=True,cwd=ROOT);path=out/f"reproduction_step{i}.log"
        path.write_bytes(p.stdout+p.stderr);logs.append(dict(command=command,start_utc=start,end_utc=utc(),returncode=p.returncode,log=record(path)))
        json_out(out/f"reproduction_step{i}.json",logs[-1])
        if p.returncode:raise RuntimeError(f"Step{i}failed; preservedlog{path}")
    original_summary=rows(source/"set_summary.csv");new=rows(out/"set_summary.csv")
    assert len(new)==len(original_summary)==54
    import numpy as np
    for a,b in zip(original_summary,new):
        for key in a:
            try:assert np.isclose(float(a[key]),float(b[key]),rtol=1e-7,atol=1e-9)
            except ValueError:assert a[key]==b[key],key
    json_out(out/"reproduction.json",dict(status="pass",utc=utc(),commands=logs,summary_rows=54,
        scope="Same public inputs and savedmapping, freshcountfit, independentaudits, actualRpackage; notnewdonors ornewindependenttest"))
    print("Full-set same-source reproduction passed in new directory")


if __name__=="__main__":
    p=argparse.ArgumentParser(description=__doc__);p.add_argument("output",type=Path)
    run(p.parse_args().output.resolve())
