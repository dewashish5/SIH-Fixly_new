"""
REST API Route Handlers for Worker Reliability Scoring.
"""

import os
import sys
import time
from typing import Any, Dict, List, Optional, Tuple
import json

_curr_dir = os.path.dirname(os.path.abspath(__file__))
_pkg_root = os.path.abspath(os.path.join(_curr_dir, "..", ".."))
if _pkg_root not in sys.path:
    sys.path.insert(0, _pkg_root)

try:
    from ..core.types import JobRecord, JobStatus, ReliabilityTier
    from ..core.engine import ReliabilityEngine
    from ..data.worker_store import WorkerStore
except ImportError:
    from gig_worker_reliability.core.types import JobRecord, JobStatus, ReliabilityTier
    from gig_worker_reliability.core.engine import ReliabilityEngine
    from gig_worker_reliability.data.worker_store import WorkerStore


class APIRouter:
    def __init__(self, store: Optional[WorkerStore] = None):
        self.store = store or WorkerStore()

    def handle_request(
        self,
        method: str,
        path: str,
        body: Optional[Dict[str, Any]] = None,
        query_params: Optional[Dict[str, str]] = None,
    ) -> Tuple[int, Dict[str, Any]]:
        body = body or {}
        query_params = query_params or {}

        # 1. GET /api/worker/{worker_id}/score
        if method == "GET" and path.startswith("/api/worker/") and path.endswith("/score"):
            parts = path.strip("/").split("/")
            if len(parts) >= 3:
                worker_id = parts[2]
                return self._handle_get_worker_score(worker_id)

        # 2. GET /api/worker/{worker_id}
        if method == "GET" and path.startswith("/api/worker/") and not path.endswith("/score"):
            worker_id = path.strip("/").split("/")[-1]
            return self._handle_get_worker(worker_id)

        # 3. POST /api/job/event (Triggered upon job completion / review / cancel)
        if method == "POST" and path == "/api/job/event":
            return self._handle_job_event(body)

        # 4. GET /api/workers
        if method == "GET" and path == "/api/workers":
            return self._handle_list_workers(query_params)

        # 5. GET /api/workers/leaderboard
        if method == "GET" and path == "/api/workers/leaderboard":
            limit = int(query_params.get("limit", 10))
            return 200, {"leaderboard": self.store.get_leaderboard(limit)}

        # 6. GET /api/admin/quality-summary
        if method == "GET" and path == "/api/admin/quality-summary":
            return 200, self.store.get_admin_quality_summary()

        # 7. GET /api/health
        if method == "GET" and path == "/api/health":
            return 200, {
                "status": "healthy",
                "service": "gig_worker_reliability",
                "version": "1.0.0",
                "total_workers": len(self.store._workers),
            }

        return 404, {"error": f"Endpoint '{method} {path}' not found."}

    def _handle_get_worker_score(self, worker_id: str) -> Tuple[int, Dict[str, Any]]:
        worker = self.store.get_worker(worker_id)
        if not worker:
            return 404, {"error": f"Worker '{worker_id}' not found."}

        report = worker.reliability_report
        if not report:
            report = self.store.engine.compute_reliability(worker.worker_id, worker.jobs_history)
            worker.reliability_report = report

        return 200, {
            "worker_id": worker.worker_id,
            "name": worker.name,
            "avatar_url": worker.avatar_url,
            "service_categories": worker.service_categories,
            "reliability_report": report.to_dict(),
        }

    def _handle_get_worker(self, worker_id: str) -> Tuple[int, Dict[str, Any]]:
        worker = self.store.get_worker(worker_id)
        if not worker:
            return 404, {"error": f"Worker '{worker_id}' not found."}
        return 200, worker.to_dict()

    def _handle_job_event(self, body: Dict[str, Any]) -> Tuple[int, Dict[str, Any]]:
        worker_id = body.get("worker_id")
        if not worker_id:
            return 400, {"error": "Missing required field: 'worker_id'."}

        job_id = body.get("job_id") or f"JB-{int(time.time()*1000)}"
        category = body.get("service_category", "general_service")
        status_str = body.get("status", "completed")

        try:
            status = JobStatus(status_str.lower())
        except ValueError:
            status = JobStatus.COMPLETED

        is_on_time = bool(body.get("is_on_time", True))
        response_time = float(body.get("response_time_seconds", 25.0))
        rating = float(body.get("customer_rating", 5.0)) if body.get("customer_rating") is not None else None
        review = body.get("customer_review", "")
        tip = bool(body.get("tip_received", False))

        job = JobRecord(
            job_id=job_id,
            worker_id=worker_id,
            service_category=category,
            scheduled_timestamp=time.time(),
            arrival_timestamp=time.time(),
            is_on_time=is_on_time,
            response_time_seconds=response_time,
            status=status,
            customer_rating=rating,
            customer_review=review,
            tip_received=tip,
            created_at=time.time(),
        )

        updated_report = self.store.record_job_event(job)

        return 201, {
            "success": True,
            "message": "Job event recorded. Worker reliability score updated automatically.",
            "worker_id": worker_id,
            "new_reliability_report": updated_report.to_dict(),
        }

    def _handle_list_workers(self, query: Dict[str, str]) -> Tuple[int, Dict[str, Any]]:
        tier_str = query.get("tier")
        category = query.get("category")
        tier = ReliabilityTier(tier_str.lower()) if tier_str else None

        workers = self.store.list_workers(tier=tier, category=category)
        return 200, {
            "count": len(workers),
            "workers": [w.to_dict() for w in workers],
        }
