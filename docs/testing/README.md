# Testing Matrix & Verification (`docs/testing`)

## Automated Test Suites
- **Unit Tests**: Pure Dart domain models & recurrence math.
- **Integration Tests**: Vitest integration suites across Auth, Tasks, Alarms, Missions, Proofs, Gamification, and Health.
- **E2E Vertical Slice**: Complete 20-step user lifecycle test verifying full registration-to-completion workflow.

## Running Tests
```bash
# Backend Test Suite
cd backend && npm test

# Flutter Test Suite
cd apps/mobile && flutter test
```
