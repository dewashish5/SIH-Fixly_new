"""
Service Discovery Helper (SIH26089)
--------------------------------------
Customer types their problem in plain words (Hindi/English mix) and this
model predicts which service category they need (Electrician, Plumber,
Carpenter, Painter, Cleaning, Caregiving).

Same technique as the Resume IQ project: TF-IDF + a classifier.
Only difference: training data is customer complaints instead of resumes.

Run:
    python3 train_classifier.py
"""

import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.model_selection import train_test_split
from sklearn.naive_bayes import MultinomialNB
from sklearn.svm import LinearSVC
from sklearn.metrics import classification_report, accuracy_score
import joblib


def load_data(path="training_data.csv"):
    df = pd.read_csv(path)
    return df


def train_and_evaluate(df):
    X = df["text"]
    y = df["category"]

    # Small dataset, so we use a modest test split
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )

    # TF-IDF: converts text into numbers, same as Resume IQ project
    # Using word-level n-grams (1,2) works well for short complaint sentences
    vectorizer = TfidfVectorizer(ngram_range=(1, 2), min_df=1)
    X_train_vec = vectorizer.fit_transform(X_train)
    X_test_vec = vectorizer.transform(X_test)

    # Try both models like you did in Resume IQ, pick the better one
    models = {
        "Naive Bayes": MultinomialNB(),
        "Linear SVM": LinearSVC(),
    }

    best_model = None
    best_acc = 0
    best_name = ""

    for name, model in models.items():
        model.fit(X_train_vec, y_train)
        preds = model.predict(X_test_vec)
        acc = accuracy_score(y_test, preds)
        print(f"\n--- {name} ---")
        print(f"Accuracy: {acc:.2%}")
        print(classification_report(y_test, preds, zero_division=0))

        if acc >= best_acc:
            best_acc = acc
            best_model = model
            best_name = name

    print(f"\nBest model: {best_name} ({best_acc:.2%} accuracy)")

    # Retrain best model on FULL dataset (more data = better predictions in production)
    X_full_vec = vectorizer.fit_transform(X)
    best_model.fit(X_full_vec, y)

    return best_model, vectorizer


def predict_service(text, model, vectorizer, top_n=3):
    """
    Predicts the most likely service category for a customer's free-text
    complaint. Returns top_n categories with confidence-like scores.
    """
    text_vec = vectorizer.transform([text])

    if hasattr(model, "predict_proba"):
        probs = model.predict_proba(text_vec)[0]
        classes = model.classes_
        ranked = sorted(zip(classes, probs), key=lambda x: x[1], reverse=True)
    else:
        # LinearSVC doesn't have predict_proba by default; use decision_function instead
        scores = model.decision_function(text_vec)[0]
        classes = model.classes_
        ranked = sorted(zip(classes, scores), key=lambda x: x[1], reverse=True)

    return ranked[:top_n]


if __name__ == "__main__":
    df = load_data("training_data.csv")
    print(f"Loaded {len(df)} training examples across {df['category'].nunique()} categories\n")

    model, vectorizer = train_and_evaluate(df)

    # Save model + vectorizer so the API (or app) can use them without retraining
    joblib.dump(model, "service_classifier.pkl")
    joblib.dump(vectorizer, "vectorizer.pkl")
    print("\nModel saved -> service_classifier.pkl, vectorizer.pkl")

    # ---- Test with NEW sentences the model has never seen ----
    print("\n" + "=" * 50)
    print("TESTING WITH NEW CUSTOMER MESSAGES")
    print("=" * 50)

    test_messages = [
        "mera fridge kaam nahi kar raha kya koi aa sakta hai",
        "ghar ki paint ukhad rahi hai",
        "bathroom ka tap tapak raha hai",
        "sofa bahut ganda ho gaya hai saaf karwana hai",
        "papa ki dekhbhal ke liye koi chahiye kuch dino ke liye",
        "almirah ka darwaza nahi khul raha",
    ]

    for msg in test_messages:
        results = predict_service(msg, model, vectorizer, top_n=2)
        top_category = results[0][0]
        print(f"\nCustomer says: \"{msg}\"")
        print(f"  -> Suggested service: {top_category}")
        print(f"     (other possibility: {results[1][0]})")
