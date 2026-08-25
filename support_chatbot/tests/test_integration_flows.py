import pytest
from gig_support_chatbot.core.types import Language, Role
from gig_support_chatbot.core.engine import ChatbotEngine


class TestIntegrationFlows:
    def setup_method(self):
        self.engine = ChatbotEngine()

    def test_full_customer_ticket_creation_flow(self):
        sid = "flow_cust_ticket_1"
        # Step 1: Start
        msg1 = self.engine.start_session(session_id=sid, role=Role.CUSTOMER, language=Language.ENGLISH)
        assert len(msg1.quick_replies) == 5

        # Step 2: Click 'Raise Ticket'
        msg2 = self.engine.process_message(session_id=sid, action_type="faq", payload={"faq_id": "cust_raise_ticket"})
        assert "category" in msg2.text.lower()
        assert len(msg2.quick_replies) >= 4

        # Step 3: Select category button
        msg3 = self.engine.process_message(session_id=sid, action_type="faq", payload={"faq_id": "ticket_cat_noshow"})
        assert "description" in msg3.text.lower()

        # Step 4: Submit description
        msg4 = self.engine.process_message(session_id=sid, text="Worker did not arrive and phone is switched off.")
        assert "Ticket Created Successfully" in msg4.text
        assert "TCK-" in msg4.text
        assert "24" in msg4.text  # SLA hours

    def test_full_worker_profile_guidance_flow(self):
        sid = "flow_work_profile_1"
        # Step 1: Start worker session in Hindi
        msg1 = self.engine.start_session(session_id=sid, role=Role.WORKER, language=Language.HINDI)
        assert "वर्कर" in msg1.text or "साथी" in msg1.text

        # Step 2: Select Profile Setup
        msg2 = self.engine.process_message(session_id=sid, action_type="faq", payload={"faq_id": "work_profile_setup"})
        assert "आधार कार्ड" in msg2.text or "दस्तावेज़" in msg2.text
        assert any(qr.id == "work_kyc_docs_list" for qr in msg2.quick_replies)

        # Step 3: Drilldown into KYC checklist
        msg3 = self.engine.process_message(session_id=sid, action_type="faq", payload={"faq_id": "work_kyc_docs_list"})
        assert "पैन कार्ड" in msg3.text
        assert "बैंक प्रमाण" in msg3.text

        # Step 4: Back to Main Menu
        msg4 = self.engine.process_message(session_id=sid, action_type="main_menu")
        assert len(msg4.quick_replies) == 4

    def test_customer_booking_inquiry_flow(self):
        sid = "flow_cust_bk_1"
        self.engine.start_session(session_id=sid, role=Role.CUSTOMER, language=Language.ENGLISH)

        # User asks for booking status
        msg2 = self.engine.process_message(session_id=sid, text="check my booking status")
        assert "My Bookings" in msg2.text or "Status" in msg2.text

        # User enters Booking ID
        msg3 = self.engine.process_message(session_id=sid, text="BK1002")
        assert "BK1002" in msg3.text
        assert "Suresh Sharma" in msg3.text
        assert "Confirmed" in msg3.text
