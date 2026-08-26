import os
import sys
import numpy as np
import joblib
from sklearn.ensemble import GradientBoostingRegressor
from sklearn.model_selection import train_test_split
from sklearn.metrics import r2_score, mean_absolute_error, mean_squared_error

pkg_root = r"C:\Users\meenakshi.p.konar\.gemini\antigravity\scratch\gig_fair_pricing"
if pkg_root not in sys.path:
    sys.path.insert(0, pkg_root)

from gig_fair_pricing.ml.dataset_generator import generate_pricing_dataset
from gig_fair_pricing.ml.model import FEATURE_COLUMNS

def train_and_save_model(model_save_path: str = None) -> dict:
    if model_save_path is None:
        model_save_path = os.path.join(pkg_root, "gig_fair_pricing", "ml", "trained_model.joblib")

    print("Generating 5,000 synthetic pricing transactions...")
    data = generate_pricing_dataset(num_samples=5000, seed=42)

    X = []
    y = []

    for row in data:
        features = [row[col] for col in FEATURE_COLUMNS]
        X.append(features)
        y.append(row["target_fair_price"])

    X = np.array(X)
    y = np.array(y)

    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

    print(f"Training GradientBoostingRegressor on {len(X_train)} samples...")
    model = GradientBoostingRegressor(
        n_estimators=100,
        learning_rate=0.1,
        max_depth=4,
        random_state=42,
    )
    model.fit(X_train, y_train)

    preds = model.predict(X_test)
    r2 = r2_score(y_test, preds)
    mae = mean_absolute_error(y_test, preds)
    rmse = np.sqrt(mean_squared_error(y_test, preds))
    mape = np.mean(np.abs((y_test - preds) / y_test)) * 100.0

    print("==================================================")
    print("Model Evaluation Results on Holdout Test Set:")
    print(f"• R2 Score:                  {r2:.4f}")
    print(f"• Mean Absolute Error (MAE): Rs. {mae:.2f}")
    print(f"• RMSE:                      Rs. {rmse:.2f}")
    print(f"• Mean Abs % Error (MAPE):   {mape:.2f}%")
    print("==================================================")

    joblib.dump(model, model_save_path)
    print(f"Model saved to: {model_save_path}")

    return {
        "r2_score": round(float(r2), 4),
        "mae": round(float(mae), 2),
        "rmse": round(float(rmse), 2),
        "mape": round(float(mape), 2),
        "model_path": model_save_path,
    }

if __name__ == "__main__":
    train_and_save_model()
