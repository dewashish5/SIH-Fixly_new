# Fixly — Full FCM Integration & Notification System Implementation Plan

> **Purpose:** This document is the implementation blueprint for adding production-grade Firebase Cloud Messaging (FCM) to the existing Fixly Flutter application and Node/Express backend, while preserving the existing Socket.IO real-time architecture and MongoDB notification inbox.
>
> **Repository audited:** `dewashish5/SIH-Fixly` (`main`)
>
> **Important:** This plan is based on the current repository structure and code paths, not a greenfield architecture. Existing implementation details, status names, API behavior, and current limitations are explicitly accounted for.

---

## 1. Executive Summary

Fixly currently has three partially independent notification/realtime mechanisms:

1. **Socket.IO** for live in-app booking/job/location updates.
2. **MongoDB `Notification` documents** for notification history/admin notification records.
3. **Flutter mock notification UI** that is not yet connected to the backend notification API.

FCM should be introduced as the **OS-level push transport** for background, terminated, and foreground push notification delivery.

The final architecture should therefore be:

```text
                         ┌────────────────────────┐
                         │      Flutter App       │
                         │                        │
                         │ Firebase Messaging     │
                         │ Local Notifications    │
                         │ Token Sync             │
                         │ Topic Subscription     │
                         │ Tap Router             │
                         └───────────┬────────────┘
                                     │
                                     │ FCM token / receive
                                     ▼
                              Firebase Cloud
                              Messaging (FCM)
                                     ▲
                                     │ send
                         ┌───────────┴────────────┐
                         │ Backend FCM Service    │
                         │ Firebase Admin SDK     │
                         └───────────▲────────────┘
                                     │
                         ┌───────────┴────────────┐
                         │ Notification Worker    │
                         │ BullMQ + Redis         │
                         └───────────▲────────────┘
                                     │
                         ┌───────────┴────────────┐
                         │ Notification Service   │
                         │ templates + routing    │
                         └───────────▲────────────┘
                                     │
                ┌────────────────────┼────────────────────┐
                │                    │                    │
                ▼                    ▼                    ▼
            Booking              Payment             Other domains
                │                    │                    │
                └────────────────────┴────────────────────┘
                                     │
                                     ▼
                             MongoDB Notification
                              durable inbox/history

                 Existing Socket.IO remains separate
                 for live application state updates.
```

### Core rule

**FCM does not replace Socket.IO.**

- Socket.IO = live state.
- FCM = OS push.
- MongoDB Notification = durable inbox/history.
- REST API = source of truth.
- Redis/BullMQ = asynchronous delivery infrastructure.

---

# 2. Repository Audit — What Exists Today

## 2.1 Backend

### Runtime and dependencies

`backend/package.json` currently uses:

- Node.js / ES Modules
- Express 5
- Mongoose 9
- BullMQ
- ioredis
- Socket.IO
- Razorpay
- Nodemailer
- Cloudinary
- JWT auth

There is currently **no `firebase-admin` dependency**.

### Server startup

`backend/server.js` currently:

- loads `.env`
- configures Express/Helmet/CORS
- mounts all API routes
- starts the email BullMQ worker
- starts the upload BullMQ worker
- initializes Socket.IO
- connects MongoDB
- listens on the configured port

FCM worker startup should follow the same application pattern.

---

## 2.2 Backend notification model

Current `backend/models/Notification.js` contains:

- title
- message
- body
- category
- targetAudience
- recipient
- role
- recipientEmail
- sendEmail
- priority
- unread
- isRead
- data
- timestamps

It already has a recipient index:

```text
{ recipient: 1, createdAt: -1 }
```

However, it does not currently contain the information necessary for reliable push orchestration.

### Required additions

Add fields conceptually equivalent to:

```text
eventType
entityType
entityId
bookingId
dedupeKey
channel
deliveryStatus
deliveryAttempts
lastDeliveryError
sentAt
deliveredAt
```

Suggested enums:

```text
channel:
  IN_APP
  PUSH
  EMAIL
  MULTI

deliveryStatus:
  PENDING
  QUEUED
  SENT
  FAILED
  PARTIAL
  SKIPPED
```

Do not store secrets or full private business objects in the notification data payload.

---

## 2.3 Existing User push-token storage

`backend/models/User.js` currently has:

```text
pushTokens: [String]
```

and also:

```text
activeDeviceId
```

The existing token controller simply `$addToSet`s tokens into that array.

This is not enough for long-term multi-device management.

### Target

Create:

```text
backend/models/PushToken.js
```

with approximately:

```text
user
token
deviceId
platform
appVersion
locale
isActive
lastSeenAt
createdAt
updatedAt
```

Indexes:

```text
unique token
user + isActive
user + deviceId
```

The token itself is not a password, but it should still be treated as sensitive infrastructure data.

### Migration strategy

Do not delete `User.pushTokens` immediately.

Recommended sequence:

1. Create `PushToken`.
2. Register all new tokens in `PushToken`.
3. Keep legacy `pushTokens` temporarily for compatibility.
4. Backfill existing tokens if useful.
5. Switch all sending logic to `PushToken`.
6. Remove the legacy array in a later cleanup release.

---

# 3. Current Flutter Architecture — Relevant Findings

## 3.1 Firebase Core already exists

`frontend/pubspec.yaml` already includes:

```text
firebase_core
google_sign_in
```

There is currently no:

```text
firebase_messaging
flutter_local_notifications
```

So FCM is an extension of the existing Firebase setup, not a brand-new Firebase integration.

---

## 3.2 Firebase bootstrap

Current:

```text
frontend/lib/core/firebase/firebase_bootstrap.dart
```

already:

- loads `firebase_client.json`
- merges Android `google-services.json`
- merges iOS `GoogleService-Info.plist`
- configures Google Sign-In
- initializes Firebase Core where valid

### Required design

Do not put the entire FCM system into `FirebaseBootstrap`.

Keep responsibilities separated:

```text
FirebaseBootstrap
  -> Firebase Core + Google Sign-In bootstrap

NotificationService
  -> Messaging + local notification setup

NotificationTokenService
  -> token acquisition/sync

NotificationTopicService
  -> FCM topic subscriptions

NotificationRouter
  -> tap/action routing

NotificationPermissionService
  -> permission UX
```

### Important existing issue

`FirebaseBootstrap` currently catches Firebase initialization failures and logs them instead of making the app fail.

The FCM layer must therefore explicitly determine:

```text
Is Firebase actually initialized?
```

before attempting:

- `FirebaseMessaging.instance`
- token retrieval
- topic subscription

Do not treat a swallowed Firebase bootstrap error as a healthy FCM state.

---

# 4. Authentication Lifecycle Integration

The existing authentication flow is centralized in:

```text
frontend/lib/features/auth/presentation/cubit/app_session_cubit.dart
```

The following paths exist:

- email login
- Google login
- OTP verification
- session restore
- logout

This is the correct lifecycle boundary for token synchronization.

## 4.1 After login

After `_applySession(...)` completes successfully:

```text
authenticated
      ↓
get FCM token
      ↓
register token with backend
      ↓
subscribe role topics
      ↓
process pending notification action
```

This applies to:

- normal login
- Google login
- OTP verification

---

## 4.2 After session restore

`restoreSession()` must also run notification registration.

Reason:

The app can start with an existing JWT session while the FCM token may have:

- changed
- expired
- changed after reinstall
- rotated by Firebase
- been generated after a previous app install

Therefore:

```text
restore session
     ↓
authenticated
     ↓
sync current FCM token
```

---

## 4.3 On FCM token refresh

Register a listener:

```text
FirebaseMessaging.onTokenRefresh
```

For every new token:

```text
update PushToken record
mark old token inactive if appropriate
associate current user + deviceId
```

The server endpoint should remain idempotent.

---

## 4.4 On logout

Logout must perform this sequence:

```text
attempt backend token deactivation/removal
unsubscribe role-specific topics
clear local push-session state
clear JWT session
clear user session
```

Push cleanup must never prevent logout.

Use best-effort semantics:

```text
try remote cleanup
finally local logout
```

This follows the existing `AuthApiRepository.logout()` philosophy, where remote logout failure does not block local session clearing.

---

# 5. Existing Device ID — Reuse It

The Flutter application already has:

```text
frontend/lib/core/auth/device_id.dart
```

and `ApiClient` automatically adds:

```http
x-device-id
```

to API requests.

This is useful for FCM token ownership.

### Registration payload

Use something like:

```json
{
  "token": "...",
  "deviceId": "...",
  "platform": "android",
  "appVersion": "1.0.4",
  "locale": "en"
}
```

The server gets the authenticated user from JWT.

Do not trust a client-provided user ID.

---

