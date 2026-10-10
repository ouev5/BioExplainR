"""Scan the intended Git index or delivery archive for common credential formats, without printing values."""
import argparse
import hashlib
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
    "aws_access_key": rb"(?<![A-Za-z0-9])AKIA[0-9A-Z]{16}(?![A-Za-z0-9])",
}


def scan(name, data, findings, non_zip_artifacts):
    for label, pattern in PATTERNS.items():
        if re.search(pattern, data): findings.append({"path": name, "type": label})
    if name.endswith((".zip", ".docx", ".xlsx")):
        if not zipfile.is_zipfile(io.BytesIO(data)):
            non_zip_artifacts.append(name)
            return
        with zipfile.ZipFile(io.BytesIO(data)) as z:
            for entry in z.infolist():
                if not entry.is_dir(): scan(name+":"+entry.filename, z.read(entry), findings, non_zip_artifacts)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--archive", type=Path)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    findings = []
    non_zip_artifacts = []
    if args.archive:
        names = [args.archive.name]
    else:
        names = subprocess.check_output(["git", "ls-files", "-z"], cwd=ROOT).decode().split("\0")
        names = [n for n in names if n]
        if not names: raise ValueError("Stage intended files before scanning")
    lfs_files = 0
    for name in names:
        data = args.archive.read_bytes() if args.archive else subprocess.check_output(["git", "show", ":"+name], cwd=ROOT)
        if data.startswith(b"version https://git-lfs.github.com/spec/v1\n"):
            pointer = re.fullmatch(rb"version https://git-lfs.github.com/spec/v1\noid sha256:([0-9a-f]{64})\nsize ([0-9]+)\n", data)
            if pointer is None: raise ValueError(f"Invalid LFS pointer: {name}")
            oid = pointer[1].decode()
            objects = subprocess.check_output(["git", "rev-parse", "--git-path", "lfs/objects"], cwd=ROOT, text=True).strip()
            data = (ROOT / objects / oid[:2] / oid[2:4] / oid).read_bytes()
            if len(data) != int(pointer[2]) or hashlib.sha256(data).hexdigest() != oid:
                raise ValueError(f"LFS object integrity mismatch: {name}")
            lfs_files += 1
        scan(name, data, findings, non_zip_artifacts)
    result = {"status": "pass" if not findings else "fail", "files": len(names), "lfs_objects_scanned": lfs_files,
              "scope": "Common credential format scan; no values emitted", "findings": findings,
              "non_zip_artifacts_raw_scanned": non_zip_artifacts}
    args.output.write_text(json.dumps(result, indent=2)+"\n")
    print(json.dumps(result, indent=2))
    return 1 if findings else 0


if __name__ == "__main__": raise SystemExit(main())
