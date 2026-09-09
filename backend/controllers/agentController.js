import { processFlexiAgentMessage } from '../agent/flexiAgent.js';
import { fail, ok } from '../utils/http.js';
import { aiLogger } from '../utils/aiLogger.js';

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

        // 1. Structured log for Customer Request
        aiLogger.logTurnStart({
            userId,
            message,
            language: normalizedLanguage,
            coordinates,
            addressLine,
            conversationState
        });

        const io = req.app.get('io');
        const result = await processFlexiAgentMessage({
            userId,
            message,
            conversationState: conversationState || {},
            coordinates,
            addressLine,
            explicitLanguage: normalizedLanguage,
            io
        });

        const responsePayload = {
            success: true,
            reply: result.reply,
            state: result.state,
            action: result.action,
            booking: result.booking || null,
            bookings: result.bookings || null,
            workers: result.workers || null,
            estimate: result.estimate || null,
            policy: result.policy || null,
            suggestedReplies: result.suggestedReplies || [],
        };

        // 2. Structured log for AI Agent Reply
        aiLogger.logTurnEnd({
            action: result.action,
            reply: result.reply,
            state: result.state,
            booking: result.booking,
            suggestedReplies: result.suggestedReplies
        });

        return ok(res, responsePayload);
    } catch (error) {
        aiLogger.logTurnEnd({
            action: 'ERROR',
            reply: 'Internal Server Error',
            state: {},
            error: error.message
        });
        return fail(res, 500, 'INTERNAL_ERROR', error.message);
    }
};
