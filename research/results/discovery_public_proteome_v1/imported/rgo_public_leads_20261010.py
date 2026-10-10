import concurrent.futures
import hashlib
import json
import urllib.parse
import urllib.request
from pathlib import Path

OUT = Path('/tmp/opencode/rgo_public_search_20261010')
PROJECTS = ['PXD029028', 'PXD063431', 'PXD029135', 'PXD003971', 'PXD003965', 'PXD003963', 'PXD015566', 'PXD055968']


def get(accession):
    records = []
    for kind in ['project', 'files']:
        base = 'https://www.ebi.ac.uk/pride/ws/archive/v2/projects/' + accession
        pages = []
        for page in range(20 if kind == 'files' else 1):
            url = base + ('/files?' + urllib.parse.urlencode(dict(pageSize=100, page=page)) if kind == 'files' else '')
            try:
                with urllib.request.urlopen(url, timeout=35) as response:
                    raw = response.read()
                    records.append(dict(url=url, status=response.status, sha256=hashlib.sha256(raw).hexdigest(), bytes=len(raw)))
                data = json.loads(raw)
                (OUT / f'{accession}_{kind}_{page}.json').write_bytes(raw)
                if kind == 'project':
                    print(accession, data['title'], '\nDESCRIPTION:', data.get('projectDescription'),
                          '\nSAMPLE:', data.get('sampleProcessingProtocol'), '\nREFERENCES:', data.get('references'), flush=True)
                else:
                    assert isinstance(data, list)
                    pages.extend(data)
                    if len(data) < 100:
                        break
            except Exception as exc:
                records.append(dict(url=url, error=repr(exc)))
                print(accession, kind, repr(exc), flush=True)
                break
        if kind == 'files':
            small = [dict(name=f['fileName'], bytes=f['fileSizeBytes'], sha1=f.get('checksum'),
                          urls=[v['value'] for v in f['publicFileLocations'] if v['name'] == 'FTP Protocol'])
                     for f in pages if not f['fileName'].lower().endswith(('.raw', '.mzml', '.mgf', '.mzid.gz', '.dat', '.msf', '.pdresult'))]
            (OUT / f'{accession}_inventory.json').write_text(json.dumps(pages, indent=2))
            print(accession, 'FILES_TOTAL', len(pages), 'SMALL/PROCESSED:', json.dumps(small, ensure_ascii=False), flush=True)
    return dict(accession=accession, requests=records)


if __name__ == '__main__':
    with concurrent.futures.ThreadPoolExecutor(max_workers=5) as pool:
        logs = list(pool.map(get, PROJECTS))
    (OUT / 'lead_requests.json').write_text(json.dumps(logs, indent=2))