# 6. Backend Notification API Changes

Existing routes:

```text
GET    /api/notifications
PATCH  /api/notifications/read-all
PATCH  /api/notifications/:id/read
DELETE /api/notifications/:id
POST   /api/notifications/device-token
DELETE /api/notifications/device-token
```

Keep these endpoints because they are already mounted and used conceptually by the product.

## 6.1 Replace legacy token storage

Current:

```text
POST /device-token
  -> User.pushTokens
```

Target:

```text
POST /device-token
  -> PushToken upsert
```

Request:

```json
{
  "token": "FCM_TOKEN",
  "deviceId": "DEVICE_ID",
  "platform": "android",
  "appVersion": "1.0.4",
  "locale": "en"
}
```

Response:

```json
{
  "success": true,
  "registered": true
}
```

---

## 6.2 Token removal/deactivation

Current:

```text
DELETE /device-token
```

Target behavior:

```text
find authenticated user's token
      ↓
mark inactive or delete
```

Prefer `isActive=false` when maintaining auditability.

---

# 7. Flutter API Endpoint Additions

Current `frontend/lib/core/network/api_enpoints.dart` does not contain notification endpoints.

Add:

```text
notifications
markAllNotificationsRead
markNotificationRead(id)
deleteNotification(id)
registerDeviceToken
removeDeviceToken
```

Keep these in the centralized endpoint file.

Do not hard-code URLs inside notification services.

---

# 8. Flutter Notification Folder

Create:

```text
frontend/lib/core/notifications/
├── notification_service.dart
├── notification_permission_service.dart
├── notification_token_service.dart
├── notification_topic_service.dart
├── notification_router.dart
├── notification_payload.dart
└── notification_channels.dart
```

Recommended responsibility boundaries:

## `notification_service.dart`

Owns:

- Firebase Messaging initialization
- foreground message listener
- background message registration
- initial notification retrieval
- tap listener wiring
- local notification initialization
- forwarding parsed events

## `notification_permission_service.dart`

Owns:

- Android notification permission
- iOS authorization
- permission state
- timing of user prompt

## `notification_token_service.dart`

Owns:

- `getToken()`
- `onTokenRefresh`
- backend registration
- token cleanup
- device metadata

## `notification_topic_service.dart`

Owns:

- subscribe
- unsubscribe
- role topic lifecycle
- marketing topic lifecycle

## `notification_router.dart`

Owns:

- payload parsing
- authentication readiness
- route mapping
- pending action queue

## `notification_payload.dart`

Owns typed notification event representation.

Example:

```text
eventType
notificationId
entityType
entityId
bookingId
action
version
```

## `notification_channels.dart`

Owns Android channel IDs/names/importance.

---

# 9. Initialization Order

Current `main.dart`:

```text
WidgetsFlutterBinding.ensureInitialized()
FlutterNativeSplash.preserve(...)
AppPreferences.init()
FirebaseBootstrap.init()
ApiServices.init()
runApp()
```

Target conceptual order:

```text
WidgetsFlutterBinding.ensureInitialized()
FlutterNativeSplash.preserve(...)

AppPreferences.init()

FirebaseBootstrap.init()

ApiServices.init()

NotificationService.initialize()

runApp(...)
```

However:

### Important distinction

Initialization should not mean:

```text
immediately show permission dialog
```

Instead:

```text
initialize FCM infrastructure
        ↓
wait for app/session context
        ↓
ask permission at an intentional UX point
```

---

# 10. Notification Permission Strategy

Do not show the system permission dialog immediately on first launch.

Recommended sequence:

```text
first useful authenticated app experience
        ↓
Explain why Fixly uses notifications
        ↓
User chooses Enable Notifications
        ↓
System permission prompt
```

For example:

- after successful login
- after first successful customer booking
- after worker onboarding completes
- or from Settings

### Safety exception

Critical transactional/safety notifications should not be presented as optional marketing.

The UI should differentiate:

```text
Service / Booking alerts
System alerts
Promotions
```

rather than one generic “all notifications” switch.

---

# 11. Notification Preferences

Current preferences contain:

```text
pref_notifications_enabled
```

and `AppSessionCubit` exposes:

```text
notificationsEnabled
```

The Settings page currently also has:

- Push Notifications
- Booking Updates
- Discounts & Updates

but only the main notification preference is connected to persistent storage.

## Target preference model

Persist:

```text
transactionalNotificationsEnabled
systemNotificationsEnabled
marketingNotificationsEnabled
```

Recommended defaults:

```text
transactional = true
system = true
marketing = false
```

Critical safety events should continue to be handled as transactional/system events.

### Migration

Read the old:

```text
pref_notifications_enabled
```

once.

Use it to initialize the new preferences, then move to the new keys.

---

# 12. Notification Topics

Topics are appropriate only for broad, non-private messages.

Recommended topics:

```text
fixly_all
fixly_customers
fixly_workers
fixly_customers_marketing
fixly_workers_marketing
```

## Role lifecycle

Customer:

```text
subscribe fixly_all
subscribe fixly_customers
```

Worker:

```text
subscribe fixly_all
subscribe fixly_workers
```

Marketing:

```text
subscribe role marketing topic
```

only when marketing preference is enabled.

On logout:

```text
unsubscribe role topics
unsubscribe marketing topic
```

### Never use topics for:

- customer-specific booking data
- worker-specific job assignment
- payment status
- SOS
- KYC result
- payout result
- private support messages

Those use direct registration tokens.

---

# 13. Direct Token vs Topic Decision

| Event | Delivery |
|---|---|
| New booking available to eligible workers | Direct token |
| Booking assigned to one worker | Direct token |
| Booking accepted | Direct token |
| Worker arrival | Direct token |
| Job started | Direct token |
| Invoice/parts update | Direct token |
| Payment success/failure | Direct token |
| KYC decision | Direct token |
| Wallet credited | Direct token |
| Payout result | Direct token |
| SOS | Direct token |
| Support reply | Direct token |
| Maintenance | Topic |
| General system announcement | Topic |
| Customer promotion | Marketing topic |
| Worker promotion | Marketing topic |
| Broad platform announcement | Topic |

---

# 14. FCM Payload Contract

FCM notification payloads should be intentionally small.

## Data payload

Example:

```json
{
  "eventType": "BOOKING_ACCEPTED",
  "notificationId": "66f...",
  "entityType": "booking",
  "entityId": "66f...",
  "bookingId": "66f...",
  "action": "booking_details",
  "version": "1"
}
```

All FCM data values should be strings.

### Do not send:

- entire Booking document
- phone numbers
- addresses
- KYC documents
- payment signatures
- access tokens
- bank details
- full customer profile
- full worker profile

The Flutter app should use the IDs to fetch current data from the authenticated API.

---

# 15. Notification Event Catalog

Use stable machine-readable event types.

## Booking

```text
NEW_BOOKING_AVAILABLE
BOOKING_ASSIGNED
BOOKING_ACCEPTED
BOOKING_DECLINED
BOOKING_UPDATED
BOOKING_CANCELLED
```

## Job lifecycle

```text
WORKER_ARRIVED
JOB_STARTED
PARTS_ADDED
INVOICE_UPDATED
JOB_COMPLETED
```

## Payment

```text
PAYMENT_PENDING
PAYMENT_SUCCESS
PAYMENT_FAILED
PAYMENT_RECEIVED
```

## Verification

```text
KYC_SUBMITTED
KYC_APPROVED
KYC_REJECTED
CERTIFICATE_APPROVED
CERTIFICATE_REJECTED
```

## Worker wallet / payouts

```text
WALLET_CREDITED
PAYOUT_REQUESTED
PAYOUT_PROCESSING
PAYOUT_PAID
PAYOUT_REJECTED
```

## Support / safety

```text
SOS_ALERT
SUPPORT_REPLY
SUPPORT_STATUS_UPDATED
```

## Platform

```text
SYSTEM_ANNOUNCEMENT
MAINTENANCE
PROMOTION
```

---

# 16. Critical Audit Finding — Booking Status Names

The backend currently uses:

```text
PENDING
SEARCHING
APPROVED
ACCEPTED
ARRIVED
IN_PROGRESS
COMPLETED
CANCELLED
```

but the Flutter `BookingStatus` enum is:

```text
draft
searching
accepted
arrived
inProgress
completed
paid
```

The most important mismatch is:

```text
Backend worker acceptance:
APPROVED

Flutter semantic state:
accepted
```

Do not fix this by making FCM use raw statuses directly.

Create a centralized event/status mapping.

Example:

```text
APPROVED
  -> BOOKING_ACCEPTED
```

The payload should describe the business event, not expose backend implementation inconsistencies.

---

# 17. Notification Trigger Architecture

