"""
Service Discovery API (SIH26089)
------------------------------------
Exposes the trained classifier as a REST endpoint so the mobile app's
"Don't know what you're looking for?" button can call it.

Run:
    python3 -m uvicorn discovery_api:app --reload --port 8002
Test at: http://localhost:8002/docs
"""

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import joblib
import os

app = FastAPI(title="Service Discovery API", version="1.0")

# Use the folder this file lives in, so it works correctly no matter
# which directory the launcher script is run from.
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
model = joblib.load(os.path.join(BASE_DIR, "service_classifier.pkl"))
vectorizer = joblib.load(os.path.join(BASE_DIR, "vectorizer.pkl"))


class DiscoveryRequest(BaseModel):
    text: str


@app.get("/")
def health_check():
    return {"status": "Service Discovery API running"}


@app.post("/discover")
def discover_service(req: DiscoveryRequest):
    if not req.text.strip():
        raise HTTPException(status_code=400, detail="Please describe your problem.")

    text_vec = vectorizer.transform([req.text])

    if hasattr(model, "predict_proba"):
        probs = model.predict_proba(text_vec)[0]
        ranked = sorted(zip(model.classes_, probs), key=lambda x: x[1], reverse=True)
        confidence_type = "probability"
    else:
        scores = model.decision_function(text_vec)[0]
        ranked = sorted(zip(model.classes_, scores), key=lambda x: x[1], reverse=True)
        confidence_type = "score"

    top3 = [{"category": cat, confidence_type: round(float(val), 3)} for cat, val in ranked[:3]]

    return {
        "input_text": req.text,
        "suggested_category": top3[0]["category"],
        "top_matches": top3,
    }
