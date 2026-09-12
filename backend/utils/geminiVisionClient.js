// backend/utils/geminiVisionClient.js
import { ChatGoogleGenerativeAI } from "@langchain/google-genai";
import Settings from '../models/Settings.js';

/**
 * Get the active Gemini API key — checks Settings DB first, falls back to .env
 */
async function getGeminiApiKey() {
    try {
        const settings = await Settings.findOne({});
        const dbKey = settings?.apiKeys?.geminiApiKey;
        return (dbKey && dbKey.length > 5) ? dbKey : (process.env.GEMINI_API_KEY || '');
    } catch {
        return process.env.GEMINI_API_KEY || '';
    }
}

/**
 * Check if Gemini Vision is properly configured
 */
export async function isGeminiVisionConfigured() {
    const key = await getGeminiApiKey();
    return Boolean(key && key.length > 5 && key !== "dummy_key_for_unconfigured_gemini");
}

/**
 * Analyze an image to detect service category and extract relevant information
 * @param {Buffer} imageBuffer - The image buffer to analyze
 * @returns {Promise<Object>} Analysis results including category and description
 */
export async function analyzeImageWithGemini(imageBuffer) {
    try {
        const apiKey = await getGeminiApiKey();
        if (!apiKey || apiKey.length <= 5) {
            return {
                category: "General",
                description: "Unable to analyze image - Gemini API not configured",
                confidence: 0.1
            };
        }

        const model = new ChatGoogleGenerativeAI({
            model: process.env.GEMINI_VISION_MODEL || "gemini-1.5-pro-latest",
            apiKey,
            temperature: 0.1,
            maxRetries: 2,
        });

        const imageBase64 = imageBuffer.toString('base64');

        const message = [
            {
                role: "system",
                content: "You are a home service image analyzer. Analyze the provided image and determine what type of home service is needed. Look for signs of: electrical issues (wiring, outlets, switches, panels), plumbing issues (pipes, leaks, fixtures, drains), cleaning needs (dirty surfaces, trash, stains), HVAC issues (vents, units, filters), carpentry (wood damage, furniture, doors), painting (peeling paint, color needs), or general maintenance. Return your analysis in JSON format with: {category: \"Electrical|Plumbing|Cleaning|HVAC|Carpentry|Painting|General\", description: \"brief description of what you see in the image related to home services\", confidence: 0.0-1.0}"
            },
            {
                role: "user",
                content: [
                    { type: "text", text: "Analyze this image for home service needs:" },
                    { type: "image_url", image_url: { url: `data:image/jpeg;base64,${imageBase64}` } }
                ]
            }
        ];

        const result = await model.invoke(message);

        let analysis = {};
        try {
            const textResponse = result.content.toString();
            const jsonMatch = textResponse.match(/\{[\s\S]*\}/);
            if (jsonMatch) {
                analysis = JSON.parse(jsonMatch[0]);
            } else {
                analysis = { category: "General", description: textResponse.substring(0, 100), confidence: 0.5 };
            }
        } catch (parseError) {
            console.warn('Failed to parse Gemini vision response:', parseError);
            analysis = { category: "General", description: "Image analyzed but response parsing failed", confidence: 0.3 };
        }

        const validCategories = ['Electrical', 'Plumbing', 'Cleaning', 'HVAC', 'Carpentry', 'Painting', 'General'];
        if (!validCategories.includes(analysis.category)) {
            analysis.category = 'General';
        }
        analysis.confidence = Math.max(0, Math.min(1, analysis.confidence || 0.5));

        return analysis;
    } catch (error) {
        console.error('Error in Gemini vision analysis:', error);
        return {
            category: "General",
            description: `Error analyzing image: ${error.message}`,
            confidence: 0.1
        };
    }
}

/**
 * Extract text from an image URL using Gemini Vision
 * @param {string} url - URL of the image
 * @param {string} promptText - The prompt to use
 * @returns {Promise<string>} Extracted text
 */
export async function extractTextFromImageURL(url, promptText) {
    try {
        const apiKey = await getGeminiApiKey();
        if (!apiKey || apiKey.length <= 5) {
            return "Gemini API not configured";
        }

        const model = new ChatGoogleGenerativeAI({
            model: process.env.GEMINI_VISION_MODEL || "gemini-1.5-pro-latest",
            apiKey,
            temperature: 0.1,
            maxRetries: 2,
        });

        const response = await fetch(url);
        const arrayBuffer = await response.arrayBuffer();
        const buffer = Buffer.from(arrayBuffer);
        const imageBase64 = buffer.toString('base64');

        const message = [
            {
                role: "user",
                content: [
                    { type: "text", text: promptText },
                    { type: "image_url", image_url: { url: `data:image/jpeg;base64,${imageBase64}` } }
                ]
            }
        ];

        const result = await model.invoke(message);
        return result.content.toString();
    } catch (error) {
        console.error('Error extracting text from image:', error);
        return "";
    }
}