Do not put FCM send code directly into every controller.

Controllers should call:

```text
NotificationService
```

which creates the durable notification record and queues delivery.

Target:

```text
Controller
   ↓
NotificationService.createAndQueue(...)
   ↓
Mongo Notification
   ↓
BullMQ Notification Job
   ↓
Notification Worker
   ↓
FCM Service
   ↓
Firebase
```

---

# 18. Backend Notification Service

Create:

```text
backend/services/notificationService.js
```

Responsibilities:

1. Resolve recipient.
2. Create Notification document.
3. Generate stable dedupe key.
4. Decide delivery channels.
5. Queue push delivery.
6. Optionally queue email.
7. Avoid duplicate notifications.
8. Log/record delivery state.

Example conceptual method:

```text
notifyUser(...)
notifyUsers(...)
notifyWorkers(...)
broadcast(...)
```

### Important

Business controllers should not need to know Firebase Admin APIs.

Bad:

```text
controller -> firebaseAdmin.messaging().send(...)
```

Good:

```text
controller -> notificationService.notifyUser(...)
```

---

# 19. Notification Templates

Create:

```text
backend/services/notificationTemplates.js
```

Templates should translate business events into:

```text
title
body
category
priority
eventType
entityType
action
channel
```

Example:

```text
BOOKING_ACCEPTED
title: Worker accepted your booking
body: Your Fixly worker has accepted the service request.
category: BOOKING
priority: High
```

Templates should avoid hard-coded controller-specific wording.

---

# 20. Firebase Admin SDK

Install backend dependency:

```text
firebase-admin
```

Only in:

```text
backend/
```

Never add the Firebase Admin service-account JSON to Flutter.

---

# 21. Firebase Admin Configuration

Create:

```text
backend/config/firebase.js
```

Preferred authentication strategy:

### Production

Use:

- Application Default Credentials
- workload identity
- managed secret
- platform secret manager

### Local development

Use a secure environment variable or local credential file outside Git.

Never commit:

```text
service-account.json
private key
client secret
```

Add credentials to `.gitignore` and deployment secret configuration.

---

# 22. FCM Service

Create:

```text
backend/services/fcmService.js
```

Responsibilities:

- send to one token
- send to multiple tokens
- send to topic
- normalize Firebase errors
- detect invalid/unregistered tokens
- retry transient failures
- return structured delivery result

Conceptual methods:

```text
sendToToken(...)
sendToTokens(...)
sendToTopic(...)
```

FCM service must not know anything about bookings, invoices, KYC, or users beyond messaging inputs.

---

# 23. BullMQ Notification Queue

The backend already uses BullMQ and Redis.

Reuse:

```text
backend/config/redis.js
```

and the existing worker architecture.

Create:

```text
backend/queues/notificationQueue.js
backend/worker/notificationWorker.js
```

Target:

```text
API/controller
   ↓
NotificationService
   ↓
notificationQueue
   ↓
notificationWorker
   ↓
fcmService
```

---

# 24. Queue Job Design

Suggested job payload:

```json
{
  "notificationId": "66f...",
  "recipientUserId": "66f...",
  "eventType": "BOOKING_ACCEPTED",
  "channel": "PUSH"
}
```

Avoid placing full customer/worker/booking documents in Redis jobs.

The worker can fetch the Notification and PushToken records.

---

# 25. Retry Strategy

Notification delivery failures must not roll back business operations.

Example:

```text
Attempt 1
Attempt 2
Attempt 3
```

with exponential/backoff delay.

Separate:

### Transient errors

Retry:

- temporary Firebase/server error
- network failure
- provider unavailable

### Permanent token errors

Do not keep retrying:

- unregistered token
- invalid token
- invalid argument

Mark token:

```text
isActive = false
```

---

# 26. Idempotency / Deduplication

Every event that can be emitted more than once should have a stable dedupe key.

Examples:

```text
BOOKING_ACCEPTED:<bookingId>:<workerId>

PAYMENT_SUCCESS:<bookingId>:<razorpayPaymentId>

KYC_APPROVED:<workerId>:<verificationUpdatedAt>

PAYOUT_PAID:<payoutId>
```

Add a unique/indexed `dedupeKey` where appropriate.

Before creating a notification:

```text
Does this event already exist?
        ↓ yes
Do not create again.
        ↓ no
Create and queue.
```

This is especially important because:

- Razorpay verification may be retried.
- Socket/API calls may be repeated.
- Admin actions may be repeated.
- queue workers may retry.

---

# 27. Booking Integration — Exact Existing Trigger Points

## 27.1 `createBooking`

Current flow:

```text
create Booking
status = PENDING
emit Socket.IO event
return response
```

### Required change

After booking is committed:

### Case A — direct worker

```text
workerId exists
    ↓
create BOOKING_ASSIGNED notification
    ↓
queue FCM to that worker's PushToken records
```

### Case B — worker discovery/open pool

Do NOT send the full booking to:

```text
fixly_workers
```

Instead calculate eligible workers on the backend.

---

# 28. New Booking Worker Eligibility

The existing worker incoming API already applies:

- worker role
- worker location
- booking location
- service/category relation
- radius
- open booking status

The FCM recipient resolver should reuse the same business rules.

### Candidate filters

At minimum:

```text
role == worker
isVerified == true
workerProfile exists
workerProfile.isOnline == true
worker is not already busy
worker has matching category/skill
worker location exists
distance <= worker service radius / configured search radius
booking remains PENDING/SEARCHING
```

Then:

```text
find eligible workers
       ↓
get active PushTokens
       ↓
create notification per worker
       ↓
queue direct token delivery
```

### Important

Notification targeting must never trust:

```text
worker-provided client filter
```

The server decides eligibility.

---

# 29. Worker Accepts Booking

Current `acceptBooking` does:

```text
Redis lock
Mongo atomic update
status = APPROVED
worker = current worker
Socket.IO updates
```

After successful Mongo update:

```text
BOOKING_ACCEPTED
```

Recipient:

```text
booking.customer
```

The worker does not need a “you accepted” push because the worker performed the action.

---

# 30. Other Workers When a Booking Is Claimed

Current backend emits:

```text
booking:claimed
```

globally through Socket.IO.

Do not mirror this as an FCM broadcast.

The remaining workers can continue receiving live Socket.IO state.

If an individual worker needs a specific push, generate a direct event intentionally rather than broadcasting job claims globally.

---

# 31. Worker Declines Booking

Current `declineBooking` only stores:

```text
declineReason
declinedBy
```

and emits Socket.IO.

Recommended notification behavior:

- customer notification only if the booking workflow actually needs to communicate that worker decline.
- if another worker search is automatic, use event:

```text
BOOKING_UPDATED
```

or a dedicated business event if product semantics require it.

Do not generate noisy pushes for every declined attempt.

---

# 32. Booking Cancellation

Current cancellation:

```text
booking.status = CANCELLED
redis tracking deleted
Socket.IO notification
worker availability update
```

Add:

```text
BOOKING_CANCELLED
```

Recipient(s):

- customer if cancellation was performed by worker/admin/system
- worker if cancellation was performed by customer/admin/system

The event direction should depend on who performed the action.

---

# 33. Worker Arrival

Current:

```text
verifyArrivalOtp
booking.status = ARRIVED
Socket.IO booking room
```

After successful persistence:

```text
WORKER_ARRIVED
```

Recipient:

```text
customer
```

---

# 34. Job Started

Current:

```text
startJob
status = IN_PROGRESS
jobStartedAt = Date.now()
Socket.IO
```

Add:

```text
JOB_STARTED
```

Recipient:

```text
customer
```

---

# 35. Extra Parts / Invoice Update

Current:

```text
addExtraParts
update addOns
recalculate invoice
Socket.IO
```

Add:

```text
PARTS_ADDED
INVOICE_UPDATED
```

These can be represented as one push to avoid duplicate OS alerts:

```text
eventType = INVOICE_UPDATED
```

while Mongo notification `data` contains the entity ID.

The detailed invoice remains fetched from REST API.

---

# 36. Payment Integration — Important Security Boundary

Current payment flow:

```text
Flutter opens Razorpay
      ↓
Flutter receives Razorpay result
      ↓
Flutter calls backend verify
      ↓
backend checks HMAC signature
      ↓
Transaction success
      ↓
booking invoice = PAID
      ↓
worker wallet credited
      ↓
job completed
```

FCM events must begin only after the backend has verified and persisted the payment.

### Never send:

```text
PAYMENT_SUCCESS
```

from a Flutter Razorpay callback.

The server is authoritative.

---

# 37. Payment Success

In `verifyPayment`, after:

