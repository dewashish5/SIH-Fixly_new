"""
Integration tests for Worker Reliability REST API endpoints.
"""

import pytest
from gig_worker_reliability.api.routes import APIRouter
from gig_worker_reliability.data.worker_store import WorkerStore


@pytest.fixture
def router():
    return APIRouter(WorkerStore())


def test_api_health(router):
    status, body = router.handle_request("GET", "/api/health")
    assert status == 200
    assert body["status"] == "healthy"
    assert body["service"] == "gig_worker_reliability"


def test_api_get_worker_score_success(router):
    status, body = router.handle_request("GET", "/api/worker/WRK-1001/score")
    assert status == 200
    assert body["worker_id"] == "WRK-1001"
    assert "reliability_report" in body
    report = body["reliability_report"]
    assert report["overall_score"] >= 90
    assert report["tier"] == "elite"
    assert "summary_text" in report


def test_api_get_worker_score_not_found(router):
    status, body = router.handle_request("GET", "/api/worker/NON-EXISTENT/score")
    assert status == 404
    assert "error" in body


def test_api_post_job_event(router):
    payload = {
        "worker_id": "WRK-1004",
        "service_category": "plumbing",
        "status": "completed",
        "is_on_time": True,
        "customer_rating": 5.0,
        "response_time_seconds": 16.0,
    }
    status, body = router.handle_request("POST", "/api/job/event", body=payload)
    assert status == 201
    assert body["success"] is True
    assert "new_reliability_report" in body
    assert body["new_reliability_report"]["overall_score"] > 0


def test_api_workers_leaderboard(router):
    status, body = router.handle_request("GET", "/api/workers/leaderboard", query_params={"limit": "3"})
    assert status == 200
    assert "leaderboard" in body
    assert len(body["leaderboard"]) == 3
    assert body["leaderboard"][0]["reliability_report"]["overall_score"] >= body["leaderboard"][1]["reliability_report"]["overall_score"]


def test_api_admin_quality_summary(router):
    status, body = router.handle_request("GET", "/api/admin/quality-summary")
    assert status == 200
    assert "total_registered_workers" in body
    assert "average_reliability_score" in body
    assert "tier_distribution" in body
