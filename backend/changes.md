# Backend Changes After 10 PM, September 5, 2026

This log is based on the commits that changed `backend/` after the requested cutoff. All three commits were pushed to `main` on September 6, 2026.

## 1. Backend Added to the Main Repository

Commit `102f281` at 01:56:14: `feat: add backend under backend directory`

- Added the complete Node.js/Express backend under `backend/`.
- Added application startup in `server.js`, including route registration, middleware, sockets, and server configuration.
- Added configuration modules for MongoDB, Firebase, Nodemailer, Redis, and Socket.IO.
- Added authentication, rate limiting, file upload, and upload-processing middleware.
- Added controllers for authentication, users, workers, bookings, active jobs, payments, services, support, notifications, reviews, verification, welfare, cooperatives, AI, demand forecasting, home data, certificates, and worker wallets.
- Added Mongoose models for users, bookings, services, notifications, reviews, transactions, payouts, welfare, support tickets, certificates, cooperatives, insurance, and settings.
- Added API routes for authentication, users, workers, bookings, payments, services, support, notifications, reviews, verification, welfare, certificates, worker wallets, cooperatives, AI, uploads, and admin operations.
- Added Redis queue workers for email and file uploads, plus general queue support.
- Added tracking sockets, seed scripts, public-tunnel tooling, Swagger generation/output, email and upload utilities, and backend deployment documentation.
- Added backend dependency manifests, lockfile, Docker Compose configuration, environment example, ignore rules, and architecture documentation.

## 2. Firebase Cloud Messaging Push Notifications

Commit `c8b88b7` at 02:23:32: `feat: implement push notification system with Firebase Cloud Messaging`

- Added the `PushToken` model for storing user device tokens.
- Expanded the `Notification` model and notification controller for persistent notification records.
- Added `notificationQueue` to enqueue notification delivery jobs.
- Added `fcmService` to send Firebase Cloud Messaging notifications.
- Added `notificationService` to coordinate notification creation and delivery.
- Added `notificationWorker` to process queued notification jobs.
- Updated Firebase configuration and backend startup wiring.
- Added notification routes and registered the notification flow with the backend API.
- Added required Firebase and queue dependencies to `package.json` and `package-lock.json`.
- Added notification environment configuration and backend README notes.
- Added notification contract tests covering payload normalization and notification behavior.
- Improved notification delivery error handling and logging.

## 3. Notification Refactor and Lifecycle Coverage

Commit `79d3e2c` at 02:50:38: `Refactor code structure for improved readability and maintainability`

- Added `services/eligibleWorkers.js` to centralize worker eligibility selection for notifications.
- Added `services/notificationTemplates.js` with reusable notification templates.
- Refactored `services/notificationService.js` to use shared templates, eligible-worker selection, and clearer delivery flow.
- Expanded `worker/notificationWorker.js` to process the refactored notification jobs.
- Updated `controllers/notificationController.js` and notification routes for the refactored notification contract.
- Added notification triggers and delivery integration to active-job, booking, payment, support, worker-certificate, and worker-wallet controllers.
- Updated `models/Notification.js` and admin routes to match the new notification behavior.
- Added or updated notification contract coverage in `tests/notificationContracts.test.js`.
- Updated `.env.example` and `.gitignore` for the backend notification setup.

## Result

- The backend is part of the root `SIH-Fixly` repository on `main`.
- Push notifications now support token storage, FCM delivery, queued processing, reusable templates, eligible-worker targeting, and notification records.
- The backend changes above are included in `origin/main` at commit `79d3e2c`.
