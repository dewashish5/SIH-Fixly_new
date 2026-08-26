"""
Machine Learning Worker Dependability and Risk Classifier Model.
"""

import os
from typing import Any, Dict, List, Optional, Tuple
from .dataset_generator import FEATURE_COLUMNS


class WorkerRiskClassifier:
    def __init__(self, model_path: Optional[str] = None):
        self.model_path = model_path or os.path.join(os.path.dirname(__file__), "trained_risk_model.joblib")
        self.sklearn_model = None
        self._load_model()

    def _load_model(self):
        if os.path.exists(self.model_path):
            try:
                import joblib
                self.sklearn_model = joblib.load(self.model_path)
            except Exception:
                self.sklearn_model = None

    def extract_features(
        self,
        on_time: float,
        completion: float,
        feedback: float,
        cancel: float,
        response: float,
        total_jobs: int,
        streak: int = 0,
        avg_rating: float = 4.5,
    ) -> List[float]:
        return [
            float(on_time),
            float(completion),
            float(feedback),
            float(cancel),
            float(response),
            float(total_jobs),
            float(streak),
            float(avg_rating),
        ]

    def predict_risk(self, features: List[float]) -> Tuple[str, float, Dict[str, Any]]:
        """
        Predict risk class (low, moderate, high) and churn probability.
        """
        on_time, completion, feedback, cancel, response = features[0], features[1], features[2], features[3], features[4]

        # 1. Scikit-learn inference if available
        if self.sklearn_model is not None:
            try:
                import numpy as np
                X = np.array([features])
                probs = self.sklearn_model.predict_proba(X)[0]
                # Class 0: Low risk, Class 1: Moderate risk, Class 2: High risk
                pred_class_idx = int(self.sklearn_model.predict(X)[0])
                churn_prob = float(probs[2]) if len(probs) > 2 else float(probs[-1])
            except Exception:
                pred_class_idx, churn_prob = self._heuristic_predict(features)
        else:
            pred_class_idx, churn_prob = self._heuristic_predict(features)

        class_map = {0: "low_risk", 1: "moderate_risk", 2: "high_risk"}
        risk_level = class_map.get(pred_class_idx, "moderate_risk")

        insights = {
            "risk_level": risk_level,
            "churn_probability": round(churn_prob, 3),
            "punctuality_risk": on_time < 75.0,
            "cancellation_warning": cancel < 70.0,
            "quality_warning": feedback < 65.0,
        }

        return risk_level, churn_prob, insights

    def _heuristic_predict(self, f: List[float]) -> Tuple[int, float]:
        score = f[0]*0.25 + f[1]*0.25 + f[2]*0.20 + f[3]*0.15 + f[4]*0.15
        if score >= 88.0:
            return 0, 0.04
        elif score >= 70.0:
            return 1, 0.18
        else:
            return 2, 0.65
