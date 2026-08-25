"""
Offers and promotions data store and resolver.
"""

from typing import Any, Dict, List
from ..core.types import Language


OFFERS_DATA = [
    {
        "code": "FIRSTGIG",
        "title_en": "Flat ₹100 OFF on First Booking",
        "title_hi": "पहली बुकिंग पर फ्लैट ₹100 की छूट",
        "desc_en": "Valid on all home services above ₹299. Use at checkout.",
        "desc_hi": "₹299 से अधिक की सभी सेवाओं पर मान्य। चेकआउट पर लगाएं।",
        "discount": "₹100 OFF",
        "min_order": "₹299",
        "expires_in": "Valid for new users",
    },
    {
        "code": "SUMMER50",
        "title_en": "15% OFF Appliance & AC Service",
        "title_hi": "एसी और घरेलू उपकरण सेवा पर 15% छूट",
        "desc_en": "Save up to ₹150 on repair and deep cleaning services.",
        "desc_hi": "मरम्मत और गहरी सफाई पर ₹150 तक की बचत।",
        "discount": "15% (Up to ₹150)",
        "min_order": "₹499",
        "expires_in": "Ends Sunday",
    },
    {
        "code": "REFER50",
        "title_en": "Refer a Friend & Earn ₹50",
        "title_hi": "मित्र को रेफर करें और ₹50 कमाएं",
        "desc_en": "Share your link. You and your friend both receive ₹50 wallet credits.",
        "desc_hi": "अपना लिंक साझा करें। दोनों को ₹50 वॉलेट बोनस मिलेगा।",
        "discount": "₹50 Wallet Cash",
        "min_order": "None",
        "expires_in": "No expiry",
    },
    {
        "code": "COMBO20",
        "title_en": "20% OFF Multi-Service Combo",
        "title_hi": "मल्टी-सर्विस कॉम्बो पर 20% छूट",
        "desc_en": "Book 2 or more services together and get flat 20% discount.",
        "desc_hi": "2 या अधिक सेवाएं एक साथ बुक करें और 20% छूट पाएं।",
        "discount": "20% OFF",
        "min_order": "₹699",
        "expires_in": "Active",
    },
]


def get_active_offers(lang: Language = Language.ENGLISH) -> List[Dict[str, Any]]:
    is_hi = lang == Language.HINDI
    result = []
    for item in OFFERS_DATA:
        result.append({
            "code": item["code"],
            "title": item["title_hi"] if is_hi else item["title_en"],
            "description": item["desc_hi"] if is_hi else item["desc_en"],
            "discount": item["discount"],
            "min_order": item["min_order"],
            "expires_in": item["expires_in"],
        })
    return result


def format_offers_message(lang: Language = Language.ENGLISH) -> str:
    is_hi = lang == Language.HINDI
    header = "🎉 **सक्रिय ऑफ़र और प्रोमो कोड:**\n" if is_hi else "🎉 **Current Active Offers & Promo Codes:**\n"
    lines = [header]
    for o in OFFERS_DATA:
        title = o["title_hi"] if is_hi else o["title_en"]
        desc = o["desc_hi"] if is_hi else o["desc_en"]
        code = o["code"]
        lines.append(f"• 🏷️ **{code}** - {title}\n  _{desc}_")
    
    footer = "\n\n💡 *चेकआउट स्क्रीन पर प्रोमो कोड दर्ज करें।* " if is_hi else "\n\n💡 *Apply promo code at checkout before payment.*"
    return "\n".join(lines) + footer