```text
transaction.status = success
booking.invoice.paymentStatus = PAID
booking.invoice.transactionId = paymentId
wallet credit completed
```

generate:

```text
PAYMENT_SUCCESS
```

Recipient:

```text
customer
```

and optionally:

```text
PAYMENT_RECEIVED
```

for the worker.

Then `finalizeJobAfterPayment()` emits completion behavior.

---

# 38. Job Completion After Payment

The current server calls:

```text
finalizeJobAfterPayment(...)
```

and marks booking:

```text
COMPLETED
```

This is the right source for:

```text
JOB_COMPLETED
```

Recipient:

- customer
- worker

Avoid sending two nearly identical completion notifications through different code paths.

There are currently two completion implementations:

- `activeJobController.completeJob`
- `paymentController.finalizeJobAfterPayment`

The plan should ensure they eventually funnel notification creation into one reusable domain notification helper.

---

# 39. Payment Failure

Invalid Razorpay signature currently sets:

```text
transaction.status = failed
invoice.paymentStatus = FAILED
```

After the failure is persisted:

```text
PAYMENT_FAILED
```

Recipient:

```text
customer
```

Do not send a push before signature validation.

---

# 40. Worker Wallet

Current `creditWorkerWallet()` is already idempotent against `paymentId`.

After wallet credit succeeds:

```text
WALLET_CREDITED
```

Recipient:

```text
worker
```

Dedupe key:

```text
WALLET_CREDITED:<paymentId>
```

---

# 41. Payout System — Current Gap

Current `PayoutRequest` supports:

```text
requested
processing
paid
rejected
```

`requestWithdraw()` creates:

```text
status = requested
```

The admin API currently exposes payout listing but no dedicated admin status update endpoint in the audited routes.

Therefore FCM support for payouts requires both:

1. notification implementation
2. explicit server-side payout status mutation endpoints/actions

Recommended admin actions:

```text
PATCH /api/admin/worker-payouts/:id/status
```

with validated transitions:

```text
requested -> processing
processing -> paid
processing -> rejected
```

After each successful persistence:

```text
PAYOUT_REQUESTED
PAYOUT_PROCESSING
PAYOUT_PAID
PAYOUT_REJECTED
```

Recipient:

```text
payout.worker
```

---

# 42. KYC / Verification

Current worker KYC flow:

```text
submitVerification
   -> kycDocuments.status = submitted
```

Admin review flow:

```text
adminReviewWorkerVerification
   -> kyc status
   -> isVerified
```

### Events

After worker submission:

```text
KYC_SUBMITTED
```

Recipient:

```text
admin/system audience only if the product requires it
```

This does not need to be an FCM push to ordinary workers.

After admin review:

```text
KYC_APPROVED
KYC_REJECTED
```

Recipient:

```text
worker
```

For rejection, notification data should only point the app to the verification screen. Do not put full rejection details into a global payload.

---

# 43. Worker Certificate Review

Current admin review supports:

```text
submitted
approved
rejected
```

After persistence:

```text
CERTIFICATE_APPROVED
CERTIFICATE_REJECTED
```

Recipient:

```text
worker
```

---

# 44. Support

Current support system supports:

- customer/worker tickets
- ticket messages
- admin ticket management

Current `addTicketMessage()` can be executed by either the ticket owner or admin.

### Notification behavior

If admin sends a message:

```text
SUPPORT_REPLY
```

Recipient:

```text
ticket.createdBy
```

If the customer/worker writes their own message:

Do not push to themselves.

If a support state changes significantly:

```text
SUPPORT_STATUS_UPDATED
```

may be sent.

---

# 45. SOS / Safety

Current SOS:

```text
POST /api/bookings/:bookingId/sos
```

emits to the booking room.

This is currently only Socket.IO and does not show persistent notification targeting.

### Required design

SOS must be treated as a **direct targeted safety event**.

Possible recipients:

- worker/customer counterpart
- designated emergency staff
- configured emergency contact workflow if implemented
- support/safety admin channel

Never:

```text
fixly_all
fixly_customers
fixly_workers
```

for a private SOS.

Create:

```text
SOS_ALERT
```

with highest notification priority.

Persist a MongoDB notification for every actual in-product recipient.

---

# 46. Admin Notifications

Current admin feature:

```text
POST /api/admin/notifications/broadcast
```

creates a Notification record and emits a Socket.IO event.

It can target broad audiences, but current implementation does not actually perform FCM delivery.

### Replace/extend with NotificationService

Admin action:

```text
broadcast
     ↓
NotificationService
     ↓
Mongo Notification
     ↓
topic or direct token selection
     ↓
BullMQ
```

### Target audience mapping

```text
All Users
    -> fixly_all

Workers Only
    -> fixly_workers

Customers Only
    -> fixly_customers

Specific User
    -> direct token

Specific Email
    -> email only / direct user resolution when applicable
```

Do not blindly use `fixly_workers` if the notification contains private worker data.

---

# 47. Admin Socket.IO Compatibility

Keep the existing Socket.IO admin event:

```text
admin_notification
```

during migration.

The final behavior can be:

```text
Mongo Notification
   ├── FCM
   └── Socket.IO (when appropriate)
```

This supports users who currently have the app open.

However, do not make Socket.IO and FCM two separate business notification generators.

Both should be outputs of the same notification event.

---

# 48. Flutter Foreground Behavior

When the app is in foreground:

```text
FirebaseMessaging.onMessage
```

receives the event.

The app should:

1. parse notification data
2. determine whether user should see an OS-style alert
3. show local notification where appropriate
4. update/invalidate relevant UI state
5. optionally insert the notification into in-memory notification state

Use:

```text
flutter_local_notifications
```

for foreground presentation.

---

# 49. Avoid Foreground / Background Double Alerts

The design must distinguish:

### Foreground

App receives:

```text
onMessage
```

and shows a local notification.

### Background / terminated

FCM notification payload can be rendered by the OS.

Do not make the Flutter background handler also show another local notification for the same message unless the payload strategy explicitly requires it.

Otherwise users will see duplicates.

---

# 50. Background Message Handler

FCM background handlers must be implemented according to Flutter/Firebase requirements.

Use a top-level function.

Conceptually:

```text
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(...)
```

Keep background processing minimal.

Do not:

- open complex UI
- depend on active BuildContext
- assume router is available
- make unnecessary API calls
- process the entire booking object

---

# 51. Notification Tap Handling

Handle:

```text
FirebaseMessaging.instance.getInitialMessage()
```

for terminated launch.

And:

```text
FirebaseMessaging.onMessageOpenedApp
```

for background-to-foreground tap.

Also handle taps from local notifications.

---

# 52. Pending Notification Action

A notification may be opened before:

- Firebase startup completes
- `ApiServices` is ready
- auth restoration completes
- GoRouter is mounted

Therefore:

```text
incoming notification
      ↓
parse payload
      ↓
store pending action
      ↓
wait for session/router readiness
      ↓
validate user role
      ↓
navigate
```

Do not call `context.go(...)` from an FCM callback without checking readiness.

---

# 53. Notification Routing Matrix

Use real existing `RouteNames`.

## Booking detail

```text
RouteNames.bookingDetailPath(bookingId)
```

for generic/shared booking detail.

## Customer flows

Possible targets:

```text
customerTracking
customerWorkerAccepted
customerWorkerArrived
customerWorkStarted
customerPayment
customerInvoice
customerBookingConfirmation
```

Do not always deep-link into a flow screen that expects ephemeral Cubit state.

When in doubt:

```text
notification
  -> booking detail
  -> REST fetch
  -> app continues from current server state
```

This is more robust after a cold start.

## Worker flows

Use:

```text
workerJobDetail
workerActiveJob
workerWallet
workerEarnings
workerOnboardingStatus
```

again based on event type.

---

# 54. Deep-Link Safety

Before routing from notification payload:

1. Validate the user is authenticated.
2. Validate user role.
3. Validate `entityId`.
4. Fetch entity via authenticated API.
5. Let the API verify user has access.
6. Only then show sensitive data.

Never trust:

```text
bookingId
```

just because it came from an FCM message.

---

# 55. Flutter Notification Inbox

Current `NotificationsCubit` is still mock-backed.

Current flow:

```text
NotificationsCubit
   -> MockRepository
   -> fake delay
   -> Mock notification list
```

This must be replaced.

Target:

```text
NotificationsCubit
   -> NotificationsApiRepository
   -> ApiClient
   -> /api/notifications
```

---

# 56. Notification Repository

Create:

```text
frontend/lib/features/shared/data/notifications_api_repository.dart
```

Methods:

```text
list(page, limit)
markRead(id)
markAllRead()
delete(id)
```

Potential future methods:

```text
getUnreadCount()
```

---

# 57. Notification Model Upgrade

