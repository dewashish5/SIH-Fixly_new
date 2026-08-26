"""
Performance and stress benchmarks for Fair Price Estimation.
"""

import time
import pytest
from gig_fair_pricing.core.engine import FairPriceEngine
from gig_fair_pricing.core.types import PriceEstimationRequest, UrgencyLevel


def test_single_request_latency():
    engine = FairPriceEngine()
    req = PriceEstimationRequest(service_category="plumbing", urgency=UrgencyLevel.EMERGENCY, distance_km=5.0)

    # Warmup
    _ = engine.estimate_price(req)

    # Benchmark 100 sequential inferences
    start = time.perf_counter()
    for _ in range(100):
        _ = engine.estimate_price(req)
    elapsed = time.perf_counter() - start

    avg_ms = (elapsed / 100.0) * 1000.0
    print(f"Average single estimation latency: {avg_ms:.3f} ms")
    assert avg_ms < 5.0  # Must be sub-5ms


def test_concurrent_batch_throughput():
    engine = FairPriceEngine()
    requests = [
        PriceEstimationRequest(
            service_category="electrical",
            urgency=UrgencyLevel.STANDARD if i % 2 == 0 else UrgencyLevel.EMERGENCY,
            distance_km=float((i % 10) + 1),
            scheduled_hour=(i % 24),
        )
        for i in range(500)
    ]

    start = time.perf_counter()
    responses = engine.batch_estimate(requests)
    elapsed = time.perf_counter() - start

    assert len(responses) == 500
    print(f"500 batch estimations processed in {elapsed:.3f} s (throughput: {500/elapsed:.1f} req/s)")
    assert elapsed < 1.0  # 500 requests must take under 1 second
