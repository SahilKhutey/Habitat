# Habitat — High-Assurance Discipline Platform

<p align="center">
  <img src="https://img.shields.io/badge/Build-Passing-emerald?style=for-the-badge&logo=githubactions&logoColor=white" alt="Build Status" />
  <img src="https://img.shields.io/badge/Tests-236%2F236%20Passing-brightgreen?style=for-the-badge&logo=vitest&logoColor=white" alt="Tests" />
  <img src="https://img.shields.io/badge/Backend-NestJS%20%7C%20TypeScript-blue?style=for-the-badge&logo=nestjs&logoColor=white" alt="Backend" />
  <img src="https://img.shields.io/badge/Mobile-Flutter%203.x%20%7C%20Dart-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/License-Commercial%20Proprietary-amber?style=for-the-badge" alt="License" />
</p>

---

## Executive Summary

**Habitat** is an enterprise-grade discipline execution engine designed from first principles to eradicate morning inertia, cognitive resistance, and habit failure. Rather than relying on easily dismissed alarms or coercive punishment loops, Habitat pairs time-critical physical missions with multi-modal proof verification, psychoacoustic audio escalation, an append-only discipline economy, and multi-device alarm mesh synchronization.

$$\boxed{\textbf{Alarm Fired} \longrightarrow \textbf{Mission Active} \longrightarrow \textbf{Physical Action} \longrightarrow \textbf{Proof Captured} \longrightarrow \begin{cases} \textbf{ACCEPTED} & \to \text{Alarm Disarmed + XP Ledger Appended} \\ \textbf{REJECTED} & \to \text{5-Minute Retry Cycle Continues} \end{cases}}$$

---

## System Architecture

```
                    ┌────────────────────────┐
                    │      FLUTTER APP       │
                    │  (iOS / Android / Web) │
                    └───────────┬────────────┘
                                │ REST / WebSocket / S3 Presigned
                                ▼
                    ┌────────────────────────┐
                    │     NESTJS BACKEND     │
                    │  (TypeScript Modular)  │
                    └───────────┬────────────┘
         ┌──────────────────────┼──────────────────────┐
         ▼                      ▼                      ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ SQLITE / POSTGRES│    │   MINIO / S3    │    │  AUDIO SYNTH    │
│  (Data Ledger)  │    │ (Proof Storage) │    │ (Psychoacoustic)│
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

---

## Core Engineering Engines (Phases 1–11)

### 1. Design System & UX Foundation (`packages/design_system/`)
* Tactical luxury aesthetic with High-Contrast OLED Dark (`#0D0E11`) & Crisp Paper Light (`#F8F9FA`) themes.
* 8-point spatial rhythm (`4px` to `48px`), accessible typography hierarchy, atomic components (`AppButton`, `AppCard`, `AppInput`, `AppDialog`).

### 2. Task & Template Engine (`backend/src/modules/tasks/`)
* 10 Canonical starter discipline task templates (`tpl-make-bed`, `tpl-pushups-10`, `tpl-brush-teeth`, `tpl-hydrate-glass`, `tpl-morning-sunlight`, `tpl-cold-shower`, `tpl-journal-plan`, `tpl-read-10-pages`, `tpl-outdoor-walk`, `tpl-wardrobe-prep`).
* Server-calculated XP multipliers ($1.0\text{x}$ to $2.5\text{x}$) and task lifecycle states (`ACTIVE` $\rightleftharpoons$ `PAUSED` $\to$ `ARCHIVED`).

### 3. Scheduling & Alarm Engine (`backend/src/modules/scheduling/`, `backend/src/modules/alarms/`)
* Timezone-aware next occurrence calculation taking into account daylight saving time.
* 5-minute escalation retry loop ($70\text{dB} \to 85\text{dB} \to 100\text{dB}$).
* Exponential siren profiles and 40Hz gamma psychoacoustic auditory entrainment.

### 4. Mission Execution & Proof Engine (`backend/src/modules/mission/`, `backend/src/modules/proofs/`)
* Strict `MissionStateMachine`: $\text{SCHEDULED} \to \text{ACTIVE} \to \text{IN\_PROGRESS} \to \text{VERIFYING} \to \text{COMPLETED} \lor \text{RETRY}$.
* `ProofStateMachine`: $\text{CAPTURING} \to \text{CAPTURED} \to \text{UPLOAD\_PENDING} \to \text{UPLOADING} \to \text{UPLOADED} \to \text{VALIDATING} \to \text{ACCEPTED} \lor \text{REJECTED}$.
* Direct S3 upload sessions via presigned URLs and `ProofRules` limits enforcement.

### 5. Verification & Truth Engine (`backend/src/modules/verification/`)
* **Anti-Cheat Heuristics**: Sensor timestamp freshness ($\le 180\text{s}$), ambient lux threshold ($\ge 25\text{ lux}$), optical entropy ($\ge 0.15$), and gallery injection blocking.
* **Computer Vision Object Detection**: Modular verifiers for `OutdoorPhotoVerifier`, `BrushingPhotoVerifier`, and starter templates.
* **Pose Estimation & Action Sequence State Machine**: Discrete `PushupStateMachine` (`TOP` $\to$ `DESCEND` $\to$ `BOTTOM` $\to$ `ASCEND` $\to$ `TOP`) with false-repetition protection.
* **Tri-State Decision Engine**: Calibrated `ACCEPT` ($\ge 0.80$), `REVIEW` ($0.50 \to 0.80$), and `REJECT` ($\le 0.50$) thresholds.

