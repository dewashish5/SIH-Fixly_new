"""
Worker Knowledge Base and FAQ Trees (Bilingual: English & Hindi).
"""

from typing import Dict, List
from ..core.types import FAQItem, Language, Role

WORKER_FAQS: List[FAQItem] = [
    # 1. View Assigned Jobs
    FAQItem(
        id="work_assigned_jobs",
        role=Role.WORKER,
        category="jobs",
        keywords_en=[
            "view assigned jobs", "assigned jobs", "how to view jobs", "incoming leads",
            "accept order", "active jobs", "leads list", "customer location navigation"
        ],
        keywords_hi=[
            "सौंपे गए काम", "काम कैसे देखें", "असाइन किए गए काम", "नया काम", "काम देखना", "लीड्स", "टास्क"
        ],
        title_en="View Assigned Jobs & Tasks",
        title_hi="सौंपे गए काम और कार्य देखें",
        answer_en=(
            "📋 **How to Manage & View Your Assigned Jobs:**\n\n"
            "1. **Home Dashboard**: When you switch your duty status to **'ONLINE'**, incoming job requests will appear with service type, payout, distance, and time.\n"
            "2. **Accepting a Job**: Tap **'Accept'** within 45 seconds to secure the booking.\n"
            "3. **'My Jobs' Tab**: View all **Active**, **Scheduled**, and **Completed** tasks.\n"
            "4. **Navigation**: Tap the **'Navigate'** icon on an active job to open Google Maps directly to the customer's address.\n"
            "5. **Job Start & Completion**: Ask customer for the 4-digit **Start OTP** upon arrival, and tap **'Complete Job'** when done."
        ),
        answer_hi=(
            "📋 **सौंपे गए काम देखने और प्रबंधित करने का तरीका:**\n\n"
            "1. **होम डैशबोर्ड**: जब आप अपनी स्थिति **'ऑनलाइन (ONLINE)'** करेंगे, तो सेवा का प्रकार, कमाई, दूरी और समय के साथ नया काम स्क्रीन पर दिखेगा।\n"
            "2. **काम स्वीकार करना**: 45 सेकंड के अंदर **'स्वीकार करें (Accept)'** दबाएं।\n"
            "3. **'मेरे काम' (My Jobs) टैब**: यहाँ आप अपने **सक्रिय**, **निर्धारित** और **पूरे हुए** काम देख सकते हैं।\n"
            "4. **रास्ता देखना (GPS)**: ग्राहक के पते पर जाने के लिए **'नेविगेट' (Navigate)** आइकन दबाएं।\n"
            "5. **काम शुरू और खत्म**: पहुंचने पर ग्राहक से 4-अंकों का **Start OTP** लें, और कार्य पूरा होने पर **'काम पूरा हुआ'** पर टैप करें।"
        ),
        sub_options_en=[
            {"id": "work_job_rejection_policy", "label": "⚠️ Job Acceptance & Cancellation Rules"},
            {"id": "work_otp_guide", "label": "🔢 OTP & Job Verification Guide"},
        ],
        sub_options_hi=[
            {"id": "work_job_rejection_policy", "label": "⚠️ काम अस्वीकार और रद्दीकरण नियम"},
            {"id": "work_otp_guide", "label": "🔢 OTP और काम सत्यापन गाइड"},
        ],
    ),

    # 1.1 Job Rejection Rules
    FAQItem(
        id="work_job_rejection_policy",
        role=Role.WORKER,
        category="jobs",
        keywords_en=["acceptance rate", "rejection penalty", "cancel accepted job", "decline job policy"],
        keywords_hi=["काम मना करना", "स्वीकृति दर", "पेनल्टी", "काम रद्द नियम"],
        title_en="Job Acceptance & Cancellation Rules",
        title_hi="काम अस्वीकार और रद्दीकरण नियम",
        answer_en=(
            "⚠️ **Acceptance & Cancellation Guidelines:**\n\n"
            "• Keep your acceptance rate above **85%** to receive top-tier premium bookings.\n"
            "• If you cannot attend a job, decline it immediately so another nearby partner can be assigned.\n"
            "• Cancelling after accepting may affect your weekly incentive eligibility unless verified as emergency."
        ),
        answer_hi=(
            "⚠️ **काम स्वीकार और रद्दीकरण दिशानिर्देश:**\n\n"
            "• उच्च कमाई वाले काम पाने के लिए अपनी स्वीकृति दर **85% से ऊपर** रखें।\n"
            "• यदि आप काम नहीं कर सकते हैं, तो तुरंत अस्वीकार करें ताकि दूसरे साथी को काम मिल सके।\n"
            "• काम स्वीकार करने के बाद रद्द करने पर साप्ताहिक प्रोत्साहन (Incentive) प्रभावित हो सकता है।"
        ),
    ),

    # 1.2 OTP Guide
    FAQItem(
        id="work_otp_guide",
        role=Role.WORKER,
        category="jobs",
        keywords_en=["otp verification", "start otp", "end otp", "customer otp"],
        keywords_hi=["ओटीपी सत्यापन", "शुरुआती ओटीपी", "समाप्ति पुष्टि", "OTP"],
        title_en="OTP & Job Verification Guide",
        title_hi="OTP और कार्य सत्यापन गाइड",
        answer_en=(
            "🔢 **OTP Verification Steps:**\n\n"
            "1. **Start OTP**: When you reach the customer's location, ask for the 4-digit code shown in their app before starting work.\n"
            "2. **End OTP / Confirmation**: Once the customer inspects and approves the job, have them confirm or provide the completion OTP.\n"
            "3. *Never start work without entering the start OTP into your worker app.*"
        ),
        answer_hi=(
            "🔢 **OTP सत्यापन के चरण:**\n\n"
            "1. **शुरुआती OTP**: ग्राहक के पते पर पहुंचकर काम शुरू करने से पहले उनकी ऐप में दिख रहा 4-अंकों का कोड दर्ज करें।\n"
            "2. **समाप्ति पुष्टि**: काम पूरा होने के बाद ग्राहक को काम दिखाकर ऐप में पुष्टि करवाएं।\n"
            "3. *बिना OTP दर्ज किए कभी काम शुरू न करें।*"
        ),
    ),

    # 2. How to Use App Features (Worker)
    FAQItem(
        id="work_app_features",
        role=Role.WORKER,
        category="features",
        keywords_en=[
            "worker app features", "how to use worker app", "duty switch", "online offline switch",
            "partner tools", "worker dashboard"
        ],
        keywords_hi=[
            "वर्कर ऐप फीचर्स", "ऐप सुविधाएं", "ऐप का इस्तेमाल", "ऑनलाइन ऑफलाइन बटन", "टूल्स"
        ],
        title_en="How to Use Worker App Features",
        title_hi="वर्कर ऐप की सुविधाएं और टूल्स",
        answer_en=(
            "⚙️ **Key Features for Gig Workers & Partners:**\n\n"
            "• 🟢 **Online/Offline Switch**: Toggle on top of the home screen whenever you are ready to receive orders.\n"
            "• 💰 **Earnings Dashboard**: Track your daily, weekly, and monthly earnings, tips, and bonus incentives in real time.\n"
            "• ⚡ **Instant Payouts**: Request daily payout transfers directly to your linked UPI ID / Bank account.\n"
            "• 📍 **Service Radius Settings**: Set how far you wish to travel (e.g., 3km, 5km, 10km).\n"
            "• ⭐ **Performance Score**: View your customer ratings, badges, and tips to maximize ranking."
        ),
        answer_hi=(
            "⚙️ **गिग कार्यकर्ताओं और पार्टनर्स के लिए मुख्य सुविधाएं:**\n\n"
            "• 🟢 **ऑनलाइन / ऑफलाइन स्विच**: जब भी आप काम करने के लिए तैयार हों, होम स्क्रीन पर सबसे ऊपर वाला बटन चालू करें।\n"
            "• 💰 **कमाई डैशबोर्ड (Earnings)**: अपनी दैनिक, साप्ताहिक कमाई, टिप और बोनस इंसेंटिव लाइव देखें।\n"
            "• ⚡ **त्वरित पेआउट (Instant Payout)**: अपनी कमाई सीधे अपने UPI या बैंक खाते में कभी भी ट्रांसफर करें।\n"
            "• 📍 **कार्य क्षेत्र (Service Radius)**: तय करें कि आप कितनी दूरी तक काम करना चाहते हैं (3 किमी, 5 किमी, 10 किमी)।\n"
            "• ⭐ **प्रदर्शन स्कोर**: अपनी रेटिंग और फीडबैक देखकर शीर्ष रैंकिंग हासिल करें।"
        ),
        sub_options_en=[
            {"id": "work_payout_guide", "label": "💰 Payouts & Earnings Guide"},
            {"id": "work_radius_guide", "label": "📍 Managing Service Area & Radius"},
        ],
        sub_options_hi=[
            {"id": "work_payout_guide", "label": "💰 पेआउट और कमाई गाइड"},
            {"id": "work_radius_guide", "label": "📍 कार्य क्षेत्र और दूरी सेट करना"},
        ],
    ),

    # 2.1 Payout Guide
    FAQItem(
        id="work_payout_guide",
        role=Role.WORKER,
        category="features",
        keywords_en=["instant payout", "payout withdrawal", "withdraw earnings", "payouts", "bank payout", "cashout"],
        keywords_hi=["कमाई कैसे निकालें", "पेआउट", "पैसे निकालना", "पेआउट गाइड", "बैंक ट्रांसफर", "निकासी"],
        title_en="Earnings & Instant Payouts",
        title_hi="कमाई और त्वरित पेआउट गाइड",
        answer_en=(
            "💰 **Payout Details:**\n\n"
            "• **Auto Payout**: Every Monday at 6:00 AM, all accumulated earnings are credited automatically to your bank.\n"
            "• **Instant Payout**: Tap **'Earnings' > 'Withdraw Now'** anytime to receive funds in your UPI ID within 5 minutes (up to 3 times/day)!\n"
            "• **0% Commission on Tips**: 100% of customer tips go directly into your pocket."
        ),
        answer_hi=(
            "💰 **पेआउट की जानकारी:**\n\n"
            "• **स्वचालित पेआउट**: हर सोमवार सुबह 6:00 बजे आपकी पूरी कमाई अपने आप बैंक में ट्रांसफर हो जाती है।\n"
            "• **त्वरित पेआउट**: कभी भी **'कमाई' > 'अभी निकालें'** दबाएं और 5 मिनट में UPI में पैसे पाएं (दिन में 3 बार तक)!\n"
            "• **टिप पर 0% कमीशन**: ग्राहक द्वारा दी गई 100% टिप आपकी होती है।"
        ),
    ),

    # 2.2 Radius Guide
    FAQItem(
        id="work_radius_guide",
        role=Role.WORKER,
        category="features",
        keywords_en=["service radius", "working area", "location distance", "travel radius"],
        keywords_hi=["कार्य क्षेत्र", "दूरी सेट", "एरिया प्रबंधन"],
        title_en="Managing Service Area & Radius",
        title_hi="कार्य क्षेत्र और दूरी प्रबंधन",
        answer_en=(
            "📍 **Setting Your Working Area:**\n\n"
            "1. Go to **Profile** > **'Service Preferences'**.\n"
            "2. Select your preferred base locality / pincode.\n"
            "3. Adjust the slider from **2 km to 15 km** depending on your transport mode (Bicycle, Bike, or Van)."
        ),
        answer_hi=(
            "📍 **अपना कार्य क्षेत्र सेट करने के चरण:**\n\n"
            "1. **प्रोफ़ाइल** > **'सेवा प्राथमिकताएं' (Service Preferences)** पर जाएं।\n"
            "2. अपना आधार इलाका या पिनकोड चुनें।\n"
            "3. अपने वाहन के अनुसार दूरी स्लाइडर को **2 किमी से 15 किमी** तक सेट करें।"
        ),
    ),

    # 3. Raise a Complaint / Ticket (Worker)
    FAQItem(
        id="work_raise_ticket",
        role=Role.WORKER,
        category="ticket",
        keywords_en=[
            "raise worker ticket", "grievance ticket", "worker complaint", "payout dispute",
            "safety complaint", "report customer"
        ],
        keywords_hi=[
            "शिकायत दर्ज करें", "वर्कर शिकायत", "शिकायत", "विवाद", "सुरक्षा समस्या", "टिकट दर्ज"
        ],
        title_en="Raise a Worker Complaint / Ticket",
        title_hi="कार्यकर्ता शिकायत या सहायता टिकट दर्ज करें",
        answer_en=(
            "🎫 **Worker Support & Grievance Desk:**\n\n"
            "We protect our community partners. If you experienced payment issues, customer disputes, unfair cancellations, or safety concerns, raise a ticket right here.\n\n"
            "Select your issue category below to proceed:"
        ),
        answer_hi=(
            "🎫 **कार्यकर्ता सहायता एवं शिकायत निवारण:**\n\n"
            "हम अपने सभी साथियों की सुरक्षा और अधिकारों की रक्षा करते हैं। यदि आपको भुगतान, ग्राहक विवाद, गलत रद्दीकरण या सुरक्षा से जुड़ी कोई समस्या है, तो यहाँ टिकट दर्ज करें।\n\n"
            "कृपया नीचे दिए गए विकल्पों में से श्रेणी चुनें:"
        ),
        action_type="ticket",
        sub_options_en=[
            {"id": "ticket_worker_payment", "label": "💵 Payment / Payout / Incentive Discrepancy"},
            {"id": "ticket_worker_customer_dispute", "label": "🚫 Customer No-Show / False Cancellation"},
            {"id": "ticket_worker_safety", "label": "🛡️ Safety / Misconduct Concern"},
            {"id": "ticket_worker_app_tech", "label": "📱 App GPS / Technical Error"},
            {"id": "ticket_worker_other", "label": "❓ Other Partner Issue"},
        ],
        sub_options_hi=[
            {"id": "ticket_worker_payment", "label": "💵 भुगतान / पेआउट / इंसेंटिव की समस्या"},
            {"id": "ticket_worker_customer_dispute", "label": "🚫 ग्राहक नहीं मिला / गलत रद्दीकरण"},
            {"id": "ticket_worker_safety", "label": "🛡️ सुरक्षा / अनुचित व्यवहार की चिंता"},
            {"id": "ticket_worker_app_tech", "label": "📱 ऐप GPS / तकनीकी खराबी"},
            {"id": "ticket_worker_other", "label": "❓ अन्य साथी समस्या"},
        ],
    ),

    # 4. How to Set Up Profile & KYC
    FAQItem(
        id="work_profile_setup",
        role=Role.WORKER,
        category="profile",
        keywords_en=[
            "profile setup", "how to complete kyc", "kyc documents", "partner onboarding",
            "set up profile", "aadhaar pan verification"
        ],
        keywords_hi=[
            "प्रोफ़ाइल और केवाईसी", "प्रोफ़ाइल कैसे बनाएं", "केवाईसी", "दस्तावेज़ अपलोड", "खाता कैसे बनाएं", "प्रोफ़ाइल सेटअप"
        ],
        title_en="How to Set Up Profile & Complete KYC",
        title_hi="अपनी प्रोफ़ाइल और KYC कैसे सेट करें",
        answer_en=(
            "👤 **Step-by-Step Profile & KYC Setup Guide:**\n\n"
            "1. **Personal Information**: Add your full legal name, profile photo (clear face, good lighting), and emergency contact.\n"
            "2. **KYC Documents**: Upload clear photos of your **Aadhaar Card** (front & back) and **PAN Card**.\n"
            "3. **Skill & Experience**: Select your trade categories (e.g. Electrician, Carpenter) and upload any vocational certificates (ITI, NSDC, etc.) for a **Verified Skill Badge**.\n"
            "4. **Bank Account / UPI**: Add your active Bank Account No. + IFSC code or UPI ID for instant daily earnings payouts.\n"
            "5. **Verification Time**: Our partner team verifies documents within **2 to 4 hours**. Once approved, you can turn ON duty and start earning!"
        ),
        answer_hi=(
            "👤 **प्रोफ़ाइल और KYC पूरा करने के आसान चरण:**\n\n"
            "1. **व्यक्तिगत जानकारी**: अपना पूरा नाम, साफ़ प्रोफ़ाइल फोटो और आपातकालीन संपर्क नंबर जोड़ें।\n"
            "2. **KYC दस्तावेज़**: अपने **आधार कार्ड** (आगे और पीछे) और **पैन कार्ड** की साफ़ फोटो अपलोड करें।\n"
            "3. **हुनर और अनुभव (Skills)**: अपनी कार्य श्रेणी चुनें (जैसे इलेक्ट्रीशियन, बढ़ई) और प्रमाणपत्र (ITI, NSDC आदि) अपलोड करके **वेरिफाइड बैज** पाएं।\n"
            "4. **बैंक खाता / UPI**: दैनिक कमाई के भुगतान के लिए अपना बैंक खाता नंबर + IFSC कोड या UPI आईडी दर्ज करें।\n"
            "5. **सत्यापन का समय**: हमारी टीम **2 से 4 घंटों** के भीतर दस्तावेज़ सत्यापित कर देती है। मंज़ूरी मिलते ही आप काम शुरू कर सकते हैं!"
        ),
        sub_options_en=[
            {"id": "work_kyc_docs_list", "label": "📄 Required Documents Checklist"},
            {"id": "work_skill_badges", "label": "🏅 How to Get Verified Skill Badges"},
        ],
        sub_options_hi=[
            {"id": "work_kyc_docs_list", "label": "📄 आवश्यक दस्तावेजों की सूची"},
            {"id": "work_skill_badges", "label": "🏅 वेरिफाइड स्किल बैज कैसे प्राप्त करें"},
        ],
    ),

    # 4.1 Required Documents Checklist
    FAQItem(
        id="work_kyc_docs_list",
        role=Role.WORKER,
        category="profile",
        keywords_en=["documents checklist", "kyc list", "what documents required", "kyc documents list"],
        keywords_hi=["दस्तावेज़ सूची", "क्या कागजात चाहिए", "आवश्यक दस्तावेज़"],
        title_en="Required Documents Checklist for Workers",
        title_hi="कार्यकर्ताओं के लिए आवश्यक दस्तावेजों की सूची",
        answer_en=(
            "📄 **Document Checklist for Worker Onboarding:**\n\n"
            "• ✅ **Government Photo ID**: Aadhaar Card / Voter ID / Passport\n"
            "• ✅ **Tax ID**: PAN Card (mandatory for TDS & payouts)\n"
            "• ✅ **Bank Proof**: Cancelled Cheque, Passbook first page, or Bank Statement\n"
            "• ✅ **Driving License**: Required only for delivery, driver, or mobile mechanic roles\n"
            "• ✅ **Skill Proof**: ITI diploma / Apprentice certificate / Trade license (optional but boosts bookings by 40%)."
        ),
        answer_hi=(
            "📄 **कार्यकर्ता ऑनबोर्डिंग के लिए आवश्यक दस्तावेज़:**\n\n"
            "• ✅ **सरकारी पहचान पत्र**: आधार कार्ड / मतदाता पहचान पत्र / पासपोर्ट\n"
            "• ✅ **पैन कार्ड**: TDS और पेआउट के लिए अनिवार्य\n"
            "• ✅ **बैंक प्रमाण**: कैंसिल्ड चेक, पासबुक का पहला पन्ना या बैंक स्टेटमेंट\n"
            "• ✅ **ड्राइविंग लाइसेंस**: केवल डिलीवरी या ड्राइवर श्रेणी के लिए आवश्यक\n"
            "• ✅ **हुनर प्रमाण पत्र**: ITI डिप्लोमा / ट्रेड लाइसेंस (वैकल्पिक लेकिन इससे 40% अधिक काम मिलता है)।"
        ),
    ),

    # 4.2 Skill Badges
    FAQItem(
        id="work_skill_badges",
        role=Role.WORKER,
        category="profile",
        keywords_en=["skill badges", "verified badge", "increase worker bookings"],
        keywords_hi=["स्किल बैज", "सत्यापित बैज", "बैज कैसे पाएं"],
        title_en="How to Get Verified Skill Badges",
        title_hi="सत्यापित स्किल बैज कैसे प्राप्त करें",
        answer_en=(
            "🏅 **Benefits of Verified Skill Badges:**\n\n"
            "• Badges display on your customer-facing profile card (e.g. ⭐ Master Electrician, 🏅 Top Rated 2026).\n"
            "• Workers with skill badges receive **3x more direct customer bookings**.\n"
            "• To apply, go to **Profile > 'Certifications & Skills' > 'Upload Proof'** or attend a free community skill assessment test."
        ),
        answer_hi=(
            "🏅 **वेरिफाइड स्किल बैज के लाभ:**\n\n"
            "• ग्राहकों को दिखने वाले आपके प्रोफ़ाइल कार्ड पर विशेष बैज दिखाई देता है।\n"
            "• स्किल बैज वाले साथियों को **3 गुना अधिक सीधी बुकिंग** मिलती है।\n"
            "• आवेदन करने के लिए **प्रोफ़ाइल > 'प्रमाणपत्र' > 'प्रमाण अपलोड करें'** पर जाएं या हमारे नि:शुल्क कौशल मूल्यांकन में भाग लें।"
        ),
    ),
]


def get_worker_faqs() -> List[FAQItem]:
    return WORKER_FAQS


def get_worker_faq_by_id(faq_id: str) -> FAQItem:
    for faq in WORKER_FAQS:
        if faq.id == faq_id:
            return faq
    return None
