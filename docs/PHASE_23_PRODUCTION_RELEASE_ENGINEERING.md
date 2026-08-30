# Habitat Phase 23 — Production Release Engineering & Distribution

## Overview
Phase 23 transitions the verified and accepted Habitat production baseline (`v1.0.0`) into enterprise-grade release engineering, distribution automation, provenance verification, rollback management, and post-release observability.

```
                    HABITAT v1.0.0 PRODUCTION
                                │
        ┌───────────────────────┼───────────────────────┐
        ▼                       ▼                       ▼
   ANDROID STORE             iOS STORE            WEB PRODUCTION
   DISTRIBUTION            DISTRIBUTION             DEPLOYMENT
   - Signed AAB            - Signed IPA           - Static Asset Bundle
   - Universal APK         - TestFlight Beta      - CDN Cache Headers
   - Play App Signing      - App Store Connect    - Edge Invalidation
        │                       │                       │
        └───────────────────────┼───────────────────────┘
                                ▼
                   GITHUB RELEASES & PROVENANCE
                   - SHA-256 Checksum Manifests
                   - Semantic Release Notes
                   - GPG Commit & Tag Signing
                                │
                                ▼
               POST-RELEASE OBSERVABILITY & ROLLBACK
               - Health & Error Telemetry
               - Canary Deployment & Hotfix Protocol
               - Zero-Data-Loss Database Rollback
```

---

## 1. Multi-Platform Artifact Distribution Architecture

### 1.1 Android Distribution Pipeline
- **Release App Bundle (AAB)**: Target for Google Play Console dynamic feature delivery and asset optimization.
- **Universal APK**: Target for direct distribution, internal testing, and sideload validation.
- **Signing Keystore Protocol**:
  - CI-injected release keystore via base64 GitHub Secrets (`ANDROID_KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`).
  - Strict absence of raw keystore binaries or passwords in git history.
- **ProGuard & R8 Obfuscation**:
  - Deterministic consumer rules preserving native MethodChannel bindings (`NativeAlarmPlugin`, `AlarmReceiver`, `BootReceiver`, `AlarmForegroundService`).

### 1.2 iOS TestFlight & App Store Pipeline
- **Xcode Archive (.xcarchive)**: Built via `xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Release archive`.
- **IPA Export**: Signed with Apple Distribution Certificate and Production Provisioning Profile.
- **App Store Connect API**: Automated TestFlight beta deployment via Fastlane / GitHub Actions integration.
- **Privacy & Entitlements**:
  - `NSCameraUsageDescription`, `NSMicrophoneUsageDescription`, `UIBackgroundModes` (`remote-notification`, `audio`).

### 1.3 Web Production CDN & Edge Hosting
- **Asset Bundling**: Minified HTML, CanvasKit WASM, icons, and service worker under `build/web/`.
- **Cache Strategy**:
  - `index.html`: `Cache-Control: no-cache, no-store, must-revalidate` (instant updates).
  - Static hashing: `main.dart.js`, WASM, fonts: `Cache-Control: public, max-age=31536000, immutable`.
- **Security Headers**: Strict CSP, HSTS, `X-Frame-Options: DENY`, `X-Content-Type-Options: nosniff`.

---

## 2. Release Provenance & Checksum Manifests

Every release publishes an authoritative, cryptographically verifiable provenance manifest:

```
# SHA256SUMS.txt
<hash>  Habitat-v1.0.0-android.apk
<hash>  Habitat-v1.0.0-android.aab
<hash>  Habitat-v1.0.0-ios-release.xcarchive.zip
<hash>  Habitat-v1.0.0-web.zip
<hash>  Habitat-v1.0.0-backend-bundle.tar.gz
```

Verification command:
```bash
sha256sum -c SHA256SUMS.txt
```

---

## 3. Rollback & Disaster Recovery Protocol

| Failure Scenario | Severity | Trigger Threshold | Rollback Procedure |
| :--- | :---: | :---: | :--- |
| **Alarm Scheduler Crash** | **P0** | Crash rate $> 0.1\%$ | Roll back Google Play release to previous track immediately; dispatch hotfix `v1.0.1`. |
| **Evidence Verification False Reject** | **P0** | False rejection $> 5\%$ | Revert verification policy threshold on backend dynamically without app update. |
| **Database Migration Incompatibility** | **P0** | Failed query / migration | Roll back Prisma schema with down-migration scripts; restore latest backup snapshot. |
| **Web Service Worker Stale Cache** | **P1** | Cache mismatch | Bump service worker version string and trigger force-reload via cache-busting script. |

---

## 4. Post-Release Observability & Smoke Tests

### 4.1 Production Health Telemetry
- **Backend Sentry / Prometheus**:
  - Endpoint latency p95/p99 ($< 150\text{ms}$)
  - Verification engine compute time ($< 500\text{ms}$)
  - Database pool saturation and lock contention ($< 5\%$)
- **Client Crash Reporting**:
  - Crash-free user rate $> 99.9\%$
  - Alarm delivery success rate $> 99.95\%$

### 4.2 Automated Post-Deployment Smoke Test Loop
1. Automated synthetic agent registers new account via API.
2. Creates task with photo verification and 1-minute alarm.
3. Simulates native camera proof submission and validates MoveNet inference.
4. Confirms atomic XP allocation and streak ledger update.
5. Verifies database read replica synchronization.
