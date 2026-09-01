"""
Comparative Pricing Analysis: Traditional Fixed vs FairPrice AI.

Provides objective, side-by-side comparison between legacy arbitrary fixed pricing
and FairPrice AI's dynamic, statutory, and fairness-constrained architecture.
"""

from typing import Any, Dict
from .constants import PLATFORM_COMMISSION_RATE, WORKER_SHARE_RATE, GOVT_MIN_WAGE_BY_TIER
from .types import PriceEstimationRequest, PriceEstimationResponse


# Legacy hand-picked fixed baseline prices for historical comparison
TRADITIONAL_FIXED_CATALOG: Dict[str, float] = {
    "tap_and_pipe_repair": 249.0,
    "toilet_and_sanitary_fitting": 399.0,
    "water_tank_and_motor_pipeline": 599.0,
    "fan_and_switch_repair": 199.0,
    "mcb_and_short_circuit_fix": 349.0,
    "full_house_wiring_inspection": 699.0,
    "ac_filter_and_jet_servicing": 499.0,
    "ac_gas_refill_and_leak_fix": 1299.0,
    "washing_machine_repair": 349.0,
    "refrigerator_repair": 399.0,
    "bathroom_deep_cleaning": 399.0,
    "full_home_deep_cleaning_2bhk": 1499.0,
    "furniture_assembly_and_hinges": 299.0,
    "door_lock_and_latches": 349.0,
    "single_room_repaint": 1199.0,
    "cockroach_and_ant_treatment": 599.0,
}


def compare_pricing(engine, req: PriceEstimationRequest) -> Dict[str, Any]:
    """
    Generate an objective comparison between traditional fixed pricing and FairPrice AI.
    """
    fp_resp = engine.estimate_price(req)
    sub = fp_resp.sub_service

    # Traditional model assumptions
    trad_fixed_price = TRADITIONAL_FIXED_CATALOG.get(sub, 299.0)
    trad_commission_rate = 0.20  # Industry standard 20% platform cut
    trad_worker_payout = round(trad_fixed_price * (1.0 - trad_commission_rate), 2)
    trad_platform_fee = round(trad_fixed_price * trad_commission_rate, 2)

    # FairPrice AI calculated figures
    b = fp_resp.breakdown
    fp_price = fp_resp.estimated_price
    fp_worker_payout = b.worker_payout_guarantee if b else round(fp_price * WORKER_SHARE_RATE, 2)
    fp_platform_fee = b.platform_fee if b else round(fp_price * PLATFORM_COMMISSION_RATE, 2)

    return {
        "service_name": sub.replace("_", " ").title(),
        "traditional_model": {
            "model_type": "Legacy Arbitrary Fixed Pricing",
            "customer_price": trad_fixed_price,
            "worker_payout": trad_worker_payout,
            "platform_commission_rate": "20%",
            "platform_fee": trad_platform_fee,
            "pricing_basis": "Arbitrary static catalog rate (no mathematical formula)",
            "city_cost_adjusted": False,
            "skill_wage_floor_guaranteed": False,
            "anti_gouging_surge_cap": "None / Opaque Surge",
            "transparency": "Zero breakdown (single opaque bill)",
        },
        "fairprice_ai": {
            "model_type": "FairPrice AI Dynamic & Statutory Architecture",
            "customer_price": fp_price,
            "worker_payout": fp_worker_payout,
            "platform_commission_rate": f"{int(PLATFORM_COMMISSION_RATE * 100)}%",
            "platform_fee": fp_platform_fee,
            "pricing_basis": (
                f"Statutory formula: (Govt Wage ₹{b.minimum_wage_per_hour:.0f}/hr × 1.8 × "
                f"{b.duration_hours:.2f}h) ÷ {WORKER_SHARE_RATE:.2f}" if b else "Statutory formula"
            ),
            "city_tier": b.city_tier if b else "Z",
            "city_cost_adjusted": True,
            "city_multiplier": b.city_multiplier if b else 1.0,
            "skill_wage_floor_guaranteed": True,
            "anti_gouging_surge_cap": "Hard Clamp at 1.60x Baseline",
            "transparency": "100% Itemized (Base, City, Demand, Urgency, Travel, Splits)",
        },
        "comparison_summary": [
            "Traditional model uses arbitrary hardcoded catalog prices; FairPrice AI derives prices from Ministry of Labour statutory wages.",
            "Traditional platforms take 20%+ commission; FairPrice AI centralizes a lower 15% commission (85% worker payout).",
            "Traditional models charge the same rate in small towns as in metros; FairPrice AI adjusts for local cost of living (X/Y/Z tiers).",
            "Traditional surge pricing is opaque; FairPrice AI enforces a hard 1.60x anti-gouging surge ceiling.",
            "FairPrice AI mathematically guarantees that worker payout never violates the statutory minimum wage floor.",
        ],
    }
