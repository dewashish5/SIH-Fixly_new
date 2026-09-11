# How AI / ML Is Working (Fixly)

Step-by-step map of how AI/ML talks to the **backend**, what the **Flutter app** calls, and who touches **databases**.

> Short answer: Flutter almost never talks to Python ML or Gemini keys directly for business data. It calls the **Node backend**. Backend either (a) runs LLM logic itself, (b) proxies Python ML microservices, or (c) mints a short-lived token so Flutter can open a **direct WebSocket to Google Gemini Live** for voice only. Booking / users / services live in **MongoDB** (backend). Session chat state lives in **Redis**. Python demos often use **in-memory / mock data**, not Fixly Mongo.

---

## 1. Big picture

```
┌──────────────────┐
│  Flutter app     │
│  (customer AI,   │
│   support, KYC)  │
└────────┬─────────┘
         │ HTTPS JWT
         ▼
┌──────────────────┐         ┌─────────────────────────────┐
│  Node backend    │────────▶│  MongoDB (Bookings, Users,  │
│  :8000           │         │  Services, Reviews, …)      │
│  /api/ai/*       │         └─────────────────────────────┘
│  /api/ai/agent/* │
│  /api/support/*  │         ┌─────────────────────────────┐
│  /api/workers/*  │────────▶│  Redis (Flexi session +     │
└────────┬─────────┘         │  chat history TTL)          │
         │                   └─────────────────────────────┘
         │
         ├─▶ Groq API / Gemini API (cloud LLMs — no Fixly DB)
         │
         ├─▶ Python ML (local ports, optional)
         │     :8002 service discovery (sklearn)
         │     :8004 identity / KYC verify
         │     :8080 support chatbot demo (mock bookings)
         │     :8082 reliability demo (own store)
         │
         └─▶ Mint Gemini Live token
                    │
                    ▼ (Flutter only for voice path)
              Google Gemini Live WebSocket
```

---

## 2. Does Flutter connect to AI/ML directly?

| Path | Flutter → ? | Direct to Python ML? | Direct to Gemini/Groq? |
|------|-------------|----------------------|------------------------|
| Flexi **chat** booking | Backend `POST /api/ai/agent/chat` | No | No (backend calls LLMs) |
| Flexi **voice / Live** | Backend `POST /api/ai/agent/live-token` then **WS to Google** | No | **Yes — audio WS only** (token from backend) |
| Live tools / booking brain | Backend `POST /api/ai/agent/live-tool` | No | No |
| Analyze issue (text/photo) | Backend `POST /api/ai/analyze-issue` | No | No (backend → Groq / Gemini Vision) |
| Service discovery | Backend `POST /api/ai/service-discovery` | No (backend → `:8002`) | No |
| Match workers | Backend `POST /api/ai/match-workers` | No (Node + Mongo geo) | No |
| Support chat | Backend `/api/support/*` | No (Node LLM + Mongo) | No |
| Worker reliability (app) | Backend `GET /api/workers/:id/reliability` | No (Node counts Booking/Review) | No |
| KYC verify | Backend verification flow → `:8004` | No from Flutter | No |

**Only special case:** Gemini Live voice — Flutter holds an ephemeral token and opens `GeminiLiveService` WebSocket to Google. Booking tools still bounce back through backend (`live-tool` / agent chat).

Flutter client code: `frontend/lib/features/ai/data/ai_api_repository.dart`, `frontend/lib/services/gemini_live_service.dart`, `customer_ai_helper_page.dart`.

---

## 3. Step-by-step: Flexi AI chat (main booking assistant)

1. User types in AI Helper (Flutter).
2. Flutter `AiApiRepository.chatWithAgent(...)` →  
   `POST /api/ai/agent/chat` with JWT + `message`, `conversationState`, optional `coordinates` / `addressLine` / `language`.
3. `agentController.chatWithFlexiAgent` → `processFixlyAgentMessage` (`backend/agent/index.js`).
4. Agent loads prior turn from **Redis** (`getSessionState` / history).
5. **LangGraph** (`backend/agent/graph/graph.js`) routes intent (greeting, category, workers, confirm, off-topic, …).
6. Tools / services hit **MongoDB** via Mongoose:
   - `Service` — categories / price estimate (`estimateService.js`)
   - `User` — nearby workers (`workerService.js`)
   - `Booking` — create / list status (`bookingService.js`, graph nodes)
