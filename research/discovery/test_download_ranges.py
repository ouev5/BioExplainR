"""Offline restoration probes: preserve a sealed report and reject changed input."""
import gzip
import hashlib
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from download_ranges import download


class Response:
    def __init__(self, headers, content=b"", status=200):
        self.headers, self.content, self.status = headers, content, status

    def __enter__(self):
        return self

    def __exit__(self, *args):
        return False

    def read(self):
        return self.content


class SealedDownloadTests(unittest.TestCase):
    def test_restoration_preserves_report_and_rejects_changed_bytes(self):
        blob = gzip.compress(b"public input\n", mtime=0)
        url, modified = "https://example.org/input.gz", "Tue, 31 Jan 2017 17:50:49 GMT"
        headers = {"Content-Length": str(len(blob)), "Last-Modified": modified}
        for expected in [hashlib.sha256(blob).hexdigest(), "0" * 64]:
            with self.subTest(expected=expected), tempfile.TemporaryDirectory() as directory:
                path = Path(directory) / "input.gz"
                report = path.parent / "range_download.json"
                original = json.dumps({"url": url, "bytes": len(blob), "last_modified": modified,
                                       "sha256": expected, "finished_utc": "historical"}).encode()
                report.write_bytes(original)
                def open_request(request, timeout):
                    if request.get_method() == "HEAD":
                        return Response(headers)
                    return Response(dict(headers, **{"Content-Range": f"bytes 0-{len(blob)-1}/{len(blob)}"}), blob, 206)
                with patch("download_ranges.urllib.request.urlopen", side_effect=open_request):
                    if expected == "0" * 64:
                        with self.assertRaisesRegex(ValueError, "SHA-256"):
                            download(url, path, workers=1, preserve_report=True)
                    else:
                        download(url, path, workers=1, preserve_report=True)
                        self.assertEqual(path.read_bytes(), blob)
                self.assertEqual(report.read_bytes(), original)

    def test_existing_sealed_input_is_not_renamed_or_replaced(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "input.gz"
            path.write_bytes(b"original")
            path.with_name("range_download.json").write_text(json.dumps({"url": "https://example.org/input.gz"}))
            with patch("download_ranges.urllib.request.urlopen") as network:
                with self.assertRaisesRegex(ValueError, "missing sealed input"):
                    download("https://example.org/input.gz", path, preserve_report=True)
                network.assert_not_called()
            self.assertEqual(path.read_bytes(), b"original")


if __name__ == "__main__":
    unittest.main()
