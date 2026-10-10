"""Start a fixture Shiny server, run browser acceptance, and stop the server."""
import argparse
import os
from pathlib import Path
import socket
import subprocess
import time
import urllib.request

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=False)
    with socket.socket() as sock:
        sock.bind(("127.0.0.1", 0))
        port = sock.getsockname()[1]
    env = dict(os.environ, BIOEXPLAINR_ACCEPTANCE_PORT=str(port), BIOEXPLAINR_URL=f"http://127.0.0.1:{port}",
        BIOEXPLAINR_ACCEPTANCE_OUTPUT=str(output), NODE_PATH="/tmp/opencode/node_modules")
    with (output / "server.txt").open("w") as log:
        server = subprocess.Popen(["Rscript", "--vanilla", "tools/shiny-acceptance-server.R"], cwd=ROOT,
            env=env, stdout=log, stderr=subprocess.STDOUT)
        try:
            for _ in range(120):
                if server.poll() is not None:
                    raise RuntimeError("Fixture Shiny server exited; see server.txt")
                try:
                    with urllib.request.urlopen(env["BIOEXPLAINR_URL"], timeout=1) as response:
                        if response.status == 200:
                            break
                except OSError:
                    time.sleep(.5)
            else:
                raise TimeoutError("Shiny fixture server did not start")
            subprocess.run(["node", "research/shiny_acceptance.cjs"], cwd=ROOT, env=env, check=True, timeout=180)
        finally:
            server.terminate()
            try:
                server.wait(timeout=10)
            except subprocess.TimeoutExpired:
                server.kill()
                server.wait()


if __name__ == "__main__":
    main()
