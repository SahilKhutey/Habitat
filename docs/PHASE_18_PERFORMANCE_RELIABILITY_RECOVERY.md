# Habitat Phase 18 — Performance, Reliability & Recovery Architecture

## Overview
Phase 18 establishes durability, write coalescing, backup recovery, atomic media promotion, and Android boot recovery:
```
                    HABITAT
                       │
              ┌────────┴────────┐
              │                 │
          UI / Flutter      Native OS
              │                 │
              ▼                 ▼
        App Controller      Alarm System
              │                 │
              ▼                 │
       Local Data Layer          │
              │                 │
       ┌──────┼───────┐          │
       │      │       │          │
     Tasks  Health  Missions     │
       │      │       │          │
       └──────┼───────┘          │
              ▼                  │
       Durable Local State       │
              │                  │
       ┌──────┴──────┐           │
       │             │           │
     Backup      Sync Queue      │
       │             │           │
       └──────┬──────┘           │
              ▼                  │
        Recovery Engine ◄────────┘
```

## Reliability Subsystems
1. **Write Coalescing & Lifecycle Flush**:
   - 250ms debounce window groups high-frequency UI mutations.
   - `flush()` invoked on `AppLifecycleState.paused` and `AppLifecycleState.detached`.
2. **Snapshot Versioning & Backup Snapshot**:
   - `schemaVersion: 3`, `revision: number`, `savedAt: timestamp`.
   - `habitat.local.v2.backup` created prior to replacing primary snapshot.
   - Corruption detection falls back to backup without destructive data loss.
3. **Durable Sync Queue**:
   - Persists offline events with idempotency keys (`idempotencyKey`), retry counters (`retryCount`), and timestamps.
4. **Android Boot & Package Replacement Recovery**:
   - `BootReceiver.kt` reconstructs scheduled alarms from durable local store upon `BOOT_COMPLETED` and `MY_PACKAGE_REPLACED`.
5. **Reliability Watchdog Coordinator**:
   - `HabitatReliabilityCoordinator.getSnapshot()` captures task count, alarm count, attempt count, proof count, health log count, revision number, and pending sync counts.
