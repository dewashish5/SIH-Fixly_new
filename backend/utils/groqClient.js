// backend/utils/groqClient.js
import { Groq } from 'groq-sdk';

import Settings from '../models/Settings.js';

let groqClientInstance = null;
let currentKey = null;

async function getGroqClient() {
  const settings = await Settings.findOne({});
  const dbKey = settings?.apiKeys?.groqApiKey;
  const key = dbKey || process.env.GROQ_API_KEY || 'dummy_groq_key_placeholder';
  
  if (!groqClientInstance || key !== currentKey) {
    groqClientInstance = new Groq({ apiKey: key });
    currentKey = key;
  }
  return { client: groqClientInstance, key };
}

async function classifyIssueWithGroq(text) {
  const { client, key } = await getGroqClient();
  if (!key || key === 'dummy_groq_key_placeholder') {
    return 'General';
  }
  const chatCompletion = await client.chat.completions.create({
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

export { getGroqClient, classifyIssueWithGroq };