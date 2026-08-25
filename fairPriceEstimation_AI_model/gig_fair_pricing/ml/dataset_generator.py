"""
Synthetic Dataset Generator for Multi-Factor Gig Pricing ML Model.
Generates realistic historical transactions with ground-truth fair clearing prices.
"""

import random
from typing import Any, Dict, List
from ..data.catalog import CATALOG, get_all_categories


def generate_pricing_dataset(num_samples: int = 5000, seed: int = 42) -> List[Dict[str, Any]]:
    random.seed(seed)
    records = []
    categories = get_all_categories()

    skill_tier_map = {"standard": 1.0, "skilled": 1.15, "master": 1.30}
    urgency_map = {"standard": 1.0, "priority": 1.15, "emergency": 1.35}

    for i in range(num_samples):
        cat = random.choice(categories)
        spec = random.choice(CATALOG[cat])

        # Feature samples
        urgency_key = random.choices(["standard", "priority", "emergency"], weights=[0.70, 0.20, 0.10])[0]
        urgency_mult = urgency_map[urgency_key]
        emergency_dispatch_fee = 100.0 if urgency_key == "emergency" else (30.0 if urgency_key == "priority" else 0.0)

        hour = random.randint(0, 23)
        is_weekend = random.choice([True, False, False, False])  # 25% weekend

        # Demand distribution (0.90 to 1.50)
        demand_mult = round(random.uniform(0.90, 1.45), 2)
        if 8 <= hour <= 11 or 17 <= hour <= 21:
            demand_mult = round(min(1.55, demand_mult + random.uniform(0.05, 0.15)), 2)

        # Distance: 1.0 km to 15.0 km
        distance_km = round(random.uniform(1.0, 12.0), 1)
        travel_fee = max(0.0, (distance_km - 2.5) * 15.0)

        # Night shift fee
        night_fee = 80.0 if (hour >= 22 or hour <= 6) else 0.0

        # Ground-truth fair clearing price calculation with slight market noise
        base = spec.base_rate
        skill_weight = skill_tier_map.get(spec.skill_tier, 1.0)
        duration_factor = spec.est_duration_mins / 60.0

        demand_component = base * (demand_mult - 1.0)
        urgency_component = (base * (urgency_mult - 1.0)) + emergency_dispatch_fee

        fair_price_clean = base + demand_component + urgency_component + travel_fee + night_fee
        # Add realistic market noise (±3%)
        noise = random.gauss(0, fair_price_clean * 0.02)
        actual_price = round(max(spec.min_price_floor, fair_price_clean + noise), 2)

        records.append({
            "sample_id": i + 1,
            "category": cat,
            "sub_service": spec.sub_service,
            "base_rate": base,
            "est_duration_mins": spec.est_duration_mins,
            "skill_tier_num": skill_weight,
            "demand_multiplier": demand_mult,
            "urgency_level": urgency_key,
            "urgency_multiplier": urgency_mult,
            "emergency_dispatch_fee": emergency_dispatch_fee,
            "distance_km": distance_km,
            "travel_fee": travel_fee,
            "hour": hour,
            "is_weekend": 1 if is_weekend else 0,
            "night_fee": night_fee,
            "target_fair_price": actual_price,
        })

    return records
