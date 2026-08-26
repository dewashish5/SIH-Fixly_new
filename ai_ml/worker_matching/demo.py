"""
Worker-Customer Matching - Live Demo (SIH26089)
----------------------------------------------------
A clean, presentation-ready demo script for showing the AI matching
engine working live during the SIH internal hackathon judging.

Run:
    python3 demo.py
"""

from matching_engine import find_best_workers
from sample_workers import SAMPLE_WORKERS


def print_banner():
    print("=" * 64)
    print("   SIH26089 | AI WORKER-CUSTOMER MATCHING ENGINE - LIVE DEMO")
    print("   Cooperative Gig Services Platform")
    print("=" * 64)
    print()


def print_result(skill, customer_location, matches):
    print(f"  Customer needs   : {skill}")
    print(f"  Customer location: {customer_location}")
    print(f"  {'-' * 58}")

    if not matches:
        print("  No available workers found nearby.\n")
        return

    for i, m in enumerate(matches, 1):
        marker = ">>" if i == 1 else "  "
        print(f"  {marker} #{i}  {m['name']:<18} Score: {m['score']:>5}/100   Distance: {m['distance_km']} km")

    print()


if __name__ == "__main__":
    print_banner()

    demo_cases = [
        ("Electrician", (28.6100, 77.2100)),
        ("Plumber", (28.6100, 77.2100)),
        ("Carpenter", (28.6100, 77.2100)),
        ("Cleaning", (28.6100, 77.2100)),
        ("Caregiving", (28.6100, 77.2100)),
        ("Driver", (28.6100, 77.2100)),
    ]

    for skill, (lat, lon) in demo_cases:
        matches = find_best_workers(SAMPLE_WORKERS, lat, lon, skill, top_n=3)
        print_result(skill, (lat, lon), matches)

    print("=" * 64)
    print("   Every worker is ranked using 5 factors:")
    print("   Skill match, Proximity, Rating, Completion rate, Response time")
    print("   -> Not just the nearest worker, but the BEST worker.")
    print("=" * 64)
