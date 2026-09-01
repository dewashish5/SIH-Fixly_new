"""
Comprehensive Gig Service Catalog with Programmatic Baseline Pricing.

All service baseline prices are dynamically computed from the central
statutory pricing formula:
    Base Price = (Govt Minimum Wage * 1.8 * Duration Hours) / (1 - Platform Commission Rate)

Sources:
- Ministry of Labour & Employment, Government of India (Central Sphere Minimum Wages)
  * Semi-Skilled ("standard")    : ₹108 / hour
  * Skilled ("skilled")          : ₹119 / hour
  * Highly Skilled ("master")    : ₹129 / hour
- Platform Commission Rate       : 15% (Worker share: 85%)
- Fair Living Wage Markup Factor : 1.8x
"""

from typing import Dict, List, Optional
from ..core.constants import (
    calculate_baseline_price,
    GOVT_MIN_WAGE_BY_TIER,
    SKILL_TIER_LABELS,
)
from ..core.types import ServiceSpec


def _build_service_spec(
    category: str,
    sub_service: str,
    unit: str,
    est_duration_mins: int,
    skill_tier: str,
    description: str,
    floor_ratio: float = 0.80,
    ceiling_ratio: float = 2.60,
) -> ServiceSpec:
    """Helper to construct a ServiceSpec with programmatically calculated base rate and bounds."""
    base_rate = calculate_baseline_price(skill_tier=skill_tier, duration_mins=est_duration_mins)
    min_floor = round(base_rate * floor_ratio, 2)
    max_ceiling = round(base_rate * ceiling_ratio, 2)
    return ServiceSpec(
        category=category,
        sub_service=sub_service,
        base_rate=base_rate,
        unit=unit,
        est_duration_mins=est_duration_mins,
        skill_tier=skill_tier,
        min_price_floor=min_floor,
        max_price_ceiling=max_ceiling,
        description=description,
    )


CATALOG: Dict[str, List[ServiceSpec]] = {
    "plumbing": [
        _build_service_spec(
            category="plumbing",
            sub_service="tap_and_pipe_repair",
            unit="job",
            est_duration_mins=45,
            skill_tier="standard",
            description="Fix leaking taps, minor pipe blocks, and washbasin fittings.",
        ),
        _build_service_spec(
            category="plumbing",
            sub_service="toilet_and_sanitary_fitting",
            unit="job",
            est_duration_mins=75,
            skill_tier="skilled",
            description="Flush tank repair, western commode fitting, and jet spray replacement.",
        ),
        _build_service_spec(
            category="plumbing",
            sub_service="water_tank_and_motor_pipeline",
            unit="job",
            est_duration_mins=120,
            skill_tier="master",
            description="Overhead tank leakage, motorized pump connection, and main pipeline repair.",
        ),
    ],
    "electrical": [
        _build_service_spec(
            category="electrical",
            sub_service="fan_and_switch_repair",
            unit="job",
            est_duration_mins=30,
            skill_tier="standard",
            description="Ceiling fan installation, modular switchboard repair, and light socket replacement.",
        ),
        _build_service_spec(
            category="electrical",
            sub_service="mcb_and_short_circuit_fix",
            unit="job",
            est_duration_mins=60,
            skill_tier="skilled",
            description="Tripping MCB diagnosis, fuse box repair, and electrical short circuit fix.",
        ),
        _build_service_spec(
            category="electrical",
            sub_service="full_house_wiring_inspection",
            unit="job",
            est_duration_mins=120,
            skill_tier="master",
            description="Complete electrical earthing, load audit, and wiring rewiring.",
        ),
    ],
    "ac_repair": [
        _build_service_spec(
            category="ac_repair",
            sub_service="ac_filter_and_jet_servicing",
            unit="appliance",
            est_duration_mins=60,
            skill_tier="skilled",
            description="Deep jet pump cleaning of indoor cooling coils and outdoor condenser.",
        ),
        _build_service_spec(
            category="ac_repair",
            sub_service="ac_gas_refill_and_leak_fix",
            unit="appliance",
            est_duration_mins=90,
            skill_tier="master",
            description="Nitrogen pressure testing, copper pipe brazing, and complete R32/R410A gas charging (labour fee; materials billed separately).",
        ),
    ],
    "cleaning": [
        _build_service_spec(
            category="cleaning",
            sub_service="bathroom_deep_cleaning",
            unit="room",
            est_duration_mins=60,
            skill_tier="standard",
            description="Tile descaling, toilet scrubbing, mirror polishing, and exhaust degreasing.",
        ),
        _build_service_spec(
            category="cleaning",
            sub_service="full_home_deep_cleaning_2bhk",
            unit="job",
            est_duration_mins=240,
            skill_tier="skilled",
            description="Complete 2 BHK floor scrubbing, balcony wash, kitchen chimney degreasing, and cobweb removal.",
        ),
    ],
    "appliance_repair": [
        _build_service_spec(
            category="appliance_repair",
            sub_service="washing_machine_repair",
            unit="appliance",
            est_duration_mins=60,
            skill_tier="skilled",
            description="Drum noise, spin cycle error, water intake motor, and PCB diagnosis.",
        ),
        _build_service_spec(
            category="appliance_repair",
            sub_service="refrigerator_repair",
            unit="appliance",
            est_duration_mins=60,
            skill_tier="skilled",
            description="Compressor troubleshooting, defrost timer issue, and thermostat replacement.",
        ),
    ],
    "carpentry": [
        _build_service_spec(
            category="carpentry",
            sub_service="furniture_assembly_and_hinges",
            unit="job",
            est_duration_mins=60,
            skill_tier="standard",
            description="Bed/wardrobe assembly, drawer channel alignment, and hydraulic hinge replacement.",
        ),
        _build_service_spec(
            category="carpentry",
            sub_service="door_lock_and_latches",
            unit="job",
            est_duration_mins=45,
            skill_tier="skilled",
            description="Main door mortise lock installation, deadbolt fitting, and handle alignment.",
        ),
    ],
    "painting": [
        _build_service_spec(
            category="painting",
            sub_service="single_room_repaint",
            unit="room",
            est_duration_mins=180,
            skill_tier="skilled",
            description="Wall putty touch-up, primer coat, and 2 coats of premium emulsion paint (labour fee; materials billed separately).",
        ),
    ],
    "pest_control": [
        _build_service_spec(
            category="pest_control",
            sub_service="cockroach_and_ant_treatment",
            unit="job",
            est_duration_mins=45,
            skill_tier="standard",
            description="Odorless herbal gel baiting and chemical spray in kitchen & bathrooms (labour fee; materials billed separately).",
        ),
    ],
}


def get_all_categories() -> List[str]:
    return list(CATALOG.keys())


def get_service_specs(category: str) -> List[ServiceSpec]:
    cat = (category or "").strip().lower()
    return CATALOG.get(cat, [])


def find_service_spec(category: str, sub_service: Optional[str] = None) -> Optional[ServiceSpec]:
    cat = (category or "").strip().lower()
    specs = CATALOG.get(cat)
    if not specs:
        # Check if category matches a sub_service name
        for c, s_list in CATALOG.items():
            for s in s_list:
                if s.sub_service.lower() == cat or cat in s.sub_service.lower():
                    return s
        return None

    if not sub_service:
        return specs[0]  # Default to primary sub-service

    sub = sub_service.strip().lower()
    for s in specs:
        if s.sub_service.lower() == sub or sub in s.sub_service.lower():
            return s

    return specs[0]
