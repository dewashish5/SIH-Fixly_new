import os
import sys
import numpy as np
import joblib
from sklearn.ensemble import GradientBoostingClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, classification_report

pkg_root = r"C:\Users\meenakshi.p.konar\.gemini\antigravity\scratch\gig_worker_reliability"
if pkg_root not in sys.path:
    sys.path.insert(0, pkg_root)

from gig_worker_reliability.ml.dataset_generator import generate_reliability_dataset, FEATURE_COLUMNS

def train_and_save_risk_model(model_save_path: str = None) -> dict:
    if model_save_path is None:
        model_save_path = os.path.join(pkg_root, "gig_worker_reliability", "ml", "trained_risk_model.joblib")

    print("Generating 5,000 synthetic worker dependability samples...")
    data = generate_reliability_dataset(num_samples=5000, seed=42)

    X = []
    y = []

    for row in data:
        features = [row[col] for col in FEATURE_COLUMNS]
        X.append(features)
        y.append(row["risk_label"])

    X = np.array(X)
    y = np.array(y)

    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

    print(f"Training GradientBoostingClassifier on {len(X_train)} samples...")
    model = GradientBoostingClassifier(
        n_estimators=100,
        learning_rate=0.1,
        max_depth=3,
        random_state=42,
    )
    model.fit(X_train, y_train)

    preds = model.predict(X_test)
    acc = accuracy_score(y_test, preds)

    print("==================================================")
    print("Worker Risk Model Evaluation on Holdout Test Set:")
    print(f"• Classification Accuracy:   {acc * 100.0:.2f}% (Target: > 95%)")
    print("==================================================")

    joblib.dump(model, model_save_path)
    print(f"Model saved to: {model_save_path}")

    return {
        "accuracy": round(float(acc), 4),
        "model_path": model_save_path,
    }

if __name__ == "__main__":
    train_and_save_risk_model()
