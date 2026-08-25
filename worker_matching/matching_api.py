"""
Worker-Customer Matching API (SIH26089)
--------------------------------------------
Exposes the matching engine as a REST endpoint so the backend/app team
can call it directly when a customer requests a service.

Run:
    python3 -m uvicorn matching_api.py --reload --port 8003
    (or: python3 -m uvicorn matching_api:app --reload --port 8003)
Test at: http://localhost:8003/docs
"""

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Optional
from matching_engine import find_best_workers
from sample_workers import SAMPLE_WORKERS

app = FastAPI(title="Worker-Customer Matching API", version="1.0")


class WorkerIn(BaseModel):
    id: str
    name: str
    skill: str
    lat: float
    lon: float
    rating: float
    completion_rate: float
    avg_response_min: float
    is_available: bool


class MatchRequest(BaseModel):
    customer_lat: float
    customer_lon: float
    required_skill: str
    top_n: int = 5
    # If the backend doesn't send real workers yet, we fall back to sample data
    workers: Optional[List[WorkerIn]] = None


@app.get("/")
def health_check():
    return {"status": "Worker Matching API running", "sample_workers_loaded": len(SAMPLE_WORKERS)}


@app.post("/match")
def get_matches(req: MatchRequest):
    if req.workers:
        workers = [w.dict() for w in req.workers]
    else:
        workers = SAMPLE_WORKERS  # use sample data for demo/testing

    matches = find_best_workers(workers, req.customer_lat, req.customer_lon,
                                 req.required_skill, req.top_n)

    if not matches:
        raise HTTPException(status_code=404, detail=f"No available {req.required_skill} found nearby.")

    return {
        "required_skill": req.required_skill,
        "matches_found": len(matches),
        "matches": matches,
    }
