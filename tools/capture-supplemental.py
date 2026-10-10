"""Run with the restored paper venv to record import and browser dependencies."""
import importlib
from importlib.metadata import version
import json
from pathlib import Path
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
packages = {}
for module, distribution in [("docx", "python-docx"), ("openpyxl", "openpyxl"),
                             ("pymupdf", "PyMuPDF"), ("PIL", "Pillow"), ("matplotlib", "matplotlib"),
                             ("numpy", "numpy")]:
    importlib.import_module(module)
    packages[distribution] = version(distribution)
node = subprocess.run(["npm", "ls", "--prefix", "/tmp/opencode", "--json"],
                      capture_output=True, text=True, check=True)
out = root / "research/results/w00_baseline"
freeze = subprocess.run([sys.executable, "-m", "pip", "freeze"], capture_output=True, text=True, check=True)
(out / "paper_python_requirements.txt").write_text(freeze.stdout, encoding="utf-8")
(out / "node_package_lock.json").write_text((Path("/tmp/opencode") / "package-lock.json").read_text(), encoding="utf-8")
value = {"python": sys.version, "python_packages": packages, "node_packages": json.loads(node.stdout),
         "python_environment": "isolated venv (no system/user site packages)",
         "python_lock": "research/results/w00_baseline/paper_python_requirements.txt",
         "node_lock": "research/results/w00_baseline/node_package_lock.json",
         "status": "imports_pass", "definition": "tools/restore-baseline.sh"}
(out / "supplemental_tools.json").write_text(
    json.dumps(value, indent=2) + "\n", encoding="utf-8")
print(json.dumps(value, indent=2))
