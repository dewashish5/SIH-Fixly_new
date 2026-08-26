"""
Central Fair Price Calculation Engine for Gig Community Platforms.
"""

from typing import Any, Dict, List, Optional
import time
from .types import (
    DemandLevel,
    PriceBreakdown,
    PriceEstimationRequest,
    PriceEstimationResponse,
    ServiceSpec,
    UrgencyLevel,
)
from .fairness import FairnessValidator
from ..data.catalog import CATALOG, find_service_spec, get_all_categories
from ..data.demand_zones import DemandForecaster
from ..ml.model import MLPriceModel


class FairPriceEngine:
    def __init__(
        self,
        ml_model: Optional[MLPriceModel] = None,
        demand_forecaster: Optional[DemandForecaster] = None,
        fairness_validator: Optional[FairnessValidator] = None,
    ):
        self.ml_model = ml_model or MLPriceModel()
        self.demand_forecaster = demand_forecaster or DemandForecaster()
        self.fairness_validator = fairness_validator or FairnessValidator()

    def estimate_price(self, req: PriceEstimationRequest) -> PriceEstimationResponse:
        # 1. Resolve Service Specification
        spec = find_service_spec(req.service_category, req.sub_service)
        if not spec:
            spec = ServiceSpec(
                category=req.service_category or "general_service",
                sub_service=req.sub_service or "standard_task",
                base_rate=299.0,
                unit="job",
                est_duration_mins=60,
                skill_tier="standard",
                min_price_floor=200.0,
                max_price_ceiling=900.0,
                description="General on-demand household task assistance.",
            )

        hour = req.get_hour()

        # 2. Demand Factor Analysis
        demand_mult, demand_level, demand_reason = self.demand_forecaster.get_demand_index(
            pincode=req.location_pincode,
            hour=hour,
            is_weekend=req.is_weekend,
            custom_override=req.custom_demand_override,
        )

        # 3. Urgency & Emergency Dispatch Multiplier
        urgency_level = req.urgency if isinstance(req.urgency, UrgencyLevel) else UrgencyLevel.from_str(str(req.urgency))
        if urgency_level == UrgencyLevel.EMERGENCY:
            urgency_mult = 1.35
            emergency_dispatch_fee = 100.0
            urgency_note = "Emergency SOS dispatch (<30-45 mins arrival guaranteed)"
        elif urgency_level == UrgencyLevel.PRIORITY:
            urgency_mult = 1.15
            emergency_dispatch_fee = 30.0
            urgency_note = "Priority booking (within 2 hours)"
        else:
            urgency_mult = 1.00
            emergency_dispatch_fee = 0.0
            urgency_note = "Standard scheduled booking (0 surcharge)"

        # 4. Feature Extraction and ML Inference
        features = self.ml_model.extract_features(
            base_rate=spec.base_rate,
            est_duration_mins=spec.est_duration_mins,
            skill_tier=spec.skill_tier,
            demand_mult=demand_mult,
            urgency_mult=urgency_mult,
            emergency_dispatch_fee=emergency_dispatch_fee,
            distance_km=req.distance_km,
            hour=hour,
            is_weekend=req.is_weekend,
        )

        raw_price, min_range, max_range, contributions = self.ml_model.predict(features)

        # 5. Build Initial Breakdown
        initial_breakdown = PriceBreakdown(
            base_service_price=contributions["base_component"],
            demand_adjustment=contributions["demand_adjustment"],
            urgency_surcharge=contributions["urgency_surcharge"],
            distance_travel_fee=contributions["distance_travel_fee"],
            time_of_day_adjustment=contributions["time_of_day_fee"],
            gross_total=raw_price,
            worker_payout_guarantee=raw_price * 0.85,
            platform_fee=raw_price * 0.15,
            tax_estimate=raw_price * 0.05,
        )

        # 6. Apply Fairness & Anti-Gouging Constraints
        raw_demand_mult = req.custom_demand_override if req.custom_demand_override is not None else demand_mult
        final_price, audited_breakdown, fairness_meta, constraint_notes = self.fairness_validator.validate_and_adjust(
            raw_estimated_price=raw_price,
            spec=spec,
            breakdown=initial_breakdown,
            urgency=urgency_level,
            raw_demand_multiplier=raw_demand_mult,
        )

        # Recalculate bounded ranges
        min_range = round(min(final_price, max(spec.min_price_floor, final_price * 0.93)), 2)
        max_range = round(max(final_price, final_price * 1.07), 2)

        # 7. Generate Explainability Notes for Customer
        notes = []
        notes.append(f"Base price for {spec.sub_service.replace('_', ' ').title()}: ₹{spec.base_rate:.0f} (est. {spec.est_duration_mins} mins)")

        if demand_mult > 1.0:
            notes.append(f"Area demand index {demand_mult:.2f}x ({demand_reason}): +₹{audited_breakdown.demand_adjustment:.0f}")
        elif demand_mult < 1.0:
            notes.append(f"Off-peak discount {demand_mult:.2f}x ({demand_reason}): -₹{abs(audited_breakdown.demand_adjustment):.0f}")
        else:
            notes.append(f"Standard area demand: ₹0 surge")

        if urgency_level != UrgencyLevel.STANDARD:
            notes.append(f"Urgency fee ({urgency_note}): +₹{audited_breakdown.urgency_surcharge:.0f}")

        if audited_breakdown.distance_travel_fee > 0:
            notes.append(f"Travel distance ({req.distance_km:.1f} km): +₹{audited_breakdown.distance_travel_fee:.0f}")

        if audited_breakdown.time_of_day_adjustment > 0:
            notes.append(f"Night shift assistance buffer: +₹{audited_breakdown.time_of_day_adjustment:.0f}")

        notes.extend(constraint_notes)

        return PriceEstimationResponse(
            service_category=spec.category,
            sub_service=spec.sub_service,
            estimated_price=final_price,
            price_range_min=min_range,
            price_range_max=max_range,
            urgency_level=urgency_level.value,
            demand_level=demand_level.value,
            demand_multiplier=demand_mult,
            urgency_multiplier=urgency_mult,
            breakdown=audited_breakdown,
            explainability_notes=notes,
            fairness_compliance=fairness_meta,
            model_version="1.0.0-gradient-boosting-fair",
            estimated_at=time.time(),
        )

    def batch_estimate(self, requests: List[PriceEstimationRequest]) -> List[PriceEstimationResponse]:
        return [self.estimate_price(r) for r in requests]

    def get_services_catalog(self) -> Dict[str, Any]:
        result = {}
        for cat, specs in CATALOG.items():
            result[cat] = [s.to_dict() for s in specs]
        return result
