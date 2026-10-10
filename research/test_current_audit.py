"""Meaningful failure probes for the baseline audit, using temporary fixtures."""
import csv
import hashlib
import json
from pathlib import Path
import tempfile
import unittest

from audit_current_results import main_experiment, narrative_links, unique, verify_file, verify_inventory, verify_saved_run


class AuditFailureTests(unittest.TestCase):
    def test_v010_missing_duplicate_and_failed_narrative_links(self):
        ids = [f"图 {n}" for n in range(1, 4)] + ["表 1"] + \
            [f"补充图 S{n}" for n in range(1, 9)] + [f"补充表 S{n}" for n in range(1, 14)]
        links = [{"id": name, "status": "pass"} for name in ids]
        self.assertEqual(len(narrative_links({"figure_table_narrative_links": links}, "v0.10")), 25)
        for broken in [links[:-1], links[:-1] + [links[-2]], links[:-1] + [{"id": ids[-1], "status": "fail"}]]:
            with self.assertRaisesRegex(ValueError, "Incomplete manuscript"):
                narrative_links({"figure_table_narrative_links": broken}, "v0.10")

    def test_saved_followup_changed_and_unlisted_member(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            base = root / "run"
            base.mkdir()
            content = b'{"status": "pass"}'
            (base / "audit.json").write_bytes(content)
            (base / "files_manifest.json").write_text(json.dumps({"files": [
                {"path": "audit.json", "bytes": len(content), "sha256": hashlib.sha256(content).hexdigest()}]}))
            self.assertEqual(verify_saved_run(root, "run"), 1)
            (base / "audit.json").write_bytes(content.replace(b"pass", b"fail"))
            with self.assertRaisesRegex(ValueError, "SHA-256"):
                verify_saved_run(root, "run")
            (base / "audit.json").write_bytes(content)
            (base / "unlisted.csv").write_text("value\n1\n")
            with self.assertRaisesRegex(ValueError, "membership mismatch"):
                verify_saved_run(root, "run")

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
