# Habitat Phase 22 — RC1 Final Validation & Production Readiness

## Overview
Phase 22 transitions the frozen Habitat Release Candidate (`v1.0.0-rc.1`, commit `08a94da`) from automated compilation/test consistency to exhaustive real-device, cross-platform, security attack, and production artifact readiness.

```
                 PHASE 21
                    │
             RC1 CODE FREEZE (v1.0.0-rc.1)
                    │
                    ▼
             PHASE 22
       RC1 FINAL VALIDATION
                    │
       ┌────────────┼────────────┐
       ▼            ▼            ▼
    Android        iOS          Web
       │            │            │
       └────────────┼────────────┘
                    ▼
             Cross-Platform
               Regression
                    │
                    ▼
          Evidence / Security
               Adversarial
                    │
                    ▼
          Offline / Reliability
               Validation
                    │
                    ▼
            Artifact Hashing
                    │
                    ▼
             FINAL SIGN-OFF
                    │
                    ▼
            v1.0.0 PRODUCTION
```

---

## 1. Release Candidate Identification
- **Release Tag**: `v1.0.0-rc.1`
- **Release Commit SHA**: `08a94da2cf8021c179836968ce63d76e73708bb8`
- **Version**: `1.0.0`
- **Quality Gate Architecture**: Fail-Closed Monorepo CI Pipeline

---

## 2. Core Product Loop Validation Matrix

```
APP LAUNCH ──▶ ONBOARDING ──▶ PERMISSIONS ──▶ HOME (Aggregated View)
                                                  │
              ┌───────────────────────────────────┴───────────────────────────────────┐
              ▼                                                                       ▼
      CREATE MISSION / TASK                                                  HEALTH FOUNDATION
              │                                                                       │
              ▼                                                                       ├── 💧 Water Tracking
        SCHEDULE ALARM                                                                ├── 🍽️ 4-Slot Meal Logging
              │                                                                       └── 😴 Nap Timer
              ▼
   EXACT ALARM RINGING & SIREN
              │
              ▼
     MISSION PROOF CAPTURE
              │
              ▼
   PROOFLFILESTORE PERSISTENCE
              │
              ▼
  AUTHORITATIVE VERIFICATION
              │
              ▼
     TASK COMPLETION & XP
              │
              ▼
   STREAK & PROGRESS UPDATE
              │
              ▼
     HOME AGGREGATION
```

---

## 3. Platform-Specific Validation Matrix

### 3.1 Android (APK & AAB)
- **Artifacts**: `app-release.apk`, `app-release.aab`
- **Hardware & OS Testing**:
  - Exact Alarm Scheduling (`AlarmManager.setExactAndAllowWhileIdle`)
  - Foreground Siren Service & Audio Focus Management
  - Full-Screen Intent over Lock Screen
  - `BootReceiver` Automatic Alarm Re-Registration on Reboot
  - Aggressive Doze Mode & Battery Optimization Exemption (`REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`)
  - Runtime Permissions: `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, `CAMERA`, `RECORD_AUDIO`, `USE_FULL_SCREEN_INTENT`

### 3.2 iOS (App Framework & IPA Pipeline)
- **Artifacts**: `Runner.app`, `Payload.ipa`
- **Hardware & OS Testing**:
  - Bounded local notification chains for alarm escalation
  - Safe Area adaptivity across Dynamic Island and Notch devices
  - VoiceOver semantics and screen reader accessibility labels
  - AVCaptureSession photo/video capture pipeline and permission revocation handling

### 3.3 Web Platform
- **Artifact**: `build/web/`
- **Browser Compatibility**: Chrome, Safari, Firefox, Edge
- **Testing**:
  - Responsive `AppShell` with `NavigationRail` $\leftrightarrow$ `BottomNavigationBar` transitions
  - Complete keyboard navigation and focus traversal
  - Graceful fallback for mobile-only hardware platform channels (camera, siren)

---

## 4. Evidence Verification & Adversarial Attack Matrix

| Attack Vector | Security Engine Behavior | Decision |
| :--- | :--- | :---: |
| **Reused Session Nonce** | Consumed nonces rejected by `SessionChallengeService` | **`REJECT`** |
| **Tampered File Bytes** | Client SHA-256 does not match server-computed payload digest | **`REJECT`** |
| **Stale Timestamp** | Capture timestamp exceeds 180-second freshness window | **`REJECT`** |
| **Future Clock Skew** | Capture timestamp $> 30\text{s}$ ahead of server clock | **`REJECT`** |
| **Gallery Upload** | Blocked when camera-live capture is required by mission policy | **`REJECT`** |
| **Frame Monotonicity Jump** | Non-monotonic video frame timestamps/indices | **`REJECT`** |
| **Low Liveness Score** | MoveNet optical entropy / lux below confidence threshold | **`REJECT`** |

---

## 5. Durability, Reliability & Offline-First Guarantees
1. **Write Coalescing**: 250ms debounced disk flushing prevents write amplification during rapid habit logging.
2. **Snapshot Recovery**: Corrupted primary databases automatically recover from the latest validated backup snapshot.
3. **Idempotent Progression**: Task completions emit exactly one XP event; duplicate submissions produce 0 extra XP.
4. **Offline Synchronization**: Complete core loop operational without internet connection; sync queue drains atomically upon reconnection.

---

## 6. Promotion to Production (v1.0.0) Sign-Off Checklist

- [x] Backend TypeScript compilation clean (`0 errors`).
- [x] Backend test suite: 402/402 tests pass (100% green).
- [x] Prisma schema validation passed.
- [x] Local release verification gate (`scripts/verify-release.ps1`) approved.
- [x] Secret audit passed (0 unhashed credentials in repository).
- [x] `LocalTask` domain properties (`isCompleted`, `difficulty`) verified.
- [x] `ProofFileStore` storage layer active and tested.
- [x] `v1.0.0-rc.1` tag pushed to repository remote.
