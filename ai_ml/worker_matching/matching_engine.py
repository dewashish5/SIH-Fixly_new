"""
Worker-Customer Matching Engine (SIH26089)
----------------------------------------------
Instead of just showing the NEAREST worker (like a basic Uber clone),
this ranks workers using 6 factors so the customer gets the BEST
worker for their job.

Factors used (as decided in the fixed AI/ML spec):
    1. Skill match      - does the worker do this exact job?
    2. Distance          - how close are they?
    3. Rating             - how good is their track record?
    4. Completion rate    - do they finish jobs they accept?
    5. Response time      - how fast do they usually respond?
    6. Availability       - are they free right now?

Run:
    python3 matching_engine.py
"""

import math
from sample_workers import SAMPLE_WORKERS

# ---- Tune these weights if you want to change what matters most ----
WEIGHTS = {
    "skill_match": 0.25,
    "proximity": 0.25,
    "rating": 0.20,
    "completion_rate": 0.15,
    "response_time": 0.15,
}

MAX_DISTANCE_KM = 15       # beyond this, proximity score becomes ~0
MAX_RESPONSE_MIN = 30      # beyond this, response-time score becomes ~0


def haversine_km(lat1, lon1, lat2, lon2):
    """Straight-line distance between two lat/lon points, in kilometers."""
    R = 6371
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lon2 - lon1)
    a = math.sin(dphi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2) ** 2
    return 2 * R * math.asin(math.sqrt(a))


def score_worker(worker: dict, customer_lat: float, customer_lon: float, required_skill: str):
    if not worker["is_available"]:
        return None  # skip unavailable workers entirely

    # 1. Skill match: 1.0 if exact match, 0 otherwise
    skill_score = 1.0 if worker["skill"].lower() == required_skill.lower() else 0.0

    # If the skill doesn't match at all, don't even bother scoring further
    if skill_score == 0.0:
        return None

    # 2. Proximity: closer = higher score
    distance = haversine_km(customer_lat, customer_lon, worker["lat"], worker["lon"])
    proximity_score = max(0.0, 1 - (distance / MAX_DISTANCE_KM))

    # 3. Rating: normalize out of 5
    rating_score = worker["rating"] / 5.0

    # 4. Completion rate: already 0-1
    completion_score = worker["completion_rate"]

    # 5. Response time: faster = higher score
    response_score = max(0.0, 1 - (worker["avg_response_min"] / MAX_RESPONSE_MIN))

    final_score = (
        WEIGHTS["skill_match"] * skill_score +
        WEIGHTS["proximity"] * proximity_score +
        WEIGHTS["rating"] * rating_score +
        WEIGHTS["completion_rate"] * completion_score +
        WEIGHTS["response_time"] * response_score
    )

    return {
        "worker_id": worker["id"],
        "name": worker["name"],
        "distance_km": round(distance, 2),
        "score": round(final_score * 100, 1),
        "breakdown": {
            "skill_match": round(skill_score * 100, 1),
            "proximity": round(proximity_score * 100, 1),
            "rating": round(rating_score * 100, 1),
            "completion_rate": round(completion_score * 100, 1),
            "response_time": round(response_score * 100, 1),
        }
    }


def find_best_workers(workers: list, customer_lat: float, customer_lon: float,
                       required_skill: str, top_n: int = 5):
    scored = []
    for w in workers:
        result = score_worker(w, customer_lat, customer_lon, required_skill)
        if result:
            scored.append(result)

    scored.sort(key=lambda x: x["score"], reverse=True)
    return scored[:top_n]


if __name__ == "__main__":
    # Customer is at this location and wants an Electrician
    customer_lat, customer_lon = 28.6100, 77.2100
    required_skill = "Electrician"

    print(f"Customer needs: {required_skill}")
    print(f"Customer location: ({customer_lat}, {customer_lon})\n")

    top_matches = find_best_workers(SAMPLE_WORKERS, customer_lat, customer_lon, required_skill, top_n=5)

    print(f"Found {len(top_matches)} matching workers, ranked best first:\n")
    for i, m in enumerate(top_matches, 1):
        print(f"{i}. {m['name']} | Score: {m['score']}/100 | Distance: {m['distance_km']} km")
        print(f"   Breakdown: {m['breakdown']}\n")
