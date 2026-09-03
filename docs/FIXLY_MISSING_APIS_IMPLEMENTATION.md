# Fixly — Missing APIs Implementation Plan

## Purpose

This document is the implementation blueprint for closing the API gaps between the current Fixly backend and the planned SIH26089 product flow.

The existing backend already contains authentication, workers, bookings, payments, services, reviews, AI issue analysis, uploads, and a broad admin API. The missing work is primarily around the worker lifecycle, cooperative/welfare layer, customer profile/support, notifications, and the complete AI orchestration layer.

> Naming rule: expose the product-facing concept as **Verification**. Do not introduce a new public API term using the old internal document terminology. Keep existing database fields temporarily for backward compatibility unless a migration is explicitly planned.

---

# 1. Current backend structure

Relevant existing paths:

```text
bakend-master/
├── controllers/
│   ├── activeJobController.js
│   ├── adminController.js
│   ├── aiController.js
│   ├── authController.js
│   ├── bookingController.js
│   ├── homeController.js
│   ├── paymentController.js
│   ├── reviewController.js
│   ├── serviceController.js
│   ├── uploadController.js
│   └── workerController.js
├── models/
│   ├── Booking.js
│   ├── Review.js
│   ├── Service.js
│   ├── Transaction.js
│   └── User.js
├── routes/
│   ├── admin-routes.js
│   ├── ai-routes.js
│   ├── auth-routes.js
│   ├── booking-routes.js
│   ├── home-routes.js
│   ├── payment-routes.js
│   ├── review-routes.js
│   ├── service-routes.js
│   ├── upload-routes.js
│   └── worker-routes.js
└── server.js
```

Do not create a second server or a parallel API architecture. Extend this structure.

---

# 2. API status snapshot

## Already present

- Auth/login/session
- Worker nearby search
- Worker profile
- Worker profile setup
- Service categories/search/details
- Booking creation/estimate/history/details/cancel
- Worker booking acceptance
- Arrival verification
- Job start/completion
- Extra parts
- Live tracking
- Booking SOS
- Invoice
- Payment order/verification/history
- Review submission
- AI issue analysis
- Admin dashboard/customer/worker/booking/service/payment/review/notification/analytics/report/settings APIs

## Needs addition or extension

- Worker verification lifecycle
- Verification status tracker
- Worker certificate management
- Worker availability management
- Worker jobs lists
- Worker earnings/wallet/payout APIs
- Customer profile APIs
- Saved address APIs
- Customer/worker notification APIs
- Support ticket and grievance APIs
- Cooperative membership APIs
- Welfare contribution/benefit APIs
- Insurance information/claims APIs
- AI service discovery contract
- AI worker matching
- Reliability score retrieval/calculation
- Demand forecasting
- Stronger price estimation using demand forecast
- Device push-token registration
- Worker rejection/arrival endpoints where needed
- Review retrieval
- Public/profile read APIs needed by Flutter

---

# 3. Worker Verification API group

## Files to create/update

Create:

```text
bakend-master/controllers/verificationController.js
bakend-master/routes/verification-routes.js
```

Update:

```text
bakend-master/server.js
```

### 3.1 Submit verification documents

```http
POST /api/verification/submit
Authorization: Bearer <token>
Content-Type: application/json
```

Request:

```json
{
  "governmentIdType": "Aadhaar Card",
  "governmentIdNumber": "masked-or-encrypted-value",
  "governmentIdFrontUrl": "https://...",
  "governmentIdBackUrl": "https://...",
  "selfieImageUrl": "https://...",
  "additionalDocuments": [
    {
      "type": "PAN Card",
      "number": "...",
      "frontUrl": "https://...",
      "backUrl": "https://..."
    }
  ]
}
```

Behavior:

1. Confirm authenticated user is a worker.
2. Validate required fields.
3. Store the data using the existing User document structure for now.
4. Set verification state to `submitted`.
5. Clear previous decline reason when resubmitting.
6. Create an audit event if an audit model exists; otherwise add it in the future.
7. Return a normalized response that never exposes sensitive full document numbers.

Response:

```json
{
  "success": true,
  "verification": {
    "status": "submitted",
    "submittedAt": "2026-09-04T00:00:00.000Z"
  }
}
```

### 3.2 Get my verification status

```http
GET /api/verification/me
```

Return:

```json
{
  "success": true,
  "verification": {
    "status": "pending",
    "identity": "submitted",
    "selfie": "approved",
    "certificates": "pending",
    "declineReason": null,
    "lastUpdatedAt": "..."
  }
}
```

