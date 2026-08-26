"""
Core Data Types, Enums, and Request/Response Models for Fair Price Estimation.
"""

from dataclasses import dataclass, field
from enum import Enum
from typing import Any, Dict, List, Optional
import time
import uuid


class UrgencyLevel(str, Enum):
    STANDARD = "standard"          # Scheduled normally (today/future slot)
    PRIORITY = "priority"          # Priority dispatch within 2 hours
    EMERGENCY = "emergency"        # Urgent / Emergency SOS dispatch (<30-45 mins guaranteed)

    @classmethod
    def from_str(cls, val: str) -> "UrgencyLevel":
        val = (val or "").strip().lower()
        if val in ("emergency", "urgent", "sos", "instant", "immediate"):
            return cls.EMERGENCY
        if val in ("priority", "express", "today", "fast"):
            return cls.PRIORITY
        return cls.STANDARD


class DemandLevel(str, Enum):
    LOW = "low"                    # Multiplier ~ 0.90x - 0.95x
    NORMAL = "normal"              # Multiplier ~ 1.00x
    MODERATE = "moderate"          # Multiplier ~ 1.10x - 1.20x
    HIGH = "high"                  # Multiplier ~ 1.25x - 1.35x
    PEAK = "peak"                  # Multiplier ~ 1.40x - 1.55x (Capped at 1.60x)


@dataclass
class ServiceSpec:
    category: str
    sub_service: str
    base_rate: float
    unit: str                      # 'job', 'hour', 'room', 'appliance'
    est_duration_mins: int
    skill_tier: str                # 'standard', 'skilled', 'master'
    min_price_floor: float
    max_price_ceiling: float
    description: str

    def to_dict(self) -> Dict[str, Any]:
        return {
            "category": self.category,
            "sub_service": self.sub_service,
            "base_rate": self.base_rate,
            "unit": self.unit,
            "est_duration_mins": self.est_duration_mins,
            "skill_tier": self.skill_tier,
            "min_price_floor": self.min_price_floor,
            "max_price_ceiling": self.max_price_ceiling,
            "description": self.description,
        }


@dataclass
class PriceEstimationRequest:
    service_category: str
    sub_service: Optional[str] = None
    location_pincode: Optional[str] = "560038"
    latitude: Optional[float] = 12.9716
    longitude: Optional[float] = 77.5946
    urgency: UrgencyLevel = UrgencyLevel.STANDARD
    scheduled_hour: Optional[int] = None   # 0 to 23
    distance_km: float = 3.5
    user_id: Optional[str] = None
    is_weekend: bool = False
    custom_demand_override: Optional[float] = None  # Hook for direct demand forecasting model feed

    def get_hour(self) -> int:
        if self.scheduled_hour is not None:
            return self.scheduled_hour
        import datetime
        return datetime.datetime.now().hour


@dataclass
class PriceBreakdown:
    base_service_price: float
    demand_adjustment: float
    urgency_surcharge: float
    distance_travel_fee: float
    time_of_day_adjustment: float
    gross_total: float
    worker_payout_guarantee: float
    platform_fee: float
    tax_estimate: float

    def to_dict(self) -> Dict[str, Any]:
        return {
            "base_service_price": round(self.base_service_price, 2),
            "demand_adjustment": round(self.demand_adjustment, 2),
            "urgency_surcharge": round(self.urgency_surcharge, 2),
            "distance_travel_fee": round(self.distance_travel_fee, 2),
            "time_of_day_adjustment": round(self.time_of_day_adjustment, 2),
            "gross_total": round(self.gross_total, 2),
            "worker_payout_guarantee": round(self.worker_payout_guarantee, 2),
            "platform_fee": round(self.platform_fee, 2),
            "tax_estimate": round(self.tax_estimate, 2),
        }


@dataclass
class PriceEstimationResponse:
    estimation_id: str = field(default_factory=lambda: f"EST-{uuid.uuid4().hex[:8].upper()}")
    service_category: str = ""
    sub_service: str = ""
    estimated_price: float = 0.0
    price_range_min: float = 0.0
    price_range_max: float = 0.0
    currency: str = "INR"
    currency_symbol: str = "₹"
    urgency_level: str = "standard"
    demand_level: str = "normal"
    demand_multiplier: float = 1.0
    urgency_multiplier: float = 1.0
    breakdown: Optional[PriceBreakdown] = None
    explainability_notes: List[str] = field(default_factory=list)
    fairness_compliance: Dict[str, Any] = field(default_factory=dict)
    model_version: str = "1.0.0-hybrid-ml"
    estimated_at: float = field(default_factory=time.time)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "estimation_id": self.estimation_id,
            "service_category": self.service_category,
            "sub_service": self.sub_service,
            "estimated_price": round(self.estimated_price, 2),
            "price_range": {
                "min_price": round(self.price_range_min, 2),
                "max_price": round(self.price_range_max, 2),
                "formatted": f"{self.currency_symbol}{round(self.price_range_min)} - {self.currency_symbol}{round(self.price_range_max)}",
            },
            "formatted_price": f"{self.currency_symbol}{round(self.estimated_price)}",
            "currency": self.currency,
            "currency_symbol": self.currency_symbol,
            "urgency_level": self.urgency_level,
            "demand_level": self.demand_level,
            "demand_multiplier": round(self.demand_multiplier, 3),
            "urgency_multiplier": round(self.urgency_multiplier, 3),
            "breakdown": self.breakdown.to_dict() if self.breakdown else None,
            "explainability_notes": self.explainability_notes,
            "fairness_compliance": self.fairness_compliance,
            "model_version": self.model_version,
            "estimated_at": self.estimated_at,
        }
