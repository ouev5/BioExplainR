"""Download public processed tables and inspect design, without candidate testing."""
import concurrent.futures
import csv
import gzip
import hashlib
import io
import json
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET
from pathlib import Path

OUT = Path('/tmp/opencode/rgo_public_search_20261010')
SELECT = {
    'PXD063431': ['240221_PB_ProteomeDiscoverer_all_Proteins_A549.txt'],
    'PXD029135': ['median-normalized.txt', 'SRDF_File.txt', 'PXD029135_community_annotated.sdrf.tsv'],
    'PXD029028': ['DDA_sample_ID.csv', 'meta_data.csv'],
    'PXD003971': ['NHDF_IL1beta_Dex_sn_1_1.pride.mztab.gz'],
    'PXD003965': ['NHDF_IL1beta_sn_1_1.pride.mztab.gz'],
    'PXD003963': ['NHDF_con_sn_1_1.pride.mztab.gz'],
}


def fetch(job):
    label, url, expected = job
    record = dict(label=label, url=url)
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'BioExplainR-public-source-check/1.0'})
        with urllib.request.urlopen(req, timeout=40) as response:
            raw = response.read()
            record.update(http_status=response.status, bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest(),
                          content_type=response.headers.get('Content-Type'))
        (OUT / label).write_bytes(raw)
        if expected:
            record.update(expected_bytes=expected['fileSizeBytes'], size_matches=len(raw) == expected['fileSizeBytes'])
            checksum = expected.get('checksum', '')
            if checksum:
                record.update(upstream_sha1=checksum, sha1_matches=hashlib.sha1(raw).hexdigest() == checksum.zfill(40))
        if label.endswith('.xml'):
            root = ET.fromstring(raw)
            paragraphs = [' '.join(''.join(p.itertext()).split()) for p in root.iter('p')]
            design = [p for p in paragraphs if any(w in p.lower() for w in ['budesonide', 'donor', 'pxd', 'gse', 'data availability'])]
            supplements = [dict(tag=e.tag, href=e.get('{http://www.w3.org/1999/xlink}href'), text=' '.join(''.join(e.itertext()).split()))
                           for e in root.iter() if e.tag in ['supplementary-material', 'media', 'ext-link']
                           and e.get('{http://www.w3.org/1999/xlink}href')]
            record.update(design_passages=design, links=supplements)
            print(label, 'ARTICLE', '\n' + '\n'.join(p[:3500] for p in design), '\nLINKS', json.dumps(supplements, ensure_ascii=False), flush=True)
        elif label.endswith('.json'):
            data = json.loads(raw)
            if isinstance(data, list):
                record['hits'] = [dict(accession=p['accession'], title=p['title'], files=p.get('projectFileNames', [])) for p in data]
            else:
                record['hits'] = [dict(id=p['id'], title=p['title'], pmcid=p.get('pmcid')) for p in data['resultList']['result']]
            print(label, json.dumps(record['hits'], ensure_ascii=False), flush=True)
        else:
            text = gzip.decompress(raw).decode('utf-8-sig') if label.endswith('.gz') else raw.decode('utf-8-sig')
            lines = text.splitlines()
            delimiter = ',' if label.endswith('.csv') else '\t'
            rows = list(csv.reader(io.StringIO(text), delimiter=delimiter))
            if label.endswith('.gz'):
                headers = {prefix:next((r for r in rows if r and r[0] == prefix), []) for prefix in ['PRH', 'PEH', 'PSH']}
                record.update(headers=headers, row_counts={prefix:sum(bool(r) and r[0] == prefix for r in rows) for prefix in ['PRT', 'PEP', 'PSM']})
                print(label, 'SIZE', len(raw), 'MZTAB', json.dumps(record['row_counts']), 'PROTEIN_HEADER', headers['PRH'], flush=True)
            else:
                record.update(rows=len(rows), header=rows[0], columns=len(rows[0]))
                preview = rows if len(rows) < 60 else rows[:3]
                print(label, 'SIZE', len(raw), 'ROWS', len(rows), 'COLUMNS', len(rows[0]), '\n' + '\n'.join(str(r)[:7000] for r in preview), flush=True)
    except Exception as exc:
        record['error'] = repr(exc)
        print(label, repr(exc), flush=True)
    return record


if __name__ == '__main__':
    jobs = []
    for project, names in SELECT.items():
        inventory = json.loads((OUT / f'{project}_inventory.json').read_text())
        for name in names:
            item = next(f for f in inventory if f['fileName'] == name)
            ftp = next(v['value'] for v in item['publicFileLocations'] if v['name'] == 'FTP Protocol')
            jobs.append((project + '_' + name, ftp.replace('ftp://', 'https://'), item))
    search = 'https://www.ebi.ac.uk/pride/ws/archive/v2/search/projects?'
    for label, keyword in [('pride_intrapulmonary', 'intrapulmonary'), ('pride_airway_proteome', 'airway proteome'), ('pride_actin', 'airway actin')]:
        jobs.append((label + '.json', search + urllib.parse.urlencode(dict(keyword=keyword, pageSize=100, page=0)), None))
    epmc = 'https://www.ebi.ac.uk/europepmc/webservices/rest/'
    jobs.append(('article_34950134.json', epmc + 'search?query=EXT_ID:34950134%20AND%20SRC:MED&format=json&resultType=core', None))
    jobs.append(('article_42336811.json', epmc + 'search?query=EXT_ID:42336811%20AND%20SRC:MED&format=json&resultType=core', None))
    with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:
        results = list(pool.map(fetch, jobs))
    (OUT / 'verified_downloads.json').write_text(json.dumps(results, ensure_ascii=False, indent=2))