### 3.3 Resubmit verification

```http
POST /api/verification/resubmit
```

Allow only when current status is `rejected` or equivalent resubmission state.

### 3.4 Admin review actions

These can live in `admin-routes.js` because admin already owns worker administration.

Add to `adminController.js`:

```text
reviewWorkerVerification
getWorkerVerificationDetails
```

Routes:

```http
GET   /api/admin/workers/:id/verification
PATCH /api/admin/workers/:id/verification
```

Patch body:

```json
{
  "status": "approved",
  "declineReason": null
}
```

Allowed values:

```text
pending
submitted
approved
rejected
```

When approved, update the worker's verified flag consistently.

---

# 4. Worker Certificate APIs

## Files

Create/update:

```text
bakend-master/controllers/workerCertificateController.js
bakend-master/routes/worker-certificate-routes.js
```

Use a new model if metadata is needed:

```text
bakend-master/models/WorkerCertificate.js
```

Recommended fields:

```text
worker
serviceCategory
certificateType
certificateNumber (optional)
fileUrl
issuer
issuedOn
expiresOn
status
reviewNote
createdAt
updatedAt
```

## Routes

```http
POST   /api/workers/me/certificates
GET    /api/workers/me/certificates
GET    /api/workers/me/certificates/:id
DELETE /api/workers/me/certificates/:id
```

Admin:

```http
GET   /api/admin/workers/:workerId/certificates
PATCH /api/admin/workers/:workerId/certificates/:certificateId
```

Do not force a certificate for every service. Make the requirement configurable per service/category.

---

# 5. Worker availability APIs

## Files

Update:

```text
bakend-master/controllers/workerController.js
bakend-master/routes/worker-routes.js
```

Add model fields to `User.workerProfile`:

```text
isOnline: Boolean
availabilitySchedule: [ ... ]
lastActiveAt: Date
serviceRadiusKm: Number
```

## Routes

```http
GET   /api/workers/me/availability
PATCH /api/workers/me/availability
PUT   /api/workers/me/availability/schedule
```

Example:

```json
{
  "isOnline": true
}
```

Schedule example:

```json
{
  "days": [1,2,3,4,5],
  "startTime": "09:00",
  "endTime": "18:00"
}
```

When worker goes online/offline, emit a Socket.IO event so customer matching can react immediately.

---

# 6. Worker job list APIs

## Files

Update:

```text
bakend-master/controllers/activeJobController.js
bakend-master/routes/booking-routes.js
```

Add:

```http
GET /api/bookings/worker/incoming
GET /api/bookings/worker/active
GET /api/bookings/worker/completed
```

Important: these endpoints must filter by `req.user.id` server-side. Never trust a `workerId` supplied by Flutter for authorization.

Suggested pagination:

```text
?page=1&limit=20&status=...
```

---

# 7. Worker earnings and wallet APIs

Current `Transaction.js` records customerId, workerId, bookingId, amount and payment state. Build the worker-facing read APIs around that model first; do not duplicate payment records. 

## Files

Create:

```text
bakend-master/controllers/workerWalletController.js
bakend-master/routes/worker-wallet-routes.js
```

Optional model for payout requests:

```text
bakend-master/models/PayoutRequest.js
```

## Routes

```http
GET  /api/workers/me/wallet
GET  /api/workers/me/earnings
GET  /api/workers/me/earnings/summary
GET  /api/workers/me/transactions
GET  /api/workers/me/payouts
POST /api/workers/me/withdraw
```

### Wallet response should include

```text
availableBalance
pendingBalance
totalEarned
thisWeek
thisMonth
platformFee
welfareContribution
insuranceContribution
lastPayout
```

### Earnings query

Calculate from successful worker transactions and completed bookings. Make the source of truth explicit.

Recommended filters:

```text
?from=YYYY-MM-DD&to=YYYY-MM-DD
```

### Withdraw

Validate minimum withdrawal amount and payout account before creating a payout request.

Do not mark the payment as completed merely because a payout request was created.

---

# 8. Customer profile APIs

## Files to create

```text
bakend-master/controllers/userController.js
bakend-master/routes/user-routes.js
```

Update:

```text
bakend-master/server.js
```

## Routes

```http
GET   /api/users/me
PUT   /api/users/me
PATCH /api/users/me/language
PATCH /api/users/me/location
PATCH /api/users/me/emergency-contact
```

