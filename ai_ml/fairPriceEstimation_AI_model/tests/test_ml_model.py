"""
Unit and evaluation tests for ML price regressor, dataset generation, and predictions.
"""

import os
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


def test_ml_model_feature_extraction():
    model = MLPriceModel()
    features = model.extract_features(
        base_rate=349.0,
        est_duration_mins=60,
        skill_tier="skilled",
        demand_mult=1.20,
        urgency_mult=1.0,
        emergency_dispatch_fee=0.0,
        distance_km=4.0,
        hour=15,
        is_weekend=False,
    )
    assert len(features) == len(FEATURE_COLUMNS)
    assert features[0] == 349.0
    assert features[2] == 1.15  # skilled


def test_ml_model_prediction_output():
    model = MLPriceModel()
    features = model.extract_features(
        base_rate=499.0,
        est_duration_mins=60,
        skill_tier="skilled",
        demand_mult=1.15,
        urgency_mult=1.35,
        emergency_dispatch_fee=100.0,
        distance_km=5.0,
        hour=18,
        is_weekend=True,
    )
    pred, p_min, p_max, contrib = model.predict(features)
    assert pred > 499.0
    assert p_min <= pred <= p_max
    assert "base_component" in contrib
    assert "demand_adjustment" in contrib
    assert "urgency_surcharge" in contrib
    assert contrib["urgency_surcharge"] > 0


def test_fallback_formula_prediction():
    model = MLPriceModel(model_path="non_existent_file.joblib")
    features = [300.0, 60.0, 1.0, 1.10, 1.0, 0.0, 3.0, 7.5, 14.0, 0.0, 0.0]
    pred = model._formula_predict(features)
    # base(300) + demand(300*0.1=30) + urgency(0) + travel(7.5) = 337.5
    assert pred == 337.5
