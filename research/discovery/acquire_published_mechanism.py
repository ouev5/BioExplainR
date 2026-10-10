"""Retrieve the authors' processed sample annotation as independent mapping evidence."""
import argparse
import json
from pathlib import Path
import subprocess
from acquire_chip import fetch


def main():
    ap=argparse.ArgumentParser();ap.add_argument('output',type=Path);ap.add_argument('--retry-source',action='store_true');a=ap.parse_args();out=a.output
    url='https://ftp.ncbi.nlm.nih.gov/geo/series/GSE229nnn/GSE229084/suppl/GSE229084_SE.processed.rds.gz'
    if a.retry_source:url+='?source=continuation_metadata'
    r=fetch(url,out/'SE.processed.rds.gz');(out/('published_object_acquisition_retry.json' if a.retry_source else 'published_object_acquisition.json')).write_text(json.dumps(r,indent=2)+'\n')
    if r['status']!='downloaded':raise RuntimeError(r)
    subprocess.run(['Rscript','--vanilla','research/discovery/inspect_published_mechanism.R',str(out)],check=True)


if __name__=='__main__':main()
