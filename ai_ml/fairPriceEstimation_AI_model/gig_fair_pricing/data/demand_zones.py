"""
Geospatial Demand Forecaster and Live Demand Index Resolver.
"""

import math
from typing import Dict, Optional, Tuple
from ..core.types import DemandLevel


# Pincode locality baseline demand indices (e.g., metropolitan vs suburban density)
LOCALITY_DENSITY_INDEX: Dict[str, float] = {
    # High-density tech hubs / commercial corridors (higher baseline demand)
    "560038": 1.15,  # Indiranagar
    "560034": 1.20,  # Koramangala
    "560100": 1.18,  # Electronic City
    "560066": 1.14,  # Whitefield
    "560001": 1.12,  # MG Road / Central
    "110001": 1.15,  # Connaught Place, Delhi
    "400050": 1.22,  # Bandra West, Mumbai
    "500081": 1.15,  # Hitec City, Hyderabad
}


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
        """
        if custom_override is not None:
            mult = max(0.85, min(1.60, float(custom_override)))
            level = self._classify_level(mult)
            return mult, level, f"Live Demand Forecast Override: {mult:.2f}x"

        # 1. Base locality density
        base_locality = LOCALITY_DENSITY_INDEX.get(str(pincode or "").strip(), 1.0)

        # 2. Time-of-day demand multiplier curve
        # Morning peak: 8:00 - 11:00 (1.15x - 1.25x)
        # Afternoon lull: 13:00 - 16:00 (0.95x - 1.00x)
        # Evening peak: 17:00 - 21:00 (1.20x - 1.35x)
        # Night shift: 22:00 - 06:00 (1.10x due to lower worker supply)
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

        # Normalized and capped between 0.90x and 1.55x for fairness
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
