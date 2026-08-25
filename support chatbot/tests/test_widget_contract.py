import os
import pytest
from gig_support_chatbot.widget.widget_template import get_widget_js, get_widget_css, generate_embed_html


class TestWidgetContract:
    def test_widget_js_assets_exist(self):
        js_content = get_widget_js()
        assert "window.GigSupportChatbot" in js_content
        assert "GigSupportChatbotWidget" in js_content
        assert "customElements.define('gig-support-chatbot'" in js_content
        assert "welcome_customer" in js_content
        assert "welcome_worker" in js_content

    def test_widget_css_assets_exist(self):
        css_content = get_widget_css()
        assert ".gig-chat-trigger" in css_content
        assert ".gig-chat-container" in css_content
        assert ".worker-theme" in css_content
        assert "@media (max-width: 480px)" in css_content

    def test_embed_html_generation(self):
        html = generate_embed_html(role="worker", language="hi", api_base_url="https://api.example.com")
        assert "gig-chatbot.css" in html
        assert "gig-chatbot.js" in html
        assert "role: 'worker'" in html
        assert "language: 'hi'" in html
        assert "https://api.example.com" in html
