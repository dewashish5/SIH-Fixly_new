"""
Integration journey tests for worker score lifecycle and promotion/demotion flows.
"""

import time
import pytest
from gig_worker_reliability.core.engine import ReliabilityEngine
from gig_worker_reliability.data.worker_store import WorkerStore
from gig_worker_reliability.core.types import JobRecord, JobStatus, ReliabilityTier


def test_worker_promotion_lifecycle():
    store = WorkerStore()
    now = time.time()
    worker_id = "WRK-NEW-LIFECYCLE"

    # Initially 0 jobs -> Cold start (Tier ~82)
    w = store.get_worker(worker_id)
    assert w is None

    # Step 1: Worker completes 5 perfect jobs in a row
    for i in range(5):
        job = JobRecord(
            job_id=f"JB-LIFE-{i}",
            worker_id=worker_id,
            service_category="electrical",
            scheduled_timestamp=now - (5 - i) * 3600,
            arrival_timestamp=now - (5 - i) * 3600,
            is_on_time=True,
            response_time_seconds=15.0,
            status=JobStatus.COMPLETED,
            customer_rating=5.0,
            tip_received=True,
            created_at=now - (5 - i) * 3600,
        )
        report = store.record_job_event(job)

    # Worker has graduated from cold start with perfect ratings -> Promoted to Elite
    assert report.is_cold_start is False
    assert report.overall_score >= 90
    assert report.tier == ReliabilityTier.ELITE
    assert "⭐ Top Rated Partner" in report.badges
