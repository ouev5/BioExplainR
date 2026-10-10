"""Pin and inspect source/task evidence; not-applicable tools are never scored as zero."""
from datetime import datetime,timezone
import hashlib
import json
from pathlib import Path
import subprocess
import tarfile
import urllib.request

ROOT=Path(__file__).resolve().parents[2]
RUNTIME=Path('/tmp/opencode/common-performance-runtime')


def main():
    out=ROOT/'research/results/common_performance_applicability_v1';out.mkdir()
    manifest=json.loads((RUNTIME/'runtime_manifest.json').read_text())
    (out/'runtime_manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    rows=[]
    descriptions={'SCassist':'Seurat single-cell workflow assistant; no native DE five-count interface',
                  'GPTCelltype':'Marker-driven cell-type annotation; no native DE five-count interface',
                  'GeneAgent':'Gene-set function analysis agent; no native DE five-count interface'}
    for r in manifest['inputs']:
        p=Path(r['path'])
        assert p.stat().st_size==r['bytes'] and hashlib.file_digest(p.open('rb'),'sha256').hexdigest()==r['sha256']
        tool=next((t for t in descriptions if p.name.startswith(t+'-')),None)
        if not tool:continue
        with tarfile.open(p) as archive:
            for member in archive:
                name=Path(member.name)
                if member.isfile() and name.name.lower()=='readme.md' and len(name.parts)==2:
                    raw=archive.extractfile(member).read(); (out/f'{tool}_README.md').write_bytes(raw)
                    rows.append(dict(tool=tool,status='not_applicable',score=None,reason=descriptions[tool],source=r,
                        evidence_file=f'{tool}_README.md',evidence_sha256=hashlib.sha256(raw).hexdigest(),archive_full_read='pass'))
                    break
            # Parse complete archive, not just first README; truncated tar must fail.
            archive.getmembers()
    assert {r['tool'] for r in rows}==set(descriptions)
    url='https://bioconductor.org/packages/3.18/bioc/src/contrib/iSEE_2.14.0.tar.gz'
    p=out/'iSEE_2.14.0.tar.gz'
    subprocess.run(['curl','-fLsS','--connect-timeout','15','--max-time','120','-o',str(p),url],check=True)
    with tarfile.open(p) as archive:
        for filename in ['DESCRIPTION','README.md']:
            member=archive.getmember('iSEE/'+filename);raw=archive.extractfile(member).read();(out/f'iSEE_{filename}').write_bytes(raw)
        archive.getmembers()
    rows.append(dict(tool='iSEE',status='not_applicable',score=None,reason='SummarizedExperiment interactive exploration; no native DE five-count interface',source_url=url,
        version='2.14.0/Bioc3.18',archive_sha256=hashlib.file_digest(p.open('rb'),'sha256').hexdigest(),evidence_file='iSEE_DESCRIPTION'))
    rows+= [dict(tool=t,status='applicable',reason=reason) for t,reason in [('BioExplainR','Offline facts and model client on DE table'),('ellmer','General model interface, same model/table/facts')]]
    result=dict(status='completed',utc=datetime.now(timezone.utc).isoformat(),tools=rows,
        scope='Source-backed native task applicability; not comprehensive six-tool runtime/performance ranking; non-native wrappers not counted as tool capability')
    (out/'applicability.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result,indent=2))


if __name__=='__main__':main()
