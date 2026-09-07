import dotenv from "dotenv";
dotenv.config();
import { ChatGoogleGenerativeAI } from "@langchain/google-genai";

/**
 * Clean, direct LangChain Google Generative AI client
 * Configured exactly as requested.
 */
export const llm = new ChatGoogleGenerativeAI({
    model: process.env.GEMINI_MODEL || "gemini-2.5-flash",
    apiKey: process.env.GEMINI_API_KEY,
    temperature: 0,
    maxRetries: 2,
});

export const isGeminiConfigured = () => {
    return Boolean(process.env.GEMINI_API_KEY && process.env.GEMINI_API_KEY.length > 5);
};
