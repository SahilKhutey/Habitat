# ADR-002: Backend Architecture & Technology Selection (NestJS + TypeScript)

## Status
Accepted (2026-08-27)

## Context
The Habitat backend serves as the single source of truth for:
* User identity and multi-device profile state.
* Authoritative mission lifecycles (`SCHEDULED` $\to$ `TRIGGERED` $\to$ `ACTIVE` $\to$ `COMPLETED`).
* Append-only XP Transaction Ledger and Streak calculation.
* Real-time WebSocket event dispatching to mobile lock screens.
* Offline synchronization reconciliation queue (`POST /api/v1/sync/batch`).

## Decision
Adopt **NestJS + TypeScript** configured as a **Modular Monolith**.

## Consequences
* **Positive**: Enforces strict module boundaries (`AuthModule`, `TasksModule`, `AlarmsModule`, `MissionsModule`, `ProofsModule`, `GamificationModule`, `SyncModule`) with built-in dependency injection; easy migration of compute-heavy modules to standalone microservices if needed later.
* **Tradeoff**: TypeScript runtime overhead compared to Go/Rust, but yields massive developer velocity and ecosystem richness.
