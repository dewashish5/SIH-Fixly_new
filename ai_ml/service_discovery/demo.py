"""
Service Discovery Helper - Live Demo (SIH26089)
---------------------------------------------------
A clean, presentation-ready demo script for showing the AI model
working live during the SIH internal hackathon judging.

Run:
    python3 demo.py
"""

import joblib
import numpy as np
import warnings
warnings.filterwarnings("ignore")

# ---- Load the trained model ----
model = joblib.load("service_classifier.pkl")
vectorizer = joblib.load("vectorizer.pkl")


def predict(text, top_n=3):
    text_vec = vectorizer.transform([text])

    if hasattr(model, "predict_proba"):
        scores = model.predict_proba(text_vec)[0]
    else:
        raw = model.decision_function(text_vec)[0]
        exp_scores = np.exp(raw - np.max(raw))
        scores = exp_scores / exp_scores.sum()

    ranked = sorted(zip(model.classes_, scores), key=lambda x: x[1], reverse=True)
    return ranked[:top_n]


def print_banner():
    print("=" * 66)
    print("   SIH26089 | AI SERVICE DISCOVERY ENGINE - LIVE DEMO")
    print("   Cooperative Gig Services Platform")
    print("=" * 66)
    print()


def print_result(customer_text, results):
    print(f"  Customer Input : \"{customer_text}\"")
    print(f"  {'-' * 60}")
    top_category, top_score = results[0]
    print(f"  >> Recommended Service : {top_category}   (confidence: {top_score*100:.1f}%)")
    print(f"  Other possible matches :")
    for category, score in results[1:]:
        print(f"      - {category:<18} ({score*100:.1f}%)")
    print()


if __name__ == "__main__":
    print_banner()

    # All demo inputs in English for a clean, professional SIH presentation
    demo_cases = [
        "My refrigerator suddenly stopped working, can someone come check it?",
        "The paint on my living room wall is peeling off badly",
        "There is a tap in the bathroom that keeps leaking water",
        "My sofa is very dirty and needs a deep clean",
        "I need someone to take care of my father for a few days",
        "The wardrobe door in my room won't open properly",
        "The grass in my garden needs to be cut and trimmed",
        "I need a driver to take me to office every day",
        "My air conditioner is not cooling the room at all",
        "I need help with daily household cleaning and cooking",
    ]

    for text in demo_cases:
        results = predict(text)
        print_result(text, results)

    print("=" * 66)
    print("   Model tested across all 10 official service categories")
    print("   Technique: TF-IDF + Linear SVM (scikit-learn)")
    print("   Supports both English and Hindi (Roman script) input")
    print("=" * 66)
