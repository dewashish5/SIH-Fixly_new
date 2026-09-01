"""
Geospatial Demand Forecaster and Pan-India City Tier Multiplier Resolver.

City-Tier Classification (7th Central Pay Commission HRA Framework):
    - Tier X (Metro cities)       : 1.30x structural baseline multiplier
    - Tier Y (Large cities)       : 1.15x structural baseline multiplier
    - Tier Z (All other regions)  : 1.00x base pricing (standard nationwide baseline)

Coverage Note:
    3-digit postal circle prefixes are used to map known X and Y metropolitan
    and tier-2 urban areas. All other pin codes across India safely and
    transparently default to Tier Z (1.00x baseline).

Separation of Concerns:
    City tier represents structural living cost differences (constant every day).
    Dynamic demand represents temporary market fluctuations (e.g. rush hours).
    They are tracked, computed, and explained as distinct multipliers.
"""

import math
from typing import Dict, Optional, Tuple
from ..core.constants import (
    CITY_TIER_MULTIPLIERS,
    X_CLASS_PINCODE_PREFIXES,
    Y_CLASS_PINCODE_PREFIXES,
)
from ..core.types import DemandLevel


# Pincode locality baseline density indices for sample urban corridors
LOCALITY_DENSITY_INDEX: Dict[str, float] = {
    "560038": 1.15,  # Indiranagar, Bengaluru
    "560034": 1.20,  # Koramangala, Bengaluru
    "560100": 1.18,  # Electronic City, Bengaluru
    "560066": 1.14,  # Whitefield, Bengaluru
    "560001": 1.12,  # MG Road / Central, Bengaluru
    "110001": 1.15,  # Connaught Place, Delhi
    "400050": 1.22,  # Bandra West, Mumbai
    "500081": 1.15,  # Hitec City, Hyderabad
}


def get_city_tier_multiplier(pincode: Optional[str] = None) -> Tuple[float, str, str]:
    """
    Resolve city tier, multiplier, and explanatory reason from the location pincode.

    Uses the first 3 digits (postal circle) to identify known X-class (metro)
    and Y-class (large city) locations. Unmapped or missing pincodes default
    safely and explicitly to Z-class (1.00x base price).

    Returns:
        Tuple[float, str, str]: (multiplier, tier_label, reason)
    """
    clean_code = str(pincode or "").strip()
    prefix = clean_code[:3] if len(clean_code) >= 3 else ""

    if prefix in X_CLASS_PINCODE_PREFIXES:
        return (
            CITY_TIER_MULTIPLIERS["X"],
            "X",
            "Metro city (X-class) - higher cost of living",
        )
    if prefix in Y_CLASS_PINCODE_PREFIXES:
        return (
            CITY_TIER_MULTIPLIERS["Y"],
            "Y",
            "Large city (Y-class) - moderate cost of living",
        )

    return (
        CITY_TIER_MULTIPLIERS["Z"],
        "Z",
        "Standard town / Unmapped area (Z-class) - base pricing",
    )


class DemandForecaster:
    def __init__(self):
        pass

    def get_demand_index(
        self,
        pincode: Optional[str] = None,
        hour: int = 14,
        is_weekend: bool = False,
        custom_override: Optional[float] = None,
    ) -> Tuple[float, DemandLevel, str]:
        """
        Compute dynamic demand multiplier based on:
        1. Custom forecast model override (if passed from upstream AI model)
        2. Locality density
        3. Diurnal hour peak curve
        4. Weekend factor

        NOTE: City-tier (X/Y/Z) is intentionally NOT mixed here. It is applied
        separately to the base price in the pricing engine.
        """
        if custom_override is not None:
            mult = max(0.85, min(1.60, float(custom_override)))
            level = self._classify_level(mult)
            return round(mult, 2), level, f"Live Demand Forecast Override: {mult:.2f}x"

        # 1. Base locality density
        base_locality = LOCALITY_DENSITY_INDEX.get(str(pincode or "").strip(), 1.0)

        # 2. Time-of-day demand multiplier curve
        hour = hour % 24
        if 8 <= hour <= 11:
            hour_factor = 1.18
            reason = "Morning peak service hours (8 AM - 11 AM)"
        elif 17 <= hour <= 21:
            hour_factor = 1.25
            reason = "Evening high-demand window (5 PM - 9 PM)"
        elif 22 <= hour or hour <= 6:
            hour_factor = 1.10
            reason = "Night shift / restricted worker availability"
        else:
            hour_factor = 1.00
            reason = "Standard daytime hours"

        # 3. Weekend factor
        weekend_factor = 1.10 if is_weekend else 1.00
        if is_weekend:
            reason += " + Weekend household booking surge"

        # Combined raw multiplier
        raw_mult = base_locality * hour_factor * weekend_factor

        # Clamped between 0.90x and 1.55x for anti-gouging fairness
        clamped_mult = round(max(0.90, min(1.55, raw_mult)), 2)
        level = self._classify_level(clamped_mult)

        return clamped_mult, level, reason

    def _classify_level(self, multiplier: float) -> DemandLevel:
        if multiplier < 0.98:
            return DemandLevel.LOW
        elif multiplier <= 1.08:
            return DemandLevel.NORMAL
        elif multiplier <= 1.22:
            return DemandLevel.MODERATE
        elif multiplier <= 1.38:
            return DemandLevel.HIGH
        else:
            return DemandLevel.PEAK
