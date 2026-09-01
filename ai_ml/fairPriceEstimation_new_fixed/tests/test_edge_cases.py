"""
Comprehensive Edge-Case, Input Validation, Matrix, and Invariant Tests for FairPrice AI.
"""

import math
import pytest
from gig_fair_pricing.core.constants import (
    calculate_baseline_price,
    CITY_TIER_MULTIPLIERS,
    GOVT_MIN_WAGE_BY_TIER,
    PLATFORM_COMMISSION_RATE,
    WORKER_SHARE_RATE,
)
from gig_fair_pricing.core.engine import FairPriceEngine
from gig_fair_pricing.core.types import (
    PriceEstimationRequest,
    ServiceSpec,
    UrgencyLevel,
)
from gig_fair_pricing.data.catalog import CATALOG
from gig_fair_pricing.api.routes import APIRouter
from gig_fair_pricing.ml.model import MLPriceModel, FEATURE_COLUMNS


@pytest.fixture
def engine():
    return FairPriceEngine()


@pytest.fixture
def router(engine):
    return APIRouter(engine)


# ---------------------------------------------------------------------------
# 1. INPUT VALIDATION EDGE CASES
# ---------------------------------------------------------------------------
def test_missing_and_malformed_pincodes_fallback_safely(engine):
    for bad_pin in [None, "", "   ", "000000", "XYZ999", "12"]:
        req = PriceEstimationRequest(
            service_category="plumbing",
            sub_service="tap_and_pipe_repair",
            location_pincode=bad_pin,
        )
        resp = engine.estimate_price(req)
        assert resp.breakdown.city_tier == "Z"
        assert resp.breakdown.city_multiplier == 1.00
        assert resp.estimated_price > 0


def test_missing_service_category_api_error(router):
    status, body = router.handle_request("POST", "/api/estimate-price", body={})
    assert status == 400
    assert "error" in body
    assert "service_category" in body["error"]
    assert "allowed_categories" in body


def test_invalid_distance_api_error(router):
    status, body = router.handle_request(
        "POST",
        "/api/estimate-price",
        body={"service_category": "plumbing", "distance_km": -5.0},
    )
    assert status == 400
    assert "error" in body
    assert "cannot be negative" in body["error"]


def test_invalid_scheduled_hour_api_error(router):
    status, body = router.handle_request(
        "POST",
        "/api/estimate-price",
        body={"service_category": "plumbing", "scheduled_hour": 25},
    )
    assert status == 400
    assert "error" in body
    assert "between 0 and 23" in body["error"]


def test_invalid_skill_tier_in_formula():
    with pytest.raises(ValueError, match="Invalid skill tier"):
        calculate_baseline_price("ultra_master", 60)


def test_invalid_duration_in_formula():
    with pytest.raises(ValueError, match="Duration must be greater than 0"):
        calculate_baseline_price("standard", -30)
    with pytest.raises(ValueError, match="Duration must be greater than 0"):
        calculate_baseline_price("standard", 0)


# ---------------------------------------------------------------------------
# 2. PRICING & SURGE EDGE CASES
# ---------------------------------------------------------------------------
def test_extreme_surge_multiplier_capped_at_1_60x(engine):
    req = PriceEstimationRequest(
        service_category="electrical",
        sub_service="fan_and_switch_repair",
        custom_demand_override=3.0,
        distance_km=2.0,
    )
    resp = engine.estimate_price(req)
    assert resp.demand_multiplier <= 1.60
    assert resp.fairness_compliance["anti_gouging_applied"] is True


def test_city_x_with_high_demand_and_emergency(engine):
    req = PriceEstimationRequest(
        service_category="electrical",
        sub_service="full_house_wiring_inspection",
        location_pincode="560038",
        urgency=UrgencyLevel.EMERGENCY,
        distance_km=10.0,
        scheduled_hour=23,
        custom_demand_override=1.40,
    )
    resp = engine.estimate_price(req)
    assert resp.estimated_price > 0
    assert resp.breakdown.city_multiplier == 1.30
    assert resp.breakdown.urgency_surcharge >= 100.0
    assert resp.breakdown.time_of_day_adjustment == 80.0
    assert resp.breakdown.distance_travel_fee == (10.0 - 2.5) * 15.0
    b = resp.breakdown
    assert round(b.worker_payout_guarantee + b.platform_fee, 2) == round(b.gross_total, 2)


def test_long_distance_travel_scaling(engine):
    req_local = PriceEstimationRequest(service_category="plumbing", distance_km=2.0)
    req_far = PriceEstimationRequest(service_category="plumbing", distance_km=15.0)

    r_local = engine.estimate_price(req_local)
    r_far = engine.estimate_price(req_far)

    assert r_local.breakdown.distance_travel_fee == 0.0
    assert r_far.breakdown.distance_travel_fee == (15.0 - 2.5) * 15.0
    assert r_far.estimated_price > r_local.estimated_price


# ---------------------------------------------------------------------------
# 3. ACCOUNTING INVARIANTS & INTEGRITY (Phase 3 Audit)
# ---------------------------------------------------------------------------
def test_accounting_invariant_all_catalog_services(engine):
    """
    Verify the fundamental accounting invariant:
    Customer Gross Total = Worker Payout (85%) + Platform Commission (15%)
    across all 15 services under standard, priority, and emergency modes.
    """
    for category, specs in CATALOG.items():
        for spec in specs:
            for urg in [UrgencyLevel.STANDARD, UrgencyLevel.PRIORITY, UrgencyLevel.EMERGENCY]:
                req = PriceEstimationRequest(
                    service_category=category,
                    sub_service=spec.sub_service,
                    location_pincode="560038",
                    urgency=urg,
                    distance_km=3.0,
                )
                resp = engine.estimate_price(req)
                b = resp.breakdown

                # Invariant 1: Sum of splits equals gross total (within 0.01 tolerance)
                assert abs(b.gross_total - (b.worker_payout_guarantee + b.platform_fee)) < 0.01

                # Invariant 2: Exact mathematical splits
                expected_platform = round(b.gross_total * PLATFORM_COMMISSION_RATE, 2)
                expected_worker = round(b.gross_total * WORKER_SHARE_RATE, 2)
                assert b.platform_fee == expected_platform
                assert b.worker_payout_guarantee == expected_worker


