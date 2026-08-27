# Database Architecture (`docs/database`)

PostgreSQL 16 relational database with strict foreign key constraints and indexed lookup queries.

## Key Schemas
- `users`: Identity, authentication hashes, and timezones.
- `tasks`: Catalog of missions, proof types (`PHOTO`, `VIDEO`), and validation rules.
- `alarms`: Scheduled wakeup commitments with 7-day ISO bitmasks.
- `missions` & `mission_attempts`: Authoritative execution lifecycle logs and resistance metrics.
- `proofs`: Metadata and S3 storage keys for submitted media.
- `xp_transactions`: Immutable double-entry financial-style XP ledger.
- `streaks`: Consecutive streak tracker and 14-day Grace Token vault.
