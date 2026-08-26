# SIH26089 — AI/ML Layer
Cooperative Gig Services Platform for Household & Community Services

This repo contains all AI/ML features for the project. Each feature has
its own folder, built as an independent microservice. The backend team
can call these directly once deployed.

## Team

- Nikhil — Worker-Customer Matching, Service Discovery Helper
- Teammate — Support Chatbot, Worker Reliability Score, Fair Price Estimation

## Folder Structure

```
SIH-2026-Ai-Ml/
├── service_discovery/            - identifies which service a customer needs from free text
├── worker_matching/              - ranks the best available worker for a job
├── worker_Reliability_Score/     - scores how dependable a worker is (0-100)
├── fairPriceEstimation_AI_model/ - estimates a fair price for a booking
├── support_chatbot/              - FAQ-style support chatbot (Hindi + English)
└── README.md
```

## Status

| Feature | Status | Owner |
|---|---|---|
| Worker-Customer Matching | Done, tested | Nikhil |
| Service Discovery Helper | Done, tested | Nikhil |
| Support Chatbot | Done, tested | Teammate |
| Worker Reliability Score | Done, tested | Teammate |
| Fair Price Estimation | Done, tested | Teammate |

**All 5 planned AI/ML features are complete.**

---

## 1. service_discovery/

**What it does:** Customer types their problem in plain words (e.g.
"My fridge stopped working" / "fridge nahi chal raha") and the model
predicts which service category they need. Supports English and Hindi
(Roman script).

**Categories covered:** Electrician, Plumber, Carpenter, Painter,
Cleaning, Domestic Helper, Caregiving, Gardener, Driver, Technician
(all 10 official categories from the problem statement).

**How it works:** TF-IDF + a trained classifier (Naive Bayes / Linear SVM).

**Files:**
- `training_data.csv` — ~190 example customer complaints (English + Hindi), labeled by category
- `train_classifier.py` — trains the model, run this first
- `service_classifier.pkl`, `vectorizer.pkl` — saved trained model
- `discovery_api.py` — FastAPI endpoint (`POST /discover`)
- `demo.py` — clean, presentation-ready script for the SIH demo

**Run it:**
```bash
cd service_discovery
pip install pandas scikit-learn joblib fastapi uvicorn --break-system-packages
python3 train_classifier.py
python3 -m uvicorn discovery_api:app --reload --port 8002
```
Test at `http://localhost:8002/docs`

**Tested result:** 10/10 official categories correctly identified,
verified via live API calls in both English and Hindi.

---

## 2. worker_matching/

**What it does:** Given a customer's location and required skill, ranks
the best available workers — not just the nearest one. Considers skill
match, distance, rating, completion rate, and response time. Covers all
10 official service categories.

**Files:**
- `sample_workers.py` — fake worker data for testing (replace with real DB data later)
- `matching_engine.py` — core scoring logic, run this to test
- `matching_api.py` — FastAPI endpoint (`POST /match`)
- `demo.py` — clean, presentation-ready script for the SIH demo

**Run it:**
```bash
cd worker_matching
pip install fastapi uvicorn --break-system-packages
python3 matching_engine.py
python3 -m uvicorn matching_api:app --reload --port 8003
```
Test at `http://localhost:8003/docs`

**Tested result:** All 10 official categories verified via live API
calls, correct ranking confirmed, clean 404 returned when no worker
is available.

---

## 3. worker_Reliability_Score/

**What it does:** Calculates a 0-100 reliability score for a worker
based on factors like on-time arrival, job completion rate, customer
feedback, and cancellation rate. Helps customers choose dependable
workers and helps the federation admin monitor worker quality.

**Status:** Built and tested by teammate.

---

## 4. fairPriceEstimation_AI_model/

**What it does:** Estimates a fair price for a booking, factoring in
demand forecasting for the area and service type, so customers see a
transparent price before confirming a booking.

**Status:** Built and tested by teammate.

---

## 5. support_chatbot/

**What it does:** FAQ-style support chatbot for both customer and worker
apps. Supports Hindi and English. Helps with common questions — booking
help, order status, raising complaints, profile setup, and general app
usage.

**Structure:**
- `gig_support_chatbot/` — core chatbot logic
- `demo/` — interactive demo pages to test the chatbot in a browser
- `tests/` — test cases
- `run_server.py` — starts the chatbot server
- `pyproject.toml`, `setup.py` — project/package configuration

**Run it:**
```bash
cd support_chatbot
python3 run_server.py
```
Server runs at `http://127.0.0.1:8080/`

**Demo pages (open in browser once server is running):**
- Interactive playground: `http://127.0.0.1:8080/demo/index.html`
- Customer app demo: `http://127.0.0.1:8080/demo/customer_app_demo.html`
- Worker app demo: `http://127.0.0.1:8080/demo/worker_app_demo.html`

**Tested result:** Server runs successfully, all three demo pages load
and respond.

---

## Notes for the Backend Team

- Each feature currently runs on its own local port during development
  (service_discovery: 8002, worker_matching: 8003, support_chatbot: 8080).
  Before final integration, these will be combined into one deployed
  service with a single public URL.
- Every folder is self-contained — its own dependencies, its own README
  section above. You can run and test any feature independently.
- Once deployed (Render/Railway), only one base URL will be shared —
  no need to track multiple ports or files.

## Next Steps

- [ ] Combine all five services into a single deployable app
- [ ] Deploy to Render/Railway and share one public URL with backend team
- [ ] Prepare final demo flow for SIH internal hackathon presentation
