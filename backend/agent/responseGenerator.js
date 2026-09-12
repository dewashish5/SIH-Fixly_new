import { llm } from './model.js';
import { isGeminiConfigured } from './model.js';

/**
 * Generate a natural language response using the LLM based on the action and state.
 * Falls back to hardcoded responses if LLM is not configured or fails.
 */
export const generateResponse = async (action, state, lang, extraData = {}) => {
  // If Gemini is not configured, we'll fall back to hardcoded responses in the caller
  if (!isGeminiConfigured()) {
    return null; // Indicates fallback to hardcoded
  }

  try {
    // Prepare the prompt for the LLM
    const prompt = `
You are Flexi AI, a helpful home service booking assistant.
Generate a natural, conversational response in ${lang === 'hi' ? 'Hindi' : 'English'} based on the current action and state.

Action: ${action}
Current State: ${JSON.stringify(state)}
Additional Data: ${JSON.stringify(extraData)}

Guidelines:
- Respond in ${lang === 'hi' ? 'Hindi' : 'English'} only.
- Be helpful, polite, and concise.
- Match the tone of the action (e.g., emergency should be urgent, confirmation should be friendly).
- Do not include any JSON or structured data in your response, just plain text.
- If the action requires asking a question, make it clear and easy to answer.
- If the action is providing information, present it clearly.
- If the action is an error or warning, be apologetic and helpful.

Generate the response now:
`;

    const result = await llm.invoke(prompt);
    const response = (result.content || "").trim();
    return response;
  } catch (error) {
    console.error('Error generating response with LLM:', error);
    return null; // Fallback to hardcoded
  }
};

/**
 * Fallback hardcoded responses for when LLM is not available or fails.
 * These are the original responses from the code.
 */
export const getFallbackResponse = (action, state, lang, extraData = {}) => {
  const isHindi = lang === 'hi';

  switch (action) {
    case 'SESSION_EXPIRED':
      return isHindi
        ? "समय समाप्त हो गया (सत्र समाप्त)। आपका पिछला सत्र 1 मिनट से अधिक निष्क्रिय रहने के कारण रीसेट कर दिया गया है। कृपया दोबारा बताएं कि आपको क्या सेवा चाहिए।"
        : "Session timed out due to 1 minute of inactivity. The previous attempt was reset. Please tell me which service you need to start fresh.";

    case 'SESSION_ABORTED':
      return isHindi
        ? "बुकिंग सत्र रद्द कर दिया गया है और कोई बुकिंग दर्ज नहीं की गई। जब भी आपको किसी सेवा की आवश्यकता हो, बेझिझक Flexi से कहें!"
        : "Booking session has been cancelled. No booking was created. Feel free to reach out anytime!";

    case 'OFF_TOPIC_GUARD':
      return isHindi
        ? "माफ़ कीजिए, मैं केवल Fixly Cooperative Gig Services (प्लंबिंग, इलेक्ट्रीशियन, कारपेंटर, सफाई आदि) और आपकी सेवा बुकिंग्स में सहायता के लिए बना हूँ। आप अपनी घरेलू सेवा संबंधी आवश्यकता बताइए।"
        : "I apologize, I am exclusively trained to assist with Fixly Cooperative Gig Services (such as Plumbing, Electrical, Cleaning, Carpentry) and bookings. Please let me know what home service you need.";

    case 'NO_BOOKINGS':
      return isHindi
        ? "आपकी अभी कोई सक्रिय बुकिंग नहीं है। क्या आप कोई नई सेवा बुक करना चाहते हैं?"
        : "You have no active bookings right now. Would you like to book a service?";

    case 'BOOKING_STATUS': {
      const { bookings } = extraData;
      if (!bookings || bookings.length === 0) {
        return isHindi
          ? "आपकी अभी कोई सक्रिय बुकिंग नहीं है। क्या आप कोई नई सेवा बुक करना चाहते हैं?"
          : "You have no active bookings right now. Would you like to book a service?";
      }
      const latest = bookings[0];
      const statusMapHi = {
        PENDING: "पुष्टि की प्रतीक्षा में",
        ACCEPTED: "कार्यकर्ता द्वारा स्वीकृत",
        APPROVED: "स्वीकृत",
        ARRIVED: "कार्यकर्ता आपके स्थान पर पहुँच गए हैं",
        IN_PROGRESS: "काम प्रगति पर है",
        COMPLETED: "काम पूरा हो गया है"
      };
      const statusDisplay = isHindi ? (statusMapHi[latest.status] || latest.status) : latest.status;
      const workerInfo = latest.worker ? `${latest.worker.name} (${latest.worker.phone || ""})` : (isHindi ? "कार्यकर्ता आवंटित हो रहा है" : "Assigning worker");
      return isHindi
        ? `आपकी हालिया बुकिंग #${latest.bookingId} (${latest.service?.title || "Service"}) की स्थिति "${statusDisplay}" है। आवंटित कार्यकर्ता: ${workerInfo}。`
        : `Your recent booking #${latest.bookingId} for ${latest.service?.title || "Service"} is currently "${statusDisplay}". Assigned worker: ${workerInfo}.`;
    }

    case 'MISSING_DETAILS':
      return isHindi
        ? "कुछ आवश्यक जानकारी अधूरी है। कृपया अपनी सेवा और पता दोबारा बताएं।"
        : "Required booking details are incomplete. Please provide service and address.";

    case 'PROMPT_CATEGORY':
      return isHindi
        ? "नमस्ते! मैं Flexi AI हूँ। आपको किस सेवा की आवश्यकता है? जैसे: प्लंबर (नल), इलेक्ट्रीशियन (बिजली), सफाई, कारपेंटर, या उपकरण रिपेयर?"
        : "Hello! I am Flexi AI. Which home service do you need? (e.g. Plumbing, Electrical, Cleaning, Carpentry, Appliance repair)";

    case 'CONFIRM_EMERGENCY_BOOKING':
      return isHindi
        ? `🚨 आपातकालीन SOS ${state.category} सेवा चुनी गई है: "${state.problemDescription}"। यह बुकिंग तत्काल प्राथमिकता पर भेजी जाएगी। क्या आप बुकिंग कन्फर्म करना चाहते हैं? (हाँ / नहीं बोलें)`
        : `🚨 Emergency SOS ${state.category} requested: "${state.problemDescription}". This will be dispatched immediately with high priority. Shall I confirm and place this booking? (Reply Yes / No)`;

    case 'PROMPT_CONFIRMATION':
      return isHindi
        ? `मैंने आपकी ${state.category} 서비스 की आवश्यकता नोट कर ली है: "${state.problemDescription}"। क्या मैं आपकी यह बुकिंग कन्फर्म कर दूँ? (हाँ / नहीं बोलें)`
        : `I noted your ${state.category} service request: "${state.problemDescription}". Shall I confirm and place this booking for you? (Reply Yes / No)`;

    case 'BOOKING_CREATED':
      const { booking } = extraData;
      return isHindi
        ? `🎉 बधाई हो! आपकी ${state.category} सेवा की बुकिंग #${booking.bookingId} सफलतापूर्वक दर्ज कर ली गई है। निकटतम प्रमाणित कार्यकर्ताओं को सूचित किया जा रहा है।`
        : `🎉 Congratulations! Your ${state.category} booking #${booking.bookingId} has been confirmed. Notifying verified cooperative workers.`;

    default:
      // Fallback to a generic response
      return isHindi
        ? "माफ़ कीजिए, मैं समझ नहीं पाया। कृपया दोहराएं।"
        : "Sorry, I didn't understand. Please repeat.";
  }
};