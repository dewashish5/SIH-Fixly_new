# FairPrice AI — 1-Slide Technical Summary

---

## 📌 Problem Statement
Traditional household and gig service platforms in India rely on **arbitrary fixed catalog prices** (e.g. ₹249 for tap repair) and extract **opaque 20–30%+ platform cuts**. Workers face volatile, unprotected earnings, while customers experience unexplainable surge pricing.

---

## 💡 Solution: Transparent Economics + ML Intelligence + Rule-Based Guardrails
FairPrice AI establishes a mathematically traceable, multi-factor pricing microservice that balances artisan living wages, localized structural living costs, dynamic market demand, and customer fairness.

---

## 📐 Statutory Baseline Pricing Formula
$$\text{Baseline Price} = \frac{\text{Statutory Minimum Hourly Wage} \times 1.8 \times \text{Duration Hours}}{1 - \text{Platform Commission Rate}}$$

* **Statutory Hourly Wage Floors (Ministry of Labour, Central Sphere Benchmarks)**:
  * Semi-Skilled (`standard`): **₹108 / hr** (Cleaning, Basic Tap Repair, Pest Control)
  * Skilled (`skilled`): **₹119 / hr** (Sanitary Fitting, MCB Repair, Appliance Diagnosis)
  * Highly Skilled (`master`): **₹129 / hr** (Motor Pipeline, House Wiring, AC Brazing)
* **Fair Living Wage Markup Factor**: **1.8x** (Configured benchmark covering artisan tooling, travel time, and social security)
* **Platform Commission**: **15%** (`0.15`) | **Worker Payout Guarantee**: **85%** (`0.85`)

---

## 🌐 Dynamic Multi-Factor Pipeline

```text
Statutory Formula Baseline (₹)
        ↓
City-Tier Structural Factor (7th CPC HRA: Tier X 1.30x Metro | Tier Y 1.15x Large City | Tier Z 1.00x Base)
        ↓
ML Market Regressor (Gradient Boosting on 12 Features with ±7% Elasticity Bounds)
        ↓
Dynamic Demand Surge (0.90x – 1.55x) + Urgency Mode (Emergency SOS 1.35x + ₹100 dispatch bonus)
        ↓
Travel Compensation (>2.5 km @ ₹15/km) + Nocturnal Allowance (10 PM – 6 AM @ +₹80)
        ↓
Deterministic Fairness Guardrails (1.60x Anti-Gouging Surge Cap & Statutory Minimum Wage Floor)
        ↓
Final Itemized Price & "Why this price?" Trace
```

---

## 🤖 ML Regressor & Validation Methodology
* **Algorithm**: Scikit-Learn `GradientBoostingRegressor` (120 Estimators, Max Depth 4)
* **Feature Schema (12 Features)**: `[base_rate, est_duration_mins, skill_tier_num, city_multiplier, demand_multiplier, urgency_multiplier, emergency_dispatch_fee, distance_km, travel_fee, hour, is_weekend, night_fee]`
* **Validation Methodology**: Controlled synthetic market transaction simulation (5,000 transactions, 80/20 train/test split)
* **Comparative Performance**:
  * Baseline Linear Regressor: $R^2 = 0.9648$, $\text{MAE} = ₹49.79$, $\text{MAPE} = 8.23\%$
  * GradientBoostingRegressor: $R^2 = 0.9977$, $\text{MAE} = ₹13.80$, $\text{RMSE} = ₹20.00$, $\text{MAPE} = 2.10\%$

---

## 🛡️ Deterministic Fairness Guarantees
1. **Statutory Wage Floor Guard**: Worker payout mathematically cannot drop below $\text{Duration} \times \text{Statutory Wage Floor}$.
2. **Anti-Price-Gouging Cap**: Dynamic surges are strictly clamped at a maximum **1.60x** baseline ceiling.
3. **100% Mathematical Traceability**: Every price exposes an itemized step-by-step breakdown explaining exact revenue splits and multipliers.
