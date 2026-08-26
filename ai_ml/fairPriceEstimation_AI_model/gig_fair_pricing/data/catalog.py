"""
Comprehensive Gig Service Catalog with Baseline Pricing, Durations, and Skill Multipliers.
"""

from typing import Dict, List, Optional
from ..core.types import ServiceSpec


CATALOG: Dict[str, List[ServiceSpec]] = {
    "plumbing": [
        ServiceSpec(
            category="plumbing",
            sub_service="tap_and_pipe_repair",
            base_rate=249.0,
            unit="job",
            est_duration_mins=45,
            skill_tier="standard",
            min_price_floor=199.0,
            max_price_ceiling=650.0,
            description="Fix leaking taps, minor pipe blocks, and washbasin fittings.",
        ),
        ServiceSpec(
            category="plumbing",
            sub_service="toilet_and_sanitary_fitting",
            base_rate=399.0,
            unit="job",
            est_duration_mins=75,
            skill_tier="skilled",
            min_price_floor=299.0,
            max_price_ceiling=950.0,
            description="Flush tank repair, western commode fitting, and jet spray replacement.",
        ),
        ServiceSpec(
            category="plumbing",
            sub_service="water_tank_and_motor_pipeline",
            base_rate=599.0,
            unit="job",
            est_duration_mins=120,
            skill_tier="master",
            min_price_floor=449.0,
            max_price_ceiling=1400.0,
            description="Overhead tank leakage, motorized pump connection, and main pipeline repair.",
        ),
    ],
    "electrical": [
        ServiceSpec(
            category="electrical",
            sub_service="fan_and_switch_repair",
            base_rate=199.0,
            unit="job",
            est_duration_mins=30,
            skill_tier="standard",
            min_price_floor=149.0,
            max_price_ceiling=500.0,
            description="Ceiling fan installation, modular switchboard repair, and light socket replacement.",
        ),
        ServiceSpec(
            category="electrical",
            sub_service="mcb_and_short_circuit_fix",
            base_rate=349.0,
            unit="job",
            est_duration_mins=60,
            skill_tier="skilled",
            min_price_floor=249.0,
            max_price_ceiling=850.0,
            description="Tripping MCB diagnosis, fuse box repair, and electrical short circuit fix.",
        ),
        ServiceSpec(
            category="electrical",
            sub_service="full_house_wiring_inspection",
            base_rate=699.0,
            unit="job",
            est_duration_mins=120,
            skill_tier="master",
            min_price_floor=499.0,
            max_price_ceiling=1800.0,
            description="Complete electrical earthing, load audit, and wiring rewiring.",
        ),
    ],
    "ac_repair": [
        ServiceSpec(
            category="ac_repair",
            sub_service="ac_filter_and_jet_servicing",
            base_rate=499.0,
            unit="appliance",
            est_duration_mins=60,
            skill_tier="skilled",
            min_price_floor=399.0,
            max_price_ceiling=1100.0,
            description="Deep jet pump cleaning of indoor cooling coils and outdoor condenser.",
        ),
        ServiceSpec(
            category="ac_repair",
            sub_service="ac_gas_refill_and_leak_fix",
            base_rate=1299.0,
            unit="appliance",
            est_duration_mins=90,
            skill_tier="master",
            min_price_floor=999.0,
            max_price_ceiling=2800.0,
            description="Nitrogen pressure testing, copper pipe brazing, and complete R32/R410A gas charging.",
        ),
    ],
    "cleaning": [
        ServiceSpec(
            category="cleaning",
            sub_service="bathroom_deep_cleaning",
            base_rate=399.0,
            unit="room",
            est_duration_mins=60,
            skill_tier="standard",
            min_price_floor=299.0,
            max_price_ceiling=900.0,
            description="Tile descaling, toilet scrubbing, mirror polishing, and exhaust degreasing.",
        ),
        ServiceSpec(
            category="cleaning",
            sub_service="full_home_deep_cleaning_2bhk",
            base_rate=1499.0,
            unit="job",
            est_duration_mins=240,
            skill_tier="skilled",
            min_price_floor=1199.0,
            max_price_ceiling=3500.0,
            description="Complete 2 BHK floor scrubbing, balcony wash, kitchen chimney degreasing, and cobweb removal.",
        ),
    ],
    "appliance_repair": [
        ServiceSpec(
            category="appliance_repair",
            sub_service="washing_machine_repair",
            base_rate=349.0,
            unit="appliance",
            est_duration_mins=60,
            skill_tier="skilled",
            min_price_floor=249.0,
            max_price_ceiling=900.0,
            description="Drum noise, spin cycle error, water intake motor, and PCB diagnosis.",
        ),
        ServiceSpec(
            category="appliance_repair",
            sub_service="refrigerator_repair",
            base_rate=399.0,
            unit="appliance",
            est_duration_mins=60,
            skill_tier="skilled",
            min_price_floor=299.0,
            max_price_ceiling=1000.0,
            description="Compressor troubleshooting, defrost timer issue, and thermostat replacement.",
        ),
    ],
    "carpentry": [
        ServiceSpec(
            category="carpentry",
            sub_service="furniture_assembly_and_hinges",
            base_rate=299.0,
            unit="job",
            est_duration_mins=60,
            skill_tier="standard",
            min_price_floor=220.0,
            max_price_ceiling=750.0,
            description="Bed/wardrobe assembly, drawer channel alignment, and hydraulic hinge replacement.",
        ),
        ServiceSpec(
            category="carpentry",
            sub_service="door_lock_and_latches",
            base_rate=349.0,
            unit="job",
            est_duration_mins=45,
            skill_tier="skilled",
            min_price_floor=249.0,
            max_price_ceiling=850.0,
            description="Main door mortise lock installation, deadbolt fitting, and handle alignment.",
        ),
    ],
    "painting": [
        ServiceSpec(
            category="painting",
            sub_service="single_room_repaint",
            base_rate=1199.0,
            unit="room",
            est_duration_mins=180,
            skill_tier="skilled",
            min_price_floor=899.0,
            max_price_ceiling=2800.0,
            description="Wall putty touch-up, primer coat, and 2 coats of premium emulsion paint.",
        ),
    ],
    "pest_control": [
        ServiceSpec(
            category="pest_control",
            sub_service="cockroach_and_ant_treatment",
            base_rate=599.0,
            unit="job",
            est_duration_mins=45,
            skill_tier="standard",
            min_price_floor=449.0,
            max_price_ceiling=1200.0,
            description="Odorless herbal gel baiting and chemical spray in kitchen & bathrooms.",
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
        # Check if category is actually a sub_service name
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
