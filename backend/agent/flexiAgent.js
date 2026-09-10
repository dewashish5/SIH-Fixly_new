import Service from "../models/Service.js";
import Booking from "../models/Booking.js";
import User from "../models/User.js";
import redis from "../config/redis.js";
import { llm, isGeminiConfigured } from "./model.js";
import { FLEXI_SYSTEM_PROMPT } from "./prompt.js";
import { aiLogger } from "../utils/aiLogger.js";

// Session timeout: 600 seconds (10 minute idle expiration)
const SESSION_TTL_SECONDS = 600;

export const CATEGORY_MAP = {
    Electrical: [
        "electrical", "electrician", "electricity", "electric", "bijli", "switch", "wire", "wiring",
        "fan", "fuse", "mcb", "light", "lights", "power", "short circuit", "spark", "sparking",
        "socket", "plug", "bulb", "meter", "inverter", "current", "batti", "board", "tube", "tubelight",
        "बिजली", "इलेक्ट्रीशियन", "तार", "पंखा", "स्विच", "शॉर्ट सर्किट", "बत्ती", "करंट"
    ],
    Plumbing: [
        "plumbing", "plumber", "nal", "leak", "leaking", "leakage", "pipe", "pipes", "tap", "taps",
        "water", "paani", "drainage", "sewer", "sink", "flush", "toilet", "tank", "tanki", "motor",
        "motor repair", "choke", "overflow", "geyser", "basin", "प्लंबर", "नल", "पानी", "पाइप", "लीक",
        "टोंटी", "ड्रेनेज", "टंकी", "गीजर"
    ],
    Cleaning: [
        "cleaning", "cleaner", "safai", "sofa", "dust", "deep cleaning", "house cleaning", "bathroom cleaning",
        "kitchen cleaning", "vacuum", "sanitize", "mop", "झाड़ू", "सफाई", "क्लीनर", "धुलाई", "गहरी सफाई"
    ],
    Carpentry: [
        "carpentry", "carpenter", "wood", "wooden", "furniture", "door", "doors", "window", "bed", "table",
        "chair", "lock", "cabinet", "almirah", "hinge", "दरवाजा", "कारपेंटर", "लकड़ी", "फर्नीचर", "ताला", "अलमारी"
    ],
    Appliance: [
        "appliance", "ac", "air conditioner", "cooler", "fridge", "refrigerator", "washing machine",
        "microwave", "oven", "tv", "television", "ro", "water purifier", "chimney", "heater",
        "एसी", "कूलर", "फ्रिज", "अप्लायंस", "वॉशिंग मशीन", "आरो", "चिमनी"
    ],
    Painting: [
        "painting", "painter", "paint", "putty", "wall", "whitewash", "distemper", "color", "colour",
        "texture", "पेंटर", "पेंटिंग", "रंगाई", "पुट्टी", "सफेदी"
    ],
    Gardening: [
        "gardening", "gardener", "mali", "plants", "lawn", "grass", "pots", "tree", "garden",
        "माली", "पौधे", "बगीचा", "घास", "गमले"
    ]
};

export const detectCategory = (text = "") => {
    const lower = text.toLowerCase();
    for (const [cat, words] of Object.entries(CATEGORY_MAP)) {
        for (const w of words) {
            if (w.length <= 3) {
                const regex = new RegExp(`(^|[^a-z0-9\u0900-\u097F])${w}([^a-z0-9\u0900-\u097F]|$)`, 'i');
                if (regex.test(lower)) return cat;
            } else {
                if (lower.includes(w)) return cat;
            }
        }
    }
    return null;
};

export const detectLanguage = (text = "", userPreferred = "hi") => {
    if (/[\u0900-\u097F]/.test(text)) return "hi";
    const hindiWords = ["kya", "kaise", "chahiye", "karo", "nal", "bijli", "paani", "bhai", "mujhe", "mera", "turant", "jaldi", "nahin", "nahi", "kru", "karein", "batao", "bhejo"];
    if (hindiWords.some(w => text.toLowerCase().includes(w))) return "hi";
    return userPreferred || "hi";
};

export const isBookingQuery = (text = "") => {
    const lower = text.toLowerCase().trim();
    if (["confirm", "new", "standard", "emergency", "cancel", "kardo", "chahiye", "select", "karo", "batao"].some(w => lower.includes(w) && !lower.includes("status") && !lower.includes("track"))) {
        return false;
    }
    return [
        "booking status", "track booking", "my booking", "meri booking",
        "check booking", "order status", "कहाँ है", "स्टेटस", "मेरी बुकिंग",
        "track order", "booking track"
    ].some(w => lower.includes(w));
};

export const isWorkerQuery = (text = "") => {
    const lower = text.toLowerCase();
    // Exclude worker selection actions (e.g. "Select worker: Vaibhav Jain (ID: ...)")
    if (lower.includes("select worker") || lower.includes("chuno") || lower.includes("id:") || /[0-9a-fA-F]{24}/.test(text)) {
        return false;
    }
    if (lower.includes("auto") || lower.includes("anyone") || lower.includes("koi bhi")) {
        return false;
    }
    return [
        "workers available", "available workers", "who is available", "who can", "kaun hai", "kitne worker",
        "kaun karega", "karyakarta", "उपलब्ध", "कितने कार्यकर्ता"
    ].some(w => lower.includes(w));
};

