"""
Support Ticket and Complaint store, validator, and tracker.
"""

from typing import Dict, List, Optional
import random
import time
import threading
from ..core.types import Language, Role, SupportTicket


class TicketManager:
    def __init__(self):
        self._tickets: Dict[str, SupportTicket] = {}
        self._lock = threading.RLock()
        self._seed_sample_tickets()

    def _seed_sample_tickets(self):
        sample = SupportTicket(
            ticket_id="TCK-10081",
            user_id="user_demo_1",
            role=Role.CUSTOMER,
            category="Worker Delayed",
            description="Worker Ramesh was 30 mins delayed for cleaning job",
            status="RESOLVED",
            created_at=time.time() - 7200,
            order_id="BK1001",
            sla_hours=24,
        )
        self._tickets[sample.ticket_id] = sample

    def generate_ticket_id(self) -> str:
        random_num = random.randint(10000, 99999)
        return f"TCK-{random_num}"

    def create_ticket(
        self,
        user_id: str,
        role: Role,
        category: str,
        description: str,
        order_id: Optional[str] = None,
        contact: Optional[str] = None,
        sla_hours: int = 24,
    ) -> SupportTicket:
        with self._lock:
            ticket_id = self.generate_ticket_id()
            while ticket_id in self._tickets:
                ticket_id = self.generate_ticket_id()

            ticket = SupportTicket(
                ticket_id=ticket_id,
                user_id=user_id,
                role=role,
                category=category.strip(),
                description=description.strip(),
                status="OPEN",
                created_at=time.time(),
                order_id=order_id,
                contact=contact,
                sla_hours=sla_hours,
            )
            self._tickets[ticket_id] = ticket
            return ticket

    def get_ticket(self, ticket_id: str) -> Optional[SupportTicket]:
        with self._lock:
            clean_id = (ticket_id or "").strip().upper()
            if not clean_id.startswith("TCK-") and clean_id.isdigit():
                clean_id = f"TCK-{clean_id}"
            return self._tickets.get(clean_id)

    def list_tickets_for_user(self, user_id: str) -> List[SupportTicket]:
        with self._lock:
            return [t for t in self._tickets.values() if t.user_id == user_id]

    def list_all_tickets(self) -> List[SupportTicket]:
        with self._lock:
            return list(self._tickets.values())

    def update_status(self, ticket_id: str, new_status: str) -> bool:
        with self._lock:
            ticket = self.get_ticket(ticket_id)
            if ticket:
                ticket.status = new_status.upper()
                return True
            return False
