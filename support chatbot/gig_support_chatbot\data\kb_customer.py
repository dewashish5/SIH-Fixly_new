"""
Customer Knowledge Base and FAQ Trees (Bilingual: English & Hindi).
"""

from typing import Dict, List
from ..core.types import FAQItem, Language, Role

CUSTOMER_FAQS: List[FAQItem] = [
    # 1. How to Book a Service
    FAQItem(
        id="cust_book_service",
        role=Role.CUSTOMER,
        category="booking",
        keywords_en=[
            "how to book", "how do i book", "book a service", "hire worker",
            "book plumber", "book electrician", "book cleaner", "hire professional"
        ],
        keywords_hi=[
            "सेवा कैसे बुक करें", "सर्विस बुक करें", "काम बुक करें", "प्लंबर बुक", "इलेक्ट्रीशियन बुक", "बुक करना"
        ],
        title_en="How to Book a Service",
        title_hi="सेवा कैसे बुक करें",
        answer_en=(
            "📌 Step-by-Step Guide to Book a Service:\n\n"
            "1. **Choose Category**: On the Home screen, select the service needed (e.g., Plumbing, Electrician, Cleaning, Appliance Repair).\n"
            "2. **Select Worker or Instant Match**: Choose a verified community worker based on rating & rate, or tap 'Quick Match'.\n"
            "3. **Pick Schedule**: Select your preferred date and time slot.\n"
            "4. **Add Address**: Confirm your service location or add a new address.\n"
            "5. **Payment Method**: Choose Pay Online (UPI/Card) or Cash on Completion.\n"
            "6. **Confirm**: Review the summary and tap 'Confirm Booking'!"
        ),
        answer_hi=(
            "📌 सेवा बुक करने के आसान चरण:\n\n"
            "1. **श्रेणी चुनें**: होम स्क्रीन पर आवश्यक सेवा चुनें (जैसे प्लंबिंग, इलेक्ट्रीशियन, सफाई, उपकरण मरम्मत)।\n"
            "2. **कार्यकर्ता चुनें**: रेटिंग और शुल्क देखकर सत्यापित कार्यकर्ता चुनें, या 'क्विक मैच' दबाएं।\n"
            "3. **समय चुनें**: अपनी पसंदीदा तिथि और समय स्लॉट चुनें।\n"
            "4. **पता जोड़ें**: अपना सेवा पता चुनें या नया पता दर्ज करें।\n"
            "5. **भुगतान विकल्प**: ऑनलाइन भुगतान (UPI/कार्ड) या काम पूरा होने पर नकद चुनें।\n"
            "6. **पुष्टि करें**: विवरण जांचें और 'बुकिंग कन्फर्म करें' पर टैप करें!"
        ),
        sub_options_en=[
            {"id": "cust_reschedule", "label": "🗓️ How to Reschedule"},
            {"id": "cust_cancel_booking", "label": "❌ How to Cancel a Booking"},
            {"id": "cust_payment_methods", "label": "💳 Accepted Payment Methods"},
        ],
        sub_options_hi=[
            {"id": "cust_reschedule", "label": "🗓️ समय कैसे बदलें"},
            {"id": "cust_cancel_booking", "label": "❌ बुकिंग कैसे रद्द करें"},
            {"id": "cust_payment_methods", "label": "💳 भुगतान के तरीके"},
        ],
    ),

    # 1.1 Reschedule Booking
    FAQItem(
        id="cust_reschedule",
        role=Role.CUSTOMER,
        category="booking",
        keywords_en=["reschedule", "reschedule appointment", "change time", "change date", "delay booking", "postpone"],
        keywords_hi=["समय बदलें", "तारीख बदलें", "रीशेड्यूल", "आगे बढ़ाएं", "समय कैसे बदलें"],
        title_en="How to Reschedule a Booking",
        title_hi="बुकिंग का समय या तारीख कैसे बदलें",
        answer_en=(
            "🗓️ **To Reschedule a Booking:**\n\n"
            "1. Go to the **'My Bookings'** tab in the bottom bar.\n"
            "2. Select your active booking.\n"
            "3. Tap **'Reschedule'**.\n"
            "4. Choose a new date and time slot, then tap **Confirm**.\n\n"
            "⚠️ Note: Free rescheduling is allowed up to 2 hours before the scheduled time."
        ),
        answer_hi=(
            "🗓️ **बुकिंग का समय बदलने के चरण:**\n\n"
            "1. नीचे दिए गए बार में **'मेरी बुकिंग' (My Bookings)** पर जाएं।\n"
            "2. अपनी सक्रिय बुकिंग चुनें।\n"
            "3. **'रीशेड्यूल करें' (Reschedule)** पर टैप करें।\n"
            "4. नई तिथि व समय स्लॉट चुनकर पुष्टि करें।\n\n"
            "⚠️ नोट: निर्धारित समय से 2 घंटे पहले तक मुफ्त रीशेड्यूलिंग संभव है।"
        ),
    ),

    # 1.2 Cancel Booking
    FAQItem(
        id="cust_cancel_booking",
        role=Role.CUSTOMER,
        category="booking",
        keywords_en=["cancel booking", "how to cancel", "cancellation", "cancel order", "cancel service", "refund policy"],
        keywords_hi=["बुकिंग रद्द", "रद्द करें", "कैंसिल", "बुकिंग रद्द करनी", "बुकिंग कैसे रद्द करें", "रिफंड नीति"],
        title_en="How to Cancel a Booking & Refund Policy",
        title_hi="बुकिंग कैसे रद्द करें और रिफंड नीति",
        answer_en=(
            "❌ **To Cancel a Booking:**\n\n"
            "1. Open **'My Bookings'** and tap the booking you wish to cancel.\n"
            "2. Scroll down and tap **'Cancel Booking'**.\n"
            "3. Select a reason for cancellation.\n\n"
            "💰 **Refund Policy:**\n"
            "• Free cancellation up to 2 hours before the job starts.\n"
            "• Prepaid amounts are refunded within 24-48 hours to original payment method or wallet instantly."
        ),
        answer_hi=(
            "❌ **बुकिंग रद्द करने के चरण:**\n\n"
            "1. **'मेरी बुकिंग'** खोलें और जिस बुकिंग को रद्द करना है उसे चुनें।\n"
            "2. नीचे स्क्रॉल करके **'बुकिंग रद्द करें'** पर टैप करें।\n"
            "3. रद्दीकरण का कारण चुनें।\n\n"
            "💰 **रिफंड नीति:**\n"
            "• काम शुरू होने से 2 घंटे पहले तक शून्य शुल्क पर रद्दीकरण।\n"
            "• प्रीपेड राशि 24-48 घंटों में आपके मूल खाते या वॉलेट में तुरंत रिफंड कर दी जाएगी।"
        ),
    ),

    # 1.3 Payment Methods
    FAQItem(
        id="cust_payment_methods",
        role=Role.CUSTOMER,
        category="booking",
        keywords_en=["payment methods", "accepted payment", "how to pay", "upi", "credit card", "debit card", "wallet payment", "cod"],
        keywords_hi=["भुगतान के तरीके", "पेमेंट", "स्वीकृत भुगतान", "यूपीआई", "कैश", "वॉलेट"],
        title_en="Accepted Payment Methods",
        title_hi="भुगतान के स्वीकृत तरीके",
        answer_en=(
            "💳 **Accepted Payment Methods:**\n\n"
            "• **UPI**: Google Pay, PhonePe, Paytm, BHIM\n"
            "• **Cards**: Visa, Mastercard, RuPay (Credit & Debit)\n"
            "• **Net Banking**: All major Indian banks\n"
            "• **GigCommunity Wallet**: Instant checkout & cashback storage\n"
            "• **Cash on Service (COD)**: Pay directly to worker upon satisfactory completion."
        ),
        answer_hi=(
            "💳 **भुगतान के स्वीकृत तरीके:**\n\n"
            "• **UPI**: Google Pay, PhonePe, Paytm, BHIM\n"
            "• **कार्ड**: वीज़ा, मास्टरकार्ड, रुपे (क्रेडिट और डेबिट)\n"
            "• **नेट बैंकिंग**: सभी प्रमुख बैंक\n"
            "• **गिग वॉलेट**: तुरंत भुगतान और कैशबैक\n"
            "• **काम पूरा होने पर नकद**: संतोषजनक काम होने पर सीधे कार्यकर्ता को नकद दें।"
        ),
    ),

    # 2. View Current Offers
    FAQItem(
        id="cust_view_offers",
        role=Role.CUSTOMER,
        category="offers",
        keywords_en=[
            "offers", "current offers", "view offers", "discount", "discounts", "promo", "promo code",
            "coupon", "coupon code", "cashback", "deals", "vouchers"
        ],
        keywords_hi=[
            "ऑफर", "ऑफ़र", "छूट", "डिस्काउंट", "कूपन", "प्रोमो कोड", "बचत", "कैशबैक", "ऑफर और छूट"
        ],
        title_en="View Current Offers & Discounts",
        title_hi="वर्तमान ऑफ़र और छूट देखें",
        answer_en=(
            "🎉 **Current Offers Available Today:**\n\n"
            "1. 🏷️ **FIRSTGIG** - Flat ₹100 OFF on your first booking (Min order ₹299)\n"
            "2. ⚡ **SUMMER50** - 15% OFF up to ₹150 on AC & Appliance repair\n"
            "3. 🤝 **REFER50** - Refer a neighbor & both get ₹50 in app wallet\n"
            "4. 🛠️ **COMBO20** - 20% OFF when you book 2 or more home services together!\n\n"
            "💡 *How to apply:* Enter the promo code on the checkout screen before making payment."
        ),
        answer_hi=(
            "🎉 **आज उपलब्ध प्रमुख ऑफ़र:**\n\n"
            "1. 🏷️ **FIRSTGIG** - पहली बुकिंग पर फ्लैट ₹100 की छूट (न्यूनतम ₹299)\n"
            "2. ⚡ **SUMMER50** - एसी और उपकरण मरम्मत पर 15% (₹150 तक) की छूट\n"
            "3. 🤝 **REFER50** - पड़ोसी को रेफर करें और दोनों ₹50 वॉलेट बोनस पाएं\n"
            "4. 🛠️ **COMBO20** - 2 या अधिक सेवाएं एक साथ बुक करने पर 20% की छूट!\n\n"
            "💡 *कूपन कैसे लगाएं:* भुगतान करने से पहले चेकआउट स्क्रीन पर प्रोमो कोड दर्ज करें।"
        ),
        action_type="offers",
    ),

    # 3. Check Order / Booking Status
    FAQItem(
        id="cust_booking_status",
        role=Role.CUSTOMER,
        category="status",
        keywords_en=[
            "booking status", "order status", "check status", "track order", "track booking",
            "where is worker", "check order status", "track my order"
        ],
        keywords_hi=[
            "बुकिंग की स्थिति", "ऑर्डर स्थिति", "स्टेटस", "स्थिति जांचें", "बुकिंग स्टेटस", "ट्रैक", "कार्यकर्ता कहाँ है"
        ],
        title_en="Check Order / Booking Status",
        title_hi="बुकिंग या ऑर्डर स्थिति जांचें",
        answer_en=(
            "🔍 **How to Check Your Booking Status:**\n\n"
            "1. Open the **'My Bookings'** tab from the bottom navigation bar.\n"
            "2. You can view all **Active**, **Upcoming**, and **Past** orders.\n"
            "3. Tap on any order to see real-time updates:\n"
            "   • **Confirmed**: Worker assigned and verified.\n"
            "   • **On the Way**: Worker is traveling to your location (live map view).\n"
            "   • **In Progress**: Work is currently being performed.\n"
            "   • **Completed**: Service done; invoice generated.\n\n"
            "👇 *You can also enter your Booking ID below to check instantly!*"
        ),
        answer_hi=(
            "🔍 **अपनी बुकिंग स्थिति की जांच कैसे करें:**\n\n"
            "1. नीचे नेविगेशन बार से **'मेरी बुकिंग' (My Bookings)** टैब खोलें।\n"
            "2. आप सभी **सक्रिय**, **आगामी** और **पूर्ण** ऑर्डर देख सकते हैं।\n"
            "3. रीयल-टाइम अपडेट देखने के लिए किसी भी ऑर्डर पर टैप करें:\n"
            "   • **पुष्ट (Confirmed)**: कार्यकर्ता नियुक्त हो गया है।\n"
            "   • **रास्ते में (On the Way)**: कार्यकर्ता आ रहा है (लाइव मैप देखें)।\n"
            "   • **कार्य प्रगति पर (In Progress)**: कार्य चल रहा है।\n"
            "   • **पूर्ण (Completed)**: कार्य पूरा हुआ और बिल तैयार।\n\n"
            "👇 *आप तुरंत जांचने के लिए नीचे अपनी बुकिंग आईडी भी दर्ज कर सकते हैं!*"
        ),
        action_type="status",
    ),

    # 4. How to Use App Features
    FAQItem(
        id="cust_app_features",
        role=Role.CUSTOMER,
        category="features",
        keywords_en=[
            "app features", "how to use app", "features overview", "favorite worker",
            "masked calling", "sos safety", "app wallet features"
        ],
        keywords_hi=[
            "ऐप सुविधाएं", "ऐप फीचर्स", "ऐप कैसे इस्तेमाल करें", "सुविधाएं", "वॉलेट", "सुरक्षा", "फेवरिट"
        ],
        title_en="How to Use Customer App Features",
        title_hi="ग्राहक ऐप की सुविधाएं कैसे इस्तेमाल करें",
        answer_en=(
            "📱 **Key App Features for Customers:**\n\n"
            "• ⭐ **Favorite Workers**: Heart any trusted worker's profile to book them directly in the future.\n"
            "• 💬 **In-App Chat & Call**: Call or message the assigned worker without sharing personal phone numbers (masked numbers).\n"
            "• 👛 **Community Wallet**: Add funds for 1-click booking, instant refunds, and bonus rewards.\n"
            "• 🛡️ **Safety SOS**: Tap the red shield icon during an active job to instantly alert our emergency support team.\n"
            "• 📝 **Reviews & Ratings**: Rate your service worker after completion to help the community."
        ),
        answer_hi=(
            "📱 **ग्राहकों के लिए मुख्य ऐप सुविधाएं:**\n\n"
            "• ⭐ **पसंदीदा कार्यकर्ता (Favorite Workers)**: भविष्य में सीधे बुक करने के लिए किसी भी कार्यकर्ता को दिल (Heart) आइकन दबाकर सहेजें।\n"
            "• 💬 **इन-ऐप चैट और कॉल**: अपना नंबर दिखाए बिना सुरक्षित कॉलिंग और चैट करें।\n"
            "• 👛 **कम्युनिटी वॉलेट**: 1-क्लिक बुकिंग, त्वरित रिफंड और बोनस के लिए पैसे जोड़ें।\n"
            "• 🛡️ **सुरक्षा एसओएस (Safety SOS)**: आपातकालीन सहायता के लिए लाल शील्ड आइकन दबाएं।\n"
            "• 📝 **रेटिंग और समीक्षा**: सेवा पूरी होने पर कार्यकर्ता को रेटिंग दें।"
        ),
        sub_options_en=[
            {"id": "cust_wallet_help", "label": "👛 Wallet & Refunds Guide"},
            {"id": "cust_safety_help", "label": "🛡️ Safety & Trust Features"},
        ],
        sub_options_hi=[
            {"id": "cust_wallet_help", "label": "👛 वॉलेट और रिफंड गाइड"},
            {"id": "cust_safety_help", "label": "🛡️ सुरक्षा और विश्वास सुविधाएं"},
        ],
    ),

    # 4.1 Wallet Help
    FAQItem(
        id="cust_wallet_help",
        role=Role.CUSTOMER,
        category="features",
        keywords_en=["wallet", "wallet help", "add money to wallet", "wallet refund", "wallet balance"],
        keywords_hi=["वॉलेट", "वॉलेट गाइड", "वॉलेट में पैसे जोड़ें", "वॉलेट बैलेंस"],
        title_en="Wallet & Refunds Guide",
        title_hi="वॉलेट और रिफंड गाइड",
        answer_en=(
            "👛 **Using Your App Wallet:**\n\n"
            "1. Tap the **Account** tab > **'My Wallet'**.\n"
            "2. Tap **'Add Money'** using UPI or cards.\n"
            "3. Wallet balance is automatically applied at checkout for faster payments.\n"
            "4. Cancelled booking refunds to wallet are instant (0-minute delay)!"
        ),
        answer_hi=(
            "👛 **ऐप वॉलेट का उपयोग कैसे करें:**\n\n"
            "1. **अकाउंट (Account)** टैब > **'माई वॉलेट'** पर टैप करें।\n"
            "2. UPI या कार्ड के ज़रिए **'पैसे जोड़ें'** पर क्लिक करें।\n"
            "3. चेकआउट पर वॉलेट बैलेंस अपने आप लग जाता है।\n"
            "4. रद्द बुकिंग का रिफंड तुरंत वॉलेट में आ जाता है!"
        ),
    ),

    # 4.2 Safety Help
    FAQItem(
        id="cust_safety_help",
        role=Role.CUSTOMER,
        category="features",
        keywords_en=["safety features", "sos emergency", "background check", "police verification", "trust safety"],
        keywords_hi=["सुरक्षा सुविधाएं", "एसओएस", "इमरजेंसी", "सत्यापन"],
        title_en="Safety & Trust Features",
        title_hi="सुरक्षा और विश्वास सुविधाएं",
        answer_en=(
            "🛡️ **Safety & Verification in GigCommunity:**\n\n"
            "• **100% KYC & Background Checked**: Every worker undergoes government ID verification and background checks.\n"
            "• **Number Masking**: Your phone number is never revealed to workers.\n"
            "• **24/7 SOS Emergency Button**: Connects to our safety response team and local emergency services immediately."
        ),
        answer_hi=(
            "🛡️ **गिग कम्युनिटी में सुरक्षा उपाय:**\n\n"
            "• **100% KYC और पृष्ठभूमि सत्यापन**: प्रत्येक कार्यकर्ता की सरकारी पहचान और पुलिस जांच की जाती है।\n"
            "• **नंबर गोपनीयता (Masking)**: आपका फ़ोन नंबर कार्यकर्ता को नहीं दिखाया जाता।\n"
            "• **24/7 एसओएस आपातकालीन बटन**: संकट के समय तुरंत सहायता टीम से जुड़ें।"
        ),
    ),

    # 5. Raise a Complaint / Ticket
    FAQItem(
        id="cust_raise_ticket",
        role=Role.CUSTOMER,
        category="ticket",
        keywords_en=[
            "raise a complaint", "raise ticket", "support ticket", "complaint", "report issue",
            "bad service", "overcharged", "dispute", "grievance"
        ],
        keywords_hi=[
            "शिकायत दर्ज करें", "शिकायत", "सपोर्ट टिकट", "समस्या", "दिक्कत", "विवाद", "टिकट दर्ज"
        ],
        title_en="Raise a Complaint / Support Ticket",
        title_hi="शिकायत या सपोर्ट टिकट दर्ज करें",
        answer_en=(
            "🎫 **We are here to resolve your concern promptly!**\n\n"
            "You can raise a support ticket directly through this chat. Our resolution team will review it and resolve it within 24 hours.\n\n"
            "Please select your issue category below to start:"
        ),
        answer_hi=(
            "🎫 **हम आपकी समस्या का तुरंत समाधान करने के लिए तत्पर हैं!**\n\n"
            "आप इस चैट के माध्यम से सीधे टिकट दर्ज कर सकते हैं। हमारी सहायता टीम 24 घंटे में समाधान करेगी।\n\n"
            "शुरू करने के लिए कृपया नीचे दी गई श्रेणियों में से चुनें:"
        ),
        action_type="ticket",
        sub_options_en=[
            {"id": "ticket_cat_noshow", "label": "🚗 Worker Delayed or No-Show"},
            {"id": "ticket_cat_quality", "label": "⚠️ Poor Quality of Service"},
            {"id": "ticket_cat_billing", "label": "💵 Billing / Overcharging Issue"},
            {"id": "ticket_cat_app", "label": "📱 App / Payment Technical Issue"},
            {"id": "ticket_cat_other", "label": "❓ Other Concern"},
        ],
        sub_options_hi=[
            {"id": "ticket_cat_noshow", "label": "🚗 कार्यकर्ता नहीं आया या देरी हुई"},
            {"id": "ticket_cat_quality", "label": "⚠️ सेवा की गुणवत्ता खराब थी"},
            {"id": "ticket_cat_billing", "label": "💵 बिलिंग या अधिक शुल्क की समस्या"},
            {"id": "ticket_cat_app", "label": "📱 ऐप या भुगतान में तकनीकी समस्या"},
            {"id": "ticket_cat_other", "label": "❓ अन्य समस्या"},
        ],
    ),
]


def get_customer_faqs() -> List[FAQItem]:
    return CUSTOMER_FAQS


def get_customer_faq_by_id(faq_id: str) -> FAQItem:
    for faq in CUSTOMER_FAQS:
        if faq.id == faq_id:
            return faq
    return None
