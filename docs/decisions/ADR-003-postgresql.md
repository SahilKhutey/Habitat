# ADR-003: Relational Database & Ledger Selection (PostgreSQL + Prisma)

## Status
Accepted (2026-08-27)

## Context
Habitat domain entities are deeply relational:
`Users` $\to$ `Alarms` $\to$ `Tasks` $\to$ `Missions` $\to$ `Attempts` $\to$ `Proofs` $\to$ `XP Transactions` $\to$ `Streaks`.
Furthermore, gamification requires an append-only audit ledger where user XP is the mathematical sum of immutable transactions rather than an easily corruptible counter.

## Decision
Adopt **PostgreSQL** with **Prisma ORM** as the primary relational database.

## Consequences
* **Positive**: Full ACID transactional guarantees, foreign key cascade constraints, JSONB column support for device sensor telemetry, and robust indexing.
* **Negative**: Requires managed database provisioning compared to NoSQL key-value stores.
