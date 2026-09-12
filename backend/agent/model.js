import dotenv from "dotenv";
dotenv.config();
import { GoogleGenerativeAI } from "@google/generative-ai";

/**
 * Direct official Google Generative AI client
 * Ultra-fast, zero-overhead client for Gemini models.
 */
const geminiKey = process.env.GEMINI_API_KEY || "dummy_key_for_unconfigured_gemini";
const primaryModel = process.env.GEMINI_MODEL || "gemini-flash-lite-latest";
const candidateModels = Array.from(new Set([
    "gemini-flash-lite-latest",
    "gemini-3.1-flash-lite",
    primaryModel,
    "gemini-3.6-flash",
    "gemini-3.5-flash",
    "gemini-2.5-flash"
]));

const genAI = new GoogleGenerativeAI(geminiKey);

export const llm = {
    invoke: async (prompt) => {
        let lastError = null;
        for (const mName of candidateModels) {
            try {
                const model = genAI.getGenerativeModel({
                    model: mName,
                    generationConfig: {
                        temperature: 0.1,
                    }
                });
                const timeoutPromise = new Promise((_, reject) =>
                    setTimeout(() => reject(new Error(`Timeout on model ${mName}`)), 4000)
                );
                const result = await Promise.race([model.generateContent(prompt), timeoutPromise]);
                return {
                    content: result.response.text(),
                    model: mName
                };
            } catch (err) {
                lastError = err;
                console.warn(`[Gemini] Model ${mName} call failed (${err.message.slice(0, 100)}). Trying fallback model...`);
            }
        }
        throw lastError;
    }
};

export const isGeminiConfigured = () => {
    return Boolean(
        process.env.GEMINI_API_KEY &&
        process.env.GEMINI_API_KEY.length > 5 &&
        process.env.GEMINI_API_KEY !== "dummy_key_for_unconfigured_gemini"
    );
};

