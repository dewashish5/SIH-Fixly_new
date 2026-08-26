# Service Discovery Helper — SIH26089

Customer types their problem in plain words ("fridge nahi chal raha")
and this predicts which service category they need — so they don't
have to know the exact category name themselves.

## The 10 Official Service Categories

These match exactly what the problem statement (SIH26089) lists:
Electrician, Plumber, Carpenter, Painter, Cleaning, Domestic Helper,
Caregiving, Gardener, Driver, Technician.

## Files

| File | What it does |
|---|---|
| `training_data.csv` | 131 example customer complaints, labeled across all 10 categories |
| `train_classifier.py` | Trains the model (TF-IDF + Linear SVM / Naive Bayes) |
| `service_classifier.pkl`, `vectorizer.pkl` | Saved trained model — used by the API, no retraining needed to run it |
| `discovery_api.py` | FastAPI wrapper — exposes the model as a REST endpoint |

## How it works

The customer's sentence is converted into numbers (TF-IDF), then a
trained model predicts the most likely category out of the 10 above.

## Setup (run once)

```bash
pip install pandas scikit-learn joblib fastapi uvicorn --break-system-packages
python3 train_classifier.py
```
This prints accuracy stats and saves the trained model to `.pkl` files.

## Run the API

```bash
python3 -m uvicorn discovery_api:app --reload --port 8002
```

Open `http://localhost:8002/docs` for an interactive test page — you
can try any sentence there without writing code.

## Example request (for the frontend/backend team)

```
POST /discover
{ "text": "mera fridge kaam nahi kar raha" }
```

Response:
```json
{
  "input_text": "mera fridge kaam nahi kar raha",
  "suggested_category": "Electrician",
  "top_matches": [
    {"category": "Electrician", "score": 0.65},
    {"category": "Technician", "score": -0.40},
    {"category": "Plumber", "score": -0.72}
  ]
}
```

The app should show `suggested_category` to the customer and let them
confirm, or pick from `top_matches` if the top guess is wrong.

## Verified working (tested by Claude before handing off)

Tested with one brand-new sentence per category (never seen during
training) through the live API:

| Category | Test Sentence | Result |
|---|---|---|
| Electrician | "fridge ka switch kaam nahi kar raha" | Correct |
| Plumber | "nal se paani tapak raha hai" | Correct |
| Carpenter | "almirah ka darwaza toota hua hai" | Correct |
| Painter | "ghar ki deewar par paint karwana hai" | Correct |
| Cleaning | "ghar ki deep cleaning chahiye" | Correct |
| Domestic Helper | "ghar ke roz ke kaam ke liye maid chahiye" | Correct |
| Caregiving | "papa ki tabiyat kharab hai dekhbhal chahiye" | Correct |
| Gardener | "garden me ghaas kaatni hai" | Correct |
| Driver | "office jaane ke liye roz driver chahiye" | Correct |
| Technician | "AC thanda nahi kar raha check karwana hai" | Correct |

**Result: 10/10 categories correctly identified.**

## Improve it later

Currently trained on 131 hand-written examples (~13 per category). Once
the app is live and customers start typing real complaints, save those
(with the category the customer actually confirmed) and add them to
`training_data.csv`, then rerun `train_classifier.py` — accuracy will
keep improving as more real examples get added.
