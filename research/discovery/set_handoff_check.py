"""Verify new navigation, source syntax and sealed legacy scientific provenance."""
import ast
import json
import re
from pathlib import Path
from validation_sources import ROOT,HERE,record,utc,json_out
from set_integrity import prior_integrity

source=ROOT/"research/results/discovery_set_validation_v1"
scripts=sorted(set(HERE.glob("*set*.py"))|set((ROOT/"research/paper_cn_revision").glob("*set*.py")))
for p in scripts:
    ast.parse(p.read_text(),str(p));assert all(line==line.rstrip() for line in p.read_text().splitlines()),p
index=ROOT/"docs/index.html";links=re.findall(r'href="([^"]+)"',index.read_text())
for link in links:
    if not link.startswith(("http:","https:")):assert (index.parent/link).is_file(),link
for p in [ROOT/"README.md",ROOT/"rgo.md",ROOT/"docs/USER_ACTIONS_REQUIRED.md"]:
    assert "v0.12" in p.read_text(),p
result=dict(status="pass",utc=utc(),python_scripts=len(scripts),index_links=len(links),prior=prior_integrity(source),
    scope="NewnavigationandPythonAST/whitespace; originalscientificpaths/hashes and exactoldnavigation snapshots; no package functionality change")
json_out(source/"handoff_check.json",result)
print(json.dumps(result,ensure_ascii=False,indent=2))
