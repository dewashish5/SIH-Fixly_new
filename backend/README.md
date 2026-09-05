# 📱 GigConnect / SkillConnect Backend Service

This is the backend service for GigConnect (or SkillConnect), a platform connecting **Customers** and **Workers** (Professionals) for local on-demand services (e.g., Plumbing, Electrical, Home Cleaning). It features JWT Authentication with Refresh Token Rotation, real-time location tracking using Socket.io and MongoDB GeoJSON indices, background job processing with BullMQ & Redis, and Razorpay payment integration.

---

## 🚀 Key Features Implemented

1. **Authentication & Session Security**:
   - Register, Email OTP Verification, Login, and Google Auth.
   - **Refresh Token Rotation**: Protects users by generating a new Access Token and rotating the Refresh Token on every refresh request, invalidating old sessions.
   - **Single-Device Session Lock**: Tracks active device IDs via Redis. Logging in on a new device invalidates the session on the old device.
   - Secured `/api/auth/me` to get the logged-in user profile.
2. **Booking & Active Job Timeline**:
   - Estimate calculation based on labor hours and materials.
   - **Booking Creation**: Bookings created in `SEARCHING` (if no worker selected) or `ACCEPTED` status.
   - **Accept Booking**: Workers can accept a booking request, transitioning status to `ACCEPTED`.
   - **OTP Arrival Verification**: Secure 4-digit PIN verification when the worker arrives at the customer's location (`ARRIVED`).
   - **Start Job**: Transitions the booking from `ARRIVED` to `IN_PROGRESS` and logs `jobStartedAt`.
   - **Add Extra Parts**: Dynamically append add-ons (materials/parts) to a booking with correct schema calculations.
   - **Complete Job**: Sets status to `COMPLETED` and computes final payments.
3. **Live Location Tracking & Socket.io**:
   - Real-time socket connections with Redis adapters for scalability.
   - **`worker_location_update`**: Real-time GPS coordinate sync from the Worker App. The server broadcasts coordinates to the specific booking's socket room and updates the worker's position coordinates in MongoDB (`User.location.coordinates`) for nearby searches.
   - **Live Tracking HTTP Endpoint**: Fetch the worker's current coordinates directly via HTTP.
   - **SOS Emergencies**: Triggers real-time emergency broadcasts (`sos_alert`) to the room.
4. **API Auto-Documentation (Swagger)**:
   - Dynamic API route scanning and swagger schema updates.
   - Interactive docs hosted directly at `/api-docs` on Port `8000`.

---

## 🛠️ Tech Stack & Services

- **Runtime**: Node.js (ES Modules - `"type": "module"`)
- **Web Framework**: Express v5
- **Database**: MongoDB (via Mongoose) with GeoJSON `2dsphere` spatial indexing
- **Caching & Sessions**: Redis (via `ioredis`)
- **Queueing**: BullMQ (for sending emails in the background)
- **Sockets**: Socket.io (with Redis Adapter for pub/sub scaling)
- **Payments**: Razorpay
- **API Documentation**: Swagger (via `swagger-autogen` and `swagger-ui-express`)

---

## ⚙️ Configuration & Installation

### 1. Requirements
Ensure you have the following installed:
- Node.js (v18+)
- MongoDB (Running locally or a MongoDB Atlas URI)
- Redis Server (Running on `localhost:6379`)

### 2. Environment Variables (`.env`)
Create a `.env` file in the root directory (already populated for you):
```ini
PORT=8000
MONGO_URI=your_mongodb_connection_string
REDIS_URL=redis://localhost:6379
JWT_SECRET=your_access_token_secret
REFRESH_SECRET=your_refresh_token_secret
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your_email@gmail.com
SMTP_PASS=your_app_password
RAZORPAY_KEY_ID=your_razorpay_key
RAZORPAY_KEY_SECRET=your_razorpay_secret
```

### 3. Install Dependencies
```bash
npm install
```

### 4. Generate Swagger Docs
To scan the routes and build/update the Swagger documentation:
```bash
npm run swagger
```

### 5. Run Server
Start the Express API and Socket server:
```bash
npm start
```
The server will run on `http://localhost:8000`.
- **Swagger Interactive Docs**: `http://localhost:8000/api-docs`

---

## 📝 API Endpoints Reference

