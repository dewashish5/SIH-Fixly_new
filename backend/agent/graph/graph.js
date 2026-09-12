import { StateGraph } from "@langchain/langgraph";
import { agentState } from "./state.js";
import { agentRouter } from "./router.js";
import { getAvailableWorkers, matchWorkerChoice, validateCategoryAgainstDB } from "../services/workerService.js";
import { calculateEstimate } from "../services/estimateService.js";
import { generateAutoDescription, createBookingInDB } from "../services/bookingService.js";
import Booking from "../../models/Booking.js";

/**
 * Suggested chips helper
 */
const getSuggestedReplies = (action, state = {}, lang = "hi") => {
    const isHi = lang === "hi";
    switch (action) {
        case "PROMPT_CATEGORY":
        case "RESET":
            return isHi
                ? ["नल लीकेज (Plumbing)", "बिजली / स्विच (Electrical)", "घर की सफाई (Cleaning)", "एसी सर्विस (Appliance)"]
                : ["Plumbing repair", "Electrician / Wiring", "Deep home cleaning", "AC service"];
        case "PROMPT_BOOKING_TYPE":
            return isHi
                ? ["⚡ Emergency SOS (तुरंत)", "⏱️ Standard (सामान्य)", "📅 Schedule (आगे का समय)"]
                : ["⚡ Emergency SOS", "⏱️ Standard Booking", "📅 Schedule for Later"];
        case "PROMPT_WORKER_SELECTION":
            return isHi
                ? ["स्वतः निकटतम चुनें (Auto)", "पहला कार्यकर्ता चुनें", "रद्द करें"]
                : ["Auto-assign nearest", "Select first worker", "Cancel"];
        case "PROMPT_SCHEDULE_TIME":
            return isHi
                ? ["कल सुबह 10 बजे", "कल दोपहर 3 बजे", "आज शाम 6 बजे"]
                : ["Tomorrow 10:00 AM", "Tomorrow 3:00 PM", "Today 6:00 PM"];
        case "PROMPT_CONFIRMATION":
            return isHi
                ? ["हाँ, बुकिंग कन्फर्म करें", "रद्द करें"]
                : ["Yes, confirm booking", "Cancel"];
        case "BOOKING_CREATED":
            return isHi
                ? ["बुकिंग स्थिति देखें", "नई सेवा बुक करें"]
                : ["Track booking", "Book another service"];
        default:
            return isHi
                ? ["प्लंबर चाहिए", "इलेक्ट्रीशियन चाहिए", "बुकिंग स्टेटस"]
                : ["Need a plumber", "Need an electrician", "Track booking"];
    }
};

/**
 * Main Agent Handler Node
 */
