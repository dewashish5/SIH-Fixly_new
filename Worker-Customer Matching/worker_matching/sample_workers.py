"""
Sample Worker Data (SIH26089)
--------------------------------
Fake worker data to test the matching engine, since there's no real
worker data yet. Replace this with real data from the database once
workers start registering on the platform.
"""

SAMPLE_WORKERS = [
    {"id": "W1", "name": "Ramesh Kumar", "skill": "Electrician", "lat": 28.6100, "lon": 77.2100,
     "rating": 4.8, "completion_rate": 0.95, "avg_response_min": 5, "is_available": True},
    {"id": "W2", "name": "Suresh Yadav", "skill": "Electrician", "lat": 28.6150, "lon": 77.2200,
     "rating": 4.2, "completion_rate": 0.80, "avg_response_min": 12, "is_available": True},
    {"id": "W3", "name": "Amit Singh", "skill": "Plumber", "lat": 28.6110, "lon": 77.2110,
     "rating": 4.9, "completion_rate": 0.97, "avg_response_min": 3, "is_available": True},
    {"id": "W4", "name": "Vijay Sharma", "skill": "Electrician", "lat": 28.6500, "lon": 77.2500,
     "rating": 4.5, "completion_rate": 0.60, "avg_response_min": 20, "is_available": True},
    {"id": "W5", "name": "Deepak Verma", "skill": "Electrician", "lat": 28.6120, "lon": 77.2130,
     "rating": 3.9, "completion_rate": 0.70, "avg_response_min": 8, "is_available": False},
    {"id": "W6", "name": "Manoj Tiwari", "skill": "Carpenter", "lat": 28.6105, "lon": 77.2105,
     "rating": 4.6, "completion_rate": 0.90, "avg_response_min": 6, "is_available": True},
    {"id": "W7", "name": "Sanjay Gupta", "skill": "Electrician", "lat": 28.6180, "lon": 77.2160,
     "rating": 4.1, "completion_rate": 0.88, "avg_response_min": 15, "is_available": True},
]
