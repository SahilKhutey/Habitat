# Habitat Phase 19 — Security & Privacy Hardening

## Overview
Phase 19 establishes an authoritative security boundary around Habitat, enforcing zero-trust client models, authorization checks, anti-replay evidence protection, structured security audit trails, and privacy protection:
```
                         HABITAT
                            │
              ┌─────────────┴─────────────┐
              │                           │
          CLIENT                         API
              │                           │
       ┌──────┴──────┐             ┌──────┴──────┐
       │             │             │             │
    Identity      Local Data    AuthN/AuthZ   Validation
       │             │             │             │
       ▼             ▼             ▼             ▼
    Session       Encryption    Policies      Rate Limits
       │             │             │             │
       └─────────────┴─────────────┴─────────────┘
                            │
                            ▼
                     EVIDENCE SECURITY
                            │
                 ┌──────────┼──────────┐
                 ▼          ▼          ▼
               Media      Replay     Integrity
                 │          │          │
                 └──────────┼──────────┘
                            ▼
                       AUDIT TRAIL
                            │
                            ▼
                    PRIVACY CONTROLS
```

## Security Boundaries & Implementations
1. **Authentication & Session Lifecycle**:
   - Short-lived Access Tokens ($15\text{m}$) + Long-lived Refresh Tokens ($30\text{d}$).
   - Explicit session states: `ACTIVE`, `REVOKED`, `EXPIRED`, `COMPROMISED`.
   - `SecurityService.revokeSession()` immediately terminates refresh capabilities.
2. **Authorization & IDOR Protection**:
   - `validateOwnership(userId, resourceOwnerId)` strictly enforces `resource.ownerId == authenticatedUser.id` across Tasks, Alarms, Missions, Proofs, and Health records.
3. **Anti-Replay Ledger & Evidence Security**:
   - Single-use challenge validation: consumed nonces immediately throw `REPLAY_NONCE_INVALID`.
   - Mission binding: challenges issued for Mission A are strictly rejected on Mission B (`MISSION_BINDING_MISMATCH`).
   - Cryptographic client vs server SHA-256 digest comparison.
4. **Abuse Resistance & Rate Limiting**:
   - Sliding-window rate limiters: Authentication ($5/\text{min}$), Evidence Verification ($20/\text{min}$), Mission Completion ($10/\text{min}$), General API ($100/\text{min}$).
5. **Structured Audit Trail & Privacy Sanitization**:
   - Immutable security audit logs with `requestId` and `eventType` (`LOGIN`, `LOGOUT`, `PROOF_SUBMITTED`, `PROOF_ACCEPTED`, etc.).
   - `sanitizePayload()` strips passwords, tokens, and GPS coordinates prior to logging/persistence.
