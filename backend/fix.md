# Fixly Conversational AI Assistant - Flutter Integration Guide & API Contract

This document contains the complete API specification, request/response payloads, and Flutter implementation instructions for the **Fixly Conversational AI Voice & Text Booking Assistant**. A frontend developer or AI coding tool can directly use this specification to generate Flutter models, API services, state management, and UI widgets.

---

## 1. API Endpoint Overview

- **Endpoint:** `POST /api/ai/agent/chat` (Alias: `POST /api/agent/chat`)
- **Base URL:** `http://<your-server-host>:8005` (e.g. `http://10.0.2.2:8005` for Android Emulator, `http://localhost:8005` for iOS Simulator)
- **Method:** `POST`
- **Content-Type:** `application/json`
- **Authentication:** Bearer Token in `Authorization` header (`Bearer <jwt_token>`). Optional: Guest mode works with `x-user-id` header or anonymous session.

---

## 2. Request Payload Schema

Every time the user speaks or types a message, send a `POST` request with the following JSON body:

```json
{
  "message": "My kitchen sink pipe is broken and leaking water everywhere, need a plumber urgently",
  "language": "en",
  "coordinates": [77.3639, 28.6280],
  "addressLine": "Flat 402, Green Valley Apartments, Noida",
  "conversationState": {}
}
```

### Request Fields:

| Field | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `message` | `String` | **Yes** | The user's input text (or transcribed speech from STT). |
| `language` | `String` | No | `"en"` for Pure English (Default), `"hi"` for Pure Hindi (देवनागरी). |
| `coordinates` | `List<double>` | No | Customer's GPS coordinates `[longitude, latitude]` for nearest worker matching. |
| `addressLine` | `String` | No | Customer's human-readable service delivery address. |
| `conversationState`| `Map<String, dynamic>` | No | Pass the `state` object received from the previous assistant turn to preserve multi-turn context (category, worker, step, etc.). |

---

## 3. Response Payload Schema & Actions

The backend returns a unified, structured response:

```json
{
  "success": true,
  "reply": "Conversational message to render inside the chat bubble",
  "action": "PROMPT_CONFIRMATION",
  "state": { ... },
  "data": { ... },
  "suggestedReplies": [ ... ]
}
```

### Supported `action` Enums & What to Render in Flutter:

| `action` Value | Meaning / Current Flow | UI Component to Render |
| :--- | :--- | :--- |
| `PROMPT_CATEGORY` | Needs user to pick or describe a home service. | Chat Bubble + Suggested category chips. |
| `CATEGORY_NOT_SUPPORTED` | User asked for an unsupported service (e.g. car repair). | Friendly error bubble + active services chips. |
| `PROMPT_BOOKING_TYPE` | Service identified. Asking if Standard, Emergency SOS, or Scheduled. | Chat Bubble + 3 chips: `[⚡ Emergency SOS]`, `[⏱️ Standard]`, `[📅 Schedule for Later]`. |
| `PROMPT_WORKER_SELECTION` | Shows nearby online workers for user selection. | Worker Cards Horizontal List / Carousel + `[Auto-assign nearest]` chip. |
| `PROMPT_CONFIRMATION` | Nearest worker matched & cost computed. Awaiting final user confirmation. | **Price Breakdown Card** + **Worker Preview Card** + **Cooperative Fair Wage Card** + `[Yes, confirm booking]`, `[Cancel]`. |
| `BOOKING_CREATED` | Booking successfully written to MongoDB! Worker dispatched in real-time. | **Green Booking Success Card** with `#BK-...` Booking ID, OTP, and status. |
| `BOOKING_STATUS` | User asked to track an active or recent booking. | **Live Booking Status Card** with assigned worker info. |
| `NO_WORKERS_AVAILABLE` | Zero workers available in customer's search radius. | Warning bubble + `[📅 Schedule for Later]` chip. |
| `OFF_TOPIC_GUARD` | User asked about cricket, movies, politics, homework, etc. | Scope refusal bubble redirecting back to Fixly home gig services. |
| `SESSION_ABORTED` | User cancelled the flow. | Cancellation message bubble + `[Book another service]` chip. |

