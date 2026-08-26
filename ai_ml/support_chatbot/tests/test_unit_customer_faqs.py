import pytest
from gig_support_chatbot.core.types import Language, Role
from gig_support_chatbot.core.engine import ChatbotEngine
from gig_support_chatbot.data.kb_customer import get_customer_faqs, get_customer_faq_by_id


class TestCustomerFAQs:
    def setup_method(self):
        self.engine = ChatbotEngine()

    def test_all_5_required_customer_categories_exist(self):
        faqs = get_customer_faqs()
        categories = {f.category for f in faqs}
        assert "booking" in categories     # How to book a service
        assert "offers" in categories      # View current offers
        assert "status" in categories      # Check order/booking status
        assert "features" in categories    # How to use app features
        assert "ticket" in categories      # Raise a complaint/ticket

    def test_faq_book_service_flow(self):
        faq = get_customer_faq_by_id("cust_book_service")
        assert faq is not None
        assert "Step-by-Step" in faq.get_answer(Language.ENGLISH)
        assert "सेवा बुक करने के आसान चरण" in faq.get_answer(Language.HINDI)
        assert len(faq.get_sub_options(Language.ENGLISH)) == 3
        assert len(faq.get_sub_options(Language.HINDI)) == 3

    def test_faq_view_offers_flow(self):
        msg = self.engine.process_message(session_id="s_test_offers", role=Role.CUSTOMER, text="What are the current offers?")
        assert "FIRSTGIG" in msg.text
        assert "SUMMER50" in msg.text
        assert "REFER50" in msg.text

    def test_faq_booking_status_lookup(self):
        msg = self.engine.process_message(session_id="s_test_status", role=Role.CUSTOMER, text="BK1001")
        assert "BK1001" in msg.text
        assert "Ramesh Kumar" in msg.text
        assert "Cleaning" in msg.text

    def test_faq_app_features(self):
        faq = get_customer_faq_by_id("cust_app_features")
        assert faq is not None
        assert "Favorite Workers" in faq.get_answer(Language.ENGLISH)
        assert "पसंदीदा कार्यकर्ता" in faq.get_answer(Language.HINDI)

    def test_faq_raise_ticket_categories(self):
        faq = get_customer_faq_by_id("cust_raise_ticket")
        assert faq is not None
        assert faq.action_type == "ticket"
        sub_en = faq.get_sub_options(Language.ENGLISH)
        assert any("Delayed" in s["label"] for s in sub_en)
        assert any("Quality" in s["label"] for s in sub_en)
        assert any("Billing" in s["label"] for s in sub_en)
