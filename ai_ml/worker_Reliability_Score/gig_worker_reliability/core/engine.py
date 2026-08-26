"""
Central Worker Reliability Calculation and Bayesian Time-Decay Scoring Engine.
"""

import math
import time
from typing import Any, Dict, List, Optional
from .types import (
    JobRecord,
    JobStatus,
    ReliabilityReport,
    ReliabilityTier,
    SubScoreBreakdown,
)
from .cold_start import ColdStartHandler


class ReliabilityEngine:
    # Component Weights summing strictly to 1.00 (100%)
    WEIGHT_ON_TIME = 0.25
    WEIGHT_COMPLETION = 0.25
    WEIGHT_FEEDBACK = 0.20
    WEIGHT_CANCELLATION = 0.15
    WEIGHT_RESPONSE_TIME = 0.15

    def __init__(
        self,
        half_life_days: float = 30.0,
        cold_start_handler: Optional[ColdStartHandler] = None,
    ):
        # Exponential decay constant: lambda = ln(2) / half_life
        self.half_life_days = half_life_days
        self.decay_lambda = math.log(2.0) / (half_life_days * 86400.0)
        self.cold_start_handler = cold_start_handler or ColdStartHandler()

    def compute_reliability(
        self,
        worker_id: str,
        jobs: List[JobRecord],
        current_time: Optional[float] = None,
    ) -> ReliabilityReport:
        current_time = current_time or time.time()
        total_jobs = len(jobs)
        is_cold_start = self.cold_start_handler.is_cold_start(total_jobs)

        if total_jobs == 0:
            priors = self.cold_start_handler.get_initial_prior_subscores()
            base_score = int(round(
                priors.on_time_arrival_rate * self.WEIGHT_ON_TIME +
                priors.job_completion_rate * self.WEIGHT_COMPLETION +
                priors.customer_feedback_score * self.WEIGHT_FEEDBACK +
                priors.cancellation_resistance * self.WEIGHT_CANCELLATION +
                priors.response_time_score * self.WEIGHT_RESPONSE_TIME
            ))
            tier = ReliabilityTier.from_score(base_score)
            summary = self._format_summary(base_score, priors)
            return ReliabilityReport(
                worker_id=worker_id,
                overall_score=base_score,
                tier=tier,
                sub_scores=priors,
                summary_text=summary,
                total_jobs_evaluated=0,
                completed_jobs_count=0,
                is_cold_start=True,
                badges=["🌱 Verified New Partner"],
                streak_bonus=0.0,
                last_updated_at=current_time,
            )

        # 1. Calculate Weights with Exponential Time-Decay
        weighted_ontime_sum = 0.0
        weighted_completion_sum = 0.0
        weighted_feedback_sum = 0.0
        weighted_cancel_sum = 0.0
        weighted_response_sum = 0.0
        total_weight = 0.0

        completed_count = 0
        consecutive_perfect_streak = 0
        counting_streak = True

        # Sort jobs newest first for streak and decay
        sorted_jobs = sorted(jobs, key=lambda j: j.created_at, reverse=True)

        for job in sorted_jobs:
            age_seconds = max(0.0, current_time - job.created_at)
            w = math.exp(-self.decay_lambda * age_seconds)
            total_weight += w

            # A. On-Time Arrival
            ontime_val = 100.0 if job.is_on_time else 0.0
            weighted_ontime_sum += w * ontime_val

            # B. Job Completion
            if job.status == JobStatus.COMPLETED:
                completion_val = 100.0
                completed_count += 1
            elif job.status == JobStatus.DISPUTED:
                completion_val = 20.0
            else:
                completion_val = 0.0
            weighted_completion_sum += w * completion_val

            # C. Customer Feedback (1-5 stars normalized to 0-100%)
            if job.customer_rating is not None and job.status == JobStatus.COMPLETED:
                # 5-star => 100%, 4-star => 75%, 3-star => 50%, 2-star => 25%, 1-star => 0%
                rating_norm = max(0.0, min(100.0, (job.customer_rating - 1.0) / 4.0 * 100.0))
                if job.tip_received:
                    rating_norm = min(100.0, rating_norm + 5.0)  # Tip bonus
                weighted_feedback_sum += w * rating_norm
            else:
                # Default neutral benchmark for missing rating
                weighted_feedback_sum += w * 85.0

            # D. Cancellation Resistance
            if job.status == JobStatus.WORKER_CANCELED_LATE:
                cancel_val = 0.0   # Severe late cancel penalty
            elif job.status == JobStatus.WORKER_CANCELED_EARLY:
                cancel_val = 40.0
            elif job.status == JobStatus.CUSTOMER_CANCELED:
                cancel_val = 100.0  # Customer cancellation does not harm worker
            else:
                cancel_val = 100.0
            weighted_cancel_sum += w * cancel_val

            # E. Lead Response Time
            resp_sec = job.response_time_seconds
            if resp_sec <= 15.0:
                resp_score = 100.0
            elif resp_sec <= 45.0:
                resp_score = 100.0 - ((resp_sec - 15.0) / 30.0 * 25.0)  # 100 down to 75
            elif resp_sec <= 90.0:
                resp_score = 75.0 - ((resp_sec - 45.0) / 45.0 * 40.0)   # 75 down to 35
            else:
                resp_score = 20.0
            weighted_response_sum += w * resp_score

            # Streak detection
            if counting_streak:
                if job.status == JobStatus.COMPLETED and job.is_on_time and (job.customer_rating or 5.0) >= 4.5:
                    consecutive_perfect_streak += 1
                else:
                    counting_streak = False

        # Compute empirical averages
        emp_ontime = weighted_ontime_sum / total_weight
        emp_completion = weighted_completion_sum / total_weight
        emp_feedback = weighted_feedback_sum / total_weight
        emp_cancel = weighted_cancel_sum / total_weight
        emp_response = weighted_response_sum / total_weight

        # Apply Bayesian Cold-Start Smoothing if low job volume
        if is_cold_start:
            priors = self.cold_start_handler.get_initial_prior_subscores()
            final_ontime = self.cold_start_handler.smooth_score(emp_ontime, total_weight, priors.on_time_arrival_rate)
            final_completion = self.cold_start_handler.smooth_score(emp_completion, total_weight, priors.job_completion_rate)
            final_feedback = self.cold_start_handler.smooth_score(emp_feedback, total_weight, priors.customer_feedback_score)
            final_cancel = self.cold_start_handler.smooth_score(emp_cancel, total_weight, priors.cancellation_resistance)
            final_response = self.cold_start_handler.smooth_score(emp_response, total_weight, priors.response_time_score)
        else:
            final_ontime = round(emp_ontime, 1)
            final_completion = round(emp_completion, 1)
            final_feedback = round(emp_feedback, 1)
            final_cancel = round(emp_cancel, 1)
            final_response = round(emp_response, 1)

        sub_scores = SubScoreBreakdown(
            on_time_arrival_rate=final_ontime,
            job_completion_rate=final_completion,
            customer_feedback_score=final_feedback,
            cancellation_resistance=final_cancel,
            response_time_score=final_response,
        )

        # 2. Weighted Overall Score Calculation
        raw_score = (
            final_ontime * self.WEIGHT_ON_TIME +
            final_completion * self.WEIGHT_COMPLETION +
            final_feedback * self.WEIGHT_FEEDBACK +
            final_cancel * self.WEIGHT_CANCELLATION +
            final_response * self.WEIGHT_RESPONSE_TIME
        )

        # 3. Streak Bonus
        streak_bonus = 0.0
        if consecutive_perfect_streak >= 10:
            streak_bonus = 3.0
        elif consecutive_perfect_streak >= 5:
            streak_bonus = 1.5

        overall_score = int(round(max(0.0, min(100.0, raw_score + streak_bonus))))
        tier = ReliabilityTier.from_score(overall_score)

        # 4. Generate Badges
        badges = []
        if is_cold_start:
            badges.append("🌱 Verified New Partner")
        if final_ontime >= 95.0 and total_jobs >= 5:
            badges.append("⏱️ Punctuality Master")
        if final_completion >= 98.0 and total_jobs >= 5:
            badges.append("🏆 99% Completion")
        if final_feedback >= 92.0 and total_jobs >= 5:
            badges.append("⭐ Top Rated Partner")
        if final_response >= 90.0 and total_jobs >= 5:
            badges.append("⚡ Rapid Responder")
        if streak_bonus > 0:
            badges.append(f"🔥 {consecutive_perfect_streak} Perfect Streak")

        summary_text = self._format_summary(overall_score, sub_scores)

        # Risk Classification
        if overall_score >= 85:
            churn_risk = "low"
        elif overall_score >= 70:
            churn_risk = "moderate"
        else:
            churn_risk = "high"

        return ReliabilityReport(
            worker_id=worker_id,
            overall_score=overall_score,
            tier=tier,
            sub_scores=sub_scores,
            summary_text=summary_text,
            total_jobs_evaluated=total_jobs,
            completed_jobs_count=completed_count,
            is_cold_start=is_cold_start,
            badges=badges,
            streak_bonus=streak_bonus,
            churn_risk_level=churn_risk,
            last_updated_at=current_time,
        )

    def _format_summary(self, score: int, sub: SubScoreBreakdown) -> str:
        return (
            f"{score}/100 - "
            f"On-time {int(round(sub.on_time_arrival_rate))}%, "
            f"Completion {int(round(sub.job_completion_rate))}%, "
            f"Feedback {int(round(sub.customer_feedback_score))}%, "
            f"Cancellation {int(round(sub.cancellation_resistance))}%, "
            f"Response time {int(round(sub.response_time_score))}%"
        )
