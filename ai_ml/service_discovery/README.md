# Service Discovery Helper — SIH26089

Customer types their problem in plain words ("My fridge stopped working"
or "mera fridge kaam nahi kar raha") and this predicts which service
category they need — so they don't have to know the exact category
name themselves.

**Supports both English and Hindi (Roman script) input.**

## The 10 Official Service Categories

These match exactly what the problem statement (SIH26089) lists:
Electrician, Plumber, Carpenter, Painter, Cleaning, Domestic Helper,
Caregiving, Gardener, Driver, Technician.

## Files

| File | What it does |
|---|---|
| `training_data.csv` | 190 example customer complaints (English + Hindi), labeled across all 10 categories |
| `train_classifier.py` | Trains the model (TF-IDF + Linear SVM / Naive Bayes) |
| `service_classifier.pkl`, `vectorizer.pkl` | Saved trained model — used by the API, no retraining needed to run it |
| `discovery_api.py` | FastAPI wrapper — exposes the model as a REST endpoint |
| `demo.py` | Clean, presentation-ready script in English — use this for the SIH demo |

## Setup (run once)

```bash
pip install pandas scikit-learn joblib fastapi uvicorn --break-system-packages
python3 train_classifier.py
```

## Run the professional demo (use this for SIH judging)

```bash
python3 demo.py
```

## Run the API

```bash
python3 -m uvicorn discovery_api:app --reload --port 8002
```

Open `http://localhost:8002/docs` for an interactive test page.

## Example request (for the frontend/backend team)

```
POST /discover
{ "text": "My refrigerator suddenly stopped working" }
```

Response:
```json
{
  "input_text": "My refrigerator suddenly stopped working",
  "suggested_category": "Electrician",
  "top_matches": [
    {"category": "Electrician", "score": 0.65},
    {"category": "Technician", "score": -0.40},
    {"category": "Plumber", "score": -0.72}
  ]
}
```

## Verified working (tested by Claude before handing off)

Tested with 10 brand-new English sentences (never seen during training)
through the live API — one per category:

| Category | Test Sentence (English) | Result |
|---|---|---|
| Electrician | "My refrigerator suddenly stopped working" | Correct |
| Plumber | "There is a tap in the bathroom that keeps leaking" | Correct |
| Carpenter | "The wardrobe door in my room won't open properly" | Correct |
| Painter | "The paint on my living room wall is peeling off" | Correct |
| Cleaning | "My sofa is very dirty and needs a deep clean" | Correct |
| Domestic Helper | "I need help with daily household cleaning and cooking" | Correct |
| Caregiving | "I need someone to take care of my father" | Correct |
| Gardener | "The grass in my garden needs to be cut" | Correct |
| Driver | "I need a driver to take me to office every day" | Correct |
| Technician | "My air conditioner is not cooling the room at all" | Correct |

**Result: 10/10 categories correctly identified, in English.**

Also verified working with Hindi (Roman script) input — the same model
handles both languages since the training data includes both.

## Improve it later

Currently trained on 190 hand-written examples. Once the app is live
and customers start typing real complaints, save those (with the
category the customer actually confirmed) and add them to
`training_data.csv`, then rerun `train_classifier.py` — accuracy will
keep improving as more real examples get added.
