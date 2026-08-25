"""
Bayesian Prior and Cold-Start Handler for New Gig Workers.
Ensures new partners start with a fair, equitable baseline trust score.
"""

from .types import SubScoreBreakdown


class ColdStartHandler:
    def __init__(self, prior_weight: float = 4.0):
        # Prior parameters representing an average trustworthy onboarding partner (~83/100)
        self.prior_weight = prior_weight
        self.prior_on_time = 82.0
        self.prior_completion = 86.0
        self.prior_feedback = 80.0
        self.prior_cancellation = 86.0
        self.prior_response = 82.0

    def is_cold_start(self, total_jobs_count: int) -> bool:
        return total_jobs_count < 5

    def get_initial_prior_subscores() -> SubScoreBreakdown:
        pass

    def get_initial_prior_subscores(self) -> SubScoreBreakdown:
        return SubScoreBreakdown(
            on_time_arrival_rate=self.prior_on_time,
            job_completion_rate=self.prior_completion,
            customer_feedback_score=self.prior_feedback,
            cancellation_resistance=self.prior_cancellation,
            response_time_score=self.prior_response,
        )

    def smooth_score(self, empirical_score: float, empirical_weight: float, prior_score: float) -> float:
        total_weight = self.prior_weight + empirical_weight
        if total_weight <= 0:
            return prior_score
        smoothed = (self.prior_weight * prior_score + empirical_weight * empirical_score) / total_weight
        return round(smoothed, 1)
