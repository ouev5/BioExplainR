"""Acquire a fixed, local CPU model/runtime and pinned comparator sources."""
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import subprocess
import tarfile
import urllib.request

OUT = Path('/tmp/opencode/common-performance-runtime')


def fetch(url, path, expected=None):
    complete = path.exists() and (expected is None or hashlib.sha256(path.read_bytes()).hexdigest() == expected)
    if not complete:
        headers = ['-H', 'Accept: application/octet-stream'] if '/releases/assets/' in url else []
        subprocess.run(['curl', '-fsSL', '--retry', '3', '--retry-all-errors', '--connect-timeout', '30', '--max-time', '900',
                        '-C', '-', *headers, '-o', str(path), url], check=True)
    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    if expected is not None and digest != expected:
        raise ValueError(f'Unexpected source hash: {path.name}')
    return {'url': url, 'path': str(path), 'bytes': path.stat().st_size, 'sha256': digest}


def main():
    OUT.mkdir(exist_ok=True)
    items = []
    runtime = OUT / 'llama-b11429-bin-ubuntu-x64.tar.gz'
    items.append(fetch('https://api.github.com/repos/ggml-org/llama.cpp/releases/assets/613152023', runtime,
                       'f6d25dde8f51133143d1453da4fd5f73b145127177612a283bf7995957af3392'))
    with tarfile.open(runtime) as archive:
        archive.extractall(OUT, filter='data')
    model_url = 'https://modelscope.cn/models/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/master/qwen2.5-1.5b-instruct-q4_k_m.gguf'
    items.append(fetch(model_url, OUT / 'qwen2.5-1.5b-instruct-q4_k_m.gguf',
                       '6a1a2eb6d15622bf3c96857206351ba97e1af16c30d7a74ee38970e434e9407e'))
    for repo, branch, name in [('NIH-NEI/SCassist', 'main', 'SCassist'),
                               ('Winnie09/GPTCelltype', 'master', 'GPTCelltype'),
                               ('ncbi-nlp/GeneAgent', 'main', 'GeneAgent')]:
        with urllib.request.urlopen(f'https://api.github.com/repos/{repo}/commits/{branch}', timeout=60) as response:
            commit = json.load(response)['sha']
        item = fetch(f'https://api.github.com/repos/{repo}/tarball/{commit}', OUT / f'{name}-{commit}.tar.gz')
        item['commit'] = commit
        items.append(item)
    (OUT / 'runtime_manifest.json').write_text(json.dumps({'created_utc': datetime.now(timezone.utc).isoformat(),
                                                         'inputs': items}, indent=2)+'\n')
    print(json.dumps(items, indent=2))


if __name__ == '__main__':
    main()
