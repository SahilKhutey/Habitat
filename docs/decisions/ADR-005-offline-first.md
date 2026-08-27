# ADR-005: Offline-First Synchronization Architecture

## Status
Accepted (2026-08-27)

## Context
A morning alarm app must be 100% reliable even when the user is in airplane mode or loses Wi-Fi connectivity overnight. Missing a wake-up mission due to network dropouts destroys product trust.

## Decision
Adopt an **Offline-First Architectural Model**:
1. **Local Persistent Cache**: Critical domain state (`User`, `Active Alarms`, `Today's Tasks`, `Current Mission State`) is stored locally in SQLite on the mobile device.
2. **Local Execution**: Alarms trigger locally via native OS schedulers; proofs are recorded and stored to local encrypted disk.
3. **Sync Queue & Idempotency**: Completed missions are queued in a local `SyncQueue` and dispatched via `POST /api/v1/sync/batch` using unique UUID `idempotencyKey` values when network returns.

## Consequences
* **Positive**: Absolute reliability independent of connectivity; zero lost missions or broken streaks due to offline execution.
* **Tradeoff**: Requires robust client-server conflict reconciliation and deduplication logic.
