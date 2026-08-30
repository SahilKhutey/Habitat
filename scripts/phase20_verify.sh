#!/usr/bin/env bash
# Habitat Phase 20 Monorepo Quality & Release Verification Script
set -euo pipefail

echo "========================================================"
echo "  HABITAT PHASE 20 FULL MONOREPO QUALITY VERIFICATION  "
echo "========================================================"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# 1. Backend Verification Gate
echo ""
echo ">>> [1/3] Running Backend Verification Gate..."
cd "${ROOT_DIR}/backend"
npm ci
npm run build
npm test
npm audit --audit-level=high
echo ">>> Backend Verification Gate [PASSED]"

# 2. Shared Design System & Mobile Gate
echo ""
echo ">>> [2/3] Running Mobile & Design System Quality Gate..."
cd "${ROOT_DIR}/apps/mobile"
if command -v flutter &> /dev/null; then
    flutter pub get
    dart format --output=none --set-exit-if-changed lib test
    flutter analyze
    flutter test
    echo ">>> Mobile Verification Gate [PASSED]"
else
    echo ">>> Flutter SDK not detected in environment. Skipping local Flutter execution (delegated to GitHub Actions CI)."
fi

# 3. Cross-Phase Gate Summary
echo ""
echo "========================================================"
echo "  ALL LOCAL QUALITY GATES COMPLETED SUCCESSFULLY!       "
echo "========================================================"
