"""Meaningful failure probes for the baseline audit, using temporary fixtures."""
import csv
import hashlib
import json
from pathlib import Path
import tempfile
import unittest

from audit_current_results import main_experiment, unique, verify_file, verify_inventory


class AuditFailureTests(unittest.TestCase):
    def test_missing_and_duplicate_score_rows(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            base = root / "research/results/main_scale_480"
            base.mkdir(parents=True)
            for name, value in {
                "experiment_manifest.json": {"n_cases": 1, "n_facts": 1, "methods": ["fixture"], "replicates": 1},
                "case_manifest.json": {"a": {"target_facts": ["n"]}},
                "reference_facts.json": {"a": {"n": 2}},
            }.items():
                (base / name).write_text(json.dumps(value))
            (base / "fact_scores.csv").write_text("case,fact,method,replicate\n")
            (base / "model_calls.csv").write_text("case,method,replicate\na,fixture,1\n")
            with self.assertRaisesRegex(ValueError, "missing/unexpected fact evaluations"):
                main_experiment(root)
            (base / "fact_scores.csv").write_text("case,fact,method,replicate\na,n,fixture,1\na,n,fixture,1\n")
            with self.assertRaisesRegex(ValueError, "Duplicate main score"):
                main_experiment(root)

    def test_missing_changed_and_escape(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            item = {"path": "value.json", "bytes": 2, "sha256": hashlib.sha256(b"{}").hexdigest()}
            with self.assertRaisesRegex(ValueError, "Missing"):
                verify_file(root, item)
            (root / "value.json").write_text("{}")
            verify_file(root, item)
            (root / "value.json").write_text("[]")
            with self.assertRaisesRegex(ValueError, "SHA-256"):
                verify_file(root, item)
            with self.assertRaisesRegex(ValueError, "project-relative"):
                verify_file(root, dict(item, path="../value.json"))

    def test_duplicate_keys_and_inventory(self):
        rows = [{"case": "a", "fact": "n"}, {"case": "a", "fact": "n"}]
        with self.assertRaisesRegex(ValueError, "Duplicate"):
            unique(rows, ["case", "fact"], "score")
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            content = b"{}"
            (root / "value.json").write_bytes(content)
            item = {"path": "value.json", "bytes": len(content), "sha256": hashlib.sha256(content).hexdigest()}
            with (root / "files.csv").open("w", newline="") as handle:
                writer = csv.DictWriter(handle, fieldnames=item)
                writer.writeheader()
                writer.writerows([item, item])
            inventory = root / "files.csv"
            with self.assertRaisesRegex(ValueError, "Duplicate"):
                verify_inventory(root, {"path": "files.csv", "bytes": inventory.stat().st_size,
                                       "sha256": hashlib.sha256(inventory.read_bytes()).hexdigest()})


if __name__ == "__main__":
    unittest.main()
