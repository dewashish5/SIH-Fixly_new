import Booking from '../models/Booking.js';
import { groqClient } from '../utils/groqClient.js';
import { llm, isGeminiConfigured } from '../agent/model.js';

// Keywords that indicate customer/worker wants a human agent
const ESCALATION_TRIGGERS = [
    'talk to human',
    'human agent',
    'real person',
    'connect to agent',
    'representative',
    'talk to admin',
    'connect with agent',
    'speak to person',
    'human support',
    'executive',
    'customer care',
    'escalate',
    'fraud',
    'police',
    'complaint against worker',
    'complaint against customer',
    'insaan se baat',
    'agent se baat',
    'admin se baat',
    'insan se baat',
    'transfer to human',
];

const DEFAULT_CUSTOMER_SNIPPETS = [
    'Where is my technician?',
    'Cancel my booking',
    'Payment & refund issue',
    'Talk to human agent',
];

const DEFAULT_WORKER_SNIPPETS = [
    'When will I get my payout?',
    'Customer is not answering',
    'KYC verification status',
    'Talk to human agent',
];

/**
 * Check if the user text explicitly requests human escalation
 */
export const isEscalationRequested = (text = '') => {
    const lower = text.toLowerCase().trim();
    return ESCALATION_TRIGGERS.some(trigger => lower.includes(trigger));
};

/**
 * Fetch recent booking context for user to enrich AI knowledge
 */
const getUserContext = async (user) => {
    if (!user || !user._id) return null;
    try {
        const query = user.role === 'worker' ? { worker: user._id } : { customer: user._id };
        const latestBooking = await Booking.findOne(query)
            .sort({ createdAt: -1 })
            .select('bookingId status service category scheduledAt invoice address')
            .lean();
        return latestBooking;
    } catch (e) {
        return null;
    }
};

/**
 * Rule-based fallback generator when external LLMs are unavailable
 */
const getRuleBasedResponse = (text, userRole, recentBooking) => {
    const lower = text.toLowerCase();

    // Customer rules
    if (userRole === 'customer') {
        if (lower.includes('where') || lower.includes('track') || lower.includes('late') || lower.includes('reach')) {
            const bId = recentBooking?.bookingId || 'your active booking';
            const status = recentBooking?.status || 'SCHEDULED';
            return {
                reply: `For ${bId}, status is currently ${status}. You can see real-time technician movement on the live map by opening your Active Booking screen.`,
                quickReplies: ['View live tracking', 'Call technician', 'Need more help', 'Talk to human agent'],
                shouldEscalate: false,
            };
        }

        if (lower.includes('cancel') || lower.includes('refund')) {
            return {
                reply: 'You can cancel any booking before the technician arrives from the Booking Details page. Refunds for prepaid orders are credited back to your original payment method within 24–48 hours.',
                quickReplies: ['Check refund status', 'Cancellation policy', 'Talk to human agent'],
                shouldEscalate: false,
            };
        }

        if (lower.includes('pay') || lower.includes('bill') || lower.includes('charge') || lower.includes('invoice') || lower.includes('extra')) {
            return {
                reply: 'Fixly has standardized rates. Any extra spare parts added by the technician require your prior approval via OTP. If you notice any unauthorized charge, we will immediately review and refund.',
                quickReplies: ['Download invoice', 'Dispute a charge', 'Talk to human agent'],
                shouldEscalate: false,
            };
        }

        if (lower.includes('otp') || lower.includes('arrival')) {
            return {
                reply: 'Your 4-digit arrival OTP is shown on your active booking screen. Only share it when the technician arrives in person at your door.',
                quickReplies: ['Where is technician?', 'Reschedule service', 'Talk to human agent'],
                shouldEscalate: false,
            };
        }
    }

    // Worker rules
    if (userRole === 'worker') {
        if (lower.includes('payout') || lower.includes('wallet') || lower.includes('money') || lower.includes('balance') || lower.includes('earning')) {
            return {
                reply: 'Your earnings are automatically credited to your Fixly Wallet upon job completion. Daily payouts to your linked UPI/Bank account are processed at 8:00 PM every evening.',
                quickReplies: ['Check wallet balance', 'Withdraw money', 'Talk to human agent'],
                shouldEscalate: false,
            };
        }

        if (lower.includes('kyc') || lower.includes('document') || lower.includes('verify') || lower.includes('approval')) {
            return {
                reply: 'Aadhaar and Police verification documents are reviewed by our administration team within 2 to 4 hours. You will receive an SMS and app alert once approved.',
                quickReplies: ['Upload document', 'Check approval status', 'Talk to human agent'],
                shouldEscalate: false,
            };
        }

        if (lower.includes('customer') && (lower.includes('reach') || lower.includes('call') || lower.includes('cancel') || lower.includes('not answering'))) {
            return {
                reply: 'If the customer is unresponsive after 3 attempts or more than 15 minutes past scheduled time, you may cancel with reason "Customer Unreachable" without any rating penalty.',
                quickReplies: ['Cancel this order', 'Contact support desk', 'Talk to human agent'],
                shouldEscalate: false,
            };
        }
    }

    // General fallback
    return {
        reply: `Hello! I'm Fixly AI Support. I can help you with bookings, tracking, payments, invoices, or safety. How can I assist you today?`,
        quickReplies: userRole === 'worker' ? DEFAULT_WORKER_SNIPPETS : DEFAULT_CUSTOMER_SNIPPETS,
        shouldEscalate: false,
    };
};

