"""
Unit tests for Worker Reliability formula, component weights, and badges.
"""

import time
import pytest
from gig_worker_reliability.core.engine import ReliabilityEngine
from gig_worker_reliability.core.types import JobRecord, JobStatus, ReliabilityTier


@pytest.fixture
def engine():
    return ReliabilityEngine()


def test_perfect_worker_scoring(engine):
    now = time.time()
    jobs = [
        JobRecord(
            job_id=f"JB-{i}",
            worker_id="WRK-PERFECT",
            service_category="electrical",
            scheduled_timestamp=now - i * 3600,
            arrival_timestamp=now - i * 3600,
            is_on_time=True,
            response_time_seconds=15.0,
            status=JobStatus.COMPLETED,
            customer_rating=5.0,
            tip_received=True,
            created_at=now - i * 3600,
        )
        for i in range(12)
    ]

    report = engine.compute_reliability("WRK-PERFECT", jobs, now)
    assert report.overall_score >= 98
    assert report.tier == ReliabilityTier.ELITE
    assert report.sub_scores.on_time_arrival_rate == 100.0
    assert report.sub_scores.job_completion_rate == 100.0
    assert report.sub_scores.customer_feedback_score == 100.0
    assert report.sub_scores.cancellation_resistance == 100.0
    assert report.sub_scores.response_time_score == 100.0
    assert report.streak_bonus > 0


def test_late_cancellation_penalty(engine):
    now = time.time()
    # 5 good jobs + 1 late cancellation
    jobs = [
        JobRecord(f"JB-{i}", "WRK-CANCEL", "plumbing", now - i*3600, now - i*3600, True, 20.0, JobStatus.COMPLETED, 5.0, "", False, True, True, now - i*3600)
        for i in range(5)
    ]
    report_before = engine.compute_reliability("WRK-CANCEL", jobs, now)

    # Add late cancellation
    jobs.append(JobRecord("JB-LATE-CANCEL", "WRK-CANCEL", "plumbing", now, None, False, 20.0, JobStatus.WORKER_CANCELED_LATE, None, "", False, False, False, now))
    report_after = engine.compute_reliability("WRK-CANCEL", jobs, now)

    assert report_after.overall_score < report_before.overall_score
    assert report_after.sub_scores.cancellation_resistance < report_before.sub_scores.cancellation_resistance


def test_summary_string_format(engine):
    now = time.time()
    jobs = [
        JobRecord(f"JB-{i}", "WRK-FORMAT", "cleaning", now - i*3600, now - i*3600, True, 25.0, JobStatus.COMPLETED, 4.5, "", False, True, True, now - i*3600)
        for i in range(10)
    ]
    report = engine.compute_reliability("WRK-FORMAT", jobs, now)
    summary = report.summary_text

    # Expected format: "XX/100 - On-time XX%, Completion XX%, Feedback XX%, Cancellation XX%, Response time XX%"
    assert "/100 - " in summary
    assert "On-time" in summary
    assert "Completion" in summary
    assert "Feedback" in summary
    assert "Cancellation" in summary
    assert "Response time" in summary


def test_tier_classification():
    assert ReliabilityTier.from_score(95) == ReliabilityTier.ELITE
    assert ReliabilityTier.from_score(85) == ReliabilityTier.DEPENDABLE
    assert ReliabilityTier.from_score(75) == ReliabilityTier.STANDARD
    assert ReliabilityTier.from_score(65) == ReliabilityTier.ATTENTION_NEEDED
    assert ReliabilityTier.from_score(45) == ReliabilityTier.PROBATION
