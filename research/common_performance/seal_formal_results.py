"""Seal audited result/report membership and preserve failed/interrupted attempt status."""
from datetime import datetime,timezone
import hashlib
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]

def seal(directory):
    rows=[dict(path=p.relative_to(directory).as_posix(),bytes=p.stat().st_size,sha256=hashlib.file_digest(p.open('rb'),'sha256').hexdigest()) for p in sorted(directory.rglob('*')) if p.is_file() and p.name!='files_manifest.json']
    (directory/'files_manifest.json').write_text(json.dumps(dict(files=rows),indent=2)+'\n')

def main():
    performance=ROOT/'research/results/common_performance_v4';report=ROOT/'docs/research_followup_v1'
    assert json.loads((performance/'audit.json').read_text())['status']=='pass'
    assert json.loads((performance/'supplemental_audit.json').read_text())['status']=='pass'
    assert json.loads((report/'independent_audit.json').read_text())['status']=='pass'
    assert json.loads((report/'browser_audit.json').read_text())['status']=='pass'
    ledger=dict(status='completed_and_independently_audited',utc=datetime.now(timezone.utc).isoformat(),formal_directory='common_performance_v4',
        run_denominator=360,model_attempts=216,warmup_model_calls=1,target_scores=1800,unique_tasks=24,
        previous_attempts=[dict(directory='common_performance_v1',status='interrupted',reason='ellmer Responses API ignored seed'),
            dict(directory='common_performance_v2',status='failed_before_inference',reason='prior service port collision'),
            dict(directory='common_performance_v3',status='interrupted',reason='client config/finish_reason interface errors found before whole run'),
            dict(directory='discovery_mechanism_fit_v1',status='failed_before_counts',reason='relative path at freeze'),
            dict(directory='discovery_mechanism_fit_v2',status='failed_before_candidate_analysis',reason='treatment whitespace in count headers'),
            dict(directory='discovery_mechanism_fit_v3',status='failed_before_candidate_analysis',reason='CSV included True read as character in R')],
        interpretation='Development counting/transmission benchmark, not six-tool rank, not general reasoning or independent biology',
        scope='Previous failed/interrupted calls excluded from formal scores; no outputs tuned task/prompt rules')
    (performance/'scientific_ledger.json').write_text(json.dumps(ledger,indent=2)+'\n')
    for d in [performance,report,ROOT/'research/results/common_performance_applicability_v1',ROOT/'research/results/discovery_chip_v1']:seal(d)
    print(json.dumps(ledger,indent=2))

if __name__=='__main__':main()
