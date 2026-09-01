"""
Unit tests for service catalog specifications, programmatic formulas, and skill tiers.
"""

import pytest
from gig_fair_pricing.core.constants import (
    calculate_baseline_price,
    GOVT_MIN_WAGE_BY_TIER,
    PLATFORM_COMMISSION_RATE,
    WORKER_SHARE_RATE,
    FAIR_MARKUP_FACTOR,
)
from gig_fair_pricing.data.catalog import (
    CATALOG,
    get_all_categories,
    find_service_spec,
    get_service_specs,
)
from gig_fair_pricing.core.engine import FairPriceEngine
from gig_fair_pricing.core.types import PriceEstimationRequest


def test_catalog_has_all_core_categories():
    categories = get_all_categories()
    expected = [
        "plumbing",
        "electrical",
        "ac_repair",
        "cleaning",
        "appliance_repair",
        "carpentry",
        "painting",
        "pest_control",
    ]
    for exp in expected:
        assert exp in categories


def test_skill_tier_minimum_wages():
    assert GOVT_MIN_WAGE_BY_TIER["standard"] == 108.0
    assert GOVT_MIN_WAGE_BY_TIER["skilled"] == 119.0
    assert GOVT_MIN_WAGE_BY_TIER["master"] == 129.0


def test_commission_constants():
    assert PLATFORM_COMMISSION_RATE == 0.15
    assert WORKER_SHARE_RATE == 0.85
    assert FAIR_MARKUP_FACTOR == 1.8


def test_every_catalog_service_matches_programmatic_formula():
    """Verify that every single catalog baseline rate is traceable to the exact statutory formula."""
    for category, specs in CATALOG.items():
        for spec in specs:
            expected_price = calculate_baseline_price(
                skill_tier=spec.skill_tier,
                duration_mins=spec.est_duration_mins,
                markup_factor=FAIR_MARKUP_FACTOR,
                commission_rate=PLATFORM_COMMISSION_RATE,
            )
            assert spec.base_rate == expected_price
            assert spec.min_price_floor == round(expected_price * 0.80, 2)
            assert spec.max_price_ceiling == round(expected_price * 2.60, 2)
            assert spec.skill_tier in ("standard", "skilled", "master")


def test_specific_formula_calculations():
    # Tap repair: standard (108), 45 min (0.75h) -> 108 * 1.8 * 0.75 / 0.85 = 171.53
    tap_price = calculate_baseline_price("standard", 45)
    assert tap_price == 171.53

    # MCB repair: skilled (119), 60 min (1.0h) -> 119 * 1.8 * 1.0 / 0.85 = 252.00
    mcb_price = calculate_baseline_price("skilled", 60)
    assert mcb_price == 252.00

    # House wiring inspection: master (129), 120 min (2.0h) -> 129 * 1.8 * 2.0 / 0.85 = 546.35
    wiring_price = calculate_baseline_price("master", 120)
    assert wiring_price == 546.35


def test_formula_invalid_inputs():
    with pytest.raises(ValueError, match="Invalid skill tier"):
        calculate_baseline_price("invalid_tier", 60)

    with pytest.raises(ValueError, match="Duration must be greater than 0"):
        calculate_baseline_price("standard", 0)


def test_find_service_spec_fuzzy():
    spec1 = find_service_spec("plumbing", "tap_and_pipe_repair")
    assert spec1 is not None
    assert spec1.sub_service == "tap_and_pipe_repair"

    spec2 = find_service_spec("washing_machine_repair")
    assert spec2 is not None
    assert spec2.category == "appliance_repair"


def test_unknown_service_category_fallback():
    engine = FairPriceEngine()
    req = PriceEstimationRequest(
        service_category="custom_drone_cleaning", sub_service="window_task"
    )
    resp = engine.estimate_price(req)
    assert resp.estimated_price > 0
    assert resp.service_category == "custom_drone_cleaning"
    assert resp.breakdown.skill_tier == "standard"
