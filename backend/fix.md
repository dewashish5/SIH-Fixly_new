# 🛠️ Fix & Integration Guide: Cooperative Gig Services Platform

This document provides a comprehensive record of all backend upgrades made to fulfill the **SIH Problem Statement** ("Cooperative Gig Services Platform for Household & Community Services"), along with exact step-by-step integration guides for both the **Mobile App (Flutter)** and the **Admin Panel (Web)**.

---

## 📑 Table of Contents
1. [Summary of Backend Architectural Changes](#1-summary-of-backend-architectural-changes)
2. [Mobile Application (Flutter) Integration Guide](#2-mobile-application-flutter-integration-guide)
   - [A. "Hey Flexi" Conversational AI Voice/Text Agent](#a-hey-flexi-conversational-ai-voicetext-agent)
   - [B. Emergency SOS & On-Demand Service Booking](#b-emergency-sos--on-demand-service-booking)
   - [C. Customer Booking Scheduling System](#c-customer-booking-scheduling-system)
   - [D. Multilingual Catalog & Localization](#d-multilingual-catalog--localization)
   - [E. Worker Wallet Withdrawal & Real-Time Payout Updates](#e-worker-wallet-withdrawal--real-time-payout-updates)
   - [F. Worker Cooperative Society Membership Card](#f-worker-cooperative-society-membership-card)
3. [Admin Panel (Web) Integration Guide](#3-admin-panel-web-integration-guide)
   - [A. Primary Cooperative Societies Management](#a-primary-cooperative-societies-management)
   - [B. Assigning Workers to Cooperative Societies](#b-assigning-workers-to-cooperative-societies)
   - [C. Federation Fair Wage Floors & Emergency Surcharges](#c-federation-fair-wage-floors--emergency-surcharges)
   - [D. Worker Payout Settlement & Instant Wallet Debit](#d-worker-payout-settlement--instant-wallet-debit)
   - [E. Multilingual Service Catalog (English & Hindi)](#e-multilingual-service-catalog-english--hindi)
4. [Backend Changes Reference (Files Modified & Created)](#4-backend-changes-reference)
5. [API Endpoint Reference Sheet](#5-api-endpoint-reference-sheet)

---

## 1. Summary of Backend Architectural Changes

| Area | What Was Fixed / Added | Impact |
|---|---|---|
| **Cooperative Hierarchy** | Created `CooperativeSociety` model. Extended `Cooperative` (Federation) with minimum wage floors. Mapped `User.workerProfile.society` and `societyMemberId`. | True multi-tier cooperative governance: State Federation ➡️ Primary Societies ➡️ Local Workers. |
| **Booking & Scheduling** | Added `scheduledTime`, `timeSlot`, `bookingType` (`STANDARD`, `SCHEDULED`, `EMERGENCY_SOS`), and `isEmergency` flag to `Booking` schema. | Customers can schedule future bookings (today, tomorrow, custom slots) or trigger immediate emergency SOS dispatches. |
| **Geo-Location Matching** | Fixed `eligibleWorkers.js` logic to verify worker `category`, `categories` array, and `skills` array against the target `serviceCategory`. | Eliminates matching bugs; all qualified tradesmen (e.g. plumbers, electricians) within radius receive relevant job requests. |
| **Welfare Fund Sync** | Connected payment settlement to `WelfareAccount` and `WelfareTransaction` in `paymentController.js`. | 5% welfare deductions are now properly credited to the worker's cooperative welfare balance instead of vanishing. |
| **Worker Wallet Settlement** | `adminUpdatePayoutStatus` now automatically deducts the worker's wallet balance on `status: 'paid'`, logs a `DEBIT` transaction, and triggers push notifications. | Complete accounting closure for worker withdrawals. |
| **Multilingual Catalog** | Added `titleI18n`, `categoryI18n`, `descriptionI18n`, `whatsIncludedI18n` to `Service` model. Added `utils/i18nHelper.js` to return localized content. | Dynamic Hindi and English service displays across mobile endpoints. |
| **"Hey Flexi" AI Agent** | Built a pure Node.js conversational StateGraph agent (`agent/flexiAgent.js`) with routes (`/api/ai/agent/chat`). | Voice/text Siri-style booking creation, category auto-detection, emergency vs scheduled handling, and active booking inquiries. |
| **Redis Cache Consistency** | Verified and ensured all admin category/service mutations invalidate and update `app:services:categories` and `app:home:dashboard`. | Zero lag between admin changes and mobile UI screens. |

---

## 2. Mobile Application (Flutter) Integration Guide

### A. "Hey Flexi" Conversational AI Voice/Text Agent

#### Endpoint:
`POST /api/ai/agent/chat` (Auth: `Bearer <JWT_TOKEN>`)

#### Request Headers:
```http
Authorization: Bearer <CUSTOMER_JWT_ACCESS_TOKEN>
Content-Type: application/json
```

#### Request Payload:
```json
{
  "message": "mujhe ek plumber chahiye nal leak ho raha hai",
  "conversationState": {},
  "coordinates": [77.2090, 28.6139],
  "addressLine": "Flat 402, Green Valley Apartments, Delhi",
  "language": "hi"
}
```
*Note: `language` can be `'hi'` or `'en'`. If omitted, agent automatically detects Hindi/English from user's voice transcript or profile.*

#### Response Structure (Standard Turn):
```json
{
  "success": true,
  "reply": "मैंने आपकी Plumbing सेवा की आवश्यकता नोट कर ली है: \"mujhe ek plumber chahiye nal leak ho raha hai\"। क्या मैं आपकी यह बुकिंग कन्फर्म कर दूँ? (हाँ / नहीं बोलें)",
  "state": {
    "language": "hi",
    "category": "Plumbing",
    "problemDescription": "mujhe ek plumber chahiye nal leak ho raha hai",
    "step": "AWAITING_CONFIRMATION"
  },
  "action": "PROMPT_CONFIRMATION",
  "booking": null,
  "bookings": null
}
```

#### Response Structure on Explicit Confirmation (`action: "BOOKING_CREATED"`):
```json
{
  "success": true,
  "reply": "🎉 बधाई हो! आपकी Plumbing सेवा की बुकिंग #BK-260907-00827D129 सफलतापूर्वक दर्ज कर ली गई है। निकटतम प्रमाणित कार्यकर्ताओं को सूचित किया जा रहा है।",
  "state": {
    "language": "hi",
    "category": "Plumbing",
    "problemDescription": "नल से पानी टपक रहा है",
    "step": "COMPLETED"
  },
  "action": "BOOKING_CREATED",
  "booking": {
    "_id": "66dc...",
    "bookingId": "BK-260907-00827D129",
    "customer": "64f1bc000000000000000001",
    "service": "64f1bc000000000000000002",
    "bookingType": "STANDARD",
    "isEmergency": false,
    "status": "PENDING",
    "invoice": {
      "baseServiceFee": 350,
      "platformFee": 0,
      "urgentFee": 0,
      "totalAmount": 350,
      "paymentStatus": "PENDING"
    }
  },
  "bookings": null
}
```

#### Response Structure on Inactivity Expiration (`action: "SESSION_EXPIRED"`):
```json
{
  "success": true,
  "reply": "समय समाप्त हो गया (सत्र समाप्त)। आपका पिछला सत्र 1 मिनट से अधिक निष्क्रिय रहने के कारण रीसेट कर दिया गया है। कृपया दोबारा बताएं कि आपको क्या सेवा चाहिए।",
  "state": {
    "language": "hi",
    "step": "AWAITING_CATEGORY"
  },
  "action": "SESSION_EXPIRED",
  "booking": null,
  "bookings": null
}
```

#### Response Structure on Explicit Cancellation (`action: "SESSION_ABORTED"`):
```json
{
  "success": true,
  "reply": "बुकिंग सत्र रद्द कर दिया गया है और कोई बुकिंग दर्ज नहीं की गई। जब भी आपको किसी सेवा की आवश्यकता हो, बेझिझक Flexi से कहें!",
  "state": {
    "language": "hi",
    "step": null
  },
  "action": "SESSION_ABORTED",
  "booking": null,
  "bookings": null
}
```

#### Response Structure on Booking Status Query (`action: "BOOKING_STATUS"`):
```json
{
  "success": true,
  "reply": "आपकी हालिया बुकिंग #BK-260907-00827D129 (Plumbing Service) की स्थिति \"पुष्टि की प्रतीक्षा में\" है। आवंटित कार्यकर्ता: कार्यकर्ता आवंटित हो रहा है।",
  "state": { "language": "hi" },
  "action": "BOOKING_STATUS",
  "booking": null,
  "bookings": [
    {
      "_id": "66dc...",
      "bookingId": "BK-260907-00827D129",
      "status": "PENDING",
      "service": { "title": "Plumbing Service", "category": "Plumbing" },
      "worker": null
    }
  ]
}
```

#### Flutter UI Flow:
1. **Floating Mic / "Hey Flexi" Button**:
   - User taps mic ➡️ STT (Speech-to-Text) converts voice to text.
   - App plays `reply` text back to user using Flutter TTS (`flutter_tts`).
2. **State Management Across Turns**:
   - Save the returned `state` in memory during the conversation.
   - Pass `conversationState: state` in the next message request.
3. **Session Handling**:
   - If `action == "SESSION_EXPIRED"`, clear state from Flutter memory and let user speak a fresh request.
   - If `action == "SESSION_ABORTED"`, close the voice dialog/modal.
4. **Booking Placed**:
   - When `action == "BOOKING_CREATED"`, navigate user directly to the Live Tracking screen using `booking.bookingId` or `booking._id`.

---

### B. Emergency SOS & On-Demand Service Booking

#### Booking Estimate Endpoint:
`POST /api/bookings/estimate`
```json
{
  "serviceId": "64f1bc000000000000000002",
  "estimatedHours": 1,
  "isEmergency": true,
  "bookingType": "EMERGENCY_SOS"
}
```
*Response includes `urgentFee: 50` or 20% surcharge, with `isEmergency: true`.*

#### Create Booking Endpoint:
`POST /api/bookings`
```json
{
  "serviceId": "64f1bc000000000000000002",
  "addressLine": "House 12, Main Market, Noida",
  "coordinates": [77.3910, 28.5355],
  "problemDescription": "Main water supply pipe burst, water overflowing",
  "bookingType": "EMERGENCY_SOS",
  "isEmergency": true,
  "timeSlot": "Immediate (SOS Emergency)"
}
```

#### Socket.io Events for Worker App:
- Listen to event: `emergency:booking_requested`
- Payload:
```json
{
  "bookingId": "66db...",
  "booking": { ... },
  "coordinates": [77.3910, 28.5355],
  "category": "Plumbing",
  "urgentFee": 50
}
```
*Show a Red Pulsing "EMERGENCY JOB - SOS" badge with a distinctive alert sound on the worker app.*

---

### C. Customer Booking Scheduling System

#### Create Scheduled Booking:
`POST /api/bookings`
```json
{
  "serviceId": "64f1bc000000000000000002",
  "addressLine": "Plot 88, Sector 14, Gurugram",
  "coordinates": [77.0266, 28.4595],
  "problemDescription": "AC seasonal servicing required",
  "bookingType": "SCHEDULED",
  "scheduledTime": "2026-09-09T10:30:00.000Z",
  "timeSlot": "10:00 AM - 12:00 PM"
}
```

---

### D. Multilingual Catalog & Localization

#### How to request localized content:
Send the language via:
1. Header: `Accept-Language: hi` or `Accept-Language: en`
2. Query param: `?lang=hi` or `?lang=en`
3. User profile: `preferredLanguage: 'hi'`

#### Endpoints supporting auto-localization:
- `GET /api/home/data?lang=hi`
- `GET /api/home/categories?lang=hi`
- `GET /api/services?lang=hi`
- `GET /api/services/search?query=plumber&lang=hi`

*Each service object contains `displayTitle`, `displayCategory`, `displayDescription`, and `displayWhatsIncluded` populated according to the selected language.*

---

### E. Worker Wallet Withdrawal & Real-Time Payout Updates

#### Worker Requests Withdrawal:
`POST /api/worker/me/withdraw`
```json
{
  "amount": 500
}
```

#### Push Notification Received on Settlement:
- Event: `PAYOUT_PAID`
- Title: *"पेआउट भेजा गया"* / *"Payout sent"*
- Body: *"आपकी निकासी का भुगतान हो गया।"* / *"Your withdrawal was paid."*

---

### F. Worker Cooperative Society Membership Card

#### Endpoint:
`GET /api/cooperative/my-society` (or `GET /api/worker/me/membership`)

#### Response Structure:
```json
{
  "success": true,
  "data": {
    "member": true,
    "verified": true,
    "societyMemberId": "MEM-NOI-8492",
    "society": {
      "_id": "66dc...",
      "name": "Noida Labour Contract Cooperative Society Ltd.",
      "registrationNumber": "COOP-UP-2024-88",
      "district": "Gautam Buddha Nagar",
      "state": "Uttar Pradesh",
      "wardOrArea": "Sector 18 - Sector 62 Zone",
      "contactPhone": "+91 9876543210",
      "presidentName": "Ramesh Kumar Sharma",
      "fairWageComplianceScore": 98
    },
    "federation": {
      "name": "Fixly Cooperative Federation",
      "federationName": "National Labour Cooperative Federation",
      "registrationNumber": "FED-COOP-2026-001",
      "fairWagePolicy": "Cooperative Minimum Fair Wage Guarantee Policy v1.0",
      "minimumWageFloor": {
        "plumbing": 350,
        "electrical": 400,
        "carpentry": 400,
        "cleaning": 250
      },
      "welfareContributionRate": 0.05,
      "insuranceEnabled": true
    }
  }
}
```
*Display this in the Worker Profile screen as a digital "Cooperative Member ID Card" with Federation & Society verification badges.*

---

## 3. Admin Panel (Web) Integration Guide

### A. Primary Cooperative Societies Management

#### 1. List All Societies:
`GET /api/admin/cooperative/societies?state=Uttar Pradesh&district=Gautam Buddha Nagar`

#### 2. Create Primary Society:
`POST /api/admin/cooperative/societies`
```json
{
  "name": "South Delhi Technicians Cooperative Society",
  "registrationNumber": "SOC-DL-2026-104",
  "state": "Delhi",
  "district": "South Delhi",
  "wardOrArea": "Saket, Malviya Nagar & Hauz Khas",
  "officeAddress": "Community Centre, Malviya Nagar, New Delhi",
  "contactPhone": "+91 11 2685 4321",
  "presidentName": "Harish Chandra Verma",
  "secretaryName": "Suresh Pal"
}
```

#### 3. View Society Details & Members:
`GET /api/admin/cooperative/societies/:id`
*Returns society details, complete affiliated workers list, and member count.*

#### 4. Update Society Details:
`PUT /api/admin/cooperative/societies/:id`
```json
{
  "contactPhone": "+91 9811223344",
  "fairWageComplianceScore": 100
}
```

---

### B. Assigning Workers to Cooperative Societies

`POST /api/admin/cooperative/assign-worker`
```json
{
  "workerId": "66db10000000000000000001",
  "societyId": "66dc20000000000000000002",
  "societyMemberId": "MEM-SD-2026-0042"
}
```
*Assigns the worker to the society, increments `activeMembersCount`, and updates the worker's profile.*

---

### C. Federation Fair Wage Floors & Emergency Surcharges

`PUT /api/admin/cooperative`
```json
{
  "federationName": "National Labour Cooperative Federation of India",
  "commissionRate": 0.05,
  "welfareContributionRate": 0.05,
  "emergencySurchargePercent": 20,
  "minimumWageFloor": {
    "electrical": 450,
    "plumbing": 400,
    "carpentry": 400,
    "cleaning": 300,
    "painting": 400,
    "appliance": 450,
    "gardening": 300,
    "default": 350
  }
  "emergencySurchargeFixed": 50
}
```

> [!IMPORTANT]
> **Zero-Fee Support**: If the Admin sets `customerPlatformFee: 0` or `workerCommissionPercent: 0`, the system cleanly evaluates to `0` without falling back to any default. Changes are immediately synced to Redis cache key `app:platform:settings`.

---

### E. Worker Payout Settlement & Instant Wallet Debit

`PATCH /api/admin/worker-payouts/:id/status`
```json
{
  "status": "paid",
  "note": "Bank IMPS Reference: UTR9988223311"
}
```
*Immediately settles the payout, deducts the amount from `worker.workerProfile.walletBalance`, writes a `DEBIT` transaction, and sends a push notification to the worker.*

---

### F. Multilingual Service Catalog (English & Hindi)

`POST /api/admin/services` or `PUT /api/admin/services/:id`
```json
{
  "title": "Ceiling Fan Repair & Installation",
  "titleI18n": {
    "en": "Ceiling Fan Repair & Installation",
    "hi": "छत का पंखा रिपेयर और इंस्टॉलेशन"
  },
  "category": "electrical",
  "categoryI18n": {
    "en": "Electrical",
    "hi": "बिजली / इलेक्ट्रिकल"
  },
  "description": "Complete fan motor testing, capacitor replacement, and balancing.",
  "descriptionI18n": {
    "en": "Complete fan motor testing, capacitor replacement, and balancing.",
    "hi": "पंखे की मोटर चेकिंग, कैपेसिटर बदलना और नया पंखा लगाना।"
  },
  "basePrice": 300,
  "estimatedTime": "45 Mins",
  "whatsIncluded": ["Capacitor test", "Blade alignment", "Wiring check"],
  "whatsIncludedI18n": {
    "en": ["Capacitor test", "Blade alignment", "Wiring check"],
    "hi": ["कैपेसिटर टेस्ट", "ब्लेड बैलेंसिंग", "वायरिंग चेक"]
  }
}
```
*Instant Redis push automatically refreshes `app:services:categories` and `app:home:dashboard`.*

---

## 4. User Language Switch, Push Notifications & Worker Wallet Transparency

### A. Mobile App Language Switch Flow (Hindi / English)

When the user selects or toggles language in the Flutter app (at onboarding or profile screen):

`PUT /api/users/language` (Auth: Bearer Token)
```json
{
  "language": "hi" // "hi" or "en"
}
```

**Backend Response:**
```json
{
  "success": true,
  "message": "Language preference updated successfully",
  "data": {
    "preferredLanguage": "hi"
  }
}
```

- **Database**: Saved in `User.preferredLanguage`.
- **Redis Fast Cache**: Instantly cached in Redis key `user:lang:<userId>` (TTL: 30 days).
- **Automatic Push Notification Delivery**: Whenever a background event occurs (Booking confirmed, Worker assigned, Payment received, SOS alert), `notificationService.js` retrieves the user's cached preferred language and delivers localized push notifications matching their selection.

---

### B. "Hey Flexi" Voice Agent Speech-to-Text & Text-to-Speech (STT / TTS)

The Flutter client can pass spoken audio transcriptions directly to `/api/ai/agent/chat` along with the chosen language:

```json
{
  "message": "mujhe abhi urgent plumber chahiye kitchen me pipe phat gaya hai",
  "language": "hi",
  "conversationState": {},
  "coordinates": [77.2090, 28.6139],
  "addressLine": "Flat 402, Green Valley Apartments, Delhi"
}
```

**Agent Capabilities:**
1. **Multi-Intent Destructuring**: Extracts category (`Plumbing`), problem (`pipe burst`), urgency (`EMERGENCY_SOS`), and schedule from a single sentence.
2. **Conversational Verification**: If a field is missing, it asks conversational follow-up questions in the chosen language.
3. **TTS-Ready Response**: The `reply` string is formatted strictly in the chosen language (pure Hindi or pure English) for clean audio playback via Flutter's `flutter_tts` plugin.

---

### C. Conversational AI Agent Architecture (`agent/` Directory)

The agent directory has been streamlined into a direct, high-performance LangChain implementation:

- **`agent/model.js`**: Centralized LangChain client initializing `ChatGoogleGenerativeAI` (`model: "gemini-2.5-flash"`, `temperature: 0`, `maxRetries: 2`). Fast, deterministic, and lightweight.
- **`agent/prompt.js`**: Static system prompt instructing the model to output a single JSON object containing `intent`, `category`, `problemDescription`, `isEmergency`, `confirmation`, and `reply` (bilingual Hindi/English formatted for TTS).
- **`agent/flexiAgent.js`**: Core conversation orchestrator with:
  - **Redis 60-Second TTL Session Memory**: Automatically tracks dialog state and resets inactive/abandoned sessions to protect against ghost/fake bookings.
  - **Zero Null/Fake Database Writes**: Enforces strict confirmation and mandatory field verification before creating a booking in MongoDB.
  - **Direct Status Inquiries**: Reads real-time booking status and assigned worker details directly from MongoDB for authenticated users.
- **`agent/index.js`**: Unified export of all agent functions and models.

---

### D. Worker Wallet Itemized Earnings & Deduction Breakdown

In compliance with fair cooperative wage principles, every job completion records and displays the complete financial breakdown to the worker:

`GET /api/payments/worker-wallet` or `GET /api/worker/me/wallet`

**Response Itemized History:**
```json
{
  "success": true,
  "data": {
    "walletBalance": 1425,
    "history": [
      {
        "transactionId": "TXN-1725700000000-A1B2",
        "type": "CREDIT",
        "amount": 450,
        "grossAmount": 500,
        "platformFeeDeducted": 25,
        "welfareDeducted": 25,
        "description": "Job Earning: BK-12345 (Gross: ₹500 - Margin: ₹25 - Welfare: ₹25)",
        "status": "COMPLETED",
        "createdAt": "2026-09-07T10:00:00.000Z"
      }
    ]
  }
}
```

- `grossAmount`: Total service fee paid by customer.
- `platformFeeDeducted`: Dynamic admin margin deduction (0% to X%).
- `welfareDeducted`: Credited to the worker's cooperative social security account.
- `amount`: Net liquid payout credited to worker's wallet.

---

## 5. Backend Changes Reference

1. **`models/Settings.js`** [MODIFIED]: Added dynamic admin fees (`customerPlatformFee`, `workerCommissionPercent`, `cooperativeWelfarePercent`, `workerSearchRadiusKm`, `defaultLaborRatePerHour`).
2. **`services/settingsService.js`** [NEW]: Redis-cached platform settings layer (`app:platform:settings`) ensuring zero hardcoded fallback overrides.
3. **`models/User.js`** [MODIFIED]: Added `preferredLanguage` (`'hi'` / `'en'`), `workerProfile.society`, `grossAmount`, `platformFeeDeducted`, `welfareDeducted` in `walletTransactionSchema`.
4. **`models/Booking.js`** [MODIFIED]: Removed hardcoded platformFee defaults; added `bookingType`, `isEmergency`, `timeSlot`, and dynamic invoices.
5. **`controllers/userController.js`** [MODIFIED]: `updateLanguage` endpoint validates `'hi'` / `'en'`, updates MongoDB, and caches in Redis key `user:lang:<id>`.
6. **`services/notificationService.js`** [MODIFIED]: Automatically resolves user preferred language from Redis/Mongo to dispatch push notifications in matching language.
7. **`agent/` Architecture** [CLEAN & DIRECT]:
   - **`agent/model.js`**: Direct LangChain `ChatGoogleGenerativeAI` (`gemini-2.5-flash`, temperature 0, maxRetries 2).
   - **`agent/prompt.js`**: Static prompt enforcing single JSON output (`intent`, `category`, `problemDescription`, `isEmergency`, `confirmation`, `reply`).
   - **`agent/flexiAgent.js`**:
     - **60-Second Inactivity Session Expiration (Redis TTL)**: Key `flexi:session:${userId}` expires in 60s. Abandoned sessions automatically abort and reset (`SESSION_EXPIRED`), preventing ghost/fake bookings.
     - **Zero Null/Fake DB Protection**: `Booking.create` strictly executes only when `state.step === 'AWAITING_CONFIRMATION'`, user gives explicit confirmation (`"confirm"`, `"kardo"`, `"कन्फर्म"`), and all required data (`category`, `coordinates`, `address`) are validated.
     - **Explicit Cancellation**: User exits ("cancel", "band karo", "radd karo") immediately delete the Redis session and return `SESSION_ABORTED`.
   - **`agent/index.js`**: Clean re-export of model, prompt, and flexiAgent.
8. **`controllers/bookingController.js`** [MODIFIED]: Uses dynamic settings for platform fees and labor rates; cleanly supports ₹0 fee.
9. **`controllers/paymentController.js`** [MODIFIED]: Credits worker wallet with itemized gross, platform fee, and welfare breakdown using dynamic margins.
10. **`controllers/workerWalletController.js`** [MODIFIED]: Summarizes and surfaces gross and deduction details in worker wallet dashboard.
11. **`controllers/adminController.js`** [MODIFIED]: Invalidates `app:platform:settings` on admin settings update.
12. **`models/CooperativeSociety.js`** [NEW]: Primary cooperative societies schema linked to federation.
13. **`models/Cooperative.js`** [MODIFIED]: Added registration number, category wage floors, emergency surcharge, and welfare balance.
14. **`services/eligibleWorkers.js`** [MODIFIED]: Uses dynamic admin search radius.
15. **`.env` & `.env.example`** [MODIFIED]: Added `GEMINI_API_KEY` and `ADMIN_NAME` configuration.

---

## 6. API Endpoint Reference Sheet

| Route | Method | Access | Description |
|---|---|---|---|
| `/api/users/language` | `PUT` | User | Update preferred app language (`hi` or `en`), synced with Redis |
| `/api/ai/agent/chat` | `POST` | Customer | Interact with "Hey Flexi" AI Voice/Text Assistant (supports `language`, audio transcript, multi-intent) |
| `/api/bookings` | `POST` | Customer | Create booking (Standard, Scheduled, or Emergency SOS) |
| `/api/bookings/:bookingId` | `PATCH` | Customer | Update existing booking (description, schedule, address) & trigger re-dispatch |
| `/api/bookings/estimate` | `POST` | Customer | Get price estimate using dynamic admin fees & wage floors |
| `/api/home/banners` | `GET` | Public | Fetch promotional coupon banners (auto-seeds defaults) |
| `/api/admin/banners` | `GET` / `POST` | Admin | List all promotional coupon banners or create a new coupon |
| `/api/admin/banners/:id` | `PUT` / `DELETE` | Admin | Update banner details or remove banner |
| `/api/admin/settings` | `GET` / `PUT` | Admin | Manage dynamic fees, commission %, welfare %, and search radius |
| `/api/payments/worker-wallet` | `GET` | Worker | Get worker wallet balance & itemized deduction transaction history |
| `/api/worker/me/wallet` | `GET` | Worker | Worker app wallet dashboard with gross & net breakdown |
| `/api/cooperative/info` | `GET` | User | Get Federation stats, societies count, and wage policies |
| `/api/cooperative/societies` | `GET` | User | List all Primary Cooperative Societies |
| `/api/cooperative/societies/:id` | `GET` | User | Get Society details and member roster |
| `/api/cooperative/my-society` | `GET` | Worker | Get logged-in worker's cooperative society details & member card |
| `/api/admin/cooperative/societies` | `POST` | Admin | Register new Primary Labour Cooperative Society |
| `/api/admin/cooperative/societies/:id`| `PUT` | Admin | Update Primary Cooperative Society details |
| `/api/admin/cooperative/assign-worker`| `POST` | Admin | Assign worker to a Primary Cooperative Society |
| `/api/admin/cooperative` | `PUT` | Admin | Update Federation wage floors & surcharge rates |
| `/api/admin/worker-payouts/:id/status`| `PATCH` | Admin | Settle worker payout and deduct wallet balance |
| `/api/worker/me/withdraw` | `POST` | Worker | Request wallet balance withdrawal to bank/UPI |
