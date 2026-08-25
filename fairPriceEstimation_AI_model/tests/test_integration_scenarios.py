"""
End-to-End customer booking pricing scenarios across normal, surge, and emergency contexts.
"""

import pytest
from gig_fair_pricing.core.engine import FairPriceEngine
from gig_fair_pricing.core.types import PriceEstimationRequest, UrgencyLevel


@pytest.fixture
def engine():
    return FairPriceEngine()


def test_scenario_standard_afternoon_plumber(engine):
    # Customer books standard scheduled plumber on weekday afternoon
    req = PriceEstimationRequest(
        service_category="plumbing",
        sub_service="tap_and_pipe_repair",
        location_pincode="560038",
        urgency=UrgencyLevel.STANDARD,
        distance_km=2.0,
        scheduled_hour=15,
        is_weekend=False,
    )
    resp = engine.estimate_price(req)
    assert resp.urgency_level == "standard"
    assert resp.breakdown.urgency_surcharge == 0.0
    assert resp.breakdown.distance_travel_fee == 0.0
    assert 240.0 <= resp.estimated_price <= 350.0


def test_scenario_peak_evening_ac_repair(engine):
    # Customer books AC repair during hot summer weekend evening peak
    req = PriceEstimationRequest(
        service_category="ac_repair",
        sub_service="ac_filter_and_jet_servicing",
        location_pincode="560034",  # Koramangala high density
        urgency=UrgencyLevel.PRIORITY,
        distance_km=4.5,
        scheduled_hour=19,
        is_weekend=True,
    )
    resp = engine.estimate_price(req)
    assert resp.demand_multiplier >= 1.20
    assert resp.breakdown.urgency_surcharge > 0
    assert resp.breakdown.distance_travel_fee > 0
    assert resp.estimated_price > 499.0


def test_scenario_midnight_emergency_short_circuit(engine):
    # Customer suffers power outage at 11:30 PM and requests Emergency SOS dispatch
    req = PriceEstimationRequest(
        service_category="electrical",
        sub_service="mcb_and_short_circuit_fix",
        location_pincode="560100",
        urgency=UrgencyLevel.EMERGENCY,
        distance_km=5.0,
        scheduled_hour=23,
        is_weekend=False,
    )
    resp = engine.estimate_price(req)
    assert resp.urgency_level == "emergency"
    assert resp.breakdown.time_of_day_adjustment == 80.0
    assert resp.breakdown.urgency_surcharge >= 100.0
    assert resp.estimated_price >= 550.0
    assert len(resp.explainability_notes) >= 3
