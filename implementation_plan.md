# WebRTC Audio Calling Integration & Multi-Emulator Testing Plan

Implement secure, end-to-end WebRTC peer-to-peer audio calling with zero phone number exposure, WhatsApp-style incoming call push notifications (CallKit + FCM), Wi-Fi firewall fallback handling, and launch the entire local testing stack (Backend, Admin Panel, and two Android emulators: Pixel 9 Pro and Medium Phone).

## User Review Required

> [!IMPORTANT]
> - **Backend & Frontend Sync**: Both backend WebRTC REST APIs / Socket.io signaling handlers and Flutter client services will be implemented according to the backend integration guide.
> - **Android Min SDK**: `flutter_callkit_incoming` requires Android `minSdk` 23 or 24. We will set `minSdk = maxOf(flutter.minSdkVersion, 23)` in `android/app/build.gradle.kts`.
> - **Emulator Resources**: Running two Android emulators (`Pixel_9_Pro` and `Medium_Phone`) along with Node backend and Vite admin panel will require adequate system RAM (~6-8GB free).

## Open Questions
None. Architecture and requirements are fully specified in the provided integration guide.

## Proposed Changes

### Backend Component (`backend/`)

#### [NEW] [Call.js](file:///Users/dewashishhatekar/Developer/Projects/SIH-Fixly/backend/models/Call.js)
- Mongoose schema for call history:
  - References: `booking`, `caller`, `receiver`.
  - Fields: `bookingId`, `callerRole`, `status` (`RINGING`, `CONNECTED`, `COMPLETED`, `MISSED`, `REJECTED`, `FAILED`), `durationSeconds`, `endReason`, `networkType`.

#### [NEW] [webrtcController.js](file:///Users/dewashishhatekar/Developer/Projects/SIH-Fixly/backend/controllers/webrtcController.js)
- Implements 5 REST endpoints per specification:
  - `getIceServers`: Returns STUN server configuration (`stun.l.google.com:19302`, etc.).
  - `initiateCall`: Validates booking, worker assignment, and authorization. Generates session ID, caches status in Redis (180s TTL), dispatches FCM high-priority VoIP push to recipient via `fcmService`, returns masked caller/receiver profiles (zero phone numbers exposed).
  - `reportNetworkDiagnostics`: Analyzes ICE failure; returns `FIREWALL_BLOCKED_WIFI_RESTRICTION` when UDP is blocked on Wi-Fi.
  - `getCallStatus`: Checks active call state in Redis.
  - `getCallHistory`: Fetches masked past call logs for authenticated user.

#### [NEW] [webrtc-routes.js](file:///Users/dewashishhatekar/Developer/Projects/SIH-Fixly/backend/routes/webrtc-routes.js)
- Mounts routes under `/api/webrtc`:
  - `GET /config/ice-servers`
  - `POST /call/initiate`
  - `POST /call/network-diagnostics`
  - `GET /call/status/:bookingId`
  - `GET /call/history`

#### [NEW] [webrtc.js](file:///Users/dewashishhatekar/Developer/Projects/SIH-Fixly/backend/sockets/webrtc.js)
- Real-time Socket.io signaling handlers:
  - `webrtc:join-room`: Dynamic room joining with booking ID alias support (`#BK-...` and raw ID).
  - `webrtc:call-initiate`: Broadcasts `webrtc:incoming-call` to recipient.
  - `webrtc:call-accept`: Broadcasts `webrtc:call-accepted` to caller, updates Redis status.
  - `webrtc:call-reject`: Broadcasts `webrtc:call-rejected`, cleans up Redis session.
  - `webrtc:offer`: Relays SDP offer to peer.
  - `webrtc:answer`: Relays SDP answer to caller.
  - `webrtc:ice-candidate`: Relays ICE candidate to peer.
  - `webrtc:ice-failed`: Emits firewall restriction error when Wi-Fi blocks UDP.
  - `webrtc:call-hangup`: Cleans up Redis session, creates DB call log, notifies peer with `webrtc:call-ended`, dispatches `CANCEL_CALL` FCM push.

#### [MODIFY] [server.js](file:///Users/dewashishhatekar/Developer/Projects/SIH-Fixly/backend/server.js)
- Mount `/api/webrtc` routes.

#### [MODIFY] [socket.js](file:///Users/dewashishhatekar/Developer/Projects/SIH-Fixly/backend/config/socket.js)
- Register `registerWebRTCSocketHandlers(io)` alongside tracking handlers.

---

### Frontend Component (`frontend/`)

#### [MODIFY] [pubspec.yaml](file:///Users/dewashishhatekar/Developer/Projects/SIH-Fixly/frontend/pubspec.yaml)
- Add dependencies:
  - `flutter_webrtc: ^1.6.1`
  - `flutter_callkit_incoming: ^3.1.5`

#### [MODIFY] [AndroidManifest.xml](file:///Users/dewashishhatekar/Developer/Projects/SIH-Fixly/frontend/android/app/src/main/AndroidManifest.xml)
- Add permissions: `RECORD_AUDIO`, `MODIFY_AUDIO_SETTINGS`, `ACCESS_NETWORK_STATE`, `USE_FULL_SCREEN_INTENT`, `VIBRATE`, `WAKE_LOCK`.

