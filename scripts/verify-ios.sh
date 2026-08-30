#!/usr/bin/env bash
set -euo pipefail

echo "========================================================"
echo "  HABITAT RC1: iOS Platform Quality Verification        "
echo "========================================================"

cd apps/mobile

echo "[1/5] Installing mobile dependencies..."
flutter pub get

echo "[2/5] Verifying iOS platform infrastructure..."
test -f ios/Runner.xcodeproj/project.pbxproj
test -f ios/Podfile

echo "[3/5] Formatting verification..."
dart format lib test

echo "[4/5] Static analysis..."
flutter analyze --no-fatal-infos

echo "[5/5] Building iOS Release App Framework (No Codesign)..."
flutter build ios --release --no-codesign --no-tree-shake-icons

echo "========================================================"
echo "  iOS PLATFORM QUALITY GATE: ALL CHECKS PASSED          "
echo "========================================================"
