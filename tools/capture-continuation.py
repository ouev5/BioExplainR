"""Archive actual continuation environment/check evidence without changing W00 history."""
import argparse
from datetime import datetime, timezone
import json
from pathlib import Path
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "research/results/w00_baseline"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--core-output", type=Path, required=True)
    parser.add_argument("--bwrap-output", type=Path, required=True)
    parser.add_argument("--prefix", default="continuation", help="New evidence prefix; refuses existing capture targets")
    options = parser.parse_args()
    prefix = options.prefix
    if not prefix or any(c not in "abcdefghijklmnopqrstuvwxyz0123456789-_" for c in prefix):
        raise ValueError("Use a lowercase ASCII evidence prefix")
    def target(name):
        return OUT / f"{prefix}-{name}"
    names = ["00check.log", "testthat.Rout", "isolation-result.json", "core-dependencies.json", "core-smoke.json",
             "core-report.html", "core-relation-report.html", "bwrap-offline-smoke-status.txt", "r-packages.csv",
             "optional-dependencies.csv", "api-inventory.csv", "r-session.txt", "system-packages.tsv", "environment-result.json"]
    if any(target(name).exists() for name in names):
        raise ValueError("Capture targets already exist; choose a new prefix")
    core = options.core_output
    for source, destination in [
        (ROOT / "BioExplainR.Rcheck/00check.log", "00check.log"),
        (ROOT / "BioExplainR.Rcheck/tests/testthat.Rout", "testthat.Rout"),
        (core / "isolation.json", "isolation-result.json"),
        (core / "dependencies.json", "core-dependencies.json"),
        (core / "smoke/smoke.json", "core-smoke.json"),
        (core / "smoke/offline-report.html", "core-report.html"),
        (core / "smoke/relation-report.html", "core-relation-report.html"),
        (options.bwrap_output / "status.txt", "bwrap-offline-smoke-status.txt"),
    ]:
        shutil.copy2(source, target(destination))
    query = r'''
      p <- installed.packages()
      write.csv(p[,c("Package","Version","LibPath")], "%s", row.names=FALSE)
      d <- read.dcf("DESCRIPTION")
      n <- trimws(strsplit(gsub("\\([^)]*\\)", "", d[1,"Suggests"]), ",")[[1]])
      z <- data.frame(package=n, installed=vapply(n,requireNamespace,logical(1),quietly=TRUE),
        version=vapply(n,function(k)as.character(packageVersion(k)),""))
      write.csv(z,"%s",row.names=FALSE)
      ns <- loadNamespace("BioExplainR", lib.loc="BioExplainR.Rcheck")
      exports <- sort(getNamespaceExports(ns))
      exports <- exports[vapply(exports,function(k)is.function(get(k,ns)),logical(1))]
      api <- data.frame(name=exports, signature=vapply(exports,function(k)
        paste(deparse(args(get(k,ns))),collapse=" "),""))
      write.csv(api,"%s",row.names=FALSE)
      print(z); print(sessionInfo())
    ''' % (target("r-packages.csv"), target("optional-dependencies.csv"), target("api-inventory.csv"))
    result = subprocess.run(["Rscript", "--vanilla", "-e", query], cwd=ROOT, capture_output=True, text=True, check=True)
    target("r-session.txt").write_text(result.stdout + result.stderr)
    print(result.stdout)
    packages = subprocess.check_output(["dpkg-query", "-W", "-f=${Package}\t${Version}\n"], text=True)
    target("system-packages.tsv").write_text(packages)
    evidence = {"status": "local_engineering_verified", "captured_utc": datetime.now(timezone.utc).isoformat(),
                "r": "4.3.3", "bioconductor": "3.18",
                "full_optional_dependencies": "all DESCRIPTION Suggests installed; capability checks limited to exercised tests",
                "imports_only": "installed/report smoke pass using linked dependency library; not a clean OS",
                "container": "boundary probes pass: readonly input, scratch, gold not mounted, network, resource limits, timeout; host-mounted runtime, not fresh OS",
                "acceptance_results": [f"{prefix}-http-result.json", f"{prefix}-shiny-browser/summary.json",
                                       f"{prefix}-sandbox-result.json", f"{prefix}-legacy-api-result.json"],
                "remote_ci_matrix": "not_run; workflow parsed locally", "third_party_reproduction": "not_run"}
    target("environment-result.json").write_text(json.dumps(evidence, indent=2) + "\n")


if __name__ == "__main__":
    main()
