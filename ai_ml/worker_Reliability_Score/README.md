# AI Model for Worker Reliability Score (Gig Worker Platform)

An independent, modular AI scoring engine that computes an explainable **Worker Reliability Score (0–100)** to help customers choose top-performing partners and empower platform admins to monitor service quality.

---

## 🌟 5 Core Reliability Pillars

| Pillar | Weight | Description |
| :--- | :---: | :--- |
| ⏱️ **On-Time Arrival Rate** | **25%** | Percentage of jobs where partner arrived within scheduled window |
| ✅ **Job Completion Rate** | **25%** | Successfully closed jobs verified via OTP and dispute-free |
| ⭐ **Customer Feedback Score** | **20%** | Normalized 5-star customer rating, review sentiment & tips |
| 🚫 **Cancellation Resistance** | **15%** | Reliability against worker-initiated cancellations (late cancel penalty) |
| ⚡ **Lead Response Speed** | **15%** | Acceptance latency for incoming dispatch leads (within 45s SLA) |

---

## 🚀 Quickstart

### 1. Run Automated Test Suite
`powershell
py tests/run_all_tests.py
`

### 2. Launch Standalone API & Interactive Dual Dashboard
`powershell
py run_server.py --port 8082
`
Open:
- 👤 **Customer & Admin Interactive Dashboard**: [http://127.0.0.1:8082/demo/index.html](http://127.0.0.1:8082/demo/index.html)
- 🏆 **Leaderboard API**: [http://127.0.0.1:8082/api/workers/leaderboard](http://127.0.0.1:8082/api/workers/leaderboard)
- 🩺 **Admin Quality Summary**: [http://127.0.0.1:8082/api/admin/quality-summary](http://127.0.0.1:8082/api/admin/quality-summary)

---

## 🐍 Python SDK Integration Example

`python
from gig_worker_reliability import ReliabilityEngine, JobRecord, JobStatus
import time

engine = ReliabilityEngine(half_life_days=30.0)

# Historical or recent jobs
jobs = [
    JobRecord(
        job_id="JB-101",
        worker_id="WRK-1001",
        service_category="electrical",
        scheduled_timestamp=time.time() - 3600,
        arrival_timestamp=time.time() - 3600,
        is_on_time=True,
        response_time_seconds=18.0,
        status=JobStatus.COMPLETED,
        customer_rating=5.0,
        tip_received=True,
    )
]

# Calculate Reliability Report
report = engine.compute_reliability("WRK-1001", jobs)

print(f"Score: {report.overall_score}/100 ({report.tier.value})")
print(report.summary_text)
# Output: "96/100 - On-time 100%, Completion 100%, Feedback 100%, Cancellation 100%, Response time 100%"
`

---

## 🌐 REST API Endpoints

### 1. GET /api/worker/{worker_id}/score
**Response:**
`json
{
  "worker_id": "WRK-1001",
  "name": "Rajesh Kumar",
  "reliability_report": {
    "overall_score": 96,
    "tier": "elite",
    "tier_label": "Elite",
    "summary_text": "96/100 - On-time 100%, Completion 100%, Feedback 100%, Cancellation 100%, Response time 97%",
    "sub_scores": {
      "on_time_arrival_rate": 100.0,
      "job_completion_rate": 100.0,
      "customer_feedback_score": 100.0,
      "cancellation_resistance": 100.0,
      "response_time_score": 97.5
    },
    "badges": ["⏱️ Punctuality Master", "🏆 99% Completion", "⭐ Top Rated Partner", "⚡ Rapid Responder"],
    "total_jobs_evaluated": 25
  }
}
`

### 2. POST /api/job/event (Auto-recalculate score after each job)
**Request Body:**
`json
{
  "worker_id": "WRK-1004",
  "service_category": "plumbing",
  "status": "completed",
  "is_on_time": true,
  "customer_rating": 5.0,
  "response_time_seconds": 19.0
}
`
