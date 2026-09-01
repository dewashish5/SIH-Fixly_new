"""
Unit and integration tests for core pricing calculations, city tiers, and component scaling.
"""

import pytest
from gig_fair_pricing.core.constants import (
    calculate_baseline_price,
    CITY_TIER_MULTIPLIERS,
    GOVT_MIN_WAGE_BY_TIER,
)
from gig_fair_pricing.core.engine import FairPriceEngine
from gig_fair_pricing.core.types import (
    PriceEstimationRequest,
    UrgencyLevel,
    DemandLevel,
)
from gig_fair_pricing.data.demand_zones import get_city_tier_multiplier


@pytest.fixture
def engine():
    return FairPriceEngine()


def test_city_tier_multipliers():
    # Metro X
    mult_x, tier_x, _ = get_city_tier_multiplier("560038")  # Bengaluru
    assert mult_x == 1.30
    assert tier_x == "X"

    mult_delhi, tier_delhi, _ = get_city_tier_multiplier("110001")  # Delhi
    assert mult_delhi == 1.30
    assert tier_delhi == "X"

    # Large City Y
    mult_y, tier_y, _ = get_city_tier_multiplier("302001")  # Jaipur
    assert mult_y == 1.15
    assert tier_y == "Y"

    # Standard Z (Unmapped or default)
    mult_z, tier_z, _ = get_city_tier_multiplier("175001")  # Small town
    assert mult_z == 1.00
    assert tier_z == "Z"

    # Missing or empty pincode falls back safely to Z
    mult_none, tier_none, _ = get_city_tier_multiplier(None)
    assert mult_none == 1.00
    assert tier_none == "Z"

    mult_empty, tier_empty, _ = get_city_tier_multiplier("")
    assert mult_empty == 1.00
    assert tier_empty == "Z"


def test_city_tier_connected_to_final_pricing_engine(engine):
    """
    Test that the actual pricing engine produces different final prices
    for different city tiers with all other inputs identical.
    """
    req_x = PriceEstimationRequest(
        service_category="electrical",
        sub_service="mcb_and_short_circuit_fix",
        location_pincode="560001",  # Bengaluru (X-tier: 1.30x)
        urgency=UrgencyLevel.STANDARD,
        distance_km=2.0,
        scheduled_hour=14,
        is_weekend=False,
    )
    req_y = PriceEstimationRequest(
        service_category="electrical",
        sub_service="mcb_and_short_circuit_fix",
        location_pincode="302001",  # Jaipur (Y-tier: 1.15x)
        urgency=UrgencyLevel.STANDARD,
        distance_km=2.0,
        scheduled_hour=14,
        is_weekend=False,
    )
    req_z = PriceEstimationRequest(
        service_category="electrical",
        sub_service="mcb_and_short_circuit_fix",
        location_pincode="175001",  # Unmapped town (Z-tier: 1.00x)
        urgency=UrgencyLevel.STANDARD,
        distance_km=2.0,
        scheduled_hour=14,
        is_weekend=False,
    )

    resp_x = engine.estimate_price(req_x)
    resp_y = engine.estimate_price(req_y)
    resp_z = engine.estimate_price(req_z)

    # Base rate for MCB repair is ₹252.00
    # X (1.30x) > Y (1.15x) > Z (1.00x)
    assert resp_x.estimated_price > resp_y.estimated_price > resp_z.estimated_price
    assert resp_x.breakdown.city_tier == "X"
    assert resp_x.breakdown.city_multiplier == 1.30
    assert resp_y.breakdown.city_tier == "Y"
    assert resp_y.breakdown.city_multiplier == 1.15
    assert resp_z.breakdown.city_tier == "Z"
    assert resp_z.breakdown.city_multiplier == 1.00


def test_demand_multiplier_independent_from_city_tier(engine):
    """Verify dynamic demand operates independently from structural city tier."""
    req_low = PriceEstimationRequest(
        service_category="plumbing",
        sub_service="tap_and_pipe_repair",
        location_pincode="560038",  # X tier
        custom_demand_override=0.95,
        distance_km=2.0,
    )
    req_high = PriceEstimationRequest(
        service_category="plumbing",
        sub_service="tap_and_pipe_repair",
        location_pincode="560038",  # Same X tier
        custom_demand_override=1.40,
        distance_km=2.0,
    )

    resp_low = engine.estimate_price(req_low)
    resp_high = engine.estimate_price(req_high)

    assert resp_low.breakdown.city_multiplier == resp_high.breakdown.city_multiplier == 1.30
    assert resp_high.demand_multiplier > resp_low.demand_multiplier
    assert resp_high.estimated_price > resp_low.estimated_price


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

    assert resp_sos.urgency_multiplier == 1.35
    assert resp_sos.breakdown.urgency_surcharge >= 100.0
    assert resp_sos.estimated_price > resp_std.estimated_price


def test_priority_vs_standard_price(engine):
    req_std = PriceEstimationRequest(
        service_category="ac_repair", urgency=UrgencyLevel.STANDARD, distance_km=2.0
    )
    req_prio = PriceEstimationRequest(
        service_category="ac_repair", urgency=UrgencyLevel.PRIORITY, distance_km=2.0
    )

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
    req_day = PriceEstimationRequest(
        service_category="electrical", scheduled_hour=15, distance_km=2.0
    )
    req_night = PriceEstimationRequest(
        service_category="electrical", scheduled_hour=23, distance_km=2.0
    )

    r_day = engine.estimate_price(req_day)
    r_night = engine.estimate_price(req_night)

    assert r_night.breakdown.time_of_day_adjustment == 80.0
    assert r_night.estimated_price > r_day.estimated_price


def test_invalid_skill_tier_fails_gracefully(engine):
    with pytest.raises(ValueError, match="Invalid skill tier"):
        calculate_baseline_price("invalid_level", 60)
