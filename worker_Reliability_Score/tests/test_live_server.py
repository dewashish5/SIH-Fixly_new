"""
Live HTTP Server and Socket Integration Tests for Worker Reliability.
"""

import threading
import time
import urllib.request
import json
import pytest
from gig_worker_reliability.api.server import create_server


@pytest.fixture(scope="module")
def live_server():
    server = create_server(host="127.0.0.1", port=8877)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    time.sleep(0.3)
    yield "http://127.0.0.1:8877"
    server.shutdown()
    server.server_close()


def test_live_health_endpoint(live_server):
    req = urllib.request.Request(f"{live_server}/api/health")
    with urllib.request.urlopen(req) as resp:
        assert resp.status == 200
        data = json.loads(resp.read().decode("utf-8"))
        assert data["status"] == "healthy"


def test_live_worker_score_endpoint(live_server):
    req = urllib.request.Request(f"{live_server}/api/worker/WRK-1001/score")
    with urllib.request.urlopen(req) as resp:
        assert resp.status == 200
        data = json.loads(resp.read().decode("utf-8"))
        assert data["worker_id"] == "WRK-1001"
        assert data["reliability_report"]["overall_score"] >= 90


def test_live_static_demo_page(live_server):
    req = urllib.request.Request(f"{live_server}/demo/index.html")
    with urllib.request.urlopen(req) as resp:
        assert resp.status == 200
        content = resp.read().decode("utf-8")
        assert "Worker Reliability Score System" in content
