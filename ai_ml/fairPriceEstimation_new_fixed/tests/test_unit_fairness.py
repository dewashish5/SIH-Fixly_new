"""
Unit tests for fairness constraints, surge limits, tiered wage floors, and commission splits.
"""

import pytest
from gig_fair_pricing.core.constants import (
    GOVT_MIN_WAGE_BY_TIER,
    PLATFORM_COMMISSION_RATE,
    WORKER_SHARE_RATE,
)
from gig_fair_pricing.core.engine import FairPriceEngine
from gig_fair_pricing.core.fairness import FairnessValidator
from gig_fair_pricing.core.types import (
    PriceBreakdown,
    PriceEstimationRequest,
    ServiceSpec,
    UrgencyLevel,
)


@pytest.fixture
def engine():
    return FairPriceEngine()


@pytest.fixture
def validator():
    return FairnessValidator()


def test_anti_price_gouging_cap_on_extreme_demand(engine):
    req = PriceEstimationRequest(
        service_category="plumbing",
        sub_service="tap_and_pipe_repair",
        custom_demand_override=2.50,
        urgency=UrgencyLevel.STANDARD,
        distance_km=2.0,
    )
    resp = engine.estimate_price(req)

    # Engine must enforce maximum 1.60x surge cap
    assert resp.demand_multiplier <= 1.60
    assert resp.fairness_compliance["anti_gouging_applied"] is True
    assert any("Anti-price-gouging" in note for note in resp.explainability_notes)


def test_worker_tiered_living_wage_floors(validator):
    # Verify wage floor lookup for all three skill tiers
    assert validator.get_wage_floor_for_tier("standard") == 108.0
    assert validator.get_wage_floor_for_tier("skilled") == 119.0
    assert validator.get_wage_floor_for_tier("master") == 129.0

    with pytest.raises(ValueError):
        validator.get_wage_floor_for_tier("unknown_tier")


def test_wage_floor_protection_boost(validator):
    # Create a spec with artificially low price and long duration
    spec = ServiceSpec(
        category="cleaning",
        sub_service="budget_task",
        base_rate=50.0,
        unit="job",
        est_duration_mins=120,  # 2 hours: standard min floor = 2 * 108 = 216
        skill_tier="standard",
        min_price_floor=30.0,
        max_price_ceiling=300.0,
        description="Low cost test task",
    )
    breakdown = PriceBreakdown(
        base_service_price=50.0,
        demand_adjustment=0.0,
        urgency_surcharge=0.0,
        distance_travel_fee=0.0,
        time_of_day_adjustment=0.0,
        gross_total=50.0,
        worker_payout_guarantee=42.5,
        platform_fee=7.5,
        tax_estimate=2.5,
    )

    final_price, audited_bd, meta, notes = validator.validate_and_adjust(
        raw_estimated_price=50.0,
        spec=spec,
        breakdown=breakdown,
        urgency=UrgencyLevel.STANDARD,
    )

    # Minimum wage for 2 hrs standard is 216; with 15% commission, final price = 216 / 0.85 = 254.12
    assert meta["wage_floor_boosted"] is True
    assert audited_bd.worker_payout_guarantee >= 216.0
    assert round(final_price * 0.85, 2) >= 216.0


def test_skill_tier_changes_wage_floor(validator):
    duration_mins = 60
    wage_standard = validator.get_wage_floor_for_tier("standard") * (duration_mins / 60)
    wage_skilled = validator.get_wage_floor_for_tier("skilled") * (duration_mins / 60)
    wage_master = validator.get_wage_floor_for_tier("master") * (duration_mins / 60)

    assert wage_standard == 108.0
    assert wage_skilled == 119.0
    assert wage_master == 129.0
    assert wage_master > wage_skilled > wage_standard


def test_platform_commission_consistency(engine):
    req = PriceEstimationRequest(
        service_category="plumbing",
        sub_service="tap_and_pipe_repair",
        distance_km=3.0,
    )
    resp = engine.estimate_price(req)
    b = resp.breakdown

    expected_platform_fee = round(b.gross_total * PLATFORM_COMMISSION_RATE, 2)
    expected_worker_payout = round(b.gross_total - expected_platform_fee, 2)

    assert b.platform_fee == expected_platform_fee
    assert b.worker_payout_guarantee == expected_worker_payout
    assert round(b.platform_fee + b.worker_payout_guarantee, 2) == round(b.gross_total, 2)
    assert resp.fairness_compliance["platform_commission_rate"] == 0.15
    assert resp.fairness_compliance["worker_share_rate"] == 0.85


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

    assert round(b.worker_payout_guarantee + b.platform_fee, 2) == round(b.gross_total, 2)
