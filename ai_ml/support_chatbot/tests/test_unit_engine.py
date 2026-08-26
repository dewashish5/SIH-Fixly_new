import pytest
from gig_support_chatbot.core.types import Language, Role, Sender
from gig_support_chatbot.core.engine import ChatbotEngine
from gig_support_chatbot.core.session import SessionManager


class TestChatbotEngine:
    def setup_method(self):
        self.engine = ChatbotEngine()

    def test_start_session_customer_en(self):
        msg = self.engine.start_session(session_id="s_cust_1", role=Role.CUSTOMER, language=Language.ENGLISH)
        assert msg.sender == Sender.BOT
        assert "Welcome to GigCommunity Customer Support" in msg.text
        assert len(msg.quick_replies) == 5
        assert any(qr.id == "cust_book_service" for qr in msg.quick_replies)
        assert any(qr.id == "cust_view_offers" for qr in msg.quick_replies)
        assert any(qr.id == "cust_booking_status" for qr in msg.quick_replies)
        assert any(qr.id == "cust_app_features" for qr in msg.quick_replies)
        assert any(qr.id == "cust_raise_ticket" for qr in msg.quick_replies)

    def test_start_session_worker_hi(self):
        msg = self.engine.start_session(session_id="s_work_1", role=Role.WORKER, language=Language.HINDI)
        assert msg.sender == Sender.BOT
        assert "वर्कर सहायता केंद्र" in msg.text or "नमस्ते साथी" in msg.text
        assert len(msg.quick_replies) == 4
        assert any(qr.id == "work_assigned_jobs" for qr in msg.quick_replies)
        assert any(qr.id == "work_app_features" for qr in msg.quick_replies)
        assert any(qr.id == "work_raise_ticket" for qr in msg.quick_replies)
        assert any(qr.id == "work_profile_setup" for qr in msg.quick_replies)

    def test_switch_role_and_language_dynamically(self):
        session_id = "s_dyn_1"
        msg1 = self.engine.start_session(session_id=session_id, role=Role.CUSTOMER, language=Language.ENGLISH)
        assert "Customer Support" in msg1.text

        msg2 = self.engine.process_message(session_id=session_id, role=Role.WORKER, language=Language.HINDI, action_type="main_menu")
        assert "वर्कर" in msg2.text or "साथी" in msg2.text

        session = self.engine.session_manager.get(session_id)
        assert session.role == Role.WORKER
        assert session.language == Language.HINDI

    def test_reset_and_menu_navigation(self):
        session_id = "s_nav_1"
        self.engine.start_session(session_id=session_id)
        # Ask question
        self.engine.process_message(session_id=session_id, text="offers")
        # Trigger reset
        msg = self.engine.process_message(session_id=session_id, action_type="reset")
        assert "Welcome" in msg.text
        assert len(msg.quick_replies) >= 4

    def test_contact_human_agent_flow(self):
        session_id = "s_human_1"
        self.engine.start_session(session_id=session_id)
        msg = self.engine.process_message(session_id=session_id, action_type="contact_human")
        assert "1800-GIG-HELP" in msg.text
        assert "support@gigcommunity.app" in msg.text

    def test_feedback_acknowledgment(self):
        session_id = "s_fb_1"
        self.engine.start_session(session_id=session_id)
        msg = self.engine.process_message(session_id=session_id, action_type="feedback")
        assert "feedback" in msg.text.lower() or "धन्यवाद" in msg.text
