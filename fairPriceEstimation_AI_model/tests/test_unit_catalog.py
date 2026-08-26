"""
Unit tests for service catalog specifications, sub-services, and skill tiers.
"""

import pytest
from gig_fair_pricing.data.catalog import CATALOG, get_all_categories, find_service_spec, get_service_specs
from gig_fair_pricing.core.engine import FairPriceEngine
from gig_fair_pricing.core.types import PriceEstimationRequest


def test_catalog_has_all_core_categories():
    categories = get_all_categories()
    expected = ["plumbing", "electrical", "ac_repair", "cleaning", "appliance_repair", "carpentry", "painting", "pest_control"]
    for exp in expected:
        assert exp in categories


def test_service_spec_properties():
    specs = get_service_specs("plumbing")
    assert len(specs) >= 2
    for s in specs:
        assert s.base_rate > 0
        assert s.min_price_floor > 0
        assert s.max_price_ceiling > s.min_price_floor
        assert s.est_duration_mins > 0
        assert s.skill_tier in ("standard", "skilled", "master")


def test_find_service_spec_fuzzy():
    spec1 = find_service_spec("plumbing", "tap_and_pipe_repair")
    assert spec1 is not None
    assert spec1.sub_service == "tap_and_pipe_repair"

    spec2 = find_service_spec("washing_machine_repair")
    assert spec2 is not None
    assert spec2.category == "appliance_repair"


def test_unknown_service_category_fallback():
    engine = FairPriceEngine()
    req = PriceEstimationRequest(service_category="custom_drone_cleaning", sub_service="window_task")
    resp = engine.estimate_price(req)
    assert resp.estimated_price > 0
    assert resp.service_category == "custom_drone_cleaning"