### 6. Gamification, Discipline Progress & Engagement Engine (`backend/src/modules/gamification/`)
* **Immutable XP Ledger (`xp_transactions`)**: Strictly append-only accounting with unique idempotency keys (`MISSION_COMPLETED:{id}`) preventing double XP exploits.
* **Quadratic Level Curve**: $\text{Level Threshold} = 50 \cdot L(L-1)$ with discrete `LEVEL_UP` event dispatching.
* **Timezone-Aware Streak Engine**: Local date boundary evaluations and Grace Vault defense tokens (earning 1 token per 14 streak days, max 3).
* **Slow-Moving Discipline Score**: Formulated as $0.40 \cdot \text{Completion} + 0.25 \cdot \text{Consistency} + 0.20 \cdot \text{Difficulty} + 0.15 \cdot \text{Streak}$ over rolling 7/30/90-day windows.
* **Declarative Achievement Engine**: Canonical achievements (`FIRST_STEP`, `FIRST_7_DAY_STREAK`, `FIRST_30_DAY_STREAK`, `TASK_100`, `EARLY_RISER`).

### 7. Personal Discipline Planning & Routine Engine (`backend/src/modules/routines/`)
* **Task Blueprint vs Schedule vs Routine**: Decoupled architecture with immutable `RoutineVersion` snapshots preserving past mission history.
* **Recurrence & Conflict Engines**: Rolling 7–14 day horizon with idempotency keys (`${ruleId}:${dateStr}:${taskId}`) and overlap severity classifications (`LOW`, `MEDIUM`, `HIGH`).
### 9. Health, Exercise & Wellness Discipline Layer (`backend/src/modules/health/`)
* **Bounded Wellness Architecture**: Exercise, hydration, and sleep operate as a decoupled domain without destabilizing the core alarm/task state machines.
* **Discipline-to-Wellness Bridge**: Verified physical missions automatically register `ExerciseSession` and `HydrationEntry` records without double logging.
* **Apple Health & Health Connect Normalization**: Ingests provider payloads with unit normalization (meters, seconds, ml) and `(source, external_id)` idempotency.
* **Discipline + Wellness Correlation Engine**: Computes behavioral associations with a strict $\ge 14$-day sample threshold.
* **Granular Privacy & Data Deletion**: Users can independently delete exercise, sleep, or hydration datasets without deleting discipline accounts or XP history.

---

## Automated Test Suite: 236/236 Passing (100% Green)

```bash
cd backend
npm test
```

```
 Test Files  36 passed (36)
      Tests  236 passed (236)
   Duration  3.59s
```

| Subsystem | Tests | Status |
| :--- | :---: | :---: |
| **Phase 1: Foundation & Health** | 2 tests | $\checkmark$ PASS |
| **Phase 3: Core Domain & Data Layer** | 12 tests | $\checkmark$ PASS |
| **Phase 4: Auth & Task Engine** | 17 tests | $\checkmark$ PASS |
| **Phase 5: Scheduling & 5-Min Alarm Escalation** | 15 tests | $\checkmark$ PASS |
| **Phase 6: Multi-Modal Proofs & State Machine** | 16 tests | $\checkmark$ PASS |
| **Phase 7: Mission Lifecycle & Gamification** | 17 tests | $\checkmark$ PASS |
| **Phase 8: Offline Sync & Multi-Device Mesh** | 6 tests | $\checkmark$ PASS |
| **Phase 8: Camera & Direct S3 Upload Session Pipeline** | 7 tests | $\checkmark$ PASS |
| **Phase 9: Verification & Truth Engine (Master Tests)** | 8 tests | $\checkmark$ PASS |
| **Phase 9: Push-Up Movement State Machine** | 4 tests | $\checkmark$ PASS |
| **Phase 9: Task Verifiers & Tri-State Decision Engine** | 7 tests | $\checkmark$ PASS |
| **Phase 10: Gamification, Discipline Progress & Engagement Engine** | 10 tests | $\checkmark$ PASS |
| **Phase 11: Personal Discipline Planning & Routine Engine** | 10 tests | $\checkmark$ PASS |
| **Phase 12: Intelligent Adaptation & Personalization Engine** | 10 tests | $\checkmark$ PASS |
| **Phase 13: Health, Exercise & Wellness Discipline Layer** | 10 tests | $\checkmark$ PASS |
| **Full Vertical Slice E2E Flow** | 20 tests | $\checkmark$ PASS |
| **Extended Advanced Tier Systems** | 65 tests | $\checkmark$ PASS |

---

## Quick Start (Local Development)

### Prerequisites
* **Node.js**: v20+ / v22+
* **Flutter SDK**: 3.22+
* **Docker & Docker Compose** (Optional for production Postgres/Redis/MinIO)

### 1. Install & Build Backend
```bash
cd backend
npm install
npm run build
npm test
npm run dev
```
* REST API: `http://localhost:4000/api/v1`
* Health Check: `http://localhost:4000/health`

### 2. Run Mobile Client
```bash
cd apps/mobile
flutter pub get
flutter run
```

---

## Commercial License & Terms

Copyright (c) 2026 Sahil Khutey. All Rights Reserved.

This software, its source code, architecture, algorithms, and psychoacoustic audio entrainment models are proprietary and confidential intellectual property. Commercial licensing, enterprise white-labeling, and partnership inquiries:

* **Repository**: [https://github.com/SahilKhutey/Habitat.git](https://github.com/SahilKhutey/Habitat.git)
* **Author**: Sahil Khutey
