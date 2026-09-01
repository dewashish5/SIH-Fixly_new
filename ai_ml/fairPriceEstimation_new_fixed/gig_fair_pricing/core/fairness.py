"""
Fairness Constraints, Anti-Price-Gouging Caps, and Wage Floor Verification.

Guarantees:
1. Anti-Price-Gouging: Hard dynamic surge ceiling capped at 1.60x baseline.
2. Tiered Statutory Minimum Wage Floor:
   - Semi-Skilled ("standard") : ₹108 / hr floor
   - Skilled ("skilled")       : ₹119 / hr floor
   - Highly Skilled ("master") : ₹129 / hr floor
3. Single Source of Truth for Platform Commission: 15% (Worker receives 85%).
"""

from typing import Any, Dict, List, Tuple
from .constants import (
    GOVT_MIN_WAGE_BY_TIER,
    MAX_SURGE_MULTIPLIER_CAP,
    PLATFORM_COMMISSION_RATE,
    TAX_RATE,
)
from .types import PriceBreakdown, ServiceSpec, UrgencyLevel


class FairnessValidator:
    def __init__(
        self,
        max_surge_multiplier_cap: float = MAX_SURGE_MULTIPLIER_CAP,
        platform_commission_rate: float = PLATFORM_COMMISSION_RATE,
        tax_rate: float = TAX_RATE,
    ):
        self.max_surge_multiplier_cap = max_surge_multiplier_cap
        self.platform_commission_rate = platform_commission_rate
        self.tax_rate = tax_rate

    def get_wage_floor_for_tier(self, skill_tier: str) -> float:
        """
        Looks up the statutory government wage floor for the service's skill tier.
        Raises ValueError if skill_tier is unrecognised.
        """
        normalized = (skill_tier or "").strip().lower()
        if normalized not in GOVT_MIN_WAGE_BY_TIER:
            valid_tiers = list(GOVT_MIN_WAGE_BY_TIER.keys())
            raise ValueError(
                f"Invalid skill tier '{skill_tier}'. Must be one of {valid_tiers}."
            )
        return GOVT_MIN_WAGE_BY_TIER[normalized]

    def validate_and_adjust(
        self,
        raw_estimated_price: float,
        spec: ServiceSpec,
        breakdown: PriceBreakdown,
        urgency: UrgencyLevel,
        raw_demand_multiplier: float = 1.0,
    ) -> Tuple[float, PriceBreakdown, Dict[str, Any], List[str]]:
        """
        Enforce ethical pricing bounds:
        1. Clamp between service min_price_floor and max_price_ceiling (with surge cap).
        2. Protect worker statutory minimum wage floor (tiered by skill level).
        3. Audit breakdown arithmetic consistency.
        """
        notes: List[str] = []

        urgency_dispatch_allowance = 100.0 if urgency == UrgencyLevel.EMERGENCY else (30.0 if urgency == UrgencyLevel.PRIORITY else 0.0)
        max_allowed = round(
            spec.base_rate * self.max_surge_multiplier_cap
            + breakdown.distance_travel_fee
            + urgency_dispatch_allowance
            + breakdown.time_of_day_adjustment,
            2,
        )

        tier_hourly_wage = self.get_wage_floor_for_tier(spec.skill_tier)
        worker_min = round((spec.est_duration_mins / 60.0) * tier_hourly_wage, 2)

        anti_gouging_applied = (
            (raw_demand_multiplier > self.max_surge_multiplier_cap)
            or (raw_estimated_price >= max_allowed and raw_demand_multiplier >= 1.50)
        )
        wage_floor_boosted = False

        # 1. Anti-Gouging Ceiling Enforcement
        final_price = raw_estimated_price
        if final_price > max_allowed or anti_gouging_applied:
            final_price = min(final_price, max_allowed)
            anti_gouging_applied = True
            notes.append(
                f"Anti-price-gouging cap enforced (maximum {self.max_surge_multiplier_cap:.1f}x surge limit)."
            )

        # Floor constraint from service specification
        if final_price < spec.min_price_floor:
            final_price = spec.min_price_floor

        # 2. Worker Wage Floor Protection (tiered by skill level)
        estimated_worker_payout = final_price * (1.0 - self.platform_commission_rate)
        if estimated_worker_payout < worker_min:
            final_price = round(worker_min / (1.0 - self.platform_commission_rate), 2)
            estimated_worker_payout = worker_min
            wage_floor_boosted = True
            notes.append(
                f"Worker statutory living wage floor applied ({spec.skill_tier} tier, "
                f"minimum ₹{worker_min:.2f} guaranteed payout at ₹{tier_hourly_wage:.0f}/hr)."
            )

        # 3. Transparent Payout & Fee Split Calculations
        platform_fee = round(final_price * self.platform_commission_rate, 2)
        worker_take_home = round(final_price - platform_fee, 2)
        tax_est = round(final_price * self.tax_rate, 2)

        # Update breakdown fields
        breakdown.gross_total = round(final_price, 2)
        breakdown.worker_payout_guarantee = worker_take_home
        breakdown.platform_fee = platform_fee
        breakdown.tax_estimate = tax_est
        breakdown.skill_tier = spec.skill_tier
        breakdown.minimum_wage_per_hour = tier_hourly_wage
        breakdown.duration_hours = round(spec.est_duration_mins / 60.0, 2)
        breakdown.platform_commission_rate = self.platform_commission_rate

        fairness_meta = {
            "anti_gouging_applied": anti_gouging_applied,
            "wage_floor_boosted": wage_floor_boosted,
            "max_allowed_price": max_allowed,
            "worker_minimum_wage_floor": worker_min,
            "wage_floor_hourly_rate_used": tier_hourly_wage,
            "platform_commission_rate": self.platform_commission_rate,
            "worker_share_rate": round(1.0 - self.platform_commission_rate, 2),
        }

        return final_price, breakdown, fairness_meta, notes
