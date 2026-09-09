# Flutter via Docker (Fixly)

Run and build Flutter without installing Flutter, Android Studio, or Java on host machine.

---

### Prerequisites
- Docker Desktop / Docker Engine installed and running.

---

### 1. Build Debug APK (Automatic)

Run from `frontend/` directory:
```bash
docker compose up
```
Or from root project folder:
```bash
docker compose -f docker-compose.flutter.yml up
```

Once build finishes, the APK will be on host laptop at:
`frontend/build/app/outputs/flutter-apk/app-debug.apk`

---

### 2. Run Interactive Shell (Run tests, custom flutter commands)

```bash
# Inside frontend/
docker compose run --rm flutter bash
```

Inside the container:
```bash
flutter test
flutter analyze
flutter build apk --release
```

---

### 3. Note regarding Web vs Mobile
This project uses native mobile plugins (`mapbox_maps_flutter`, `flutter_callkit_incoming`, `razorpay_flutter`). These require Android/iOS runtimes and cannot run in a desktop web browser. Docker builds the Android APK directly for use on a real device or emulator.
