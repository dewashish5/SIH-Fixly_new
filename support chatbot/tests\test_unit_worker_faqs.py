import pytest
from gig_support_chatbot.core.types import Language, Role
from gig_support_chatbot.core.engine import ChatbotEngine
from gig_support_chatbot.data.kb_worker import get_worker_faqs, get_worker_faq_by_id


class TestWorkerFAQs:
    def setup_method(self):
        self.engine = ChatbotEngine()

    def test_all_4_required_worker_categories_exist(self):
        faqs = get_worker_faqs()
        categories = {f.category for f in faqs}
        assert "jobs" in categories         # View assigned jobs
        assert "features" in categories     # How to use app features
        assert "ticket" in categories       # Raise a complaint/ticket
        assert "profile" in categories      # How to set up their profile

    def test_faq_assigned_jobs_flow(self):
        faq = get_worker_faq_by_id("work_assigned_jobs")
        assert faq is not None
        assert "ONLINE" in faq.get_answer(Language.ENGLISH)
        assert "ऑनलाइन" in faq.get_answer(Language.HINDI)
        assert "OTP" in faq.get_answer(Language.ENGLISH)
        assert len(faq.get_sub_options(Language.ENGLISH)) == 2

    def test_faq_worker_app_features(self):
        faq = get_worker_faq_by_id("work_app_features")
        assert faq is not None
        assert "Earnings Dashboard" in faq.get_answer(Language.ENGLISH)
        assert "कमाई डैशबोर्ड" in faq.get_answer(Language.HINDI)
        assert "Instant Payouts" in faq.get_answer(Language.ENGLISH)

    def test_faq_worker_raise_ticket(self):
        faq = get_worker_faq_by_id("work_raise_ticket")
        assert faq is not None
        assert faq.action_type == "ticket"
        sub_en = faq.get_sub_options(Language.ENGLISH)
        assert any("Payment" in s["label"] for s in sub_en)
        assert any("Safety" in s["label"] for s in sub_en)

    def test_faq_worker_profile_setup(self):
        faq = get_worker_faq_by_id("work_profile_setup")
        assert faq is not None
        assert "Aadhaar Card" in faq.get_answer(Language.ENGLISH)
        assert "आधार कार्ड" in faq.get_answer(Language.HINDI)
        assert "Bank Account" in faq.get_answer(Language.ENGLISH)
        assert len(faq.get_sub_options(Language.ENGLISH)) == 2
