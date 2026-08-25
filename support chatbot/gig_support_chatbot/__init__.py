"""
Gig Support Chatbot - Multi-Language FAQ & Assistance Engine for Gig Platforms.
"""

from .core.types import (
    Role,
    Language,
    ChatMessage,
    QuickReply,
    FAQItem,
    SupportTicket,
    BookingInfo,
    Sender,
)
from .core.engine import ChatbotEngine
from .core.session import ChatSession, SessionManager
from .core.matcher import IntentMatcher
from .data.bookings import BookingManager
from .data.tickets import TicketManager
from .server.api_routes import APIRouter
from .server.app import create_server, run_server

__version__ = "1.0.0"
__all__ = [
    "Role",
    "Language",
    "ChatMessage",
    "QuickReply",
    "FAQItem",
    "SupportTicket",
    "BookingInfo",
    "Sender",
    "ChatbotEngine",
    "ChatSession",
    "SessionManager",
    "IntentMatcher",
    "BookingManager",
    "TicketManager",
    "APIRouter",
    "create_server",
    "run_server",
]
