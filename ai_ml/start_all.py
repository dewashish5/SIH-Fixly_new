"""
SIH26089 — Start ALL AI/ML Services (Single Command)
---------------------------------------------------------
Starts all 5 AI/ML features with ONE command, each on its own port,
exactly as they already work individually. This does not change any
teammate's code — it just launches everything together instead of you
having to open 5 separate terminals.

Why not combine them into one single port?
Two of the modules (service_discovery, worker_matching) are built with
FastAPI. The other three (worker_Reliability_Score,
fairPriceEstimation_AI_model, support_chatbot) are built with Python's
built-in http.server, which is a different, incompatible technology —
it cannot be merged into a FastAPI app without rewriting their internal
routing. Running them as separate processes (started together, from one
script) is the safe way to combine everything without risking breaking
code that already works.

Run:
    python3 start_all.py

Then everything is available at:
    Service Discovery   -> http://127.0.0.1:8002/docs
    Worker Matching      -> http://127.0.0.1:8003/docs
    Fair Price Estimation -> http://127.0.0.1:8081/demo/index.html
    Worker Reliability   -> http://127.0.0.1:8082/demo/index.html
    Support Chatbot       -> http://127.0.0.1:8080/demo/index.html

Press Ctrl+C once to stop ALL of them together.
"""

import subprocess
import sys
import os
import signal
import time

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# Each entry: (display name, folder name, command to run, port, url to show)
SERVICES = [
    {
        "name": "Service Discovery",
        "folder": "service_discovery",
        "cmd": [sys.executable, "-m", "uvicorn", "discovery_api:app", "--port", "8002"],
        "url": "http://127.0.0.1:8002/docs",
    },
    {
        "name": "Worker Matching",
        "folder": "worker_matching",
        "cmd": [sys.executable, "-m", "uvicorn", "matching_api:app", "--port", "8003"],
        "url": "http://127.0.0.1:8003/docs",
    },
    {
        "name": "Worker Reliability Score",
        "folder": "worker_Reliability_Score",
        "cmd": [sys.executable, "run_server.py", "--port", "8082"],
        "url": "http://127.0.0.1:8082/demo/index.html",
    },
    {
        "name": "Fair Price Estimation",
        "folder": "fairPriceEstimation_AI_model",
        "cmd": [sys.executable, "run_server.py", "--port", "8081"],
        "url": "http://127.0.0.1:8081/demo/index.html",
    },
    {
        "name": "Support Chatbot",
        "folder": "support_chatbot",
        "cmd": [sys.executable, "run_server.py", "--port", "8080"],
        "url": "http://127.0.0.1:8080/demo/index.html",
    },
]

processes = []


def start_all():
    print("=" * 64)
    print("  SIH26089 — Starting all 5 AI/ML services...")
    print("=" * 64)

    for service in SERVICES:
        folder_path = os.path.join(BASE_DIR, service["folder"])
        print(f"  Starting: {service['name']} ...")
        proc = subprocess.Popen(
            service["cmd"],
            cwd=folder_path,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        processes.append(proc)
        time.sleep(1)  # small delay so startup logs don't overlap

    print()
    print("=" * 64)
    print("  ALL SERVICES RUNNING")
    print("=" * 64)
    for service in SERVICES:
        print(f"  {service['name']:<28} -> {service['url']}")
    print("=" * 64)
    print("  Press Ctrl+C to stop all services.")
    print()


def stop_all(sig=None, frame=None):
    print("\nStopping all services...")
    for proc in processes:
        proc.terminate()
    for proc in processes:
        try:
            proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            proc.kill()
    print("All services stopped.")
    sys.exit(0)


if __name__ == "__main__":
    signal.signal(signal.SIGINT, stop_all)
    start_all()
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        stop_all()
