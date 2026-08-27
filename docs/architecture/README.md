# System Architecture (`docs/architecture`)

```
                         DISCIPLINE PLATFORM
                                  │
             ┌────────────────────┼────────────────────┐
             │                    │                    │
             ▼                    ▼                    ▼
        iOS APP              ANDROID APP           WEB APP
       Flutter/Swift        Flutter/Kotlin       Flutter Web
             │                    │                    │
             └────────────────────┬────────────────────┘
                                  │
                                  ▼
                         MODULAR API GATEWAY
                        (NestJS / TypeScript)
                                  │
             ┌────────────────────┼────────────────────┐
             │                    │                    │
             ▼                    ▼                    ▼
        PostgreSQL             Redis 7              MinIO S3
     (Relational DB)       (Queue & Cache)      (Object Storage)
```

## Source-of-Truth Hierarchy
1. **Product Rules & Recurrence**: Pure Dart Domain Engine (`packages/domain/`).
2. **User Data & XP Ledger**: PostgreSQL (`users`, `streaks`, `xp_transactions`).
3. **Mission State**: NestJS Backend (`missions`, `mission_attempts`, `proofs`).
4. **Time-Critical Wake-Up**: Native Android Foreground Service (`AlarmManager.setExactAndAllowWhileIdle`) & iOS `AVAudioSessionCategoryPlayback`.
5. **Proof Media**: S3 / MinIO Object Storage (`habitat-proofs` bucket).