---

## 4. End-to-End Concrete JSON Examples

### Turn 1: User requests an emergency service
**Request Body:**
```json
{
  "message": "my home will be short circuit emergency plumber or electrician",
  "language": "en",
  "coordinates": [77.3639, 28.6280],
  "addressLine": "Flat 402, Green Valley Apartments, Noida"
}
```

**Response Payload (Action: `PROMPT_CONFIRMATION`):**
```json
{
  "success": true,
  "reply": "⚡ Emergency SOS Dispatch Ready:\n• Worker: Vaibhav Jain (5★, 1.2 km away)\n• Total Amount: ₹250 (Includes ₹50 emergency fee, ₹0 platform fee)\n• Task: \"Urgently diagnose and repair the short circuit to restore safe electrical operation.\"\n\nShall I confirm immediate dispatch? (Reply Yes / No)",
  "action": "PROMPT_CONFIRMATION",
  "state": {
    "category": "Electrical",
    "bookingType": "EMERGENCY_SOS",
    "isEmergency": true,
    "workerId": "6a9d255bf09b371a043e8b77",
    "workerName": "Vaibhav Jain",
    "workerRate": 200,
    "problemDescription": "Urgently diagnose and repair the short circuit to restore safe electrical operation.",
    "step": "AWAITING_CONFIRMATION",
    "language": "en"
  },
  "data": {
    "category": "Electrical",
    "step": "AWAITING_CONFIRMATION",
    "workers": [
      {
        "_id": "6a9d255bf09b371a043e8b77",
        "name": "Vaibhav Jain",
        "phone": "+91 6377137304",
        "avatar": "https://res.cloudinary.com/demo/image/upload/avatar1.jpg",
        "rating": 5.0,
        "hourlyRate": 200,
        "experienceYears": 3,
        "distanceKm": 1.2
      }
    ],
    "estimate": {
      "baseServiceFee": 200,
      "urgentFee": 50,
      "platformFee": 0,
      "welfareContribution": 10,
      "totalAmount": 250,
      "currency": "INR"
    },
    "policy": {
      "title": "Fixly Cooperative Fair Wage Guarantee",
      "fairWageNotice": "100% of the service fee goes directly to the cooperative worker.",
      "welfareFundNotice": "Includes 5% contribution to Worker Social Security & Medical Accident Fund.",
      "platformCommission": "0% Platform Fee (No Middleman)"
    }
  },
  "suggestedReplies": [
    "Yes, confirm booking",
    "Cancel"
  ]
}
```

---

### Turn 2: User confirms booking ("Yes, confirm")
**Request Body:**
```json
{
  "message": "Yes, confirm booking",
  "language": "en",
  "conversationState": {
    "category": "Electrical",
    "bookingType": "EMERGENCY_SOS",
    "isEmergency": true,
    "workerId": "6a9d255bf09b371a043e8b77",
    "step": "AWAITING_CONFIRMATION"
  }
}
```

**Response Payload (Action: `BOOKING_CREATED`):**
```json
{
  "success": true,
  "reply": "🎉 Congratulations! Your Electrical booking #BK-260910-00841D9A has been confirmed! Total estimated fee: ₹250. Assigned worker Vaibhav Jain has been dispatched.",
  "action": "BOOKING_CREATED",
  "state": {
    "category": "Electrical",
    "bookingType": "EMERGENCY_SOS",
    "isEmergency": true,
    "step": "COMPLETED",
    "language": "en"
  },
  "data": {
    "booking": {
      "_id": "66df849ba83f120034a1b099",
      "bookingId": "#BK-260910-00841D9A",
      "status": "PENDING",
      "bookingType": "EMERGENCY_SOS",
      "isEmergency": true,
      "arrivalOtp": "8492",
      "problemDescription": "Urgently diagnose and repair the short circuit to restore safe electrical operation.",
      "invoice": {
        "baseServiceFee": 200,
        "platformFee": 0,
        "urgentFee": 50,
        "couponDiscount": 0,
        "totalAmount": 250,
        "paymentStatus": "PENDING",
        "paymentMethod": "UPI"
      },
      "service": {
        "title": "Electrical Maintenance",
        "category": "electrical"
      },
      "worker": {
        "_id": "6a9d255bf09b371a043e8b77",
        "name": "Vaibhav Jain",
        "phone": "+91 6377137304"
      }
    }
  },
  "suggestedReplies": [
    "Track booking",
    "Book another service"
  ]
}
```

