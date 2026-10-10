"""Relocation and rehashed-corruption probes for the public development audit."""
import csv
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

from audit_miniacc import audit

ROOT = Path(__file__).resolve().parents[2]


class MiniaccAuditTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="miniacc-audit-", dir="/tmp/opencode")
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name) / "relocated"
        shutil.copytree(ROOT / "research/results/miniacc_development_v1", self.base)

    def manifest(self, transform):
        path = self.base / "manifest.json"
        value = json.loads(path.read_text())
        transform(value)
        path.write_text(json.dumps(value))

    def table(self, name, transform):
        path = self.base / name
        with path.open(newline="") as handle:
            reader = csv.DictReader(handle)
            fields, data = reader.fieldnames, list(reader)
        transform(data)
        with path.open("w", newline="") as handle:
            writer = csv.DictWriter(handle, fieldnames=fields)
            writer.writeheader()
            writer.writerows(data)
        self.manifest(lambda m: [r.update(bytes=path.stat().st_size,
            sha256=hashlib.sha256(path.read_bytes()).hexdigest()) for r in m["files"]
            if Path(r["path"]).name == name])

    def test_legacy_relocation(self):
        self.assertEqual(audit(self.base)["effects_recomputed"], 66)

    def test_modern_relocation(self):
        def modern(m):
            m.update(manifest_version="2.0", path_base="run_directory")
            for r in m["files"]:
                r["path"] = Path(r["path"]).name
        self.manifest(modern)
        self.assertEqual(audit(self.base)["files_verified"], 23)

    def test_actual_installed_rerun_relocation(self):
        installed = ROOT / "research/results/miniacc_installed_review"
        target = Path(self.temp.name) / "installed-relocated"
        shutil.copytree(installed, target)
        result = audit(target)
        self.assertEqual(result["effects_recomputed"], 66)
        summary = json.loads((target / "summary.json").read_text())
        self.assertEqual(summary["package_mode"], "installed")
        self.assertEqual(summary["package_version"], "0.4.0.9000")
        self.assertNotEqual(summary["package_path"], str(ROOT))
        for name in ["clinical_groups.csv", "sample_map.csv", "paired_measurements.csv", "feature_results.csv",
                     "modality_coverage.csv", "pairwise_coverage.csv", "direction_findings.csv", "engineering_checks.csv"]:
            self.assertEqual((target / name).read_bytes(), (self.base / name).read_bytes(), name)

    def test_runner_refuses_overwrite_before_loading_package(self):
        before = {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in self.base.iterdir()}
        run = subprocess.run(["Rscript", "--vanilla", str(ROOT / "research/multiomics/run_miniacc.R"),
                              str(self.base), "--installed"], cwd=self.temp.name, capture_output=True, text=True)
        self.assertNotEqual(run.returncode, 0)
        self.assertIn("Output exists", run.stderr)
        self.assertEqual(before, {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in self.base.iterdir()})

    def test_missing_manifest_member(self):
        self.manifest(lambda m: m["files"].pop())
        with self.assertRaisesRegex(ValueError, "membership"):
            audit(self.base)

    def test_duplicate_manifest_member(self):
        self.manifest(lambda m: m["files"].append(m["files"][0]))
        with self.assertRaisesRegex(ValueError, "Duplicate"):
            audit(self.base)

    def test_unsafe_manifest_path(self):
        self.manifest(lambda m: m["files"][0].update(path="../alignment_summary.json"))
        with self.assertRaisesRegex(ValueError, "Unsafe"):
            audit(self.base)

    def test_missing_artifact(self):
        (self.base / "facts.json").unlink()
        with self.assertRaisesRegex(ValueError, "Missing"):
            audit(self.base)

    def test_corrupt_hash(self):
        (self.base / "facts.json").write_text("{}")
        with self.assertRaisesRegex(ValueError, "mismatch"):
            audit(self.base)

    def test_truncated_tables_with_valid_hash(self):
        for name in ["modality_coverage.csv", "pairwise_coverage.csv", "relations.csv", "direction_findings.csv",
                     "engineering_checks.csv"]:
            with self.subTest(name=name):
                backup = (self.base / name).read_bytes()
                manifest = (self.base / "manifest.json").read_bytes()
                self.table(name, lambda data: data.pop())
                with self.assertRaisesRegex(ValueError, "membership"):
                    audit(self.base)
                (self.base / name).write_bytes(backup)
                (self.base / "manifest.json").write_bytes(manifest)

    def test_duplicate_primary_keys_with_valid_hash(self):
        for name in ["clinical_groups.csv", "sample_map.csv", "feature_results.csv", "relations.csv",
                     "direction_findings.csv", "paired_measurements.csv"]:
            with self.subTest(name=name):
                backup = (self.base / name).read_bytes()
                manifest = (self.base / "manifest.json").read_bytes()
                self.table(name, lambda data: data.append(data[0]))
                with self.assertRaisesRegex(ValueError, "duplicate key"):
                    audit(self.base)
                (self.base / name).write_bytes(backup)
                (self.base / "manifest.json").write_bytes(manifest)

    def test_extra_measurement_with_valid_hash(self):
        self.table("paired_measurements.csv", lambda data: data.append(dict(data[0], feature_id="EXTRA")))
        with self.assertRaisesRegex(ValueError, "Measurement membership"):
            audit(self.base)

    def test_wrong_stage_with_valid_hash(self):
        self.table("clinical_groups.csv", lambda data: data[0].update(group="wrong"))
        with self.assertRaisesRegex(ValueError, "stage/group"):
            audit(self.base)

    def test_wrong_effect_with_valid_hash(self):
        self.table("feature_results.csv", lambda data: data[0].update(rna_effect="999"))
        with self.assertRaisesRegex(ValueError, "Effect mismatch"):
            audit(self.base)

    def test_wrong_bh_with_valid_hash(self):
        self.table("feature_results.csv", lambda data: data[0].update(rna_padj="999"))
        with self.assertRaisesRegex(ValueError, "BH mismatch"):
            audit(self.base)

    def test_symlink_artifact(self):
        path = self.base / "facts.json"
        path.unlink()
        path.symlink_to(ROOT / "research/results/miniacc_development_v1/facts.json")
        with self.assertRaisesRegex(ValueError, "unsafe artifact"):
            audit(self.base)


if __name__ == "__main__":
    unittest.main()
