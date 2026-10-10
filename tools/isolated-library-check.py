"""Install the built package with an isolated Imports-only R library on this host.

Dependencies are linked from the observed system installations. This tests the
absence of optional bioinformatics/UI packages, not a fresh OS or downloaded lock.
"""
import argparse
import json
import os
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--archive", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    output = args.output.resolve()
    if output.exists():
        raise ValueError("Output already exists; use a new directory")
    output.mkdir(parents=True)
    library = output / "library"
    library.mkdir()
    query = r'''
      p <- installed.packages()
      deps <- tools::package_dependencies(c("httr2", "jsonlite", "digest"), db=p,
                 which=c("Depends", "Imports", "LinkingTo"), recursive=TRUE)
      names <- unique(c("httr2", "jsonlite", "digest", unlist(deps)))
      names <- setdiff(names, c("R", rownames(p)[p[,"Priority"] %in% c("base", "recommended")]))
      jsonlite::write_json(lapply(names, function(n) list(name=n, version=p[n,"Version"],
        path=file.path(p[n,"LibPath"], n))), stdout(), auto_unbox=TRUE)
    '''
    packages = json.loads(subprocess.check_output(["Rscript", "--vanilla", "-e", query], text=True))
    for package in packages:
        (library / package["name"]).symlink_to(package["path"], target_is_directory=True)
    env = dict(os.environ, R_LIBS=str(library), R_LIBS_USER=str(library), R_LIBS_SITE=str(library),
               R_ENVIRON_USER="/dev/null", R_PROFILE_USER="/dev/null")
    (output / "dependencies.json").write_text(json.dumps(packages, indent=2) + "\n")
    commands = [
        ["R", "CMD", "INSTALL", f"--library={library}", str(args.archive.resolve())],
        ["Rscript", "--vanilla", str(ROOT / "tools/offline-smoke.R"), str(output / "smoke")],
        ["Rscript", "--vanilla", "-e",
         'stopifnot(!any(vapply(c("DESeq2","SingleCellExperiment","MultiAssayExperiment","SpatialExperiment","shiny","ggplot2"),requireNamespace,logical(1),quietly=TRUE)))'],
    ]
    for command in commands:
        subprocess.run(command, cwd=ROOT, env=env, check=True)
    (output / "isolation.json").write_text(json.dumps({"status": "pass", "commands": commands,
        "scope": "Imports-only linked library on existing Ubuntu/R; no container or third-party reproduction"}, indent=2) + "\n")
    print("Isolated Imports-only installed-package smoke passed")


if __name__ == "__main__":
    main()