---

### Turn 3: User queries status ("Where is my worker / booking status?")
**Request Body:**
```json
{
  "message": "Where is my worker and what is the status of my booking?",
  "language": "en"
}
```

**Response Payload (Action: `BOOKING_STATUS`):**
```json
{
  "success": true,
  "reply": "Your recent booking #BK-260910-00841D9A (Electrical Maintenance) is currently \"PENDING\". Assigned worker: Vaibhav Jain (+91 6377137304).",
  "action": "BOOKING_STATUS",
  "data": {
    "bookings": [
      {
        "_id": "66df849ba83f120034a1b099",
        "bookingId": "#BK-260910-00841D9A",
        "status": "PENDING",
        "problemDescription": "Urgently diagnose and repair the short circuit",
        "worker": {
          "name": "Vaibhav Jain",
          "phone": "+91 6377137304"
        },
        "service": {
          "title": "Electrical Maintenance",
          "category": "electrical"
        }
      }
    ]
  },
  "suggestedReplies": [
    "Track booking",
    "Book another service"
  ]
}
```

---

## 5. Flutter Dart Models (Ready to Copy-Paste)

Create a file `lib/models/ai_agent_response.dart`:

```dart
class AiAgentResponse {
  final bool success;
  final String reply;
  final String action;
  final Map<String, dynamic>? state;
  final AiAgentData? data;
  final List<String> suggestedReplies;

  AiAgentResponse({
    required this.success,
    required this.reply,
    required this.action,
    this.state,
    this.data,
    this.suggestedReplies = const [],
  });

  factory AiAgentResponse.fromJson(Map<String, dynamic> json) {
    return AiAgentResponse(
      success: json['success'] ?? false,
      reply: json['reply'] ?? '',
      action: json['action'] ?? '',
      state: json['state'] as Map<String, dynamic>?,
      data: json['data'] != null ? AiAgentData.fromJson(json['data']) : null,
      suggestedReplies: (json['suggestedReplies'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

class AiAgentData {
  final String? step;
  final String? category;
  final List<AgentWorkerItem>? workers;
  final AgentEstimate? estimate;
  final AgentPolicy? policy;
  final Map<String, dynamic>? booking;
  final List<dynamic>? bookings;

  AiAgentData({
    this.step,
    this.category,
    this.workers,
    this.estimate,
    this.policy,
    this.booking,
    this.bookings,
  });

  factory AiAgentData.fromJson(Map<String, dynamic> json) {
    return AiAgentData(
      step: json['step'],
      category: json['category'],
      workers: json['workers'] != null
          ? (json['workers'] as List)
              .map((w) => AgentWorkerItem.fromJson(w))
              .toList()
          : null,
      estimate: json['estimate'] != null
          ? AgentEstimate.fromJson(json['estimate'])
          : null,
      policy: json['policy'] != null
          ? AgentPolicy.fromJson(json['policy'])
          : null,
      booking: json['booking'] as Map<String, dynamic>?,
      bookings: json['bookings'] as List<dynamic>?,
    );
  }
}

class AgentWorkerItem {
  final String id;
  final String name;
  final String? phone;
  final String? avatar;
  final double rating;
  final double hourlyRate;
  final int experienceYears;
  final double distanceKm;

  AgentWorkerItem({
    required this.id,
    required this.name,
    this.phone,
    this.avatar,
    required this.rating,
    required this.hourlyRate,
    required this.experienceYears,
    required this.distanceKm,
  });

  factory AgentWorkerItem.fromJson(Map<String, dynamic> json) {
    return AgentWorkerItem(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Cooperative Worker',
      phone: json['phone'],
      avatar: json['avatar'],
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble() ?? 200.0,
      experienceYears: (json['experienceYears'] as num?)?.toInt() ?? 0,
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

class AgentEstimate {
  final double baseServiceFee;
  final double urgentFee;
  final double platformFee;
  final double welfareContribution;
  final double totalAmount;
  final String currency;

  AgentEstimate({
    required this.baseServiceFee,
    required this.urgentFee,
    required this.platformFee,
    required this.welfareContribution,
    required this.totalAmount,
    required this.currency,
  });

  factory AgentEstimate.fromJson(Map<String, dynamic> json) {
    return AgentEstimate(
      baseServiceFee: (json['baseServiceFee'] as num?)?.toDouble() ?? 0.0,
      urgentFee: (json['urgentFee'] as num?)?.toDouble() ?? 0.0,
      platformFee: (json['platformFee'] as num?)?.toDouble() ?? 0.0,
      welfareContribution: (json['welfareContribution'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'INR',
    );
  }
}

class AgentPolicy {
  final String title;
  final String fairWageNotice;
  final String welfareFundNotice;
  final String platformCommission;

  AgentPolicy({
    required this.title,
    required this.fairWageNotice,
    required this.welfareFundNotice,
    required this.platformCommission,
  });

  factory AgentPolicy.fromJson(Map<String, dynamic> json) {
    return AgentPolicy(
      title: json['title'] ?? '',
      fairWageNotice: json['fairWageNotice'] ?? '',
      welfareFundNotice: json['welfareFundNotice'] ?? '',
      platformCommission: json['platformCommission'] ?? '',
    );
  }
}
```

