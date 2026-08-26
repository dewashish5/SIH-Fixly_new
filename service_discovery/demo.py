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
        # Softmax: turns raw SVM scores into realistic-looking confidence
        # percentages that sum to 100%, instead of always showing the top
        # answer as 100% (which min-max scaling would incorrectly do).
        exp_scores = np.exp(raw - np.max(raw))
        scores = exp_scores / exp_scores.sum()

    ranked = sorted(zip(model.classes_, scores), key=lambda x: x[1], reverse=True)
    return ranked[:top_n]


def print_banner():
    print("=" * 64)
    print("   SIH26089 | AI SERVICE DISCOVERY ENGINE - LIVE DEMO")
    print("   Cooperative Gig Services Platform")
    print("=" * 64)
    print()


def print_result(customer_text, results):
    print(f"  Customer Input : \"{customer_text}\"")
    print(f"  {'-' * 58}")
    top_category, top_score = results[0]
    print(f"  >> Recommended Service : {top_category}   (confidence: {top_score*100:.1f}%)")
    print(f"  Other possible matches :")
    for category, score in results[1:]:
        print(f"      - {category:<18} ({score*100:.1f}%)")
    print()


if __name__ == "__main__":
    print_banner()

    demo_cases = [
        "mera fridge kaam nahi kar raha kya koi aa sakta hai",
        "ghar ki paint ukhad rahi hai",
        "bathroom ka tap tapak raha hai",
        "sofa bahut ganda ho gaya hai saaf karwana hai",
        "papa ki dekhbhal ke liye koi chahiye kuch dino ke liye",
        "almirah ka darwaza nahi khul raha",
        "garden me ghaas kaatni hai",
        "office jaane ke liye roz driver chahiye",
        "AC thanda nahi kar raha check karwana hai",
        "ghar ke roz ke kaam ke liye maid chahiye",
    ]

    for text in demo_cases:
        results = predict(text)
        print_result(text, results)

    print("=" * 64)
    print(f"   Model tested across all 10 official service categories")
    print(f"   Technique: TF-IDF + Linear SVM (scikit-learn)")
    print("=" * 64)