#### [MODIFY] [build.gradle.kts](file:///Users/dewashishhatekar/Developer/Projects/SIH-Fixly/frontend/android/app/build.gradle.kts)
- Ensure `minSdk = maxOf(flutter.minSdkVersion, 23)`.

#### [NEW] [webrtc_call_service.dart](file:///Users/dewashishhatekar/Developer/Projects/SIH-Fixly/frontend/lib/services/webrtc_call_service.dart)
- Manages complete WebRTC lifecycle:
  - Socket.io connection & signaling event listeners.
  - Fetching ICE STUN servers dynamically.
  - Local microphone media stream capture and track attachment.
  - Peer connection creation, SDP offer/answer exchange, ICE candidate routing.
  - Wi-Fi firewall detection and state handling (`FIREWALL_BLOCKED_WIFI_RESTRICTION`).
  - Mute/unmute microphone and speakerphone toggle.
  - Dynamic host resolution using `ApiConfig.baseUrl` (resolves to `http://10.0.2.2:8000` on Android emulator).

#### [NEW] [call_screen.dart](file:///Users/dewashishhatekar/Developer/Projects/SIH-Fixly/frontend/lib/screens/call_screen.dart)
- Full-screen in-call UI:
  - Masked caller/receiver info (Avatar, Name, Role, Service title).
  - Live call timer and status indicator ("Connecting...", "Ringing...", "01:45").
  - Mute button, Speakerphone toggle, End Call (red FAB) button.
  - Wi-Fi firewall diagnostic alert dialog advising switch to mobile data.

#### [MODIFY] [notification_service.dart](file:///Users/dewashishhatekar/Developer/Projects/SIH-Fixly/frontend/lib/core/notifications/notification_service.dart)
- Add `_firebaseMessagingBackgroundHandler` logic for:
  - `INCOMING_CALL`: Show native incoming call UI via `FlutterCallkitIncoming.showCallkitIncoming(...)`.
  - `CANCEL_CALL`: Dismiss ringing via `FlutterCallkitIncoming.endCall(...)`.
- Add foreground message listener for incoming calls.
- Add CallKit event listener for Accept/Decline actions.

#### [MODIFY] [route_names.dart](file:///Users/dewashishhatekar/Developer/Projects/SIH-Fixly/frontend/lib/app/router/route_names.dart) & [app_router.dart](file:///Users/dewashishhatekar/Developer/Projects/SIH-Fixly/frontend/lib/app/router/app_router.dart)
- Register RouteNames.call (`/call`) pointing to `CallScreen`.

#### [MODIFY] Booking/Navigation Pages
- Wire Call button to launch WebRTC call session:
  - [CustomerTrackingPage](file:///Users/dewashishhatekar/Developer/Projects/SIH-Fixly/frontend/lib/features/customer/presentation/pages/customer_tracking_page.dart)
  - [WorkerNavigationPage](file:///Users/dewashishhatekar/Developer/Projects/SIH-Fixly/frontend/lib/features/worker/presentation/pages/worker_navigation_page.dart)
  - [WorkerActiveJobPage](file:///Users/dewashishhatekar/Developer/Projects/SIH-Fixly/frontend/lib/features/worker/presentation/pages/worker_active_job_page.dart)

---

### Execution & Multi-Device Testing Stack

1. **Backend**:
   - Run Node server `cd backend && node server.js` (port 8000).
   - Check health endpoint `http://localhost:8000/`.
2. **Admin Panel**:
   - Run Vite dev server in `FIXLY ADMIN PANEL` (`npm run dev` on port 5173).
3. **Android Emulators**:
   - Launch Emulator 1: `flutter emulators --launch Pixel_9_Pro`
   - Launch Emulator 2: `flutter emulators --launch Medium_Phone`
   - Verify both devices are online and responsive via `/Volumes/NVme1TB/Programs/androidstudio/android_SDK/platform-tools/adb devices`.

## Verification Plan

### Automated Tests
- Backend WebRTC endpoint testing:
  - Query `GET /api/webrtc/config/ice-servers` -> verify 200 OK and STUN list.
  - Query `POST /api/webrtc/call/network-diagnostics` -> verify 400 with `FIREWALL_BLOCKED_WIFI_RESTRICTION`.
  - Run backend unit/contract tests: `node --test tests/*.test.js`.
- Frontend validation:
  - `flutter analyze` -> verify 0 syntax or type errors.

### Manual Verification
1. Backend & Admin panel:
   - Check backend logs: MongoDB connected, Redis connected, Socket.IO initialized, server listening on 8000.
   - Check Admin Panel: Vite server running on `http://localhost:5173`.
2. Emulators:
   - `adb devices` shows 2 connected devices: e.g. `emulator-5554` and `emulator-5556`.
3. Call Flow:
   - Verify WebRTC call flow and privacy masking on the launched emulators.
