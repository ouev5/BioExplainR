"""Restore exact sources/assets used in the formal run, avoiding moving branch heads."""
import hashlib
import json
from pathlib import Path
import subprocess
import tarfile

ROOT=Path(__file__).resolve().parents[2]
OUT=Path('/tmp/opencode/common-performance-runtime')

def main():
    saved=json.loads((ROOT/'research/results/common_performance_applicability_v1/runtime_manifest.json').read_text())
    OUT.mkdir(exist_ok=True)
    for row in saved['inputs']:
        name=Path(row['path']).name;p=OUT/name
        if p.exists() and p.stat().st_size==row['bytes'] and hashlib.file_digest(p.open('rb'),'sha256').hexdigest()==row['sha256']:continue
        url=row['url'];headers=['-H','Accept: application/octet-stream'] if '/releases/assets/' in url else []
        subprocess.run(['curl','-fLsS','--connect-timeout','20','--max-time','900','--retry','3','-C','-',*headers,'-o',str(p),url],check=True)
        assert p.stat().st_size==row['bytes'] and hashlib.file_digest(p.open('rb'),'sha256').hexdigest()==row['sha256']
    with tarfile.open(OUT/'llama-b11429-bin-ubuntu-x64.tar.gz') as a:a.extractall(OUT,filter='data')
    print('Formal runtime/model/source bytes and SHA-256 restored exactly')

if __name__=='__main__':main()
