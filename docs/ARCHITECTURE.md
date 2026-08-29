# Habitat System Architecture & Technical Specifications

```
                       HABITAT PLATFORM
                              │
        ┌─────────────────────┼─────────────────────┐
        ▼                     ▼                     ▼
     ANDROID                iPHONE                 WEB
  (AlarmManager)         (UNUserNotify)         (IndexedDB)
        │                     │                     │
        └─────────────────────┼─────────────────────┘
                              ▼
                     LOCAL-FIRST ENGINE
                              │
        ┌─────────────────────┼─────────────────────┐
        ▼                     ▼                     ▼
      TASKS                 ALARMS                PROOF
  (Templates/Custom)     (5-min Retry)       (Photo/Video)
        │                     │                     │
        └─────────────────────┼─────────────────────┘
                              ▼
                         COMPLETION
                              │
                    ┌─────────┴─────────┐
                    ▼                   ▼
                XP LEDGER             STREAK
               (Append-Only)      (Day-Boundary)
                    │                   │
                    └─────────┬─────────┘
                              ▼
                           JOURNEY
                              │
                              ▼
                        OFFLINE FEEDBACK
```

## Architectural Decoupling Rules
1. **Local-First Authority:** The core loop operates 100% locally on device SQLite without requiring an active network or server handshake.
2. **Deterministic Termination:** Alarms stop **only** when physical proof is captured and verified, never from closing or clearing notifications.
3. **Decoupled Wellness & AI:** Health data deletions or offline AI coach status never impact basic morning alarm delivery.
