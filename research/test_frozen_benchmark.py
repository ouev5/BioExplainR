"""Exercise W09 artifacts with hand-authored protocol labels, not research gold."""
import csv
import json
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = ROOT / "research/frozen_benchmark"
TMP = "/tmp/opencode" if Path("/tmp/opencode").is_dir() else None


class BenchmarkBoundaries(unittest.TestCase):
    def run_r(self, script, *args, success=True):
        result = subprocess.run(["Rscript", "--vanilla", str(SCRIPTS / script), *args], cwd=ROOT,
                                text=True, capture_output=True)
        self.assertEqual(result.returncode == 0, success, result.stdout + result.stderr)
        return result

    def test_dry_run_immutability_hashes_and_keys(self):
        with tempfile.TemporaryDirectory(dir=TMP) as directory:
            output = Path(directory) / "run"
            self.run_r("run_claim_benchmark.R", f"--output={output}")
            manifest = f"--manifest={output / 'benchmark_manifest.json'}"
            self.run_r("audit_benchmark.R", manifest)
            self.run_r("run_claim_benchmark.R", f"--output={output}", success=False)
            calls = output / "calls.csv"
            calls.write_text(calls.read_text() + "corrupt\n")
            self.run_r("audit_benchmark.R", manifest, success=False)

    def test_replay_and_explicit_scoring(self):
        with tempfile.TemporaryDirectory(dir=TMP) as directory:
            base = Path(directory)
            replay = base / "predictions.csv"
            replay.write_text("case_id,prediction\nfixture-001,3\nfixture-002,0\n")
            output = base / "run"
            self.run_r("run_claim_benchmark.R", "--mode=replay", f"--replay={replay}", f"--output={output}")
            self.run_r("audit_benchmark.R", f"--manifest={output / 'benchmark_manifest.json'}")
            gold = base / "controlled.csv"
            gold.write_text("case_id,reference\nfixture-001,3\nfixture-002,1e-132\n")
            score = base / "scores.csv"
            self.run_r("score_benchmark.R", f"--calls={output / 'calls.csv'}", f"--gold={gold}", f"--output={score}")
            with score.open() as handle:
                rows = list(csv.DictReader(handle))
            self.assertEqual([r["correct"] for r in rows], ["TRUE", "FALSE"])
            gold.write_text("case_id,reference\nfixture-001,3\n")
            self.run_r("score_benchmark.R", f"--calls={output / 'calls.csv'}", f"--gold={gold}", f"--output={base / 'missing.csv'}", success=False)
            self.assertFalse((base / "missing.csv").exists())

    def test_public_input_rejects_controlled_fields(self):
        with tempfile.TemporaryDirectory(dir=TMP) as directory:
            base = Path(directory)
            cases = base / "cases.json"
            cases.write_text(json.dumps([{"case_id": "c", "facts": {"gold": "secret"}}]))
            self.run_r("run_claim_benchmark.R", f"--input={cases}", f"--output={base / 'run'}", success=False)
            self.assertFalse((base / "run").exists())


if __name__ == "__main__":
    unittest.main()
