/**
 * Gig Community Support Chatbot Widget
 * Independent, zero-dependency embeddable widget & Web Component
 */

(function (window, document) {
  'use strict';

  // Client-side Knowledge Base for zero-dependency standalone operation
  const CLIENT_I18N = {
    welcome_customer: {
      en: "👋 Hello! Welcome to GigCommunity Customer Support. How can I help you today?",
      hi: "👋 नमस्ते! गिग कम्युनिटी ग्राहक सहायता में आपका स्वागत है। आज मैं आपकी क्या मदद कर सकता हूँ?"
    },
    welcome_worker: {
      en: "👋 Hello Partner! Welcome to GigCommunity Worker Support Desk. How can I assist you?",
      hi: "👋 नमस्ते साथी! गिग कम्युनिटी वर्कर सहायता केंद्र में आपका स्वागत है। मैं आपकी कैसे मदद कर सकता हूँ?"
    },
    app_title: {
      en: "GigCommunity Support",
      hi: "गिग कम्युनिटी सहायता"
    },
    menu_back: {
      en: "🔙 Back to Main Menu",
      hi: "🔙 मुख्य मेनू पर वापस जाएं"
    },
    input_placeholder: {
      en: "Type a question or select an option...",
      hi: "अपना प्रश्न लिखें या विकल्प चुनें..."
    },
    ticket_created: {
      en: "✅ Ticket Created Successfully!\n• Ticket ID: {id}\n• Status: OPEN (Resolves in 24h)",
      hi: "✅ शिकायत टिकट दर्ज हो गया!\n• टिकट आईडी: {id}\n• स्थिति: खुली है (24 घंटे में समाधान)"
    }
  };

  const CUSTOMER_MENU = [
    { id: "cust_book_service", label_en: "📅 How to Book a Service", label_hi: "📅 सेवा कैसे बुक करें", icon: "📅" },
    { id: "cust_view_offers", label_en: "🏷️ View Current Offers", label_hi: "🏷️ वर्तमान ऑफ़र देखें", icon: "🏷️" },
    { id: "cust_booking_status", label_en: "🔍 Check Booking Status", label_hi: "🔍 बुकिंग स्थिति जांचें", icon: "🔍" },
    { id: "cust_app_features", label_en: "📱 How to Use App Features", label_hi: "📱 ऐप की सुविधाएं", icon: "📱" },
    { id: "cust_raise_ticket", label_en: "🎫 Raise a Complaint / Ticket", label_hi: "🎫 शिकायत दर्ज करें", icon: "🎫" }
  ];

  const WORKER_MENU = [
    { id: "work_assigned_jobs", label_en: "📋 View Assigned Jobs", label_hi: "📋 सौंपे गए काम देखें", icon: "📋" },
    { id: "work_app_features", label_en: "⚙️ How to Use App Features", label_hi: "⚙️ ऐप की सुविधाएं", icon: "⚙️" },
    { id: "work_raise_ticket", label_en: "🎫 Raise a Complaint / Ticket", label_hi: "🎫 शिकायत दर्ज करें", icon: "🎫" },
    { id: "work_profile_setup", label_en: "👤 How to Set Up Profile", label_hi: "👤 प्रोफ़ाइल कैसे बनाएं", icon: "👤" }
  ];

  class GigSupportChatbotWidget {
    constructor(config = {}) {
      this.role = (config.role || 'customer').toLowerCase();
      this.language = (config.language || 'en').toLowerCase();
      this.apiBaseUrl = config.apiBaseUrl || '';
      this.sessionId = config.sessionId || 'session_' + Math.random().toString(36).substring(2, 9);
      this.isOpen = false;
      this.history = [];
      this.state = 'IDLE';
      this.stateData = {};
      this.initDOM();
    }

    initDOM() {
      // Create Floating Button
      this.triggerBtn = document.createElement('button');
      this.triggerBtn.className = 'gig-chat-trigger' + (this.role === 'worker' ? ' worker-theme' : '');
      this.triggerBtn.setAttribute('aria-label', 'Open Support Chatbot');
      this.triggerBtn.innerHTML = 💬<span class=\"badge\">1</span>;
      this.triggerBtn.onclick = () => this.toggle();

      // Create Chat Container
      this.container = document.createElement('div');
      this.container.className = 'gig-chat-container hidden' + (this.role === 'worker' ? ' worker-theme' : '');
      this.container.setAttribute('role', 'dialog');
      this.container.setAttribute('aria-label', 'Support Chat Window');

      this.renderWidgetStructure();
      document.body.appendChild(this.triggerBtn);
      document.body.appendChild(this.container);

      // Start initial chat
      this.fetchInitialMessage();
    }

    renderWidgetStructure() {
      const isWorker = this.role === 'worker';
      const title = this.language === 'hi' ? CLIENT_I18N.app_title.hi : CLIENT_I18N.app_title.en;
      const roleLabel = isWorker ? (this.language === 'hi' ? 'वर्कर सपोर्ट' : 'Worker Desk') : (this.language === 'hi' ? 'ग्राहक सहायता' : 'Customer Help');

      this.container.innerHTML = 
        <div class=\"gig-chat-header \">
          <div class=\"gig-header-info\">
            <div class=\"gig-avatar\"></div>
            <div class=\"gig-title-area\">
              <h3> <span class=\"role-badge\"></span></h3>
              <p>24x7 Multi-Language Support</p>
            </div>
          </div>
          <div class=\"gig-header-actions\">
            <button class=\"gig-lang-btn\" title=\"Change Language\"></button>
            <button class=\"gig-close-btn\" title=\"Close Chat\" aria-label=\"Close Chat\">✕</button>
          </div>
        </div>
        <div class=\"gig-chat-messages\" id=\"gig-chat-msgs\"></div>
        <div class=\"gig-chat-footer\">
          <input type=\"text\" class=\"gig-chat-input\" placeholder=\"\" />
          <button class=\"gig-send-btn\" aria-label=\"Send Message\">➤</button>
        </div>
      ;

      this.messagesContainer = this.container.querySelector('#gig-chat-msgs');
      this.inputField = this.container.querySelector('.gig-chat-input');
      this.sendBtn = this.container.querySelector('.gig-send-btn');
      this.langBtn = this.container.querySelector('.gig-lang-btn');
      this.closeBtn = this.container.querySelector('.gig-close-btn');

      this.sendBtn.onclick = () => this.handleSendMessage();
      this.inputField.onkeypress = (e) => {
        if (e.key === 'Enter') this.handleSendMessage();
      };
      this.langBtn.onclick = () => this.toggleLanguage();
      this.closeBtn.onclick = () => this.toggle(false);
    }

    toggle(forceState) {
      this.isOpen = forceState !== undefined ? forceState : !this.isOpen;
      if (this.isOpen) {
        this.container.classList.remove('hidden');
        this.triggerBtn.style.display = 'none';
        this.inputField.focus();
        this.scrollToBottom();
      } else {
        this.container.classList.add('hidden');
        this.triggerBtn.style.display = 'flex';
      }
    }

    toggleLanguage() {
      this.language = this.language === 'hi' ? 'en' : 'hi';
      this.renderWidgetStructure();
      this.fetchInitialMessage();
    }

    setRole(newRole) {
      this.role = newRole.toLowerCase();
      this.triggerBtn.className = 'gig-chat-trigger' + (this.role === 'worker' ? ' worker-theme' : '');
      this.renderWidgetStructure();
      this.fetchInitialMessage();
    }

    async fetchInitialMessage() {
      if (this.apiBaseUrl) {
        try {
          const res = await fetch(${this.apiBaseUrl}/api/chat, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              session_id: this.sessionId,
              role: this.role,
              language: this.language,
              action: 'start'
            })
          });
          const data = await res.json();
          this.messagesContainer.innerHTML = '';
          this.appendMessage(data.message);
          return;
        } catch (e) {
          console.warn('API fetch failed, using client fallback', e);
        }
      }

      // Standalone client fallback
      this.messagesContainer.innerHTML = '';
      const isWorker = this.role === 'worker';
      const welcome = isWorker ? CLIENT_I18N.welcome_worker[this.language] : CLIENT_I18N.welcome_customer[this.language];
      const menu = isWorker ? WORKER_MENU : CUSTOMER_MENU;

      const quickReplies = menu.map(m => ({
        id: m.id,
        label: this.language === 'hi' ? m.label_hi : m.label_en,
        action_type: 'faq',
        payload: { faq_id: m.id }
      }));

      this.appendMessage({
        sender: 'bot',
        text: welcome,
        quick_replies: quickReplies,
        timestamp: Date.now() / 1000
      });
    }

    async sendMessage(text, actionType = null, payload = {}) {
      if (!text && !actionType) return;

      if (text) {
        this.appendMessage({
          sender: 'user',
          text: text,
          timestamp: Date.now() / 1000
        });
      }

      if (this.apiBaseUrl) {
        try {
          const res = await fetch(${this.apiBaseUrl}/api/chat, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              session_id: this.sessionId,
              message: text,
              action_type: actionType,
              payload: payload,
              role: this.role,
              language: this.language
            })
          });
          const data = await res.json();
          this.appendMessage(data.message);
          return;
        } catch (e) {
          console.warn('Chat API error:', e);
        }
      }

      // Fallback message
      this.appendMessage({
        sender: 'bot',
        text: this.language === 'hi' ? "मुख्य मेनू पर वापस जाने के लिए नीचे क्लिक करें।" : "Please use the options below or restart:",
        quick_replies: [{ id: "main_menu", label: CLIENT_I18N.menu_back[this.language], action_type: "reset" }]
      });
    }

    handleSendMessage() {
      const text = this.inputField.value.trim();
      if (!text) return;
      this.inputField.value = '';
      this.sendMessage(text);
    }

    appendMessage(msg) {
      if (!msg) return;
      const row = document.createElement('div');
      row.className = gig-msg-row ;

      const bubble = document.createElement('div');
      bubble.className = 'gig-msg-bubble';
      bubble.innerText = msg.text || '';
      row.appendChild(bubble);

      // Render Quick Replies
      if (msg.quick_replies && msg.quick_replies.length > 0) {
        const qrContainer = document.createElement('div');
        qrContainer.className = 'gig-quick-replies';
        msg.quick_replies.forEach(qr => {
          const pill = document.createElement('button');
          pill.className = 'gig-qr-pill';
          pill.innerHTML = qr.label || qr.id;
          pill.onclick = () => {
            if (qr.action_type === 'main_menu' || qr.id === 'main_menu') {
              this.fetchInitialMessage();
            } else {
              this.sendMessage(qr.label, qr.action_type || 'faq', qr.payload || { faq_id: qr.id });
            }
          };
          qrContainer.appendChild(pill);
        });
        row.appendChild(qrContainer);
      }

      this.messagesContainer.appendChild(row);
      this.scrollToBottom();
    }

    scrollToBottom() {
      setTimeout(() => {
        this.messagesContainer.scrollTop = this.messagesContainer.scrollHeight;
      }, 50);
    }
  }

  // Custom Web Component registration
  if (window.customElements && !window.customElements.get('gig-support-chatbot')) {
    class GigChatbotElement extends HTMLElement {
      connectedCallback() {
        const role = this.getAttribute('role') || 'customer';
        const lang = this.getAttribute('lang') || 'en';
        const apiUrl = this.getAttribute('api-url') || '';
        this.widget = new GigSupportChatbotWidget({
          role: role,
          language: lang,
          apiBaseUrl: apiUrl
        });
      }
    }
    window.customElements.define('gig-support-chatbot', GigChatbotElement);
  }

  // Global namespace export
  window.GigSupportChatbot = {
    init: function (config) {
      return new GigSupportChatbotWidget(config);
    }
  };

})(window, document);