export const fixlyAgentHandler = async (state) => {
    const text = (state.prompt || "").trim();
    const lang = state.language || "en";
    const isHi = lang === "hi";

    // 1. IDENTITY QUERY
    if (state.intent === "IDENTITY_QUERY") {
        const reply = isHi
            ? "नमस्ते! मैं Fixly AI Assistant हूँ, जिसे वैभव जैन (Vaibhav Jain) द्वारा Fixly Cooperative प्लेटफॉर्म के लिए विकसित किया गया है। मैं प्लंबिंग, बिजली, घर की सफाई, कारपेंटर आदि घरेलू सेवाओं की बुकिंग में आपकी सहायता करता हूँ।"
            : "Hello! I am Fixly AI Assistant, developed by Vaibhav Jain for Fixly Cooperative Gig Services. I help you book verified home professionals like Plumbers, Electricians, Cleaners, and Carpenters.";
        return {
            ...state,
            aiResponse: reply,
            action: "IDENTITY_INFO",
            suggestedReplies: getSuggestedReplies("IDENTITY_INFO", state, lang)
        };
    }

    // 2. OFF TOPIC GUARDRAIL
    if (state.intent === "OFF_TOPIC") {
        const reply = isHi
            ? "माफ़ कीजिए, मैं केवल Fixly सहकारी घरेलू सेवाओं (जैसे प्लंबिंग, बिजली, सफाई, कारपेंटर आदि) की बुकिंग के लिए प्रशिक्षित हूँ। अन्य विषयों पर मेरे पास डेटा नहीं है। कृपया अपनी घरेलू सेवा से संबंधित आवश्यकता बताइए।"
            : "I apologize, I am exclusively trained to assist with Fixly Cooperative home services (Plumbing, Electrical, Cleaning, Carpentry) and bookings. I do not have information on other topics. Please let me know which home service you require.";
        return {
            ...state,
            aiResponse: reply,
            action: "OFF_TOPIC_GUARD",
            suggestedReplies: getSuggestedReplies("PROMPT_CATEGORY", state, lang)
        };
    }

    // 3. CANCEL / EXIT
    if (state.intent === "CANCEL") {
        const reply = isHi
            ? "बुकिंग सत्र रद्द कर दिया गया है। कोई बुकिंग नहीं बनाई गई। जब भी आपको किसी सेवा की आवश्यकता हो, बेझिझक Fixly से कहें!"
            : "Booking session has been cancelled. No booking was created. Feel free to reach out anytime!";
        return {
            ...state,
            category: null,
            workerId: null,
            step: null,
            aiResponse: reply,
            action: "SESSION_ABORTED",
            suggestedReplies: getSuggestedReplies("PROMPT_CATEGORY", state, lang)
        };
    }

    // 4. RESET / START OVER
    if (state.intent === "RESET") {
        const reply = isHi
            ? "आइए नए सिरे से शुरू करते हैं! Fixly पर आपको किस घरेलू सेवा की आवश्यकता है? (जैसे: प्लंबिंग, बिजली, घर की सफाई, कारपेंटर आदि)"
            : "Let's start fresh! Which home service do you need? (e.g. Plumbing, Electrical, Cleaning, Carpentry)";
        return {
            ...state,
            category: null,
            workerId: null,
            workerName: null,
            bookingType: null,
            isEmergency: false,
            scheduledTime: null,
            problemDescription: null,
            estimate: null,
            policy: null,
            step: "AWAITING_CATEGORY",
            aiResponse: reply,
            action: "RESET",
            suggestedReplies: getSuggestedReplies("PROMPT_CATEGORY", state, lang)
        };
    }

    // 5. STATUS QUERY
    if (state.intent === "STATUS_QUERY") {
        try {
            const userBookings = await Booking.find({ customer: state.userId })
                .populate('service', 'title category')
                .populate('worker', 'name phone')
                .sort({ createdAt: -1 })
                .limit(3)
                .lean();

            if (!userBookings || userBookings.length === 0) {
                const reply = isHi
                    ? "आपकी कोई सक्रिय बुकिंग नहीं मिली। क्या आप कोई नई सेवा बुक करना चाहते हैं?"
                    : "No active bookings found for your account. Would you like to book a service?";
                return {
                    ...state,
                    aiResponse: reply,
                    action: "NO_BOOKINGS",
                    bookings: [],
                    suggestedReplies: getSuggestedReplies("PROMPT_CATEGORY", state, lang)
                };
            }

            const latest = userBookings[0];
            const workerInfo = latest.worker ? `${latest.worker.name} (${latest.worker.phone || ""})` : (isHi ? "कार्यकर्ता आवंटित हो रहा है" : "Assigning worker");
            const reply = isHi
                ? `आपकी हालिया बुकिंग #${latest.bookingId} (${latest.service?.title || latest.problemDescription || "Service"}) की स्थिति "${latest.status}" है। कार्यकर्ता: ${workerInfo}।`
                : `Your recent booking #${latest.bookingId} (${latest.service?.title || latest.problemDescription || "Service"}) is currently "${latest.status}". Assigned worker: ${workerInfo}.`;

            return {
                ...state,
                aiResponse: reply,
                action: "BOOKING_STATUS",
                bookings: userBookings,
                suggestedReplies: getSuggestedReplies("BOOKING_STATUS", state, lang)
            };
        } catch (e) {
            console.warn("[Graph] Status query error:", e.message);
        }
    }

    // 6. BOOKING FLOW & PROGRESSIVE SLOT FILLING
    let currentCategory = state.category;

    // STEP A: If Category is missing -> Prompt Category
    if (!currentCategory) {
        const reply = isHi
            ? "नमस्ते! मैं Fixly AI Assistant हूँ। आपको किस सेवा की आवश्यकता है? (जैसे: प्लंबिंग, बिजली/स्विच, घर की सफाई, कारपेंटर आदि)"
            : "Hello! I am Fixly AI Assistant. Which home service do you need? (e.g. Plumbing, Electrical, Cleaning, Carpentry)";
        return {
            ...state,
            step: "AWAITING_CATEGORY",
            aiResponse: reply,
            action: "PROMPT_CATEGORY",
            suggestedReplies: getSuggestedReplies("PROMPT_CATEGORY", state, lang)
        };
    }

    // STEP A2: Dynamic Database Validation (Ensure Category exists in DB Service catalog created by Admin)
    const categoryCheck = await validateCategoryAgainstDB(currentCategory);
    if (!categoryCheck.isValid) {
        const activeListStr = categoryCheck.availableCategories.join(", ");
        const reply = isHi
            ? `माफ़ कीजिए, वर्तमान में Fixly पर "${currentCategory}" सेवा उपलब्ध नहीं है। हमारी उपलब्ध सक्रिय सेवाएँ हैं: ${activeListStr}। कृपया इनमें से कोई सेवा चुनें।`
            : `I apologize, "${currentCategory}" service is currently not offered on Fixly. Our currently available services are: ${activeListStr}. Please choose from these services.`;
        return {
            ...state,
            category: null,
            step: "AWAITING_CATEGORY",
            aiResponse: reply,
            action: "CATEGORY_NOT_SUPPORTED",
            suggestedReplies: categoryCheck.availableCategories
        };
    }
    currentCategory = categoryCheck.matchedCategory;

    // STEP B: Fetch available workers immediately for this category
    const availableWorkers = await getAvailableWorkers({ category: currentCategory });

    if (!availableWorkers || availableWorkers.length === 0) {
        const reply = isHi
            ? `माफ़ कीजिए, वर्तमान में आपके क्षेत्र में ${currentCategory} के कोई कार्यकर्ता उपलब्ध नहीं हैं। क्या आप बाद के समय के लिए शेड्यूल करना चाहेंगे?`
            : `Sorry, no verified ${currentCategory} workers are currently available in your area. Would you like to schedule for later?`;
        return {
            ...state,
            category: currentCategory,
            workers: [],
            step: "NO_WORKERS",
            aiResponse: reply,
            action: "NO_WORKERS_AVAILABLE",
            suggestedReplies: ["📅 Schedule for Later", "Try another service", "Cancel"]
        };
    }

    // STEP C: Check Booking Type (STANDARD vs EMERGENCY_SOS vs SCHEDULED)
    let currentBookingType = state.bookingType;

    if (!currentBookingType) {
        const reply = isHi
            ? `मैंने आपकी ${currentCategory} सेवा की आवश्यकता नोट कर ली है। हमारे पास आपके क्षेत्र में ${availableWorkers.length} सत्यापित कार्यकर्ता उपलब्ध हैं!\nआप इसे कैसे बुक करना चाहते हैं?\n• ⚡ Emergency SOS (तत्काल 15-30 मिनट में)\n• ⏱️ Standard (सामान्य सेवा)\n• 📅 Schedule (आगे के समय के लिए)`
            : `Noted your ${currentCategory} request! Found ${availableWorkers.length} verified cooperative workers near you.\nHow would you like to book?\n• ⚡ Emergency SOS (Instant priority)\n• ⏱️ Standard (Regular service)\n• 📅 Schedule for Later`;
        return {
            ...state,
            category: currentCategory,
            workers: availableWorkers,
            step: "AWAITING_BOOKING_TYPE",
            aiResponse: reply,
            action: "PROMPT_BOOKING_TYPE",
            suggestedReplies: getSuggestedReplies("PROMPT_BOOKING_TYPE", state, lang)
        };
    }

    // STEP D1: If EMERGENCY SOS -> Fast Path!
    if (currentBookingType === "EMERGENCY_SOS" || state.isEmergency) {
        const assignedWorker = availableWorkers[0]; // Nearest worker auto-assigned
        const autoDesc = await generateAutoDescription({
            category: currentCategory,
            promptText: state.problemDescription || text,
            isEmergency: true
        });

        const { estimate, policy } = await calculateEstimate({
            category: currentCategory,
            workerRate: assignedWorker?.hourlyRate,
            isEmergency: true,
            lang
        });

        // Check if user confirmed or proceed to prompt confirmation
        if (state.intent === "CONFIRMATION" || state.confirmation) {
            const newBooking = await createBookingInDB({
                userId: state.userId,
                category: currentCategory,
                bookingType: "EMERGENCY_SOS",
                isEmergency: true,
                scheduledTime: null,
                workerId: assignedWorker?._id,
                problemDescription: autoDesc,
                addressLine: state.addressLine,
                coordinates: state.coordinates,
                estimate
            });

            const reply = isHi
                ? `⚡ आपातकालीन SOS बुकिंग #${newBooking.bookingId} दर्ज कर ली गई है! निकटतम कार्यकर्ता ${assignedWorker?.name} को तुरंत रवाना किया गया है। कुल राशि: ₹${estimate.totalAmount}।`
                : `⚡ Emergency SOS booking #${newBooking.bookingId} confirmed! Nearest worker ${assignedWorker?.name} has been dispatched immediately. Total amount: ₹${estimate.totalAmount}.`;

            return {
                ...state,
                category: currentCategory,
                bookingType: "EMERGENCY_SOS",
                isEmergency: true,
                workerId: assignedWorker?._id,
                workerName: assignedWorker?.name,
                problemDescription: autoDesc,
                estimate,
                policy,
                booking: newBooking,
                step: "COMPLETED",
                aiResponse: reply,
                action: "BOOKING_CREATED",
                suggestedReplies: getSuggestedReplies("BOOKING_CREATED", state, lang)
            };
        }

        // Prompt SOS Confirmation
        const reply = isHi
            ? `⚡ आपातकालीन सेवा तैयार है:\n• कार्यकर्ता: ${assignedWorker?.name} (${assignedWorker?.rating}★, ${assignedWorker?.distanceKm} किमी दूर)\n• अनुमानित लागत: ₹${estimate.totalAmount} (₹50 आपातकालीन शुल्क शामिल, ₹0 प्लेटफार्म शुल्क)\n• कार्य विवरण: "${autoDesc}"\n\nक्या मैं तुरंत कार्यकर्ता को रवाना करने के लिए बुकिंग कन्फर्म कर दूँ? (हाँ / नहीं बोलें)`
            : `⚡ Emergency SOS Dispatch Ready:\n• Worker: ${assignedWorker?.name} (${assignedWorker?.rating}★, ${assignedWorker?.distanceKm} km away)\n• Total Amount: ₹${estimate.totalAmount} (Includes ₹50 emergency fee, ₹0 platform fee)\n• Task: "${autoDesc}"\n\nShall I confirm immediate dispatch? (Reply Yes / No)`;

        return {
            ...state,
            category: currentCategory,
            bookingType: "EMERGENCY_SOS",
            isEmergency: true,
            workerId: assignedWorker?._id,
            workerName: assignedWorker?.name,
            workers: availableWorkers,
            problemDescription: autoDesc,
            estimate,
            policy,
            step: "AWAITING_CONFIRMATION",
            aiResponse: reply,
            action: "PROMPT_CONFIRMATION",
            suggestedReplies: getSuggestedReplies("PROMPT_CONFIRMATION", state, lang)
        };
    }

    // STEP D2: If SCHEDULED -> Ensure Date and Time is filled!
    if (currentBookingType === "SCHEDULED") {
        if (!state.scheduledTime) {
            // Check if user provided time in message
            const hasTime = ["कल", "आज", "सुबह", "दोपहर", "शाम", "बजे", "tomorrow", "today", "morning", "afternoon", "evening", "am", "pm"].some(w => text.toLowerCase().includes(w));
            if (hasTime && text.length >= 3) {
                state.scheduledTime = text;
            } else {
                const reply = isHi
                    ? `कृपया बताइए आप किस दिन और समय पर सेवा चाहते हैं? (जैसे: "कल सुबह 10 बजे" या "आज शाम 5 बजे")`
                    : `Please specify your preferred date and time (e.g. "Tomorrow 10:00 AM" or "Today 5:00 PM"):`;
                return {
                    ...state,
                    category: currentCategory,
                    bookingType: "SCHEDULED",
                    workers: availableWorkers,
                    step: "AWAITING_SCHEDULE_TIME",
                    aiResponse: reply,
                    action: "PROMPT_SCHEDULE_TIME",
                    suggestedReplies: getSuggestedReplies("PROMPT_SCHEDULE_TIME", state, lang)
                };
            }
        }
    }

    // STEP D3: Worker Selection (For Standard or Scheduled)
    let selectedWorkerId = state.workerId;
    let selectedWorkerName = state.workerName;
    let selectedWorkerRate = state.workerRate;

    if (!selectedWorkerId && !state.isAutoAssign) {
        const choice = matchWorkerChoice(text, availableWorkers);
        if (choice) {
            if (choice.isAuto) {
                state.isAutoAssign = true;
                selectedWorkerId = choice.worker?._id || availableWorkers[0]?._id;
                selectedWorkerName = isHi ? "निकटतम कार्यकर्ता (स्वतः आवंटित)" : "Auto-Assigned Nearest Worker";
                selectedWorkerRate = choice.worker?.hourlyRate || availableWorkers[0]?.hourlyRate;
            } else if (choice.worker) {
                selectedWorkerId = choice.worker._id;
                selectedWorkerName = choice.worker.name;
                selectedWorkerRate = choice.worker.hourlyRate;
            }
        } else {
            // Worker not chosen yet -> Prompt Worker Selection with worker cards in data.workers
            const reply = isHi
                ? `आपके क्षेत्र में ${availableWorkers.length} सत्यापित ${currentCategory} कार्यकर्ता ऑनलाइन उपलब्ध हैं। आप नीचे दी गई सूची से कार्यकर्ता चुन सकते हैं या "स्वतः असाइन करें" कह सकते हैं:`
                : `Found ${availableWorkers.length} verified ${currentCategory} cooperative workers near you. Please choose a worker from the list below or reply "Auto-assign":`;
            return {
                ...state,
                category: currentCategory,
                bookingType: currentBookingType,
                workers: availableWorkers,
                step: "AWAITING_WORKER_SELECTION",
                aiResponse: reply,
                action: "PROMPT_WORKER_SELECTION",
                suggestedReplies: getSuggestedReplies("PROMPT_WORKER_SELECTION", state, lang)
            };
        }
    }

    // STEP E: Calculate Estimate & Policy
    const { estimate, policy } = await calculateEstimate({
        category: currentCategory,
        workerRate: selectedWorkerRate,
        isEmergency: false,
        lang
    });

    // STEP F: Check Confirmation Intent -> Create Booking in DB!
    if (state.step === "AWAITING_CONFIRMATION" && (state.intent === "CONFIRMATION" || state.confirmation)) {
        const newBooking = await createBookingInDB({
            userId: state.userId,
            category: currentCategory,
            bookingType: currentBookingType,
            isEmergency: false,
            scheduledTime: state.scheduledTime,
            workerId: selectedWorkerId,
            problemDescription: state.problemDescription || `${currentCategory} service via Fixly AI`,
            addressLine: state.addressLine,
            coordinates: state.coordinates,
            estimate
        });

        const reply = isHi
            ? `🎉 बधाई हो! आपकी ${currentCategory} सेवा की बुकिंग #${newBooking.bookingId} सफलतापूर्वक दर्ज कर ली गई है। कुल अनुमानित शुल्क: ₹${estimate.totalAmount}। आवंटित कार्यकर्ता: ${selectedWorkerName || "Fixly Worker"}।`
            : `🎉 Congratulations! Your ${currentCategory} booking #${newBooking.bookingId} has been confirmed. Total estimated fee: ₹${estimate.totalAmount}. Assigned worker: ${selectedWorkerName || "Fixly Worker"}.`;

        return {
            ...state,
            category: currentCategory,
            bookingType: currentBookingType,
            workerId: selectedWorkerId,
            workerName: selectedWorkerName,
            estimate,
            policy,
            booking: newBooking,
            step: "COMPLETED",
            aiResponse: reply,
            action: "BOOKING_CREATED",
            suggestedReplies: getSuggestedReplies("BOOKING_CREATED", state, lang)
        };
    }

    // STEP G: Prompt Confirmation with Summary & Fair Wage Policy
    const scheduleLine = state.scheduledTime ? (isHi ? `\n• समय: ${state.scheduledTime}` : `\n• Scheduled: ${state.scheduledTime}`) : "";
    const reply = isHi
        ? `लागत अनुमान तैयार है:\n• आधार शुल्क: ₹${estimate.baseServiceFee}\n• प्लेटफॉर्म शुल्क: ₹0 (Fixly सहकारी मॉडल)\n• कुल राशि: ₹${estimate.totalAmount}${scheduleLine}\n🛡️ Fixly निष्पक्ष मजदूरी: 100% राशि सीधे कार्यकर्ता को दी जाती है।\nकार्यकर्ता: ${selectedWorkerName || "चयनित कार्यकर्ता"}।\n\nक्या मैं आपकी यह बुकिंग कन्फर्म कर दूँ? (हाँ / नहीं बोलें)`
        : `Here is your price estimate:\n• Base Service Fee: ₹${estimate.baseServiceFee}\n• Platform Fee: ₹0 (Fixly Cooperative)\n• Total Amount: ₹${estimate.totalAmount}${scheduleLine}\n🛡️ Fixly Fair Wage Guarantee: 100% payout directly to worker.\nWorker: ${selectedWorkerName || "Selected Worker"}.\n\nShall I confirm and place this booking for you? (Reply Yes / No)`;

    return {
        ...state,
        category: currentCategory,
        bookingType: currentBookingType,
        workerId: selectedWorkerId,
        workerName: selectedWorkerName,
        workerRate: selectedWorkerRate,
        workers: availableWorkers,
        estimate,
        policy,
        step: "AWAITING_CONFIRMATION",
        aiResponse: reply,
        action: "PROMPT_CONFIRMATION",
        suggestedReplies: getSuggestedReplies("PROMPT_CONFIRMATION", state, lang)
    };
};

// Build StateGraph
const workflow = new StateGraph(agentState);

workflow.addNode("router", agentRouter);
workflow.addNode("handler", fixlyAgentHandler);

workflow.addEdge("__start__", "router");
workflow.addEdge("router", "handler");
workflow.addEdge("handler", "__end__");

export const graph = workflow.compile();
export default graph;
