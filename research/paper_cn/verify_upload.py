"""Verify explicitly authorized public paper uploads by anonymous content hash."""
import hashlib
import json
from pathlib import Path
import urllib.request

ROOT=Path(__file__).resolve().parents[2]
FILES=[(45,"docs/paper_cn_v1/BioExplainR-中文论文-v0.8.docx","2026-10-08T09:35:22.964Z"),
       (46,"docs/paper_cn_v1/BioExplainR-中文论文-v0.8.pdf","2026-10-08T09:35:23.407Z"),
       (47,"docs/BioExplainR-中文论文-v0.8-图表附件.zip","2026-10-08T09:35:30.660Z")]


def main():
    entries=[]
    for id,name,time in FILES:
        p=ROOT/name;expected=hashlib.sha256(p.read_bytes()).hexdigest();checks=[]
        for kind in ["download","file"]:
            url=f"http://62.234.106.117:8003/api/{kind}/{id}"
            with urllib.request.urlopen(url,timeout=120) as response:
                content=response.read();actual=hashlib.sha256(content).hexdigest()
                if response.status!=200 or len(content)!=p.stat().st_size or actual!=expected:
                    raise ValueError(f"Public upload differs from local file: {id}/{kind}")
                checks.append({"url":url,"http_status":response.status,"sha256":actual,"anonymous":True})
        entries.append({"id":id,"local_file":name,"bytes":p.stat().st_size,"sha256":expected,"is_public":1,
                        "uploaded_utc":time,"verification":checks})
    record={"status":"pass","scope":"User-authorized public paper upload; no authentication secret stored", "files":entries}
    output=ROOT/"research/results/w00_baseline/paper-cn-upload-result.json"
    if output.exists():raise ValueError("Verification record exists")
    output.write_text(json.dumps(record,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    print(json.dumps(record,ensure_ascii=False,indent=2))


if __name__=="__main__":main()
