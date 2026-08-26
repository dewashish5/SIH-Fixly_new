"""
Standalone HTTP Server with CORS and Static File Hosting for Worker Reliability.
"""

import os
import sys
import json
import urllib.parse
from http.server import HTTPServer, BaseHTTPRequestHandler
from typing import Optional

_curr_dir = os.path.dirname(os.path.abspath(__file__))
_pkg_root = os.path.abspath(os.path.join(_curr_dir, "..", ".."))
if _pkg_root not in sys.path:
    sys.path.insert(0, _pkg_root)

try:
    from .routes import APIRouter
    from ..data.worker_store import WorkerStore
except ImportError:
    from gig_worker_reliability.api.routes import APIRouter
    from gig_worker_reliability.data.worker_store import WorkerStore


class ReliabilityHTTPRequestHandler(BaseHTTPRequestHandler):
    router: APIRouter = APIRouter()
    static_dir: str = _pkg_root

    def _set_cors_headers(self, status_code: int = 200, content_type: str = "application/json"):
        self.send_response(status_code)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS, PUT, DELETE")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Requested-With")
        self.send_header("Content-Type", f"{content_type}; charset=utf-8")
        self.end_headers()

    def do_OPTIONS(self):
        self._set_cors_headers(200)

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path
        query_params = dict(urllib.parse.parse_qsl(parsed.query))

        if path.startswith("/api/"):
            status_code, response_data = self.router.handle_request("GET", path, query_params=query_params)
            self._set_cors_headers(status_code, "application/json")
            self.wfile.write(json.dumps(response_data, ensure_ascii=False, indent=2).encode("utf-8"))
            return

        self._serve_static(path)

    def do_POST(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path
        query_params = dict(urllib.parse.parse_qsl(parsed.query))

        content_len = int(self.headers.get("Content-Length", 0))
        body = {}
        if content_len > 0:
            raw_body = self.rfile.read(content_len).decode("utf-8")
            try:
                body = json.loads(raw_body)
            except Exception:
                body = {"raw": raw_body}

        status_code, response_data = self.router.handle_request("POST", path, body=body, query_params=query_params)
        self._set_cors_headers(status_code, "application/json")
        self.wfile.write(json.dumps(response_data, ensure_ascii=False, indent=2).encode("utf-8"))

    def _serve_static(self, path: str):
        if path in ("/", ""):
            rel_path = os.path.join("demo", "index.html")
        else:
            rel_path = path.lstrip("/")

        full_path = os.path.abspath(os.path.join(self.static_dir, rel_path))
        if not full_path.startswith(self.static_dir) or not os.path.isfile(full_path):
            self._set_cors_headers(404, "text/plain")
            self.wfile.write(b"File not found")
            return

        content_type = "text/plain"
        if full_path.endswith(".html"):
            content_type = "text/html"
        elif full_path.endswith(".js"):
            content_type = "application/javascript"
        elif full_path.endswith(".css"):
            content_type = "text/css"
        elif full_path.endswith(".json"):
            content_type = "application/json"
        elif full_path.endswith(".svg"):
            content_type = "image/svg+xml"
        elif full_path.endswith(".png"):
            content_type = "image/png"

        try:
            with open(full_path, "rb") as f:
                content = f.read()
            self._set_cors_headers(200, content_type)
            self.wfile.write(content)
        except Exception as e:
            self._set_cors_headers(500, "text/plain")
            self.wfile.write(str(e).encode("utf-8"))

    def log_message(self, format, *args):
        pass


def create_server(host: str = "127.0.0.1", port: int = 8082, store: Optional[WorkerStore] = None) -> HTTPServer:
    ReliabilityHTTPRequestHandler.router = APIRouter(store or WorkerStore())
    server = HTTPServer((host, port), ReliabilityHTTPRequestHandler)
    return server


def run_server(host: str = "127.0.0.1", port: int = 8082):
    server = create_server(host, port)
    print("=========================================================")
    print(f"[WORKER RELIABILITY ENGINE] Server is RUNNING at:")
    print(f"URL: http://{host}:{port}/")
    print(f"Interactive Profile & Admin Dashboard: http://{host}:{port}/demo/index.html")
    print(f"Leaderboard API:                       http://{host}:{port}/api/workers/leaderboard")
    print(f"Admin Quality Summary:                 http://{host}:{port}/api/admin/quality-summary")
    print("=========================================================")
    print("Press Ctrl+C to stop the server.\n")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nStopping server...")
        server.server_close()


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="Worker Reliability Standalone Server")
    parser.add_argument("--host", default="127.0.0.1", help="Host address")
    parser.add_argument("--port", type=int, default=8082, help="Port number")
    args = parser.parse_args()
    run_server(args.host, args.port)
