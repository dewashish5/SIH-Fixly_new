# Worker-Customer Matching — SIH26089

Ranks available workers for a customer's service request using 6 factors,
instead of just picking the nearest one.

## Files

| File | What it does |
|---|---|
| `sample_workers.py` | Fake worker data (use this until real worker data exists in your database) |
| `matching_engine.py` | The core scoring logic — run this directly to test |
| `matching_api.py` | FastAPI wrapper so the backend team can call this over REST |

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
python3 matching_engine.py     # sanity check: prints ranked workers for a demo scenario
```

## Run the API

```bash
python3 -m uvicorn matching_api:app --reload --port 8003
```

Open `http://localhost:8003/docs` for the interactive Swagger UI — you
can test the `/match` endpoint there without writing any frontend code.

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

If you don't pass a `workers` list, it uses the built-in sample data —
useful for demos before the real database is ready. Once you have real
worker data, pass it in the request like this:

```json
{
  "customer_lat": 28.61,
  "customer_lon": 77.21,
  "required_skill": "Electrician",
  "top_n": 5,
  "workers": [
    { "id": "W1", "name": "Ramesh", "skill": "Electrician",
      "lat": 28.611, "lon": 77.211, "rating": 4.8,
      "completion_rate": 0.95, "avg_response_min": 5, "is_available": true }
  ]
}
```

## Verified working (tested by Claude before handing off)

- Health check: `GET /` returns status OK
- Match request: returns workers ranked by score, breakdown included
- No-match case: returns a clean 404 with a clear message when no worker
  has the required skill available
- Unavailable workers are correctly excluded from results

## Tune it later

If you want to change what matters most (e.g. make proximity matter
more than rating), just edit the `WEIGHTS` dictionary at the top of
`matching_engine.py` — the numbers must add up to 1.0.
