"""Scan the intended Git index or delivery archive for common credential formats, without printing values."""
import argparse
import io
import json
from pathlib import Path
import re
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[1]
PATTERNS = {
    "github_fine_grained": rb"github_pat_[A-Za-z0-9_]{30,}",
    "github_classic": rb"gh[pousr]_[A-Za-z0-9]{30,}",
    "openai_style": rb"sk-(?:proj-)?[A-Za-z0-9_-]{24,}",
    "private_key": rb"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----",
    "aws_access_key": rb"AKIA[0-9A-Z]{16}",
}


def scan(name, data, findings):
    for label, pattern in PATTERNS.items():
        if re.search(pattern, data): findings.append({"path": name, "type": label})
    if name.endswith((".zip", ".docx", ".xlsx")):
        with zipfile.ZipFile(io.BytesIO(data)) as z:
            for entry in z.infolist():
                if not entry.is_dir(): scan(name+":"+entry.filename, z.read(entry), findings)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--archive", type=Path)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    findings = []
    if args.archive:
        files = [(args.archive.name, args.archive.read_bytes())]
    else:
        names = subprocess.check_output(["git", "ls-files", "-z"], cwd=ROOT).decode().split("\0")
        files = [(n, subprocess.check_output(["git", "show", ":"+n], cwd=ROOT)) for n in names if n]
        if not files: raise ValueError("Stage intended files before scanning")
    for name, data in files: scan(name, data, findings)
    result = {"status": "pass" if not findings else "fail", "files": len(files),
              "scope": "Common credential format scan; no values emitted", "findings": findings}
    args.output.write_text(json.dumps(result, indent=2)+"\n")
    print(json.dumps(result, indent=2))
    return 1 if findings else 0


if __name__ == "__main__": raise SystemExit(main())
