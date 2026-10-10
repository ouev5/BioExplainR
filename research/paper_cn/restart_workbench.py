"""Reload the existing idle loopback workbench after this paper's UI fixes."""
import json
from pathlib import Path
import subprocess
import time
import urllib.request

ROOT=Path(__file__).resolve().parents[2]
PID=3305541


def main():
    command=subprocess.check_output(["ps","-o","args=","-p",str(PID)],text=True)
    cwd=subprocess.check_output(["readlink",f"/proc/{PID}/cwd"],text=True).strip()
    if cwd!=str(ROOT) or "port=3888" not in command or "bio_run_app" not in command:
        raise ValueError("Existing process differs from the verified BioExplainR workbench")
    connections=subprocess.check_output(["ss","-Htn","( sport = :3888 )"],text=True).strip()
    if connections:raise ValueError("Workbench currently has connected clients")
    subprocess.run(["kill","-TERM",str(PID)],check=True)
    for _ in range(40):
        if subprocess.run(["kill","-0",str(PID)],capture_output=True).returncode:break
        time.sleep(.25)
    else:raise RuntimeError("Old workbench did not stop")
    log=Path("/tmp/opencode/bioexplainr-paper-cn-workbench-3888.log")
    with log.open("x") as output:
        process=subprocess.Popen(["Rscript","--vanilla","-e",
            'pkgload::load_all(".", quiet=TRUE); bio_configure("local"); bio_run_app(envir=new.env(parent=globalenv()), port=3888, launch.browser=FALSE)'],
            cwd=ROOT,stdout=output,stderr=subprocess.STDOUT,start_new_session=True)
    for _ in range(120):
        if process.poll() is not None:raise RuntimeError("Updated workbench exited")
        try:
            with urllib.request.urlopen("http://127.0.0.1:3888",timeout=1) as response:
                if response.status==200:break
        except OSError:time.sleep(.5)
    else:raise TimeoutError("Updated workbench did not become ready")
    result={"status":"pass","old_pid":PID,"new_pid":process.pid,"url":"http://127.0.0.1:3888",
            "reload":"current source; original local preset and empty startup workspace retained", "log":str(log)}
    (ROOT/"research/results/w00_baseline/paper-cn-workbench-reload-result.json").write_text(json.dumps(result,indent=2)+"\n")
    print(json.dumps(result,indent=2))


if __name__=="__main__":main()
