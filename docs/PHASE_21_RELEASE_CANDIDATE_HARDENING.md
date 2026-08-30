# Habitat Phase 21 — Release Candidate Hardening

## Overview
Phase 21 establishes formal Release Candidate (RC) verification, hardening the Habitat monorepo for production deployment across Android, iOS, Web, and Backend:
```
                    HABITAT RC
                       │
                       ▼
              FOUNDATION CHECK
                       │
                       ▼
              BACKEND VERIFICATION
                       │
                       ▼
             MOBILE STATIC ANALYSIS
                       │
                       ▼
                UNIT / WIDGET TEST
                       │
                       ▼
             INTEGRATION TESTING
                       │
        ┌──────────────┼──────────────┐
        ▼              ▼              ▼
     ANDROID          iOS            WEB
        │              │              │
        └──────────────┼──────────────┘
                       ▼
              REAL DEVICE TESTING
                       │
                       ▼
               CORE PRODUCT LOOP
                       │
                       ▼
             ALARM / MISSION TEST
                       │
                       ▼
             EVIDENCE VERIFICATION
                       │
                       ▼
               HEALTH / PROGRESS
                       │
                       ▼
             OFFLINE / RECOVERY
                       │
                       ▼
             SECURITY REGRESSION
                       │
                       ▼
            ACCESSIBILITY REGRESSION
                       │
                       ▼
              PERFORMANCE CHECK
                       │
                       ▼
                  RC BUILD
                       │
                       ▼
                FINAL SIGN-OFF
```

## RC Quality Pillars
1. **End-to-End Core Loop Validation**:
   - Task $\to$ Alarm $\to$ Mission $\to$ Single-Use Nonce $\to$ Video/Photo Proof $\to$ MoveNet / Label Verification $\to$ XP $\to$ Streak $\to$ Progress.
2. **Device & OS Matrix Validation**:
   - Android (Exact Alarms, Foreground Siren, BootReceiver, Battery Optimization).
   - iOS (Bounded notification chain, Safe Area adaptivity, VoiceOver).
   - Web (Keyboard traversal, responsive `NavigationRail`, zoom resilience).
3. **Durability & Offline Resiliency**:
   - 250ms write coalescing, backup snapshot fallback, and offline sync queue.
4. **Security & IDOR Isolation**:
   - Authoritative resource ownership, anti-replay nonces, dual tokens, and sanitized audit logs.
5. **Release Manifest**:
   - Release notes, SHA-256 checksums, and RC sign-off available under `release/RC1/`.
