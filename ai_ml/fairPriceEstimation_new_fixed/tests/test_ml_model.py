"""
Unit and regression tests for ML price regressor, dataset generation, and model metrics.
"""

import os
import json
import math
import pytest
from gig_fair_pricing.ml.dataset_generator import generate_pricing_dataset
from gig_fair_pricing.ml.model import MLPriceModel, FEATURE_COLUMNS


def test_dataset_generator_structure():
    data = generate_pricing_dataset(num_samples=100, seed=123)
    assert len(data) == 100
    first = data[0]
    for col in FEATURE_COLUMNS:
        assert col in first
    assert "target_fair_price" in first
    assert first["target_fair_price"] > 0
    assert first["city_multiplier"] in (1.00, 1.15, 1.30)


def test_ml_model_feature_extraction():
    model = MLPriceModel()
    features = model.extract_features(
        base_rate=349.0,
        est_duration_mins=60,
        skill_tier="skilled",
        city_multiplier=1.30,
        demand_mult=1.20,
        urgency_mult=1.0,
        emergency_dispatch_fee=0.0,
        distance_km=4.0,
        hour=15,
        is_weekend=False,
    )
    assert len(features) == len(FEATURE_COLUMNS)
    assert features[0] == 349.0
    assert features[2] == 1.15  # skilled numeric weight
    assert features[3] == 1.30  # city multiplier


def test_ml_model_prediction_output():
    model = MLPriceModel()
    features = model.extract_features(
        base_rate=252.0,
        est_duration_mins=60,
        skill_tier="skilled",
        city_multiplier=1.30,
        demand_mult=1.15,
        urgency_mult=1.35,
        emergency_dispatch_fee=100.0,
        distance_km=5.0,
        hour=18,
        is_weekend=True,
    )
    pred, p_min, p_max, contrib = model.predict(features)
    assert isinstance(pred, (int, float))
    assert not math.isnan(pred) and not math.isinf(pred)
    assert pred > 252.0
    assert p_min <= pred <= p_max
    assert "base_component" in contrib
    assert "city_adjustment" in contrib
    assert "demand_adjustment" in contrib
    assert "urgency_surcharge" in contrib
    assert contrib["urgency_surcharge"] > 0


def test_fallback_formula_prediction():
    model = MLPriceModel(model_path="non_existent_file.joblib")
    # [base_rate, est_duration, skill_num, city_mult, demand_mult, urgency_mult, emergency_fee, dist, travel_fee, hour, weekend, night_fee]
    features = [300.0, 60.0, 1.0, 1.0, 1.10, 1.0, 0.0, 3.0, 7.5, 14.0, 0.0, 0.0]
    pred = model._formula_predict(features)
    # base(300) + demand(300*0.1=30) + urgency(0) + travel(7.5) = 337.5
    assert pred == 337.5


def test_model_evaluation_metrics_report():
    report_path = os.path.join(
        os.path.dirname(__file__), "..", "reports", "model_evaluation.json"
    )
    assert os.path.exists(report_path), "Model evaluation report must exist."

    with open(report_path, "r", encoding="utf-8") as f:
        report = json.load(f)

    metrics = report["metrics"]
    assert "r2_score" in metrics
    assert "mae" in metrics
    assert "rmse" in metrics
    assert "mape_percent" in metrics

    # Defensible accuracy thresholds verified from actual evaluation run
    assert metrics["r2_score"] >= 0.98
    assert metrics["mae"] <= 25.0
    assert metrics["rmse"] <= 35.0
    assert metrics["mape_percent"] <= 5.0
