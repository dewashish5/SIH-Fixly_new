"""
Bilingual text, list, and status formatting helpers.
"""

from typing import Any, Dict, List
from ..core.types import Language


def format_bullet_list(items: List[str]) -> str:
    return "\n".join(f"• {item}" for item in items if item.strip())


def format_numbered_list(items: List[str]) -> str:
    return "\n".join(f"{i+1}. {item}" for i, item in enumerate(items) if item.strip())


def format_status_badge(status_code: str, lang: Language = Language.ENGLISH) -> str:
    status_map = {
        "CONFIRMED": {"en": "✅ Confirmed", "hi": "✅ पुष्टि की गई"},
        "ON_THE_WAY": {"en": "🚗 On The Way", "hi": "🚗 रास्ते में है"},
        "IN_PROGRESS": {"en": "⏳ In Progress", "hi": "⏳ कार्य जारी है"},
        "COMPLETED": {"en": "🎉 Completed", "hi": "🎉 पूर्ण हुआ"},
        "CANCELLED": {"en": "❌ Cancelled", "hi": "❌ रद्द किया गया"},
        "OPEN": {"en": "📬 Open", "hi": "📬 खुली है"},
        "RESOLVED": {"en": "✅ Resolved", "hi": "✅ हल हो गया"},
    }
    entry = status_map.get(status_code.upper(), {"en": status_code, "hi": status_code})
    return entry.get(lang.value, status_code)
