"""
Unit and integration tests for ML Worker Risk Classifier.
"""

import pytest
from gig_worker_reliability.ml.risk_model import WorkerRiskClassifier
from gig_worker_reliability.ml.dataset_generator import generate_reliability_dataset, FEATURE_COLUMNS


def test_risk_dataset_generation():
    data = generate_reliability_dataset(num_samples=100, seed=123)
    assert len(data) == 100
    for col in FEATURE_COLUMNS:
        assert col in data[0]
    assert "risk_label" in data[0]


def test_risk_classifier_predictions():
    clf = WorkerRiskClassifier()
    # High performing worker
    feat_elite = clf.extract_features(98.0, 99.0, 96.0, 98.0, 95.0, 50, streak=10, avg_rating=4.9)
    risk_elite, prob_elite, insights_elite = clf.predict_risk(feat_elite)
    assert risk_elite == "low_risk"
    assert prob_elite < 0.15

    # Poor performing worker
    feat_poor = clf.extract_features(45.0, 50.0, 40.0, 30.0, 40.0, 10, streak=0, avg_rating=2.5)
    risk_poor, prob_poor, insights_poor = clf.predict_risk(feat_poor)
    assert risk_poor == "high_risk"
    assert prob_poor > 0.40
    assert insights_poor["cancellation_warning"] is True
