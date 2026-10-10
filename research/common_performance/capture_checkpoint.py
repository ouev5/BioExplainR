"""Record actual preparation state without running inference or scientific fits."""
from datetime import datetime, timezone
import gzip
import hashlib
import json
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[2]
RUNTIME = Path('/tmp/opencode/common-performance-runtime')
OUT = ROOT / 'research/results/common_performance_checkpoint_v1'


def record(path, name=None):
    return {'path': name or path.name, 'bytes': path.stat().st_size,
            'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}


def main():
    OUT.mkdir(exist_ok=False)
    expected = {
        'llama-b11429-bin-ubuntu-x64.tar.gz': 'f6d25dde8f51133143d1453da4fd5f73b145127177612a283bf7995957af3392',
        'qwen2.5-1.5b-instruct-q4_k_m.gguf': '6a1a2eb6d15622bf3c96857206351ba97e1af16c30d7a74ee38970e434e9407e'}
    assets = []
    for name, digest in expected.items():
        item = record(RUNTIME / name)
        if item['sha256'] != digest:
            raise ValueError(f'Runtime input hash mismatch: {name}')
        assets.append(dict(item, location=str(RUNTIME / name), status='hash_verified_not_used_for_inference'))
    for path in sorted(RUNTIME.glob('*-*.tar.gz')):
        if path.name in expected:
            continue
        item = record(path)
        try:
            with gzip.open(path, 'rb') as handle:
                while handle.read(1024*1024):
                    pass
            item['status'] = 'gzip_readable_source_not_installed'
        except (OSError, EOFError):
            item['status'] = 'incomplete_not_usable'
        assets.append(dict(item, location=str(path)))
    r = subprocess.run(['Rscript', '--vanilla', '-e',
        '.libPaths(c("/tmp/opencode/common-performance-R-library",.libPaths())); '
        'stopifnot(requireNamespace("ellmer",quietly=TRUE)); '
        'cat(as.character(packageVersion("ellmer")))'], capture_output=True, text=True, check=True)
    session = RUNTIME / 'comparator_session.txt'
    (OUT / 'comparator_session.txt').write_bytes(session.read_bytes())
    frozen = ROOT / 'research/results/discovery_mechanism_v1/frozen_protocol.json'
    freeze = json.loads(frozen.read_text())
    protocol = ROOT / 'research/discovery/MECHANISM_PROTOCOL.md'
    if record(protocol) != freeze['protocol']:
        raise ValueError('Mechanism protocol differs from frozen version')
    inputs = json.loads((frozen.parent / 'input_manifest.json').read_text())['inputs']
    for item in inputs:
        if record(frozen.parent / item['path']) != {k: item[k] for k in ['path', 'bytes', 'sha256']}:
            raise ValueError(f'Mechanism input changed: {item["path"]}')
    report = {
        'status': 'preparation_partial', 'captured_utc': datetime.now(timezone.utc).isoformat(),
        'narrative_date': '2026-10-09; execution timestamps retained from host UTC without clock changes',
        'performance': {'protocol': record(ROOT / 'research/common_performance/PROTOCOL.md'),
            'ellmer_version': r.stdout.strip(), 'library': '/tmp/opencode/common-performance-R-library',
            'assets': assets, 'benchmark_input_freeze': 'not_created', 'runner': 'not_implemented',
            'model_calls': 0, 'performance_scores': 0,
            'runtime_manifest': 'not_created; latest acquisition interrupted',
            'interrupted_execution': 'performance-runtime-acquire-final.txt exists without completion metadata'},
        'mechanism': {'frozen_protocol': record(frozen), 'verified_inputs': len(inputs),
            'gene_counts': next(x for x in inputs if x['path'] == 'geneCounts.tab.gz'),
            'chip_peaks_downloaded': False, 'chip_assembly': 'unverified; GEO metadata says mm9 for human HASM2',
            'missing_source': 'PMC5576583.xml: Europe PMC HTTP 500',
            'candidate_expression_read': False, 'statistical_fit': 'not_run', 'independent_numeric_audit': 'not_run',
            'acquisition_script_revision': record(ROOT / 'research/discovery/prepare_mechanism.py'),
            'revision_note': 'Resume/downloader changed after initial freeze; original script hash retained, no candidate analysis'} }
    (OUT / 'checkpoint.json').write_text(json.dumps(report, ensure_ascii=False, indent=2)+'\n')
    files = [record(p) for p in sorted(OUT.iterdir()) if p.is_file()]
    (OUT / 'files_manifest.json').write_text(json.dumps({'files': files}, indent=2)+'\n')
    print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
