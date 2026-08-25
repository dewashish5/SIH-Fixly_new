"""
REST API request handlers and route dispatcher.
"""

from typing import Any, Dict, Optional, Tuple
import json
from ..core.engine import ChatbotEngine
from ..core.types import Language, Role


class APIRouter:
    def __init__(self, engine: Optional[ChatbotEngine] = None):
        self.engine = engine or ChatbotEngine()

    def handle_request(
        self,
        method: str,
        path: str,
        body: Optional[Dict[str, Any]] = None,
        query_params: Optional[Dict[str, str]] = None,
    ) -> Tuple[int, Dict[str, Any]]:
        body = body or {}
        query_params = query_params or {}

        # 1. POST /api/chat
        if method == "POST" and path == "/api/chat":
            return self._handle_chat(body)

        # 2. GET /api/faqs
        if method == "GET" and path == "/api/faqs":
            return self._handle_get_faqs(query_params)

        # 3. POST /api/ticket
        if method == "POST" and path == "/api/ticket":
            return self._handle_create_ticket(body)

        # 4. GET /api/ticket
        if method == "GET" and (path == "/api/ticket" or path.startswith("/api/ticket/")):
            return self._handle_get_ticket(path, query_params)

        # 5. GET /api/booking-status
        if method == "GET" and path == "/api/booking-status":
            return self._handle_booking_status(query_params)

        # 6. GET /api/offers
        if method == "GET" and path == "/api/offers":
            return self._handle_get_offers(query_params)

        # 7. GET /api/health
        if method == "GET" and path == "/api/health":
            return 200, {
                "status": "healthy",
                "sessions_active": self.engine.session_manager.count(),
                "version": "1.0.0",
                "module": "gig_support_chatbot",
            }

        return 404, {"error": f"Endpoint '{method} {path}' not found."}

    def _handle_chat(self, body: Dict[str, Any]) -> Tuple[int, Dict[str, Any]]:
        session_id = body.get("session_id")
        user_id = body.get("user_id")
        text = body.get("message") or body.get("text") or ""
        action_type = body.get("action_type")
        payload = body.get("payload") or {}

        role_str = body.get("role", "customer")
        lang_str = body.get("language", "en")
        role = Role.from_str(role_str)
        language = Language.from_str(lang_str)

        # If starting new or initial ping
        if body.get("action") == "start" or (not text and not action_type):
            msg = self.engine.start_session(
                session_id=session_id,
                user_id=user_id,
                role=role,
                language=language,
            )
        else:
            msg = self.engine.process_message(
                session_id=session_id or "default_session",
                text=text,
                action_type=action_type,
                payload=payload,
                role=role,
                language=language,
            )

        session = self.engine.session_manager.get(session_id or "default_session")
        return 200, {
            "session_id": session.session_id if session else session_id,
            "role": session.role.value if session else role.value,
            "language": session.language.value if session else language.value,
            "message": msg.to_dict(),
        }

    def _handle_get_faqs(self, query: Dict[str, str]) -> Tuple[int, Dict[str, Any]]:
        role = Role.from_str(query.get("role", "customer"))
        lang = Language.from_str(query.get("lang", "en"))
        faqs = self.engine.get_faqs_for_role(role)
        results = [
            {
                "id": f.id,
                "category": f.category,
                "title": f.get_title(lang),
                "answer": f.get_answer(lang),
                "sub_options": f.get_sub_options(lang),
                "action_type": f.action_type,
            }
            for f in faqs
        ]
        return 200, {"role": role.value, "language": lang.value, "count": len(results), "faqs": results}

    def _handle_create_ticket(self, body: Dict[str, Any]) -> Tuple[int, Dict[str, Any]]:
        user_id = body.get("user_id", "guest_user")
        role = Role.from_str(body.get("role", "customer"))
        category = body.get("category", "General Issue")
        desc = body.get("description", "")
        order_id = body.get("order_id")

        if not desc or len(desc.strip()) < 3:
            return 400, {"error": "Description is required (minimum 3 characters)."}

        ticket = self.engine.ticket_manager.create_ticket(
            user_id=user_id,
            role=role,
            category=category,
            description=desc,
            order_id=order_id,
        )
        return 201, {"success": True, "ticket": ticket.to_dict()}

    def _handle_get_ticket(self, path: str, query: Dict[str, str]) -> Tuple[int, Dict[str, Any]]:
        ticket_id = path.split("/")[-1] if path != "/api/ticket" else query.get("ticket_id")
        if not ticket_id:
            return 400, {"error": "Missing ticket_id parameter."}

        ticket = self.engine.ticket_manager.get_ticket(ticket_id)
        if not ticket:
            return 404, {"error": f"Ticket '{ticket_id}' not found."}
        return 200, {"ticket": ticket.to_dict()}

    def _handle_booking_status(self, query: Dict[str, str]) -> Tuple[int, Dict[str, Any]]:
        booking_id = query.get("booking_id")
        lang = Language.from_str(query.get("lang", "en"))
        if not booking_id:
            return 400, {"error": "Missing booking_id parameter."}

        booking = self.engine.booking_manager.get_booking(booking_id)
        if not booking:
            return 404, {"error": f"Booking ID '{booking_id}' not found."}
        return 200, {"booking": booking.to_dict(lang)}

    def _handle_get_offers(self, query: Dict[str, str]) -> Tuple[int, Dict[str, Any]]:
        lang = Language.from_str(query.get("lang", "en"))
        from ..data.offers import get_active_offers
        offers = get_active_offers(lang)
        return 200, {"count": len(offers), "language": lang.value, "offers": offers}
