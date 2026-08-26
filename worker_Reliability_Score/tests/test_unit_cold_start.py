"""
Unit tests for Cold-Start Prior and new worker trust baseline.
"""

import time
import pytest
from gig_worker_reliability.core.engine import ReliabilityEngine
from gig_worker_reliability.core.types import JobRecord, JobStatus, ReliabilityTier


@pytest.fixture
def engine():
    return ReliabilityEngine()


def test_zero_jobs_receives_cold_start_prior(engine):
    report = engine.compute_reliability("WRK-NEWBIE", [])
    assert report.is_cold_start is True
    assert 80 <= report.overall_score <= 85
    assert report.tier in (ReliabilityTier.DEPENDABLE, ReliabilityTier.STANDARD)
    assert "🌱 Verified New Partner" in report.badges
    assert report.total_jobs_evaluated == 0


def test_cold_start_smoothing_with_two_jobs(engine):
    now = time.time()
    two_jobs = [
        JobRecord("JB-1", "WRK-NEW2", "cleaning", now - 3600, now - 3600, True, 20.0, JobStatus.COMPLETED, 5.0, "Great!", True, True, True, now - 3600),
        JobRecord("JB-2", "WRK-NEW2", "cleaning", now, now, True, 22.0, JobStatus.COMPLETED, 4.8, "Punctual", False, True, True, now),
    ]

    report = engine.compute_reliability("WRK-NEW2", two_jobs, now)
    assert report.is_cold_start is True
    assert report.total_jobs_evaluated == 2
    assert report.overall_score >= 82
    assert "🌱 Verified New Partner" in report.badges
