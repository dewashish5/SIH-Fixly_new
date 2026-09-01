"""
Integration tests for Fair Pricing REST API endpoints.
"""

import pytest
from gig_fair_pricing.api.routes import APIRouter
from gig_fair_pricing.core.engine import FairPriceEngine


@pytest.fixture
def router():
    return APIRouter(FairPriceEngine())


def test_api_health(router):
    status, body = router.handle_request("GET", "/api/health")
    assert status == 200
    assert body["status"] == "healthy"
    assert body["service"] == "gig_fair_pricing"


def test_api_get_services(router):
    status, body = router.handle_request("GET", "/api/services")
    assert status == 200
    assert "services" in body
    assert "plumbing" in body["services"]


def test_api_estimate_price_success(router):
    payload = {
        "service_category": "plumbing",
        "sub_service": "tap_and_pipe_repair",
        "location_pincode": "560038",
        "urgency": "emergency",
        "distance_km": 4.0,
    }
    status, body = router.handle_request("POST", "/api/estimate-price", body=payload)
    assert status == 200
    assert "estimated_price" in body
    assert body["estimated_price"] > 0
    assert body["urgency_level"] == "emergency"
    assert "price_range" in body
    assert "breakdown" in body
    assert body["currency"] == "INR"


def test_api_estimate_price_missing_field(router):
    status, body = router.handle_request("POST", "/api/estimate-price", body={})
    assert status == 400
    assert "error" in body


def test_api_batch_estimate(router):
    payload = {
        "estimates": [
            {"service_category": "plumbing", "urgency": "standard"},
            {"service_category": "electrical", "urgency": "emergency"},
        ]
    }
    status, body = router.handle_request("POST", "/api/batch-estimate", body=payload)
    assert status == 200
    assert body["count"] == 2
    assert len(body["estimates"]) == 2


def test_api_demand_index(router):
    status, body = router.handle_request("GET", "/api/demand-index", query_params={"pincode": "560038", "hour": "18"})
    assert status == 200
    assert "demand_multiplier" in body
    assert body["demand_multiplier"] >= 0.90
