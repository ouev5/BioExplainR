"""Wait for a running process's completion marker and show low-frequency progress."""
import argparse
import json
from pathlib import Path
import time


def main():
    ap=argparse.ArgumentParser();ap.add_argument('--seconds',type=int,default=600);a=ap.parse_args()
    out=Path('research/results/common_performance_v4');deadline=time.monotonic()+a.seconds
    while time.monotonic()<deadline:
        if (out/'execution.json').exists():
            print((out/'execution.json').read_text(),flush=True);return
        runs=list((out/'runs').glob('*.json'))
        print(f'Formal runs saved: {len(runs)}/360',flush=True)
        time.sleep(min(120,max(0,deadline-time.monotonic())))


if __name__=='__main__':main()
