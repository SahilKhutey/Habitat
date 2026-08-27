# Habitat — High-Assurance Discipline Platform

<p align="center">
  <img src="https://img.shields.io/badge/Build-Passing-emerald?style=for-the-badge&logo=githubactions&logoColor=white" alt="Build Status" />
  <img src="https://img.shields.io/badge/Tests-185%2F185%20Passing-brightgreen?style=for-the-badge&logo=vitest&logoColor=white" alt="Tests" />
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

## Core Engineering Engines (Phases 1–9)

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
* **Computer Vision Object Detection**: Dynamic label matching for starter templates (`bed`, `glass/water`, `toothbrush`, `sunlight/sky`, `book/pages`).
* **Pose Estimation Repetition Counter**: Validates video motion cycles and repetition counts with full range of motion.

### 6. Discipline Economics & Gamification (`backend/src/modules/gamification/`)
* Append-only immutable XP Ledger (`xp_transactions`) with reason provenance (`MISSION_COMPLETED`, `FIRST_ATTEMPT_SPEED_BONUS`, `STREAK_MILESTONE_7D`).
* Quadratic level curve: $\text{Level Threshold} = 50 \cdot L(L-1)$.
* **Grace Vault Defense**: Automatically consumes defensive shields on missed days to protect streaks (earning 1 token every 14 days, max 3).
* 0–100 Daily Discipline Score formulation: $100 \times (0.5 \cdot \text{OnTime} + 0.3 \cdot \text{FirstAttempt} + 0.2 \cdot \text{SpeedBonus})$.

### 7. Offline Sync & Multi-Device Coordination (`backend/src/modules/sync/`, `backend/src/modules/mesh/`)
* `POST /api/v1/sync/batch` ingesting offline event queues with clock drift sanitization window ($\le 24\text{h}$).
* Last-Write-Wins (LWW) conflict resolver and idempotency replay protection.
* Multi-device mesh disarm broadcasting: Completing a mission on your phone automatically silences your bedside tablet and web dashboard.

---

## Directory Topology

```
discipline-app/
├── apps/
│   ├── mobile/             # Flutter (iOS, Android)
│   └── web/                # Flutter Web / React Dashboard
├── backend/
│   ├── src/
│   │   ├── modules/
│   │   │   ├── auth/           # Authentication & Tokens
│   │   │   ├── tasks/          # Task & Template Engine
│   │   │   ├── alarms/         # Recurrence & Scheduling
│   │   │   ├── mission/        # Mission Lifecycle & State Machine
│   │   │   ├── proofs/         # Proof Capture & S3 Direct Uploads
│   │   │   ├── verification/   # Verification & Truth Engine (CV & Pose)
│   │   │   ├── gamification/   # Immutable XP Ledger & Badges
│   │   │   ├── sync/           # Offline Queue & Conflict Resolver
│   │   │   ├── mesh/           # Multi-Device Synchronization Hub
│   │   │   └── audio/          # Psychoacoustic Synthesizers
│   │   └── db/                 # SQLite / PostgreSQL Connection & Seeds
│   └── tests/                  # 30 Vitest Test Suites (185 Tests)
├── packages/
│   ├── domain/             # Pure Dart Domain Entities
│   └── design_system/      # Atomic UI Tokens & Components
├── docs/                   # ADRs, API Reference, Specifications
├── infrastructure/         # Docker Compose (Postgres, Redis, MinIO)
└── scripts/                # Development & Build Automation Scripts
```

---

## Automated Test Suite: 185/185 Passing (100% Green)

```bash
cd backend
npm test
```

```
 Test Files  30 passed (30)
      Tests  185 passed (185)
   Duration  2.69s
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
| **Phase 9: Verification & Truth Engine (Anti-Cheat, CV & Pose)** | 8 tests | $\checkmark$ PASS |
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
