"""
Machine Learning Price Regressor Model and Feature Engineering Pipeline.
"""

import os
import math
from typing import Any, Dict, List, Optional, Tuple

FEATURE_COLUMNS = [
    "base_rate",
    "est_duration_mins",
    "skill_tier_num",
    "demand_multiplier",
    "urgency_multiplier",
    "emergency_dispatch_fee",
    "distance_km",
    "travel_fee",
    "hour",
    "is_weekend",
    "night_fee",
]


class MLPriceModel:
    def __init__(self, model_path: Optional[str] = None):
        self.model_path = model_path or os.path.join(os.path.dirname(__file__), "trained_model.joblib")
        self.sklearn_model = None
        self._load_or_init_model()

    def _load_or_init_model(self):
        if os.path.exists(self.model_path):
            try:
                import joblib
                self.sklearn_model = joblib.load(self.model_path)
                return
            except Exception:
                pass
        self.sklearn_model = None

    def extract_features(
        self,
        base_rate: float,
        est_duration_mins: int,
        skill_tier: str,
        demand_mult: float,
        urgency_mult: float,
        emergency_dispatch_fee: float,
        distance_km: float,
        hour: int,
        is_weekend: bool,
    ) -> List[float]:
        skill_map = {"standard": 1.0, "skilled": 1.15, "master": 1.30}
        skill_num = skill_map.get(skill_tier.lower(), 1.0)
        travel_fee = max(0.0, (distance_km - 2.5) * 15.0)
        night_fee = 80.0 if (hour >= 22 or hour <= 6) else 0.0

        return [
            float(base_rate),
            float(est_duration_mins),
            float(skill_num),
            float(demand_mult),
            float(urgency_mult),
            float(emergency_dispatch_fee),
            float(distance_km),
            float(travel_fee),
            float(hour),
            1.0 if is_weekend else 0.0,
            float(night_fee),
        ]

    def predict(self, feature_vector: List[float]) -> Tuple[float, float, float, Dict[str, float]]:
        """
        Predict price with confidence intervals and feature contribution breakdown.
        """
        base_rate = feature_vector[0]
        demand_mult = feature_vector[3]
        urgency_mult = feature_vector[4]
        emergency_fee = feature_vector[5]
        travel_fee = feature_vector[7]
        night_fee = feature_vector[10]

        # 1. Scikit-learn model inference if loaded
        if self.sklearn_model is not None:
            try:
                import numpy as np
                X = np.array([feature_vector])
                pred_price = float(self.sklearn_model.predict(X)[0])
            except Exception:
                pred_price = self._formula_predict(feature_vector)
        else:
            pred_price = self._formula_predict(feature_vector)

        pred_price = round(max(base_rate * 0.85, pred_price), 2)

        # 2. Confidence interval range (±7% market elasticity buffer)
        margin = max(30.0, pred_price * 0.07)
        min_range = round(max(base_rate, pred_price - margin), 2)
        max_range = round(pred_price + margin, 2)

        # 3. Transparent feature contribution breakdown
        demand_delta = round(base_rate * (demand_mult - 1.0), 2)
        urgency_delta = round((base_rate * (urgency_mult - 1.0)) + emergency_fee, 2)

        contributions = {
            "base_component": round(base_rate, 2),
            "demand_adjustment": demand_delta,
            "urgency_surcharge": urgency_delta,
            "distance_travel_fee": round(travel_fee, 2),
            "time_of_day_fee": round(night_fee, 2),
        }

        return pred_price, min_range, max_range, contributions

    def _formula_predict(self, f: List[float]) -> float:
        base_rate = f[0]
        demand_mult = f[3]
        urgency_mult = f[4]
        emergency_fee = f[5]
        travel_fee = f[7]
        night_fee = f[10]

        demand_comp = base_rate * (demand_mult - 1.0)
        urgency_comp = (base_rate * (urgency_mult - 1.0)) + emergency_fee

        return base_rate + demand_comp + urgency_comp + travel_fee + night_fee
