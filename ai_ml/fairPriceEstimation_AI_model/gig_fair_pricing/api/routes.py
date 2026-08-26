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
except ImportError:
    from gig_fair_pricing.core.engine import FairPriceEngine
    from gig_fair_pricing.core.types import PriceEstimationRequest, UrgencyLevel


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

        # 5. GET /api/health
        if method == "GET" and path == "/api/health":
            return 200, {
                "status": "healthy",
                "service": "gig_fair_pricing",
                "version": "1.0.0",
                "ml_model_loaded": self.engine.ml_model.sklearn_model is not None,
            }

        return 404, {"error": f"Endpoint '{method} {path}' not found."}

    def _handle_estimate_price(self, body: Dict[str, Any]) -> Tuple[int, Dict[str, Any]]:
        service = body.get("service_category") or body.get("service_type") or body.get("service")
        if not service:
            return 400, {"error": "Missing required field: 'service_category'."}

        sub_service = body.get("sub_service")
        pincode = body.get("location_pincode") or body.get("pincode") or "560038"
        urgency_raw = body.get("urgency", "standard")
        urgency = UrgencyLevel.from_str(str(urgency_raw))

        distance_km = float(body.get("distance_km", 3.5))
        scheduled_hour = body.get("scheduled_hour")
        if scheduled_hour is not None:
            scheduled_hour = int(scheduled_hour)

        is_weekend = bool(body.get("is_weekend", False))
        custom_demand_override = body.get("custom_demand_override")
        if custom_demand_override is not None:
            custom_demand_override = float(custom_demand_override)

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

        resp = self.engine.estimate_price(req)
        return 200, resp.to_dict()

    def _handle_batch_estimate(self, body: Dict[str, Any]) -> Tuple[int, Dict[str, Any]]:
        items = body.get("estimates", [])
        if not items:
            return 400, {"error": "Missing 'estimates' list in request body."}

        results = []
        for item in items:
            service = item.get("service_category") or item.get("service_type")
            sub_service = item.get("sub_service")
            pincode = item.get("location_pincode") or "560038"
            urgency = UrgencyLevel.from_str(str(item.get("urgency", "standard")))
            distance = float(item.get("distance_km", 3.5))
            hour = item.get("scheduled_hour")

            req = PriceEstimationRequest(
                service_category=service or "plumbing",
                sub_service=sub_service,
                location_pincode=pincode,
                urgency=urgency,
                distance_km=distance,
                scheduled_hour=int(hour) if hour is not None else None,
            )
            resp = self.engine.estimate_price(req)
            results.append(resp.to_dict())

        return 200, {"count": len(results), "estimates": results}

    def _handle_demand_index(self, query: Dict[str, str]) -> Tuple[int, Dict[str, Any]]:
        pincode = query.get("pincode", "560038")
        hour = int(query.get("hour", 14))
        is_weekend = query.get("is_weekend", "false").lower() in ("true", "1")
        custom = query.get("custom_override")
        override = float(custom) if custom is not None else None

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