export const parseBookingTypeChoice = (text = "") => {
    const lower = text.toLowerCase().trim();
    if (["sos", "emergency", "turant", "urgent", "jaldi", "आपातकालीन", "तत्काल"].some(w => lower.includes(w))) {
        return 'EMERGENCY_SOS';
    }
    if (["schedule", "later", "baad me", "kal", "tomorrow", "shaam", "baje", "date", "time", "शेड्यूल", "बाद में", "समय"].some(w => lower.includes(w))) {
        return 'SCHEDULED';
    }
    if (["standard", "normal", "abhi", "regular", "सामान्य", "स्टैंडर्ड"].some(w => lower.includes(w))) {
        return 'STANDARD';
    }
    return null;
};

export const parseWorkerChoice = (text = "", workers = []) => {
    const lower = text.toLowerCase().trim();
    if (["auto", "auto-assign", "auto assign", "koi bhi", "any", "anyone", "closest", "nearest", "kisi ko bhi", "koi bhi chalega", "स्वतः", "कोई भी", "स्वतः असाइन"].some(w => lower.includes(w))) {
        return { isAuto: true, worker: null };
    }
    // Match ID
    const idMatch = text.match(/[0-9a-fA-F]{24}/);
    if (idMatch) {
        const found = workers.find(w => String(w._id) === idMatch[0]);
        if (found) return { isAuto: false, worker: found };
    }
    // Match by name
    for (const w of workers) {
        if (w.name && lower.includes(w.name.toLowerCase())) {
            return { isAuto: false, worker: w };
        }
    }
    return null;
};

/**
 * Fetch online, verified, non-busy workers for a category
 */
export const getAvailableWorkersForCategory = async ({ category, limit = 5 }) => {
    const query = {
        role: 'worker',
        isVerified: true,
        'workerProfile.isOnline': true,
    };

    if (category) {
        const queryWords = CATEGORY_MAP[category] || [category.toLowerCase()];
        const regexes = queryWords.slice(0, 8).map(w => new RegExp(w, 'i'));
        query.$or = [
            { 'workerProfile.category': { $in: regexes } },
            { 'workerProfile.categories': { $in: regexes } },
            { 'workerProfile.skills': { $in: regexes } }
        ];
    }

    const busyWorkers = await Booking.distinct('worker', {
        status: { $in: ['APPROVED', 'ACCEPTED', 'ARRIVED', 'IN_PROGRESS'] },
        worker: { $ne: null },
    });
    if (busyWorkers.length > 0) {
        query._id = { $nin: busyWorkers.filter(Boolean) };
    }

    const workers = await User.find(query)
        .select('name avatar phone rating workerProfile address')
        .limit(limit)
        .lean();

    return workers.map(w => ({
        _id: String(w._id),
        name: w.name || 'Cooperative Worker',
        avatar: w.avatar || w.workerProfile?.selfieImageUrl || null,
        phone: w.phone || null,
        rating: w.workerProfile?.rating !== undefined ? Number(w.workerProfile.rating) : 0.0,
        ratingCount: w.workerProfile?.totalJobs || 0,
        category: w.workerProfile?.category || category,
        hourlyRate: w.workerProfile?.rate || w.workerProfile?.hourlyRate || 199,
        experienceYears: w.workerProfile?.experienceYears || 3,
        society: w.workerProfile?.society?.name || 'Fixly Central Cooperative',
        isOnline: true,
    }));
};

