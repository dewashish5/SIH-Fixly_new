import pytest
from gig_support_chatbot.core.matcher import IntentMatcher, normalize_text, tokenize
from gig_support_chatbot.core.types import Language, Role
from gig_support_chatbot.data.kb_customer import get_customer_faqs
from gig_support_chatbot.data.kb_worker import get_worker_faqs


class TestIntentMatcher:
    def setup_method(self):
        self.matcher = IntentMatcher()
        self.cust_faqs = get_customer_faqs()
        self.work_faqs = get_worker_faqs()

    def test_text_normalization(self):
        assert normalize_text("  How to Book a Service?! ") == "how to book a service"
        assert normalize_text("सेवा कैसे बुक करें???") == "सेवा कैसे बुक करें"
        assert normalize_text("") == ""

    def test_tokenization(self):
        tokens = tokenize("Book a plumber now!")
        assert tokens == ["book", "a", "plumber", "now"]
        hi_tokens = tokenize("बुकिंग की स्थिति")
        assert hi_tokens == ["बुकिंग", "की", "स्थिति"]

    def test_customer_english_matching(self):
        queries = [
            ("how do i book a service", "cust_book_service"),
            ("view offers and coupons", "cust_view_offers"),
            ("track my order status", "cust_booking_status"),
            ("app features overview", "cust_app_features"),
            ("i want to raise a complaint", "cust_raise_ticket"),
            ("reschedule my appointment", "cust_reschedule"),
            ("how to cancel booking", "cust_cancel_booking"),
            ("accepted payment methods", "cust_payment_methods"),
        ]
        for query, expected_id in queries:
            result = self.matcher.match_faq(query, self.cust_faqs, Language.ENGLISH)
            assert result is not None, f"Failed to match '{query}'"
            faq, score = result
            assert faq.id == expected_id, f"Expected {expected_id} for '{query}', got {faq.id}"
            assert score >= 0.40

    def test_customer_hindi_matching(self):
        queries = [
            ("सेवा कैसे बुक करें", "cust_book_service"),
            ("ऑफर और छूट दिखाएं", "cust_view_offers"),
            ("बुकिंग की स्थिति जांचें", "cust_booking_status"),
            ("शिकायत दर्ज करें", "cust_raise_ticket"),
            ("समय कैसे बदलें", "cust_reschedule"),
            ("बुकिंग रद्द करनी है", "cust_cancel_booking"),
        ]
        for query, expected_id in queries:
            result = self.matcher.match_faq(query, self.cust_faqs, Language.HINDI)
            assert result is not None, f"Failed to match Hindi query '{query}'"
            faq, score = result
            assert faq.id == expected_id, f"Expected {expected_id} for '{query}', got {faq.id}"
            assert score >= 0.40

    def test_worker_english_matching(self):
        queries = [
            ("how to view assigned jobs", "work_assigned_jobs"),
            ("how to use worker app features", "work_app_features"),
            ("raise a grievance ticket", "work_raise_ticket"),
            ("how to complete kyc and profile", "work_profile_setup"),
            ("instant payout withdrawal", "work_payout_guide"),
            ("documents checklist for kyc", "work_kyc_docs_list"),
        ]
        for query, expected_id in queries:
            result = self.matcher.match_faq(query, self.work_faqs, Language.ENGLISH)
            assert result is not None, f"Failed to match worker query '{query}'"
            faq, score = result
            assert faq.id == expected_id, f"Expected {expected_id} for '{query}', got {faq.id}"

    def test_worker_hindi_matching(self):
        queries = [
            ("सौंपे गए काम कैसे देखें", "work_assigned_jobs"),
            ("कमाई कैसे निकालें पेआउट", "work_payout_guide"),
            ("प्रोफ़ाइल और केवाईसी कैसे बनाएं", "work_profile_setup"),
            ("शिकायत दर्ज करें", "work_raise_ticket"),
        ]
        for query, expected_id in queries:
            result = self.matcher.match_faq(query, self.work_faqs, Language.HINDI)
            assert result is not None, f"Failed to match worker Hindi query '{query}'"
            faq, score = result
            assert faq.id == expected_id, f"Expected {expected_id} for '{query}', got {faq.id}"

    def test_unrecognized_query_returns_none(self):
        result = self.matcher.match_faq("quantum astrophysics formula xyz999", self.cust_faqs, Language.ENGLISH)
        assert result is None