Do not return passwords, device IDs, raw government identifiers, or other secrets.

Example profile fields:

```text
name
phone
email
avatar
language
location
emergencyContact
```

Add these fields to User schema if not already present.

---

# 9. Saved address APIs

The current User schema already contains `savedAddresses`. Expose it through a dedicated endpoint group instead of sending the complete user document back and forth.

## Routes

```http
GET    /api/users/me/addresses
POST   /api/users/me/addresses
PUT    /api/users/me/addresses/:id
DELETE /api/users/me/addresses/:id
```

Validate GeoJSON coordinates as:

```text
[longitude, latitude]
```

---

# 10. Notification APIs

The admin API already supports notifications/broadcasting, but customer/worker clients need their own read state.

## Files

Create:

```text
bakend-master/models/Notification.js
bakend-master/controllers/notificationController.js
bakend-master/routes/notification-routes.js
```

Suggested model:

```text
recipient
role
category
title
body
data
isRead
createdAt
```

## Routes

```http
GET   /api/notifications
PATCH /api/notifications/:id/read
PATCH /api/notifications/read-all
DELETE /api/notifications/:id
POST  /api/notifications/device-token
DELETE /api/notifications/device-token
```

Notification categories:

```text
BOOKING
PAYMENT
VERIFICATION
SUPPORT
SAFETY
SYSTEM
PROMOTION
```

For realtime UX, keep Socket.IO events alongside persistent notifications.

---

# 11. Support and grievance APIs

This is a high-priority API group because the product differentiates itself through transparent grievance handling.

## Files

Create:

```text
bakend-master/models/SupportTicket.js
bakend-master/controllers/supportController.js
bakend-master/routes/support-routes.js
```

Recommended model:

```text
ticketNumber
createdBy
booking
category
priority
status
subject
description
attachments
assignedTo
lastMessageAt
resolvedAt
createdAt
updatedAt
```

Statuses:

```text
OPEN
IN_REVIEW
WAITING_FOR_USER
RESOLVED
CLOSED
```

## User routes

```http
POST  /api/support/tickets
GET   /api/support/tickets
GET   /api/support/tickets/:id
POST  /api/support/tickets/:id/messages
PATCH /api/support/tickets/:id/close
```

## Admin routes

```http
GET   /api/admin/support/tickets
GET   /api/admin/support/tickets/:id
PATCH /api/admin/support/tickets/:id
POST  /api/admin/support/tickets/:id/messages
```

Ticket categories:

```text
SERVICE_DISPUTE
WORKER_CUSTOMER_ISSUE
PAYMENT
SAFETY
BOOKING
ACCOUNT
OTHER
```

The chatbot should be able to create a ticket through this API.

---

# 12. Cooperative identity APIs

Do not hard-code cooperative text only in Flutter. The backend should expose the cooperative configuration and membership state.

## Files

Create:

```text
bakend-master/models/Cooperative.js
bakend-master/controllers/cooperativeController.js
bakend-master/routes/cooperative-routes.js
```

Possible fields:

```text
name
federationName
state
district
commissionRate
welfareContributionRate
insuranceEnabled
fairWagePolicy
active
```

## Routes

```http
GET /api/cooperative/info
GET /api/workers/me/membership
```

Admin:

```http
GET   /api/admin/cooperative
PUT   /api/admin/cooperative
GET   /api/admin/cooperative/members
```

Do not let the mobile app calculate cooperative commission on its own. Fetch the authoritative values from the backend.

---

# 13. Welfare and insurance APIs

## Files

Create:

```text
bakend-master/models/WelfareAccount.js
bakend-master/models/WelfareTransaction.js
bakend-master/models/InsurancePolicy.js
bakend-master/controllers/welfareController.js
bakend-master/routes/welfare-routes.js
```

## Worker routes

```http
GET /api/workers/me/welfare
GET /api/workers/me/welfare/transactions
GET /api/workers/me/insurance
GET /api/workers/me/insurance/claims
POST /api/workers/me/insurance/claims
```

## Suggested welfare response

```json
{
  "balance": 350,
  "totalContributed": 4200,
  "trainingEligible": true,
  "insuranceActive": true,
  "lastContribution": "..."
}
```

This becomes one of the clearest proof points that the platform is not only a booking marketplace.

---

# 14. Service discovery AI API

Existing AI route:

```http
POST /api/ai/analyze-issue
```

Keep it backward compatible, but standardize the response and expose a product-level endpoint.

## Files

Update:

