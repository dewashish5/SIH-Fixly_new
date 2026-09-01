"""
REST API request handlers and route dispatcher for Fair Price Estimation.
"""

import os
import sys
from typing import Any, Dict, List, Optional, Tuple
import json

_curr_dir = os.path.dirname(os.path.abspath(__file__))
_pkg_root = os.path.abspath(os.path.join(_curr_dir, "..", ".."))
if _pkg_root not in sys.path:
    sys.path.insert(0, _pkg_root)

try:
    from ..core.engine import FairPriceEngine
    from ..core.types import PriceEstimationRequest, UrgencyLevel
    from ..data.catalog import get_all_categories
    from ..core.constants import GOVT_MIN_WAGE_BY_TIER
except ImportError:
    from gig_fair_pricing.core.engine import FairPriceEngine
    from gig_fair_pricing.core.types import PriceEstimationRequest, UrgencyLevel
    from gig_fair_pricing.data.catalog import get_all_categories
    from gig_fair_pricing.core.constants import GOVT_MIN_WAGE_BY_TIER


class APIRouter:
    def __init__(self, engine: Optional[FairPriceEngine] = None):
        self.engine = engine or FairPriceEngine()

    def handle_request(
        self,
        method: str,
        path: str,
        body: Optional[Dict[str, Any]] = None,
        query_params: Optional[Dict[str, str]] = None,
    ) -> Tuple[int, Dict[str, Any]]:
        body = body or {}
        query_params = query_params or {}

        # 1. POST /api/estimate-price
        if method == "POST" and path == "/api/estimate-price":
            return self._handle_estimate_price(body)

        # 2. POST /api/batch-estimate
        if method == "POST" and path == "/api/batch-estimate":
            return self._handle_batch_estimate(body)

        # 3. GET /api/services
        if method == "GET" and path == "/api/services":
            return 200, {
                "services": self.engine.get_services_catalog(),
                "count": len(self.engine.get_services_catalog()),
            }

        # 4. GET /api/demand-index
        if method == "GET" and path == "/api/demand-index":
            return self._handle_demand_index(query_params)

        # 5. GET /api/demo-scenarios
        if method == "GET" and path == "/api/demo-scenarios":
            scenarios = self.engine.get_judge_scenarios()
            return 200, {
                "scenarios": scenarios,
                "count": len(scenarios),
                "status": "success",
            }

        # 6. POST /api/compare-pricing
        if method == "POST" and path == "/api/compare-pricing":
            return self._handle_compare_pricing(body)

        # 7. GET /api/health
        if method == "GET" and path == "/api/health":
            return 200, {
                "status": "healthy",
                "service": "gig_fair_pricing",
                "version": "1.0.0",
                "ml_model_loaded": self.engine.ml_model.sklearn_model is not None,
                "endpoints": [
                    "POST /api/estimate-price",
                    "POST /api/batch-estimate",
                    "GET /api/services",
                    "GET /api/demand-index",
                    "GET /api/demo-scenarios",
                    "POST /api/compare-pricing",
                    "GET /api/health",
                ],
            }

        return 404, {"error": f"Endpoint '{method} {path}' not found."}

    def _handle_estimate_price(self, body: Dict[str, Any]) -> Tuple[int, Dict[str, Any]]:
        service = body.get("service_category") or body.get("service_type") or body.get("service")
        if not service:
            return 400, {
                "error": "Missing required field: 'service_category'.",
                "allowed_categories": get_all_categories(),
            }

        sub_service = body.get("sub_service")
        pincode = body.get("location_pincode") or body.get("pincode") or "560038"
        urgency_raw = body.get("urgency", "standard")
        urgency = UrgencyLevel.from_str(str(urgency_raw))

        try:
            distance_km = float(body.get("distance_km", 3.5))
            if distance_km < 0:
                return 400, {"error": "Invalid 'distance_km': value cannot be negative."}
        except (ValueError, TypeError):
            return 400, {"error": "Invalid 'distance_km': must be a numeric value."}

        scheduled_hour = body.get("scheduled_hour")
        if scheduled_hour is not None:
            try:
                scheduled_hour = int(scheduled_hour)
                if not (0 <= scheduled_hour <= 23):
                    return 400, {"error": "Invalid 'scheduled_hour': must be between 0 and 23."}
            except (ValueError, TypeError):
                return 400, {"error": "Invalid 'scheduled_hour': must be an integer between 0 and 23."}

        is_weekend = bool(body.get("is_weekend", False))
        custom_demand_override = body.get("custom_demand_override")
        if custom_demand_override is not None:
            try:
                custom_demand_override = float(custom_demand_override)
                if custom_demand_override <= 0:
                    return 400, {"error": "Invalid 'custom_demand_override': must be positive."}
            except (ValueError, TypeError):
                return 400, {"error": "Invalid 'custom_demand_override': must be numeric."}

        req = PriceEstimationRequest(
            service_category=service,
            sub_service=sub_service,
            location_pincode=pincode,
            urgency=urgency,
            distance_km=distance_km,
            scheduled_hour=scheduled_hour,
            is_weekend=is_weekend,
            custom_demand_override=custom_demand_override,
            user_id=body.get("user_id"),
        )

        try:
            resp = self.engine.estimate_price(req)
            explanation = self.engine.explain_response(resp)
            resp_dict = resp.to_dict()
            resp_dict["structured_explanation"] = explanation
            return 200, resp_dict
        except ValueError as ve:
            return 400, {"error": str(ve), "allowed_skill_tiers": list(GOVT_MIN_WAGE_BY_TIER.keys())}
        except Exception as e:
            return 500, {"error": f"Internal estimation error: {str(e)}"}

    def _handle_batch_estimate(self, body: Dict[str, Any]) -> Tuple[int, Dict[str, Any]]:
        items = body.get("estimates", [])
        if not items:
            return 400, {"error": "Missing 'estimates' list in request body."}

        results = []
        for i, item in enumerate(items):
            service = item.get("service_category") or item.get("service_type")
            if not service:
                return 400, {
                    "error": f"Missing 'service_category' at item index {i}.",
                    "allowed_categories": get_all_categories(),
                }

            sub_service = item.get("sub_service")
            pincode = item.get("location_pincode") or "560038"
            urgency = UrgencyLevel.from_str(str(item.get("urgency", "standard")))
            try:
                distance = float(item.get("distance_km", 3.5))
            except (ValueError, TypeError):
                return 400, {"error": f"Invalid 'distance_km' at item index {i}."}
            hour = item.get("scheduled_hour")

            req = PriceEstimationRequest(
                service_category=service,
                sub_service=sub_service,
                location_pincode=pincode,
                urgency=urgency,
                distance_km=distance,
                scheduled_hour=int(hour) if hour is not None else None,
            )
            try:
                resp = self.engine.estimate_price(req)
                results.append(resp.to_dict())
            except ValueError as ve:
                return 400, {"error": str(ve)}

        return 200, {"count": len(results), "estimates": results}

    def _handle_compare_pricing(self, body: Dict[str, Any]) -> Tuple[int, Dict[str, Any]]:
        service = body.get("service_category") or body.get("service_type") or "plumbing"
        sub_service = body.get("sub_service")
        pincode = body.get("location_pincode") or "560038"
        urgency_raw = body.get("urgency", "standard")
        urgency = UrgencyLevel.from_str(str(urgency_raw))
        distance_km = float(body.get("distance_km", 3.5))

        req = PriceEstimationRequest(
            service_category=service,
            sub_service=sub_service,
            location_pincode=pincode,
            urgency=urgency,
            distance_km=distance_km,
        )

        try:
            comparison = self.engine.get_pricing_comparison(req)
            return 200, comparison
        except Exception as e:
            return 400, {"error": f"Comparison error: {str(e)}"}

    def _handle_demand_index(self, query: Dict[str, str]) -> Tuple[int, Dict[str, Any]]:
        pincode = query.get("pincode", "560038")
        try:
            hour = int(query.get("hour", 14))
        except (ValueError, TypeError):
            hour = 14
        is_weekend = query.get("is_weekend", "false").lower() in ("true", "1")
        custom = query.get("custom_override")
        override = None
        if custom is not None:
            try:
                override = float(custom)
            except (ValueError, TypeError):
                override = None

        mult, level, reason = self.engine.demand_forecaster.get_demand_index(
            pincode=pincode,
            hour=hour,
            is_weekend=is_weekend,
            custom_override=override,
        )

        return 200, {
            "pincode": pincode,
            "hour": hour,
            "is_weekend": is_weekend,
            "demand_multiplier": mult,
            "demand_level": level.value,
            "reason": reason,
        }
