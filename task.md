# Task List - WebRTC Audio Calling Integration & Multi-Emulator Setup

- [x] 1. Backend WebRTC Implementation <!-- id: 0 -->
  - [x] 1.1 Create `backend/models/Call.js` (Call history schema) <!-- id: 1 -->
  - [x] 1.2 Create `backend/controllers/webrtcController.js` (ICE servers, initiate call, network diagnostics, call status, call history) <!-- id: 2 -->
  - [x] 1.3 Create `backend/routes/webrtc-routes.js` & mount in `backend/server.js` <!-- id: 3 -->
  - [x] 1.4 Implement `backend/sockets/webrtc.js` & integrate in `backend/config/socket.js` <!-- id: 4 -->
  - [x] 1.5 Verify backend syntax & tests <!-- id: 5 -->

- [x] 2. Frontend WebRTC & CallKit Integration <!-- id: 6 -->
  - [x] 2.1 Add `flutter_webrtc` and `flutter_callkit_incoming` dependencies to `frontend/pubspec.yaml` <!-- id: 7 -->
  - [x] 2.2 Configure Android permissions in `AndroidManifest.xml` and ensure `minSdk` in `build.gradle.kts` <!-- id: 8 -->
  - [x] 2.3 Implement `frontend/lib/services/webrtc_call_service.dart` <!-- id: 9 -->
  - [x] 2.4 Implement `frontend/lib/screens/call_screen.dart` <!-- id: 10 -->
  - [x] 2.5 Update `NotificationService` in `frontend/lib/core/notifications/notification_service.dart` for FCM VoIP & CallKit background/foreground handling <!-- id: 11 -->
  - [x] 2.6 Register `/call` route in `AppRouter` and `RouteNames` <!-- id: 12 -->
  - [x] 2.7 Replace direct phone calls with WebRTC calls in `CustomerTrackingPage`, `WorkerNavigationPage`, `WorkerActiveJobPage` <!-- id: 13 -->
  - [x] 2.8 Verify Flutter build & run `flutter analyze` <!-- id: 14 -->

- [x] 3. Real-Time Worker Socket.IO & Booking Lifecycle <!-- id: 25 -->
  - [x] 3.1 Backend Updates: `Booking.js` (PAYMENT_PENDING status), `activeJobController.js` (verify OTP -> IN_PROGRESS, complete job -> PAYMENT_PENDING), `paymentController.js` (COMPLETED/PAID broadcast to all room aliases), `tracking.js` (worker room & timestamp) <!-- id: 26 -->
  - [x] 3.2 Backend FCM startup support: `PushToken.js` (user optional), `authMiddleware.js` (optionalProtect), `notification-routes.js`, `notificationController.js` <!-- id: 27 -->
  - [x] 3.3 Create `WorkerRealtimeService` & integrate with `WorkerDashboardPage`, `WorkerActiveJobPage`, `JobFeedCubit` (StreamBuilder & auto-updates without pull-to-refresh) <!-- id: 28 -->
  - [x] 3.4 Fix tracking map bike movement (timestamp order check, stale HTTP poll suppression, jitter filter, forward smooth lerp) <!-- id: 29 -->
  - [x] 3.5 Fix worker arrival OTP flow: verify arrival OTP transitions directly to `IN_PROGRESS` and redirects directly to `WorkerActiveJobPage` with "Swipe to Complete Job" <!-- id: 30 -->
  - [x] 3.6 Implement Worker Complete -> Customer Payment switch: worker swipe complete emits PAYMENT_PENDING -> customer screen dynamically replaces Tracking button with Payment button <!-- id: 31 -->
  - [x] 3.7 Implement Payment -> Auto Review flow: Razorpay payment success emits COMPLETED/PAID -> both Customer and Worker auto-navigate to their respective Review screens <!-- id: 32 -->
  - [x] 3.8 App startup FCM token sync & default notification permissions <!-- id: 33 -->
  - [x] 3.9 Verification: Backend `npm test` & Frontend `flutter analyze` <!-- id: 34 -->

- [ ] 4. Error Resolution, Payment & Persistence Lifecycle <!-- id: 35 -->
  - [ ] 4.1 Backend Mongoose fix: replace `{ new: true }` with `{ returnDocument: 'after' }` <!-- id: 36 -->
  - [ ] 4.2 Backend BullMQ fix: eliminate colon in custom job IDs (`notification_${id}`) <!-- id: 37 -->
  - [ ] 4.3 Backend & Frontend Zero Initial Rating: reset defaults to 0.0, remove fake seed reviews, remove hardcoded 4.9 ★ <!-- id: 38 -->
  - [ ] 4.4 Flutter crash fix: add `serviceName` alias on `WorkerJob` and fix `worker_active_job_page.dart` <!-- id: 39 -->
  - [ ] 4.5 Flutter permission collision fix: sequentialize/batch location and notification permissions <!-- id: 40 -->
  - [ ] 4.6 Razorpay payment fix & live invoice sync: allow `PAYMENT_PENDING` in `createOrder`, pass `bookingId` to `CustomerPaymentPage`, fetch fresh booking data, periodic 3s parts sync <!-- id: 41 -->
  - [ ] 4.7 Redirection flow: Customer tracking auto-pops to details on `IN_PROGRESS`; worker has "Swipe to Request Payment", on payment worker receives push & reveals "Swipe to Complete Job" <!-- id: 42 -->
  - [ ] 4.8 Worker state persistence: persist active job across app kill/close; auto-restore straight to active job on relaunch <!-- id: 43 -->
  - [ ] 4.9 Full verification: Backend `npm test` & Frontend `flutter analyze` <!-- id: 44 -->

