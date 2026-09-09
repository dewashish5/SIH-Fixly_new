# Implementation Plan: "Hey Flexi" Conversational AI Voice/Text Agent

Implement complete "Hey Flexi" Conversational Voice & Text AI workflow per specification:
1. Floating Mic / "Hey Flexi" Button on Customer Home.
2. Full multi-turn state preservation (`conversationState`).
3. STT (Speech-to-Text) + TTS (Flutter TTS) in Hindi (`'hi'`) and English (`'en'`).
4. Location & Address payload delivery (`coordinates: [lng, lat]`, `addressLine`).
5. Session handling (`SESSION_EXPIRED` resets state, `SESSION_ABORTED` dismisses modal/resets).
6. Auto-navigation to Live Tracking (`RouteNames.customerTracking`) on `BOOKING_CREATED`.

## Proposed Changes

### AI Repository
#### [MODIFY] [ai_api_repository.dart](file:///Users/dewashishhatekar/Developer/Projects/SIH-Fixly/frontend/lib/features/ai/data/ai_api_repository.dart)
- Pass clean payload with `coordinates`, `addressLine`, and `language`.
- Gracefully handle `state`, `action`, `booking`, `bookings`.

### Permissions & Speech Integration
#### [MODIFY] [AndroidManifest.xml](file:///Users/dewashishhatekar/Developer/Projects/SIH-Fixly/frontend/android/app/src/main/AndroidManifest.xml)
- Add `<action android:name="android.speech.RecognitionService" />` inside `<queries>` for Android 11+ Google Speech Recognition access.
- Add `<uses-permission android:name="android.permission.BLUETOOTH" />` & `<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />`.

#### [MODIFY] [Info.plist](file:///Users/dewashishhatekar/Developer/Projects/SIH-Fixly/frontend/ios/Runner/Info.plist)
- Add `NSMicrophoneUsageDescription` and `NSSpeechRecognitionUsageDescription`.

#### [MODIFY] [speech_service.dart](file:///Users/dewashishhatekar/Developer/Projects/SIH-Fixly/frontend/lib/services/speech_service.dart)
- Request `Permission.microphone` and `Permission.speech` on `initialize()` using `permission_handler`.
- Configure natural human conversation mode (dynamic speech rate, auto locale, interrupt handling).

### Customer Home Page
#### [MODIFY] [customer_home_page.dart](file:///Users/dewashishhatekar/Developer/Projects/SIH-Fixly/frontend/lib/features/customer/presentation/pages/customer_home_page.dart)
- Add Floating Mic / "Hey Flexi" Action Button with glowing pulse and tooltip.
- Tapping triggers `HeyFlexiVoiceSheet.show(context)` to talk immediately.

### Customer AI Helper Page
#### [MODIFY] [customer_ai_helper_page.dart](file:///Users/dewashishhatekar/Developer/Projects/SIH-Fixly/frontend/lib/features/customer/presentation/pages/customer_ai_helper_page.dart)
- Inject device GPS coordinates (`AppLocation.instance`) and locale language.
- Implement session handling for `SESSION_EXPIRED`, `SESSION_ABORTED`, and `BOOKING_CREATED` auto-routing to tracking.

Structure the document into:
1. **Executive Summary & Scope**: Overview of commit `70ceced78dbfa61b7ad8ffaa4e63e2bad09e42c8`, file breakdown (11 backend files), architectural intent.
2. **Feature Deep Dives & Data Flows**:
   - **Feature 1: Customer Booking Update & Worker Re-dispatch**:
     - Flow: Client PATCH → Auth & ownership check → status guards → field mutation → state reset (`PENDING`, `worker=null`) → Socket.IO emission (`booking:updated`) → Worker notification (`NEW_BOOKING_AVAILABLE`).
   - **Feature 2: Promotional Coupon Banners System**:
     - Model schema (`Banner`), auto-seeding logic (`seedDefaultBannersIfEmpty`), public customer endpoint (`GET /api/home/banners`), integration in `homeController.js` (`getHomeData`), and secure Admin CRUD (`GET`, `POST`, `PUT`, `DELETE` on `/api/admin/banners`).
   - **Feature 3: Worker Category Matching & Alias Normalization**:
     - Alias mapping logic, regex safety, matching against `workerProfile.category`, `categories`, and `categoryRates.category`.
3. **Complete Code Implementation File-by-File**:
   - `backend/models/Banner.js` (Complete File)
   - `backend/utils/workerCategoryFilter.js` (Complete File)
   - `backend/controllers/bannerController.js` (Complete File)
   - `backend/routes/home-routes.js` (Complete File / Exact additions)
   - `backend/routes/booking-routes.js` (Complete File / Exact additions)
   - `backend/routes/admin-routes.js` (Exact additions + context)
   - `backend/controllers/bookingController.js` (Complete `updateBooking` controller implementation)
   - `backend/controllers/homeController.js` (Exact diff / updated `getHomeData`)
   - `backend/controllers/workerController.js` (Exact diff / updated `getNearbyWorkers`)
   - `backend/tests/bookingUpdateRoute.test.js` (Complete File)
   - `backend/tests/workerCategoryFilter.test.js` (Complete File)
4. **Step-by-Step Integration & Verification Guide**:
   - Order of operations to apply changes.
   - Socket.IO & notification dependencies check.
   - Automated tests execution via `node --test`.
   - Sample cURL requests for testing all new endpoints.

## Verification Plan

### Automated Verification
- Verify that `backend_changes.md` exists and contains full code snippets without missing functions.
- Run tests in backend to confirm code accuracy:
  ```bash
  node --test backend/tests/bookingUpdateRoute.test.js
  node --test backend/tests/workerCategoryFilter.test.js
  ```
