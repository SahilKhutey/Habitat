#!/usr/bin/env bash
set -euo pipefail

echo "========================================================"
echo "  HABITAT RC1: Web Platform Quality Verification        "
echo "========================================================"

cd apps/web

echo "[1/6] Installing web dependencies..."
flutter pub get

echo "[2/6] Verifying Web platform infrastructure..."
test -f web/index.html
test -f web/manifest.json

echo "[3/6] Formatting verification..."
dart format lib test

echo "[4/6] Static analysis..."
flutter analyze --no-fatal-infos

echo "[5/6] Running Web test suite..."
flutter test

echo "[6/6] Building Flutter Web Release..."
flutter build web --release

echo "========================================================"
echo "  WEB PLATFORM QUALITY GATE: ALL CHECKS PASSED          "
echo "========================================================"
