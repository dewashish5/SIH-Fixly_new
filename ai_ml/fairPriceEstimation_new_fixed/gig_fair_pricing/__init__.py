"""
AI Model and Fair Price Estimation Engine for Gig Community Service App.
"""

from .core.types import (
    UrgencyLevel,
    DemandLevel,
    ServiceSpec,
    PriceEstimationRequest,
    PriceEstimationResponse,
    PriceBreakdown,
)
from .core.engine import FairPriceEngine
from .core.fairness import FairnessValidator
from .data.catalog import CATALOG, find_service_spec, get_all_categories
from .data.demand_zones import DemandForecaster
from .ml.model import MLPriceModel
from .api.routes import APIRouter
from .api.server import create_server, run_server

__version__ = "1.0.0"
__all__ = [
    "FairPriceEngine",
    "PriceEstimationRequest",
    "PriceEstimationResponse",
    "PriceBreakdown",
    "ServiceSpec",
    "UrgencyLevel",
    "DemandLevel",
    "FairnessValidator",
    "DemandForecaster",
    "MLPriceModel",
    "CATALOG",
    "find_service_spec",
    "get_all_categories",
    "APIRouter",
    "create_server",
    "run_server",
]