/**
 * Process a support message using AI (Groq / Gemini) with seamless fallback
 */
export const processSupportMessageWithAI = async ({
    user,
    message,
    conversationHistory = [],
}) => {
    const text = (message || '').trim();
    const userRole = user?.role === 'worker' ? 'worker' : 'customer';

    // 1. Direct Escalation Check
    if (isEscalationRequested(text)) {
        return {
            reply: `I understand this needs personal attention. I have escalated this conversation to our Human Support Arbitration Desk. An admin agent has been notified and will take over this chat shortly.`,
            shouldEscalate: true,
            quickReplies: ['Check queue status', 'Add more information', 'Cancel request'],
        };
    }

    // 2. Fetch context (e.g. latest booking)
    const recentBooking = await getUserContext(user);

    // 3. Try Groq or Gemini LLM
    try {
        const systemPrompt = `You are Fixly AI Support Agent for the Fixly On-Demand Home Services platform.
User Role: ${userRole.toUpperCase()} (Name: ${user?.name || 'User'}).
Recent Booking Context: ${recentBooking ? JSON.stringify({
    bookingId: recentBooking.bookingId,
    status: recentBooking.status,
    service: recentBooking.service,
    address: recentBooking.address?.streetAddress,
}) : 'No recent booking found'}.

RULES:
1. Be concise, polite, helpful, and empathetic. Answer in 2-4 sentences.
2. If the user's issue cannot be resolved or is too complex/critical (e.g., severe dispute, legal, harassment, repeated failure), set "escalate": true.
3. Provide 3-4 suggested quick-reply snippets that the user can tap next. Always include "Talk to human agent" as the last snippet option.
4. You MUST reply ONLY in valid JSON matching this exact format:
{
  "reply": "Your response message here",
  "escalate": false,
  "quickReplies": ["Snippet 1", "Snippet 2", "Snippet 3", "Talk to human agent"]
}`;

        let aiOutput = null;

        // Try Groq first for blazing fast speed (< 400ms)
        if (process.env.GROQ_API_KEY && process.env.GROQ_API_KEY !== 'dummy_groq_key_placeholder') {
            const messages = [
                { role: 'system', content: systemPrompt },
                ...conversationHistory.slice(-6).map(m => ({
                    role: m.role === 'customer' || m.role === 'worker' ? 'user' : 'assistant',
                    content: m.body,
                })),
                { role: 'user', content: text }
            ];

            const completion = await groqClient.chat.completions.create({
                messages,
                model: 'llama-3.1-8b-instant',
                temperature: 0.3,
                max_tokens: 300,
                response_format: { type: 'json_object' }
            });

            aiOutput = completion.choices[0]?.message?.content;
        } else if (isGeminiConfigured()) {
            const prompt = `${systemPrompt}\nUser Message: ${text}`;
            const res = await llm.invoke(prompt);
            aiOutput = typeof res.content === 'string' ? res.content : JSON.stringify(res.content);
        }

        if (aiOutput) {
            try {
                // Parse JSON from output
                const cleanJson = aiOutput.replace(/```json/g, '').replace(/```/g, '').trim();
                const parsed = JSON.parse(cleanJson);
                if (parsed.reply) {
                    const snippets = Array.isArray(parsed.quickReplies) && parsed.quickReplies.length > 0
                        ? parsed.quickReplies
                        : (userRole === 'worker' ? DEFAULT_WORKER_SNIPPETS : DEFAULT_CUSTOMER_SNIPPETS);

                    // Ensure "Talk to human agent" is present
                    if (!snippets.some(s => s.toLowerCase().includes('human'))) {
                        snippets.push('Talk to human agent');
                    }

                    return {
                        reply: parsed.reply,
                        shouldEscalate: Boolean(parsed.escalate),
                        quickReplies: snippets.slice(0, 4),
                    };
                }
            } catch (err) {
                // Failed to parse JSON, use clean raw string
                return {
                    reply: aiOutput.replace(/[{}\"\']/g, '').trim(),
                    shouldEscalate: false,
                    quickReplies: userRole === 'worker' ? DEFAULT_WORKER_SNIPPETS : DEFAULT_CUSTOMER_SNIPPETS,
                };
            }
        }
    } catch (err) {
        console.warn('AI Support LLM failed, using intelligent fallback:', err.message);
    }

    // 4. Fallback if LLM wasn't available or failed
    return getRuleBasedResponse(text, userRole, recentBooking);
};

export const getDefaultQuickReplies = (role = 'customer') => {
    return role === 'worker' ? DEFAULT_WORKER_SNIPPETS : DEFAULT_CUSTOMER_SNIPPETS;
};
