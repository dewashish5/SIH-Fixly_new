import { processFlexiAgentMessage } from '../agent/flexiAgent.js';
import { fail, ok } from '../utils/http.js';

export const chatWithFlexiAgent = async (req, res) => {
    // #swagger.tags = ['AI Agent']
    // #swagger.description = 'Interact with Hey Flexi Conversational AI voice/text booking assistant'
    try {
        const { message, conversationState, coordinates, addressLine, language, lang } = req.body;
        if (!message) {
            return fail(res, 400, 'VALIDATION_ERROR', 'Message is required');
        }

        const userId = req.user?.id;
        const chosenLanguage = String(language || lang || req.user?.preferredLanguage || 'en').toLowerCase().trim();
        const normalizedLanguage = (chosenLanguage === 'hi' || chosenLanguage === 'hindi') ? 'hi' : 'en';

        const result = await processFlexiAgentMessage({
            userId,
            message,
            conversationState: conversationState || {},
            coordinates,
            addressLine,
            explicitLanguage: normalizedLanguage,
        });

        return ok(res, {
            success: true,
            reply: result.reply,
            state: result.state,
            action: result.action,
            booking: result.booking || null,
            bookings: result.bookings || null,
            suggestedReplies: result.suggestedReplies || [],
        });
    } catch (error) {
        console.error('Flexi Agent Error:', error);
        return fail(res, 500, 'INTERNAL_ERROR', error.message);
    }
};