### 🔐 Authentication (`/api/auth`)
| Route | Method | Auth Required | Description |
|---|---|---|---|
| `/register` | `POST` | No | Creates user with status unverified and queues OTP email. |
| `/verify-otp` | `POST` | No | Verifies registration OTP, updates user verification state, and returns `accessToken` & `refreshToken`. |
| `/login` | `POST` | No | Logs in local user, saves session in Redis, returns tokens. |
| `/refresh-token` | `POST` | No | **Token Rotation**: Takes `userId`, `deviceId`, and `refreshToken`. Returns a *new* access token and a *rotated* refresh token. |
| `/google` | `POST` | No | Google Firebase Authentication login/registration. |
| `/forgot-password`| `POST` | No | Generates and sends OTP for resetting password. |
| `/reset-password` | `POST` | No | Verifies reset OTP and updates user password. |
| `/logout` | `POST` | No | Clears device session token from Redis cache. |
| `/me` | `GET` | Yes | Retrieves the current logged-in user profile. |

### 🛠️ Bookings & Jobs (`/api/bookings`)
| Route | Method | Auth Required | Description |
|---|---|---|---|
| `/history` | `GET` | Yes | Fetches booking history filtered by user's role (Customer/Worker). |
| `/estimate` | `POST` | Yes | Calculates estimate range based on service labor fee & materials. |
| `/` | `POST` | Yes | Creates a booking (status `SEARCHING` or `ACCEPTED`). |
| `/:bookingId` | `GET` | Yes | Retrieves detailed booking info, populating service and user roles. |
| `/:bookingId/accept`| `POST` | Yes | Worker accepts a searching booking. Transitions status to `ACCEPTED` and notifies customer room. |
| `/:bookingId/verify-otp`| `POST`| Yes | Verifies 4-digit PIN worker arrival. Transitions status to `ARRIVED`. |
| `/:bookingId/start-job`| `POST` | Yes | Starts work. Transitions status to `IN_PROGRESS` and sets `jobStartedAt`. |
| `/:bookingId/add-parts`| `PATCH`| Yes | Appends extra materials/addons, recalculating totals and sending updates. |
| `/:bookingId/complete`| `POST` | Yes | Finalizes work. Transitions status to `COMPLETED` and sets `jobCompletedAt`. |
| `/:bookingId/track` | `GET` | Yes | Fetches live coordinates of the assigned worker. |
| `/:bookingId/sos` | `POST` | Yes | Triggers a real-time panic/SOS socket broadcast to the room. |
| `/:bookingId/invoice`| `GET` | Yes | Returns detailed billing information. |

---

## ⚡ Real-Time Socket.io Event Interface

Clients (Android, iOS, React Native, or Web) connect to the socket server at `http://localhost:8000`.

### **Listening for Events**
1. **`booking_status_update`**:
   - **Emitted when**: Booking status changes (Worker accepts, arrives, starts work, adds parts, completes).
   - **Payload**:
     ```json
     {
       "bookingId": "64a...",
       "status": "ARRIVED",
       "workerId": "...", // If applicable
       "addOns": [],
       "invoice": {}
     }
     ```
2. **`live_tracking`**:
   - **Emitted when**: Worker updates their GPS location.
   - **Payload**:
     ```json
     {
       "lat": 28.6139,
       "lng": 77.2090,
       "heading": 90.0,
       "timestamp": 1690000000000
     }
     ```
3. **`sos_alert`**:
   - **Emitted when**: Client triggers SOS panic mode.
   - **Payload**:
     ```json
     {
       "bookingId": "64a...",
       "message": "EMERGENCY: SOS has been triggered!",
       "timestamp": 1690000000000
     }
     ```

### **Emitting Events**
1. **`join_booking_room`**:
   - Join the channel to receive notifications for a specific booking.
   - **Arguments**: `bookingId` (String)
2. **`worker_location_update`**:
   - Sent by Worker app periodically to broadcast real-time GPS locations to the customer and store it in MongoDB.
   - **Arguments**:
     ```json
     {
       "bookingId": "64a...",
       "lat": 28.6139,
       "lng": 77.2090,
       "heading": 120.5
     }
     ```

---

## 📬 Redis Queue Jobs (BullMQ)
The backend uses **BullMQ** to process heavy emails asynchronously using Redis under the name `emailQueue`.
- The worker is registered in `worker/emailWorker.js`.
- It processes background verification emails via Nodemailer SMTP.
