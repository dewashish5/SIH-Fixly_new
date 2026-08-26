import pytest
from gig_support_chatbot.core.types import Language, Role
from gig_support_chatbot.core.engine import ChatbotEngine


class TestE2EScenarios:
    def setup_method(self):
        self.engine = ChatbotEngine()

    def test_e2e_customer_fallback_and_recovery(self):
        sid = "e2e_cust_fallback"
        self.engine.start_session(session_id=sid, role=Role.CUSTOMER, language=Language.ENGLISH)

        # Unrecognized input
        msg1 = self.engine.process_message(session_id=sid, text="Can you order a pizza with extra cheese?")
        assert "couldn't find a direct match" in msg1.text or "choose from the topics below" in msg1.text
        assert len(msg1.quick_replies) >= 4

        # Recovery via button click
        msg2 = self.engine.process_message(session_id=sid, action_type="faq", payload={"faq_id": "cust_book_service"})
        assert "Step-by-Step" in msg2.text

    def test_e2e_rapid_language_switching_mid_flow(self):
        sid = "e2e_lang_switch"
        # Start in EN
        self.engine.start_session(session_id=sid, role=Role.CUSTOMER, language=Language.ENGLISH)
        msg_en = self.engine.process_message(session_id=sid, text="offers")
        assert "FIRSTGIG" in msg_en.text

        # Switch to Hindi mid-conversation
        msg_hi = self.engine.process_message(session_id=sid, language=Language.HINDI, text="ऑफ़र")
        assert "सक्रिय ऑफ़र" in msg_hi.text

        # Switch to Worker role mid-conversation
        msg_work = self.engine.process_message(session_id=sid, role=Role.WORKER, text="काम कैसे देखें")
        assert "सौंपे गए काम" in msg_work.text or "डैशबोर्ड" in msg_work.text

    def test_e2e_empty_input_graceful_handling(self):
        sid = "e2e_empty"
        self.engine.start_session(session_id=sid)
        msg = self.engine.process_message(session_id=sid, text="   ")
        assert msg is not None
        assert len(msg.quick_replies) >= 4