Current `NotificationItem` contains only:

```text
id
title
body
time
read
```

Expand it to include:

```text
id
title
body
createdAt
read
category
eventType
priority
entityType
entityId
bookingId
action
data
```

Keep the model tolerant of missing legacy fields.

---

# 58. Notification Page Migration

Current page:

```text
NotificationsPage
```

already displays the notification list and has “Mark all read”.

Change it to:

```text
REST-backed list
```

Add:

- pull-to-refresh
- pagination or infinite scroll
- individual read state
- individual open/tap
- delete
- meaningful timestamp
- empty state
- loading/error/retry
- notification category treatment

---

# 59. Notification Click Inside Inbox

An inbox item should use its same notification metadata to route:

```text
tap
  -> mark read
  -> notificationRouter.handle(...)
```

Do not duplicate routing rules in the widget.

---

# 60. Live Inbox Updates

When a push event is received while the app is open:

Preferred flow:

```text
FCM
  -> notification service
  -> invalidate/reload notification list
```

or insert a lightweight notification object if all data is already available.

MongoDB is the source of truth, so the safest implementation is:

```text
FCM received
   ↓
fetch/refresh notification inbox
```

Do not permanently store only the local notification.

---

# 61. Socket.IO and FCM Coexistence

Current Flutter booking flow opens a Socket.IO connection and also polls every five seconds.

This behavior should remain unless separately refactored.

Notification design:

```text
Socket.IO
  -> immediate state refresh
  -> booking screen live updates

FCM
  -> OS alert
  -> cold/background wake-up
  -> navigation trigger

REST
  -> authoritative booking state
```

This is intentionally redundant.

The redundancy improves resilience.

---

# 62. Current Socket.IO Security Consideration

`backend/sockets/tracking.js` currently allows:

```text
join_booking_room
```

without an obvious room authorization check.

FCM does not solve this.

The notification implementation should not assume Socket.IO is a secure private channel just because it uses booking room names.

A later hardening task should validate that the authenticated socket user actually belongs to the booking room.

For FCM:

- authenticated REST API controls data access
- tokens are tied to users
- payload contains IDs only

---

# 63. Android Configuration

Current:

```text
frontend/android/app/src/main/AndroidManifest.xml
```

already declares:

```text
INTERNET
ACCESS_FINE_LOCATION
ACCESS_COARSE_LOCATION
```

Add notification permission as required by current Android target SDK:

```text
POST_NOTIFICATIONS
```

Use notification channels.

Recommended channel IDs:

```text
fixly_booking
fixly_worker_jobs
fixly_payment
fixly_safety
fixly_general
```

Map each event to one channel.

---

# 64. Android Notification Priority

Suggested priorities:

### Safety

```text
Very High
```

### Active booking/job

```text
High
```

### Payment

```text
High
```

### System

```text
Default
```

### Marketing

```text
Low / default
```

Do not make every notification high priority.

---

# 65. Android Small Icon

FCM/local notifications require a valid monochrome notification status icon.

Add a dedicated:

```text
fixly_notification
```

icon to Android resources.

Do not rely on a multicolor launcher icon.

---

# 66. Android Gradle

Current `frontend/android/app/build.gradle.kts` conditionally applies:

```text
com.google.gms.google-services
```

when local `google-services.json` exists.

Confirm the Firebase messaging plugin integration remains compatible with the final Gradle/Firebase plugin versions.

Do not add duplicate Firebase initialization logic.

---

# 67. iOS Configuration

Current:

```text
frontend/ios/Runner/AppDelegate.swift
```

is minimal and delegates plugin registration.

Current `Info.plist` has:

- location permissions
- camera/photo permissions
- Google Sign-In configuration
- Firebase config asset in the Flutter project

### Required FCM setup

Enable in Apple project:

```text
Push Notifications capability
Background Modes
Remote notifications
```

Configure APNs in Firebase Console.

For production notifications, test on a real iOS device.

Simulator-only testing is insufficient for the full APNs/FCM delivery path.

---

# 68. iOS Notification Permission

Request via Firebase Messaging after the app has established useful context.

Handle authorization states:

```text
authorized
provisional
denied
notDetermined
```

Settings should direct users to system notification settings when appropriate.

---

# 69. Localization

Fixly already supports:

```text
en
hi
```

and the User model already stores:

```text
preferredLanguage
```

Notification templates should eventually support the user's preferred language.

Recommended first implementation:

```text
Notification template key
      ↓
language selection
      ↓
localized title/body
```

Do not store only UI-local English strings.

The backend should be able to choose the language when creating the Mongo notification if the notification is user-specific.

For broad topic notifications, either:

- use a neutral language
- use localized topic variants later
- or keep marketing/system localization as a future enhancement

---

# 70. Notification Category Consistency

Current `Notification.category` enum contains mixed casing/legacy values:

```text
BOOKING
PAYMENT
...
Emergency
Payments
System
Surge
General
```

Normalize to stable uppercase codes.

Example:

```text
BOOKING
PAYMENT
VERIFICATION
SUPPORT
SAFETY
SYSTEM
PROMOTION
WALLET
PAYOUT
```

Keep compatibility mapping for old records.

This avoids Flutter conditional logic such as:

```text
if category == "Payments"
```

vs.

```text
if category == "PAYMENT"
```

---

# 71. Notification Priority Consistency

Current backend priority enum has:

```text
High
Medium
Normal
Urgent
Emergency
Low
```

Normalize internally to a stable set:

```text
LOW
NORMAL
HIGH
URGENT
EMERGENCY
```

Map old values when reading existing records.

---

# 72. Notification Creation Rules

Every durable notification should have:

```text
recipient
eventType
title
body/message
category
priority
entityType
entityId
data
createdAt
```

Only create a Mongo Notification if the product actually needs an inbox item.

For ephemeral system messages, topic push can be used without creating millions of individual records.

---

# 73. Broad Topic Notification Strategy

For:

```text
MAINTENANCE
SYSTEM_ANNOUNCEMENT
PROMOTION
```

the architecture may use:

```text
Mongo admin record
+
topic FCM
+
Socket.IO live announcement
```

Do not create one Mongo notification per user for large broadcasts unless the product explicitly requires per-user inbox history.

For user-visible inbox requirements at large scale, consider a separate broadcast/read model in a future optimization.

For the first production implementation, keep broad broadcasts simple and explicit.

---

# 74. New Booking Notification Scalability

`NEW_BOOKING_AVAILABLE` is the most important FCM scaling case.

Do not:

```text
for every worker:
    send notification
```

from a controller synchronously.

Instead:

```text
Booking created
     ↓
NotificationService
     ↓
resolve eligible workers
     ↓
batch recipient token lookup
     ↓
create queued notification jobs
     ↓
FCM worker sends in batches
```

Use FCM multicast/batch capabilities where appropriate.

---

# 75. Avoid Notification Storms

A single booking may cause:

```text
created
assigned
accepted
arrived
started
parts added
payment
completed
```

This can become noisy.

Define which events are:

```text
push + inbox
push only
inbox only
Socket only
```

Suggested:

| Event | Push | Inbox | Socket |
|---|---|---|---|
| New booking | Yes | Yes for targeted worker | Yes |
| Accepted | Yes | Yes | Yes |
| Arrived | Yes | Yes | Yes |
| Started | Yes | Yes | Yes |
| Parts update | Yes/controlled | Yes | Yes |
| Payment success | Yes | Yes | Yes |
| Completed | Yes | Yes | Yes |
| Live GPS | No | No | Yes |
| Worker claimed broadcast | No | No | Yes |

---

# 76. Live GPS Must Never Use FCM

Current live location uses:

```text
worker_location_update
```

and Redis cache.

Keep it that way.

Never use FCM for:

- continuous location
- heading
- live tracking
- frequent ETA updates

FCM is not a realtime telemetry channel.

---

# 77. Backend Error Isolation

A booking should still succeed when FCM is unavailable.

Example:

```text
Booking.create()
   succeeds
   ↓
NotificationService queues push
   ↓
FCM service fails
   ↓
retry/failure logged
```

The API response must still be:

```text
booking successfully created
```

Do not wrap business transaction logic in a “must send FCM” condition.

---

# 78. Notification Delivery Observability

Add structured logs:

```text
notificationId
eventType
recipientUserId
token/device
channel
attempt
status
error code
latency
```

Do not log:

- full FCM tokens
- secrets
- user passwords
- sensitive payment data

Mask token values in logs.

---

# 79. Admin Notification Monitoring

Add backend/admin visibility for:

```text
pending
sent
failed
skipped
```

Potential admin metrics:

```text
FCM send success rate
invalid token count
notification queue backlog
failed notification count
average push latency
```

