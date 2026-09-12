import redis from "../../config/redis.js";

const DEFAULT_SESSION_TTL = 1800; // 30 minutes

/**
 * Get recent message history for a conversation/user
 */
export const getMemory = async (conversationId) => {
    if (!conversationId) return [];
    try {
        const key = `fixly:history:${conversationId}`;
        const raw = await redis.get(key);
        if (raw) {
            return JSON.parse(raw);
        }
        return [];
    } catch (error) {
        console.warn("[Memory] Error getting memory:", error.message);
        return [];
    }
};

/**
 * Append a turn to conversation memory (capped at 20 turns)
 */
export const addMemoryMessage = async (conversationId, role, content) => {
    if (!conversationId || !content) return;
    try {
        const key = `fixly:history:${conversationId}`;
        const history = await getMemory(conversationId);
        history.push({ role, content, timestamp: new Date().toISOString() });
        if (history.length > 20) {
            history.shift();
        }
        await redis.set(key, JSON.stringify(history), "EX", DEFAULT_SESSION_TTL);
    } catch (error) {
        console.warn("[Memory] Error adding message:", error.message);
    }
};

/**
 * Get the active conversational slot-filling state
 */
export const getSessionState = async (conversationId) => {
    if (!conversationId) return null;
    try {
        const key = `fixly:session:${conversationId}`;
        const raw = await redis.get(key);
        if (raw) {
            return JSON.parse(raw);
        }
        return null;
    } catch (error) {
        console.warn("[Memory] Error getting session state:", error.message);
        return null;
    }
};

/**
 * Save active conversational slot-filling state
 */
export const saveSessionState = async (conversationId, state, ttl = DEFAULT_SESSION_TTL) => {
    if (!conversationId || !state) return;
    try {
        const key = `fixly:session:${conversationId}`;
        await redis.set(key, JSON.stringify(state), "EX", ttl);
    } catch (error) {
        console.warn("[Memory] Error saving session state:", error.message);
    }
};

/**
 * Clear conversation session and history
 */
export const clearSession = async (conversationId) => {
    if (!conversationId) return;
    try {
        await redis.del(`fixly:session:${conversationId}`);
        await redis.del(`fixly:history:${conversationId}`);
    } catch (error) {
        console.warn("[Memory] Error clearing session:", error.message);
    }
};

export default {
    getMemory,
    addMemoryMessage,
    getSessionState,
    saveSessionState,
    clearSession
};
