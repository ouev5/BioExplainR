"""Capture actual loopback HTTP request bytes; no real model or key is used."""
import argparse
import hashlib
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
from pathlib import Path
import subprocess
import tempfile
import threading

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    requests = []
    counts = {}

    class Handler(BaseHTTPRequestHandler):
        def log_message(self, *args):
            pass

        def do_POST(self):
            body = self.rfile.read(int(self.headers["Content-Length"]))
            counts[self.path] = counts.get(self.path, 0) + 1
            requests.append({"path": self.path, "sha256": hashlib.sha256(body).hexdigest(),
                "bytes": len(body), "body": json.loads(body), "auth_header_present": bool(
                    self.headers.get("Authorization") or self.headers.get("x-api-key"))})
            status = 401 if self.path == "/unauthorized" else 503 if self.path == "/retry" and counts[self.path] == 1 else 200
            if status != 200:
                response = {"error": {"message": "fixture-key-for-local-test"}}
            elif self.path == "/anthropic":
                response = {"model": "local-fixture", "content": [{"type": "text", "text": '{"data_facts":["three"],"claims":[]}'}],
                    "usage": {"input_tokens": 8, "output_tokens": 4}}
            else:
                response = {"model": "local-fixture", "choices": [{"message": {"content": '{"data_facts":["three"],"claims":[]}'}}],
                    "usage": {"prompt_tokens": 8, "completion_tokens": 4, "total_tokens": 12}}
            payload = json.dumps(response).encode()
            self.send_response(status)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(payload)))
            if status == 503:
                self.send_header("Retry-After", "0")
            self.end_headers()
            self.wfile.write(payload)

    server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    try:
        with tempfile.TemporaryDirectory(dir="/tmp/opencode") as directory:
            result_path = Path(directory) / "client.json"
            subprocess.run(["Rscript", "--vanilla", "tools/http-transport-smoke.R",
                f"http://127.0.0.1:{server.server_port}", str(result_path)], cwd=ROOT, check=True, timeout=60)
            client = json.loads(result_path.read_text())
        for protocol in ["openai", "anthropic"]:
            request = next(r for r in requests if r["path"] == f"/{protocol}")
            assert request["sha256"] == client[protocol]["request_hash"]
            assert request["bytes"] == client[protocol]["request_bytes"]
            assert request["auth_header_present"]
            assert request["body"]["fixture"] == {"p": 1e-132, "pca": 0.47842864474215936, "zero": 0, "missing": None}
            assert "fixture-key-for-local-test" not in json.dumps(request["body"])
            assert client[protocol]["structured"]
        assert client["openai"]["usage"]["total_tokens"] == 12
        assert client["anthropic"]["usage"]["input_tokens"] == 8
        assert counts["/retry"] == 2 and counts["/unauthorized"] == 1
        result = {"status": "pass", "scope": "actual loopback HTTP, not a model evaluation",
            "counts": counts, "client": client, "requests": requests}
        args.output.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n")
        print("Actual HTTP body hashes, byte lengths, numeric round-trip, usage and retry checks passed")
    finally:
        server.shutdown()
        server.server_close()
        thread.join()


if __name__ == "__main__":
    main()
