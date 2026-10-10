"""Freeze and acquire public receptor intervention inputs before candidate analysis."""
import argparse
from datetime import datetime, timezone
import gzip
import hashlib
import json
from pathlib import Path
import subprocess
import urllib.request

ROOT = Path(__file__).resolve().parents[2]


def record(p):
    return {'path': p.name, 'bytes': p.stat().st_size, 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()}


def fetch(url, path):
    subprocess.run(['curl', '-fsSL', '--retry', '3', '--connect-timeout', '20', '--max-time', '180', '-o', str(path), url], check=True)
    if path.name.endswith('.gz'):
        with gzip.open(path, 'rb') as f:
            while f.read(1024*1024):
                pass
    return {**record(path), 'url': url, 'downloaded_utc': datetime.now(timezone.utc).isoformat()}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('output', type=Path)
    parser.add_argument('--resume', action='store_true')
    args = parser.parse_args()
    out = args.output
    out.mkdir(exist_ok=args.resume)
    protocol = ROOT / 'research/discovery/MECHANISM_PROTOCOL.md'
    if not args.resume:
        (out / 'frozen_protocol.json').write_text(json.dumps({'frozen_utc': datetime.now(timezone.utc).isoformat(),
            'protocol': record(protocol), 'script': record(Path(__file__)),
            'candidate': 'ENSG00000152583/SPARCL1', 'expression_not_read': True}, indent=2)+'\n')
    manifest = out / 'input_manifest.json'
    inputs = json.loads(manifest.read_text())['inputs'] if manifest.exists() else []
    for name, url in [
        ('intervention_metadata.txt', 'https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE229084&targ=gsm&form=text&view=brief'),
        ('chip_metadata.txt', 'https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE95632&targ=gsm&form=text&view=brief'),
        ('intervention_series.txt.gz', 'https://ftp.ncbi.nlm.nih.gov/geo/series/GSE229nnn/GSE229084/matrix/GSE229084_series_matrix.txt.gz'),
        ('geneCounts.tab.gz', 'https://ftp.ncbi.nlm.nih.gov/geo/series/GSE229nnn/GSE229084/suppl/GSE229084_geneCounts.tab.gz'),
        ('PMC10710461.xml', 'https://www.ebi.ac.uk/europepmc/webservices/rest/PMC10710461/fullTextXML'),
        ('PMC5576583.xml', 'https://www.ebi.ac.uk/europepmc/webservices/rest/PMC5576583/fullTextXML')]:
        if name in {r['path'] for r in inputs}:
            continue
        path = out / name
        if path.exists():
            path.rename(path.with_name(name+'.incomplete'))
        inputs.append(fetch(url, path))
        manifest.write_text(json.dumps({'inputs': inputs}, indent=2)+'\n')
    print(json.dumps(inputs, indent=2))


if __name__ == '__main__':
    main()
