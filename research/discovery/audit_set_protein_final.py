"""Verify exact ranges/member CRCs, donor scope and all protein sensitivity arithmetic."""
import json
import re
import sys
import zlib
from pathlib import Path
import numpy as np
from scipy import stats
from set_validation import rows,adjust
from validation_sources import ROOT,record,utc,json_out

out=Path(sys.argv[1]).resolve();dest=out/"unselected_protein";partchecks=0;crc_checks=0
for acc in ["PXD033514","PXD033534"]:
    directory=out/"protein_full_tables_small"/acc
    manifests=sorted(directory.glob("parts_manifest*.json"),key=lambda p:p.stat().st_mtime)
    manifest=json.loads(manifests[-1].read_text());parts=manifest["parts"]
    assert all(r["status"]=="pass" for r in parts)
    block=json.loads((out/"protein_archives_inspected"/acc/"range_acquisition.json").read_text())["packed_blocks"][2]
    start=block["start"]
    for r in parts:
        assert r["start"]==start;start=r["end"]+1
        assert record(ROOT/r["body"]["path"])==r["body"]
        header=ROOT/r["attempts"][-1]["header"]["path"]
        assert record(header)==r["attempts"][-1]["header"]
        expected=(r["start"],r["end"],1994859629 if acc=="PXD033514" else 1332639631)
        actual=re.findall(r"[Cc]ontent-[Rr]ange:\s*bytes\s+(\d+)-(\d+)/(\d+)",header.read_text())
        assert tuple(map(int,actual[-1]))==expected and r["body"]["bytes"]==r["end"]-r["start"]+1
        partchecks+=1
    assert start==block["end"]+1 and len({r["last_modified"] for r in parts})==1
    filename="extraction_verified.json" if (directory/"extraction_verified.json").exists() else "extraction.json"
    completion=json.loads((directory/filename).read_text());assert completion["status"]=="pass"
    for r in completion["outputs"]:
        path=ROOT/r["path"];assert record(path)["sha256"]==r["sha256"] and zlib.crc32(path.read_bytes())==r["crc32"];crc_checks+=1
for name in ["r_audit.json","r_sensitivity_audit.json","bioexplainr_workflow.json"]:assert json.loads((dest/name).read_text())["status"]=="pass"
effects=rows(dest/"donor_effects.csv");scope=rows(dest/"donor_scope.csv");checks=0
for filename,family in [("published_label_sensitivity.csv",112),("direct_time_results.csv",56),("direct_published_labels.csv",56)]:
    data=rows(dest/filename)
    for r in data:
        if r["status"]!="estimable":continue
        allowed={int(s["time_h"]):set(s["published_selected_labels"].split("|")) for s in scope}
        if filename=="published_label_sensitivity.csv":
            time=int(r["time_h"]);x=[float(s["effect"]) for s in effects if s["feature_id"]==r["feature_id"] and int(s["time_h"])==time and s["status"]=="paired" and s["donor"] in allowed[time]]
        else:
            bytime={t:{s["donor"]:float(s["effect"]) for s in effects if s["feature_id"]==r["feature_id"] and int(s["time_h"])==t and s["status"]=="paired" and (filename!="direct_published_labels.csv" or s["donor"] in allowed[t])} for t in [24,72]}
            x=[bytime[72][d]-bytime[24][d] for d in sorted(set(bytime[24])&set(bytime[72]))]
        assert len(x)==int(r["n_donors"])
        se=np.std(x,ddof=1)/np.sqrt(len(x));width=stats.t.ppf(.975,len(x)-1)*se
        for key,val in zip(["effect","se","ci_low","ci_high","pvalue"],[np.mean(x),se,np.mean(x)-width,np.mean(x)+width,stats.ttest_1samp(x,0).pvalue]):
            assert np.isclose(float(r[key]),val,rtol=1e-7,atol=1e-9);checks+=1
    for r,p in zip(data,adjust([float(r["pvalue"]) for r in data])):assert np.isclose(float(r["holm"+str(family)]),p)
comparison=rows(dest/"published_raw_cell_comparison.csv")
observed=[r for r in comparison if r["raw_missing"]=="False"]
assert len(comparison)==144 and len(observed)==142
assert max(abs(float(r["difference"])) for r in observed)<.000051
json_out(dest/"final_audit.json",dict(status="pass",utc=utc(),complete_HTTP_range_parts=partchecks,member_CRC_checks=crc_checks,
    protein_sensitivity_numeric_checks=checks,published_raw_cells=144,observed_matching_to_rounding=142,rawzero_publishedfinite=2,
    source_conflicts=["7rawdonorlabels vs6published,extra10.09.19age/QCunverified","MaxQuantparameters1.6.15vsreported1.6.11","twooriginalLFQzero cells have finitepublishedvalues"],
    scope="Allsuccessfulpackedranges/CRC andraw-versus-publishedscope explicit; notwholearchiveSHA1 or freshMSsearch; samebiologicalsource"))
print("Final protein ranges, CRCs, raw/published cells and sensitivity arithmetic passed")
