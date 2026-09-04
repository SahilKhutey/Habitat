# Habitat Multi-Platform Production Distribution

This directory contains standalone, officially signed, and shareable production release builds for Habitat.

---

## 1. Android Consumer Distribution (APK & AAB)

### Deliverables:
- **Direct Install APK:** [`release/android/Habitat.apk`](file:///c:/Users/ASUS/Documents/Habitat/release/android/Habitat.apk) (or `release/android/Habitat-release.apk`)
- **Google Play App Bundle:** [`release/android/Habitat-release.aab`](file:///c:/Users/ASUS/Documents/Habitat/release/android/Habitat-release.aab)
- **Checksum Verification:** [`release/android/SHA256SUMS.txt`](file:///c:/Users/ASUS/Documents/Habitat/release/android/SHA256SUMS.txt)
- **Target SDK:** 36 (Android 16) | **Minimum SDK:** 24 (Android 7.0+)
- **Architecture:** Fat binary containing `arm64-v8a`, `armeabi-v7a`, `x86_64`

### Production Signing & Integrity:
- **Signer Certificate:** `CN=Habitat Release, OU=Mobile Engineering, O=Habitat Discipline, L=San Francisco, ST=California, C=US`
- **Signing Schemes:** APK Signature Scheme v1 + v2 enabled and verified (`apksigner verify`)
- **AAB Signature:** Signed with official release key via `jarsigner`
- **SHA-256 Hashes:**
  - `Habitat.apk`: `c9e4053259ea1a22428f0b1af87019ac4711f36d8f678b288888c45be12658d1`
  - `Habitat-release.aab`: `601f73007a8453173044e2449e863780d8cec0469058c05c067f3b5089da88bc`

### User Installation (Zero Developer Tooling Required):
1. **Download:** Download `Habitat.apk` directly to your Android device via browser or direct link.
2. **Open:** Tap the downloaded `Habitat.apk` in your notification drawer or Downloads folder.
3. **Install:** Follow the standard Android system installer prompt (grant "Install unknown apps" permission if prompted for your browser/file manager).
4. **Launch:** Tap **Open** or launch Habitat from the app drawer. No ADB, Flutter, or developer settings required.

### Developer / Testing Install:
```bash
adb install -r release/android/Habitat.apk
```

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

