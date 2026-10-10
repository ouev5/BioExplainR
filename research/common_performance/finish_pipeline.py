"""Wait for the formal run, then score, independently audit and export results."""
import json
from pathlib import Path
import subprocess
import time

ROOT=Path(__file__).resolve().parents[2]


def main():
    directory=ROOT/'research/results/common_performance_v4'
    while not (directory/'execution.json').exists():
        time.sleep(30)
    execution=json.loads((directory/'execution.json').read_text());assert execution['status']=='completed'
    commands=[('continuation-performance-scoring',['Rscript','--vanilla','research/common_performance/score_complete.R',str(directory)]),
        ('continuation-performance-independent',['python3','research/common_performance/audit_benchmark.py',str(directory)]),
        ('continuation-performance-secondary',['Rscript','--vanilla','research/common_performance/supplemental_scores.R',str(directory)]),
        ('continuation-performance-secondary-independent',['python3','research/common_performance/audit_supplemental_scores.py']),
        ('continuation-research-report-export',['/tmp/opencode/paper-venv/bin/python','research/common_performance/build_followup_report.py'])]
    for label,command in commands:
        subprocess.run(['python3','research/manage_baseline.py','run',label,'--',*command],check=True,cwd=ROOT)


if __name__=='__main__':main()
