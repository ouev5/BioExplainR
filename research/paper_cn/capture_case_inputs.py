"""Index the saved public input objects consumed by the new paper cases."""
import hashlib
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
NAMES=["research/cache/real_objects.rds","research/results/miniacc_installed_review/project.rds",
       "research/results/miniacc_installed_review/feature_results.csv","research/paper_cn/run_cases.R"]
OUTPUT=ROOT/"research/results/w00_baseline/paper-cn-case-inputs.json"


def main():
    if OUTPUT.exists():raise ValueError("Input index exists")
    result={"status":"indexed","scope":"Post-run input inventory of preserved public source objects; no new upstream fitting",
            "files":[{"path":name,"bytes":(ROOT/name).stat().st_size,"sha256":hashlib.sha256((ROOT/name).read_bytes()).hexdigest()} for name in NAMES]}
    OUTPUT.write_text(json.dumps(result,indent=2)+"\n")
    print(json.dumps(result,indent=2))


if __name__=="__main__":main()
