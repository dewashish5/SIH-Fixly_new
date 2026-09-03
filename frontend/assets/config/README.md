# Google Sign-In setup (Fixly / Firebase project `ai-agent-29433`)

Google login needs real OAuth client IDs from Firebase. Placeholder files here are not enough.

## Quick setup

1. Open [Firebase Console](https://console.firebase.google.com/) → project **ai-agent-29433**.
2. Add Android app: package `com.example.fixly`, SHA-1:
   ```
   DE:5D:F2:BF:11:CE:A8:46:1F:C2:20:56:E5:AE:6C:CD:66:24:0D:A5
   ```
   (debug keystore — re-run `./android/gradlew signingReport` if yours differs)
3. Add iOS app: bundle `com.example.fixly`.
4. Enable **Authentication → Google** sign-in provider.
5. Download:
   - `google-services.json` → save as `assets/config/google-services.json`
   - `GoogleService-Info.plist` → save as `assets/config/GoogleService-Info.plist`
6. From `frontend/` run:
   ```bash
   dart run tool/sync_google_sign_in.dart
   flutter pub get
   ```
7. Rebuild the app.

The sync script copies Android config, patches iOS `Info.plist`, and updates `firebase_client.json`.

## Flow

Tap Google → native Google account picker → `POST /api/auth/google` with email, name, avatar, role, deviceId, location.

Firebase Auth on device is **not** required; backend trusts the profile payload after Google Sign-In.
