import pytest
from gig_support_chatbot.server.api_routes import APIRouter
from gig_support_chatbot.core.engine import ChatbotEngine


class TestIntegrationAPI:
    def setup_method(self):
        self.engine = ChatbotEngine()
        self.router = APIRouter(self.engine)

    def test_api_health(self):
        status, data = self.router.handle_request("GET", "/api/health")
        assert status == 200
        assert data["status"] == "healthy"
        assert data["module"] == "gig_support_chatbot"

    def test_api_chat_start(self):
        body = {
            "session_id": "api_sess_1",
            "role": "customer",
            "language": "en",
            "action": "start",
        }
        status, data = self.router.handle_request("POST", "/api/chat", body=body)
        assert status == 200
        assert data["session_id"] == "api_sess_1"
        assert "message" in data
        assert len(data["message"]["quick_replies"]) == 5

    def test_api_chat_message_flow(self):
        body = {
            "session_id": "api_sess_2",
            "role": "worker",
            "language": "hi",
            "message": "प्रोफ़ाइल कैसे बनाएं",
        }
        status, data = self.router.handle_request("POST", "/api/chat", body=body)
        assert status == 200
        assert "आधार" in data["message"]["text"] or "KYC" in data["message"]["text"]

    def test_api_get_faqs(self):
        status, data = self.router.handle_request("GET", "/api/faqs", query_params={"role": "customer", "lang": "en"})
        assert status == 200
        assert data["count"] >= 5
        assert any(f["id"] == "cust_book_service" for f in data["faqs"])

    def test_api_create_and_get_ticket(self):
        create_body = {
            "user_id": "cust_99",
            "role": "customer",
            "category": "Overcharge",
            "description": "Extra 100 charged by technician",
        }
        status, data = self.router.handle_request("POST", "/api/ticket", body=create_body)
        assert status == 201
        assert data["success"] is True
        t_id = data["ticket"]["ticket_id"]

        # Get Ticket
        get_status, get_data = self.router.handle_request("GET", f"/api/ticket/{t_id}")
        assert get_status == 200
        assert get_data["ticket"]["ticket_id"] == t_id

    def test_api_booking_status(self):
        status, data = self.router.handle_request("GET", "/api/booking-status", query_params={"booking_id": "BK1001", "lang": "en"})
        assert status == 200
        assert data["booking"]["booking_id"] == "BK1001"
        assert "Ramesh Kumar" in data["booking"]["worker_name"]

    def test_api_offers(self):
        status, data = self.router.handle_request("GET", "/api/offers", query_params={"lang": "hi"})
        assert status == 200
        assert data["count"] >= 4
        assert any(o["code"] == "FIRSTGIG" for o in data["offers"])

    def test_api_404_not_found(self):
        status, data = self.router.handle_request("GET", "/api/unknown_endpoint")
        assert status == 404
        assert "error" in data
