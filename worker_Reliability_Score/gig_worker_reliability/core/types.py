"""
Core Data Types, Enums, Job Records, and Reliability Report Models.
"""

from dataclasses import dataclass, field
from enum import Enum
from typing import Any, Dict, List, Optional
import time


class ReliabilityTier(str, Enum):
    ELITE = "elite"                    # 90 - 100 (Gold Partner, Top Dispatch Priority)
    DEPENDABLE = "dependable"          # 80 - 89 (Silver Partner, Standard Priority)
    STANDARD = "standard"              # 70 - 79 (Bronze Partner)
    ATTENTION_NEEDED = "attention"     # 60 - 69 (Quality Review Warning)
    PROBATION = "probation"            # < 60 (Training Required, Dispatch Throttled)

    @classmethod
    def from_score(cls, score: float) -> "ReliabilityTier":
        if score >= 90.0:
            return cls.ELITE
        elif score >= 80.0:
            return cls.DEPENDABLE
        elif score >= 70.0:
            return cls.STANDARD
        elif score >= 60.0:
            return cls.ATTENTION_NEEDED
        else:
            return cls.PROBATION


class JobStatus(str, Enum):
    COMPLETED = "completed"
    WORKER_CANCELED_EARLY = "worker_canceled_early"  # > 2 hours in advance
    WORKER_CANCELED_LATE = "worker_canceled_late"    # < 1 hour in advance (Severe penalty)
    CUSTOMER_CANCELED = "customer_canceled"          # No penalty to worker
    DISPUTED = "disputed"


@dataclass
class JobRecord:
    job_id: str
    worker_id: str
    service_category: str
    scheduled_timestamp: float
    arrival_timestamp: Optional[float] = None
    is_on_time: bool = True
    response_time_seconds: float = 25.0  # Time to accept incoming dispatch lead (0-60s)
    status: JobStatus = JobStatus.COMPLETED
    customer_rating: Optional[float] = 5.0  # 1.0 - 5.0
    customer_review: Optional[str] = ""
    tip_received: bool = False
    otp_verified_start: bool = True
    otp_verified_end: bool = True
    created_at: float = field(default_factory=time.time)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "job_id": self.job_id,
            "worker_id": self.worker_id,
            "service_category": self.service_category,
            "scheduled_timestamp": self.scheduled_timestamp,
            "arrival_timestamp": self.arrival_timestamp,
            "is_on_time": self.is_on_time,
            "response_time_seconds": self.response_time_seconds,
            "status": self.status.value,
            "customer_rating": self.customer_rating,
            "customer_review": self.customer_review,
            "tip_received": self.tip_received,
            "otp_verified_start": self.otp_verified_start,
            "otp_verified_end": self.otp_verified_end,
            "created_at": self.created_at,
        }


@dataclass
class SubScoreBreakdown:
    on_time_arrival_rate: float          # 0 - 100% (Weight: 25%)
    job_completion_rate: float           # 0 - 100% (Weight: 25%)
    customer_feedback_score: float       # 0 - 100% (Weight: 20%)
    cancellation_resistance: float       # 0 - 100% (Weight: 15%)
    response_time_score: float           # 0 - 100% (Weight: 15%)

    def to_dict(self) -> Dict[str, float]:
        return {
            "on_time_arrival_rate": round(self.on_time_arrival_rate, 1),
            "job_completion_rate": round(self.job_completion_rate, 1),
            "customer_feedback_score": round(self.customer_feedback_score, 1),
            "cancellation_resistance": round(self.cancellation_resistance, 1),
            "response_time_score": round(self.response_time_score, 1),
        }


@dataclass
class ReliabilityReport:
    worker_id: str
    overall_score: int                   # 0 - 100
    tier: ReliabilityTier
    sub_scores: SubScoreBreakdown
    summary_text: str                    # e.g. "94/100 - On-time 96%, Completion 98%, Feedback 92%, Cancellation 95%, Response time 90%"
    total_jobs_evaluated: int
    completed_jobs_count: int
    is_cold_start: bool = False
    badges: List[str] = field(default_factory=list)
    streak_bonus: float = 0.0
    churn_risk_level: str = "low"
    last_updated_at: float = field(default_factory=time.time)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "worker_id": self.worker_id,
            "overall_score": self.overall_score,
            "tier": self.tier.value,
            "tier_label": self.tier.name.replace("_", " ").title(),
            "sub_scores": self.sub_scores.to_dict(),
            "summary_text": self.summary_text,
            "total_jobs_evaluated": self.total_jobs_evaluated,
            "completed_jobs_count": self.completed_jobs_count,
            "is_cold_start": self.is_cold_start,
            "badges": self.badges,
            "streak_bonus": round(self.streak_bonus, 1),
            "churn_risk_level": self.churn_risk_level,
            "last_updated_at": self.last_updated_at,
        }


@dataclass
class WorkerProfile:
    worker_id: str
    name: str
    service_categories: List[str]
    phone: str = "9876543210"
    avatar_url: Optional[str] = None
    jobs_history: List[JobRecord] = field(default_factory=list)
    reliability_report: Optional[ReliabilityReport] = None

    def to_dict(self) -> Dict[str, Any]:
        return {
            "worker_id": self.worker_id,
            "name": self.name,
            "service_categories": self.service_categories,
            "phone": self.phone,
            "avatar_url": self.avatar_url,
            "total_jobs": len(self.jobs_history),
            "reliability_report": self.reliability_report.to_dict() if self.reliability_report else None,
        }