```text
bakend-master/controllers/aiController.js
bakend-master/routes/ai-routes.js
```

Add:

```http
POST /api/ai/service-discovery
```

Request:

```json
{
  "text": "fridge is not cooling"
}
```

Response:

```json
{
  "success": true,
  "suggestions": [
    {
      "categoryId": "...",
      "serviceId": "...",
      "title": "Refrigerator Repair",
      "confidence": 0.94
    }
  ]
}
```

First release can remain text-only. Voice can be added later.

---

# 15. AI worker matching API

This is a core differentiator and should not be reduced to simple nearest-worker sorting.

## Routes

```http
POST /api/ai/match-workers
```

Request:

```json
{
  "serviceId": "...",
  "latitude": 28.61,
  "longitude": 77.20,
  "scheduledAt": "2026-09-04T12:00:00.000Z",
  "priceRange": {
    "min": 300,
    "max": 700
  }
}
```

The scoring inputs should be the six agreed inputs:

```text
skill match
distance
rating
completion rate
response time
current availability
```

Return a ranked list:

```json
{
  "success": true,
  "matches": [
    {
      "workerId": "...",
      "matchScore": 96,
      "reasons": [
        "Strong skill match",
        "Available now",
        "High completion rate"
      ]
    }
  ]
}
```

Do not expose internal model coefficients or sensitive worker data.

---

# 16. Worker reliability API

## Routes

Preferred design: include reliability inside the worker profile response so Flutter does not need a second request.

Existing:

```http
GET /api/workers/:workerId
```

Extend the response with:

```json
{
  "reliability": {
    "score": 94,
    "onTimeArrival": 96,
    "completionRate": 98,
    "customerFeedback": 92,
    "cancellationRate": 95,
    "responseTime": 90
  }
}
```

If a separate endpoint is still useful for admin analytics:

```http
GET /api/workers/:workerId/reliability
```

The score should be calculated server-side from booking/review history.

---

# 17. Demand forecasting API

This is currently the largest missing AI capability.

## Files

Create:

```text
bakend-master/controllers/demandForecastController.js
bakend-master/routes/demand-routes.js
```

Route:

```http
GET /api/ai/demand-forecast
```

Query examples:

```text
?areaId=...
&serviceId=...
&horizon=24h
```

Response:

```json
{
  "success": true,
  "forecast": [
    {
      "time": "2026-09-04T10:00:00.000Z",
      "demandLevel": "HIGH",
      "expectedBookings": 17
    }
  ]
}
```

Use the forecast for:

1. price estimation
2. worker availability suggestions
3. admin demand heatmaps
4. service coverage planning

Do not allow demand forecast to silently raise prices without an explicit cooperative pricing policy.

---

# 18. Fair price estimation — extend existing API

Existing:

```http
POST /api/bookings/estimate
```

Do not create another duplicate endpoint.

Extend the estimator so it consumes:

```text
base service price
+ area demand signal
+ emergency fee
+ approved cooperative pricing rules
+ optional extra-part estimate
```

Return a breakdown:

```json
{
  "baseServiceFee": 450,
  "demandAdjustment": 20,
  "urgentFee": 50,
  "estimatedTotal": 520,
  "currency": "INR",
  "isEstimate": true
}
```

The UI must clearly state this is an estimate, not a live worker bidding system.

---

# 19. Review read APIs

Existing review route currently focuses on submission.

Add:

```http
GET /api/workers/:workerId/reviews
GET /api/bookings/:bookingId/review
```

Optional pagination:

```text
?page=1&limit=10
```

Worker profile should show summary statistics rather than loading hundreds of reviews.

---

# 20. SOS expansion

Existing:

```http
POST /api/bookings/:bookingId/sos
```

Keep it.

Add general SOS history/detail endpoints if the app requires them:

```http
POST /api/sos
GET  /api/sos/:id
GET  /api/sos/history
```

Allowed categories:

```text
SAFETY_EMERGENCY
SERVICE_DISPUTE
WORKER_CUSTOMER_ISSUE
CUSTOMER_SUPPORT
```

Capture booking reference and current coordinates when the request is made.

---

# 21. Worker rejection/decline support

The current booking lifecycle contains acceptance but the worker UI also requires decline.

Preferred:

```http
POST /api/bookings/:bookingId/decline
```

Request:

```json
{
  "reason": "TOO_FAR"
}
```

Do not penalize every decline equally. Store a structured reason for analytics and fairness analysis.

Possible reasons:

