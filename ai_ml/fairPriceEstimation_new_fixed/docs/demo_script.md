# FairPrice AI — Hackathon Live Demo Script (3–5 Minutes)

This script provides a concise, step-by-step walkthrough for presenting FairPrice AI to hackathon judges.

---

## ⏱️ Timeline & Pitch Flow

### 0:00 – 0:45: The Problem & Vision
* **Pitch**:
  > *"Household gig service platforms in India often rely on arbitrary, hardcoded pricing (e.g., ₹249 for a tap repair) and take high, opaque commissions (20–30%). Workers suffer from unpredictable incomes, while customers face hidden surge pricing without explanation."*
* **Solution**:
  > *"FairPrice AI solves this by unifying statutory labour economics with dynamic machine learning and deterministic ethical guardrails. Every rupee is mathematically traceable."*

---

### 0:45 – 1:30: The Programmatic Statutory Baseline
* **Action**: Open the simulator at `http://127.0.0.1:8081/demo/index.html`.
* **Demonstrate**: Select **Plumbing: Tap & Pipe Repair** in an unmapped/standard town (**Tier Z**, Pincode `175001`).
* **Explanation**:
  > *"Notice how the base price is NOT hardcoded. It is computed live from the statutory formula:
  $$\text{Base Price} = \frac{\text{Govt Minimum Wage} \times 1.8 \times \text{Duration (hours)}}{1 - \text{Commission Rate}}$$
  *For a Semi-Skilled task (₹108/hr, 45 minutes) with a 15% platform commission, the base price is exactly ₹171.53.*"

---

### 1:30 – 2:15: City-Tier Structural Adjustment (X/Y/Z)
* **Action**: Click **Scenario B: Metro (X)** or enter Bengaluru Pincode `560038`.
* **Demonstrate**: Observe the price change from **₹171.53** to **₹222.99** base price.
* **Explanation**:
  > *"Under the 7th Central Pay Commission HRA framework, Tier X metros have a 1.30x structural cost-of-living multiplier. Crucially, this structural cost is kept completely separate from temporary demand surges."*

---

### 2:15 – 3:00: Dynamic Demand & Emergency SOS Dispatch
* **Action**: Click **Scenario C: Surge (1.35x)** and then **Scenario E: Emergency SOS**.
* **Demonstrate**:
  - Show the dynamic demand index adding an itemized +₹30.10 demand adjustment.
  - Show Emergency SOS mode adding a transparent 1.35x surge multiplier plus a ₹100 guaranteed emergency dispatch bonus to incentivize workers.

---

### 3:00 – 3:45: Ethical AI & Wage Floor Protection
* **Action**: Click **Scenario F: Wage Floor**.
* **Demonstrate**:
  - Show that even during off-peak discounts, the fairness layer activates to guarantee that worker payout **never drops below the statutory hourly wage floor** (₹108/hr, ₹119/hr, ₹129/hr).
  - Point to the **1.60x Anti-Price-Gouging Surge Ceiling** which clamps extreme price spikes.

---

### 3:45 – 4:30: Explainability & Comparative Transparency
* **Action**:
  - Open the **"Why this price?"** section to show the step-by-step mathematical trace.
  - Click **"Compare Models"** to show the side-by-side comparison table between legacy arbitrary pricing and FairPrice AI.
* **Conclusion**:
  > *"FairPrice AI provides 100% transparency for the customer, guaranteed fair earnings for the artisan, and sustainable 15% economics for the platform."*
