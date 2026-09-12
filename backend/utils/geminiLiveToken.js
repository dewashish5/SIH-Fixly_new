/**
 * Mint Gemini Live ephemeral tokens (REST).
 * Locked to gemini-3.1-flash-live-preview + AUDIO for client WebSocket sessions.
 */
export const LIVE_MODEL = process.env.GEMINI_LIVE_MODEL || 'gemini-3.1-flash-live-preview';

export async function createGeminiLiveEphemeralToken({
  language = 'en',
  expireMinutes = 30,
} = {}) {
  const apiKey = process.env.GEMINI_API_KEY || process.env.GOOGLE_API_KEY || '';
  if (!apiKey || apiKey.length < 8) {
    throw new Error('GEMINI_API_KEY not configured');
  }

  const now = Date.now();
  const expireTime = new Date(now + expireMinutes * 60 * 1000).toISOString();
  const newSessionExpireTime = new Date(now + 2 * 60 * 1000).toISOString();

  const systemInstruction = buildLiveSystemInstruction(language);

  const body = {
    uses: 1,
    expireTime,
    newSessionExpireTime,
    liveConnectConstraints: {
      model: `models/${LIVE_MODEL}`,
      config: {
        sessionResumption: {},
        responseModalities: ['AUDIO'],
        systemInstruction: {
          parts: [{ text: systemInstruction }],
        },
        speechConfig: {
          voiceConfig: {
            prebuiltVoiceConfig: { voiceName: 'Aoede' },
          },
        },
      },
    },
  };

  const res = await fetch(
    'https://generativelanguage.googleapis.com/v1beta/auth_tokens',
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': apiKey,
      },
      body: JSON.stringify(body),
    },
  );

  if (!res.ok) {
    const errText = await res.text();
    throw new Error(`Live token failed (${res.status}): ${errText.slice(0, 300)}`);
  }

  const data = await res.json();
  const token = data.name || data.token || data.authToken?.name;
  if (!token) {
    throw new Error('Live token response missing name');
  }

  return {
    token,
    model: LIVE_MODEL,
    expireTime,
    websocketUrl:
      `wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContentConstrained?access_token=${encodeURIComponent(token)}`,
  };
}

function buildLiveSystemInstruction(language) {
  const lang = String(language || 'en').toLowerCase();
  const hinglishHint =
    lang === 'hi' || lang === 'en'
      ? 'Prefer natural Hinglish when it helps clarity (mix Hindi+English casually).'
      : `Speak primarily in locale "${lang}". Keep Fixly service words clear.`;

  return [
    'You are Flexi AI, Fixly home-services voice assistant.',
    'Be warm, human, concise. Lowest latency.',
    'While user is talking or you need a beat: briefly acknowledge with short fillers like "hmm", "haan", "ok", "um" — then answer.',
    hinglishHint,
    'Never invent bookings. For booking/search/status/price use the call_fixly_brain tool, then speak the result naturally.',
    'Do not sound robotic. Prefer short spoken sentences.',
  ].join(' ');
}

export default createGeminiLiveEphemeralToken;
