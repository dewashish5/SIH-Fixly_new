# SIH-Fixly Changes

This file combines the documented frontend and backend changes for the project.

## Frontend: Booking Lifecycle

### Foundation and Models

- Added `arrived` status to `BookingStatus`.
- Expanded `WorkerJob` with `problemDescription`, `problemPhotos`, `customerPhone`, `arrivalOtp`, financial fields, and `rawStatus`.
- Updated `bookings_api_repository.dart` to map `ARRIVED` to `BookingStatus.arrived` and extract the new `WorkerJob` fields.

### Cubits and Logic

- Added `BookingFlowCubit.loadFromBooking()` for status-based routing from history.
- Added real-time booking status updates through `socket.io-client`, with a 5-second polling fallback.
- Added `ActiveJobCubit.verifyOtpAndStart()`, `addExtraParts()`, and `submitWorkerReview()`.
- Added `inProgress`, `navigating`, and `reviewSubmitted` active-job states.

### Customer Screens

- Redesigned the Finding Worker page with a pulsing radar animation and automatic navigation after worker acceptance.
- Updated the Worker Accepted page with an OTP card and automatic transition to the arrived state.
- Added the Worker Arrived page for OTP-sharing authorization.
- Redesigned the Payment page with an itemized invoice and Razorpay security badge.
- Routed successful payments to the mandatory rating page.
- Redesigned the Rating page with interactive five-star input and multi-select tags.
- Prevented skipping the rating page with `PopScope(canPop: false)`.

### Worker Screens

- Overhauled the Active Job page with job details, customer information, problem photos, lifecycle banners, and action controls.
- Added the OTP Entry page with four-digit OTP input.
- Added the Add Parts page for optional parts and total calculation before completion.
- Added the Worker Rating page for post-job customer reviews.

### Shared and Routing

- Added routes for Worker Arrived, OTP Entry, Add Parts, and Rating screens.
- Updated order history to load the selected booking into the cubit.
- Added status-aware actions to the booking detail page.
- Added proximity detection and arrival feedback to customer tracking.

### Frontend Review Support

- Added `reviewerRole` support for customer and worker reviews.
- Changed review uniqueness from `booking` to the compound key `booking` and `reviewerRole`.
- Allowed both parties to submit reviews without conflicts.
- Limited worker aggregate rating updates to customer-submitted reviews.

## Backend: Changes After 10 PM, September 5, 2026

All three backend commits below were pushed to `main` on September 6, 2026.

### Backend Added to the Main Repository

Commit `102f281` at 01:56:14: `feat: add backend under backend directory`

- Added the complete Node.js/Express backend under `backend/`.
- Added application startup in `server.js`, including routes, middleware, sockets, and server configuration.
- Added MongoDB, Firebase, Nodemailer, Redis, and Socket.IO configuration modules.
- Added authentication, rate limiting, file upload, and upload-processing middleware.
- Added controllers for authentication, users, workers, bookings, active jobs, payments, services, support, notifications, reviews, verification, welfare, cooperatives, AI, demand forecasting, home data, certificates, and worker wallets.
- Added Mongoose models for users, bookings, services, notifications, reviews, transactions, payouts, welfare, support tickets, certificates, cooperatives, insurance, and settings.
- Added API routes for authentication, users, workers, bookings, payments, services, support, notifications, reviews, verification, welfare, certificates, worker wallets, cooperatives, AI, uploads, and admin operations.
- Added Redis queue workers for email and file uploads, plus general queue support.
- Added tracking sockets, seed scripts, public-tunnel tooling, Swagger generation/output, email and upload utilities, and backend deployment documentation.
- Added dependency manifests, lockfile, Docker Compose configuration, environment example, ignore rules, and architecture documentation.

### Firebase Cloud Messaging Push Notifications

Commit `c8b88b7` at 02:23:32: `feat: implement push notification system with Firebase Cloud Messaging`

- Added the `PushToken` model for storing user device tokens.
- Expanded the `Notification` model and notification controller for persistent notification records.
- Added `notificationQueue` for notification delivery jobs.
- Added `fcmService` for Firebase Cloud Messaging delivery.
- Added `notificationService` for notification creation and delivery coordination.
- Added `notificationWorker` for processing queued notification jobs.
- Updated Firebase configuration and backend startup wiring.
- Added notification routes and registered the notification flow with the backend API.
- Added Firebase and queue dependencies to `package.json` and `package-lock.json`.
- Added notification environment configuration and backend README notes.
- Added notification contract tests for payload normalization and notification behavior.
- Improved notification delivery error handling and logging.

### Notification Refactor and Lifecycle Coverage

Commit `79d3e2c` at 02:50:38: `Refactor code structure for improved readability and maintainability`

- Added `services/eligibleWorkers.js` for centralized worker eligibility selection.
- Added `services/notificationTemplates.js` with reusable notification templates.
- Refactored `services/notificationService.js` to use shared templates, eligible-worker selection, and a clearer delivery flow.
- Expanded `worker/notificationWorker.js` to process refactored notification jobs.
- Updated notification controllers and routes for the refactored contract.
- Added notification triggers and delivery integration to active-job, booking, payment, support, worker-certificate, and worker-wallet controllers.
- Updated `models/Notification.js` and admin routes for the new notification behavior.
- Added and updated notification contract coverage in `tests/notificationContracts.test.js`.
- Updated `.env.example` and `.gitignore` for the backend notification setup.

## Result

- Frontend and backend changes are documented in this single root-level file.
- The backend and notification changes are on `main` at commit `79d3e2c`.
- The separate frontend and backend `changes.md` files have been consolidated here.