export const getSuggestedReplies = (action, state = {}, lang = 'en') => {
    const isHi = lang === 'hi';
    switch (action) {
        case 'PROMPT_CATEGORY':
        case 'SESSION_EXPIRED':
        case 'SESSION_ABORTED':
            return isHi
                ? ['नल का रिसाव (Plumber)', 'बिजली / स्विच खराब (Electrician)', 'घर की गहरी सफाई (Cleaning)', 'एसी सर्विस (AC Repair)', 'मेरी बुकिंग स्थिति']
                : ['Plumbing leak / repair', 'Electrician / Wiring issue', 'Deep home cleaning', 'AC service & repair', 'Track my bookings'];
        case 'PROMPT_BOOKING_TYPE':
            return isHi
                ? ['⚡ Emergency SOS (तुरंत)', '⏱️ Standard Booking (सामान्य)', '📅 Schedule (आगे का समय)']
                : ['⚡ Emergency SOS (Urgent)', '⏱️ Standard Booking', '📅 Schedule for Later'];
        case 'PROMPT_SCHEDULE_TIME':
            return isHi
                ? ['कल सुबह 10 बजे', 'कल दोपहर 3 बजे', 'आज शाम 6 बजे', 'रद्द करें']
                : ['Tomorrow 10:00 AM', 'Tomorrow 3:00 PM', 'Today Evening 6:00 PM', 'Cancel'];
        case 'PROMPT_WORKER_SELECTION':
            return isHi
                ? ['स्वतः असाइन करें (Auto-Assign)', 'पहला कार्यकर्ता चुनें', 'रद्द करें']
                : ['Auto-assign nearest worker', 'Select first worker', 'Cancel'];
        case 'NO_WORKERS_AVAILABLE':
            return isHi
                ? ['📅 बाद के लिए शेड्यूल करें', 'अन्य सेवा चुनें', 'रद्द करें']
                : ['📅 Schedule for Later', 'Try another service', 'Cancel'];
        case 'CONFIRM_EMERGENCY_BOOKING':
            return isHi
                ? ['हाँ, तुरंत कार्यकर्ता भेजें', 'नहीं, बाद में बुक करेंगे', 'रद्द करें']
                : ['Yes, send worker immediately', 'No, not right now', 'Cancel'];
        case 'PROMPT_CONFIRMATION':
            return isHi
                ? ['हाँ, बुकिंग कन्फर्म करें', 'खर्च कितना होगा?', 'पते की पुष्टि करें', 'रद्द करें']
                : ['Yes, confirm booking', 'What is the estimated cost?', 'Confirm my address', 'Cancel'];
        case 'WORKERS_AVAILABLE':
            return isHi
                ? ['हाँ, बुकिंग कन्फर्म करें', 'कितना समय लगेगा?', 'रद्द करें']
                : ['Yes, confirm booking', 'How long will it take?', 'Cancel'];
        case 'BOOKING_CREATED':
            return isHi
                ? ['कार्यकर्ता को ट्रैक करें', 'मेरी बुकिंग्स देखें', 'नई सेवा बुक करें']
                : ['Track worker live', 'View my bookings', 'Book another service'];
        case 'BOOKING_STATUS':
            return isHi
                ? ['कार्यकर्ता को कॉल करें', 'सक्रिय ऑर्डर ट्रैक करें', 'नई सेवा चाहिए']
                : ['Call worker', 'Track active booking', 'Need another service'];
        case 'MISSING_DETAILS':
            return isHi
                ? ['नल ठीक करना है', 'इलेक्ट्रीशियन चाहिए', 'पता अपडेट करें']
                : ['Need a plumber', 'Need an electrician', 'Update my address'];
        case 'OFF_TOPIC_GUARD':
        default:
            return isHi
                ? ['प्लंबर चाहिए', 'इलेक्ट्रीशियन चाहिए', 'घर की सफाई', 'बुकिंग स्टेटस']
                : ['Need a plumber', 'Need an electrician', 'Need home cleaning', 'Booking status'];
    }
};

/**
 * Main AI Agent Conversation Handler with Progressive Slot-Filling State Machine
 */
