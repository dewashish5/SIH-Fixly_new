"""
Bilingual translation dictionaries and string resources (English & Hindi).
"""

from typing import Any, Dict
from ..core.types import Language, Role

TRANSLATIONS: Dict[str, Dict[str, str]] = {
    # General UI & Common Strings
    "app_title": {
        "en": "GigCommunity Support Assistant",
        "hi": "गिग कम्युनिटी सहायता सहायक",
    },
    "app_subtitle": {
        "en": "Instant answers for Customers & Gig Workers",
        "hi": "ग्राहकों और गिग कार्यकर्ताओं के लिए त्वरित सहायता",
    },
    "welcome_customer": {
        "en": "👋 Hello! Welcome to GigCommunity Customer Support. How can I help you today?",
        "hi": "👋 नमस्ते! गिग कम्युनिटी ग्राहक सहायता में आपका स्वागत है। आज मैं आपकी क्या मदद कर सकता हूँ?",
    },
    "welcome_worker": {
        "en": "👋 Hello Partner! Welcome to GigCommunity Worker Support Desk. How can I assist you?",
        "hi": "👋 नमस्ते साथी! गिग कम्युनिटी वर्कर सहायता केंद्र में आपका स्वागत है। मैं आपकी कैसे मदद कर सकता हूँ?",
    },
    "role_customer_label": {
        "en": "Customer Support",
        "hi": "ग्राहक सहायता",
    },
    "role_worker_label": {
        "en": "Worker Support",
        "hi": "कार्यकर्ता सहायता",
    },
    "lang_en": {
        "en": "English",
        "hi": "English",
    },
    "lang_hi": {
        "en": "हिन्दी (Hindi)",
        "hi": "हिन्दी (Hindi)",
    },
    "menu_back": {
        "en": "🔙 Back to Main Menu",
        "hi": "🔙 मुख्य मेनू पर वापस जाएं",
    },
    "menu_reset": {
        "en": "🔄 Restart Chat",
        "hi": "🔄 नई बातचीत शुरू करें",
    },
    "menu_contact_human": {
        "en": "📞 Speak with an Agent",
        "hi": "📞 कस्टमर केयर एजेंट से बात करें",
    },
    "human_agent_info": {
        "en": "Our support helpline is available 24x7 at 1800-GIG-HELP (1800-444-4357) or email support@gigcommunity.app.",
        "hi": "हमारी हेल्पलाइन 24x7 उपलब्ध है: 1800-GIG-HELP (1800-444-4357) या support@gigcommunity.app पर ईमेल करें।",
    },
    "input_placeholder": {
        "en": "Type a question or select an option below...",
        "hi": "अपना प्रश्न लिखें या नीचे दिए गए विकल्पों में से चुनें...",
    },
    "fallback_message": {
        "en": "I'm a FAQ support assistant for common questions. I couldn't find a direct match for that. Please choose from the topics below or rephrase:",
        "hi": "मैं सामान्य प्रश्नों के लिए सहायता बॉट हूँ। मुझे इसके लिए सीधा उत्तर नहीं मिला। कृपया नीचे दिए गए विकल्पों में से चुनें:",
    },
    "helpful_prompt": {
        "en": "Was this helpful?",
        "hi": "क्या इससे आपकी मदद हुई?",
    },
    "thanks_feedback": {
        "en": "Thank you for your feedback! Glad we could help. 😊",
        "hi": "आपकी प्रतिक्रिया के लिए धन्यवाद! आपकी सहायता करके खुशी हुई। 😊",
    },

    # Customer Main Menu Options
    "cust_menu_book_service": {
        "en": "📅 How to Book a Service",
        "hi": "📅 सेवा कैसे बुक करें",
    },
    "cust_menu_view_offers": {
        "en": "🏷️ View Current Offers & Discounts",
        "hi": "🏷️ वर्तमान ऑफ़र और छूट देखें",
    },
    "cust_menu_booking_status": {
        "en": "🔍 Check Order / Booking Status",
        "hi": "🔍 बुकिंग या ऑर्डर स्थिति जांचें",
    },
    "cust_menu_app_features": {
        "en": "📱 How to Use App Features",
        "hi": "📱 ऐप की सुविधाएं कैसे इस्तेमाल करें",
    },
    "cust_menu_raise_ticket": {
        "en": "🎫 Raise a Complaint / Support Ticket",
        "hi": "🎫 शिकायत या सपोर्ट टिकट दर्ज करें",
    },

    # Worker Main Menu Options
    "work_menu_assigned_jobs": {
        "en": "📋 View Assigned Jobs & Tasks",
        "hi": "📋 सौंपे गए काम और कार्य देखें",
    },
    "work_menu_app_features": {
        "en": "⚙️ How to Use App Features",
        "hi": "⚙️ ऐप की सुविधाएं और टूल्स",
    },
    "work_menu_raise_ticket": {
        "en": "🎫 Raise a Complaint / Ticket",
        "hi": "🎫 शिकायत या टिकट दर्ज करें",
    },
    "work_menu_profile_setup": {
        "en": "👤 How to Set Up Profile & KYC",
        "hi": "👤 प्रोफ़ाइल और KYC कैसे सेट करें",
    },

    # Ticket Flow Strings
    "ticket_select_category": {
        "en": "Please select the category for your complaint / ticket:",
        "hi": "कृपया अपनी शिकायत/टिकट के लिए श्रेणी चुनें:",
    },
    "ticket_enter_description": {
        "en": "Please type a brief description of the problem you are experiencing:",
        "hi": "कृपया अपनी समस्या का संक्षिप्त विवरण लिखें:",
    },
    "ticket_created_success": {
        "en": "✅ Ticket Created Successfully!\n• Ticket ID: {ticket_id}\n• Category: {category}\n• Status: OPEN\n• SLA: Our team will review this within {sla_hours} hours.\n• Description: {description}",
        "hi": "✅ शिकायत टिकट सफलतापूर्वक दर्ज कर लिया गया है!\n• टिकट आईडी: {ticket_id}\n• श्रेणी: {category}\n• स्थिति: खुली है (OPEN)\n• समाधान समय: हमारी टीम {sla_hours} घंटे के भीतर समाधान करेगी।\n• विवरण: {description}",
    },
    "ticket_invalid_desc": {
        "en": "Please provide at least a short description (minimum 5 characters) of the issue.",
        "hi": "कृपया समस्या का कम से कम 5 अक्षरों में संक्षिप्त विवरण दें।",
    },

    # Booking Status Flow Strings
    "booking_prompt_id": {
        "en": "Please enter your 6-digit Booking ID (e.g. BK1001 or BK1002) or select a recent booking:",
        "hi": "कृपया अपनी 6-अंकों की बुकिंग आईडी (उदा. BK1001 या BK1002) दर्ज करें या हाल की बुकिंग चुनें:",
    },
    "booking_not_found": {
        "en": "❌ No booking found with ID '{booking_id}'. Please verify the ID or check the 'My Bookings' tab in the app.",
        "hi": "❌ आईडी '{booking_id}' के साथ कोई बुकिंग नहीं मिली। कृपया आईडी की जांच करें या ऐप में 'मेरी बुकिंग' टैब देखें।",
    },
    "booking_details_template": {
        "en": "📦 Booking Status for #{booking_id}:\n• Service: {service_name}\n• Status: {status}\n• Assigned Worker: {worker_name} ({worker_phone})\n• Scheduled Time: {scheduled_time}\n• Location: {address}\n• Amount: {amount}",
        "hi": "📦 बुकिंग स्थिति (#{booking_id}):\n• सेवा: {service_name}\n• स्थिति: {status}\n• नियुक्त कार्यकर्ता: {worker_name} ({worker_phone})\n• निर्धारित समय: {scheduled_time}\n• पता: {address}\n• राशि: {amount}",
    },

    # Offers Strings
    "offers_header": {
        "en": "🎉 Current Active Offers & Promo Codes for You:",
        "hi": "🎉 आपके लिए वर्तमान सक्रिय ऑफ़र और प्रोमो कोड:",
    },
}


def get_text(key: str, lang: Language = Language.ENGLISH, **kwargs: Any) -> str:
    """Retrieve localized string with optional formatting parameters."""
    lang_key = lang.value if isinstance(lang, Language) else str(lang)
    entry = TRANSLATIONS.get(key)
    if not entry:
        return key
    text = entry.get(lang_key) or entry.get("en") or key
    if kwargs:
        try:
            return text.format(**kwargs)
        except Exception:
            return text
    return text
