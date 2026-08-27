# Habitat Platform Architecture Overview

Habitat is a high-assurance, multi-platform discipline and behavioral execution platform engineered to eliminate morning resistance, inertia, and habit failure through physical commitment verification.

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
│  (Data Ledger)  │    │ (Proof Storage) │    │  (Psychoacoustic│
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## System Topology & Subsystems

1. **Domain Engine (`packages/domain/`)**: Pure Dart models with zero external UI or framework dependencies for total reusability across Mobile and Web.
2. **Design System (`packages/design_system/`)**: Tactical luxury aesthetic based on High-Contrast Tactical themes (OLED Dark `#0D0E11` & Crisp Paper Light `#F8F9FA`) with strict accessibility and 8-point spatial rhythm.
3. **Task & Template Engine (`backend/src/modules/tasks/`)**: 10 Starter Discipline Templates (`tpl-make-bed`, `tpl-pushups-10`, `tpl-brush-teeth`, `tpl-hydrate-glass`, `tpl-morning-sunlight`, `tpl-cold-shower`, `tpl-journal-plan`, `tpl-read-10-pages`, `tpl-outdoor-walk`, `tpl-wardrobe-prep`) and customized User Tasks.
4. **Scheduling & Alarm Engine (`backend/src/modules/scheduling/`, `backend/src/modules/alarms/`)**: Timezone-aware next occurrence calculator with a 5-minute escalation retry loop ($70\text{dB} \to 85\text{dB} \to 100\text{dB}$).
5. **Mission Execution & Proof Verification (`backend/src/modules/mission/`, `backend/src/modules/proofs/`)**: Multi-modal verification (`PHOTO`, `VIDEO`, `MANUAL`) with strict `ProofStateMachine` and `BasicVerificationProvider`.
6. **Discipline Economics & Gamification (`backend/src/modules/gamification/`)**: Append-only immutable XP ledger (`xp_transactions`), progressive level curve ($50 \cdot L(L-1)$), streak calculation with Grace Vault defense shields, and 0–100 Daily Discipline Score.
7. **Offline Sync & Multi-Device Coordination (`backend/src/modules/sync/`, `backend/src/modules/mesh/`)**: Offline SQLite queue, Last-Write-Wins conflict resolver, clock drift sanitization window, and remote alarm disarm mesh broadcasting.
