"""Freeze inputs/code/order, record actual HTTP bytes, and run the common task."""
import argparse
from datetime import datetime, timezone
import hashlib
from http.server import BaseHTTPRequestHandler, HTTPServer
import json
from pathlib import Path
import random
import subprocess
import threading
import time
import urllib.request

ROOT = Path(__file__).resolve().parents[2]
METHODS = ['bio_offline', 'base_r', 'ellmer_table', 'ellmer_facts', 'bio_client_facts']


def record(p):
    return dict(path=str(p.relative_to(ROOT)) if p.is_relative_to(ROOT) else str(p),
                bytes=p.stat().st_size, sha256=hashlib.file_digest(p.open('rb'), 'sha256').hexdigest())


def write(p, x):
    p.write_text(json.dumps(x, ensure_ascii=False, indent=2)+'\n')


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('output', type=Path)
    ap.add_argument('--runtime', type=Path, default=Path('/tmp/opencode/common-performance-runtime'))
    a = ap.parse_args(); out = a.output.resolve(); out.mkdir()
    subprocess.run(['Rscript','--vanilla','research/common_performance/prepare_inputs.R',str(out/'inputs')],check=True,cwd=ROOT)
    tasks = [dict(id=f'{d}_{n}_a{alpha}_l{lfc}',input=f'{d}_{n}.csv',dataset=d,n=n,alpha=alpha,lfc=lfc)
             for d in ['airway','pasilla'] for n in [50,200] for alpha in [.01,.05,.1] for lfc in [0,1]]
    schedule = [dict(task_index=i,repeat=r,method=m) for i in range(24) for r in range(1,4) for m in METHODS]
    rng=random.Random(42); rng.shuffle(schedule)
    for order,x in enumerate(schedule,1): x['order']=order
    bootstrap=[[rng.randrange(24) for _ in range(24)] for _ in range(2000)]
    for name,x in [('tasks',tasks),('schedule',schedule),('bootstrap_indices',bootstrap)]: write(out/f'{name}.json',x)
    assets=[a.runtime/'llama-b11429-bin-ubuntu-x64.tar.gz',a.runtime/'qwen2.5-1.5b-instruct-q4_k_m.gguf']
    expected=['f6d25dde8f51133143d1453da4fd5f73b145127177612a283bf7995957af3392','6a1a2eb6d15622bf3c96857206351ba97e1af16c30d7a74ee38970e434e9407e']
    for p,h in zip(assets,expected): assert record(p)['sha256']==h
    scripts=list((ROOT/'research/common_performance').glob('*.*'))+list((ROOT/'R').glob('*.R'))
    frozen=dict(frozen_utc=datetime.now(timezone.utc).isoformat(),inputs=[record(p) for p in sorted((out/'inputs').glob('*'))],
                scripts=[record(p) for p in sorted(scripts)],assets=[record(p) for p in assets],
                design=[record(out/f'{n}.json') for n in ['tasks','schedule','bootstrap_indices']],
                scope='Known public development DE tables; not independent biological gold',calls_planned=216)
    write(out/'freeze.json',frozen)
    servers=list(a.runtime.rglob('llama-server')); assert len(servers)==1
    command=[str(servers[0]),'-m',str(assets[1]),'--host','127.0.0.1','--port','18181','-t','4','-c','16384','-np','1','--alias','qwen-fixed','--cache-ram','0','--no-cache-prompt']
    write(out/'server_command.json',command)
    log=(out/'server.log').open('w'); server=subprocess.Popen(command,stdout=log,stderr=subprocess.STDOUT)
    (out/'wire').mkdir(); counter=0
    class Proxy(BaseHTTPRequestHandler):
        def do_POST(self):
            nonlocal counter
            counter+=1; name=f'{counter:03d}'
            raw=self.rfile.read(int(self.headers['Content-Length']))
            (out/'wire'/f'{name}_request.json').write_bytes(raw)
            started=time.perf_counter()
            try:
                req=urllib.request.Request('http://127.0.0.1:18181'+self.path,data=raw,headers={'Content-Type':'application/json'})
                with urllib.request.urlopen(req,timeout=180) as response: body=response.read(); status=response.status
            except Exception as e: body=json.dumps({'error':str(e)}).encode(); status=502
            (out/'wire'/f'{name}_response.json').write_bytes(body)
            write(out/'wire'/f'{name}_metadata.json',dict(path=self.path,status=status,elapsed_sec=time.perf_counter()-started,
                request=record(out/'wire'/f'{name}_request.json'),response=record(out/'wire'/f'{name}_response.json')))
            try:
                self.send_response(status); self.send_header('Content-Type','application/json'); self.send_header('Content-Length',str(len(body))); self.end_headers(); self.wfile.write(body)
            except BrokenPipeError: pass
        def log_message(self,*args): pass
    proxy=HTTPServer(('127.0.0.1',18182),Proxy)
    try:
        for _ in range(120):
            try:
                with urllib.request.urlopen('http://127.0.0.1:18181/health',timeout=2) as r:
                    if r.status==200: break
            except Exception: time.sleep(1)
        else: raise RuntimeError('Model server did not become ready')
        threading.Thread(target=proxy.serve_forever,daemon=True).start()
        subprocess.run(['Rscript','--vanilla','research/common_performance/worker.R',str(out),'http://127.0.0.1:18182/v1'],cwd=ROOT,check=True)
        write(out/'execution.json',dict(status='completed',runs=360,model_calls=counter-1,warmup_calls=1,api_fee=0,local_total_cost='not_measured'))
    finally:
        proxy.shutdown(); proxy.server_close(); server.terminate(); server.wait(timeout=30); log.close()


if __name__=='__main__': main()
