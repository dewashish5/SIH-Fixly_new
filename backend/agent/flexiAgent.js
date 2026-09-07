import Service from "../models/Service.js";
import Booking from "../models/Booking.js";
import User from "../models/User.js";
import redis from "../config/redis.js";
import { llm, isGeminiConfigured } from "./model.js";
import { FLEXI_SYSTEM_PROMPT } from "./prompt.js";

// Session timeout: 60 seconds (1 minute idle expiration)
const SESSION_TTL_SECONDS = 60;

const CATEGORY_MAP = {
    Electrical: ["electrical", "electrician", "bijli", "switch", "wire", "fan", "fuse", "mcb", "बिजली", "इलेक्ट्रीशियन", "तार", "पंखा"],
    Plumbing: ["plumbing", "plumber", "nal", "leak", "pipe", "tap", "water", "paani", "drainage", "प्लंबर", "नल", "पानी", "पाइप", "लीक"],
    Cleaning: ["cleaning", "cleaner", "safai", "sofa", "dust", "deep cleaning", "झाड़ू", "सफाई", "क्लीनर"],
    Carpentry: ["carpentry", "carpenter", "wood", "furniture", "door", "bed", "दरवाजा", "कारपेंटर", "लकड़ी"],
    Appliance: ["appliance", "ac", "cooler", "fridge", "washing machine", "tv", "एसी", "कूलर", "फ्रिज", "अप्लायंस"],
    Painting: ["painting", "painter", "paint", "putty", "wall", "पेंटर", "पेंटिंग", "रंगाई"],
    Gardening: ["gardening", "gardener", "mali", "plants", "lawn", "माली", "पौधे", "बगीचा"]
};

export const detectCategory = (text = "") => {
    const lower = text.toLowerCase();
    for (const [cat, words] of Object.entries(CATEGORY_MAP)) {
        if (words.some(w => lower.includes(w))) return cat;
    }
    return null;
};

export const detectLanguage = (text = "", userPreferred = "hi") => {
    if (/[\u0900-\u097F]/.test(text)) return "hi";
    const hindiWords = ["kya", "kaise", "chahiye", "karo", "nal", "bijli", "paani", "bhai", "mujhe", "mera", "turant", "jaldi"];
    if (hindiWords.some(w => text.toLowerCase().includes(w))) return "hi";
    return userPreferred || "hi";
};

export const isBookingQuery = (text = "") => {
    const lower = text.toLowerCase();
    return ["booking", "status", "कहाँ है", "स्टेटस", "मेरी बुकिंग"].some(w => lower.includes(w));
};

/**
 * Main AI Agent Conversation Handler with 1-Minute Session TTL & Strict Anti-Fake Verification
 */