7. LLM replies: Gemini Flash and/or Groq (`backend/agent/model.js`, `config/llmModel.js`, `utils/groqClient.js`) — **cloud APIs**, not a local ML DB.
8. Session written back to Redis (TTL ~10 min). Cleared on `BOOKING_CREATED` / abort.
9. JSON reply → Flutter shows bubbles + rich cards (workers, estimate, booking).

**DB ownership:** Mongo is the source of truth for bookings/workers/services. Redis is ephemeral conversation state only. LLMs do not query Mongo themselves — Node tools do.

---

## 4. Step-by-step: Flexi Live voice (hybrid)

1. Flutter requests `POST /api/ai/agent/live-token` (auth required).
2. Backend `createGeminiLiveEphemeralToken` calls Google  
   `https://generativelanguage.googleapis.com/v1beta/auth_tokens` with `GEMINI_API_KEY`.
3. Flutter `GeminiLiveService.connect(websocketUrl, model, …)` — **device ↔ Google** for audio/transcripts.
4. When Live needs booking actions, Flutter/backend bridge:  
   `POST /api/ai/agent/live-tool` → same Flash/agent brain as chat (Mongo + Redis again).
5. Result fed back into Live / chat UI.

Voice model (config): `gemini-3.1-flash-live-preview` (`GEMINI_LIVE_MODEL`).  
Design notes: `docs/superpowers/specs/2026-09-10-flexi-ai-live-orchestration-design.md`.

---

## 5. Step-by-step: AI/ML Python services ↔ backend

Folder: `ai_ml/`. Start together: `cd ai_ml && python3 start_all.py`.

| Service | Port | Tech | Wired into Node? | Data store |
|---------|------|------|------------------|------------|
| Service Discovery | **8002** | FastAPI + sklearn `.pkl` | **Yes** — `aiController.serviceDiscovery` `fetch http://127.0.0.1:8002/discover` | Local pickles only; Node then maps categories → Mongo `Service` |
| Identity Verification | **8004** | FastAPI | **Yes** — `verificationController` `fetch …/verify` | No Fixly Mongo; scores written by Node onto `User.kycDocuments` |
| Support Chatbot (Python) | **8080** | http.server + rule engine | **Demo / parallel** — production app uses Node `aiSupportService` | **Mock** `MOCK_BOOKINGS` in Python, not Mongo |
| Worker Reliability (Python) | **8082** | ML joblib + HTTP demo | **Not used by app API** | Own `worker_store` / demo; app uses Node `computeReliability` on Mongo |
| Worker Matching (older README :8003) | — | FastAPI (if present) | App matching is **Node** `matchWorkers` + Mongo `$near` | Mongo workers |

### 5.1 Service discovery sequence

1. Flutter (or discovery UI) → `POST /api/ai/service-discovery` `{ text }`.
2. Backend tries Python `:8002/discover` (TF-IDF + classifier).
3. On success, backend loads active `Service` docs from Mongo and attaches `serviceId` / titles.
4. If Python down → Node keyword fallback over Mongo services.

Python has **no Mongo connection**. It only classifies text → category probabilities.

### 5.2 KYC / identity sequence

1. Worker uploads docs via backend.
2. Backend stores Cloudinary URLs on `User`, status `PROCESSING`.
3. Backend POSTs URLs to `:8004/verify`.
4. Scores returned → backend updates KYC fields / approve-reject / manual review in Mongo.

### 5.3 Python support chatbot vs app support

- **App path:** Flutter → `/api/support/*` → `aiSupportService.js` (Groq/Gemini + optional Mongo latest booking) → tickets in Mongo.
- **Python `:8080`:** standalone demo with FAQ/matcher + **mock bookings**; not the primary Flutter integration.

---

## 6. Other AI endpoints (backend-owned)

Mounted in `backend/server.js`:

- `app.use('/api/ai', aiRoutes)` → analyze-issue, service-discovery, match-workers, demand-forecast  
- `app.use('/api/ai/agent', agentRoutes)` → chat, live-token, live-tool  

### Analyze issue

1. Flutter multipart/text → `/api/ai/analyze-issue`.
2. Optional image → Cloudinary.
3. Image → Gemini Vision (`geminiVisionClient`); else text → Groq classify.
4. Suggested `Service` from Mongo by category.

### Match workers

1. Flutter/backend → `/api/ai/match-workers` with lat/lng.
2. `User.find` workers with geo + score (rating, online, jobs, verified).
3. **No Python call** in current controller.

### Reliability (app)

