// backend/utils/geminiVisionClient.js
import { ChatGoogleGenerativeAI } from "@langchain/google-genai";
import { readFile } from 'node:fs/promises';
import { join } from 'node:path';

/**
 * Gemini Vision client for image understanding
 * Uses Google's Gemini Pro Vision model to analyze images and extract service-related information
 */
const geminiKey = process.env.GEMINI_API_KEY || "dummy_key_for_unconfigured_gemini";

export const geminiVisionModel = new ChatGoogleGenerativeAI({
    model: process.env.GEMINI_VISION_MODEL || "gemini-1.5-pro-latest",
    apiKey: geminiKey,
    temperature: 0.1,
    maxRetries: 2,
});

/**
 * Analyze an image to detect service category and extract relevant information
 * @param {Buffer} imageBuffer - The image buffer to analyze
 * @returns {Promise<Object>} Analysis results including category and description
 */
export async function analyzeImageWithGemini(imageBuffer) {
    try {
        // Check if Gemini is properly configured
        if (!process.env.GEMINI_API_KEY || process.env.GEMINI_API_KEY.length <= 5) {
            // Return fallback analysis when Gemini is not configured
            return {
                category: "General",
                description: "Unable to analyze image - Gemini API not configured",
                confidence: 0.1
            };
        }

        // Convert buffer to base64 for Gemini
        const imageBase64 = imageBuffer.toString('base64');

        // Create a message with the image for Gemini to analyze
        const message = [
            {
                role: "system",
                content: "You are a home service image analyzer. Analyze the provided image and determine what type of home service is needed. Look for signs of: electrical issues (wiring, outlets, switches, panels), plumbing issues (pipes, leaks, fixtures, drains), cleaning needs (dirty surfaces, trash, stains), HVAC issues (vents, units, filters), carpentry (wood damage, furniture, doors), painting (peeling paint, color needs), or general maintenance. Return your analysis in JSON format with: {category: \"Electrical|Plumbing|Cleaning|HVAC|Carpentry|Painting|General\", description: \"brief description of what you see in the image related to home services\", confidence: 0.0-1.0}"
            },
            {
                role: "user",
                content: [
                    {
                        type: "text",
                        text: "Analyze this image for home service needs:"
                    },
                    {
                        type: "image_url",
                        image_url: {
                            url: `data:image/jpeg;base64,${imageBase64}`
                        }
                    }
                ]
            }
        ];

        // Call Gemini Vision model
        const result = await geminiVisionModel.invoke(message);

        // Parse the response to extract JSON
        let analysis = {};
        try {
            // Try to parse JSON from the response
            const textResponse = result.content.toString();
            // Extract JSON from response (handle cases where model might add extra text)
            const jsonMatch = textResponse.match(/\{[\s\S]*\}/);
            if (jsonMatch) {
                analysis = JSON.parse(jsonMatch[0]);
            } else {
                // Fallback if no JSON found
                analysis = {
                    category: "General",
                    description: textResponse.substring(0, 100),
                    confidence: 0.5
                };
            }
        } catch (parseError) {
            console.warn('Failed to parse Gemini vision response:', parseError);
            analysis = {
                category: "General",
                description: "Image analyzed but response parsing failed",
                confidence: 0.3
            };
        }

        // Validate category
        const validCategories = ['Electrical', 'Plumbing', 'Cleaning', 'HVAC', 'Carpentry', 'Painting', 'General'];
        if (!validCategories.includes(analysis.category)) {
            analysis.category = 'General';
        }

        // Ensure confidence is within bounds
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
 * Check if Gemini Vision is properly configured
 * @returns {boolean} True if configured, false otherwise
 */
export const isGeminiVisionConfigured = () => {
    return Boolean(
        process.env.GEMINI_API_KEY &&
        process.env.GEMINI_API_KEY.length > 5 &&
        process.env.GEMINI_API_KEY !== "dummy_key_for_unconfigured_gemini"
    );
};