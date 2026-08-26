"""
Unit tests for Bayesian exponential time decay and recency weighting.
"""

import time
import pytest
from gig_worker_reliability.core.engine import ReliabilityEngine
from gig_worker_reliability.core.types import JobRecord, JobStatus


@pytest.fixture
def engine():
    return ReliabilityEngine(half_life_days=30.0)


def test_recent_jobs_dominate_decay(engine):
    now = time.time()
    day = 86400.0

    # Worker had 5 bad jobs 60 days ago (2 half-lives ago)
    old_bad_jobs = [
        JobRecord(f"JB-OLD-{i}", "WRK-RECOVERY", "plumbing", now - 60 * day, now - 60 * day, False, 70.0, JobStatus.COMPLETED, 2.5, "Late", False, True, True, now - 60 * day)
        for i in range(5)
    ]

    # Worker has 10 recent perfect 5-star jobs in the last 5 days
    recent_good_jobs = [
        JobRecord(f"JB-REC-{i}", "WRK-RECOVERY", "plumbing", now - i * day, now - i * day, True, 18.0, JobStatus.COMPLETED, 5.0, "Excellent!", True, True, True, now - i * day)
        for i in range(10)
    ]

    combined = old_bad_jobs + recent_good_jobs
    report = engine.compute_reliability("WRK-RECOVERY", combined, now)

    # Score should reflect recent excellence (>88) rather than an unweighted average
    assert report.overall_score >= 88
    assert report.sub_scores.on_time_arrival_rate >= 85.0
    assert report.sub_scores.customer_feedback_score >= 85.0