```text
TOO_FAR
UNAVAILABLE
WRONG_SKILL
CUSTOMER_REQUEST
OTHER
```

---

# 22. Admin additions

The existing admin route layer is strong. Extend it instead of creating a second admin API family.

Add:

```http
GET   /api/admin/support/tickets
GET   /api/admin/support/tickets/:id
PATCH /api/admin/support/tickets/:id
GET   /api/admin/workers/:id/verification
PATCH /api/admin/workers/:id/verification
GET   /api/admin/workers/:id/certificates
PATCH /api/admin/workers/:id/certificates/:certificateId
GET   /api/admin/cooperative
PUT   /api/admin/cooperative
GET   /api/admin/welfare/summary
GET   /api/admin/worker-payouts
```

The admin dashboard should expose these as operational modules, not just analytics cards.

---

# 23. Server registration

Update `bakend-master/server.js` with new imports and mounts.

Recommended mounting:

```js
app.use('/api/users', apiLimiter, userRoutes);
app.use('/api/verification', apiLimiter, verificationRoutes);
app.use('/api/worker-certificates', apiLimiter, workerCertificateRoutes);
app.use('/api/worker-wallet', apiLimiter, workerWalletRoutes);
app.use('/api/notifications', apiLimiter, notificationRoutes);
app.use('/api/support', apiLimiter, supportRoutes);
app.use('/api/cooperative', apiLimiter, cooperativeRoutes);
app.use('/api/welfare', apiLimiter, welfareRoutes);
```

For AI endpoints:

```js
app.use('/api/ai', apiLimiter, aiRoutes);
```

Keep the existing `/api/ai` mount and extend its routes; do not mount `/api/ai` twice.

---

# 24. Data model changes

## User.js

Add only the missing product fields, for example:

```text
preferredLanguage
emergencyContact
workerProfile.isOnline
workerProfile.lastActiveAt
workerProfile.serviceRadiusKm
workerProfile.availabilitySchedule
```

Keep the legacy document-storage fields temporarily to avoid breaking existing Flutter/backend code. Public API names should use **verification** terminology.

## New collections

Recommended:

```text
WorkerCertificate
Notification
SupportTicket
Cooperative
WelfareAccount
WelfareTransaction
InsurancePolicy
PayoutRequest
```

Do not create models for data that can be derived reliably from existing `Booking`, `Review`, and `Transaction` data.

---

# 25. Authorization rules

Every user endpoint must enforce ownership with `req.user.id`.

Examples:

```text
Customer can read/update own profile
Worker can update own availability
Worker can read own earnings
Worker can read own verification
Customer can read own notifications
Worker can read own notifications
Admin can review other workers
```

Never accept an arbitrary user/worker ID from Flutter as the source of authorization.

For worker-only routes, add a reusable middleware:

```text
middleware/roleMiddleware.js
```

with helpers such as:

```js
requireRole('worker')
requireRole('customer')
requireRole('admin')
```

If an equivalent middleware already exists, reuse it.

---

# 26. Validation

Use consistent validation before controller logic.

Recommended package if the project does not already have one:

```text
zod
```

or the project's existing validation library.

At minimum validate:

- ObjectId format
- coordinates
- dates
- numeric rates
- payout amounts
- phone/email formats
- notification IDs
- support ticket IDs
- file URLs
- certificate metadata

---

# 27. Error response standard

All new APIs should return the same shape.

Success:

```json
{
  "success": true,
  "data": {}
}
```

Validation error:

```json
{
  "success": false,
  "code": "VALIDATION_ERROR",
  "message": "Invalid request",
  "details": []
}
```

Not found:

```json
{
  "success": false,
  "code": "NOT_FOUND",
  "message": "Resource not found"
}
```

Unauthorized:

```json
{
  "success": false,
  "code": "UNAUTHORIZED",
  "message": "Authentication required"
}
```

Forbidden:

```json
{
  "success": false,
  "code": "FORBIDDEN",
  "message": "You do not have access to this resource"
}
```

Server failure:

```json
{
  "success": false,
  "code": "INTERNAL_ERROR",
  "message": "Something went wrong"
}
```

Do not send stack traces to Flutter.

---

# 28. Socket.IO events

Because the server already initializes Socket.IO, use it for realtime state instead of polling everything.

Recommended events:

```text
worker:availability-changed
booking:created
booking:accepted
booking:declined
booking:arrived
booking:started
booking:completed
booking:location-updated
booking:sos
notification:new
support:ticket-updated
```