# ---------------------------------------------------------------------------
# 4. CITY × DEMAND INDEPENDENCE MATRIX (Phase 6 Audit)
# ---------------------------------------------------------------------------
def test_city_tier_and_demand_independence_matrix(engine):
    """
    Verify complete 3x2 Matrix:
    City Tiers (Z: 1.00x, Y: 1.15x, X: 1.30x) x Demand Levels (Normal: 1.00x, High: 1.35x)
    Proves that structural city cost and dynamic demand operate as independent factors.
    """
    pins = {"Z": "175001", "Y": "302001", "X": "560038"}
    matrix = {}

    for tier, pin in pins.items():
        for demand_mode, demand_val in [("normal", 1.00), ("high", 1.35)]:
            req = PriceEstimationRequest(
                service_category="electrical",
                sub_service="mcb_and_short_circuit_fix",  # Base = 252.00
                location_pincode=pin,
                custom_demand_override=demand_val,
                urgency=UrgencyLevel.STANDARD,
                distance_km=2.0,
            )
            resp = engine.estimate_price(req)
            matrix[(tier, demand_mode)] = resp.estimated_price

    # 1. Structural scaling under normal demand: X > Y > Z
    assert matrix[("X", "normal")] > matrix[("Y", "normal")] > matrix[("Z", "normal")]

    # 2. Structural scaling under high demand: X > Y > Z
    assert matrix[("X", "high")] > matrix[("Y", "high")] > matrix[("Z", "high")]

    # 3. Dynamic demand effect within each tier: High > Normal
    assert matrix[("Z", "high")] > matrix[("Z", "normal")]
    assert matrix[("Y", "high")] > matrix[("Y", "normal")]
    assert matrix[("X", "high")] > matrix[("X", "normal")]


# ---------------------------------------------------------------------------
# 5. ANTI-GOUGING REFERENCE DEFINITION (Phase 7 Audit)
# ---------------------------------------------------------------------------
def test_anti_gouging_reference_base_definition(engine):
    """
    Verify that the 1.60x anti-gouging surge ceiling is calculated relative to
    the service's structural baseline rate.
    """
    req = PriceEstimationRequest(
        service_category="plumbing",
        sub_service="tap_and_pipe_repair",
        location_pincode="560038",  # X-Tier: Base = 171.53 * 1.30 = 222.99
        custom_demand_override=2.80,  # Extreme surge
        urgency=UrgencyLevel.STANDARD,
        distance_km=2.0,
    )
    resp = engine.estimate_price(req)
    meta = resp.fairness_compliance

    assert meta["anti_gouging_applied"] is True
    # Ceiling is 1.60 * 222.99 = 356.78
    assert resp.estimated_price <= meta["max_allowed_price"]
    assert meta["max_allowed_price"] == round(222.99 * 1.60, 2)


# ---------------------------------------------------------------------------
# 6. ML MODEL ROBUSTNESS & FALLBACK
# ---------------------------------------------------------------------------
def test_ml_model_feature_sanity():
    model = MLPriceModel()
    features = model.extract_features(
        base_rate=252.0,
        est_duration_mins=60,
        skill_tier="skilled",
        city_multiplier=1.15,
        demand_mult=1.0,
        urgency_mult=1.0,
        emergency_dispatch_fee=0.0,
        distance_km=3.0,
        hour=12,
        is_weekend=False,
    )
    assert len(features) == 12
    for val in features:
        assert not math.isnan(val) and not math.isinf(val)


def test_ml_model_prediction_never_nan_or_inf():
    model = MLPriceModel()
    features = [252.0, 60.0, 1.15, 1.30, 1.25, 1.35, 100.0, 5.0, 37.5, 23.0, 1.0, 80.0]
    pred, p_min, p_max, contrib = model.predict(features)
    assert not math.isnan(pred) and not math.isinf(pred)
    assert not math.isnan(p_min) and not math.isnan(p_max)
    assert pred > 0


# ---------------------------------------------------------------------------
# 7. DEMO SCENARIOS & COMPARISON API
# ---------------------------------------------------------------------------
def test_demo_scenarios_endpoint(router):
    status, body = router.handle_request("GET", "/api/demo-scenarios")
    assert status == 200
    assert body["count"] == 6
    assert len(body["scenarios"]) == 6

    scenario_ids = [s["id"] for s in body["scenarios"]]
    assert "scenario_a_standard_city" in scenario_ids
    assert "scenario_b_metro_city" in scenario_ids
    assert "scenario_c_high_demand" in scenario_ids
    assert "scenario_d_skilled_artisan" in scenario_ids
    assert "scenario_e_emergency_dispatch" in scenario_ids
    assert "scenario_f_worker_protection" in scenario_ids


def test_compare_pricing_endpoint(router):
    payload = {
        "service_category": "plumbing",
        "sub_service": "tap_and_pipe_repair",
        "location_pincode": "560038",
    }
    status, body = router.handle_request("POST", "/api/compare-pricing", body=payload)
    assert status == 200
    assert "traditional_model" in body
    assert "fairprice_ai" in body
    assert "comparison_summary" in body
    assert body["fairprice_ai"]["customer_price"] > 0
    assert body["traditional_model"]["customer_price"] == 249.0
