"""
Centralized Configuration & Single Source of Truth for FairPrice AI.

All platform-wide rates, statutory wage floors, city-tier multipliers,
and mathematical pricing formulas are defined here as the authoritative
single source of truth.
"""

from typing import Dict, Set, Tuple


# ---------------------------------------------------------------------------
# PLATFORM COMMISSION & REVENUE SPLIT CONSTANTS
# ---------------------------------------------------------------------------
# Single source of truth for platform commission: 15%
PLATFORM_COMMISSION_RATE: float = 0.15

# Worker share of customer price: 85% (1.0 - 0.15)
WORKER_SHARE_RATE: float = 1.0 - PLATFORM_COMMISSION_RATE

# Statutory Fair Markup Factor for pre-booking customer pricing
FAIR_MARKUP_FACTOR: float = 1.8

# Indicative GST / Tax Rate estimate
TAX_RATE: float = 0.05

# Anti-Price-Gouging Maximum Dynamic Surge Cap
MAX_SURGE_MULTIPLIER_CAP: float = 1.60


# ---------------------------------------------------------------------------
# STATUTORY GOVERNMENT MINIMUM WAGE FLOORS (BY SKILL TIER)
# Ministry of Labour & Employment, Central Sphere (₹ / hour)
# ---------------------------------------------------------------------------
GOVT_MIN_WAGE_BY_TIER: Dict[str, float] = {
    "standard": 108.0,  # Semi-Skilled: Cleaning, Domestic Helper, Gardener, Painter, Pest Control
    "skilled": 119.0,   # Skilled: Plumber, Carpenter, Driver, Caregiving
    "master": 129.0,    # Highly Skilled: Electrician, Technician, AC Repair
}

SKILL_TIER_LABELS: Dict[str, str] = {
    "standard": "Semi-Skilled",
    "skilled": "Skilled",
    "master": "Highly Skilled",
}


# ---------------------------------------------------------------------------
# CITY-TIER CLASSIFICATION & MULTIPLIERS (7th CPC HRA Framework)
# ---------------------------------------------------------------------------
CITY_TIER_MULTIPLIERS: Dict[str, float] = {
    "X": 1.30,   # Metro cities (Population 50 Lakh+) - Higher cost of living
    "Y": 1.15,   # Large cities (Population 5 - 50 Lakh) - Moderate cost of living
    "Z": 1.00,   # Standard towns & all other unmapped areas - Base cost of living
}

# 3-digit Postal Circle Prefixes for X-Class (Metro) Cities
# Note: Covers representative metropolitan postal circles in India.
X_CLASS_PINCODE_PREFIXES: Set[str] = {
    "110",  # Delhi NCR
    "400",  # Mumbai
    "560",  # Bengaluru
    "600",  # Chennai
    "700",  # Kolkata
    "500",  # Hyderabad
    "411",  # Pune
    "380",  # Ahmedabad
}

# 3-digit Postal Circle Prefixes for Y-Class (Large City) Centers
Y_CLASS_PINCODE_PREFIXES: Set[str] = {
    "302",  # Jaipur
    "226",  # Lucknow
    "452",  # Indore
    "440",  # Nagpur
    "395",  # Surat
    "682",  # Kochi
    "160",  # Chandigarh
    "462",  # Bhopal
    "800",  # Patna
    "641",  # Coimbatore
    "390",  # Vadodara
    "530",  # Visakhapatnam
    "422",  # Nashik
    "360",  # Rajkot
    "221",  # Varanasi
    "781",  # Guwahati
}


# ---------------------------------------------------------------------------
# PROGRAMMATIC BASELINE PRICING FORMULA
# ---------------------------------------------------------------------------
def calculate_baseline_price(
    skill_tier: str,
    duration_mins: int,
    markup_factor: float = FAIR_MARKUP_FACTOR,
    commission_rate: float = PLATFORM_COMMISSION_RATE,
) -> float:
    """
    Calculate baseline customer price programmatically using the statutory formula:

        Base Price = (Govt Minimum Wage * Markup Factor * Duration Hours) / (1 - Commission Rate)

    Args:
        skill_tier: 'standard', 'skilled', or 'master'
        duration_mins: Service duration in minutes
        markup_factor: Fairness multiplier (default: 1.8)
        commission_rate: Platform commission rate (default: 0.15)

    Returns:
        float: Calculated baseline price rounded to 2 decimal places.

    Raises:
        ValueError: If skill_tier is invalid or duration_mins <= 0.
    """
    normalized_tier = (skill_tier or "").strip().lower()
    if normalized_tier not in GOVT_MIN_WAGE_BY_TIER:
        valid_tiers = list(GOVT_MIN_WAGE_BY_TIER.keys())
        raise ValueError(
            f"Invalid skill tier '{skill_tier}'. Must be one of {valid_tiers}."
        )

    if duration_mins <= 0:
        raise ValueError(f"Duration must be greater than 0, got {duration_mins} mins.")

    wage_per_hour = GOVT_MIN_WAGE_BY_TIER[normalized_tier]
    duration_hours = duration_mins / 60.0
    worker_share = 1.0 - commission_rate

    raw_price = (wage_per_hour * markup_factor * duration_hours) / worker_share
    return round(raw_price, 2)


def get_skill_wage(skill_tier: str) -> float:
    """Return hourly minimum wage for a given skill tier or raise ValueError."""
    normalized_tier = (skill_tier or "").strip().lower()
    if normalized_tier not in GOVT_MIN_WAGE_BY_TIER:
        raise ValueError(f"Invalid skill tier '{skill_tier}'.")
    return GOVT_MIN_WAGE_BY_TIER[normalized_tier]
