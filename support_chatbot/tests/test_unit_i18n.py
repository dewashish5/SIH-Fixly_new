import pytest
from gig_support_chatbot.core.types import Language
from gig_support_chatbot.i18n.translations import TRANSLATIONS, get_text
from gig_support_chatbot.i18n.formatter import format_bullet_list, format_numbered_list, format_status_badge


class TestI18n:
    def test_translations_dictionary_parity(self):
        """Verify every key exists in both English and Hindi with non-empty content."""
        for key, lang_map in TRANSLATIONS.items():
            assert "en" in lang_map, f"Missing English translation for key: {key}"
            assert "hi" in lang_map, f"Missing Hindi translation for key: {key}"
            assert len(lang_map["en"].strip()) > 0, f"Empty English text for key: {key}"
            assert len(lang_map["hi"].strip()) > 0, f"Empty Hindi text for key: {key}"

    def test_hindi_unicode_presence(self):
        """Ensure Hindi translations contain actual Devanagari Unicode characters."""
        devanagari_count = 0
        for key, lang_map in TRANSLATIONS.items():
            hi_text = lang_map.get("hi", "")
            # Check for at least one character in Devanagari range U+0900 to U+097F or English fallback
            for char in hi_text:
                if 0x0900 <= ord(char) <= 0x097F:
                    devanagari_count += 1
                    break
        assert devanagari_count > 10, "Expected rich Devanagari script across Hindi translations."

    def test_get_text_formatting(self):
        res_en = get_text("ticket_created_success", Language.ENGLISH, ticket_id="TCK-999", category="Billing", sla_hours=24, description="Overcharged")
        assert "TCK-999" in res_en
        assert "Billing" in res_en
        assert "24" in res_en

        res_hi = get_text("ticket_created_success", Language.HINDI, ticket_id="TCK-999", category="बिलिंग", sla_hours=24, description="अधिक शुल्क")
        assert "TCK-999" in res_hi
        assert "बिलिंग" in res_hi

    def test_formatters(self):
        bullets = format_bullet_list(["Item 1", "Item 2"])
        assert bullets == "• Item 1\n• Item 2"

        numbered = format_numbered_list(["Step 1", "Step 2"])
        assert numbered == "1. Step 1\n2. Step 2"

        badge_en = format_status_badge("CONFIRMED", Language.ENGLISH)
        assert "Confirmed" in badge_en
        badge_hi = format_status_badge("CONFIRMED", Language.HINDI)
        assert "पुष्टि" in badge_hi
