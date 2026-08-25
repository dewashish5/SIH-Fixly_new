"""
Unit tests for fairness constraints, surge limits, and wage floor protections.
"""

import pytest
from gig_fair_pricing.core.engine import FairPriceEngine
from gig_fair_pricing.core.types import PriceEstimationRequest, UrgencyLevel


@pytest.fixture
def engine():
    return FairPriceEngine()


def test_anti_price_gouging_cap_on_extreme_demand(engine):
    # Pass an extreme 2.5x custom demand surge
    req = PriceEstimationRequest(
        service_category="plumbing",
        sub_service="tap_and_pipe_repair",
        custom_demand_override=2.50,
        urgency=UrgencyLevel.STANDARD,
        distance_km=2.0,
    )
    resp = engine.estimate_price(req)

    # Engine must enforce maximum 1.60x cap
    assert resp.demand_multiplier <= 1.60
    assert resp.fairness_compliance["anti_gouging_applied"] is True
    assert any("Anti-price-gouging" in note for note in resp.explainability_notes)


def test_worker_minimum_living_wage_floor(engine):
    # Test service with low rate but longer duration
    req = PriceEstimationRequest(
        service_category="cleaning",
        sub_service="bathroom_deep_cleaning",
        custom_demand_override=0.85,
        distance_km=2.0,
    )
    resp = engine.estimate_price(req)

    # Worker minimum living wage floor (₹200/hr)
    assert resp.breakdown.worker_payout_guarantee >= 200.0 * (60.0 / 60.0)


def test_price_range_symmetric_bounds(engine):
    req = PriceEstimationRequest(service_category="appliance_repair", sub_service="washing_machine_repair")
    resp = engine.estimate_price(req)

    assert resp.price_range_min <= resp.estimated_price
    assert resp.estimated_price <= resp.price_range_max
    assert resp.price_range_max > resp.price_range_min


def test_breakdown_arithmetic_consistency(engine):
    req = PriceEstimationRequest(
        service_category="painting",
        sub_service="single_room_repaint",
        urgency=UrgencyLevel.EMERGENCY,
        distance_km=6.0,
        scheduled_hour=23,
    )
    resp = engine.estimate_price(req)
    b = resp.breakdown

    # Platform fee + Worker payout == Gross Total
    assert round(b.worker_payout_guarantee + b.platform_fee, 2) == round(b.gross_total, 2)
