# Changelog — Habitat Discipline Platform

All notable changes across development phases are documented in this file.

---

## [1.0.0] - 2026-08-29

### Phase 1–3: Core Foundation, Architecture & Domain
- Modular NestJS/Express TypeScript backend with robust SQLite repository layer.
- Core entities: `User`, `Task`, `TaskTemplate`, `Alarm`, `Mission`, `Proof`, `Streak`, `XpTransaction`.
- Auth, JWT tokens, bcrypt hashing, and multi-tenant user isolation.

### Phase 4–6: Mission Proofs & Multi-Strategy Verification
- 5-Minute Escalation Threshold with escalating audio siren loops.
- Camera and video proof capture system with device motion, luminance, and duration telemetry.
- Computer vision heuristics: Push-up rep counter, oral hygiene detector, outdoor morning light verification.

### Phase 7–10: Gamification & Discipline Progress Engine
- Progressive XP curve ($50 \cdot L(L-1)$), streak grace tokens, and non-punitive recovery tokens.
- Idempotent transaction ledger with anti-farming cooldowns.
- Discipline score algorithm weighing 30-day consistency and momentum.

### Phase 11–13: Personal Routine Planner & Bounded Health Layer
- Routine scheduler with conflict detection and quiet hours.
- Decoupled Health & Wellness subsystem: Exercise sessions, hydration tracking (ml $\to$ L), sleep sessions.
- Apple Health / Health Connect deduplication and 14-day correlation analysis.
- GDPR right-to-be-forgotten granular health data deletion.

### Phase 14: Personal Discipline Intelligence & Adaptive Coach
- Versioned Personal Discipline Profile ($v_1 \to v_2$).
- Behavioral pattern discovery with confidence thresholds and sample safeguards.
- AI Action Allowlist Guard blocking unauthorized system commands.
- Non-punitive failure diagnostics and momentum recovery generator.
- Interactive Discipline Coach Flutter UI.

### Phase 15: Gamification, Social Layer & Entitlements
- Server-side authoritative entitlements (`FREE`, `PLUS`, `PRO`).
- Social relationships (`FRIEND`, `BLOCKED`, `PENDING`), content moderation queue, and mutual blocking guarantee.
- Dynamic feature flags and remote configuration.

### Phase 16–17: Master Integration, Release Engineering & Production Launch
- Master Golden Path integration test suite (262/262 Vitest tests passing across 39 files).
- Semantic versioning freeze (`v1.0.0` in `/VERSION`).
- Release scripts (`scripts/verify-release.ps1`, `scripts/build-android.sh`, `scripts/build-ios.sh`).
- GitHub Actions CI/CD workflows for Android (`.aab` / `.apk`), iOS (`.ipa`), Backend, and Web.
- Zero secrets compliance audit.
