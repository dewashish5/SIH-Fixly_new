# FairPrice AI — 1-Page Team Cheat Sheet

> *Read this in 2 minutes before going on stage or answering judges.*

---

## 🚀 The 30-Second Elevator Pitch
> *"Traditional gig service platforms rely on arbitrary fixed pricing (like ₹249 for tap repair) and extract high 20–30% opaque commissions. FairPrice AI uses statutory labour economics, city-tier cost indices, and machine learning to calculate transparent pre-booking prices while guaranteeing that the worker earns a legal living wage and the customer is protected by anti-gouging caps."*

---

## 🔑 Core Facts to Memorize

* **The Formula**:
  $$\text{Baseline Price} = \frac{\text{Statutory Wage} \times 1.8 \times \text{Duration Hours}}{0.85}$$
* **The 3 Skill Wage Floors (Ministry of Labour Benchmarks)**:
  * **Semi-Skilled (`standard`)**: **₹108 / hr** (Cleaning, Basic Tap Repair, Pest Control)
  * **Skilled (`skilled`)**: **₹119 / hr** (Sanitary Fitting, MCB Diagnosis, Appliance Repair)
  * **Highly Skilled (`master`)**: **₹129 / hr** (Water Motor Pipeline, House Wiring, AC Gas Brazing)
* **The Revenue Split**:
  * **Platform Commission**: Fixed at **15%** (`0.15`)
  * **Worker Guaranteed Take-Home**: Fixed at **85%** (`0.85`)
* **City Tiers (7th Central Pay Commission HRA)**:
  * **Tier X (Metro)**: **1.30×** (Bengaluru, Delhi NCR, Mumbai, Pune, Chennai, etc.)
  * **Tier Y (Large City)**: **1.15×** (Jaipur, Lucknow, Indore, Kochi, Chandigarh, etc.)
  * **Tier Z (Base)**: **1.00×** (Standard towns and all unmapped pin codes)
* **City vs Demand**:
  * **City Multiplier** = Structural cost of living (*where* the job is).
  * **Demand Surge** = Temporary rush hour (*when* the job is). They are completely separate.
* **The Machine Learning Model**:
  * Scikit-Learn `GradientBoostingRegressor` on 12 features ($R^2 = 0.9977$, $\text{MAE} = ₹13.80$).
  * Outperforms baseline Linear Regression by **72.3% lower error** by learning non-linear compound interactions (night shift + travel + emergency mode).
* **The Guardrails**:
  * **Anti-Price-Gouging Surge Ceiling**: Clamped at **1.60x** of the structural baseline price.
  * **Worker Living Wage Floor**: Worker payout cannot fall below $\text{Duration} \times \text{Statutory Wage Floor}$.
* **Test Suite**:
  * **57 / 57 tests passing (100%)**, **87% code coverage**, **<0.75 ms latency**.

---

## ⚡ 3-Minute Live Demo Script Summary

1. **Step 1 — Baseline (Tier Z)**: Click **Scenario A**. Show Tap Repair = **₹171.53** ($\frac{108 \times 1.8 \times 0.75}{0.85}$).
2. **Step 2 — Metro Cost (Tier X)**: Click **Scenario B**. Show same job in Bengaluru = **₹222.99** ($171.53 \times 1.30$).
3. **Step 3 — Demand Surge**: Click **Scenario C**. Show 1.35x surge = **₹301.04** (City and Demand stay separate).
4. **Step 4 — Skill Level**: Click **Scenario D**. Show MCB repair = **₹327.60** (₹119/hr skilled wage floor).
5. **Step 5 — Emergency SOS**: Click **Scenario E**. Show Emergency SOS = **₹542.26** (1.35x + ₹100 dispatch bonus).
6. **Step 6 — Wage Floor Guard**: Click **Scenario F**. Show that low demand still guarantees the legal wage floor.
7. **Step 7 — The Climax**: Open **"Why this price?"** and click **"Compare Models"** to show 100% itemized transparency.

---

## 🛡️ Top 3 Judge Defenses

* **If asked "Why is R² so high (0.9977)?":**
  > *"It was measured on a controlled synthetic validation dataset to test feature interactions and the learning loop. We do not claim live real-world accuracy without production transaction logs."*
* **If asked "What stops AI from overcharging?":**
  > *"The ML model is constrained by deterministic fairness guardrails. Surges are capped at 1.60x structural baseline."*
* **If asked "Why 1.8x markup?":**
  > *"It is a configured economic benchmark covering artisan equipment depreciation, travel time, and social security buffers."*
