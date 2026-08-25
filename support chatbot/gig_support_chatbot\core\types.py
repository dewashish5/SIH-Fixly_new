"""
Core data types, enums, and data classes for Gig Support Chatbot.
"""

from dataclasses import dataclass, field
from enum import Enum
from typing import Any, Dict, List, Optional
import time
import uuid


class Role(str, Enum):
    CUSTOMER = "customer"
    WORKER = "worker"

    @classmethod
    def from_str(cls, val: str) -> "Role":
        val = (val or "").strip().lower()
        if val in ("worker", "provider", "partner", "gig_worker", "technician"):
            return cls.WORKER
        return cls.CUSTOMER


class Language(str, Enum):
    ENGLISH = "en"
    HINDI = "hi"

    @classmethod
    def from_str(cls, val: str) -> "Language":
        val = (val or "").strip().lower()
        if val in ("hi", "hindi", "hin", "हिंदी", "हिन्दी"):
            return cls.HINDI
        return cls.ENGLISH


class Sender(str, Enum):
    USER = "user"
    BOT = "bot"
    SYSTEM = "system"


@dataclass
class QuickReply:
    id: str
    label: str
    action_type: str = "faq"  # 'faq', 'submenu', 'ticket', 'status', 'offers', 'link', 'reset'
    payload: Optional[Dict[str, Any]] = None
    icon: Optional[str] = None

    def to_dict(self) -> Dict[str, Any]:
        data: Dict[str, Any] = {
            "id": self.id,
            "label": self.label,
            "action_type": self.action_type,
        }
        if self.payload:
            data["payload"] = self.payload
        if self.icon:
            data["icon"] = self.icon
        return data


@dataclass
class ChatMessage:
    id: str = field(default_factory=lambda: str(uuid.uuid4())[:8])
    sender: Sender = Sender.BOT
    text: str = ""
    quick_replies: List[QuickReply] = field(default_factory=list)
    timestamp: float = field(default_factory=time.time)
    metadata: Dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "sender": self.sender.value if isinstance(self.sender, Sender) else str(self.sender),
            "text": self.text,
            "quick_replies": [qr.to_dict() if isinstance(qr, QuickReply) else qr for qr in self.quick_replies],
            "timestamp": self.timestamp,
            "metadata": self.metadata,
        }


@dataclass
class FAQItem:
    id: str
    role: Role
    category: str
    keywords_en: List[str]
    keywords_hi: List[str]
    title_en: str
    title_hi: str
    answer_en: str
    answer_hi: str
    sub_options_en: List[Dict[str, str]] = field(default_factory=list)
    sub_options_hi: List[Dict[str, str]] = field(default_factory=list)
    action_type: Optional[str] = None
    related_faq_ids: List[str] = field(default_factory=list)

    def get_title(self, lang: Language) -> str:
        return self.title_hi if lang == Language.HINDI else self.title_en

    def get_answer(self, lang: Language) -> str:
        return self.answer_hi if lang == Language.HINDI else self.answer_en

    def get_sub_options(self, lang: Language) -> List[Dict[str, str]]:
        return self.sub_options_hi if lang == Language.HINDI else self.sub_options_en

    def get_keywords(self, lang: Language) -> List[str]:
        return self.keywords_hi if lang == Language.HINDI else self.keywords_en


@dataclass
class SupportTicket:
    ticket_id: str
    user_id: str
    role: Role
    category: str
    description: str
    status: str = "OPEN"  # OPEN, IN_PROGRESS, RESOLVED
    created_at: float = field(default_factory=time.time)
    contact: Optional[str] = None
    order_id: Optional[str] = None
    sla_hours: int = 24

    def to_dict(self) -> Dict[str, Any]:
        return {
            "ticket_id": self.ticket_id,
            "user_id": self.user_id,
            "role": self.role.value,
            "category": self.category,
            "description": self.description,
            "status": self.status,
            "created_at": self.created_at,
            "contact": self.contact,
            "order_id": self.order_id,
            "sla_hours": self.sla_hours,
        }


@dataclass
class BookingInfo:
    booking_id: str
    service_name_en: str
    service_name_hi: str
    worker_name: str
    worker_phone: str
    status_en: str
    status_hi: str
    status_code: str  # CONFIRMED, ON_THE_WAY, IN_PROGRESS, COMPLETED, CANCELLED
    scheduled_time: str
    address: str
    amount: str

    def to_dict(self, lang: Language = Language.ENGLISH) -> Dict[str, Any]:
        is_hi = lang == Language.HINDI
        return {
            "booking_id": self.booking_id,
            "service_name": self.service_name_hi if is_hi else self.service_name_en,
            "worker_name": self.worker_name,
            "worker_phone": self.worker_phone,
            "status": self.status_hi if is_hi else self.status_en,
            "status_code": self.status_code,
            "scheduled_time": self.scheduled_time,
            "address": self.address,
            "amount": self.amount,
        }