1. `GET /api/workers/:workerId/reliability`.
2. Node aggregates Mongo `Booking` + `Review` → score.  
   Python `:8082` is a separate ML demo.

---

## 7. Who accesses the database?

| Component | MongoDB | Redis | Own files / mock |
|-----------|---------|-------|------------------|
| Flutter | Never directly | Never | — |
| Flexi agent (Node) | Yes — Booking, User, Service | Yes — session/history | — |
| aiController (Node) | Yes — Service, User | — | — |
| aiSupportService (Node) | Yes — Booking (+ tickets elsewhere) | — | — |
| computeReliability (Node) | Yes — Booking, Review | — | — |
| verificationController | Yes — User KYC fields | — | — |
| Python discovery | No | No | `.pkl` models |
| Python KYC `:8004` | No | No | Vision/ML in process |
| Python support `:8080` | No | No | `MOCK_BOOKINGS`, KB JSON |
| Python reliability `:8082` | No | No | Local store / joblib |
| Groq / Gemini APIs | No | No | Vendor cloud |

**Rule:** Anything that creates or updates real bookings/users goes through **Node + Mongo**. Python ML is inference/scoring/classification; Node persists results.

---

## 8. API cheat sheet (Flutter → backend)

| Flutter / client | Backend route | Downstream |
|------------------|---------------|------------|
| `AiApiRepository.chatWithAgent` | `POST /api/ai/agent/chat` | LangGraph + Mongo + Redis + Groq/Gemini |
| `mintLiveToken` | `POST /api/ai/agent/live-token` | Google auth_tokens |
| `liveToolBridge` | `POST /api/ai/agent/live-tool` | Same agent brain |
| `analyzeIssue` | `POST /api/ai/analyze-issue` | Groq / Gemini Vision + Mongo Service |
| (discovery UI) | `POST /api/ai/service-discovery` | Python `:8002` + Mongo Service |
| (match UI) | `POST /api/ai/match-workers` | Mongo User geo |
| Support cubit | `/api/support/*` | Node LLM + Mongo |
| Reliability page | `GET /api/workers/:id/reliability` | Mongo aggregates |

Auth: `protect` middleware (JWT) on AI routes.

---

## 9. Env / keys (backend)

Typical (see `backend/.env`, never commit secrets):

- `GEMINI_API_KEY` / `GOOGLE_API_KEY` — Flash, Vision, Live tokens  
- `GEMINI_MODEL`, `GEMINI_LIVE_MODEL`  
- `GROQ_API_KEY`, `GROQ_MODEL`  
- Mongo / Redis connection strings  
- Optional admin-panel settings for keys (`apiKeys.geminiApiKey`, etc.)

Python services: no shared Mongo URI required for discovery/KYC/demo bots.

---

## 10. How to run locally (mental model)

1. Start **Mongo + Redis + Node** (`backend` → `:8000`).
2. Optionally start **Python AI** (`ai_ml/start_all.py`) so discovery (`:8002`) and KYC (`:8004`) work; otherwise Node falls back / marks KYC manual.
3. Start **Flutter**; point API base at backend.
4. Chat always works through backend if Groq/Gemini keys set.
5. Live voice needs Gemini key + working `live-token` + device mic.

---

## 11. Folder map

```
ai_ml/                          # Python microservices + demos
  service_discovery/            # :8002 sklearn discover
  identity_verification/        # :8004 KYC verify
  support_chatbot/              # :8080 demo (mock data)
  worker_Reliability_Score/     # :8082 demo ML score
  start_all.py

backend/
  routes/ai-routes.js
  routes/agent-routes.js
  controllers/aiController.js
  controllers/agentController.js
  controllers/verificationController.js
  services/aiSupportService.js
  agent/                        # Flexi LangGraph + tools
  utils/groqClient.js
  utils/geminiVisionClient.js
  utils/geminiLiveToken.js

frontend/lib/
  features/ai/data/ai_api_repository.dart
  services/gemini_live_service.dart
  features/customer/.../customer_ai_helper_page.dart
```

Related older notes (may be stale on Groq/Gemini — this doc wins):  
`AI_CAPABILITIES_SUMMARY.md`, `ai_ml/README.md`, `docs/superpowers/specs/2026-09-10-flexi-ai-live-orchestration-design.md`.

---

## 12. One-line summary

**AI/ML = (cloud LLMs + optional Python classifiers) behind the Node API; Flutter uses the API; only Gemini Live audio is direct device→Google; real DB writes always go Node→Mongo (Redis for chat session only).**