This is especially valuable when users report “I did not receive my booking notification.”

---

# 80. Token Cleanup

When FCM returns permanent token errors:

```text
isActive = false
```

Do not delete blindly because a token may be useful for audit/debugging.

A periodic cleanup can later remove old inactive tokens.

---

# 81. Security Rules

Never put these in FCM payloads:

```text
JWT access token
refresh token
Razorpay secret
Razorpay signature
bank account
UPI credentials
KYC document number
KYC images
private address
full phone number
```

FCM payloads are transport data, not a secure database.

---

# 82. Notification API Authorization

Existing notification routes use:

```text
router.use(protect)
```

Keep this.

Every user notification endpoint must filter by:

```text
recipient = req.user.id
```

Never allow:

```text
GET /notifications/:otherUsersId
```

style access.

---

# 83. Admin Notification Authorization

Keep admin routes behind:

```text
adminProtect
```

Do not reuse ordinary user notification authorization for admin broadcast endpoints.

---

# 84. Backend Domain Helper for State Transitions

The current backend performs booking mutations directly in multiple controllers.

To avoid duplicated notification logic, introduce small reusable helpers.

Conceptually:

```text
emitBookingEvent({
    booking,
    eventType,
    actor,
    metadata
})
```

This helper can decide:

- recipient
- Mongo notification
- Socket.IO event
- FCM delivery

However, keep business logic and transport logic separated enough that one channel can fail without affecting another.

---

# 85. Recommended Backend File Structure

Final:

```text
backend/
├── config/
│   ├── firebase.js
│   ├── db.js
│   ├── redis.js
│   └── socket.js
│
├── controllers/
│   ├── bookingController.js
│   ├── activeJobController.js
│   ├── paymentController.js
│   ├── notificationController.js
│   ├── verificationController.js
│   ├── workerCertificateController.js
│   ├── workerWalletController.js
│   ├── supportController.js
│   └── adminController.js
│
├── models/
│   ├── Notification.js
│   ├── PushToken.js
│   ├── PayoutRequest.js
│   └── ...
│
├── services/
│   ├── fcmService.js
│   ├── notificationService.js
│   └── notificationTemplates.js
│
├── queues/
│   └── notificationQueue.js
│
├── worker/
│   ├── notificationWorker.js
│   ├── emailWorker.js
│   └── uploadWorker.js
│
└── ...
```

---

# 86. Recommended Flutter File Structure

```text
frontend/lib/
├── core/
│   ├── auth/
│   ├── firebase/
│   ├── network/
│   ├── preferences/
│   └── notifications/
│       ├── notification_service.dart
│       ├── notification_permission_service.dart
│       ├── notification_token_service.dart
│       ├── notification_topic_service.dart
│       ├── notification_router.dart
│       ├── notification_payload.dart
│       └── notification_channels.dart
│
├── features/
│   ├── auth/
│   ├── shared/
│   │   ├── data/
│   │   │   └── notifications_api_repository.dart
│   │   ├── presentation/
│   │   │   ├── cubit/
│   │   │   │   ├── notifications_cubit.dart
│   │   │   │   └── notifications_state.dart
│   │   │   └── pages/
│   │   │       └── notifications_page.dart
│   ├── customer/
│   └── worker/
```

---

# 87. Exact Flutter Files Expected to Change

## Core

```text
frontend/lib/main.dart
frontend/lib/core/firebase/firebase_bootstrap.dart
frontend/lib/core/network/api_enpoints.dart
frontend/lib/core/preferences/app_preferences.dart
```

## New

```text
frontend/lib/core/notifications/*
frontend/lib/features/shared/data/notifications_api_repository.dart
```

## Auth

```text
frontend/lib/features/auth/presentation/cubit/app_session_cubit.dart
frontend/lib/features/auth/presentation/cubit/app_session_state.dart
```

Potentially:

```text
frontend/lib/features/auth/data/auth_api_repository.dart
```

only when lifecycle boundaries require it.

## Models

```text
frontend/lib/shared/models/models.dart
```

## Notification UI

```text
frontend/lib/features/shared/presentation/cubit/notifications_cubit.dart
frontend/lib/features/shared/presentation/cubit/notifications_state.dart
frontend/lib/features/shared/presentation/pages/notifications_page.dart
```

## Settings

```text
frontend/lib/features/shared/presentation/pages/settings_page.dart
```

## Routing

```text
frontend/lib/app/router/app_router.dart
frontend/lib/app/router/route_names.dart
```

## Booking/payment state

Only when notification-triggered refresh/navigation requires it:

```text
frontend/lib/features/customer/presentation/cubit/booking_flow_cubit.dart
frontend/lib/features/worker/presentation/cubit/job_feed_cubit.dart
frontend/lib/features/worker/presentation/cubit/active_job_cubit.dart
```

Do not put Firebase code into these Cubits.

---

# 88. Exact Backend Files Expected to Change

## Dependencies

```text
backend/package.json
backend/package-lock.json
```

## Startup

```text
backend/server.js
```

## Models

```text
backend/models/Notification.js
backend/models/User.js
backend/models/PayoutRequest.js
backend/models/PushToken.js
```

`User.js` should be changed carefully because it is a central schema.

## Existing controllers

```text
backend/controllers/bookingController.js
backend/controllers/activeJobController.js
backend/controllers/paymentController.js
backend/controllers/verificationController.js
backend/controllers/workerCertificateController.js
backend/controllers/workerWalletController.js
backend/controllers/supportController.js
backend/controllers/adminController.js
backend/controllers/notificationController.js
```

Only add notification orchestration; do not move unrelated business logic.

## Routes

Potentially:

```text
backend/routes/notification-routes.js
backend/routes/admin-routes.js
```

especially for payout state mutations and future admin notification controls.

## New

```text
backend/config/firebase.js
backend/services/fcmService.js
backend/services/notificationService.js
backend/services/notificationTemplates.js
backend/queues/notificationQueue.js
backend/worker/notificationWorker.js
```

---

# 89. Environment Configuration

Add backend environment configuration documentation such as:

```text
FCM_PROJECT_ID
FCM_CLIENT_EMAIL
FCM_PRIVATE_KEY
```

only when using environment credentials.

Alternative production authentication:

```text
Google Application Default Credentials
```

should be preferred.

Document which approach each environment uses:

```text
local
development
staging
production
```

Never commit actual credential values.

---

# 90. Firebase Console Setup Checklist

Project:

```text
same Firebase project already used by Fixly Firebase Core
```

### Android

Verify:

```text
package name = com.example.fixly
Firebase Android app registered
google-services.json matches project
Cloud Messaging available
```

### iOS

Verify:

```text
bundle identifier matches Firebase app
GoogleService-Info.plist matches
APNs authentication configured
Push Notifications capability enabled
Background Modes/remote notifications enabled
```

### Backend

Enable Firebase Admin access to the same Firebase project.

---

# 91. Flutter Dependencies

Add:

```text
firebase_messaging
flutter_local_notifications
```

Use versions compatible with the repository's current:

```text
firebase_core
Dart SDK
Flutter SDK
Android Gradle setup
iOS deployment target
```

Do not blindly copy old tutorial versions.

Before implementation, run package resolution and verify compatibility in the repository's actual toolchain.

---

# 92. Notification Channel Design

Recommended channel configuration:

```text
fixly_booking
  importance: high

fixly_worker_jobs
  importance: high

fixly_payment
  importance: high

fixly_safety
  importance: max/high as platform allows

fixly_general
  importance: default
```

Marketing may share:

```text
fixly_general
```

or use a dedicated low-importance channel if product UX benefits from it.

---

# 93. Notification Actions

Payload action examples:

```text
booking_details
booking_tracking
worker_job
invoice
payment
wallet
verification
support_ticket
system
```

Do not encode widget implementation details in FCM.

The router translates:

```text
action + entityType
```

into a route.

---

# 94. Versioned Payloads

Every payload should include:

```text
version=1
```

so future clients can understand older/newer server payloads.

Example:

```json
{
  "eventType": "PAYMENT_SUCCESS",
  "entityType": "booking",
  "entityId": "123",
  "bookingId": "123",
  "notificationId": "456",
  "action": "booking_invoice",
  "version": "1"
}
```

---

# 95. API-First Navigation Rule

When a user taps a notification:

```text
notification ID / booking ID
        ↓
open relevant page
        ↓
page fetches server state
        ↓
render current state
```

Do not reconstruct booking state from push payload.

This protects against stale notification data.

---

# 96. Notification Inbox vs Push Alert

A push notification and a MongoDB notification are related but not identical.

Example:

```text
PAYMENT_SUCCESS

Mongo:
  title
  body
  createdAt
  unread = true
  data.bookingId

FCM:
  title/body
  bookingId
  notificationId
```

