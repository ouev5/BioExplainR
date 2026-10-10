"""Read-only public-source discovery; retain responses outside the repository."""
import concurrent.futures
import datetime
import hashlib
import json
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path


OUT = Path('/tmp/opencode/rgo_public_search_20261010')
PRIDE = 'https://www.ebi.ac.uk/pride/ws/archive/v2/search/projects?'
EPMC = 'https://www.ebi.ac.uk/europepmc/webservices/rest/search?'
JOBS = []
for label, keyword in [
    ('pride_airway', 'airway smooth muscle'),
    ('pride_bronchial', 'bronchial smooth muscle'),
    ('pride_hasm', 'HASM'),
    ('pride_hbsmc', 'HBSMC'),
    ('pride_dex', 'dexamethasone'),
    ('pride_bud', 'budesonide'),
    ('pride_gc', 'glucocorticoid'),
    ('pride_control', 'BioExplainR_unrelated_negative_control_9f3f'),
]:
    JOBS.append((label, PRIDE + urllib.parse.urlencode(dict(keyword=keyword, pageSize=100, page=0))))
for label, query in [
    ('papers_asm_protein', 'TITLE_ABS:("airway smooth muscle" OR "bronchial smooth muscle") AND TITLE_ABS:(proteomics OR proteomic OR secretome OR "mass spectrometry")'),
    ('papers_lung_gc_protein', 'TITLE_ABS:(lung OR airway OR bronchial) AND TITLE_ABS:(dexamethasone OR glucocorticoid OR budesonide) AND TITLE_ABS:(proteomics OR proteomic OR secretome)'),
    ('papers_asm_public', 'TITLE_ABS:("airway smooth muscle" OR "bronchial smooth muscle") AND ("data availability" OR "GEO" OR "ProteomeXchange") AND TITLE_ABS:(glucocorticoid OR dexamethasone OR budesonide)'),
]:
    JOBS.append((label, EPMC + urllib.parse.urlencode(dict(query=query, format='json', pageSize=100, resultType='core'))))


def fetch(job):
    label, url = job
    log = dict(label=label, url=url, utc=datetime.datetime.now(datetime.timezone.utc).isoformat())
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'BioExplainR-public-source-check/1.0', 'Accept': 'application/json'})
        with urllib.request.urlopen(req, timeout=45) as response:
            raw = response.read()
            log.update(status=response.status, bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())
        (OUT / (label + '.json')).write_bytes(raw)
        data = json.loads(raw)
        if label.startswith('pride_'):
            assert isinstance(data, list)
            log['returned'] = len(data)
            summary = [dict(accession=p['accession'], title=p['title'],
                            description=p.get('projectDescription', ''),
                            files=p.get('projectFileNames', []),
                            sample_protocol=p.get('sampleProcessingProtocol', ''),
                            references=p.get('references', [])) for p in data]
            # Present every hit; short titles make the output manageable.
            print(label, len(data), '\n' + '\n'.join(p['accession'] + ' | ' + p['title'] for p in summary), flush=True)
        else:
            hits = data['resultList']['result']
            log.update(hit_count=data['hitCount'], returned=len(hits))
            summary = [dict(id=p['id'], source=p['source'], pmcid=p.get('pmcid', ''), doi=p.get('doi', ''),
                            title=p['title'], abstract=p.get('abstractText', '')) for p in hits]
            print(label, data['hitCount'], '\n' + '\n'.join(p['id'] + ' | ' + p['pmcid'] + ' | ' + p['title'] for p in summary), flush=True)
        (OUT / (label + '_summary.json')).write_text(json.dumps(summary, ensure_ascii=False, indent=2))
    except Exception as exc:
        log['error'] = repr(exc)
        print(label, log['error'], flush=True)
    return log


if __name__ == '__main__':
    OUT.mkdir(exist_ok=False)
    with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:
        logs = list(pool.map(fetch, JOBS))
    (OUT / 'requests.json').write_text(json.dumps(logs, ensure_ascii=False, indent=2))
