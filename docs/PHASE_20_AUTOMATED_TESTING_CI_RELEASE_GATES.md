# Habitat Phase 20 — Complete Automated Testing, CI/CD & Release Gates

## Overview
Phase 20 establishes a fail-closed quality pipeline across Backend, Mobile (Android & iOS), Web, and GitHub Release automation:
```
CODE
 ↓
FORMAT (dart format / prettier)
 ↓
STATIC ANALYSIS (flutter analyze / tsc)
 ↓
UNIT TESTS (Vitest & Flutter Test)
 ↓
WIDGET TESTS (A11y & Responsive)
 ↓
INTEGRATION & CONTRACT TESTS
 ↓
PLATFORM BUILD (APK / iOS / Web)
 ↓
SECURITY AUDIT (npm audit)
 ↓
RELEASE ARTIFACT (Habitat-vX.Y.Z-android.apk)
 ↓
CHECKSUM (Habitat-vX.Y.Z-android.sha256)
 ↓
GITHUB RELEASE
```

## CI/CD Pipeline Architecture (`.github/workflows/`)
1. **`ci.yml` (Pull Request & Push Workflow)**:
   - **`backend-gate`**: `npm ci`, `npm run build`, `npm test` (402/402 tests), and `npm audit --audit-level=high`.
   - **`mobile-gate`**: `flutter pub get`, `dart format --set-exit-if-changed`, `flutter analyze`, `flutter test`, and `flutter build apk --debug`.
   - **`web-gate`**: `flutter build web --release` and artifact upload.
   - **`ios-gate`**: macOS runner, `flutter build ios --release --no-codesign --no-tree-shake-icons`.
   - **`cross-phase-gate`**: Fail-closed gate blocking merges if any platform fails.
2. **`phase20-release-gate.yml` (Tag Push Workflow `v*`)**:
   - Compiles release APK (`Habitat-vX.Y.Z-android.apk`).
   - Generates SHA-256 digest (`Habitat-vX.Y.Z-android.sha256`).
   - Creates GitHub Release with download assets.

## Quality Scripts & Regression Matrix
- `scripts/phase20_verify.sh`: Bash local verification runner with `set -euo pipefail`.
- `scripts/development/phase20_verify.ps1`: PowerShell local verification runner.
- `apps/mobile/test/phase20_quality_gate_test.dart`: End-to-end regression test suite locking in the core product loop (Task $\to$ Alarm $\to$ Mission $\to$ Verification $\to$ XP $\to$ Streak $\to$ Progress).
