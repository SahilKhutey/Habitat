# Habitat — High-Assurance Discipline Platform

<p align="center">
  <img src="https://img.shields.io/badge/Build-Passing-emerald?style=for-the-badge&logo=githubactions&logoColor=white" alt="Build Status" />
  <img src="https://img.shields.io/badge/Tests-336%2F336%20Passing-brightgreen?style=for-the-badge&logo=vitest&logoColor=white" alt="Tests" />
  <img src="https://img.shields.io/badge/Spoof%20Accepts-0%20(Release%20Approved)-brightgreen?style=for-the-badge&logo=shield&logoColor=white" alt="Spoof Accepts" />
  <img src="https://img.shields.io/badge/Backend-TypeScript%20%2B%20Express-blue?style=for-the-badge&logo=express&logoColor=white" alt="Backend" />
  <img src="https://img.shields.io/badge/Storage-S3%20%2B%20Local%20Abstraction-orange?style=for-the-badge&logo=amazons3&logoColor=white" alt="Storage" />
  <img src="https://img.shields.io/badge/Mobile-Flutter%203.x%20%7C%20Dart-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/License-Commercial%20Proprietary-amber?style=for-the-badge" alt="License" />
</p>

---

## Executive Summary

**Habitat** is an enterprise-grade discipline execution engine designed from first principles to eradicate morning inertia, cognitive resistance, and habit failure. Rather than relying on easily dismissed alarms or coercive punishment loops, Habitat pairs time-critical physical missions with multi-modal proof verification, psychoacoustic audio escalation, an append-only discipline economy, and multi-device alarm mesh synchronization.

$$\boxed{\textbf{Alarm Fired} \longrightarrow \textbf{Mission Active} \longrightarrow \textbf{Physical Action} \longrightarrow \textbf{Proof Captured} \longrightarrow \begin{cases} \textbf{ACCEPTED} & \to \text{Alarm Disarmed + XP Ledger Appended} \\ \textbf{REJECTED} & \to \text{5-Minute Retry Cycle Continues} \end{cases}}$$

