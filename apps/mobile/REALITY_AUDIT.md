# Habitat Mobile: Reality & Fidelity Audit (Track J9)

This document tracks all previously-fake, hardcoded, or simulated paths across the mobile application, their current status, and their authoritative resolution.

---

## 1. Computer Vision & Proof Verification Boundary

| Component | Previous State | Resolved State | Authoritative Mechanism |
|---|---|---|---|
| **`ProofCameraScreen`** | Hardcoded SHA-256 hash | Real camera capture & physical byte hash | `CameraService` -> `NativeCameraController` -> `crypto.sha256` |
| **`NativeCameraProofPipeline`** | Fabricated `mockBytes` & fake 0.94 score | Delegated to `CameraService` + `serverVerificationPending` flag | Direct `CameraService` delegation |
| **`MediaActionService`** | Hardcoded `'local://proof_photo.jpg'` & 0.95 | Delegated to `CameraService` | `DefaultMediaActionService` wrapping `CameraService` |
| **`MediaVerificationEngine`** | Returned `confidenceScore: 0.98` | Local format validator with `serverVerificationPending: true` | `POST /proofs/:id/verify-real-vision` server backend |
| **Repetition Counting** | Local simulation | Server-side MoveNet pose estimation | `ProofsService.verifyWithRealVision` + TFJS MoveNet engine |

---

## 2. Local Persistence & State Durability

| Component | Previous State | Resolved State | Authoritative Mechanism |
|---|---|---|---|
| **Local Database Engine** | In-memory `ValueNotifier` only | `SharedPreferences` + `exportCompleteStateJson` | Debounced (250ms) + immediate flush on critical actions |
| **Critical Domain Actions** | Could be lost if app killed | `_notifyChanged(immediate: true)` | Tasks, alarms, attempts, proofs, XP, streaks flush synchronously |
| **Schema Migrations** | Static version number | `_migrateSchema()` handling v1 -> v2 -> v3 | Incremental structural upgrades |
| **Corrupt Payload Recovery** | App crash / white screen | Backup snapshot restore with fallback | `_backupSnapshot` restore with default template seeding |

---

## 4. UI Layer Integration & Zero-Mock Wiring (Phase 26)

| UI Screen / Controller | Previous State | Resolved State | Authoritative Mechanism |
|---|---|---|---|
| **`HomeController`** | Demo strings and fake dashboard metrics | Real SQLite streams + `LocalDatabase` | Reactive query of active task attempts, today's schedule, and real daily progress |
| **`HealthController`** | Static 0.0L hydration and fake meals | Real `water_entries`, `meal_entries`, `nap_entries` | `LocalDatabase.addWater`, `addMeal`, `startNap`, `stopNap` with persistent atomic updates |
| **`TasksScreen`** | Hardcoded demo task models | Dynamically queried SQLite task catalog | Filters (`ALL`, `ACTIVE`, `SCHEDULED`, `COMPLETED`) over real persistent `LocalTask` records |
| **`ProgressScreen`** | Static completion percentage & mock streak | Calculated from actual event ledger | 7-day completion trend, real streak counter, and dynamic Grace Token inventory |
| **`DailyJournalScreen`** | In-memory temporary entries | Persistent `reflections` table | CRUD operations saved directly to local database across app sessions |
| **`MissionExecutionScreen`** | Synthetic completion buttons | Strict proof verification boundary | Mission cannot be marked complete without valid media proof or verified telemetry |
