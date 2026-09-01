"""
Deterministic Judge Demo Scenarios for FairPrice AI.

Provides reproducible, 1-click test scenarios (Scenarios A through F) for
hackathon demonstrations and automated verification.
"""

from typing import Any, Dict, List
from .types import PriceEstimationRequest, UrgencyLevel
from .explanation import generate_price_explanation


def get_all_demo_scenarios(engine) -> List[Dict[str, Any]]:
    """
    Execute and return all 6 deterministic judge scenarios with full breakdowns.
    """
    scenarios = [
        # Scenario A: Standard City (Tier Z)
        {
            "id": "scenario_a_standard_city",
            "title": "Scenario A — Standard City (Tier Z)",
            "description": "Tap repair in Tier Z standard region (1.00x base cost) with normal demand and standard scheduling.",
            "request": PriceEstimationRequest(
                service_category="plumbing",
                sub_service="tap_and_pipe_repair",
                location_pincode="175001",  # Tier Z
                urgency=UrgencyLevel.STANDARD,
                distance_km=2.0,
                scheduled_hour=14,
                is_weekend=False,
            ),
            "key_learning": "Proves nationwide baseline formula (₹108/hr × 1.8 × 0.75h ÷ 0.85 = ₹171.53) with 1.00x Tier Z multiplier.",
        },
        # Scenario B: Metro City (Tier X)
        {
            "id": "scenario_b_metro_city",
            "title": "Scenario B — Metro City (Tier X)",
            "description": "Same tap repair service in Tier X metro (Bengaluru, 1.30x structural cost index).",
            "request": PriceEstimationRequest(
                service_category="plumbing",
                sub_service="tap_and_pipe_repair",
                location_pincode="560038",  # Tier X: Bengaluru
                urgency=UrgencyLevel.STANDARD,
                distance_km=2.0,
                scheduled_hour=14,
                is_weekend=False,
            ),
            "key_learning": "Proves structural city-tier scaling: ₹171.53 × 1.30 = ₹222.99 base price before demand.",
        },
        # Scenario C: High Demand Surge
        {
            "id": "scenario_c_high_demand",
            "title": "Scenario C — High Demand Surge",
            "description": "Same tap repair in Tier X metro during high demand peak (1.35x dynamic demand surge).",
            "request": PriceEstimationRequest(
                service_category="plumbing",
                sub_service="tap_and_pipe_repair",
                location_pincode="560038",  # Tier X
                urgency=UrgencyLevel.STANDARD,
                distance_km=2.0,
                scheduled_hour=18,
                is_weekend=False,
                custom_demand_override=1.35,
            ),
            "key_learning": "Proves dynamic demand changes independently from structural city multiplier.",
        },
        # Scenario D: Skilled Artisan Tier Wage
        {
            "id": "scenario_d_skilled_artisan",
            "title": "Scenario D — Skilled vs Semi-Skilled Artisan",
            "description": "MCB short circuit fix requiring Skilled artisan (₹119/hr) vs basic Standard artisan (₹108/hr).",
            "request": PriceEstimationRequest(
                service_category="electrical",
                sub_service="mcb_and_short_circuit_fix",  # Skilled tier
                location_pincode="560038",
                urgency=UrgencyLevel.STANDARD,
                distance_km=2.0,
                scheduled_hour=14,
            ),
            "key_learning": "Proves skill-based statutory wage floors: ₹119/hr produces ₹252 base vs ₹228.71 for ₹108/hr standard.",
        },
        # Scenario E: Emergency SOS Dispatch
        {
            "id": "scenario_e_emergency_dispatch",
            "title": "Scenario E — Emergency SOS Dispatch",
            "description": "MCB short circuit repair requested under Emergency SOS mode (<30-45 mins arrival guaranteed).",
            "request": PriceEstimationRequest(
                service_category="electrical",
                sub_service="mcb_and_short_circuit_fix",
                location_pincode="560038",
                urgency=UrgencyLevel.EMERGENCY,
                distance_km=2.0,
                scheduled_hour=14,
            ),
            "key_learning": "Proves transparent urgency surge: 1.35x multiplier + ₹100 guaranteed emergency dispatch bonus.",
        },
        # Scenario F: Statutory Worker Wage Floor Protection
        {
            "id": "scenario_f_worker_protection",
            "title": "Scenario F — Worker Statutory Wage Floor Protection",
            "description": "Service with low custom demand index where fairness layer guarantees statutory hourly payout.",
            "request": PriceEstimationRequest(
                service_category="cleaning",
                sub_service="bathroom_deep_cleaning",
                location_pincode="175001",  # Tier Z
                custom_demand_override=0.85,  # Off-peak discount
                distance_km=2.0,
                scheduled_hour=15,
            ),
            "key_learning": "Proves worker payout cannot fall below statutory wage floor (60 mins × ₹108/hr = ₹108 minimum).",
        },
    ]

    results = []
    for sc in scenarios:
        resp = engine.estimate_price(sc["request"])
        explanation = generate_price_explanation(resp)
        results.append({
            "id": sc["id"],
            "title": sc["title"],
            "description": sc["description"],
            "key_learning": sc["key_learning"],
            "inputs": {
                "service_category": sc["request"].service_category,
                "sub_service": sc["request"].sub_service,
                "location_pincode": sc["request"].location_pincode,
                "urgency": sc["request"].urgency.value if hasattr(sc["request"].urgency, "value") else str(sc["request"].urgency),
                "distance_km": sc["request"].distance_km,
                "custom_demand_override": sc["request"].custom_demand_override,
            },
            "output": resp.to_dict(),
            "explanation": explanation,
        })

    return results
