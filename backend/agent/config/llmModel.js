import dotenv from "dotenv";
dotenv.config();
import { GoogleGenerativeAI } from "@google/generative-ai";
import Groq from "groq-sdk";

const geminiKey = process.env.GEMINI_API_KEY || process.env.GOOGLE_API_KEY || "";
const groqKey = process.env.GROQ_API_KEY || "";

const geminiModelName = process.env.GEMINI_MODEL || "gemini-2.5-flash";
const groqModelName = process.env.GROQ_MODEL || "openai/gpt-oss-120b";

const genAI = geminiKey ? new GoogleGenerativeAI(geminiKey) : null;
const groqClient = groqKey ? new Groq({ apiKey: groqKey }) : null;

export const isGeminiAvailable = () => Boolean(geminiKey && geminiKey.length > 5);
export const isGroqAvailable = () => Boolean(groqKey && groqKey.length > 5);

export const llm = {
    invoke: async (prompt, options = {}) => {
        let lastError = null;

        // 1. Try Gemini first (if configured)
        if (genAI && isGeminiAvailable()) {
            try {
                const model = genAI.getGenerativeModel({
                    model: geminiModelName,
                    generationConfig: {
                        temperature: options.temperature !== undefined ? options.temperature : 0.1,
                    }
                });

                const timeoutPromise = new Promise((_, reject) =>
                    setTimeout(() => reject(new Error(`Timeout on Gemini ${geminiModelName}`)), 8000)
                );

                const result = await Promise.race([model.generateContent(prompt), timeoutPromise]);
                return {
                    content: result.response.text(),
                    model: geminiModelName,
                    provider: "gemini"
                };
            } catch (err) {
                lastError = err;
                console.warn(`[LLM] Gemini (${geminiModelName}) failed: ${err.message.slice(0, 120)}. Trying Groq fallback...`);
            }
        }

        // 2. Try Groq fallback
        if (groqClient && isGroqAvailable()) {
            try {
                const chatCompletion = await groqClient.chat.completions.create({
                    messages: [
                        { role: "user", content: typeof prompt === "string" ? prompt : JSON.stringify(prompt) }
                    ],
                    model: groqModelName,
                    temperature: options.temperature !== undefined ? options.temperature : 0.1,
                });

                const content = chatCompletion.choices[0]?.message?.content || "";
                return {
                    content,
                    model: groqModelName,
                    provider: "groq"
                };
            } catch (err) {
                lastError = err;
                console.warn(`[LLM] Groq (${groqModelName}) failed: ${err.message.slice(0, 120)}`);
            }
        }

        // If both failed or not configured, throw error
        throw lastError || new Error("No LLM provider available or configured.");
    }
};

export default llm;
