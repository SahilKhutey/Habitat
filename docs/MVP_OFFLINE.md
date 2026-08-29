# Phase 19 — Local-First MVP / Offline Architecture

## Core Philosophy
The Habitat MVP operates with a **Local-First & Offline-by-Default** philosophy.
The core discipline loop functions completely without cloud infrastructure, internet connectivity, or remote authentication.

```
                 DISCIPLINE MVP
                       │
          ┌────────────┴────────────┐
          ▼                         ▼
       MOBILE                      WEB
          │                         │
   ┌──────┴──────┐             Local browser
   ▼             ▼              (IndexedDB)
 Android        iPhone
   │             │
   └──────┬──────┘
          ▼
    LOCAL STORAGE
          │
          ▼
    LOCAL DATABASE
          │
          ▼
   LOCAL TASK ENGINE
          │
          ▼
     ALARM ENGINE (5-min escalation)
          │
          ▼
     CAMERA / PROOF
          │
          ▼
      XP / STREAK
          │
          ▼
      LOCAL HISTORY / FEEDBACK EXPORT
```

## Features Supported Offline
1. **Local User Profile:** Fast zero-registration onboarding.
2. **Deterministic Task & Alarm Engine:** Local SQLite storage with 5-minute repeating alarms until verification.
3. **Local Media & Proof:** In-app camera captures stored in app-private sandboxed directories (`discipline/proofs/`).
4. **Immutable XP Ledger & Streak:** Tamper-proof offline XP calculations and day-boundary streak advancement.
5. **Offline Feedback Queue:** Submit feedback, bugs, and ratings offline; export to JSON/ZIP via the native OS share sheet.
