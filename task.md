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

- [ ] 3. FCM Startup Token Sync & Notification Permissions <!-- id: 25 -->
  - [ ] 3.1 Update Backend `PushToken.js` (user optional), `authMiddleware.js` (optionalProtect), `notificationController.js`, `notification-routes.js` <!-- id: 26 -->
  - [ ] 3.2 Update `AppPreferences` to default all notifications to true <!-- id: 27 -->
  - [ ] 3.3 Update `NotificationService` & `NotificationPermissionService` to request permission & send FCM token on startup <!-- id: 28 -->
  - [ ] 3.4 Bundle notification permission prompt with other permissions (`location_service.dart`, `splash_page.dart`, `worker_navigation_page.dart`, `webrtc_call_service.dart`) <!-- id: 29 -->
  - [ ] 3.5 Run backend tests & `flutter analyze` verification <!-- id: 30 -->
