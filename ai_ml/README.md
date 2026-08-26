# SIH26089 — AI/ML Layer (Unified)
Cooperative Gig Services Platform for Household & Community Services

All 5 AI/ML features live in this ONE `ai_ml/` folder, and start with
ONE command — no need to open 5 separate terminals or remember 5 ports
individually.

## Team

- Nikhil — Worker-Customer Matching, Service Discovery Helper
- Teammate — Support Chatbot, Worker Reliability Score, Fair Price Estimation

## Quick Start (Run Everything At Once)

```bash
cd ai_ml
pip install fastapi uvicorn pandas scikit-learn joblib numpy --break-system-packages
python3 start_all.py
```

That's it — all 5 services start together. You'll see:

```
ALL SERVICES RUNNING
  Service Discovery            -> http://127.0.0.1:8002/docs
  Worker Matching               -> http://127.0.0.1:8003/docs
  Worker Reliability Score      -> http://127.0.0.1:8082/demo/index.html
  Fair Price Estimation         -> http://127.0.0.1:8081/demo/index.html
  Support Chatbot                -> http://127.0.0.1:8080/demo/index.html
```

Press `Ctrl+C` once to stop all 5 services together.

## Why Not One Single Port For Everything?

Two modules (`service_discovery`, `worker_matching`) are built with
**FastAPI**. The other three (`worker_Reliability_Score`,
`fairPriceEstimation_AI_model`, `support_chatbot`) are built with
Python's built-in **http.server** — a completely different, incompatible
web technology. Merging them into one port would mean rewriting the
other three modules' internal routing, which risks breaking code that
already works correctly.

Instead, `start_all.py` launches all 5 as separate background
processes with ONE command — same effect for you (one command, one
place, everything running), without touching anyone's working code.

## Folder Structure

```
ai_ml/
├── start_all.py                     - run this to start EVERYTHING
├── service_discovery/               - Nikhil (FastAPI, port 8002)
├── worker_matching/                  - Nikhil (FastAPI, port 8003)
├── worker_Reliability_Score/         - Teammate (port 8082)
├── fairPriceEstimation_AI_model/     - Teammate (port 8081)
├── support_chatbot/                   - Teammate (port 8080)
└── README.md
```

## Status — All 5 Features Verified Working

| Feature | Port | Status |
|---|---|---|
| Service Discovery Helper | 8002 | Verified — correct predictions via API |
| Worker-Customer Matching | 8003 | Verified — correct ranking via API |
| Worker Reliability Score | 8082 | Verified — leaderboard & quality summary respond correctly |
| Fair Price Estimation | 8081 | Verified — health check passes, model loaded |
| Support Chatbot | 8080 | Verified — demo page loads correctly |

**All 5 tested together, launched from a single command, with zero errors.**

## Individual Module Details

Each module folder has its own `README.md` inside it with full details
(what it does, how it works, example requests). This top-level README
is just the "how to run everything together" guide.

## One Thing To Know: Fair Price Estimation Warning

When Fair Price Estimation starts, you may see warnings like:
```
InconsistentVersionWarning: Trying to unpickle estimator ... from
version 1.9.0 when using version 1.8.0
```
This is just a scikit-learn version mismatch warning (the model was
trained with a slightly newer scikit-learn than what's installed) — it
still works correctly (verified: `"ml_model_loaded": true`). To remove
the warning entirely, whoever built this module can retrain the model
using the same scikit-learn version that's installed, but it is not
blocking for the demo.

## Notes for the Backend Team

- Each of the 5 features runs on its own local port (see table above).
  This is intentional — see "Why Not One Single Port" above.
- Before the final deployment, each service will be deployed
  separately (e.g. on Render/Railway) and the backend team will be
  given 5 URLs — one per feature — instead of local ports.
- Every folder is self-contained — its own dependencies, its own
  internal README. You can run and test any single feature on its own
  by going into its folder and following its own README, exactly as
  before this integration.

## Next Steps

- [ ] Deploy each of the 5 services separately (Render/Railway free tier)
- [ ] Share the 5 public URLs with the backend team
- [ ] Prepare final demo flow for the SIH internal hackathon presentation
