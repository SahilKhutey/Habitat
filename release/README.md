# Habitat Multi-Platform Release Distribution (v1.1.0)

This directory contains standalone, easily accessible, and shareable production builds for Habitat.

---

## 1. Android (APK)
- **Path:** [`release/android/Habitat-v1.1.0-release.apk`](file:///c:/Users/ASUS/Documents/Habitat/release/android/Habitat-v1.1.0-release.apk)
- **File Size:** ~58.7 MB
- **Target SDK:** 36 (Android 16) | Minimum SDK: 24 (Android 7.0+)
- **Architecture:** `arm64-v8a`, `armeabi-v7a`, `x86_64` fat binary
- **SHA-256:** `D2032F1DA0913D597CF030EE834C8C2876FD026E3B1B8882E1C29399561E40DC`

### Installation:
```bash
adb install -r release/android/Habitat-v1.1.0-release.apk
```
Or download directly to your Android device and tap to install (enable "Install from Unknown Sources").

---

## 2. Web PC (Browser & Desktop)
- **Path:** [`release/web/`](file:///c:/Users/ASUS/Documents/Habitat/release/web/)
- **Technology:** Flutter Web with CanvasKit & HTML renderer
- **Features:** Real-time Command Center, live REST API integration, telemetry charts.

### Running Locally on PC:
You can serve the web build using any HTTP server:
```bash
# Python
python -m http.server 8080 --directory release/web

# Node.js
npx serve release/web -l 8080
```
Then open `http://localhost:8080` in Chrome, Edge, Safari, or Firefox.

---

## 3. iOS (Apple Devices)
- **Path:** [`release/ios/`](file:///c:/Users/ASUS/Documents/Habitat/release/ios/)
- **Cloud Build Workflow:** [`.github/workflows/ios.yml`](file:///c:/Users/ASUS/Documents/Habitat/.github/workflows/ios.yml) (Runs on `macos-14` runner)
- **Xcode Project:** `apps/mobile/ios/Runner.xcodeproj`
- Refer to [`release/ios/README.md`](file:///c:/Users/ASUS/Documents/Habitat/release/ios/README.md) for compilation and deployment.
