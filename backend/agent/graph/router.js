import { llm } from "../config/llmModel.js";
import { FIXLY_SYSTEM_PROMPT } from "../prompts/agentPrompt.js";
import { detectCategoryFromKeywords } from "../services/workerService.js";

/**
 * Fast keyword detector for identity questions
 */
const isIdentityQuestion = (text = "") => {
    const lower = text.toLowerCase();
    return (
        lower.includes("who are you") ||
        lower.includes("what are you") ||
        lower.includes("who created you") ||
        lower.includes("who developed you") ||
        lower.includes("who made you") ||
        lower.includes("tum kaun ho") ||
        lower.includes("tumhe kisne banaya") ||
        lower.includes("kaun banaya") ||
        lower.includes("developer kaun")
    );
};

/**
 * Fast keyword detector for off-topic queries
 */
const isOffTopicQuery = (text = "") => {
    const lower = text.toLowerCase();
    return [
        "cricket", "ipl", "match score", "politics", "election", "modi", "rahul gandhi",
        "movie", "cinema", "bollywood", "song", "weather", "mausam", "recipe", "biryani",
        "chatgpt", "openai", "who is elon", "stock market", "bitcoin", "crypto"
    ].some(w => lower.includes(w));
};

/**
 * Fast keyword detector for status queries
 */
const isStatusQuery = (text = "") => {
    const lower = text.toLowerCase();
    if (lower.includes("confirm") || lower.includes("booking karo") || lower.includes("chahiye")) return false;
    return (
        lower.includes("status") ||
        lower.includes("track") ||
        lower.includes("kahan hai") ||
        lower.includes("meri booking") ||
        lower.includes("my booking") ||
        lower.includes("order status")
    );
};

/**
 * Fast keyword detector for cancellation
 */
const isCancelQuery = (text = "") => {
    const lower = text.toLowerCase();
    return ["cancel", "quit", "exit", "band karo", "nahi chahiye", "radd karo", "रद्द"].some(w => lower.includes(w));
};

/**
 * Fast keyword detector for reset
 */
const isResetQuery = (text = "") => {
    const lower = text.toLowerCase();
    return [
        "reset", "clear", "restart", "start over", "shuru se", "nayi booking",
        "another service", "dusri service", "koi aur service"
    ].some(w => lower.includes(w));
};

/**
 * Fast keyword detector for confirmation
 */
const isConfirmQuery = (text = "") => {
    const lower = text.toLowerCase().trim();
    // If message mentions a category or schedule keyword, it is a service request, not a confirmation
    if (detectCategoryFromKeywords(lower)) return false;
    if (lower.includes("select") || lower.includes("chuno") || /[0-9a-fA-F]{24}/.test(text)) return false;
    if (lower.includes("schedule") || lower.includes("tomorrow") || lower.includes("kal") || lower.includes("baje")) return false;

    const exactWords = ["yes", "haan", "ha", "हाँ", "thik hai", "theek hai", "ok", "proceed", "confirm", "kardo", "kar do"];
    if (exactWords.includes(lower)) return true;

    return [
        "confirm kardo", "kar do confirm", "yes confirm", "haan confirm",
        "booking confirm", "confirm booking", "haan kardo", "haan kar do", "book now"
    ].some(w => lower.includes(w));
};

/**
 * Router Node: Classifies intent and extracts slots using LLM with rule fallback
 */
