"""Probe isolated R execution boundaries on this host with privileged bubblewrap.

The controller mounts only public fixtures and an installed package library.
These are engineering probes, not a live code-agent evaluation or fresh OS build.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import socket
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--library", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    library = args.library.resolve()
    if not (library / "BioExplainR/DESCRIPTION").is_file():
        raise ValueError("Supply a real installed BioExplainR library")
    listener = socket.socket()
    listener.bind(("127.0.0.1", 0))
    listener.listen()
    try:
        with tempfile.TemporaryDirectory(dir="/tmp/opencode") as directory:
            base = Path(directory)
            base.chmod(0o755)
            public = base / "public"
            public.mkdir()
            public.chmod(0o755)
            inputs = public / "input.csv"
            inputs.write_text("log2FoldChange,padj\n2,0.01\n-2,0.02\n0.1,0.8\n")
            hidden = base / "controlled_gold.json"
            hidden.write_text('{"engineering_probe": "must_not_be_visible"}\n')
            hidden.chmod(0o600)
            uid, gid = os.getuid(), os.getgid()
            common = ["sudo", "-n", "bwrap", "--unshare-all", "--die-with-parent", "--new-session",
                "--ro-bind", "/usr", "/usr", "--ro-bind", "/bin", "/bin", "--ro-bind", "/lib", "/lib",
                "--ro-bind", "/lib64", "/lib64", "--dir", "/etc", "--ro-bind", "/etc/R", "/etc/R",
                "--ro-bind", "/etc/alternatives", "/etc/alternatives", "--ro-bind", "/etc/ld.so.cache", "/etc/ld.so.cache",
                "--dir", "/opt", "--ro-bind", str(library), "/opt/library", "--ro-bind", str(public), "/input",
                "--proc", "/proc", "--dev", "/dev", "--tmpfs", "/tmp", "--tmpfs", "/scratch",
                "--chdir", "/scratch", "--uid", str(uid), "--gid", str(gid), "--cap-drop", "ALL",
                "--clearenv", "--setenv", "PATH", "/usr/bin:/bin", "--setenv", "R_LIBS_SITE", "/opt/library",
                "--setenv", "R_LIBS_USER", "/opt/library", "--setenv", "HOME", "/scratch",
                "--", "/usr/bin/prlimit", "--as=2147483648", "--cpu=20", "--nofile=1024", "--",
                "/usr/bin/Rscript", "--vanilla", "-e"]
            host_net = os.readlink("/proc/self/ns/net")
            expression = f'''
              library(BioExplainR)
              fail_write <- function(path) suppressWarnings(tryCatch({{writeLines("probe", path); FALSE}}, error=function(e) TRUE))
              denied <- fail_write("/input/input.csv")
              outside <- fail_write("/usr/bioexplainr_boundary_probe")
              gold_absent <- !file.exists("{hidden}") && !file.exists("/home/ubuntu/creatR/research/study_materials/investigator_answer_key.json")
              host_home_absent <- !dir.exists("/home/ubuntu")
              network <- suppressWarnings(tryCatch({{x <- socketConnection("127.0.0.1", {listener.getsockname()[1]}, open="r+", timeout=1); close(x); FALSE}}, error=function(e) TRUE))
              own_net <- Sys.readlink("/proc/self/ns/net")
              isolated_net <- !identical(own_net, "{host_net}")
              dir.create("/scratch/output")
              ctx <- bio_context(read.csv("/input/input.csv"), scope=list(comparison_id="fixture"))
              ex <- bio_explain(ctx,use_llm=FALSE)
              suppressMessages(bio_report(ex,file="/scratch/output/report.html"))
              report_ok <- file.info("/scratch/output/report.html")$size > 0
              stopifnot(denied,outside,gold_absent,host_home_absent,network,isolated_net,report_ok,
                ctx$facts$n_significant == 2,ctx$facts$n_up == 1,ctx$facts$n_down == 1)
              jsonlite::write_json(list(status="pass",readonly_input=denied,outside_write_denied=outside,
                gold_not_mounted=gold_absent,host_home_not_mounted=host_home_absent,network_denied=network,
                network_namespace_distinct=isolated_net,scratch_report=report_ok,
                resource_limits=readLines("/proc/self/limits")),stdout(),auto_unbox=TRUE)
            '''
            result = subprocess.run(common + [expression], capture_output=True, text=True, timeout=45)
            if result.returncode != 0:
                raise RuntimeError(result.stdout + result.stderr)
            probes = json.loads(result.stdout)
            original = "log2FoldChange,padj\n2,0.01\n-2,0.02\n0.1,0.8\n"
            assert inputs.read_text() == original
            listener.settimeout(.1)
            try:
                connection, _ = listener.accept()
                connection.close()
                raise AssertionError("Sandbox connected to host listener")
            except TimeoutError:
                pass
            timed = subprocess.run(["timeout", "--signal=TERM", "--kill-after=2", "2", *common, "Sys.sleep(30)"],
                capture_output=True, text=True, timeout=8)
            assert timed.returncode == 124, timed.stdout + timed.stderr
            probes["controller_timeout"] = "pass: timeout exit 124"
            output = {"status": "pass", "scope": "restricted host-mounted R boundary probes, not clean OS or live agent",
                "probes": probes, "runtime": subprocess.check_output(["bwrap", "--version"], text=True).strip(),
                "input_sha256": hashlib.sha256(inputs.read_bytes()).hexdigest(),
                "package_description_sha256": hashlib.sha256((library / "BioExplainR/DESCRIPTION").read_bytes()).hexdigest(),
                "mount_policy": "readonly runtime/library/public input; tmpfs scratch; host project/home/gold absent",
                "limits": {"address_space_bytes": 2147483648, "cpu_seconds": 20, "open_files": 1024},
                "execution_prefix": common[:-1]}
            args.output.write_text(json.dumps(output, indent=2) + "\n")
            print("Input write, outside write, gold visibility, host network, scratch report, resource limits and timeout probes passed")
    finally:
        listener.close()


if __name__ == "__main__":
    main()
