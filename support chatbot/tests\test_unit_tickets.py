import pytest
from gig_support_chatbot.core.types import Role
from gig_support_chatbot.data.tickets import TicketManager


class TestTickets:
    def setup_method(self):
        self.mgr = TicketManager()

    def test_create_ticket_success(self):
        ticket = self.mgr.create_ticket(
            user_id="user_123",
            role=Role.CUSTOMER,
            category="Delayed Worker",
            description="Worker has not reached location for 45 mins",
            order_id="BK1001",
            sla_hours=24,
        )
        assert ticket.ticket_id.startswith("TCK-")
        assert ticket.status == "OPEN"
        assert ticket.sla_hours == 24
        assert ticket.user_id == "user_123"

    def test_get_ticket_by_id(self):
        created = self.mgr.create_ticket(
            user_id="user_abc",
            role=Role.WORKER,
            category="Payout Issue",
            description="Weekly payout delayed by 2 days",
        )
        found = self.mgr.get_ticket(created.ticket_id)
        assert found is not None
        assert found.description == "Weekly payout delayed by 2 days"

    def test_update_ticket_status(self):
        created = self.mgr.create_ticket(
            user_id="user_xyz",
            role=Role.CUSTOMER,
            category="Quality",
            description="Cleaning incomplete",
        )
        success = self.mgr.update_status(created.ticket_id, "RESOLVED")
        assert success is True
        updated = self.mgr.get_ticket(created.ticket_id)
        assert updated.status == "RESOLVED"

    def test_list_tickets_for_user(self):
        uid = "user_multi_1"
        self.mgr.create_ticket(user_id=uid, role=Role.CUSTOMER, category="Cat 1", description="Desc 1")
        self.mgr.create_ticket(user_id=uid, role=Role.CUSTOMER, category="Cat 2", description="Desc 2")
        user_tickets = self.mgr.list_tickets_for_user(uid)
        assert len(user_tickets) == 2
