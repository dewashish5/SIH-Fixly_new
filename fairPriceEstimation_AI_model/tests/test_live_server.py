"""
Live HTTP Server and Socket Integration Tests for Fair Pricing.
"""

import threading
import time
import urllib.request
import json
import pytest
from gig_fair_pricing.api.server import create_server


@pytest.fixture(scope="module")
def live_server():
    server = create_server(host="127.0.0.1", port=8899)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    time.sleep(0.3)
    yield "http://127.0.0.1:8899"
    server.shutdown()
    server.server_close()


def test_live_health_endpoint(live_server):
    req = urllib.request.Request(f"{live_server}/api/health")
    with urllib.request.urlopen(req) as resp:
        assert resp.status == 200
        data = json.loads(resp.read().decode("utf-8"))
        assert data["status"] == "healthy"


def test_live_estimate_price_endpoint(live_server):
    payload = json.dumps({
        "service_category": "electrical",
        "sub_service": "fan_and_switch_repair",
        "urgency": "emergency",
        "distance_km": 3.0,
    }).encode("utf-8")

    req = urllib.request.Request(
        f"{live_server}/api/estimate-price",
        data=payload,
        headers={"Content-Type": "application/json"},
        method="POST"
    )
    with urllib.request.urlopen(req) as resp:
        assert resp.status == 200
        data = json.loads(resp.read().decode("utf-8"))
        assert data["estimated_price"] > 0
        assert data["urgency_level"] == "emergency"


def test_live_static_demo_page(live_server):
    req = urllib.request.Request(f"{live_server}/demo/index.html")
    with urllib.request.urlopen(req) as resp:
        assert resp.status == 200
        content = resp.read().decode("utf-8")
        assert "Fair Price Estimation" in content
