// backend/utils/groqClient.js
import { Groq } from 'groq-sdk';

const apiKey = process.env.GROQ_API_KEY || 'dummy_groq_key_placeholder';
const groqClient = new Groq({ apiKey });

async function classifyIssueWithGroq(text) {
  if (!process.env.GROQ_API_KEY) {
    return 'General';
  }
  const chatCompletion = await groqClient.chat.completions.create({
    messages: [
      {
        role: "system",
        content: "You are a home service classifier. Classify the issue into: Electrical, Plumbing, Cleaning, HVAC, Carpentry, Painting, or General. Return only the category name."
      },
      {
        role: "user",
        content: text
      }
    ],
    model: "llama3-8b-8192",
    temperature: 0.1,
    max_tokens: 10
  });

  return chatCompletion.choices[0].message.content.trim();
}

export { groqClient, classifyIssueWithGroq };