# FairPrice AI — Pre-Booking Fair Price Estimation Engine

A machine-learning powered, transparent, mathematically traceable, and explainable **Pre-Booking Fair Price Estimation Engine** for gig community platforms.

---

## 🏛️ Technical Architecture

FairPrice AI unifies transparent statutory economics with machine learning intelligence and deterministic ethical guardrails:

```text
                        ┌──────────────────────────────┐
                        │      CUSTOMER REQUEST        │
                        │ (Service, Pincode, Urgency)  │
                        └──────────────┬───────────────┘
                                       │
                                       ▼
                        ┌──────────────────────────────┐
                        │  1. INPUT VALIDATION LAYER   │
                        │ (Strict Schema & Type Audit) │
                        └──────────────┬───────────────┘
                                       │
                        ┌──────────────┴───────────────┐
                        ▼                              ▼
          ┌───────────────────────────┐  ┌───────────────────────────┐
          │  DETERMINISTIC STATUTORY  │  │  STRUCTURAL CITY-TIER     │
          │  BASELINE FORMULA (Labour)│  │  COST FACTOR (7th CPC)    │
          │ Base = (Wage×1.8×Dur)÷0.85│  │ Tier X: 1.30x / Y: 1.15x  │
          └─────────────┬─────────────┘  └─────────────┬─────────────┘
                        │                              │
                        └──────────────┬───────────────┘
                                       │
                                       ▼
                        ┌──────────────────────────────┐
                        │ 2. ML MARKET INTELLIGENCE    │
                        │   GradientBoostingRegressor  │
                        │ (12 Features, R² = 0.9977)   │
                        └──────────────┬───────────────┘
                                       │
                                       ▼
                        ┌──────────────────────────────┐
                        │ 3. DYNAMIC SURGE & DISPATCH  │
                        │   Area Demand (0.90x-1.55x)  │
                        │   Emergency SOS (+₹100/1.35x)│
                        │   Travel Fee (>2.5km @ ₹15)  │
                        └──────────────┬───────────────┘
                                       │
                                       ▼
                        ┌──────────────────────────────┐
                        │ 4. DETERMINISTIC FAIRNESS    │
                        │    GUARDRAILS & AUDIT        │
                        │ • 1.60x Anti-Gouging Cap     │
                        │ • Statutory Wage Floor Guard │
                        │ • Exact 15% Platform Split   │
                        └──────────────┬───────────────┘
                                       │
                                       ▼
                        ┌──────────────────────────────┐
                        │ 5. FINAL PRE-BOOKING PRICE   │
                        │   + Transparent Breakdown    │
                        │   + "Why this price?" Trace  │
                        └──────────────────────────────┘
```

---

## ⚖️ Component Roles: Formula vs ML vs Guardrails

| Layer | Type | Role | Guarantees |
|---|---|---|---|
| **Statutory Baseline** | Deterministic Formula | Establishes economic baseline from statutory hourly wages | No arbitrary pricing |
| **City-Tier Scaling** | Rule-based Index | Adjusts base prices for metropolitan cost of living (X/Y/Z) | Separated from demand spikes |
| **ML Regressor** | Machine Learning | Evaluates multi-factor market dynamics and elasticity bounds | High-speed, data-driven clearing |
| **Fairness Guardrails** | Deterministic Constraints | Clamps price gouging and enforces statutory worker wage floors | Worker living wage protection |
| **Explainability Engine** | Dynamic Generator | Generates line-by-line mathematical trace for customers and judges | 100% Zero hidden charges |

---

## 📊 Statutory Formula & Commission Standards

$$\text{Baseline Price} = \frac{\text{Government Minimum Wage} \times 1.8 \times \text{Duration (hours)}}{1 - \text{Platform Commission Rate}}$$

### 1. Statutory Skill Wage Floors (Ministry of Labour, Central Sphere)
* **Semi-Skilled (`standard`)**: **₹108 / hr** (Cleaning, Domestic Helper, Basic Tap Repair, Pest Control)
* **Skilled (`skilled`)**: **₹119 / hr** (Sanitary Fitting, MCB Repair, Washing Machine Diagnosis, Carpentry)
* **Highly Skilled (`master`)**: **₹129 / hr** (Water Motor Pipeline, House Wiring, AC Brazing)

### 2. Platform Commission & Revenue Split
* **Platform Commission**: **15%** (`0.15`)
* **Guaranteed Worker Payout**: **85%** (`0.85`)
* Zero hardcoded 20% or 0.80 commission values.

### 3. Pan-India City Tiers (7th CPC HRA Framework)
* **Tier X (Metro)**: **1.30×** (Bengaluru, Delhi NCR, Mumbai, Chennai, Kolkata, Hyderabad, Pune, Ahmedabad)
* **Tier Y (Large Cities)**: **1.15×** (Jaipur, Lucknow, Indore, Nagpur, Surat, Kochi, Chandigarh, Bhopal, Patna, etc.)
* **Tier Z (All Other Regions)**: **1.00×** (Standard base pricing fallback for unmapped pin codes)

---

## 🤖 Real Machine Learning Model Evaluation

Evaluated on a 20% holdout test set (1,000 samples) in [`reports/model_evaluation.json`](file:///c:/Users/meenakshi.p.konar/Documents/fairprice/fairPriceEstimation_AI_model/reports/model_evaluation.json):

* **Algorithm**: Scikit-Learn `GradientBoostingRegressor` (120 Estimators, Max Depth 4)
* **Feature Count**: 12 Features (with strict training/inference parity)
* **$R^2$ Score**: **0.9977**
* **Mean Absolute Error (MAE)**: **₹13.80**
* **Root Mean Squared Error (RMSE)**: **₹20.00**
* **Mean Absolute Percentage Error (MAPE)**: **2.10%**

---

## 🚀 Quickstart & Verification

### 1. Run Automated Test Suite (55 Tests)
```powershell
py tests/run_all_tests.py
```
Or run pytest directly:
```powershell
py -m pytest -v
```

### 2. Retrain ML Model & Generate Evaluation Report
```powershell
py -m gig_fair_pricing.ml.train
```

### 3. Launch Standalone API & Interactive Demo Server
```powershell
py run_server.py --port 8081
```
Then open:
* 🎛️ **Customer Booking Simulator**: [http://127.0.0.1:8081/demo/index.html](http://127.0.0.1:8081/demo/index.html)
* 🩺 **API Health Check**: [http://127.0.0.1:8081/api/health](http://127.0.0.1:8081/api/health)
* 📋 **Service Catalog**: [http://127.0.0.1:8081/api/services](http://127.0.0.1:8081/api/services)
* ⚡ **1-Click Judge Scenarios JSON**: [http://127.0.0.1:8081/api/demo-scenarios](http://127.0.0.1:8081/api/demo-scenarios)

---

## 📚 Hackathon Documentation
* 🎙️ **[Live Demo Script (3–5 Min)](file:///c:/Users/meenakshi.p.konar/Documents/fairprice/fairPriceEstimation_AI_model/docs/demo_script.md)**: Structured walkthrough for pitching to hackathon judges.
* ❓ **[Judge FAQ (20 Questions)](file:///c:/Users/meenakshi.p.konar/Documents/fairprice/fairPriceEstimation_AI_model/docs/judge_faq.md)**: Fact-based technical and economic answers.
