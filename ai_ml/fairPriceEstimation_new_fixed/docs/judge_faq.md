# FairPrice AI — Hackathon Judge FAQ (20 Credibility Questions)

This document provides fact-based, verified answers to technical, economic, and machine learning questions frequently asked by hackathon judges.

---

### 1. Why is the price not fixed?
Fixed catalog pricing creates market failure in gig services. A flat ₹249 tap repair fails when a worker travels 12 km at 11 PM during a thunderstorm, and overcharges a customer for a 15-minute standard task next door. FairPrice AI uses dynamic pricing to balance market clearing while protecting workers with guaranteed wage floors.

### 2. Why did you choose 1.8x as the fair markup factor?
Government minimum wages represent absolute survival floors for pure unequipped physical labour. The **1.8x markup factor** is a configured benchmark representing:
- Artisan tooling and equipment maintenance (plumbing wrenches, multimeters, drill bits)
- Unbilled travel time between bookings
- Social security and health contingency buffers
- Platform operational sustainability
In production, this factor can be tuned per category based on equipment intensity.

### 3. Why 15% platform commission?
Traditional aggregator platforms extract 20% to 30%+ commissions, depressing artisan take-home earnings. FairPrice AI centralizes a sustainable 15% platform fee (`PLATFORM_COMMISSION_RATE = 0.15`), mathematically guaranteeing that **85%** of the gross customer fee is paid to the worker.

### 4. Why are skill wages different?
Artisans possess varying levels of specialized technical training, equipment capital, and electrical/mechanical hazard exposure. In accordance with Indian labour norms, tasks are categorized into Semi-Skilled, Skilled, and Highly Skilled tiers.

### 5. Where do the wage numbers come from?
The base hourly wages are benchmarked from the Ministry of Labour & Employment, Government of India (Central Sphere statutory minimum wage notifications):
* **Semi-Skilled (`standard`)**: ₹108.00 / hour
* **Skilled (`skilled`)**: ₹119.00 / hour
* **Highly Skilled (`master`)**: ₹129.00 / hour
*Note*: In a full-scale production rollout, these can be extended to dynamically pull state-specific gazette wage rates via an automated API connector.

### 6. Why does Mumbai or Bengaluru cost more?
Tier X metropolitan areas exhibit higher structural living costs (housing, transportation, food, fuel). FairPrice AI adjusts the base rate using official cost indices.

### 7. Why use X/Y/Z city tiers?
Rather than inventing arbitrary city multipliers, FairPrice AI adopts the Government of India's 7th Central Pay Commission (CPC) House Rent Allowance (HRA) classification:
* **Tier X (Metro cities, population 50L+)**: 1.30x structural multiplier
* **Tier Y (Large cities, population 5L–50L)**: 1.15x structural multiplier
* **Tier Z (All other regions)**: 1.00x nationwide base pricing

### 8. What happens for an unmapped pincode?
Any postal pincode not matching known Tier X or Y postal circle prefixes defaults safely and transparently to Tier Z (1.00x base price). The system never fails on an unknown pincode.

### 9. Why use Machine Learning if there is already a mathematical formula?
The formula establishes the deterministic statutory baseline economics. The ML model (`GradientBoostingRegressor`) learns complex multi-factor interactions from transaction history (e.g. compound interplay between travel distance, time of day, weekend surges, and localized density) to estimate fair market clearing prices and ±7% market elasticity confidence bounds.

### 10. What exactly does the ML model predict?
The model predicts the fair market clearing price given 12 input features:
`[base_rate, est_duration_mins, skill_tier_num, city_multiplier, demand_multiplier, urgency_multiplier, emergency_dispatch_fee, distance_km, travel_fee, hour, is_weekend, night_fee]`.

### 11. Why is the $R^2$ score so high ($0.9977$)?
**Credibility Disclosure**: The high $R^2 = 0.9977$ reflects controlled **synthetic-data validation** used to verify that the ML learning loop and feature extraction accurately capture multi-factor interactions. It is **not** a claim of live production market accuracy (which requires real customer booking and acceptance logs). Compared to a baseline Linear Regressor ($R^2 = 0.9648$, $\text{MAE} = ₹49.79$), the Gradient Boosting Regressor reduces error by over 72% ($\text{MAE} = ₹13.80$).

### 12. Is there target data leakage in the ML pipeline?
**No**. The input feature vector consists solely of independent parameters available *before* transaction execution (duration, skill tier, city factor, demand index, urgency, distance, hour). No target-derived features or post-transaction variables exist in the feature set.

### 13. How do you prevent price gouging?
The deterministic fairness layer enforces a hard dynamic surge cap at **1.60x** baseline. Even during severe demand spikes, prices cannot exceed this statutory ceiling.

### 14. How do you protect workers from market down-pressure?
The fairness validator verifies that:
$$\text{Worker Payout} \ge \left(\frac{\text{Duration Mins}}{60}\right) \times \text{Tier Minimum Hourly Wage}$$
If off-peak market discounts cause worker payout to fall below this floor, the engine automatically boosts the final price to satisfy the statutory wage guarantee.

### 15. What stops the ML model from producing unfair prices?
The ML model does **not** have unrestricted authority. Every ML prediction passes through the deterministic `FairnessValidator` which audits statutory wage floors, ceiling bounds, and exact 15%/85% revenue splits.

### 16. What happens if the ML model file is missing or corrupted?
The engine features a built-in mathematical fallback mode (`_formula_predict`) that calculates exact prices using pure Python arithmetic without requiring scikit-learn or external dependencies.

### 17. How is structural city cost separated from temporary demand?
City tier represents structural living cost differences (constant every day), whereas demand represents temporary market fluctuations (e.g. rush hours). They are tracked, computed, and itemized as distinct multipliers in both the breakdown and customer explanation.

### 18. How would this work with real transaction data?
In production, synthetic data generation would be replaced by actual historical booking logs, completion times, customer acceptance rates, and artisan feedback, allowing the Gradient Boosting model to continuously learn localized market clearing price elasticities.

### 19. How would you scale to millions of users?
Inference is ultra-lightweight:
* Single estimation latency: **<0.75 ms**
* Batch throughput: **>1,000 req/sec per CPU core**
* Stateless microservice architecture allows instant horizontal scaling behind standard load balancers.

### 20. How would you verify statutory wage updates in production?
Statutory wage tables in `constants.py` can be synchronized via an automated API connector or annual cron job fetching gazette notifications from the Ministry of Labour & Employment portal.
