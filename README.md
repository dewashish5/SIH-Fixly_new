# SIH26089 — AI/ML Layer
Cooperative Gig Services Platform for Household & Community Services

This repo contains all AI/ML features for the project. Each feature has
its own folder, built as an independent microservice. The backend team
can call these directly once deployed.

## Team

- Nikhil  — Worker-Customer Matching, Service Discovery Helper
- Meenakshi — Support Chatbot

## Folder Structure

```
SIH-2026-Ai-Ml/
├── service_discovery/     - identifies which service a customer needs from free text
├── worker_matching/       - ranks the best available worker for a job
├── support_chatbot/       - FAQ-style support chatbot (Hindi + English)
└── README.md
```

## Status

| Feature | Status | Owner |
|---|---|---|
| Worker-Customer Matching | Done, tested | Nikhil |
| Service Discovery Helper | Not started | - |
| Support Chatbot | Done, tested | Meenakshi |
| Worker Reliability Score | Not started | - |
| Fair Price Estimation | Not started | - |

---

## 1. service_discovery/

**What it does:** Customer types their problem in plain words (e.g.
"fridge nahi chal raha") and the model predicts which service category
they need (Electrician, Plumber, Carpenter, Painter, Cleaning, Caregiving).

**How it works:** TF-IDF + a trained classifier (Naive Bayes / Linear SVM).

**Files:**
- `training_data.csv` — example customer complaints labeled by category
- `train_classifier.py` — trains the model, run this first
- `service_classifier.pkl`, `vectorizer.pkl` — saved trained model
- `discovery_api.py` — FastAPI endpoint (`POST /discover`)

**Run it:**
```bash
cd service_discovery
pip install pandas scikit-learn joblib fastapi uvicorn --break-system-packages
python3 train_classifier.py
python3 -m uvicorn discovery_api:app --reload --port 8002
```
Test at `http://localhost:8002/docs`

**Tested result:** 78.95% accuracy on held-out data, correctly classified
6/6 new unseen test messages.

---

## 2. worker_matching/

**What it does:** Given a customer's location and required skill, ranks
the best available workers — not just the nearest one. Considers skill
match, distance, rating, completion rate, and response time.

**Files:**
- `sample_workers.py` — fake worker data for testing (replace with real DB data later)
- `matching_engine.py` — core scoring logic, run this to test
- `matching_api.py` — FastAPI endpoint (`POST /match`)

**Run it:**
```bash
cd worker_matching
pip install fastapi uvicorn --break-system-packages
python3 matching_engine.py
python3 -m uvicorn matching_api:app --reload --port 8003
```
Test at `http://localhost:8003/docs`

**Tested result:** Verified with 3 test cases — health check, successful
match with correct ranking, and clean 404 when no worker is available.

---

## 3. support_chatbot/

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

- [ ] Build Worker Reliability Score (Nikhil)
- [ ] Build Fair Price Estimation (Nikhil)
- [ ] Combine all services into a single deployable app
- [ ] Deploy to Render/Railway and share one public URL with backend team