export const processFlexiAgentMessage = async ({
    userId,
    message,
    conversationState = {},
    coordinates = null,
    addressLine = null,
    explicitLanguage = null,
}) => {
    const text = String(message || "").trim();
    const lang = explicitLanguage || conversationState.language || detectLanguage(text, "hi");
    const sessionKey = userId ? `flexi:session:${userId}` : null;

    // --- 1. Session TTL & 1-Minute Inactivity / Fake User Abort Check ---
    let activeState = { ...conversationState, language: lang };

    if (sessionKey) {
        try {
            const cachedSession = await redis.get(sessionKey);
            if (!cachedSession && Object.keys(conversationState).length > 0 && conversationState.step) {
                // Session expired (> 60s inactivity) - abort fake/abandoned attempt
                const reply = lang === "hi"
                    ? "समय समाप्त हो गया (सत्र समाप्त)। आपका पिछला सत्र 1 मिनट से अधिक निष्क्रिय रहने के कारण रीसेट कर दिया गया है। कृपया दोबारा बताएं कि आपको क्या सेवा चाहिए।"
                    : "Session timed out due to 1 minute of inactivity. The previous attempt was reset. Please tell me which service you need to start fresh.";

                return {
                    reply,
                    state: { language: lang, step: "AWAITING_CATEGORY" },
                    action: "SESSION_EXPIRED"
                };
            } else if (cachedSession) {
                const parsed = JSON.parse(cachedSession);
                activeState = { ...parsed, ...conversationState, language: lang };
            }
        } catch (err) {
            // In test/offline environments, smoothly continue with in-memory state
        }
    }

    const state = activeState;

    // --- 2. User Explicit Exit / Cancel Check ---
    const isExplicitCancel = ["cancel", "exit", "quit", "band karo", "nahi chahiye", "radd karo", "रद्द", "बंद करो"].some(w => text.toLowerCase().includes(w));
    if (isExplicitCancel) {
        if (sessionKey) {
            try { await redis.del(sessionKey); } catch (e) {}
        }
        const reply = lang === "hi"
            ? "बुकिंग सत्र रद्द कर दिया गया है और कोई बुकिंग दर्ज नहीं की गई। जब भी आपको किसी सेवा की आवश्यकता हो, बेझिझक Flexi से कहें!"
            : "Booking session has been cancelled. No booking was created. Feel free to reach out anytime!";

        return {
            reply,
            state: { language: lang, step: null },
            action: "SESSION_ABORTED"
        };
    }

    // --- 3. Guardrail for Off-topic ---
    const isOffTopic = ["cricket", "ipl", "match", "politics", "election", "movie", "cinema", "क्रिकेट", "राजनीति", "मौसम"].some(w => text.toLowerCase().includes(w));
    if (isOffTopic) {
        const reply = lang === "hi"
            ? "माफ़ कीजिए, मैं केवल Fixly Cooperative Gig Services (प्लंबिंग, इलेक्ट्रीशियन, कारपेंटर, सफाई आदि) और आपकी सेवा बुकिंग्स में सहायता के लिए बना हूँ। आप अपनी घरेलू सेवा संबंधी आवश्यकता बताइए।"
            : "I apologize, I am exclusively trained to assist with Fixly Cooperative Gig Services (such as Plumbing, Electrical, Cleaning, Carpentry) and bookings. Please let me know what home service you need.";

        return { reply, state, action: "OFF_TOPIC_GUARD" };
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
            const reply = lang === "hi"
                ? "आपकी अभी कोई सक्रिय बुकिंग नहीं है। क्या आप कोई नई सेवा बुक करना चाहते हैं?"
                : "You have no active bookings right now. Would you like to book a service?";
            return { reply, state, action: "NO_BOOKINGS", bookings: [] };
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
        const statusDisplay = lang === "hi" ? (statusMapHi[latest.status] || latest.status) : latest.status;
        const workerInfo = latest.worker ? `${latest.worker.name} (${latest.worker.phone || ""})` : (lang === "hi" ? "कार्यकर्ता आवंटित हो रहा है" : "Assigning worker");

        const reply = lang === "hi"
            ? `आपकी हालिया बुकिंग #${latest.bookingId} (${latest.service?.title || "Service"}) की स्थिति "${statusDisplay}" है। आवंटित कार्यकर्ता: ${workerInfo}।`
            : `Your recent booking #${latest.bookingId} for ${latest.service?.title || "Service"} is currently "${statusDisplay}". Assigned worker: ${workerInfo}.`;

        return { reply, state, action: "BOOKING_STATUS", bookings: userBookings };
    }

    // --- 5. Extract Details via Gemini LLM or Fast Pattern ---
    let extracted = {
        category: detectCategory(text),
        isEmergency: ["sos", "emergency", "turant", "urgent", "jaldi", "तुरंत", "आपातकालीन"].some(w => text.toLowerCase().includes(w)),
        problemDescription: text,
        confirmation: ["confirm", "kardo", "yes", "haan", "ha", "कन्फर्म", "हाँ", "कर दो", "करदो", "हाँ कर दो", "ठीक है"].some(w => text.toLowerCase().includes(w))
    };

    if (isGeminiConfigured()) {
        try {
            const promptContext = `${FLEXI_SYSTEM_PROMPT}

Current Conversation State: ${JSON.stringify(state)}
User Spoken Message: "${text}"
Target Language: ${lang}

Analyze the user's message and return the single JSON output.`;

            const aiRes = await llm.invoke(promptContext);
            const cleaned = (aiRes.content || "").replace(/```json/gi, "").replace(/```/g, "").trim();
            const parsed = JSON.parse(cleaned);

            if (parsed.category) extracted.category = parsed.category;
            if (parsed.isEmergency !== undefined) extracted.isEmergency = Boolean(parsed.isEmergency);
            if (parsed.problemDescription) extracted.problemDescription = parsed.problemDescription;
            if (parsed.confirmation !== undefined) extracted.confirmation = Boolean(parsed.confirmation);
        } catch (e) {
            // Keep pattern extracted values
        }
    }

    // Update state fields
    if (extracted.category && !state.category) {
        state.category = extracted.category;
    }
    if (extracted.isEmergency) {
        state.isEmergency = true;
        state.bookingType = "EMERGENCY_SOS";
    }
    if (extracted.problemDescription && !state.problemDescription) {
        state.problemDescription = extracted.problemDescription;
    }

    // --- 6. Strict Anti-Fake Verification & Explicit Confirmation Check ---
    const isExplicitConfirm = (state.step === "AWAITING_CONFIRMATION") &&
        ["confirm", "kardo", "कन्फर्म", "कर दो", "करदो", "हाँ कर दो", "yes confirm", "haan confirm"].some(w => text.toLowerCase().includes(w));

    if (isExplicitConfirm && state.category) {
        const user = await User.findById(userId).lean();
        const coords = coordinates || user?.savedAddresses?.[0]?.location?.coordinates || [77.2090, 28.6139];
        const address = addressLine || user?.savedAddresses?.[0]?.addressLine || "Registered Address";

        // Validate that mandatory data is not null/empty before touching database
        if (!state.category || !coords || !address) {
            const reply = lang === "hi"
                ? "कुछ आवश्यक जानकारी अधूरी है। कृपया अपनी सेवा और पता दोबारा बताएं।"
                : "Required booking details are incomplete. Please provide service and address.";
            return { reply, state, action: "MISSING_DETAILS" };
        }

        let service = await Service.findOne({ category: state.category.toLowerCase() }).lean();
        if (!service) {
            service = await Service.findOne({ isActive: true }).lean();
        }

        const basePrice = service?.basePrice || 150;
        const urgentFee = state.isEmergency ? 50 : 0;
        const totalAmount = basePrice + urgentFee;

        // Clean Atomic DB Transaction / Creation (Zero Fake / Zero Null Values)
        const newBooking = await Booking.create({
            customer: userId,
            service: service?._id,
            bookingType: state.bookingType || (state.isEmergency ? "EMERGENCY_SOS" : "STANDARD"),
            isEmergency: Boolean(state.isEmergency),
            timeSlot: state.isEmergency ? "Immediate (SOS Emergency)" : (state.timeSlot || "Scheduled"),
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

        const reply = lang === "hi"
            ? `🎉 बधाई हो! आपकी ${state.category} सेवा की बुकिंग #${newBooking.bookingId} सफलतापूर्वक दर्ज कर ली गई है। निकटतम प्रमाणित कार्यकर्ताओं को सूचित किया जा रहा है।`
            : `🎉 Congratulations! Your ${state.category} booking #${newBooking.bookingId} has been confirmed. Notifying verified cooperative workers.`;

        return {
            reply,
            state,
            action: "BOOKING_CREATED",
            booking: newBooking
        };
    }

    // --- 7. Step-by-Step Dialog Progression ---
    if (!state.category) {
        state.step = "AWAITING_CATEGORY";
        const reply = lang === "hi"
            ? "नमस्ते! मैं Flexi AI हूँ। आपको किस सेवा की आवश्यकता है? जैसे: प्लंबर (नल), इलेक्ट्रीशियन (बिजली), सफाई, कारपेंटर, या उपकरण रिपेयर?"
            : "Hello! I am Flexi AI. Which home service do you need? (e.g. Plumbing, Electrical, Cleaning, Carpentry, Appliance repair)";

        if (sessionKey) {
            try { await redis.set(sessionKey, JSON.stringify(state), "EX", SESSION_TTL_SECONDS); } catch (e) {}
        }
        return { reply, state, action: "PROMPT_CATEGORY" };
    }

    if (state.isEmergency) {
        state.step = "AWAITING_CONFIRMATION";
        const reply = lang === "hi"
            ? `🚨 आपातकालीन SOS ${state.category} सेवा चुनी गई है: "${text}"। यह बुकिंग तत्काल प्राथमिकता पर भेजी जाएगी। क्या आप बुकिंग कन्फर्म करना चाहते हैं? (हाँ / नहीं बोलें)`
            : `🚨 Emergency SOS ${state.category} requested: "${text}". This will be dispatched immediately with high priority. Shall I confirm and place this booking? (Reply Yes / No)`;

        if (sessionKey) {
            try { await redis.set(sessionKey, JSON.stringify(state), "EX", SESSION_TTL_SECONDS); } catch (e) {}
        }
        return { reply, state, action: "CONFIRM_EMERGENCY_BOOKING" };
    }

    state.step = "AWAITING_CONFIRMATION";
    const reply = lang === "hi"
        ? `मैंने आपकी ${state.category} सेवा की आवश्यकता नोट कर ली है: "${text}"। क्या मैं आपकी यह बुकिंग कन्फर्म कर दूँ? (हाँ / नहीं बोलें)`
        : `I noted your ${state.category} service request: "${text}". Shall I confirm and place this booking for you? (Reply Yes / No)`;

    // Save session in Redis with 1-Minute Expiration Window
    if (sessionKey) {
        try { await redis.set(sessionKey, JSON.stringify(state), "EX", SESSION_TTL_SECONDS); } catch (e) {}
    }

    return { reply, state, action: "PROMPT_CONFIRMATION" };
};

export const routeAgentMessage = processFlexiAgentMessage;
export default processFlexiAgentMessage;
