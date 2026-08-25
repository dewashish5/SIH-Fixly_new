"""
Synthetic Dataset Generator for Gig Worker Reliability and Churn Risk Prediction.
"""

import random
from typing import Any, Dict, List

FEATURE_COLUMNS = [
    "on_time_rate",
    "completion_rate",
    "feedback_score",
    "cancellation_resistance",
    "response_time_score",
    "total_jobs_evaluated",
    "streak_count",
    "average_rating",
]


def generate_reliability_dataset(num_samples: int = 5000, seed: int = 42) -> List[Dict[str, Any]]:
    random.seed(seed)
    records = []

    for i in range(num_samples):
        # 3 Worker Archetypes: Elite (40%), Standard/Dependable (45%), High-Risk/At-Risk (15%)
        archetype = random.choices(["elite", "standard", "at_risk"], weights=[0.40, 0.45, 0.15])[0]

        if archetype == "elite":
            on_time = round(random.uniform(92.0, 100.0), 1)
            completion = round(random.uniform(96.0, 100.0), 1)
            feedback = round(random.uniform(88.0, 100.0), 1)
            cancel = round(random.uniform(90.0, 100.0), 1)
            response = round(random.uniform(88.0, 100.0), 1)
            total_jobs = random.randint(15, 120)
            streak = random.randint(3, 20)
            avg_rating = round(random.uniform(4.6, 5.0), 2)
            risk_label = 0  # Low risk (Elite)
            churn_prob = round(random.uniform(0.01, 0.08), 3)

        elif archetype == "standard":
            on_time = round(random.uniform(75.0, 92.0), 1)
            completion = round(random.uniform(80.0, 95.0), 1)
            feedback = round(random.uniform(70.0, 88.0), 1)
            cancel = round(random.uniform(75.0, 90.0), 1)
            response = round(random.uniform(70.0, 90.0), 1)
            total_jobs = random.randint(5, 60)
            streak = random.randint(0, 5)
            avg_rating = round(random.uniform(3.8, 4.5), 2)
            risk_label = 1  # Moderate risk (Standard)
            churn_prob = round(random.uniform(0.10, 0.25), 3)

        else:  # at_risk
            on_time = round(random.uniform(40.0, 70.0), 1)
            completion = round(random.uniform(35.0, 75.0), 1)
            feedback = round(random.uniform(30.0, 65.0), 1)
            cancel = round(random.uniform(20.0, 65.0), 1)
            response = round(random.uniform(30.0, 65.0), 1)
            total_jobs = random.randint(3, 40)
            streak = 0
            avg_rating = round(random.uniform(2.0, 3.6), 2)
            risk_label = 2  # High risk (Probation / Attention)
            churn_prob = round(random.uniform(0.40, 0.85), 3)

        composite_score = int(round(
            on_time * 0.25 + completion * 0.25 + feedback * 0.20 + cancel * 0.15 + response * 0.15
        ))

        records.append({
            "worker_id": f"WRK-SYN-{i+1}",
            "on_time_rate": on_time,
            "completion_rate": completion,
            "feedback_score": feedback,
            "cancellation_resistance": cancel,
            "response_time_score": response,
            "total_jobs_evaluated": total_jobs,
            "streak_count": streak,
            "average_rating": avg_rating,
            "composite_score": composite_score,
            "risk_label": risk_label,
            "churn_probability": churn_prob,
        })

    return records