For the machine-checkable phase gates and status audit, see [`docs/STATUS.md`](file:///c:/Users/ASUS/Documents/Habitat/docs/STATUS.md).
For the definitive system mapping and source of truth, see [`docs/ARCHITECTURE.md`](file:///c:/Users/ASUS/Documents/Habitat/docs/ARCHITECTURE.md).

---

## System Architecture

```
                    ┌────────────────────────┐
                    │      FLUTTER APP       │
                    │  (iOS / Android / Web) │
                    └───────────┬────────────┘
                                │ REST (/api/v1) / WebSocket
                                ▼
                    ┌────────────────────────┐
                    │   TYPESCRIPT BACKEND   │
                    │   (Express Monolith)   │
                    └───────────┬────────────┘
         ┌──────────────────────┼──────────────────────┐
         ▼                      ▼                      ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ LOCAL SQLITE DB │    │   MINIO / S3    │    │  AUDIO SYNTH    │
│ (Active Ledger) │    │(Cloud Ready S3) │    │ (Psychoacoustic)│
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

---

## Core Engineering Engines

### 1. Design System & UX Foundation (`packages/design_system/`)
* Tactical luxury aesthetic with High-Contrast OLED Dark (`#0D0E11`) & Crisp Paper Light (`#F8F9FA`) themes.
* 8-point spatial rhythm (`4px` to `48px`), accessible typography hierarchy, atomic components (`AppButton`, `AppCard`, `AppInput`, `AppDialog`).

### 2. Task & Template Engine (`backend/src/modules/tasks/`)
* 10 Canonical starter discipline task templates (`tpl-make-bed`, `tpl-pushups-10`, `tpl-brush-teeth`, `tpl-hydrate-glass`, `tpl-morning-sunlight`, `tpl-cold-shower`, `tpl-journal-plan`, `tpl-read-10-pages`, `tpl-outdoor-walk`, `tpl-wardrobe-prep`).
* Server-calculated XP multipliers ($1.0\text{x}$ to $2.5\text{x}$) and task lifecycle states (`ACTIVE` $\rightleftharpoons$ `PAUSED` $\to$ `ARCHIVED`).

### 3. Scheduling & Alarm Engine (`backend/src/modules/alarms/`)
* Timezone-aware next occurrence calculation taking into account daylight saving time.
* 5-minute escalation retry loop ($70\text{dB} \to 85\text{dB} \to 100\text{dB}$).
* Exponential siren profiles and 40Hz gamma psychoacoustic auditory entrainment.

### 4. Mission Execution & Proof Engine (`backend/src/modules/mission/`, `backend/src/modules/proofs/`)
* Strict `MissionStateMachine`: $\text{SCHEDULED} \to \text{ACTIVE} \to \text{IN\_PROGRESS} \to \text{VERIFYING} \to \text{COMPLETED} \lor \text{RETRY}$.
* `ProofStateMachine`: $\text{CAPTURING} \to \text{CAPTURED} \to \text{UPLOAD\_PENDING} \to \text{UPLOADING} \to \text{UPLOADED} \to \text{VALIDATING} \to \text{ACCEPTED} \lor \text{REJECTED}$.

### 5. Verification & Truth Engine (`backend/src/modules/verification/`)
* **Anti-Cheat Heuristics**: Sensor timestamp freshness ($\le 180\text{s}$), ambient lux threshold ($\ge 25\text{ lux}$), optical entropy ($\ge 0.15$), and gallery injection blocking.
* **Movement State Machine**: Discrete `PushupStateMachine` (`TOP` $\to$ `DESCEND` $\to$ `BOTTOM` $\to$ `ASCEND` $\to$ `TOP`) with false-repetition protection.
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

### 8. Health, Exercise & Wellness Discipline Layer (`backend/src/modules/health/`)
* **Bounded Wellness Architecture**: Exercise, hydration, and sleep operate as a decoupled domain without destabilizing the core alarm/task state machines.
* **Discipline-to-Wellness Bridge**: Verified physical missions automatically register `ExerciseSession` and `HydrationEntry` records without double logging.
* **Granular Privacy & Data Deletion**: Users can independently delete exercise, sleep, or hydration datasets without deleting discipline accounts or XP history.

---

## Known Limitations

Habitat is currently under active development.

### Verification
The verification pipeline and decision engine are implemented and tested, but the current computer-vision provider is a mock implementation. It does not perform real object detection or pose estimation against uploaded media. Consequently, vision-based mission verification should not currently be considered production-grade anti-cheat verification.

### Storage
The current backend uses the implemented local SQLite database/storage layer. The documented PostgreSQL and S3/MinIO cloud architecture is designed and staged in `infrastructure/` but is not yet fully wired into the default running application.

### Web Application
The Web application is currently an early client prototype. Some screens and interactions are not yet connected to the complete backend mission, alarm, proof, and gamification flows.

### Production Status
Passing automated tests indicate that the implemented domain logic is working as tested; they do not imply that all external integrations, computer vision, storage, or end-to-end mobile flows are production-ready.

---

## Automated Test Suite: 276/276 Passing (100% Green)

```bash
npm test
```

```
 Test Files  42 passed (42)
      Tests  276 passed (276)
   Duration  4.07s
```

---

## Quick Start (Local Development)

### Prerequisites
* **Node.js**: v20+ / v22+ / v24+
* **Flutter SDK**: 3.22+ (for mobile & web client development)

### 1. Install & Run Backend
```bash
# Install backend dependencies
cd backend && npm install

# Build TypeScript
npm run build

# Run Vitest test suite (262 tests)
npm test

# Start Express development server
npm run dev
```
* REST API: `http://localhost:4000/api/v1`
* Web SPA Dashboard: `http://localhost:4000/`
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