export const processFlexiAgentMessage = async ({
    userId,
    message,
    conversationState = {},
    coordinates = null,
    addressLine = null,
    explicitLanguage = null,
    io = null,
}) => {
    const text = String(message || "").trim();
    const lang = explicitLanguage || conversationState.language || detectLanguage(text, "hi");
    const isHi = lang === "hi";
    const sessionKey = userId ? `flexi:session:${userId}` : null;
    const historyKey = userId ? `flexi:history:${userId}` : null;

    console.log(`[FlexiAgent] Processing turn for user: ${userId || 'guest'} | text: "${text}" | lang: ${lang}`);

    // --- 1. Session Memory & Multi-turn History Retrieval ---
    let activeState = { ...conversationState, language: lang };
    let conversationHistory = [];

    if (sessionKey) {
        try {
            const cachedSession = await redis.get(sessionKey);
            if (cachedSession) {
                const parsed = JSON.parse(cachedSession);
                activeState = { ...parsed, ...conversationState, language: lang };
                console.log(`[FlexiAgent] Restored active state from Redis:`, activeState);
            }
        } catch (err) {
            console.warn(`[FlexiAgent] Redis session restore error:`, err.message);
        }
    }

    if (historyKey) {
        try {
            const cachedHistory = await redis.get(historyKey);
            if (cachedHistory) {
                conversationHistory = JSON.parse(cachedHistory);
            }
        } catch (err) {}
    }

    const state = activeState;

    // --- 2. User Explicit Exit / Cancel Check ---
    const isExplicitCancel = ["cancel", "exit", "quit", "band karo", "nahi chahiye", "radd karo", "रद्द", "बंद करो", "nahi krna"].some(w => text.toLowerCase().includes(w));
    if (isExplicitCancel) {
        if (sessionKey) {
            try { await redis.del(sessionKey); } catch (e) {}
        }
        if (historyKey) {
            try { await redis.del(historyKey); } catch (e) {}
        }
        const reply = isHi
            ? "बुकिंग सत्र रद्द कर दिया गया है और कोई बुकिंग दर्ज नहीं की गई। जब भी आपको किसी सेवा की आवश्यकता हो, बेझिझक Flexi से कहें!"
            : "Booking session has been cancelled. No booking was created. Feel free to reach out anytime!";

        const action = "SESSION_ABORTED";
        return {
            reply,
            state: { language: lang, step: null },
            action,
            suggestedReplies: getSuggestedReplies(action, state, lang)
        };
    }

    // --- 2b. User Reset / Restart / Confusion / Clarification Check ---
    const isResetOrConfusion = [
        "reset", "clear", "start over", "restart", "nayi booking", "nai booking", "shuru se", "wapas",
        "try another service", "another service", "other service", "try other", "change service",
        "dusri service", "koi aur service", "dusra kaam", "different service",
        "i don't understand", "dont understand", "what are you saying", "what do you mean",
        "samajh nahi aaya", "samajh nahi aa raha", "kya bol rahe ho", "kya keh rahe ho",
        "kya matlab", "help me", "kuch samajh nahi", "batao kya karein"
    ].some(w => text.toLowerCase().includes(w));

    if (isResetOrConfusion) {
        if (sessionKey) {
            try { await redis.del(sessionKey); } catch (e) {}
        }
        if (historyKey) {
            try { await redis.del(historyKey); } catch (e) {}
        }
        state.category = null;
        state.workerId = null;
        state.workerName = null;
        state.bookingType = null;
        state.scheduledTime = null;
        state.problemDescription = null;
        state.estimate = null;
        state.policy = null;
        state.step = "AWAITING_CATEGORY";

        const isAnotherService = ["another service", "other service", "change service", "dusri service", "koi aur"].some(w => text.toLowerCase().includes(w));

        const reply = isAnotherService
            ? (isHi
                ? "ज़रूर! आप कौन सी दूसरी सेवा लेना चाहेंगे? हमारे पास अभी बिजली (Electrical) और प्लंबिंग (Plumbing) के सत्यापित कार्यकर्ता उपलब्ध हैं।"
                : "Sure! Which other service would you like to try? We currently have verified cooperative workers available for Electrical and Plumbing.")
            : (isHi
                ? "माफ़ कीजिए, कोई बात नहीं! आइए नए सिरे से शुरू करते हैं। Fixly Cooperative पर आपको किस घरेलू सेवा की आवश्यकता है? (जैसे: प्लंबिंग, बिजली, घर की सफाई, कारपेंटर आदि)"
                : "Apologies for any confusion! Let's start fresh. Which home service do you need? (e.g. Plumbing, Electrical, Cleaning, Appliance repair)");

        const action = "PROMPT_CATEGORY";
        aiLogger.logInference({
            engine: "Rule System",
            model: "Reset/Clarification Engine",
            extracted: { category: null, problemDescription: text },
            workersCount: 0,
            correction: isAnotherService ? "User switched to another service. Reset category slot." : "User requested clarification/reset. Cleared conversation state slots."
        });

        return {
            reply,
            state,
            action,
            suggestedReplies: [
                "Electrician / Wiring issue",
                "Plumbing leak / repair",
                "Deep home cleaning",
                "Cancel"
            ]
        };
    }

    // --- 3. Guardrail for Off-topic ---
    const isOffTopic = ["cricket", "ipl", "match", "politics", "election", "movie", "cinema", "क्रिकेट", "राजनीति", "मौसम"].some(w => text.toLowerCase().includes(w));
    if (isOffTopic) {
        const reply = isHi
            ? "माफ़ कीजिए, मैं केवल Fixly Cooperative Gig Services (प्लंबिंग, इलेक्ट्रीशियन, कारपेंटर, सफाई आदि) और आपकी सेवा बुकिंग्स में सहायता के लिए बना हूँ। आप अपनी घरेलू सेवा संबंधी आवश्यकता बताइए।"
            : "I apologize, I am exclusively trained to assist with Fixly Cooperative Gig Services (such as Plumbing, Electrical, Cleaning, Carpentry) and bookings. Please let me know what home service you need.";

        const action = "OFF_TOPIC_GUARD";
        return { reply, state, action, suggestedReplies: getSuggestedReplies(action, state, lang) };
    }

    // --- 4. Booking Status Query ---
    if (isBookingQuery(text)) {
        const userBookings = await Booking.find({ customer: userId })
            .populate('service', 'title category')
            .populate('worker', 'name phone')
            .sort({ createdAt: -1 })
            .limit(3)
            .lean();

        if (!userBookings.length) {
            const reply = isHi
                ? "आपकी अभी कोई सक्रिय बुकिंग नहीं है। क्या आप कोई नई सेवा बुक करना चाहते हैं?"
                : "You have no active bookings right now. Would you like to book a service?";
            const action = "NO_BOOKINGS";
            return { reply, state, action, bookings: [], suggestedReplies: getSuggestedReplies(action, state, lang) };
        }

        const latest = userBookings[0];
        const statusMapHi = {
            PENDING: "पुष्टि की प्रतीक्षा में",
            ACCEPTED: "कार्यकर्ता द्वारा स्वीकृत",
            APPROVED: "स्वीकृत",
            ARRIVED: "कार्यकर्ता आपके स्थान पर पहुँच गए हैं",
            IN_PROGRESS: "काम प्रगति पर है",
            COMPLETED: "काम पूरा हो गया है"
        };
        const statusDisplay = isHi ? (statusMapHi[latest.status] || latest.status) : latest.status;
        const workerInfo = latest.worker ? `${latest.worker.name} (${latest.worker.phone || ""})` : (isHi ? "कार्यकर्ता आवंटित हो रहा है" : "Assigning worker");

        const reply = isHi
            ? `आपकी हालिया बुकिंग #${latest.bookingId} (${latest.service?.title || "Service"}) की स्थिति "${statusDisplay}" है। आवंटित कार्यकर्ता: ${workerInfo}।`
            : `Your recent booking #${latest.bookingId} for ${latest.service?.title || "Service"} is currently "${statusDisplay}". Assigned worker: ${workerInfo}.`;

        const action = "BOOKING_STATUS";
        return { reply, state, action, bookings: userBookings, suggestedReplies: getSuggestedReplies(action, state, lang) };
    }

    // --- 5. Workers Direct Query ---
    if (isWorkerQuery(text)) {
        const detectedCat = detectCategory(text) || state.category;
        const onlineWorkers = await getAvailableWorkersForCategory({ category: detectedCat });

        const catDisplay = detectedCat || (isHi ? 'घरेलू सेवा' : 'home service');
        let reply;
        if (onlineWorkers.length > 0) {
            reply = isHi
                ? `हमारे पास आपके क्षेत्र में ${onlineWorkers.length} सत्यापित ${catDisplay} कार्यकर्ता ऑनलाइन उपलब्ध हैं। आप नीचे दिए कार्ड से किसी को भी चुन सकते हैं या बुकिंग जारी रख सकते हैं।`
                : `We found ${onlineWorkers.length} verified ${catDisplay} cooperative professionals online nearby. You can tap a card to choose or proceed with booking.`;
        } else {
            reply = isHi
                ? `वर्तमान में आपके क्षेत्र में कोई ${catDisplay} कार्यकर्ता ऑनलाइन उपलब्ध नहीं है। आप बाद के समय के लिए शेड्यूल कर सकते हैं।`
                : `No verified ${catDisplay} professionals are currently online in your area. Would you like to schedule for later?`;
        }

        if (detectedCat) {
            state.category = detectedCat;
        }
        const action = onlineWorkers.length > 0 ? "WORKERS_AVAILABLE" : "NO_WORKERS_AVAILABLE";
        return { reply, state, action, workers: onlineWorkers, suggestedReplies: getSuggestedReplies(action, state, lang) };
    }

    // --- 6. Extract Details via Gemini LLM or Fast Pattern ---
    const detectedFromKeywords = detectCategory(text);
    const bookingTypeFromKeywords = parseBookingTypeChoice(text);

    let extracted = {
        category: detectedFromKeywords,
        bookingType: bookingTypeFromKeywords,
        isEmergency: bookingTypeFromKeywords === 'EMERGENCY_SOS',
        problemDescription: text,
    };

    let engineUsed = "Local Keyword/Rule Extractor";
    let activeModel = null;
    let inferenceIssue = null;
    let autoCorrection = null;

    if (isGeminiConfigured()) {
        try {
            const historyText = conversationHistory.slice(-4).map(h => `${h.role === 'user' ? 'User' : 'Assistant'}: "${h.content}"`).join('\n');
            const promptContext = `${FLEXI_SYSTEM_PROMPT}

Recent Conversation History:
${historyText || 'No prior context.'}

Current State: ${JSON.stringify(state)}
Latest User Spoken Message: "${text}"
Target Language: ${lang}

Analyze the user's message and return the single JSON output with keys:
{
  "category": "Electrical" | "Plumbing" | "Cleaning" | "Carpentry" | "Appliance" | "Painting" | "Gardening" | null,
  "bookingType": "STANDARD" | "EMERGENCY_SOS" | "SCHEDULED" | null,
  "isEmergency": boolean,
  "scheduledTime": string | null,
  "workerSelection": string | null,
  "confirmation": boolean,
  "problemDescription": string
}`;

            const aiRes = await llm.invoke(promptContext);
            engineUsed = "Google Gemini";
            activeModel = aiRes.model || "gemini-flash-lite-latest";

            const cleaned = (aiRes.content || "").replace(/```json/gi, "").replace(/```/g, "").trim();
            const parsed = JSON.parse(cleaned);

            if (parsed.category) extracted.category = parsed.category;
            if (parsed.bookingType) extracted.bookingType = parsed.bookingType;
            if (parsed.isEmergency !== undefined) extracted.isEmergency = Boolean(parsed.isEmergency);
            if (parsed.scheduledTime) extracted.scheduledTime = parsed.scheduledTime;
            if (parsed.workerSelection) extracted.workerSelection = parsed.workerSelection;
            if (parsed.confirmation !== undefined) extracted.confirmation = Boolean(parsed.confirmation);
            if (parsed.problemDescription) extracted.problemDescription = parsed.problemDescription;
        } catch (e) {
            inferenceIssue = `Gemini call failed: ${e.message.slice(0, 100)}`;
            autoCorrection = `Auto-fallback to rule engine (Category: ${extracted.category || 'None'})`;
            console.warn(`[FlexiAgent] Gemini LLM invocation warning:`, e.message);
        }
    }

    const explicitBookingType = bookingTypeFromKeywords || (extracted.bookingType === 'EMERGENCY_SOS' ? 'EMERGENCY_SOS' : (extracted.bookingType === 'SCHEDULED' ? 'SCHEDULED' : null));

    // --- 7. Category Switching & State Evolution ---
    // If a new category is mentioned, switch immediately and reset downstream slots
    if (extracted.category && (!state.category || state.category.toLowerCase() !== extracted.category.toLowerCase())) {
        console.log(`🔄 [FlexiAgent] Category switched: "${state.category}" ➔ "${extracted.category}"`);
        state.category = extracted.category;
        state.problemDescription = extracted.problemDescription || text;
        state.workerId = null;
        state.workerName = null;
        state.bookingType = explicitBookingType;
        state.isEmergency = explicitBookingType === 'EMERGENCY_SOS';
        state.scheduledTime = extracted.scheduledTime || null;
        state.step = explicitBookingType ? 'AWAITING_WORKER_SELECTION' : 'AWAITING_BOOKING_TYPE';
    } else if (extracted.problemDescription) {
        state.problemDescription = extracted.problemDescription;
    }

    if (extracted.scheduledTime && !state.scheduledTime) {
        state.scheduledTime = extracted.scheduledTime;
    }

    // Confirmation keywords check (strictly distinct from worker selection)
    const isSelectingWorker = Boolean(
        text.toLowerCase().includes("select worker") ||
        text.toLowerCase().includes("chuno") ||
        /[0-9a-fA-F]{24}/.test(text)
    );
    const hasExplicitConfirmPhrase = ["confirm", "kardo", "कन्फर्म", "कर दो", "करदो", "हाँ कर दो", "yes confirm", "haan confirm", "confirm booking", "book now", "proceed"].some(w => text.toLowerCase().includes(w));
    const isShortAffirmation = ["yes", "haan", "ha", "हाँ", "ठीक है", "ok"].includes(text.toLowerCase().trim());
    const isUserConfirming = !isSelectingWorker && (hasExplicitConfirmPhrase || isShortAffirmation || (extracted.confirmation === true && !extracted.workerSelection));

    // --- 8. PROGRESSIVE SLOT-FILLING STATE MACHINE ---

    // STEP 1: Missing Category -> Prompt Category
    if (!state.category) {
        state.step = "AWAITING_CATEGORY";
        aiLogger.logInference({
            engine: engineUsed,
            model: activeModel,
            extracted,
            workersCount: 0,
            issue: inferenceIssue || "Category slot not yet filled",
            correction: autoCorrection
        });
        const reply = isHi
            ? "नमस्ते! मैं Flexi AI हूँ। आपको किस घरेलू सेवा की आवश्यकता है? (जैसे: नल ठीक करना, बिजली/स्विच, घर की सफाई, एसी रिपेयर आदि)"
            : "Hello! I am Flexi AI. Which home service do you need? (e.g. Plumbing, Electrical, Cleaning, Appliance repair)";
        const action = "PROMPT_CATEGORY";
        await saveSession(sessionKey, historyKey, state, text, reply, conversationHistory);
        return { reply, state, action, suggestedReplies: getSuggestedReplies(action, state, lang) };
    }

    // STEP 2: Missing Booking Type -> Prompt Booking Type (Emergency SOS vs Standard vs Scheduled)
    if (!state.bookingType) {
        const typeChoice = parseBookingTypeChoice(text);
        if (typeChoice) {
            state.bookingType = typeChoice;
            state.isEmergency = typeChoice === 'EMERGENCY_SOS';
        } else {
            state.step = "AWAITING_BOOKING_TYPE";
            const reply = isHi
                ? `मैंने आपकी ${state.category} सेवा की आवश्यकता नोट कर ली है: "${state.problemDescription || text}"।\nआप इसे कैसे बुक करना चाहते हैं?\n• ⚡ Emergency SOS (तत्काल 15-30 मिनट में)\n• ⏱️ Standard (सामान्य सेवा)\n• 📅 Schedule (आगे के समय के लिए)`
                : `I have noted your ${state.category} request: "${state.problemDescription || text}".\nHow would you like to book?\n• ⚡ Emergency SOS (Instant priority)\n• ⏱️ Standard (Regular service)\n• 📅 Schedule for Later`;
            const action = "PROMPT_BOOKING_TYPE";
            await saveSession(sessionKey, historyKey, state, text, reply, conversationHistory);
            return { reply, state, action, suggestedReplies: getSuggestedReplies(action, state, lang) };
        }
    }

    // STEP 3: If Scheduled, Missing Schedule Time -> Prompt Schedule Time
    if (state.bookingType === 'SCHEDULED' && !state.scheduledTime) {
        const hasTimeWord = ["कल", "आज", "सुबह", "दोपहर", "शाम", "बजे", "tomorrow", "today", "am", "pm", "morning", "afternoon", "evening"].some(w => text.toLowerCase().includes(w));
        if (hasTimeWord && text.length > 3) {
            state.scheduledTime = text;
        } else {
            state.step = "AWAITING_SCHEDULE_TIME";
            const reply = isHi
                ? `कृपया बताइए आप किस दिन और समय पर सेवा चाहते हैं? (जैसे: "कल सुबह 10 बजे" या "आज शाम 5 बजे")`
                : `Please specify your preferred date and time (e.g. "Tomorrow 10:00 AM" or "Today 5:00 PM"):`;
            const action = "PROMPT_SCHEDULE_TIME";
            await saveSession(sessionKey, historyKey, state, text, reply, conversationHistory);
            return { reply, state, action, suggestedReplies: getSuggestedReplies(action, state, lang) };
        }
    }

    // STEP 4: Worker Availability Check & Selection
    const onlineWorkers = await getAvailableWorkersForCategory({ category: state.category });

    aiLogger.logInference({
        engine: engineUsed,
        model: activeModel,
        extracted,
        workersCount: onlineWorkers ? onlineWorkers.length : 0,
        issue: (!onlineWorkers || onlineWorkers.length === 0) ? `Zero verified workers online for category "${state.category}"` : inferenceIssue,
        correction: autoCorrection
    });

    // STRICT GUARDRAIL: If 0 eligible workers exist in that category, BLOCK GHOST BOOKING!
    if (!onlineWorkers || onlineWorkers.length === 0) {
        state.step = "AWAITING_WORKER_SELECTION";
        const reply = isHi
            ? `माफ़ कीजिए, आपके क्षेत्र में इस समय ${state.category} के कोई सत्यापित कार्यकर्ता ऑनलाइन उपलब्ध नहीं हैं। क्या आप बाद के लिए शेड्यूल करना चाहेंगे या कुछ समय बाद प्रयास करना चाहेंगे?`
            : `We're sorry, no verified ${state.category} cooperative workers are currently online in your area. Would you like to schedule for later or try again shortly?`;
        const action = "NO_WORKERS_AVAILABLE";
        await saveSession(sessionKey, historyKey, state, text, reply, conversationHistory);
        return {
            reply,
            state,
            action,
            workers: [],
            suggestedReplies: getSuggestedReplies(action, state, lang)
        };
    }

    // Check if user has selected a worker or chose auto-dispatch
    const workerChoice = parseWorkerChoice(text, onlineWorkers);
    if (workerChoice) {
        if (workerChoice.isAuto) {
            state.isAutoAssign = true;
            state.workerId = null;
            state.workerName = isHi ? 'निकटतम कार्यकर्ता (स्वतः आवंटित)' : 'Auto-Dispatch Nearest Worker';
        } else if (workerChoice.worker) {
            state.workerId = workerChoice.worker._id;
            state.workerName = workerChoice.worker.name;
            state.workerRate = workerChoice.worker.hourlyRate;
            state.isAutoAssign = false;
        }
        state.step = 'AWAITING_CONFIRMATION';
    } else if (!state.workerId && !state.isAutoAssign) {
        if (!isUserConfirming) {
            state.step = "AWAITING_WORKER_SELECTION";
            const reply = isHi
                ? `आपके क्षेत्र में ${onlineWorkers.length} सत्यापित ${state.category} कार्यकर्ता ऑनलाइन उपलब्ध हैं। आप नीचे दिए गए कार्ड से अपना पसंदीदा कार्यकर्ता चुन सकते हैं, या "स्वतः असाइन करें" कह सकते हैं:`
                : `Found ${onlineWorkers.length} verified ${state.category} cooperative workers online near you. Tap a worker card below to choose, or say "Auto-assign":`;
            const action = "PROMPT_WORKER_SELECTION";
            await saveSession(sessionKey, historyKey, state, text, reply, conversationHistory);
            return {
                reply,
                state,
                action,
                workers: onlineWorkers,
                suggestedReplies: getSuggestedReplies(action, state, lang)
            };
        }
    }

    // STEP 5: Price Estimate & Cooperative Fair Wage Policy Calculation
    let service = await Service.findOne({ category: new RegExp(`^${state.category}$`, 'i') }).lean();
    if (!service) {
        service = await Service.findOne({ isActive: true }).lean();
    }

    const basePrice = state.workerRate || service?.basePrice || 150;
    const urgentFee = state.isEmergency ? 50 : 0;
    const platformFee = 0; // Fixly 0% middleman platform fee
    const welfareContribution = Math.round(basePrice * 0.05); // 5% welfare & insurance contribution
    const totalAmount = basePrice + urgentFee + platformFee;

    const estimate = {
        baseServiceFee: basePrice,
        urgentFee,
        platformFee,
        welfareContribution,
        totalAmount,
        currency: 'INR',
    };

    const policy = {
        title: isHi ? 'Fixly सहकारी निष्पक्ष मजदूरी नीति' : 'Fixly Cooperative Fair Wage Guarantee',
        fairWageNotice: isHi
            ? 'सेवा शुल्क का 100% सीधे कार्यकर्ता को दिया जाता है।'
            : '100% of the service fee goes directly to the cooperative worker.',
        welfareFundNotice: isHi
            ? 'इसमें कार्यकर्ता सामाजिक सुरक्षा और दुर्घटना बीमा कोष का 5% शामिल है।'
            : 'Includes 5% contribution to Worker Social Security & Medical Accident Fund.',
        platformCommission: '0% Platform Fee (No Middleman)',
    };

    state.estimate = estimate;
    state.policy = policy;

    // STEP 6: Final Confirmation Check or Prompt
    if (state.step === 'AWAITING_CONFIRMATION' && isUserConfirming) {
        // Double-check availability before DB atomic creation
        if (!state.workerId) {
            const recheck = await getAvailableWorkersForCategory({ category: state.category });
            if (!recheck.length) {
                const reply = isHi
                    ? "माफ़ कीजिए, इस समय सभी कार्यकर्ता व्यस्त हो गए हैं। कृपया कुछ समय बाद प्रयास करें।"
                    : "Sorry, all workers have become occupied right now. Please try again in a few moments.";
                return { reply, state, action: "NO_WORKERS_AVAILABLE", workers: [], suggestedReplies: getSuggestedReplies("NO_WORKERS_AVAILABLE", state, lang) };
            }
        }

        const user = await User.findById(userId).lean();
        const coords = coordinates || user?.savedAddresses?.[0]?.location?.coordinates || [77.2090, 28.6139];
        const address = addressLine || user?.savedAddresses?.[0]?.addressLine || "Registered Address";

        const newBooking = await Booking.create({
            customer: userId,
            worker: state.workerId || null,
            service: service?._id,
            bookingType: state.bookingType || (state.isEmergency ? "EMERGENCY_SOS" : "STANDARD"),
            isEmergency: Boolean(state.isEmergency),
            timeSlot: state.isEmergency ? "Immediate (SOS Emergency)" : (state.scheduledTime || "Standard Service"),
            scheduledTime: state.scheduledTime ? new Date(Date.now() + 86400000) : null,
            problemDescription: state.problemDescription || `${state.category} service request via Flexi AI`,
            serviceAddress: {
                addressLine: address,
                location: { type: "Point", coordinates: coords }
            },
            status: "PENDING",
            invoice: {
                baseServiceFee: basePrice,
                platformFee: 0,
                urgentFee: urgentFee,
                totalAmount: totalAmount,
                paymentStatus: "PENDING",
                paymentMethod: "UPI"
            }
        });

        state.step = "COMPLETED";

        // Clear active session from Redis on completion
        if (sessionKey) {
            try { await redis.del(sessionKey); } catch (e) {}
        }
        if (historyKey) {
            try { await redis.del(historyKey); } catch (e) {}
        }

        // Populate booking for response & socket
        const populatedBooking = await Booking.findById(newBooking._id)
            .populate('worker', 'name phone avatar workerProfile rating')
            .populate('service', 'name category icon')
            .lean();

        if (io) {
            if (state.workerId) {
                io.emit('worker:booking_requested', {
                    workerId: String(state.workerId),
                    booking: populatedBooking || newBooking
                });
            } else {
                io.emit('booking:new_available', {
                    bookingId: newBooking._id,
                    coordinates: coords,
                    category: state.category,
                    isEmergency: state.isEmergency,
                    bookingType: newBooking.bookingType
                });
            }
        }

        const assignedText = populatedBooking?.worker?.name || state.workerName || (isHi ? 'निकटतम कार्यकर्ता को सूचित किया जा रहा है' : 'Dispatching to nearest worker');
        const reply = isHi
            ? `🎉 बधाई हो! आपकी ${state.category} सेवा की बुकिंग #${newBooking.bookingId} सफलतापूर्वक दर्ज कर ली गई है। कुल अनुमानित शुल्क: ₹${totalAmount}। कार्यकर्ता: ${assignedText}।`
            : `🎉 Congratulations! Your ${state.category} booking #${newBooking.bookingId} has been confirmed. Total fee: ₹${totalAmount}. Worker: ${assignedText}.`;

        const action = "BOOKING_CREATED";
        return {
            reply,
            state,
            action,
            booking: populatedBooking || newBooking,
            estimate,
            policy,
            suggestedReplies: getSuggestedReplies(action, state, lang)
        };
    }

    // Prompt Confirmation with Itemized Estimate & Cooperative Policy
    state.step = "AWAITING_CONFIRMATION";
    const workerDisplay = state.workerName || (isHi ? 'स्वतः निकटतम कार्यकर्ता' : 'Auto-dispatch nearest worker');
    const urgentLine = urgentFee > 0 ? (isHi ? `\n• ⚡ आपातकालीन SOS शुल्क: ₹${urgentFee}` : `\n• ⚡ Emergency SOS Fee: ₹${urgentFee}`) : '';

    const reply = isHi
        ? `लागत अनुमान तैयार है:\n• आधार शुल्क: ₹${basePrice}${urgentLine}\n• प्लेटफॉर्म शुल्क: ₹0 (Fixly सहकारी मॉडल)\n• कुल राशि: ₹${totalAmount}\n🛡️ Fixly निष्पक्ष मजदूरी: 100% राशि सीधे कार्यकर्ता को जाती है (कल्याण कोष शामिल)।\nचयनित कार्यकर्ता: ${workerDisplay}।\n\nक्या मैं आपकी यह बुकिंग कन्फर्म कर दूँ? (हाँ / नहीं बोलें)`
        : `Here is your price estimate:\n• Base Service Fee: ₹${basePrice}${urgentLine}\n• Platform Fee: ₹0 (Fixly Cooperative)\n• Total Amount: ₹${totalAmount}\n🛡️ Fixly Fair Wage Guarantee: 100% payout to worker + Cooperative Welfare & Insurance included.\nWorker: ${workerDisplay}.\n\nShall I confirm and place this booking for you? (Reply Yes / No)`;

    const action = "PROMPT_CONFIRMATION";
    await saveSession(sessionKey, historyKey, state, text, reply, conversationHistory);
    return {
        reply,
        state,
        action,
        estimate,
        policy,
        workers: onlineWorkers,
        suggestedReplies: getSuggestedReplies(action, state, lang)
    };
};

const saveSession = async (sessionKey, historyKey, state, text, reply, conversationHistory) => {
    if (sessionKey) {
        try { await redis.set(sessionKey, JSON.stringify(state), "EX", SESSION_TTL_SECONDS); } catch (e) {}
    }
    if (historyKey) {
        try {
            conversationHistory.push({ role: 'user', content: text });
            conversationHistory.push({ role: 'agent', content: reply });
            const trimmed = conversationHistory.slice(-10);
            await redis.set(historyKey, JSON.stringify(trimmed), "EX", SESSION_TTL_SECONDS);
        } catch (e) {}
    }
};

export const routeAgentMessage = processFlexiAgentMessage;
export default processFlexiAgentMessage;
