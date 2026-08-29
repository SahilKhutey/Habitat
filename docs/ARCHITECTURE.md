# Habitat System Architecture & Source of Truth

This document serves as the authoritative architectural source of truth for the Habitat repository.

---

## 1. Directory & Subsystem Mapping

| Layer | Path | Responsibility |
| :--- | :--- | :--- |
| **Backend Core** | [`/backend`](file:///c:/Users/ASUS/Documents/Habitat/backend) | Canonical TypeScript + Express REST API (`/api/v1`), WebSocket gateway, and domain engines |
| **Database & Seeds** | [`/backend/src/db`](file:///c:/Users/ASUS/Documents/Habitat/backend/src/db) | Local database connection, schemas, migrations, and canonical task seed definitions |
| **Mobile Client** | [`/apps/mobile`](file:///c:/Users/ASUS/Documents/Habitat/apps/mobile) | Flutter iOS/Android application with native alarm manager & foreground service bindings |
| **Web Client** | [`/apps/web`](file:///c:/Users/ASUS/Documents/Habitat/apps/web) | Flutter Web client & control dashboard |
| **Web SPA (Embedded)** | [`/backend/public`](file:///c:/Users/ASUS/Documents/Habitat/backend/public) | Standalone single-page web dashboard served directly by the Express backend |
| **Shared Packages** | [`/packages`](file:///c:/Users/ASUS/Documents/Habitat/packages) | Shared domain contracts, design system, and discipline definitions |
| **Infrastructure** | [`/infrastructure`](file:///c:/Users/ASUS/Documents/Habitat/infrastructure) | Local Docker compose definitions (Postgres, Redis, MinIO) for cloud deployment |
| **Documentation** | [`/docs`](file:///c:/Users/ASUS/Documents/Habitat/docs) | System documentation, architectural decision records (ADRs), and guides |

> [!IMPORTANT]
> **Canonical Backend Rule**: `/backend` is the ONLY canonical backend. Root-level `/src` and `/tests` were legacy prototypes and have been permanently removed. Do NOT reintroduce root-level application code.

---

## 2. Core Execution Loop

```
                    HABITAT RUNTIME
                           │
           ┌───────────────┼───────────────┐
           │               │               │
           ▼               ▼               ▼
        Android           iOS             Web
           │               │               │
       REAL native     REAL native     Prototype
     alarm plumbing  alarm plumbing    UI/client
           │
           ▼
        Mission Engine
           │
           ▼
       Proof Pipeline
           │
           ▼
      ┌─────────────────────────┐
      │   Verification Engine   │
      │                         │
      │   REAL decision logic   │
      │   REAL state machine    │
      │   REAL unit tests       │
      │                         │
      │   ⚠️ MOCK CV INFERENCE  │
      └─────────────────────────┘
```

$$\boxed{\textbf{Alarm Fired} \longrightarrow \textbf{Mission Active} \longrightarrow \textbf{Physical Action} \longrightarrow \textbf{Proof Captured} \longrightarrow \begin{cases} \textbf{ACCEPTED} & \to \text{Alarm Disarmed + XP Ledger Appended} \\ \textbf{REJECTED} & \to \text{5-Minute Retry Escalation Continues} \end{cases}}$$

---

## 3. Subsystem Maturity Tiers

| Tier | Status | Components |
| :--- | :--- | :--- |
| 🟢 **Production-Capable** | **Real** | Native Android `AlarmManager` + `ForegroundService`<br>Native iOS Notification / Alarm Plumbing<br>Mission State Machine (`MissionStateMachine`) & Escalation Loop<br>Append-Only XP Ledger (`xp_transactions`) & Gamification Calculations<br>Backend REST Routing & Core Test Matrix (262/262 passing tests) |
| 🟡 **Integrated Prototype** | **Partial** | Flutter Mobile UI<br>Web Dashboard (currently mock-driven)<br>Backend HTTP Routes<br>Local SQLite Persistence Engine |
| 🔴 **Unimplemented / Mock** | **Pending** | Real On-Device / Server-Side CV Pose & Landmark Inference<br>Visual Anti-Cheat Proof Generation Against Live Media<br>Production S3 / MinIO Storage Provider Wiring<br>Production JWT Auth Hardening |
| ⚪ **Future Expansion** | **Roadmap** | Squad Battles & Social Accountability<br>AI Discipline Coach<br>Wearable & HealthKit Biometric Sync |

---

## 4. Verification Architecture

The proof verification pipeline separates evidence extraction from the decision engine:

```
                    VIDEO / IMAGE / CAMERA
                              │
                              ▼
                   ┌───────────────────────┐
                   │   Vision Provider     │
                   │  (Pose / Landmarks)   │  <-- [Current: MockProvider | Target: Real Inference]
                   └──────────┬────────────┘
                              │
                    REAL extracted metrics
                   (angles, alignment, reps)
                              │
                              ▼
                   ┌───────────────────────┐
                   │    Decision Engine    │
                   │ (Accept / Reject / QA)│  <-- [REAL & TESTED]
                   └──────────┬────────────┘
                              │
                              ▼
                   ┌───────────────────────┐
                   │    Mission Engine     │
                   │  (State / Escalation) │  <-- [REAL & TESTED]
                   └───────────────────────┘
```

---

## 5. Architectural Invariants & Development Rules

1. **The Single Source-of-Truth Rule**:
   > *No README or documentation feature claim is permitted unless there is a functioning implementation and a test/integration path proving it.*

2. **Local-First Authority**: The morning alarm and mission cycle must operate deterministically without requiring an active network or server handshake.
3. **Deterministic Disarm**: Alarms stop **only** when physical proof is captured and verified, never from dismissing or swiping away notifications.
4. **Decoupled Auxiliary Domains**: Analytics, social features, and health data sync operate as decoupled modules that never block or destabilize the core alarm and mission state machines.
