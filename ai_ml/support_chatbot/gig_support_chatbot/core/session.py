"""
Session management and state tracking for Gig Support Chatbot.
"""

from typing import Any, Dict, List, Optional
import time
import uuid
import threading
from .types import ChatMessage, Language, Role, Sender, QuickReply


class ChatSession:
    def __init__(
        self,
        session_id: Optional[str] = None,
        user_id: Optional[str] = None,
        role: Role = Role.CUSTOMER,
        language: Language = Language.ENGLISH,
    ):
        self.session_id: str = session_id or str(uuid.uuid4())
        self.user_id: str = user_id or f"user_{self.session_id[:6]}"
        self.role: Role = role
        self.language: Language = language
        self.history: List[ChatMessage] = []
        self.current_state: str = "IDLE"
        self.state_data: Dict[str, Any] = {}
        self.created_at: float = time.time()
        self.updated_at: float = time.time()

    def add_message(
        self,
        sender: Sender,
        text: str,
        quick_replies: Optional[List[QuickReply]] = None,
        metadata: Optional[Dict[str, Any]] = None,
    ) -> ChatMessage:
        msg = ChatMessage(
            sender=sender,
            text=text,
            quick_replies=quick_replies or [],
            metadata=metadata or {},
        )
        self.history.append(msg)
        self.updated_at = time.time()
        return msg

    def set_language(self, language: Language) -> None:
        self.language = language
        self.updated_at = time.time()

    def set_role(self, role: Role) -> None:
        self.role = role
        self.reset_state()
        self.updated_at = time.time()

    def set_state(self, state: str, data: Optional[Dict[str, Any]] = None) -> None:
        self.current_state = state
        if data is not None:
            self.state_data.update(data)
        self.updated_at = time.time()

    def reset_state(self) -> None:
        self.current_state = "IDLE"
        self.state_data = {}
        self.updated_at = time.time()

    def clear_history(self) -> None:
        self.history.clear()
        self.reset_state()
        self.updated_at = time.time()

    def get_recent_history(self, limit: int = 20) -> List[ChatMessage]:
        return self.history[-limit:]

    def to_dict(self) -> Dict[str, Any]:
        return {
            "session_id": self.session_id,
            "user_id": self.user_id,
            "role": self.role.value,
            "language": self.language.value,
            "current_state": self.current_state,
            "state_data": self.state_data,
            "history_count": len(self.history),
            "created_at": self.created_at,
            "updated_at": self.updated_at,
        }


class SessionManager:
    def __init__(self, ttl_seconds: int = 86400):
        self._sessions: Dict[str, ChatSession] = {}
        self._lock = threading.RLock()
        self.ttl_seconds = ttl_seconds

    def get_or_create(
        self,
        session_id: Optional[str] = None,
        user_id: Optional[str] = None,
        role: Optional[Role] = None,
        language: Optional[Language] = None,
    ) -> ChatSession:
        with self._lock:
            self._cleanup_expired()
            if session_id and session_id in self._sessions:
                session = self._sessions[session_id]
                if role is not None and session.role != role:
                    session.set_role(role)
                if language is not None and session.language != language:
                    session.set_language(language)
                return session

            new_session = ChatSession(
                session_id=session_id,
                user_id=user_id,
                role=role or Role.CUSTOMER,
                language=language or Language.ENGLISH,
            )
            self._sessions[new_session.session_id] = new_session
            return new_session

    def get(self, session_id: str) -> Optional[ChatSession]:
        with self._lock:
            return self._sessions.get(session_id)

    def delete(self, session_id: str) -> bool:
        with self._lock:
            if session_id in self._sessions:
                del self._sessions[session_id]
                return True
            return False

    def count(self) -> int:
        with self._lock:
            return len(self._sessions)

    def clear(self) -> None:
        with self._lock:
            self._sessions.clear()

    def _cleanup_expired(self) -> None:
        now = time.time()
        expired_keys = [
            sid for sid, s in self._sessions.items()
            if (now - s.updated_at) > self.ttl_seconds
        ]
        for sid in expired_keys:
            del self._sessions[sid]
