# Habitat Phase 14 — Authoritative Evidence Verification & Integrity Engine

## Overview
Phase 14 introduces deterministic verification rules ensuring captured proofs are treated as authentic, tamper-resistant evidence rather than simple path strings.

## Verification Rules Hierarchy
1. **Cryptographic Checksum Format**: Enforces valid 64-character hexadecimal SHA-256 hash.
2. **Anti-Replay Protection**: Re-submitting an already used proof hash is strictly rejected.
3. **Byte Bounds Check**: Validates minimum data payload ($\ge 10\text{ KB}$ for photos, $\ge 50\text{ KB}$ for videos).
4. **Temporal Freshness Window**: Proofs must be captured within 10 minutes of active mission verification.
5. **Video Duration Enforcement**: Video proofs require a minimum of $3.0\text{ seconds}$ duration.
6. **Task Category Matching**: Enforces strict alignment between task requirements and media capture type (e.g. Physical tasks strictly require motion video).

## Verification Pipeline
```
CaptureResult
      ↓
EvidenceVerificationEngine
      ↓
Check 1: SHA-256 format
Check 2: Anti-Replay
Check 3: Byte bounds
Check 4: Freshness (<= 600s)
Check 5: Duration (>= 3s)
Check 6: Category match
      ↓
EvidenceVerificationResult (isPassed, confidenceScore, telemetry)
      ↓
MissionExecutionService
```
