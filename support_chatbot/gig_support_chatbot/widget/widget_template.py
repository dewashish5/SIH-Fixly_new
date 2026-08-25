"""
Helper utilities for bundling and embedding the widget into web applications.
"""

import os

WIDGET_DIR = os.path.dirname(__file__)


def get_widget_js() -> str:
    path = os.path.join(WIDGET_DIR, "gig-chatbot.js")
    with open(path, "r", encoding="utf-8") as f:
        return f.read()


def get_widget_css() -> str:
    path = os.path.join(WIDGET_DIR, "gig-chatbot.css")
    with open(path, "r", encoding="utf-8") as f:
        return f.read()


def generate_embed_html(role: str = "customer", language: str = "en", api_base_url: str = "") -> str:
    """Generate a self-contained HTML snippet to embed into any web page."""
    return f"""
<!-- Gig Support Chatbot Embed Snippet -->
<link rel="stylesheet" href="{api_base_url}/gig_support_chatbot/widget/gig-chatbot.css">
<script src="{api_base_url}/gig_support_chatbot/widget/gig-chatbot.js"></script>
<script>
  document.addEventListener('DOMContentLoaded', function() {{
    window.GigSupportChatbot.init({{
      role: '{role}',
      language: '{language}',
      apiBaseUrl: '{api_base_url}'
    }});
  }});
</script>
"""