The notification ID connects push and inbox.

---

# 97. Read State

When a user taps a push:

```text
mark Mongo notification read
```

When a user opens the inbox:

```text
show unread state
```

When “Mark all read” is pressed:

```text
PATCH /api/notifications/read-all
```

Use server state as truth.

---

# 98. Unread Badge

Future enhancement:

Expose:

```text
unreadCount
```

from backend, or calculate efficiently.

Show a badge on:

```text
notification icon
```

in customer/worker shells.

Avoid repeatedly downloading the entire notification list only to calculate count.

---

# 99. Current Mock Repository Migration

Do not remove mock notifications until the real repository path is working.

Suggested migration:

```text
Phase 1:
real Notification API repository

Phase 2:
NotificationsCubit uses API

Phase 3:
remove mock notification dependency

Phase 4:
delete notification mock data
```

This lets other mock-driven UI remain untouched.

---

# 100. Booking Refresh After Push

A background/terminated booking push should not attempt to rebuild a complete booking flow.

Example:

```text
BOOKING_ACCEPTED
```

should route to:

```text
BookingDetailPage
```

which fetches:

```text
GET /api/bookings/:bookingId
```

Then the user can continue from the actual backend status.

This is safer than trying to set `BookingFlowCubit.step` directly from an FCM callback.

---

# 101. Worker Push and Active Job

Similarly:

```text
JOB_STARTED
```

should route to the worker active-job surface.

The active page already fetches active jobs through `BookingsApiRepository`.

Use that as the data source.

---

# 102. App Session + Notification Service Coupling

Avoid:

```text
NotificationService -> AppSessionCubit
```

strong coupling where possible.

Prefer:

```text
AppSessionCubit
    -> NotificationService.onAuthenticated(user)

AppSessionCubit
    -> NotificationService.onSignedOut()
```

or a small coordinator layer.

The notification service should know only what it needs:

```text
userId
role
locale
```

---

# 103. Router Readiness Contract

The notification router needs an explicit readiness concept:

```text
authReady
routerReady
```

Only process pending actions after both are ready.

Possible lifecycle:

```text
main()
  ↓
App created
  ↓
AppSessionCubit.restoreSession()
  ↓
router available
  ↓
NotificationRouter.flushPending()
```

---

# 104. Cold Start Race Condition to Test

Test:

```text
App is terminated
FCM notification arrives
user taps it
App starts
Firebase initializes
API initializes
auth restores
router mounts
notification action processes
booking page opens
```

This is one of the most important acceptance tests.

---

# 105. Background Race Condition

Test:

```text
App in background
notification arrives
user taps
App resumes
router exists
event opens correct route
```

Also test:

```text
App background
expired JWT
notification tap
API refresh / re-login flow
route only after authenticated state
```

---

# 106. Logout / Token Race Condition

Test:

```text
User logs out
old device token remains temporarily active
new user logs in on same device
```

The server must ensure the same token is associated with the correct authenticated user.

A token should not remain assigned to the previous account.

---

# 107. Multi-Device Case

Test one account:

```text
phone A
phone B
```

Both authenticated.

Expected:

```text
PushToken:
  user -> token A
  user -> token B
```

Logout on A:

```text
A inactive
B remains active
```

A payment push should still reach B.

---

# 108. Role Change Case

If a user's role can change:

```text
customer -> worker
```

unsubscribe:

```text
fixly_customers
```

then subscribe:

```text
fixly_workers
```

Also update PushToken user role context if stored.

---

# 109. FCM Token Rotation Case

Firebase may issue a new token.

Test:

```text
old token
   ↓
onTokenRefresh
   ↓
backend register new token
   ↓
old token inactive/obsolete
```

No duplicate sends.

---

# 110. Invalid Token Case

Simulate:

```text
FCM returns UNREGISTERED
```

Expected:

```text
PushToken.isActive = false
```

No permanent retry loop.

---

# 111. Queue Failure Case

Stop Redis/queue worker.

Business operation:

```text
create booking
```

must still succeed.

Notification:

```text
remains pending/failed
```

and can recover when worker returns, depending on queue configuration.

---

# 112. Firebase Outage Case

If Firebase Admin cannot send:

```text
booking remains successful
Mongo Notification remains durable
push status = failed/pending
```

The user can still see the notification in the app inbox.

This is why MongoDB history and FCM should be separate concerns.

---

# 113. Duplicate Payment Verification Case

Call payment verification twice with the same Razorpay payment ID.

Expected:

```text
transaction remains success
wallet credited once
JOB_COMPLETED generated once
PAYMENT_SUCCESS generated once
```

This should be enforced with current payment idempotency plus notification dedupe.

---

# 114. Duplicate Booking Acceptance Case

Multiple workers simultaneously attempt:

```text
POST /accept
```

Current Redis/Mongo concurrency control decides the winner.

FCM should only be emitted after the successful state transition.

Expected:

```text
winner -> BOOKING_ACCEPTED to customer
losers -> no false accepted notification
```

---

# 115. Notification Testing Matrix

## Device state

Test each:

```text
foreground
background
terminated
```

## Platform

```text
Android real device
Android debug/release
iOS real device
iOS release/TestFlight
```

## Event groups

```text
booking
job
payment
KYC
wallet
payout
support
SOS
admin broadcast
```

## Auth states

```text
logged in
logged out
session restored
token expired
```

## Network states

```text
online
offline
poor connection
server unavailable
```

---

# 116. Development Test Events

Create a safe development-only mechanism for testing FCM.

Options:

```text
admin broadcast
development test user notification endpoint
Firebase Console test message
```

Do not expose arbitrary token-send APIs in production.

---

# 117. Recommended Implementation Phases

Do not implement everything in one giant change.

## Phase 1 — Dependency + Firebase groundwork

Goal:

```text
firebase_core working
firebase_messaging installed
flutter_local_notifications installed
Firebase Admin installed
```

Deliverable:

```text
FCM can initialize on Android/iOS.
```

---

## Phase 2 — Device token registration

Implement:

```text
PushToken model
POST /device-token
DELETE /device-token
NotificationTokenService
token refresh
```

Deliverable:

```text
login -> token stored in MongoDB
logout -> token inactive
```

---

## Phase 3 — First end-to-end push

Create:

```text
test notification
```

Flow:

```text
Backend
 -> NotificationService
 -> queue
 -> worker
 -> FCM
 -> Flutter
```

Deliverable:

```text
real device receives push
```

Do not move to all event integration until this works.

---

## Phase 4 — Foreground + local notifications

Implement:

```text
onMessage
flutter_local_notifications
channels
```

Deliverable:

```text
foreground push appears correctly without duplicates
```

---

## Phase 5 — Background + terminated + tap routing

Implement:

```text
background handler
getInitialMessage
onMessageOpenedApp
NotificationRouter
pending action
```

Deliverable:

```text
tap -> correct page from every app state
```

---

## Phase 6 — Real notification inbox

Replace:

```text
MockRepository notifications
```

with REST API.

Implement:

```text
NotificationsApiRepository
NotificationsCubit
NotificationsPage
mark read
mark all read
delete
```

Deliverable:

```text
Mongo notification history works
```

---

## Phase 7 — Booking events

Integrate:

```text
NEW_BOOKING_AVAILABLE
BOOKING_ASSIGNED
BOOKING_ACCEPTED
BOOKING_DECLINED
BOOKING_CANCELLED
WORKER_ARRIVED
JOB_STARTED
INVOICE_UPDATED
JOB_COMPLETED
```

Deliverable:

```text
full booking lifecycle notifications
```

---

## Phase 8 — Payments + wallet

Integrate:

```text
PAYMENT_SUCCESS
PAYMENT_FAILED
PAYMENT_RECEIVED
WALLET_CREDITED
```

Deliverable:

```text
server-authoritative financial pushes
```

---

## Phase 9 — KYC / certificates / support

Integrate:

```text
KYC_APPROVED
KYC_REJECTED
CERTIFICATE_APPROVED
CERTIFICATE_REJECTED
SUPPORT_REPLY
```

---

## Phase 10 — Payout lifecycle

First add missing admin payout status APIs.

Then integrate:

```text
PAYOUT_REQUESTED
PAYOUT_PROCESSING
PAYOUT_PAID
PAYOUT_REJECTED
```

---

## Phase 11 — Topic broadcasts + preferences

Implement:

```text
role topics
marketing topic
system topic
notification preferences
admin broadcast FCM
```

---

## Phase 12 — Production hardening

Complete:

```text
retry/backoff
invalid token cleanup
observability
rate control
deduplication
security review
Android/iOS production testing
```

---

