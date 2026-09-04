# Implementation Plan - Fixly Stack Run & Tunnel Integration

Run full stack locally with public ingress via Cloudflare and connect Flutter client on iOS simulator.

## Proposed Steps

### Step 1: Prerequisites
- Install & start Redis service via Homebrew (`brew install redis && brew services start redis`)
- Install Cloudflare tunnel CLI (`brew install cloudflared`)

### Step 2: Run Backend
- Launch `bakend-master/server.js` with Node on port 9001
- Confirm MongoDB Atlas connection & Redis connection

### Step 3: Expose Backend via Cloudflare
- Run `cloudflared tunnel --url http://localhost:9001`
- Extract public HTTPS tunnel URL (`https://<hash>.trycloudflare.com`)

### Step 4: Run Admin Panel
- Run Vite dev server in `FIXLY ADMIN PANEL` (`npm run dev`)
- Default port: 5173

### Step 5: Update Flutter API Configuration
- Set baseUrl in `frontend/lib/core/network/api_config.dart` and `frontend/dart_defines.json` to the Cloudflare public URL

### Step 6: Launch Flutter App
- Run Flutter on the active iPhone 17 Simulator (`flutter run -d 4D9C0520-E188-459D-BE9A-0E5D58595AE5`)

### Step 7: Verification
- Verify backend health check endpoint (`/`)
- Verify Cloudflare tunnel returns 200 on public URL
- Verify Admin Panel dev server is accessible
- Verify Flutter app boots and connects to API
