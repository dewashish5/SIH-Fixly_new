# Flexi AI Live Orchestration Design

Date: 2026-09-10  
Status: Approved (Approach A + §1 + 3-dot wave loader)

## Goal

Low-latency voice + text Flexi AI with load-split models, app-locale languages, Siri-like glow UI, and live-mode chrome hiding.

## Models

| Role | Model |
|------|--------|
| Voice I/O | `gemini-3.1-flash-live-preview` (device ↔ Google WS) |
| Brain / tools | Gemini Flash (`GEMINI_MODEL`) |
| Chat text / bubbles | Groq `openai/gpt-oss-120b` |
| Auth | Backend ephemeral Live token |

## Language

- App locales only: `en hi ta te kn bn mr gu pa`
- Start from app locale; `en`/`hi` allow Hinglish
- In-session language switch allowed

## UI

- Entry: glow corners (Siri-like)
- Live voice ON: hide typing bar / dictation chrome; show transcript only
- Thinking: 3-dot smooth wave loader in assistant bubble

## Live UX

- Fillers: hmm / um / hn / ok while listening (Live system prompt)
- Sudden human-like replies via Live audio
- Tool/booking → backend Flash brain → result back into Live

## Out of scope

- Video input
- Proactive audio / affective dialogue (not on 3.1 Live yet)