# 118. Implementation Order at File Level

Recommended order:

```text
1. backend/package.json
2. backend/config/firebase.js
3. backend/models/PushToken.js
4. backend/models/Notification.js
5. backend/services/fcmService.js
6. backend/services/notificationTemplates.js
7. backend/queues/notificationQueue.js
8. backend/services/notificationService.js
9. backend/worker/notificationWorker.js
10. backend/controllers/notificationController.js
11. backend/routes/notification-routes.js
12. backend/server.js

13. frontend/pubspec.yaml
14. frontend/lib/core/notifications/*
15. frontend/lib/core/network/api_enpoints.dart
16. frontend/lib/main.dart
17. frontend/lib/features/auth/presentation/cubit/app_session_cubit.dart
18. frontend/lib/shared/models/models.dart
19. frontend/lib/features/shared/data/notifications_api_repository.dart
20. frontend/lib/features/shared/presentation/cubit/notifications_cubit.dart
21. frontend/lib/features/shared/presentation/cubit/notifications_state.dart
22. frontend/lib/features/shared/presentation/pages/notifications_page.dart
23. frontend/lib/features/shared/presentation/pages/settings_page.dart
24. frontend/lib/app/router/route_names.dart
25. frontend/lib/app/router/app_router.dart
```

Then integrate business event controllers one domain at a time.

---

# 119. What NOT to Do

Do not:

```text
send FCM directly from every controller
```

Do not:

```text
broadcast all jobs to fixly_workers
```

Do not:

```text
put whole booking JSON in FCM data
```

Do not:

```text
store Firebase Admin service credentials in Flutter
```

Do not:

```text
remove Socket.IO
```

Do not:

```text
use FCM for live tracking
```

Do not:

```text
trust Flutter payment success as final
```

Do not:

```text
show notification permission immediately on first startup
```

Do not:

```text
route to sensitive pages without API authorization
```

Do not:

```text
make FCM delivery required for booking/payment transaction success
```

Do not:

```text
let every notification have maximum priority
```

---

# 120. Known Current Codebase Issues to Account For

These are not all FCM bugs, but FCM work touches them.

## Issue 1 — Status mismatch

Backend worker acceptance writes:

```text
APPROVED
```

while Flutter semantic state is:

```text
accepted
```

Normalize this in event mapping.

## Issue 2 — Notification UI is mocked

Current NotificationsCubit reads MockRepository.

It must be migrated.

## Issue 3 — Legacy User pushTokens

Use PushToken model.

## Issue 4 — Single-device concept

`activeDeviceId` represents current session security, but FCM should support multiple tokens/devices per user.

Do not equate one JWT device session with one FCM token globally.

## Issue 5 — Firebase bootstrap swallows errors

Notification service must explicitly detect Firebase availability.

## Issue 6 — Admin actions bypass notification domain logic

Admin worker, booking, verification, support, and payout mutations need explicit notification hooks.

## Issue 7 — Payout admin mutation endpoint missing

Add validated payout transition API before building payout notifications.

## Issue 8 — Notification category values are inconsistent

Normalize casing and legacy aliases.

## Issue 9 — Existing Socket.IO room join appears trust-based

Future security hardening should authorize booking room membership.

## Issue 10 — Booking cancellation semantics

Notification direction must depend on actor:

```text
customer cancelled
worker cancelled
admin/system cancelled
```

---

# 121. Definition of Done

FCM integration is complete when all of these are true:

### Firebase

```text
Android push works
iOS push works
foreground works
background works
terminated works
```

### Token lifecycle

```text
login registers token
restore registers token
refresh updates token
logout deactivates token
multi-device works
```

### Topics

```text
customer role topic works
worker role topic works
marketing opt-in works
logout cleanup works
```

### Business events

```text
booking events
job events
payment events
wallet events
KYC events
payout events
support events
SOS
system/admin broadcasts
```

### Notification inbox

```text
real Mongo data
pagination
mark read
mark all read
delete
tap routing
unread state
```

### Reliability

```text
queue retries
invalid token cleanup
deduplication
push failures do not break business operations
```

### Security

```text
no Admin SDK credentials in Flutter
no PII in global push payloads
API authorization on deep links
authenticated token registration
```

### UX

```text
no duplicate foreground/background alerts
appropriate channels
appropriate priorities
permission prompt at a useful moment
English/Hindi strategy defined
```

---

# 122. Final Target Architecture

```text
                         FIXLY CLIENT
                              │
             ┌────────────────┼────────────────┐
             │                │                │
             ▼                ▼                ▼
       REST API          Socket.IO            FCM
             │          live state       OS-level push
             │                │                │
             │                │                ▼
             │                │       Local Notification
             │                │                │
             ▼                ▼                ▼
       Domain State      Live Refresh       Tap Router
             │                                  │
             ▼                                  ▼
          MongoDB                         GoRouter
             │
             ▼
    Notification History
             ▲
             │
      NotificationService
             ▲
             │
        BullMQ Queue
             ▲
             │
    Notification Worker
             ▲
             │
       Firebase Admin
             │
             ▼
            FCM
```

---

# 123. Final Design Principles

The implementation should consistently follow these principles:

1. **Socket.IO remains.**
2. **FCM is transport, not business logic.**
3. **MongoDB is notification history/source of truth.**
4. **REST APIs remain the source of truth for entities.**
5. **Topics are for broad public/role-level messages.**
6. **Direct tokens are for private transactional events.**
7. **Every private FCM payload contains IDs, not private data.**
8. **Business events create notification records before queueing delivery.**
9. **Push delivery is asynchronous.**
10. **Push failure never rolls back booking/payment/KYC state.**
11. **All event generation is idempotent.**
12. **Invalid FCM tokens are deactivated automatically.**
13. **User/device/token relationships are explicit.**
14. **Foreground and background presentation must not duplicate.**
15. **Notification taps wait for authentication/router readiness.**
16. **Financial notifications come only from server-authoritative state.**
17. **Safety notifications are targeted directly.**
18. **Notification preferences distinguish transactional/system/marketing behavior.**
19. **All platform-specific FCM setup is tested on real devices before production.**
20. **Implementation should be incremental, with one working end-to-end push path before integrating every business event.**

---

# 124. Recommended First Implementation Milestone

The safest first milestone is:

```text
Firebase Messaging
        +
Flutter token registration
        +
PushToken Mongo model
        +
backend FCM service
        +
BullMQ notification worker
        +
one authenticated test notification
```

Do not start by modifying all booking/payment/KYC controllers.

First prove this complete path:

```text
Flutter gets FCM token
      ↓
POST /api/notifications/device-token
      ↓
PushToken saved in MongoDB
      ↓
backend creates test Notification
      ↓
BullMQ
      ↓
Firebase Admin
      ↓
FCM
      ↓
real device receives
      ↓
tap opens test destination
```

Once this works reliably, integrate each business event using the architecture above.

---

## Audit Basis

This plan was built against the current Fixly code structure, including:

```text
backend/server.js
backend/package.json
backend/models/User.js
backend/models/Notification.js
backend/models/PayoutRequest.js
backend/controllers/bookingController.js
backend/controllers/activeJobController.js
backend/controllers/paymentController.js
backend/controllers/notificationController.js
backend/controllers/verificationController.js
backend/controllers/workerCertificateController.js
backend/controllers/workerWalletController.js
backend/controllers/supportController.js
backend/controllers/adminController.js
backend/config/socket.js
backend/sockets/tracking.js
backend/config/redis.js
backend/worker/emailWorker.js
backend/routes/booking-routes.js
backend/routes/notification-routes.js
backend/routes/admin-routes.js

frontend/pubspec.yaml
frontend/lib/main.dart
frontend/lib/app/app.dart
frontend/lib/app/router/app_router.dart
frontend/lib/app/router/route_names.dart
frontend/lib/core/firebase/firebase_bootstrap.dart
frontend/lib/core/network/api_client.dart
frontend/lib/core/network/api_enpoints.dart
frontend/lib/core/preferences/app_preferences.dart
frontend/lib/features/auth/data/auth_api_repository.dart
frontend/lib/features/auth/presentation/cubit/app_session_cubit.dart
frontend/lib/features/shared/presentation/cubit/notifications_cubit.dart
frontend/lib/features/shared/presentation/pages/notifications_page.dart
frontend/lib/features/shared/presentation/pages/settings_page.dart
frontend/lib/shared/models/models.dart
frontend/android/app/src/main/AndroidManifest.xml
frontend/android/app/build.gradle.kts
frontend/ios/Runner/AppDelegate.swift
frontend/ios/Runner/Info.plist
```

This is the implementation reference. New work should follow the actual repository boundaries above rather than introducing a parallel notification architecture.
