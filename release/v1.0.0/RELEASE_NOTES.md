# Habitat v1.0.0 Production Release Notes

**Release Date**: August 30, 2026  
**Git Commit**: `8acc9a7cf84931f6c449c57d19da05fc8aa1fe91`  
**Git Tag**: `v1.0.0`  
**Release Provenance**: `v1.0.0-rc.1` $\to$ `v1.0.0`

---

## 1. Core Mission & Alarm System
- **Task & Action Engine**: Create habit, physical, and cognitive tasks bound to custom verification actions.
- **Fail-Safe Native Alarms**: High-priority full-screen sirens (`USE_FULL_SCREEN_INTENT`), lock-screen waking, audio focus management, and automatic reboot recovery (`BootReceiver`).
- **Escalation Protocol**: 5-minute escalation retry loop ensuring morning missions cannot be dismissed without verified action.

## 2. Cryptographic Proof & Verification Engine
- **Single-Use Challenge Nonces**: Cryptographic session binding preventing cross-mission and replayed proof exploits.
- **Media Proof Persistence**: Local SHA-256 digest validation and chunked byte persistence via `ProofFileStore`.
- **Computer Vision & Pose Analysis**: Real MoveNet-Lightning pose estimation with keypoint geometry, repetition counters, optical entropy, and liveness scoring.

## 3. Health & Wellness Layer
- **Hydration Tracking**: Rapid logging presets (+250ml, +500ml), dynamic daily volume goals, and progress visualizers.
- **4-Slot Meal Tracker**: Breakfast, lunch, snack, and dinner meal status tracking with timestamped notes.
- **Nap Timer**: Timestamped start/stop nap duration tracker integrated into daily health summaries.

## 4. Progression, Streaks & Gamification
- **Idempotent XP Ledger**: Exactly-once XP allocation per verified task completion.
- **Dynamic Streaks**: Consecutive daily discipline tracking with milestone unlocks (`FIRST_STEP`, `TEN_MISSIONS`, `STREAK_7_DAYS`, `HYDRATION_HERO`).
- **Aggregated Home Dashboard**: Live reactive progress cards, active missions, next alarm indicator, and health metrics.

## 5. Offline Durability & Recovery
- **Write Coalescing**: 250ms debounced disk flushing to prevent write amplification.
- **Database Snapshot Fallback**: Automated watchdog snapshots for zero-data-loss state restoration.
- **Offline Sync Queue**: Complete offline execution with atomic server synchronization upon reconnection.

## 6. Multi-Platform Support
- **Android**: Target SDK 34, ProGuard/R8 rules preserving native platform channels, background siren service.
- **iOS**: Safe Area adaptivity across Dynamic Island and notch displays, bounded local notification escalation.
- **Web**: Responsive `AppShell` with adaptive `NavigationRail` $\leftrightarrow$ `BottomNavigationBar`, full keyboard focus traversal, and semantic labels.
