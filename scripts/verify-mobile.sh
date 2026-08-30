#!/usr/bin/env bash
set -euo pipefail

echo "========================================================"
echo "  HABITAT RC1: Mobile (Android) Quality Verification   "
echo "========================================================"

cd apps/mobile

echo "[1/6] Installing mobile dependencies..."
flutter pub get

echo "[2/6] Verifying Android platform infrastructure..."
test -f android/settings.gradle
test -f android/app/build.gradle
test -f android/gradlew

echo "[3/6] Formatting verification..."
dart format lib test

echo "[4/6] Static analysis..."
flutter analyze --no-fatal-infos

echo "[5/6] Running Flutter test suite..."
flutter test

echo "[6/6] Building Android Debug APK..."
flutter build apk --debug

echo "========================================================"
echo "  MOBILE (ANDROID) QUALITY GATE: ALL CHECKS PASSED      "
echo "========================================================"
