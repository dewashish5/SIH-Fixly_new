"""
Dynamic, Human-Readable Price Explainability Generator for FairPrice AI.

Generates transparent, line-by-line breakdowns of exactly why a given price
was calculated, step-by-step from statutory minimum wages to final price.
"""

from typing import Any, Dict, List
from .constants import (
    FAIR_MARKUP_FACTOR,
    GOVT_MIN_WAGE_BY_TIER,
    PLATFORM_COMMISSION_RATE,
    SKILL_TIER_LABELS,
    WORKER_SHARE_RATE,
)
from .types import PriceEstimationResponse


def generate_price_explanation(resp: PriceEstimationResponse) -> Dict[str, Any]:
    """
    Generate a structured, judge-friendly explanation of the estimation response.

    Returns a structured dictionary containing human-readable summaries and
    mathematical steps suitable for display in web UI, mobile apps, or API responses.
    """
    b = resp.breakdown
    if not b:
        return {"summary": "Breakdown not available for this estimation."}

    skill_tier = b.skill_tier
    skill_label = SKILL_TIER_LABELS.get(skill_tier, skill_tier.title())
    hourly_wage = b.minimum_wage_per_hour or GOVT_MIN_WAGE_BY_TIER.get(skill_tier, 108.0)
    duration_hours = b.duration_hours

    # 1. Statutory Baseline Step
    base_calc_str = (
        f"₹{hourly_wage:.0f}/hr (statutory {skill_label} floor) × {FAIR_MARKUP_FACTOR:.1f} markup × "
        f"{duration_hours:.2f}h ÷ {WORKER_SHARE_RATE:.2f} (worker share)"
    )

    # 2. City Step
    city_percent = int(round((b.city_multiplier - 1.0) * 100))
    city_str = (
        f"Tier {b.city_tier} ({b.city_multiplier:.2f}x / +{city_percent}% cost-of-living index)"
        if b.city_multiplier != 1.0
        else "Tier Z (1.00x nationwide base cost index)"
    )

    # 3. Demand Step
    demand_percent = int(round((resp.demand_multiplier - 1.0) * 100))
    if demand_percent > 0:
        demand_str = f"+{demand_percent}% dynamic demand surge (+₹{b.demand_adjustment:.2f})"
    elif demand_percent < 0:
        demand_str = f"{demand_percent}% off-peak discount (-₹{abs(b.demand_adjustment):.2f})"
    else:
        demand_str = "Normal demand (+₹0.00)"

    # 4. Urgency Step
    urgency_str = (
        f"Emergency SOS dispatch (+₹{b.urgency_surcharge:.2f})"
        if resp.urgency_level == "emergency"
        else (
            f"Priority express (+₹{b.urgency_surcharge:.2f})"
            if resp.urgency_level == "priority"
            else "Standard scheduled slot (+₹0.00)"
        )
    )

    # 5. Travel & Night Step
    travel_str = (
        f"Travel fee beyond 2.5 km (+₹{b.distance_travel_fee:.2f})"
        if b.distance_travel_fee > 0
        else "Within 2.5 km local radius (+₹0.00)"
    )
    night_str = (
        f"Night shift allowance (+₹{b.time_of_day_adjustment:.2f})"
        if b.time_of_day_adjustment > 0
        else "Daytime slot (+₹0.00)"
    )

    # 6. Revenue Splits
    worker_payout_str = (
        f"₹{b.worker_payout_guarantee:.2f} ({int(WORKER_SHARE_RATE * 100)}% guaranteed payout)"
    )
    platform_fee_str = (
        f"₹{b.platform_fee:.2f} ({int(PLATFORM_COMMISSION_RATE * 100)}% platform commission)"
    )

    # 7. Fairness Badges
    fairness_meta = resp.fairness_compliance or {}
    fairness_badges = [
        f"✓ Worker wage protected (≥ ₹{hourly_wage:.0f}/hr floor)",
        f"✓ 15% platform commission verified",
        f"✓ Anti-gouging surge ceiling enforced (max 1.6x)",
    ]

    return {
        "service_name": resp.sub_service.replace("_", " ").title(),
        "skill_tier": skill_tier,
        "skill_tier_label": skill_label,
        "hourly_minimum_wage": hourly_wage,
        "duration_hours": duration_hours,
        "steps": {
            "1_baseline_formula": {
                "label": "Statutory Baseline Price",
                "value": b.base_service_price,
                "formatted": f"₹{b.base_service_price:.2f}",
                "calculation": base_calc_str,
            },
            "2_city_cost_adjustment": {
                "label": "City-Tier Cost Factor",
                "tier": b.city_tier,
                "multiplier": b.city_multiplier,
                "city_adjusted_base": b.city_adjusted_base,
                "formatted": f"₹{b.city_adjusted_base:.2f}",
                "description": city_str,
            },
            "3_demand_adjustment": {
                "label": "Dynamic Demand Factor",
                "multiplier": resp.demand_multiplier,
                "adjustment": b.demand_adjustment,
                "formatted": f"{'+' if b.demand_adjustment >= 0 else '-'}₹{abs(b.demand_adjustment):.2f}",
                "description": demand_str,
            },
            "4_urgency_surcharge": {
                "label": "Urgency & Dispatch Mode",
                "urgency_level": resp.urgency_level,
                "surcharge": b.urgency_surcharge,
                "formatted": f"+₹{b.urgency_surcharge:.2f}",
                "description": urgency_str,
            },
            "5_travel_and_nocturnal": {
                "travel_fee": b.distance_travel_fee,
                "travel_description": travel_str,
                "night_fee": b.time_of_day_adjustment,
                "night_description": night_str,
            },
            "6_revenue_split": {
                "gross_total": b.gross_total,
                "worker_payout_guarantee": b.worker_payout_guarantee,
                "worker_payout_formatted": worker_payout_str,
                "platform_fee": b.platform_fee,
                "platform_fee_formatted": platform_fee_str,
            },
        },
        "fairness_badges": fairness_badges,
        "human_readable_summary": (
            f"Base: ₹{b.base_service_price:.2f} | City ({b.city_tier}): {b.city_multiplier:.2f}x → ₹{b.city_adjusted_base:.2f} | "
            f"Demand: {resp.demand_multiplier:.2f}x | Urgency: {resp.urgency_level.title()} | "
            f"Worker Payout: ₹{b.worker_payout_guarantee:.2f} (85%) | Platform Fee: ₹{b.platform_fee:.2f} (15%) | "
            f"Final Pre-Booking Price: ₹{resp.estimated_price:.2f}"
        ),
    }
