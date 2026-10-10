"""Verify designated links, preserved original website/upload narrative and result status."""
import json
from pathlib import Path
import re
import subprocess

ROOT=Path(__file__).resolve().parents[2]
handoff=(ROOT/'SESSION_HANDOFF.md').read_text()
assert '360运行/1,800评分' in handoff and '不可估计' in handoff and 'r13' in handoff
continuation='docs/implementation_records/PAPER_CN_CONTINUATION.md'
old=subprocess.check_output(['git','show','HEAD:'+continuation],cwd=ROOT,text=True)
current=(ROOT/continuation).read_text()
marker='以下为v0.8阶段的原始实施与上传记录。'
assert old.split(marker,1)[1]==current.split(marker,1)[1]
historical=(ROOT/'docs/paper_cn_v1/README.md').read_text()
assert '../paper_cn_v3/README.md' in historical and '../paper_cn_v4/README.md' in historical
for p in [ROOT/'docs/research_followup_v1/README.md',ROOT/'docs/paper_cn_v1/README.md',ROOT/'docs/paper_cn_v4/README.md']:
    for link in re.findall(r'\]\(([^)]+)\)',p.read_text()):
        if not link.startswith(('https://','http://','#')):assert (p.parent/link).resolve().exists(),(p,link)
links=re.findall(r'href="([^"]+)"',(ROOT/'docs/index.html').read_text())
assert all((ROOT/'docs'/link).is_file() for link in links)
result=dict(status='pass',preserved_original_website_and_upload_text=True,history_v091_and_current_v010_links=True,index_links=len(links),
    scope='Documentation links/status/history preservation, not new research inference')
(ROOT/'research/results/w00_baseline/continuation-handoff-check-result.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps(result,indent=2))
