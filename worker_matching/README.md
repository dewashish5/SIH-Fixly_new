# Worker-Customer Matching — SIH26089

Ranks available workers for a customer's service request using 5 factors,
instead of just picking the nearest one. Covers all 10 official service
categories from the problem statement.

## The 10 Official Service Categories

Electrician, Plumber, Carpenter, Painter, Cleaning, Domestic Helper,
Caregiving, Gardener, Driver, Technician.

## Files

| File | What it does |
|---|---|
| `sample_workers.py` | Fake worker data covering all 10 categories (replace with real DB data later) |
| `matching_engine.py` | The core scoring logic — run this directly to test |
| `matching_api.py` | FastAPI wrapper so the backend team can call this over REST |
| `demo.py` | Clean, presentation-ready script — use this for the SIH demo |

## How the score works

Each worker gets a score out of 100, built from:

| Factor | Weight | What it measures |
|---|---|---|
| Skill match | 25% | Does the worker do this exact job? (Workers with the wrong skill are excluded entirely) |
| Proximity | 25% | How close is the worker to the customer? |
| Rating | 20% | Worker's average rating out of 5 |
| Completion rate | 15% | Percent of accepted jobs the worker actually finished |
| Response time | 15% | How quickly the worker usually responds |

Unavailable workers are automatically excluded before scoring.

## Setup (run once)

```bash
pip install fastapi uvicorn --break-system-packages
python3 matching_engine.py     # sanity check
```

## Run the professional demo (use this for SIH judging)

```bash
python3 demo.py
```

## Run the API

```bash
python3 -m uvicorn matching_api:app --reload --port 8003
```

Open `http://localhost:8003/docs` for the interactive Swagger UI.

## Example request (for the backend team)

```
POST /match
{
  "customer_lat": 28.61,
  "customer_lon": 77.21,
  "required_skill": "Electrician",
  "top_n": 5
}
```

## Verified working (tested by Claude before handing off)

Every one of the 10 official categories was tested end-to-end through
the live API:

| Category | Status | Top Match | Score |
|---|---|---|---|
| Electrician | OK | Ramesh Kumar | 95.9 |
| Plumber | OK | Amit Singh | 97.4 |
| Carpenter | OK | Manoj Tiwari | 93.8 |
| Painter | OK | Ashok Mehta | 93.6 |
| Cleaning | OK | Sunita Devi | 96.9 |
| Domestic Helper | OK | Meena Kumari | 92.6 |
| Caregiving | OK | Anita Sharma | 96.2 |
| Gardener | OK | Ram Lal | 89.6 |
| Driver | OK | Sanjay Gupta | 85.3 |
| Technician | OK | Naresh Kumar | 94.0 |

**Result: 10/10 categories passed, zero errors.**

Also tested: requesting a skill with no available worker correctly
returns a clean 404 error instead of crashing.

## Tune it later

To change what matters most (e.g. make proximity matter more than
rating), edit the `WEIGHTS` dictionary at the top of `matching_engine.py`
— the numbers must add up to 1.0.