export const agentRouter = async (state) => {
    const text = (state.prompt || "").trim();
    const lang = state.language || "en";

    // 1. Fast path checks
    if (isCancelQuery(text)) {
        return {
            ...state,
            intent: "CANCEL",
            action: "SESSION_ABORTED"
        };
    }

    if (isResetQuery(text)) {
        return {
            ...state,
            intent: "RESET",
            action: "RESET"
        };
    }

    if (isIdentityQuestion(text)) {
        return {
            ...state,
            intent: "IDENTITY_QUERY"
        };
    }

    if (isOffTopicQuery(text)) {
        return {
            ...state,
            intent: "OFF_TOPIC"
        };
    }

    if (isStatusQuery(text)) {
        return {
            ...state,
            intent: "STATUS_QUERY"
        };
    }

    // Check confirmation intent when in confirmation step
    if (state.step === "AWAITING_CONFIRMATION" && isConfirmQuery(text)) {
        return {
            ...state,
            intent: "CONFIRMATION"
        };
    }

    // 2. LLM Intent & Slot Extraction
    let extracted = {
        intent: "BOOKING_FLOW",
        category: state.category || detectCategoryFromKeywords(text),
        bookingType: state.bookingType || null,
        isEmergency: state.isEmergency || false,
        scheduledTime: state.scheduledTime || null,
        workerSelection: null,
        problemDescription: state.problemDescription || null,
        confirmation: false,
        reply: null
    };

    try {
        const promptContext = `${FIXLY_SYSTEM_PROMPT}

Current Slot State:
${JSON.stringify({
    category: state.category,
    bookingType: state.bookingType,
    isEmergency: state.isEmergency,
    scheduledTime: state.scheduledTime,
    step: state.step,
    workerName: state.workerName
})}

User Message: "${text}"
Target Language: ${lang}

Analyze the message and return ONLY the JSON object.`;

        const aiRes = await llm.invoke(promptContext);
        const cleaned = (aiRes.content || "").replace(/```json/gi, "").replace(/```/g, "").trim();
        const parsed = JSON.parse(cleaned);

        if (parsed.intent) extracted.intent = parsed.intent;
        if (parsed.category) extracted.category = parsed.category;
        if (parsed.bookingType) extracted.bookingType = parsed.bookingType;
        if (parsed.isEmergency !== undefined) extracted.isEmergency = Boolean(parsed.isEmergency);
        if (parsed.scheduledTime) extracted.scheduledTime = parsed.scheduledTime;
        if (parsed.workerSelection) extracted.workerSelection = parsed.workerSelection;
        if (parsed.problemDescription) extracted.problemDescription = parsed.problemDescription;
        if (parsed.confirmation !== undefined) extracted.confirmation = Boolean(parsed.confirmation);
        if (parsed.reply) extracted.reply = parsed.reply;
    } catch (err) {
        console.warn("[Router] LLM extraction fallback to rules:", err.message);
        const fastCategory = detectCategoryFromKeywords(text);
        if (fastCategory) extracted.category = fastCategory;
        const explicitFromKeywords = parseExplicitBookingType(text);
        if (explicitFromKeywords) {
            extracted.bookingType = explicitFromKeywords;
            extracted.isEmergency = explicitFromKeywords === "EMERGENCY_SOS";
        }
        if (isConfirmQuery(text)) {
            extracted.confirmation = true;
            if (state.step === "AWAITING_CONFIRMATION") extracted.intent = "CONFIRMATION";
        }
    }

    const explicitType = parseExplicitBookingType(text);
    const detectedCat = detectCategoryFromKeywords(text) || extracted.category;
    const isCategorySwitched = Boolean(detectedCat && state.category && detectedCat.toLowerCase() !== state.category.toLowerCase());

    const activeCategory = isCategorySwitched ? detectedCat : (detectedCat || state.category);
    const resolvedBookingType = isCategorySwitched ? explicitType : (state.bookingType || explicitType || (extracted.bookingType && explicitType ? extracted.bookingType : null));

    return {
        ...state,
        intent: extracted.intent,
        category: activeCategory,
        bookingType: resolvedBookingType,
        isEmergency: resolvedBookingType === "EMERGENCY_SOS" || (explicitType === "EMERGENCY_SOS"),
        scheduledTime: isCategorySwitched ? (extracted.scheduledTime || null) : (extracted.scheduledTime || state.scheduledTime),
        workerId: isCategorySwitched ? null : state.workerId,
        workerName: isCategorySwitched ? null : state.workerName,
        workerRate: isCategorySwitched ? null : state.workerRate,
        workerSelection: extracted.workerSelection,
        problemDescription: isCategorySwitched ? (extracted.problemDescription || text) : (extracted.problemDescription || state.problemDescription || text),
        confirmation: extracted.confirmation,
        llmReply: extracted.reply
    };
};

export const parseExplicitBookingType = (text = "") => {
    const lower = text.toLowerCase().trim();
    if (["sos", "emergency", "turant", "urgent", "jaldi", "आपातकालीन", "तत्काल", "danger"].some(w => lower.includes(w))) {
        return "EMERGENCY_SOS";
    }
    if (["schedule", "later", "baad me", "kal", "tomorrow", "shaam", "baje", "date", "time", "शेड्यूल", "बाद में", "समय"].some(w => lower.includes(w))) {
        return "SCHEDULED";
    }
    if (["standard", "normal", "regular", "सामान्य", "स्टैंडर्ड"].some(w => lower.includes(w))) {
        return "STANDARD";
    }
    return null;
};

export default agentRouter;
