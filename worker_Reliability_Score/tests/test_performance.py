"""
Performance and stress benchmarks for Worker Reliability Engine.
"""

import time
import pytest
from gig_worker_reliability.core.engine import ReliabilityEngine
from gig_worker_reliability.core.types import JobRecord, JobStatus


def test_single_worker_score_latency():
    engine = ReliabilityEngine()
    now = time.time()
    jobs = [
        JobRecord(f"JB-{i}", "WRK-PERF", "electrical", now - i*3600, now - i*3600, True, 20.0, JobStatus.COMPLETED, 5.0, "", False, True, True, now - i*3600)
        for i in range(50)
    ]

    # Warmup
    _ = engine.compute_reliability("WRK-PERF", jobs, now)

    # 100 iterations
    start = time.perf_counter()
    for _ in range(100):
        _ = engine.compute_reliability("WRK-PERF", jobs, now)
    elapsed = time.perf_counter() - start

    avg_ms = (elapsed / 100.0) * 1000.0
    print(f"Average single worker reliability calculation latency: {avg_ms:.3f} ms")
    assert avg_ms < 2.0  # Must be sub-2ms per 50-job evaluation


def test_batch_event_throughput():
    engine = ReliabilityEngine()
    now = time.time()

    start = time.perf_counter()
    for i in range(500):
        jobs = [
            JobRecord(f"JB-{j}", f"WRK-{i}", "plumbing", now - j*3600, now - j*3600, True, 20.0, JobStatus.COMPLETED, 5.0, "", False, True, True, now - j*3600)
            for j in range(10)
        ]
        _ = engine.compute_reliability(f"WRK-{i}", jobs, now)
    elapsed = time.perf_counter() - start

    print(f"500 worker score calculations completed in {elapsed:.3f} s (throughput: {500/elapsed:.1f} workers/s)")
    assert elapsed < 1.0
