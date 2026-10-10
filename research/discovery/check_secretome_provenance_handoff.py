"""Final new-work syntax/docs checks and explicit preexisting whitespace scope."""
import ast
import argparse
import json
import re
import subprocess
from pathlib import Path

from validation_sources import ROOT,HERE,utc,record,json_out


def main(out):
    paths=sorted(set(HERE.glob("*secretome_provenance*.py"))|set(HERE.glob("*secretome_provenance*.R"))|
        {HERE / "SECRETOME_PROVENANCE_PROTOCOL.md",ROOT / "rgo.md",ROOT / "docs/secretome_provenance_v1/README.md",
         out / "README.md",out / "FINDINGS.md",out / "EXECUTION_NOTES.md"})
    for path in paths:
        text=path.read_text()
        if path.suffix==".py":ast.parse(text,filename=str(path))
        assert all(line==line.rstrip() for line in text.splitlines()),path
    r=subprocess.run(["Rscript","--vanilla","-e",'for(p in Sys.glob("research/discovery/*secretome_provenance*.R")) invisible(parse(p))'],
        cwd=ROOT,capture_output=True,text=True)
    assert r.returncode==0,r.stderr
    links=[]
    for path in [ROOT / "docs/secretome_provenance_v1/README.md",out / "README.md"]:
        for url in re.findall(r"\]\(([^)]+)\)",path.read_text()):
            if url.startswith(("http:","https:")):continue
            target=(path.parent/url).resolve()
            # New archive/manifest intentionally created after this check to avoid recursive indices.
            if target.name in ["provenance_manifest.json","分泌蛋白组-来源诊断与ASM公开证据-附件.zip"]:
                status="pending_seal_output"
            else:
                assert target.exists(),target;status="exists"
            links.append(dict(document=record(path)["path"],url=url,status=status))
    diff=subprocess.run(["git","diff","--check"],cwd=ROOT,capture_output=True,text=True)
    failures=[line for line in diff.stdout.splitlines() if re.match(r".+:\d+: (trailing whitespace|new blank line|space before tab)",line)]
    assert all(line.startswith("research/results/w00_baseline/") for line in failures),failures[:10]
    scoped=subprocess.run(["git","diff","--check","--","rgo.md","docs/secretome_provenance_v1",
        "research/results/discovery_secretome_provenance_v1","research/discovery/*secretome_provenance*",
        "research/discovery/SECRETOME_PROVENANCE_PROTOCOL.md"],cwd=ROOT,capture_output=True,text=True)
    assert scoped.returncode==0,scoped.stdout+scoped.stderr
    json_out(out / "complete/handoff_check.json",dict(status="pass",utc=utc(),new_source_docs=[record(p) for p in paths],
        links=links,python_AST=True,R_parse=True,new_source_document_whitespace=True,new_scope_git_diff_check=scoped.returncode,
        whole_existing_worktree_diff_check=dict(returncode=diff.returncode,reported_whitespace_locations=len(failures),
            scope="Preexisting baseline CSV CRLF rows only; sealed historical files untouched",examples=failures[:6]),
        visual_scope="Modelimageinput unavailable; browser screenshots preserved but no claimed human/manualimage review"))
    print(json.dumps(dict(status="pass",source_docs=len(paths),links=len(links),existing_baseline_whitespace_locations=len(failures))))


if __name__=="__main__":
    p=argparse.ArgumentParser();p.add_argument("output",type=Path);main(p.parse_args().output.resolve())
