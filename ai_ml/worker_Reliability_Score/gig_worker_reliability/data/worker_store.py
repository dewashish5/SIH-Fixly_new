"""
In-Memory and Pluggable Persistent Worker Repository & Event Store.
"""

import threading
import time
from typing import Dict, List, Optional, Any
from ..core.types import (
    JobRecord,
    JobStatus,
    ReliabilityReport,
    ReliabilityTier,
    WorkerProfile,
)
from ..core.engine import ReliabilityEngine


class WorkerStore:
    def __init__(self, engine: Optional[ReliabilityEngine] = None):
        self._lock = threading.RLock()
        self.engine = engine or ReliabilityEngine()
        self._workers: Dict[str, WorkerProfile] = {}
        self._populate_sample_workers()

    def get_worker(self, worker_id: str) -> Optional[WorkerProfile]:
        with self._lock:
            return self._workers.get(worker_id)

    def list_workers(
        self,
        tier: Optional[ReliabilityTier] = None,
        category: Optional[str] = None,
    ) -> List[WorkerProfile]:
        with self._lock:
            results = list(self._workers.values())
            if tier:
                results = [w for w in results if w.reliability_report and w.reliability_report.tier == tier]
            if category:
                cat = category.strip().lower()
                results = [w for w in results if any(c.lower() == cat for c in w.service_categories)]
            return results

    def record_job_event(self, job: JobRecord) -> ReliabilityReport:
        """
        Trigger: Record completed or canceled job and automatically re-calculate worker's reliability score.
        """
        with self._lock:
            worker = self._workers.get(job.worker_id)
            if not worker:
                worker = WorkerProfile(
                    worker_id=job.worker_id,
                    name=f"Worker {job.worker_id}",
                    service_categories=[job.service_category],
                )
                self._workers[job.worker_id] = worker

            # Append job to history
            worker.jobs_history.append(job)

            # Recompute reliability score
            report = self.engine.compute_reliability(worker.worker_id, worker.jobs_history)
            worker.reliability_report = report
            return report

    def get_leaderboard(self, limit: int = 10) -> List[Dict[str, Any]]:
        with self._lock:
            sorted_workers = sorted(
                self._workers.values(),
                key=lambda w: w.reliability_report.overall_score if w.reliability_report else 0,
                reverse=True,
            )
            return [w.to_dict() for w in sorted_workers[:limit]]

    def get_admin_quality_summary(self) -> Dict[str, Any]:
        with self._lock:
            total = len(self._workers)
            tier_counts = {t.value: 0 for t in ReliabilityTier}
            total_score_sum = 0
            alert_workers = []

            for w in self._workers.values():
                if w.reliability_report:
                    tier_counts[w.reliability_report.tier.value] += 1
                    total_score_sum += w.reliability_report.overall_score
                    if w.reliability_report.tier in (ReliabilityTier.ATTENTION_NEEDED, ReliabilityTier.PROBATION):
                        alert_workers.append({
                            "worker_id": w.worker_id,
                            "name": w.name,
                            "score": w.reliability_report.overall_score,
                            "tier": w.reliability_report.tier.value,
                            "cancellation_rate": 100 - w.reliability_report.sub_scores.cancellation_resistance,
                        })

            avg_score = round(total_score_sum / total, 1) if total > 0 else 0.0

            return {
                "total_registered_workers": total,
                "average_reliability_score": avg_score,
                "tier_distribution": tier_counts,
                "quality_alerts_count": len(alert_workers),
                "attention_and_probation_workers": alert_workers,
            }

    def _populate_sample_workers(self):
        now = time.time()
        day = 86400.0

        # 1. WRK-1001: Rajesh Kumar (Elite - 96/100)
        jobs_1 = [
            JobRecord(f"JB-101-{i}", "WRK-1001", "electrical", now - i * day, now - i * day, True, 18.0, JobStatus.COMPLETED, 5.0, "Superb!", True, True, True, now - i * day)
            for i in range(25)
        ]
        w1 = WorkerProfile("WRK-1001", "Rajesh Kumar", ["electrical", "appliance_repair"], "9876543210", jobs_history=jobs_1)
        w1.reliability_report = self.engine.compute_reliability("WRK-1001", jobs_1, now)
        self._workers["WRK-1001"] = w1

        # 2. WRK-1002: Priya Sharma (Elite - 94/100)
        jobs_2 = [
            JobRecord(f"JB-102-{i}", "WRK-1002", "cleaning", now - i * day * 1.5, now - i * day * 1.5, True, 22.0, JobStatus.COMPLETED, 4.9, "Very clean!", True, True, True, now - i * day * 1.5)
            for i in range(18)
        ]
        # Add 1 early cancellation
        jobs_2.append(JobRecord("JB-102-99", "WRK-1002", "cleaning", now - 40 * day, None, False, 30.0, JobStatus.WORKER_CANCELED_EARLY, None, "", False, False, False, now - 40 * day))
        w2 = WorkerProfile("WRK-1002", "Priya Sharma", ["cleaning", "pest_control"], "9876543211", jobs_history=jobs_2)
        w2.reliability_report = self.engine.compute_reliability("WRK-1002", jobs_2, now)
        self._workers["WRK-1002"] = w2

        # 3. WRK-1003: Mohammed Farooq (Dependable - 86/100)
        jobs_3 = [
            JobRecord(f"JB-103-{i}", "WRK-1003", "ac_repair", now - i * day * 2, now - i * day * 2, i % 6 != 0, 32.0, JobStatus.COMPLETED, 4.4, "Good job", False, True, True, now - i * day * 2)
            for i in range(15)
        ]
        w3 = WorkerProfile("WRK-1003", "Mohammed Farooq", ["ac_repair"], "9876543212", jobs_history=jobs_3)
        w3.reliability_report = self.engine.compute_reliability("WRK-1003", jobs_3, now)
        self._workers["WRK-1003"] = w3

        # 4. WRK-1004: Amit Verma (Standard - 76/100)
        jobs_4 = [
            JobRecord(f"JB-104-{i}", "WRK-1004", "plumbing", now - i * day, now - i * day, i % 3 != 0, 48.0, JobStatus.COMPLETED, 3.9, "Okay", False, True, True, now - i * day)
            for i in range(12)
        ]
        jobs_4.append(JobRecord("JB-104-98", "WRK-1004", "plumbing", now - 5 * day, None, False, 55.0, JobStatus.WORKER_CANCELED_EARLY, None, "", False, False, False, now - 5 * day))
        w4 = WorkerProfile("WRK-1004", "Amit Verma", ["plumbing"], "9876543213", jobs_history=jobs_4)
        w4.reliability_report = self.engine.compute_reliability("WRK-1004", jobs_4, now)
        self._workers["WRK-1004"] = w4

        # 5. WRK-1005: Rahul Singh (Attention Needed - 64/100)
        jobs_5 = [
            JobRecord(f"JB-105-{i}", "WRK-1005", "carpentry", now - i * day, now - i * day, i % 2 == 0, 60.0, JobStatus.COMPLETED if i > 2 else JobStatus.WORKER_CANCELED_LATE, 3.2 if i > 2 else None, "Late", False, True, True, now - i * day)
            for i in range(10)
        ]
        w5 = WorkerProfile("WRK-1005", "Rahul Singh", ["carpentry"], "9876543214", jobs_history=jobs_5)
        w5.reliability_report = self.engine.compute_reliability("WRK-1005", jobs_5, now)
        self._workers["WRK-1005"] = w5

        # 6. WRK-1006: Suresh Patel (Probation - 46/100)
        jobs_6 = [
            JobRecord(f"JB-106-{i}", "WRK-1006", "painting", now - i * day, now - i * day, False, 85.0, JobStatus.WORKER_CANCELED_LATE if i % 2 == 0 else JobStatus.DISPUTED, 2.0, "Dispute", False, True, True, now - i * day)
            for i in range(8)
        ]
        w6 = WorkerProfile("WRK-1006", "Suresh Patel", ["painting"], "9876543215", jobs_history=jobs_6)
        w6.reliability_report = self.engine.compute_reliability("WRK-1006", jobs_6, now)
        self._workers["WRK-1006"] = w6

        # 7. WRK-1007: Sunita Devi (Cold Start / New Partner - 82/100)
        jobs_7 = [
            JobRecord("JB-107-1", "WRK-1007", "cleaning", now - 1 * day, now - 1 * day, True, 19.0, JobStatus.COMPLETED, 5.0, "Great service!", True, True, True, now - 1 * day),
            JobRecord("JB-107-2", "WRK-1007", "cleaning", now - 2 * day, now - 2 * day, True, 21.0, JobStatus.COMPLETED, 4.8, "Punctual", False, True, True, now - 2 * day),
        ]
        w7 = WorkerProfile("WRK-1007", "Sunita Devi", ["cleaning"], "9876543216", jobs_history=jobs_7)
        w7.reliability_report = self.engine.compute_reliability("WRK-1007", jobs_7, now)
        self._workers["WRK-1007"] = w7
