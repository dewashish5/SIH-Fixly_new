"""
Fairness Constraints, Anti-Price-Gouging Caps, and Wage Floor Verification.
"""

from typing import Any, Dict, List, Tuple
from .types import PriceBreakdown, ServiceSpec, UrgencyLevel


class FairnessValidator:
    def __init__(
        self,
        max_surge_multiplier_cap: float = 1.60,
        min_worker_hourly_rate: float = 200.0,
        platform_commission_rate: float = 0.15,
        tax_rate: float = 0.05,
    ):
        self.max_surge_multiplier_cap = max_surge_multiplier_cap
        self.min_worker_hourly_rate = min_worker_hourly_rate
        self.platform_commission_rate = platform_commission_rate
        self.tax_rate = tax_rate

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
        2. Protect worker minimum wage floor.
        3. Audit breakdown arithmetic consistency.
        """
        notes = []
        max_allowed = round(spec.base_rate * self.max_surge_multiplier_cap + breakdown.distance_travel_fee + (100 if urgency == UrgencyLevel.EMERGENCY else 0), 2)
        worker_min = round((spec.est_duration_mins / 60.0) * self.min_worker_hourly_rate, 2)

        anti_gouging_applied = (raw_demand_multiplier > self.max_surge_multiplier_cap) or (raw_estimated_price >= max_allowed and raw_demand_multiplier >= 1.50)
        wage_floor_boosted = False

        # 1. Anti-Gouging Ceiling Enforcement
        final_price = raw_estimated_price
        if final_price > max_allowed or anti_gouging_applied:
            final_price = min(final_price, max_allowed)
            anti_gouging_applied = True
            notes.append(f"Anti-price-gouging cap enforced (maximum {self.max_surge_multiplier_cap:.1f}x surge limit).")

        # Floor constraint
        if final_price < spec.min_price_floor:
            final_price = spec.min_price_floor

        # 2. Worker Wage Floor Protection
        estimated_worker_payout = final_price * (1.0 - self.platform_commission_rate)
        if estimated_worker_payout < worker_min:
            final_price = round(worker_min / (1.0 - self.platform_commission_rate), 2)
            estimated_worker_payout = worker_min
            wage_floor_boosted = True
            notes.append(f"Worker minimum living wage protection applied (minimum ₹{worker_min:.0f} guaranteed payout).")

        # 3. Recalculate transparent splits
        platform_fee = round(final_price * self.platform_commission_rate, 2)
        worker_take_home = round(final_price - platform_fee, 2)
        tax_est = round(final_price * self.tax_rate, 2)

        # Update breakdown
        breakdown.gross_total = round(final_price, 2)
        breakdown.worker_payout_guarantee = worker_take_home
        breakdown.platform_fee = platform_fee
        breakdown.tax_estimate = tax_est

        fairness_meta = {
            "anti_gouging_applied": anti_gouging_applied,
            "wage_floor_boosted": wage_floor_boosted,
            "max_allowed_price": max_allowed,
            "worker_minimum_wage_floor": worker_min,
        }

        return final_price, breakdown, fairness_meta, notes
