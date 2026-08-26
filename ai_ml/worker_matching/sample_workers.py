"""
Sample Worker Data (SIH26089)
--------------------------------
Fake worker data to test the matching engine, covering all 10 official
service categories. Replace this with real data from the database once
workers start registering on the platform.
"""

SAMPLE_WORKERS = [
    # Electrician
    {"id": "W1", "name": "Ramesh Kumar", "skill": "Electrician", "lat": 28.6100, "lon": 77.2100,
     "rating": 4.8, "completion_rate": 0.95, "avg_response_min": 5, "is_available": True},
    {"id": "W2", "name": "Suresh Yadav", "skill": "Electrician", "lat": 28.6150, "lon": 77.2200,
     "rating": 4.2, "completion_rate": 0.80, "avg_response_min": 12, "is_available": True},
    {"id": "W3", "name": "Vijay Sharma", "skill": "Electrician", "lat": 28.6500, "lon": 77.2500,
     "rating": 4.5, "completion_rate": 0.60, "avg_response_min": 20, "is_available": True},

    # Plumber
    {"id": "W4", "name": "Amit Singh", "skill": "Plumber", "lat": 28.6110, "lon": 77.2110,
     "rating": 4.9, "completion_rate": 0.97, "avg_response_min": 3, "is_available": True},
    {"id": "W5", "name": "Rakesh Jha", "skill": "Plumber", "lat": 28.6300, "lon": 77.2300,
     "rating": 4.0, "completion_rate": 0.75, "avg_response_min": 18, "is_available": True},

    # Carpenter
    {"id": "W6", "name": "Manoj Tiwari", "skill": "Carpenter", "lat": 28.6105, "lon": 77.2105,
     "rating": 4.6, "completion_rate": 0.90, "avg_response_min": 6, "is_available": True},
    {"id": "W7", "name": "Prakash Rao", "skill": "Carpenter", "lat": 28.6400, "lon": 77.2400,
     "rating": 3.8, "completion_rate": 0.65, "avg_response_min": 25, "is_available": True},

    # Painter
    {"id": "W8", "name": "Ashok Mehta", "skill": "Painter", "lat": 28.6120, "lon": 77.2120,
     "rating": 4.7, "completion_rate": 0.92, "avg_response_min": 7, "is_available": True},

    # Cleaning
    {"id": "W9", "name": "Sunita Devi", "skill": "Cleaning", "lat": 28.6115, "lon": 77.2115,
     "rating": 4.9, "completion_rate": 0.98, "avg_response_min": 4, "is_available": True},
    {"id": "W10", "name": "Kiran Bala", "skill": "Cleaning", "lat": 28.6350, "lon": 77.2350,
     "rating": 4.3, "completion_rate": 0.82, "avg_response_min": 15, "is_available": True},

    # Domestic Helper
    {"id": "W11", "name": "Meena Kumari", "skill": "Domestic Helper", "lat": 28.6108, "lon": 77.2108,
     "rating": 4.6, "completion_rate": 0.89, "avg_response_min": 8, "is_available": True},

    # Caregiving
    {"id": "W12", "name": "Anita Sharma", "skill": "Caregiving", "lat": 28.6112, "lon": 77.2112,
     "rating": 4.9, "completion_rate": 0.96, "avg_response_min": 5, "is_available": True},
    {"id": "W13", "name": "Poonam Yadav", "skill": "Caregiving", "lat": 28.6450, "lon": 77.2450,
     "rating": 4.1, "completion_rate": 0.70, "avg_response_min": 22, "is_available": False},

    # Gardener
    {"id": "W14", "name": "Ram Lal", "skill": "Gardener", "lat": 28.6130, "lon": 77.2130,
     "rating": 4.4, "completion_rate": 0.85, "avg_response_min": 10, "is_available": True},

    # Driver
    {"id": "W15", "name": "Sanjay Gupta", "skill": "Driver", "lat": 28.6180, "lon": 77.2160,
     "rating": 4.1, "completion_rate": 0.88, "avg_response_min": 15, "is_available": True},
    {"id": "W16", "name": "Deepak Verma", "skill": "Driver", "lat": 28.6122, "lon": 77.2130,
     "rating": 3.9, "completion_rate": 0.70, "avg_response_min": 8, "is_available": False},

    # Technician
    {"id": "W17", "name": "Naresh Kumar", "skill": "Technician", "lat": 28.6118, "lon": 77.2118,
     "rating": 4.7, "completion_rate": 0.91, "avg_response_min": 6, "is_available": True},
    {"id": "W18", "name": "Vikas Chauhan", "skill": "Technician", "lat": 28.6320, "lon": 77.2320,
     "rating": 4.0, "completion_rate": 0.78, "avg_response_min": 17, "is_available": True},
]
