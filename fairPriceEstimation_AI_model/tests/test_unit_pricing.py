"""
Unit tests for core pricing calculations and component scaling.
"""

import pytest
from gig_fair_pricing.core.engine import FairPriceEngine
from gig_fair_pricing.core.types import PriceEstimationRequest, UrgencyLevel, DemandLevel


@pytest.fixture
def engine():
    return FairPriceEngine()


def test_standard_plumbing_base_price(engine):
    req = PriceEstimationRequest(
        service_category="plumbing",
        sub_service="tap_and_pipe_repair",
        location_pincode="560001",
        urgency=UrgencyLevel.STANDARD,
        distance_km=2.0,
        scheduled_hour=14,
        is_weekend=False,
    )
    resp = engine.estimate_price(req)
    assert resp.service_category == "plumbing"
    assert resp.sub_service == "tap_and_pipe_repair"
    assert resp.estimated_price >= 249.0
    assert resp.breakdown.base_service_price == 249.0
    assert resp.urgency_multiplier == 1.0
    assert resp.breakdown.urgency_surcharge == 0.0


def test_emergency_sos_surcharge(engine):
    req_std = PriceEstimationRequest(
        service_category="electrical",
        sub_service="fan_and_switch_repair",
        urgency=UrgencyLevel.STANDARD,
        distance_km=2.0,
        scheduled_hour=14,
    )
    resp_std = engine.estimate_price(req_std)

    req_sos = PriceEstimationRequest(
        service_category="electrical",
        sub_service="fan_and_switch_repair",
        urgency=UrgencyLevel.EMERGENCY,
        distance_km=2.0,
        scheduled_hour=14,
    )
    resp_sos = engine.estimate_price(req_sos)

    # Emergency SOS must have higher multiplier and flat dispatch fee
    assert resp_sos.urgency_multiplier > resp_std.urgency_multiplier
    assert resp_sos.breakdown.urgency_surcharge >= 100.0
    assert resp_sos.estimated_price > resp_std.estimated_price


def test_priority_vs_standard_price(engine):
    req_std = PriceEstimationRequest(service_category="ac_repair", urgency=UrgencyLevel.STANDARD, distance_km=2.0)
    req_prio = PriceEstimationRequest(service_category="ac_repair", urgency=UrgencyLevel.PRIORITY, distance_km=2.0)

    r_std = engine.estimate_price(req_std)
    r_prio = engine.estimate_price(req_prio)

    assert r_prio.estimated_price > r_std.estimated_price
    assert r_prio.breakdown.urgency_surcharge > 0


def test_distance_travel_fee_scaling(engine):
    req_near = PriceEstimationRequest(service_category="plumbing", distance_km=2.0)
    req_far = PriceEstimationRequest(service_category="plumbing", distance_km=8.5)

    r_near = engine.estimate_price(req_near)
    r_far = engine.estimate_price(req_far)

    assert r_near.breakdown.distance_travel_fee == 0.0
    assert r_far.breakdown.distance_travel_fee == (8.5 - 2.5) * 15.0
    assert r_far.estimated_price > r_near.estimated_price


def test_night_shift_fee_application(engine):
    req_day = PriceEstimationRequest(service_category="electrical", scheduled_hour=15, distance_km=2.0)
    req_night = PriceEstimationRequest(service_category="electrical", scheduled_hour=23, distance_km=2.0)

    r_day = engine.estimate_price(req_day)
    r_night = engine.estimate_price(req_night)

    assert r_night.breakdown.time_of_day_adjustment == 80.0
    assert r_night.estimated_price > r_day.estimated_price
