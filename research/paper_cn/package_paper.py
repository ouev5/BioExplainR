"""Freeze a paper-only ZIP with manuscript, PDF panels/composites and external tables."""
import hashlib
import json
from pathlib import Path
import zipfile

ROOT=Path(__file__).resolve().parents[2]
BASE=ROOT/"docs/paper_cn_v1"
OUTPUT=ROOT/"docs/BioExplainR-中文论文-v0.8-图表附件.zip"


def main():
    audit=json.loads((BASE/"audit.json").read_text())
    if audit["status"]!="pass":raise ValueError("Document audit required")
    files=sorted(p for p in BASE.rglob("*") if p.is_file() and "rendered_docx" not in p.parts
                 and p.name!="upload_record.json")
    records=[]
    with zipfile.ZipFile(OUTPUT,"x",compression=zipfile.ZIP_DEFLATED) as z:
        for p in files:
            b=p.read_bytes();name=p.relative_to(BASE).as_posix()
            z.writestr(name,b);records.append({"path":name,"bytes":len(b),"sha256":hashlib.sha256(b).hexdigest()})
        manifest={"status":"paper_only_bundle","manuscript_version":"v0.8","members":records,
                  "scope":"Chinese manuscript, original vector figure assets and external tables; no expert/user results"}
        z.writestr("paper_bundle_manifest.json",json.dumps(manifest,ensure_ascii=False,indent=2)+"\n")
    with zipfile.ZipFile(OUTPUT) as z:
        assert z.testzip() is None and len(z.namelist())==len(records)+1
        for r in records:assert hashlib.sha256(z.read(r["path"])).hexdigest()==r["sha256"]
    result={"status":"pass","path":OUTPUT.relative_to(ROOT).as_posix(),"members":len(records)+1,
            "bytes":OUTPUT.stat().st_size,"sha256":hashlib.sha256(OUTPUT.read_bytes()).hexdigest()}
    (ROOT/"research/results/w00_baseline/paper-cn-paper-bundle-result.json").write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n")
    print(json.dumps(result,ensure_ascii=False,indent=2))


if __name__=="__main__":main()