Persist important events in MongoDB as needed; Socket.IO should not be the source of truth.

---

# 29. Flutter integration mapping

## Customer app

```text
Profile screen        -> /api/users/me
Address screen        -> /api/users/me/addresses
Notifications         -> /api/notifications
Support               -> /api/support/tickets
AI service helper     -> /api/ai/service-discovery
Worker results        -> /api/ai/match-workers
Worker profile        -> /api/workers/:workerId
Worker reviews        -> /api/workers/:workerId/reviews
Price estimate        -> /api/bookings/estimate
Booking lifecycle     -> /api/bookings/*
Payment               -> /api/payments/*
SOS                   -> /api/bookings/:id/sos
```

## Worker app

```text
Profile               -> /api/users/me or /api/workers/*
Verification          -> /api/verification/*
Certificates          -> /api/workers/me/certificates
Availability          -> /api/workers/me/availability
Incoming jobs         -> /api/bookings/worker/incoming
Active job            -> /api/bookings/worker/active
Earnings              -> /api/workers/me/earnings
Wallet                -> /api/workers/me/wallet
Payouts               -> /api/workers/me/payouts
Welfare               -> /api/workers/me/welfare
Insurance             -> /api/workers/me/insurance
Notifications         -> /api/notifications
Support               -> /api/support/tickets
```

## Admin panel

```text
Worker verification   -> /api/admin/workers/:id/verification
Certificates          -> /api/admin/workers/:id/certificates
Support               -> /api/admin/support/*
Cooperative           -> /api/admin/cooperative
Welfare               -> /api/admin/welfare/*
Worker payouts        -> /api/admin/worker-payouts
Existing dashboards   -> existing admin routes
```

---

# 30. Recommended implementation order

## Phase 1 — Required for complete demo

1. Worker Verification status + submission
2. Worker certificates
3. Worker availability
4. Worker incoming/active/completed jobs
5. Worker earnings/wallet
6. Customer profile + addresses
7. Notifications
8. Support tickets
9. Review read API

## Phase 2 — SIH differentiators

10. AI service discovery
11. AI worker matching
12. Reliability score
13. Fair price estimator integration
14. Demand forecasting

## Phase 3 — Cooperative identity

15. Cooperative info/membership
16. Welfare account/transactions
17. Insurance
18. Payout workflow

## Phase 4 — polish

19. Push-token lifecycle
20. Realtime event hardening
21. Audit history
22. Advanced analytics
23. Rate-limit tuning
24. API tests + Swagger updates

---

# 31. Testing checklist

For each endpoint create tests for:

### Authentication

- valid token
- missing token
- expired token
- wrong role

### Ownership

- user can read own resource
- user cannot read another user's private resource

### Validation

- missing required fields
- invalid ObjectId
- invalid coordinate
- invalid amount
- invalid enum value

### Lifecycle

- valid transition
- invalid transition
- duplicate action
- already completed/cancelled job

### Payments

- duplicate verification callback
- payment failure
- payout request while balance is insufficient

### Support

- ticket creation
- message append
- close
- admin assignment

### Verification

- submit
- resubmit after rejection
- approve
- reject with reason
- prevent invalid transitions

---

# 32. Important implementation rule

Do not replace the existing backend in one large rewrite.

Implement each API group as an additive change, then run:

```bash
npm test
npm run swagger
npm run dev
```

and test the affected routes in Swagger/Postman before moving to the next group.

The existing booking/payment flow is already substantial, so protect it from regressions.

---

# 33. Final target architecture

```text
                         FIXLY API
                             │
       ┌─────────────────────┼─────────────────────┐
       │                     │                     │
   CUSTOMER               WORKER                ADMIN
       │                     │                     │
 Profile                 Verification          Workers
 Addresses               Certificates          Customers
 Bookings                Availability           Bookings
 Payments                Jobs                   Services
 Reviews                 Earnings               Payments
 Support                 Welfare                Support
 Notifications           Insurance              Analytics
       │                     │                     │
       └─────────────────────┼─────────────────────┘
                             │
                        AI LAYER
                             │
              ┌──────────────┼──────────────┐
              │              │              │
        Service Discovery  Matching    Demand Forecast
              │              │              │
              └──────────────┼──────────────┘
                             │
                    Fair Price Estimation
                             │
                         MongoDB
                             │
                         Redis
                             │
                        Socket.IO
```

This is the target backend shape to align the codebase with the product design without breaking the existing booking/payment infrastructure.
