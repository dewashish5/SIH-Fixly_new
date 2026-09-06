# ==============================================================================
# GIGCONNECT: FLUTTER MOBILE APP - WEBRTC AUDIO CALLING INTEGRATION GUIDE
# ==============================================================================
# Target Audience: Frontend (Flutter) Engineers, Mobile Developers & AI Agents (Antigravity)
# Features: Zero Phone Number Exposure, Dynamic Booking Room, WebRTC P2P Audio,
#           WhatsApp-style Incoming Call (CallKit/FCM Push), Wi-Fi Firewall Fallback
# ==============================================================================

---

## TABLE OF CONTENTS
1. [End-to-End User Experience Workflows](#1-end-to-end-user-experience-workflows)
   - [Workflow A: Worker Calling Customer (Near Arrival / Location Issue)](#workflow-a-worker-calling-customer-near-arrival--location-issue)
   - [Workflow B: Customer Calling Worker (ETA / Instructions)](#workflow-b-customer-calling-worker-eta--instructions)
2. [Phone Number Privacy & Data Masking Guarantee](#2-phone-number-privacy--data-masking-guarantee)
3. [Complete REST API Specifications (Request & Response)](#3-complete-rest-api-specifications-request--response)
   - [API 1: Fetch ICE / STUN / TURN Configuration](#api-1-fetch-ice--stun--turn-configuration)
   - [API 2: Initiate Booking Call Session](#api-2-initiate-booking-call-session)
   - [API 3: Report Network Diagnostics & Firewall Block](#api-3-report-network-diagnostics--firewall-block)
   - [API 4: Get Live Call Status from Redis](#api-4-get-live-call-status-from-redis)
   - [API 5: Get Masked Call History](#api-5-get-masked-call-history)
4. [Complete Socket.io Real-Time Signaling Dictionary](#4-complete-socketio-real-time-signaling-dictionary)
   - [Client to Server Events (App Emits)](#client-to-server-events-app-emits)
   - [Server to Client Events (App Listens)](#server-to-client-events-app-listens)
5. [Closed / Killed App VoIP Push Mechanism (WhatsApp Style)](#5-closed--killed-app-voip-push-mechanism-whatsapp-style)
6. [Wi-Fi Firewall & Strict NAT Diagnostics Handling](#6-wi-fi-firewall--strict-nat-diagnostics-handling)
7. [Flutter Production Code Implementation](#7-flutter-production-code-implementation)
   - [A. Dependencies & Native Permissions](#a-dependencies--native-permissions)
   - [B. WebRTC & Socket Call Service (`webrtc_call_service.dart`)](#b-webrtc--socket-call-service-webrtc_call_servicedart)
   - [C. Background VoIP Push Handler (`main.dart`)](#c-background-voip-push-handler-maindart)
   - [D. In-Call UI Screen (`call_screen.dart`)](#d-in-call-ui-screen-call_screendart)

---

## 1. END-TO-END USER EXPERIENCE WORKFLOWS

### WORKFLOW A: Worker Calling Customer (Near Arrival / Location Issue)
**Situation:** Worker arrives near the customer's home or cannot find the exact house/building. Worker needs to guide or ask directions.

```
[WORKER MOBILE APP]                                                  [CUSTOMER MOBILE APP]
       │                                                                      │
  (1) Taps "Call Customer" Icon                                               │
       │                                                                      │
  (2) HTTP GET /api/webrtc/config/ice-servers                                 │
      Returns STUN servers list                                               │
       │                                                                      │
  (3) HTTP POST /api/webrtc/call/initiate                                     │
      Request: { bookingId: "#BK-260906-01042A8F" }                           │
      Response: { room, maskedCaller, maskedReceiver }                        │
       │                                                                      │
  (4) Opens Calling Screen                                                    │
      Socket.io: Emits 'webrtc:join-room' { bookingId, userId }               │
      Socket.io: Emits 'webrtc:call-initiate' { bookingId, ... }              │
       │                                                                      │
       ├─────────────────────────► BACKEND ◄──────────────────────────────────┤
       │                           Backend sends:                             │
       │                           1. Socket event 'webrtc:incoming-call'     │
       │                           2. FCM High-Priority Push to Customer      │
       │                                                                      │
       │                                                      (5) Customer Receives Call:
       │                                                          - If App Open: In-app ringing popup
       │                                                          - If App Closed: Full-screen CallKit
       │                                                            Ringtone + Vibrate (WhatsApp style)
       │                                                                      │
       │                                                      (6) Customer taps "Accept" (Green Button)
       │                                                          Customer App joins socket room:
       │                                                          'webrtc:join-room' & 'webrtc:call-accept'
       │                                                                      │
  (7) Worker App receives 'webrtc:call-accepted'                              │
      Worker WebRTC creates SDP Offer                                         │
      Emits 'webrtc:offer' ───────────────────────────────────────────────► Receives Offer
       │                                                                      Creates SDP Answer
  Receives Answer ◄─────────────────────────────────────────────────────── Emits 'webrtc:answer'
       │                                                                      │
  Exchanges ICE Candidates ◄─────────────────────────────────────────────► Exchanges ICE Candidates
       │                                                                      │
  ═════════════════════════════════════════════════════════════════════════════
         (8) P2P ENCRYPTED AUDIO CONNECTED! (Real numbers NOT visible)
  ═════════════════════════════════════════════════════════════════════════════
       │                                                                      │
  (9) Worker guides location, taps "End Call"                                 │
      Emits 'webrtc:call-hangup' ────────────────────────────────────────► Receives 'webrtc:call-ended'
      Both apps close call screen cleanly.                                    Duration recorded in DB.
```

---

### WORKFLOW B: Customer Calling Worker (ETA / Instructions)
**Situation:** Customer wants to ask the worker what time they will reach or give special entry instructions.
- The flow is 100% symmetric! Customer taps Call icon -> Backend authorizes customer -> Worker's phone rings with WhatsApp-style incoming call -> Worker accepts -> WebRTC audio connected.

---

## 2. PHONE NUMBER PRIVACY & DATA MASKING GUARANTEE

> [!IMPORTANT]
> **Strict Security Principle:**
> Real phone numbers are stored safely in MongoDB `User` collections, but **NEVER** transmitted over WebRTC signaling or REST calling APIs.
> 
> When the mobile app queries `/api/webrtc/call/initiate`, the response contains:
> - `caller.name`, `caller.avatar`, `caller.role`
> - `receiver.name`, `receiver.avatar`, `receiver.role`
> - `serviceTitle` and `bookingId`
> 
> The UI displays:
> *"Calling Ramesh Kumar (Plumber) regarding Tap Repair Service (#BK-260906-01042A8F)"*
> Neither user can see the other party's phone number, preventing unsolicited calls or off-platform transactions.

---

## 3. COMPLETE REST API SPECIFICATIONS (REQUEST & RESPONSE)

**Base URL:** `http://<YOUR_BACKEND_HOST>:8000` (or AWS ALB URL)  
**Authentication:** Required for all endpoints via Header:  
`Authorization: Bearer <JWT_ACCESS_TOKEN>`  
`Content-Type: application/json`

---

### API 1: Fetch ICE / STUN / TURN Configuration
Fetches high-availability Google STUN servers and custom TURN relay credentials (if configured).

- **Method:** `GET`
- **Route:** `/api/webrtc/config/ice-servers`
- **Request Headers:**
  ```http
  GET /api/webrtc/config/ice-servers HTTP/1.1
  Host: api.gigconnect.com
  Authorization: Bearer eyJhbGciOi...
  ```
- **Success Response (200 OK):**
  ```json
  {
    "success": true,
    "iceServers": [
      { "urls": "stun:stun.l.google.com:19302" },
      { "urls": "stun:stun1.l.google.com:19302" },
      { "urls": "stun:stun2.l.google.com:19302" }
    ]
  }
  ```

---

### API 2: Initiate Booking Call Session
Called when a user taps the Call icon. Validates participants, verifies worker assignment, caches ringing state in Redis (180s TTL), dispatches FCM VoIP Push to the recipient, and returns masked profiles.

- **Method:** `POST`
- **Route:** `/api/webrtc/call/initiate`
- **Request Headers:**
  ```http
  POST /api/webrtc/call/initiate HTTP/1.1
  Host: api.gigconnect.com
  Authorization: Bearer eyJhbGciOi...
  Content-Type: application/json
  ```
- **Request Body:**
  ```json
  {
    "bookingId": "#BK-260906-01042A8F"
  }
  ```
  *(Note: Booking ID format is strictly unique: `#BK-YYMMDD-SSSSXXXX` e.g. `#BK-260906-01042A8F`. The backend also accepts without hash `BK-260906-01042A8F` or MongoDB ObjectId `66da1b9872f9b8c01` seamlessly).*

- **Success Response (200 OK):**
  ```json
  {
    "success": true,
    "message": "Call session initialized successfully",
    "callSessionId": "call_#BK-260906-01042A8F_1725612345678",
    "room": "webrtc_call_#BK-260906-01042A8F",
    "bookingId": "#BK-260906-01042A8F",
    "serviceTitle": "Tap Repair Service",
    "caller": {
      "id": "66da1b9872f9b8c01",
      "name": "Vaibhav Jain",
      "role": "customer",
      "avatar": "https://res.cloudinary.com/gigconnect/image/upload/v1/avatar.jpg"
    },
    "receiver": {
      "id": "66da2c8762f9b8c02",
      "name": "Ramesh Kumar (Plumber)",
      "role": "worker",
      "avatar": "https://res.cloudinary.com/gigconnect/image/upload/v1/worker.jpg"
    }
  }
  ```

- **Error Responses:**
  - **400 Bad Request (Worker Not Assigned):**
    ```json
    {
      "success": false,
      "message": "Worker is not yet assigned for this booking. Call cannot be placed."
    }
    ```
  - **400 Bad Request (Invalid Status, e.g. Cancelled/Completed):**
    ```json
    {
      "success": false,
      "message": "Audio calling is not allowed for booking in 'CANCELLED' status"
    }
    ```
  - **403 Forbidden (Unauthorized Caller):**
    ```json
    {
      "success": false,
      "message": "Access denied. You are not a participant in this booking."
    }
    ```
  - **404 Not Found:**
    ```json
    {
      "success": false,
      "message": "Booking not found"
    }
    ```

---

### API 3: Report Network Diagnostics & Firewall Block
Triggered by the mobile app if WebRTC ICE state fails due to strict Wi-Fi router UDP port blocking.

- **Method:** `POST`
- **Route:** `/api/webrtc/call/network-diagnostics`
- **Request Body:**
  ```json
  {
    "bookingId": "#BK-260906-01042A8F",
    "networkType": "wifi",
    "iceConnectionState": "failed",
    "details": "UDP packet blocked by corporate router firewall"
  }
  ```
- **Response (400 Bad Request - Wi-Fi Restriction Detected):**
  ```json
  {
    "success": false,
    "errorCode": "FIREWALL_BLOCKED_WIFI_RESTRICTION",
    "message": "Aapke Wi-Fi network ya router firewall ne audio call ports block kar diye hain. Kripya apna Wi-Fi band karke mobile data (personal internet) chalu karein aur call dobara lagayein.",
    "suggestion": "SWITCH_TO_MOBILE_DATA",
    "networkType": "wifi",
    "retryable": true
  }
  ```

---

### API 4: Get Live Call Status from Redis
Checks whether the call is currently ringing, connected, or idle.

- **Method:** `GET`
- **Route:** `/api/webrtc/call/status/:bookingId`
- **Response (200 OK):**
  ```json
  {
    "success": true,
    "status": "RINGING",
    "callSession": {
      "bookingId": "#BK-260906-01042A8F",
      "status": "RINGING",
      "callerRole": "customer",
      "callerId": "66da1b9872f9b8c01",
      "initiatedAt": 1725612345678
    }
  }
  ```

---

### API 5: Get Masked Call History
Returns call logs for the logged-in user without exposing phone numbers.

- **Method:** `GET`
- **Route:** `/api/webrtc/call/history`
- **Response (200 OK):**
  ```json
  {
    "success": true,
    "count": 1,
    "calls": [
      {
        "_id": "66da3d9872f9b8c03",
        "bookingId": "#BK-260906-01042A8F",
        "caller": { "name": "Ramesh Kumar", "avatar": "...", "role": "worker" },
        "receiver": { "name": "Vaibhav Jain", "avatar": "...", "role": "customer" },
        "callerRole": "worker",
        "status": "COMPLETED",
        "durationSeconds": 64,
        "endReason": "NORMAL_HANGUP",
        "createdAt": "2026-09-06T03:30:00.000Z"
      }
    ]
  }
  ```

---

## 4. COMPLETE SOCKET.IO REAL-TIME SIGNALING DICTIONARY

**Connection URL:** `http://<BACKEND_HOST>:8000`  
**Transport:** `websocket`

> [!NOTE]
> **Dual-Room Alias Support**: Backend automatically handles rooms for both `#BK-260906-01042A8F` and `BK-260906-01042A8F` and MongoDB `_id`. Frontend can pass either form safely without messaging drop.

### Client to Server Events (App Emits)

| Event Name | When to Emit | Payload Structure |
| :--- | :--- | :--- |
| `webrtc:join-room` | Immediately after `call/initiate` succeeds or when receiving call | `{"bookingId": "#BK-260906-01042A8F", "userId": "66da1b9872f9..."}` |
| `webrtc:call-initiate` | Caller starts ringing peer | `{"bookingId": "#BK-260906-01042A8F", "callerId": "...", "callerName": "Vaibhav", "callerRole": "customer", "callerAvatar": "url"}` |
| `webrtc:call-accept` | Recipient taps green "Accept" button | `{"bookingId": "#BK-260906-01042A8F", "receiverId": "..."}` |
| `webrtc:call-reject` | Recipient taps red "Decline" button | `{"bookingId": "#BK-260906-01042A8F", "reason": "DECLINED"}` *(or "BUSY")* |
| `webrtc:offer` | Caller creates WebRTC SDP Offer | `{"bookingId": "#BK-260906-01042A8F", "sdp": {"type": "offer", "sdp": "..."}}` |
| `webrtc:answer` | Recipient creates WebRTC SDP Answer | `{"bookingId": "#BK-260906-01042A8F", "sdp": {"type": "answer", "sdp": "..."}}` |
| `webrtc:ice-candidate`| Local ICE candidate generated | `{"bookingId": "#BK-260906-01042A8F", "candidate": {"candidate": "...", "sdpMid": "0", "sdpMLineIndex": 0}}` |
| `webrtc:ice-failed` | ICE state becomes 'failed' on Wi-Fi | `{"bookingId": "#BK-260906-01042A8F", "networkType": "wifi", "iceState": "failed"}` |
| `webrtc:call-hangup` | User taps red "End Call" button | `{"bookingId": "#BK-260906-01042A8F", "durationSeconds": 45, "endReason": "NORMAL_HANGUP"}` |

---

### Server to Client Events (App Listens)

| Event Name | Meaning / Description | Payload Structure | Action Required by Flutter App |
| :--- | :--- | :--- | :--- |
| `webrtc:room-joined` | Confirmation that socket entered channel | `{"bookingId": "...", "room": "...", "role": "customer"}` | Proceed to initiate call or wait for offer |
| `webrtc:incoming-call` | In-app incoming call alert (foreground) | `{"bookingId": "...", "caller": {"name": "...", "role": "...", "avatar": "..."}}` | Show in-app incoming call bottom sheet / dialog |
| `webrtc:call-accepted` | Peer accepted your call | `{"bookingId": "...", "receiverId": "..."}` | Caller creates WebRTC SDP Offer and emits `webrtc:offer` |
| `webrtc:call-rejected` | Peer declined or was busy | `{"bookingId": "...", "reason": "DECLINED"}` | Play busy tone, show "Call Declined", pop screen |
| `webrtc:offer` | Received SDP Offer from caller | `{"bookingId": "...", "sdp": {...}}` | Set remote description, create answer, emit `webrtc:answer` |
| `webrtc:answer` | Received SDP Answer from receiver | `{"bookingId": "...", "sdp": {...}}` | Set remote description (audio established!) |
| `webrtc:ice-candidate`| Received ICE candidate from peer | `{"bookingId": "...", "candidate": {...}}` | Add candidate to `peerConnection` |
| `webrtc:call-ended` | Peer clicked Hangup | `{"bookingId": "...", "durationSeconds": 45}` | Stop audio, play disconnect sound, close call screen |
| `webrtc:error` | Firewall / Connection Error | `{"errorCode": "FIREWALL_BLOCKED_WIFI_RESTRICTION", "suggestion": "SWITCH_TO_MOBILE_DATA"}` | Show prompt dialog: *"Turn off Wi-Fi and switch to Mobile Data"* |
| `webrtc:peer-network-issue` | Counterpart has firewall trouble | `{"message": "Doosre user ka Wi-Fi firewall block kar raha hai..."}` | Show toast: *"Waiting for peer to switch to Mobile Data..."* |

---

## 5. CLOSED / KILLED APP VOIP PUSH MECHANISM (WHATSAPP STYLE)

When the recipient's mobile app is **closed (terminated)** or in the background with screen locked:
1. Socket.io cannot deliver events directly.
2. The backend automatically dispatches a high-priority FCM VoIP message:
   ```json
   {
     "priority": "high",
     "data": {
       "type": "INCOMING_CALL",
       "callSessionId": "call_#BK-260906-01042A8F_1725612345",
       "bookingId": "#BK-260906-01042A8F",
       "callerName": "Ramesh Worker",
       "callerAvatar": "https://res.cloudinary.com/.../avatar.jpg",
       "callerRole": "worker",
       "serviceTitle": "Plumbing Repair",
       "hasAudio": "true"
     }
   }
   ```
3. The Flutter background messaging handler invokes `FlutterCallkitIncoming.showCallkitIncoming(params)`.
4. The OS displays the native incoming call UI (same as WhatsApp, Truecaller, or Phone app):
   - Wakes up the screen.
   - Plays ringing sound and vibrates.
   - Shows green "Accept" button and red "Decline" button.
5. If the caller hangs up before the call is answered, the backend sends a dismiss push with `type: 'CANCEL_CALL'`, causing the phone to stop ringing immediately.

---

## 6. WI-FI FIREWALL & STRICT NAT DIAGNOSTICS HANDLING

### The Issue
Some office, college, or strict home Wi-Fi routers block UDP traffic (ports 3478, 1024–65535) or symmetric NAT prevents direct P2P audio streaming, leading to `iceConnectionState == 'failed'`.

### The Resolution Steps
1. Mobile app monitors `peerConnection.onIceConnectionState`.
2. When state changes to `RTCIceConnectionStateFailed`:
   - Checks network type using `connectivity_plus`.
   - If connected via Wi-Fi:
     - Emits `webrtc:ice-failed` with `{ bookingId, networkType: 'wifi' }` or calls `POST /api/webrtc/call/network-diagnostics`.
3. Backend returns code `FIREWALL_BLOCKED_WIFI_RESTRICTION`.
4. Mobile app displays a user-friendly alert dialog:
   > **"Wi-Fi Firewall Blocked"**  
   > *"Aapke Wi-Fi router ya firewall ne audio call ko block kar diya hai. Kripya apna Wi-Fi band karein aur personal Mobile Data on karein."*  
   > `[ Switch to Mobile Data & Retry ]`

---

## 7. FLUTTER PRODUCTION CODE IMPLEMENTATION

### A. Dependencies & Native Permissions

#### `pubspec.yaml`:
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_webrtc: ^0.12.5
  socket_io_client: ^3.0.2
  flutter_callkit_incoming: ^2.4.4
  firebase_messaging: ^15.2.4
  connectivity_plus: ^6.1.4
  permission_handler: ^11.4.0
  http: ^1.2.2
```

#### Android (`android/app/src/main/AndroidManifest.xml`):
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT" />
    <uses-permission android:name="android.permission.VIBRATE" />
    <uses-permission android:name="android.permission.WAKE_LOCK" />
</manifest>
```

#### iOS (`ios/Runner/Info.plist`):
```xml
<key>NSMicrophoneUsageDescription</key>
<string>GigConnect requires microphone access to enable internet audio calling between customer and worker.</string>
<key>UIBackgroundModes</key>
<array>
    <string>voip</string>
    <string>audio</string>
    <string>remote-notification</string>
</array>
```

---

### B. Background VoIP Push Handler (`main.dart`)
Place this at the very top level of `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  final data = message.data;
  if (data['type'] == 'INCOMING_CALL') {
    CallKitParams params = CallKitParams(
      id: data['callSessionId'],
      nameCaller: data['callerName'] ?? 'GigConnect User',
      appName: 'GigConnect',
      avatar: data['callerAvatar'],
      handle: data['serviceTitle'] ?? 'Audio Calling',
      type: 0, // 0 = Audio Call
      duration: 30000,
      textAccept: 'Accept',
      textDecline: 'Decline',
      extra: <String, dynamic>{
        'bookingId': data['bookingId'],
        'callerId': data['callerId'],
        'callerRole': data['callerRole'],
      },
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#0955fa',
        actionColor: '#4CAF50',
      ),
      ios: const IOSParams(
        iconName: 'AppIcon',
        handleType: 'generic',
        supportsVideo: false,
        maximumCallGroups: 1,
        maximumCallsPerCallGroup: 1,
        audioSessionMode: 'voiceChat',
        audioSessionActive: true,
      ),
    );

    await FlutterCallkitIncoming.showCallkitIncoming(params);
  } else if (data['type'] == 'CANCEL_CALL') {
    await FlutterCallkitIncoming.endCall(data['callSessionId']);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const MyApp());
}
```

---

### C. WebRTC & Socket Call Service (`lib/services/webrtc_call_service.dart`)

```dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

enum CallState { idle, initiating, ringing, connected, ended, failed }

class WebRTCCallService {
  final String serverUrl = "http://YOUR_SERVER_IP:8000";
  late IO.Socket socket;
  RTCPeerConnection? peerConnection;
  MediaStream? localStream;

  CallState currentState = CallState.idle;
  String? currentBookingId;
  String? currentUserId;
  int callDurationSeconds = 0;
  Timer? durationTimer;

  // Callbacks for UI updates
  Function(CallState state)? onCallStateChanged;
  Function(Map<String, dynamic> caller)? onIncomingCall;
  Function(String message)? onFirewallError;

  void initializeSocket(String token, String userId) {
    currentUserId = userId;
    socket = IO.io(serverUrl, IO.OptionBuilder()
      .setTransports(['websocket'])
      .disableAutoConnect()
      .setExtraHeaders({'Authorization': 'Bearer $token'})
      .build());

    socket.connect();
    _bindSocketListeners();
  }

  void _bindSocketListeners() {
    // 1. Room Joined Confirmation
    socket.on('webrtc:room-joined', (data) {
      print("[WebRTC] Joined room: ${data['room']}");
    });

    // 2. In-App Incoming Call (When recipient is already active in app)
    socket.on('webrtc:incoming-call', (data) {
      if (currentState == CallState.idle) {
        currentBookingId = data['bookingId'];
        _setCallState(CallState.ringing);
        onIncomingCall?.call(Map<String, dynamic>.from(data['caller']));
      }
    });

    // 3. Caller receives call accepted -> Creates Offer
    socket.on('webrtc:call-accepted', (data) async {
      _setCallState(CallState.connected);
      _startDurationTimer();

      RTCSessionDescription offer = await peerConnection!.createOffer({
        'offerToReceiveAudio': 1,
        'offerToReceiveVideo': 0,
      });
      await peerConnection!.setLocalDescription(offer);

      socket.emit('webrtc:offer', {
        'bookingId': currentBookingId,
        'sdp': offer.toMap(),
      });
    });

    // 4. Receiver receives offer -> Creates Answer
    socket.on('webrtc:offer', (data) async {
      await peerConnection!.setRemoteDescription(
        RTCSessionDescription(data['sdp']['sdp'], data['sdp']['type']),
      );
      RTCSessionDescription answer = await peerConnection!.createAnswer();
      await peerConnection!.setLocalDescription(answer);

      socket.emit('webrtc:answer', {
        'bookingId': currentBookingId,
        'sdp': answer.toMap(),
      });
    });

    // 5. Caller receives answer
    socket.on('webrtc:answer', (data) async {
      await peerConnection!.setRemoteDescription(
        RTCSessionDescription(data['sdp']['sdp'], data['sdp']['type']),
      );
    });

    // 6. ICE Candidate Exchange
    socket.on('webrtc:ice-candidate', (data) async {
      final cand = data['candidate'];
      await peerConnection?.addCandidate(
        RTCIceCandidate(cand['candidate'], cand['sdpMid'], cand['sdpMLineIndex']),
      );
    });

    // 7. Call Rejected or User Busy
    socket.on('webrtc:call-rejected', (data) {
      _setCallState(CallState.ended);
      cleanupCall();
    });

    // 8. Call Ended by Peer
    socket.on('webrtc:call-ended', (data) {
      _setCallState(CallState.ended);
      cleanupCall();
    });

    // 9. Wi-Fi Firewall Error Detected
    socket.on('webrtc:error', (error) {
      if (error['errorCode'] == 'FIREWALL_BLOCKED_WIFI_RESTRICTION') {
        _setCallState(CallState.failed);
        onFirewallError?.call(error['message'] ?? 'Wi-Fi firewall blocking audio call.');
      }
    });
  }

  // ===========================================================================
  // START OUTGOING CALL (Triggered by Call Icon Tap)
  // ===========================================================================
  Future<bool> startCall({required String bookingId, required String token}) async {
    currentBookingId = bookingId;
    _setCallState(CallState.initiating);

    // Step 1: Request Microphone Permission
    var status = await Permission.microphone.request();
    if (!status.isGranted) {
      _setCallState(CallState.failed);
      return false;
    }

    try {
      // Step 2: Hit REST API to initiate and authorize call
      final initRes = await http.post(
        Uri.parse('$serverUrl/api/webrtc/call/initiate'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'bookingId': bookingId}),
      );

      final initData = jsonDecode(initRes.body);
      if (initRes.statusCode != 200 || !initData['success']) {
        _setCallState(CallState.failed);
        return false;
      }

      // Step 3: Fetch ICE Servers (STUN/TURN)
      final iceRes = await http.get(
        Uri.parse('$serverUrl/api/webrtc/config/ice-servers'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final iceData = jsonDecode(iceRes.body);

      // Step 4: Create PeerConnection
      Map<String, dynamic> rtcConfig = {
        'iceServers': iceData['iceServers'],
        'sdpSemantics': 'unified-plan',
      };
      peerConnection = await createPeerConnection(rtcConfig);

      // Step 5: Get Microphone Track
      localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': false,
      });
      localStream!.getTracks().forEach((track) {
        peerConnection!.addTrack(track, localStream!);
      });

      // Step 6: Listen for ICE Candidates
      peerConnection!.onIceCandidate = (candidate) {
        socket.emit('webrtc:ice-candidate', {
          'bookingId': bookingId,
          'candidate': candidate.toMap(),
        });
      };

      // Step 7: Listen for ICE State (Detect Wi-Fi Firewall Block)
      peerConnection!.onIceConnectionState = (state) async {
        if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
          var connectivity = await Connectivity().checkConnectivity();
          bool isWifi = connectivity.contains(ConnectivityResult.wifi);

          socket.emit('webrtc:ice-failed', {
            'bookingId': bookingId,
            'networkType': isWifi ? 'wifi' : 'cellular',
            'iceState': 'failed',
          });
        }
      };

      // Step 8: Join Socket Room & Trigger Ring
      socket.emit('webrtc:join-room', {
        'bookingId': bookingId,
        'userId': currentUserId,
      });

      socket.emit('webrtc:call-initiate', {
        'bookingId': bookingId,
        'callerId': currentUserId,
        'callerRole': initData['caller']['role'],
        'callerName': initData['caller']['name'],
        'callerAvatar': initData['caller']['avatar'],
      });

      _setCallState(CallState.ringing);
      return true;
    } catch (e) {
      print('[WebRTC] Start call exception: $e');
      _setCallState(CallState.failed);
      return false;
    }
  }

  // ===========================================================================
  // ACCEPT INCOMING CALL
  // ===========================================================================
  Future<void> acceptCall({required String bookingId, required String token}) async {
    currentBookingId = bookingId;
    _setCallState(CallState.connected);
    _startDurationTimer();

    await Permission.microphone.request();

    // Fetch ICE servers & Create Peer Connection
    final iceRes = await http.get(
      Uri.parse('$serverUrl/api/webrtc/config/ice-servers'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final iceData = jsonDecode(iceRes.body);

    peerConnection = await createPeerConnection({
      'iceServers': iceData['iceServers'],
      'sdpSemantics': 'unified-plan',
    });

    localStream = await navigator.mediaDevices.getUserMedia({'audio': true, 'video': false});
    localStream!.getTracks().forEach((track) {
      peerConnection!.addTrack(track, localStream!);
    });

    peerConnection!.onIceCandidate = (candidate) {
      socket.emit('webrtc:ice-candidate', {
        'bookingId': bookingId,
        'candidate': candidate.toMap(),
      });
    };

    socket.emit('webrtc:join-room', {'bookingId': bookingId, 'userId': currentUserId});
    socket.emit('webrtc:call-accept', {'bookingId': bookingId, 'receiverId': currentUserId});
  }

  // ===========================================================================
  // REJECT CALL
  // ===========================================================================
  void rejectCall() {
    if (currentBookingId != null) {
      socket.emit('webrtc:call-reject', {
        'bookingId': currentBookingId,
        'reason': 'DECLINED',
      });
    }
    _setCallState(CallState.ended);
    cleanupCall();
  }

  // ===========================================================================
  // HANGUP / END CALL
  // ===========================================================================
  void hangUp() {
    if (currentBookingId != null) {
      socket.emit('webrtc:call-hangup', {
        'bookingId': currentBookingId,
        'durationSeconds': callDurationSeconds,
        'endReason': 'NORMAL_HANGUP',
      });
    }
    _setCallState(CallState.ended);
    cleanupCall();
  }

  void cleanupCall() {
    durationTimer?.cancel();
    callDurationSeconds = 0;
    localStream?.dispose();
    peerConnection?.close();
    peerConnection = null;
    localStream = null;
  }

  void _startDurationTimer() {
    durationTimer?.cancel();
    callDurationSeconds = 0;
    durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      callDurationSeconds++;
      onCallStateChanged?.call(currentState);
    });
  }

  void _setCallState(CallState state) {
    currentState = state;
    onCallStateChanged?.call(state);
  }
}
```

---

### D. In-Call UI Screen (`lib/screens/call_screen.dart`)

```dart
import 'package:flutter/material.dart';
import '../services/webrtc_call_service.dart';

class CallScreen extends StatefulWidget {
  final WebRTCCallService callService;
  final String peerName;
  final String peerRole;
  final String? peerAvatar;
  final String serviceTitle;

  const CallScreen({
    Key? key,
    required this.callService,
    required this.peerName,
    required this.peerRole,
    this.peerAvatar,
    required this.serviceTitle,
  }) : super(key: key);

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  bool isMuted = false;
  bool isSpeakerOn = false;

  @override
  void initState() {
    super.initState();
    widget.callService.onCallStateChanged = (state) {
      if (mounted) setState(() {});
      if (state == CallState.ended) {
        Navigator.pop(context);
      }
    };

    widget.callService.onFirewallError = (message) {
      _showFirewallDialog(message);
    };
  }

  void _showFirewallDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Wi-Fi Firewall Issue', style: TextStyle(color: Colors.red)),
        content: Text(message),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // close call screen, user will switch network & retry
            },
            child: const Text('OK, Switch to Mobile Data'),
          )
        ],
      ),
    );
  }

  String _formatTimer(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.callService.currentState;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Caller/Receiver Masked Info
            Column(
              children: [
                CircleAvatar(
                  radius: 54,
                  backgroundImage: widget.peerAvatar != null
                      ? NetworkImage(widget.peerAvatar!)
                      : null,
                  child: widget.peerAvatar == null
                      ? const Icon(Icons.person, size: 54, color: Colors.white)
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  widget.peerName,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  "${widget.peerRole.toUpperCase()} • ${widget.serviceTitle}",
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
                const SizedBox(height: 12),
                Text(
                  state == CallState.initiating
                      ? "Connecting..."
                      : state == CallState.ringing
                          ? "Ringing..."
                          : state == CallState.connected
                              ? _formatTimer(widget.callService.callDurationSeconds)
                              : "Ending...",
                  style: const TextStyle(fontSize: 18, color: Colors.greenAccent, fontWeight: FontWeight.w600),
                ),
              ],
            ),

            // Call Action Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Mute/Unmute
                IconButton(
                  iconSize: 32,
                  icon: Icon(isMuted ? Icons.mic_off : Icons.mic, color: Colors.white),
                  onPressed: () {
                    setState(() => isMuted = !isMuted);
                    widget.callService.localStream?.getAudioTracks().forEach((track) {
                      track.enabled = !isMuted;
                    });
                  },
                ),

                // End Call (Hangup)
                FloatingActionButton(
                  backgroundColor: Colors.red,
                  onPressed: () => widget.callService.hangUp(),
                  child: const Icon(Icons.call_end, color: Colors.white, size: 30),
                ),

                // Speaker On/Off
                IconButton(
                  iconSize: 32,
                  icon: Icon(isSpeakerOn ? Icons.volume_up : Icons.volume_down, color: Colors.white),
                  onPressed: () {
                    setState(() => isSpeakerOn = !isSpeakerOn);
                    widget.callService.localStream?.getAudioTracks().forEach((track) {
                      track.enableSpeakerphone(isSpeakerOn);
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 8. SUMMARY CHECKLIST FOR FRONTEND DEPLOYMENT
- [x] Use `POST /api/webrtc/call/initiate` on call icon press.
- [x] Use `GET /api/webrtc/config/ice-servers` for STUN configuration.
- [x] Display masked caller info on screen (Real phone numbers never displayed).
- [x] Register `_firebaseMessagingBackgroundHandler` in `main.dart` with `flutter_callkit_incoming` for WhatsApp-style incoming calls.
- [x] Handle `FIREWALL_BLOCKED_WIFI_RESTRICTION` error event to advise user to switch to mobile data.
- [x] Emit `webrtc:call-hangup` on end call to log duration and dismiss incoming push notifications.
