# Habitat Mock & Synthetic Entity Inventory (Phase 22)

This document classifies every mock, fake, placeholder, and synthetic component across the Habitat codebase into strict operational categories to guarantee zero production leakage.

---

## 1. Classification Taxonomy

- 🔴 **Production Mock / Shortcut**: Forbidden in production runtime. Must fail closed or be replaced with authentic service.
- 🔴 **Demo / Sample UI Data**: Fake client state. Forbidden in production; UI must reflect true database state.
- 🟡 **Development & Test Seeds**: Database fixtures allowed exclusively during local development (`npm run db:seed:dev`) or automated testing (`npm run db:seed:test`). Forbidden in production deployments.
- 🟢 **Unit-Test Fixtures & Mocks**: Synthetic objects and deterministic stubs allowed strictly inside `tests/` directories for hermetic, fast testing.

---

## 2. Component Inventory & Action Matrix

| Component / File | Discovered Pattern | Classification | Resolution / Operational Rule |
|---|---|:---:|---|
| `backend/src/modules/verification/infrastructure/mock-vision.provider.ts` | `MockVisionProvider` | 🟢 Test Only | Allowed strictly in unit tests. Gated with fail-closed production check in `VisionFactory`. |
| `backend/src/modules/verification/vision.factory.ts` | Default fallback to `'mock'` | 🔴 Production Violation | Refactored: Throws fatal error in production (`NODE_ENV=production` or `HABITAT_ENV=production`) if `MockVisionProvider` is requested. Default in production is strictly `tfjs`. |
| `backend/src/main.ts` | Startup assertion on `VISION_PROVIDER` | 🔴 Refined Guard | Re-enforced: Refuses bootstrap if `VISION_PROVIDER === 'mock'` when running in production mode. |
| `backend/src/modules/media/storage.service.ts` | `?auth=presigned-token-mock` | 🔴 Obsolete Mock | Removed synthetic query parameter. Real S3 presigned URLs or LocalStorage filesystem endpoints are used. |
| `backend/src/modules/accountability/accountability.controller.ts` | `'DISPATCHED_MOCK_SMS'` | 🔴 Placeholder Status | Replaced with `'LOGGED_AND_DISPATCHED'` reflecting real database persistence in `accountability_logs`. |
| `backend/src/modules/intelligence/ai/ai-provider.ts` | `MockAIProvider` | 🔴 Misnamed Local Rule Engine | Renamed to `DeterministicRuleAIProvider`—a true deterministic rule-based local discipline intelligence engine. |
| `backend/src/db/seeds.ts` | Synthetic streaks / fake XP | 🟡 Development Seed | Cleaned: Initial recruit state starts at Day 1, 100 XP recruit grant. Production database bootstrap does not inject artificial activity history. |
| `backend/public/index.html` | Hardcoded metrics & mock toggles | 🔴 Demo UI Data | Cleaned: Auto-authenticates recruit (`alex@habitat.discipline`), fetches real SQLite tasks/alarms/hydration/journal, and uploads actual binary proof files. |
| `apps/mobile/lib/database/local_database.dart` | Default task templates | 🟡 Local Baseline | Provides starter discipline templates (`tpl-pushups`, `tpl-make-bed`) matching canonical backend seeds. |
| `apps/mobile/lib/features/proof/data/proof_file_store.dart` | In-memory fallback | 🟢 Test Fallback | Memory fallback used only when `baseDirectory == null` (widget/unit tests); real filesystem used in app runtime. |
| `backend/tests/*` | Mocks in test files | 🟢 Unit-Test Mocks | Retained strictly within test suites for isolated coverage. |

---

## 3. Production Invariants

1. **Vision Fail-Closed**:
   ```typescript
   if (isProduction && providerType === 'mock') {
     throw new Error('[FATAL] Production violation: MockVisionProvider prohibited in production.');
   }
   ```

2. **Zero Fake State**:
   - Every completed mission, alarm disarm, and XP transaction must originate from a verified event in the database ledger.
   - If an external subsystem (e.g. wearable, SMS gateway) is not configured, state is displayed as `UNAVAILABLE` or `NOT_CONNECTED`, never fabricated.

3. **Continuous Enforcement**:
   - Verified via `npm run verify:no-production-mocks` in CI.
