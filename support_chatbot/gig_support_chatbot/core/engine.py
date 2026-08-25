"""
Core Chatbot Conversation Engine, State Machine, and Dispatcher.
"""

from typing import Any, Dict, List, Optional
import re
from .types import (
    ChatMessage,
    FAQItem,
    Language,
    QuickReply,
    Role,
    Sender,
    SupportTicket,
)
from .session import ChatSession, SessionManager
from .matcher import IntentMatcher
from ..i18n.translations import get_text
from ..data.kb_customer import get_customer_faqs, get_customer_faq_by_id
from ..data.kb_worker import get_worker_faqs, get_worker_faq_by_id
from ..data.offers import format_offers_message
from ..data.bookings import BookingManager
from ..data.tickets import TicketManager


class ChatbotEngine:
    def __init__(
        self,
        session_manager: Optional[SessionManager] = None,
        booking_manager: Optional[BookingManager] = None,
        ticket_manager: Optional[TicketManager] = None,
    ):
        self.session_manager = session_manager or SessionManager()
        self.booking_manager = booking_manager or BookingManager()
        self.ticket_manager = ticket_manager or TicketManager()
        self.matcher = IntentMatcher()

    def get_faqs_for_role(self, role: Role) -> List[FAQItem]:
        if role == Role.WORKER:
            return get_worker_faqs()
        return get_customer_faqs()

    def get_main_menu_quick_replies(self, role: Role, lang: Language) -> List[QuickReply]:
        if role == Role.CUSTOMER:
            return [
                QuickReply(
                    id="cust_book_service",
                    label=get_text("cust_menu_book_service", lang),
                    action_type="faq",
                    payload={"faq_id": "cust_book_service"},
                    icon="📅",
                ),
                QuickReply(
                    id="cust_view_offers",
                    label=get_text("cust_menu_view_offers", lang),
                    action_type="faq",
                    payload={"faq_id": "cust_view_offers"},
                    icon="🏷️",
                ),
                QuickReply(
                    id="cust_booking_status",
                    label=get_text("cust_menu_booking_status", lang),
                    action_type="faq",
                    payload={"faq_id": "cust_booking_status"},
                    icon="🔍",
                ),
                QuickReply(
                    id="cust_app_features",
                    label=get_text("cust_menu_app_features", lang),
                    action_type="faq",
                    payload={"faq_id": "cust_app_features"},
                    icon="📱",
                ),
                QuickReply(
                    id="cust_raise_ticket",
                    label=get_text("cust_menu_raise_ticket", lang),
                    action_type="faq",
                    payload={"faq_id": "cust_raise_ticket"},
                    icon="🎫",
                ),
            ]
        else:
            return [
                QuickReply(
                    id="work_assigned_jobs",
                    label=get_text("work_menu_assigned_jobs", lang),
                    action_type="faq",
                    payload={"faq_id": "work_assigned_jobs"},
                    icon="📋",
                ),
                QuickReply(
                    id="work_app_features",
                    label=get_text("work_menu_app_features", lang),
                    action_type="faq",
                    payload={"faq_id": "work_app_features"},
                    icon="⚙️",
                ),
                QuickReply(
                    id="work_raise_ticket",
                    label=get_text("work_menu_raise_ticket", lang),
                    action_type="faq",
                    payload={"faq_id": "work_raise_ticket"},
                    icon="🎫",
                ),
                QuickReply(
                    id="work_profile_setup",
                    label=get_text("work_menu_profile_setup", lang),
                    action_type="faq",
                    payload={"faq_id": "work_profile_setup"},
                    icon="👤",
                ),
            ]

    def start_session(
        self,
        session_id: Optional[str] = None,
        user_id: Optional[str] = None,
        role: Role = Role.CUSTOMER,
        language: Language = Language.ENGLISH,
    ) -> ChatMessage:
        session = self.session_manager.get_or_create(
            session_id=session_id,
            user_id=user_id,
            role=role,
            language=language,
        )
        session.clear_history()

        welcome_key = "welcome_worker" if session.role == Role.WORKER else "welcome_customer"
        welcome_text = get_text(welcome_key, session.language)
        quick_replies = self.get_main_menu_quick_replies(session.role, session.language)

        return session.add_message(
            sender=Sender.BOT,
            text=welcome_text,
            quick_replies=quick_replies,
            metadata={"view": "main_menu", "role": session.role.value, "lang": session.language.value},
        )

    def process_message(
        self,
        session_id: str,
        text: str = "",
        action_type: Optional[str] = None,
        payload: Optional[Dict[str, Any]] = None,
        role: Optional[Role] = None,
        language: Optional[Language] = None,
    ) -> ChatMessage:
        session = self.session_manager.get_or_create(
            session_id=session_id,
            role=role,
            language=language,
        )

        text = (text or "").strip()
        payload = payload or {}

        # Record user message if provided
        if text:
            session.add_message(sender=Sender.USER, text=text)

        # 1. Check for Reset / Main Menu actions
        if action_type in ("reset", "main_menu", "menu_back") or text.lower() in ("menu", "main menu", "home", "reset", "restart", "मेनू", "मुख्य मेनू", "शुरू करें"):
            session.reset_state()
            quick_replies = self.get_main_menu_quick_replies(session.role, session.language)
            msg_text = get_text("welcome_worker" if session.role == Role.WORKER else "welcome_customer", session.language)
            return session.add_message(
                sender=Sender.BOT,
                text=msg_text,
                quick_replies=quick_replies,
                metadata={"view": "main_menu"},
            )

        # 2. Check for human agent contact
        if action_type == "contact_human" or text.lower() in ("agent", "human", "call support", "help desk", "कॉल", "एजेंट"):
            info = get_text("human_agent_info", session.language)
            quick_replies = [
                QuickReply(id="main_menu", label=get_text("menu_back", session.language), action_type="main_menu")
            ]
            return session.add_message(
                sender=Sender.BOT,
                text=info,
                quick_replies=quick_replies,
                metadata={"view": "human_agent"},
            )

        # 3. Check for feedback thumbs up/down
        if action_type == "feedback":
            thanks = get_text("thanks_feedback", session.language)
            quick_replies = [
                QuickReply(id="main_menu", label=get_text("menu_back", session.language), action_type="main_menu")
            ]
            return session.add_message(
                sender=Sender.BOT,
                text=thanks,
                quick_replies=quick_replies,
                metadata={"view": "feedback_ack"},
            )

        # 4. Handle State Machine Flows (e.g. Raising Ticket or Checking Booking ID)
        if session.current_state != "IDLE":
            return self._handle_active_state(session, text, action_type, payload)

        # 5. Handle Action Types directly from Quick Reply clicks
        faq_id = payload.get("faq_id") or (text if action_type == "faq" else None)
        if faq_id:
            return self._handle_faq_request(session, faq_id)

        # 6. Check for Special Keywords / Booking ID format (e.g. BK1001 or 1001)
        if re.match(r"^(BK)?\d{4,6}$", text.upper()):
            return self._handle_booking_lookup(session, text.upper())

        # 7. Intent and Keyword Matching on user input
        faqs = self.get_faqs_for_role(session.role)
        match_result = self.matcher.match_faq(text, faqs, session.language)

        if match_result:
            matched_faq, score = match_result
            return self._format_faq_message(session, matched_faq)

        # 8. Graceful Fallback with Main Menu Suggestions
        fallback_text = get_text("fallback_message", session.language)
        quick_replies = self.get_main_menu_quick_replies(session.role, session.language)
        return session.add_message(
            sender=Sender.BOT,
            text=fallback_text,
            quick_replies=quick_replies,
            metadata={"view": "fallback", "unmatched_query": text},
        )

    def _handle_active_state(
        self,
        session: ChatSession,
        text: str,
        action_type: Optional[str],
        payload: Dict[str, Any],
    ) -> ChatMessage:
        state = session.current_state

        # State: RAISING_TICKET_CATEGORY
        if state == "RAISING_TICKET_CAT":
            selected_cat = payload.get("category") or text
            session.state_data["category"] = selected_cat
            session.set_state("RAISING_TICKET_DESC")
            prompt_text = get_text("ticket_enter_description", session.language)
            cancel_btn = QuickReply(id="menu_back", label=get_text("menu_back", session.language), action_type="main_menu")
            return session.add_message(
                sender=Sender.BOT,
                text=prompt_text,
                quick_replies=[cancel_btn],
                metadata={"view": "ticket_desc_prompt", "category": selected_cat},
            )

        # State: RAISING_TICKET_DESCRIPTION
        if state == "RAISING_TICKET_DESC":
            desc = text.strip()
            if len(desc) < 3:
                warn_text = get_text("ticket_invalid_desc", session.language)
                return session.add_message(
                    sender=Sender.BOT,
                    text=warn_text,
                    metadata={"view": "ticket_desc_invalid"},
                )

            category = session.state_data.get("category", "General Inquiry")
            ticket = self.ticket_manager.create_ticket(
                user_id=session.user_id,
                role=session.role,
                category=category,
                description=desc,
                sla_hours=24,
            )
            session.reset_state()

            success_msg = get_text(
                "ticket_created_success",
                session.language,
                ticket_id=ticket.ticket_id,
                category=ticket.category,
                sla_hours=ticket.sla_hours,
                description=ticket.description,
            )
            quick_replies = [
                QuickReply(id="main_menu", label=get_text("menu_back", session.language), action_type="main_menu")
            ]
            return session.add_message(
                sender=Sender.BOT,
                text=success_msg,
                quick_replies=quick_replies,
                metadata={"view": "ticket_success", "ticket": ticket.to_dict()},
            )

        # State: CHECKING_BOOKING_ID
        if state == "CHECKING_BOOKING_ID":
            return self._handle_booking_lookup(session, text)

        # Fallback reset
        session.reset_state()
        quick_replies = self.get_main_menu_quick_replies(session.role, session.language)
        return session.add_message(
            sender=Sender.BOT,
            text=get_text("welcome_customer", session.language),
            quick_replies=quick_replies,
        )

    def _handle_faq_request(self, session: ChatSession, faq_id: str) -> ChatMessage:
        faq = (
            get_worker_faq_by_id(faq_id)
            if session.role == Role.WORKER
            else get_customer_faq_by_id(faq_id)
        )
        if not faq:
            faq = get_customer_faq_by_id(faq_id) or get_worker_faq_by_id(faq_id)

        if faq:
            return self._format_faq_message(session, faq)

        if faq_id.startswith("ticket_cat_") or faq_id.startswith("ticket_worker_"):
            return self._trigger_ticket_creation(session, faq_id)

        quick_replies = self.get_main_menu_quick_replies(session.role, session.language)
        return session.add_message(
            sender=Sender.BOT,
            text=get_text("fallback_message", session.language),
            quick_replies=quick_replies,
        )

    def _format_faq_message(self, session: ChatSession, faq: FAQItem) -> ChatMessage:
        lang = session.language
        answer = faq.get_answer(lang)
        sub_opts = faq.get_sub_options(lang)

        quick_replies: List[QuickReply] = []

        for sub in sub_opts:
            quick_replies.append(
                QuickReply(
                    id=sub["id"],
                    label=sub["label"],
                    action_type="faq",
                    payload={"faq_id": sub["id"]},
                )
            )

        if faq.action_type == "offers":
            offers_text = format_offers_message(lang)
            answer = f"{answer}\n\n{offers_text}"

        elif faq.action_type == "status":
            session.set_state("CHECKING_BOOKING_ID")
            sample_ids = ["BK1001", "BK1002", "BK1003", "BK1004"]
            for sid in sample_ids:
                b = self.booking_manager.get_booking(sid)
                if b:
                    sname = b.service_name_hi if lang == Language.HINDI else b.service_name_en
                    quick_replies.append(
                        QuickReply(
                            id=f"check_{sid}",
                            label=f"🔍 #{sid} ({sname[:16]}...)",
                            action_type="booking_lookup",
                            payload={"booking_id": sid},
                        )
                    )

        elif faq.action_type == "ticket":
            session.set_state("RAISING_TICKET_CAT")

        quick_replies.append(
            QuickReply(
                id="main_menu",
                label=get_text("menu_back", lang),
                action_type="main_menu",
            )
        )

        return session.add_message(
            sender=Sender.BOT,
            text=answer,
            quick_replies=quick_replies,
            metadata={"faq_id": faq.id, "category": faq.category, "view": "faq_answer"},
        )

    def _trigger_ticket_creation(self, session: ChatSession, cat_id: str) -> ChatMessage:
        category_map = {
            "ticket_cat_noshow": "Worker Delayed / No-Show",
            "ticket_cat_quality": "Poor Quality of Service",
            "ticket_cat_billing": "Billing / Overcharging Issue",
            "ticket_cat_app": "App / Payment Technical Issue",
            "ticket_cat_other": "Other Customer Concern",
            "ticket_worker_payment": "Payment / Payout Issue",
            "ticket_worker_customer_dispute": "Customer No-Show / Dispute",
            "ticket_worker_safety": "Safety / Misconduct Concern",
            "ticket_worker_app_tech": "App GPS / Tech Glitch",
            "ticket_worker_other": "Other Partner Concern",
        }
        category_name = category_map.get(cat_id, "Support Issue")
        session.set_state("RAISING_TICKET_DESC", {"category": category_name})

        prompt_text = get_text("ticket_enter_description", session.language)
        cancel_btn = QuickReply(id="main_menu", label=get_text("menu_back", session.language), action_type="main_menu")
        return session.add_message(
            sender=Sender.BOT,
            text=f"📌 **Category**: {category_name}\n\n{prompt_text}",
            quick_replies=[cancel_btn],
            metadata={"view": "ticket_desc_prompt", "category": category_name},
        )

    def _handle_booking_lookup(self, session: ChatSession, booking_id_input: str) -> ChatMessage:
        booking = self.booking_manager.get_booking(booking_id_input)
        session.reset_state()

        if not booking:
            not_found_text = get_text("booking_not_found", session.language, booking_id=booking_id_input)
            quick_replies = [
                QuickReply(id="main_menu", label=get_text("menu_back", session.language), action_type="main_menu")
            ]
            return session.add_message(
                sender=Sender.BOT,
                text=not_found_text,
                quick_replies=quick_replies,
                metadata={"view": "booking_not_found"},
            )

        resp_text = self.booking_manager.format_booking_response(booking, session.language)
        quick_replies = [
            QuickReply(id="main_menu", label=get_text("menu_back", session.language), action_type="main_menu")
        ]
        return session.add_message(
            sender=Sender.BOT,
            text=resp_text,
            quick_replies=quick_replies,
            metadata={"view": "booking_result", "booking": booking.to_dict(session.language)},
        )
