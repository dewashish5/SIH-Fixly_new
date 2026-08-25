# Gig Support Chatbot (Multi-Language)

> **Independent, Reusable Support Chatbot Module** for Gig Worker Community Service Platforms.
> Provides instant, fixed-FAQ answers and interactive assistance for both **Customers** and **Gig Workers** in **Hindi (हिन्दी)** and **English**.

---

## Key Features

- **Dual-Persona Support**:
  - **Customer App**:
    1. *How to book a service* (Step-by-step, rescheduling, cancellations, accepted payment methods)
    2. *View current offers* (Dynamic coupons like FIRSTGIG, SUMMER50, REFER50)
    3. *Check order/booking status* (Interactive status lookup by Booking ID, live updates)
    4. *How to use app features* (Favorites, masked call/chat, safety SOS, ratings)
    5. *Raise a complaint/ticket* (Categorized grievance submission with unique Ticket ID & 24h SLA)
  - **Gig Worker App**:
    1. *View assigned jobs* (Incoming leads, acceptance timer, GPS navigation, Start/End OTP)
    2. *How to use app features* (Online/Offline duty toggle, earnings dashboard, instant payouts)
    3. *Raise a complaint/ticket* (Payout disputes, customer no-shows, safety concerns)
    4. *How to set up profile* (Aadhaar/PAN KYC, skill badges, bank account & UPI setup)

- **True Multi-Language (i18n)**:
  - English & Native Hindi (हिन्दी with Devanagari script parity).
  - Instant on-the-fly language toggle without losing conversation state.
  - Expandable to other regional languages (Tamil, Telugu, Bengali, Marathi, etc.).

- **Fixed FAQ + Smart Fallback Matcher**:
  - Clickable quick-reply menu pills for 1-tap answers.
  - Bilingual keyword, phrase, and fuzzy token matcher.
  - Graceful fallback with helpful recommendations when queries are ambiguous.

- **Zero Hardcoded Dependencies & Modular Integration**:
  - Pluggable Python Backend (gig_support_chatbot SDK, REST API, WSGI/ASGI/FastAPI adapter).
  - Standalone embeddable Web Component (<gig-support-chatbot>) and Vanilla JavaScript widget.
  - Compatible with React, Vue, Angular, Flutter Web, React Native WebViews, and native mobile apps.

---

## Quickstart & Demo

### 1. Run the Standalone Demo Server
`powershell
py gig_support_chatbot/server/app.py --port 8080
`

Open your browser:
- **Interactive Playground**: http://127.0.0.1:8080/demo/index.html
- **Customer App View**: http://127.0.0.1:8080/demo/customer_app_demo.html
- **Worker App View**: http://127.0.0.1:8080/demo/worker_app_demo.html
- **API Health Check**: http://127.0.0.1:8080/api/health

---

## Web Embedding & Integration

### A. Embed via JavaScript SDK
`html
<link rel="stylesheet" href="path/to/gig-chatbot.css" />
<script src="path/to/gig-chatbot.js"></script>
<script>
  window.GigSupportChatbot.init({
    role: 'customer',      // 'customer' or 'worker'
    language: 'hi',        // 'hi' (Hindi) or 'en' (English)
    apiBaseUrl: 'http://localhost:8080' // Optional backend URL
  });
</script>
`

### B. Embed via Custom Web Component
`html
<gig-support-chatbot role="worker" lang="en" api-url="http://localhost:8080"></gig-support-chatbot>
`

---

## Python SDK Integration

`python
from gig_support_chatbot import ChatbotEngine, Role, Language

engine = ChatbotEngine()

# Start session for customer in English
resp = engine.start_session(session_id="cust_101", role=Role.CUSTOMER, language=Language.ENGLISH)
print(resp.text)

# Ask question in Hindi
resp = engine.process_message(
    session_id="cust_101",
    text="सेवा कैसे बुक करें",
    language=Language.HINDI
)
print(resp.text)
`

---

## Automated Test Suite

Run the full automated test suite with coverage:
`powershell
py -m pytest tests -v --cov=gig_support_chatbot --cov-report=term-missing
`