---

## 6. Flutter API Service Client (Dio Example)

Create a file `lib/services/ai_agent_service.dart`:

```dart
import 'package:dio/dio.dart';
import '../models/ai_agent_response.dart';

class AiAgentService {
  final Dio _dio;

  AiAgentService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: 'http://10.0.2.2:8005/api', // Adjust for your environment
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
            ));

  Future<AiAgentResponse> sendMessage({
    required String message,
    String language = 'en',
    List<double>? coordinates,
    String? addressLine,
    Map<String, dynamic>? conversationState,
    String? userToken,
  }) async {
    final response = await _dio.post(
      '/ai/agent/chat',
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          if (userToken != null) 'Authorization': 'Bearer $userToken',
        },
      ),
      data: {
        'message': message,
        'language': language,
        if (coordinates != null) 'coordinates': coordinates,
        if (addressLine != null) 'addressLine': addressLine,
        if (conversationState != null) 'conversationState': conversationState,
      },
    );

    return AiAgentResponse.fromJson(response.data);
  }
}
```

---

## 7. UI Rendering Guidelines for Flutter

1. **Suggested Quick-Reply Chips (`suggestedReplies`)**:
   Render as a horizontal scrolling list of `ActionChip` widgets right above the message input bar. When the user taps a chip, send its text as the next `message`.

2. **Estimate & Policy Card (`res.data.estimate` & `res.data.policy`)**:
   Render when `action == 'PROMPT_CONFIRMATION'`. Display a clean card with:
   - Base Price: ₹`estimate.baseServiceFee`
   - Emergency Fee: ₹`estimate.urgentFee`
   - Platform Middleman Fee: ₹0 *(Fixly 0% Middleman Guarantee)*
   - **Total:** ₹`estimate.totalAmount`
   - Shield Icon with text: *"100% of the service fee goes directly to the cooperative worker."*

3. **Assigned Worker Card (`res.data.workers`)**:
   Display avatar, Name, Rating stars (`5.0 ★`), hourly rate, and proximity (e.g. `~1.2 km away`).

4. **Booking Confirmation Card (`res.data.booking`)**:
   Render when `action == 'BOOKING_CREATED'`. Show a green checkmark, the Booking ID (e.g. `#BK-260910-00841D9A`), and the Arrival Security OTP.

5. **Language Toggle**:
   Users can switch between **Pure English** (`"en"`) and **Pure Hindi** (`"hi"`). The agent strictly respects this setting and never replies in Romanized Hinglish.
