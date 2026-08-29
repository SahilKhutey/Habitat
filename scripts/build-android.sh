#!/usr/bin/env bash
# Habitat Standard Android APK Build & Packaging Pipeline
set -e

echo "=================================================="
echo "  HABITAT - ANDROID RELEASE BUILD PIPELINE        "
echo "=================================================="

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT/apps/mobile"

# 1. Clean build artifacts
echo "[1/7] Cleaning Flutter project..."
flutter clean

# 2. Fetch dependencies
echo "[2/7] Fetching dependencies..."
flutter pub get

# 3. Static code analysis
echo "[3/7] Running static code analysis..."
flutter analyze

# 4. Run test suite
echo "[4/7] Running tests..."
flutter test

# 5. Build Release APK and App Bundle
echo "[5/7] Building Release APK and AAB..."
flutter build apk --release --no-tree-shake-icons
flutter build appbundle --release --no-tree-shake-icons

# 6. Copy and rename artifacts to release/android/
echo "[6/7] Packaging artifacts into release/android/..."
mkdir -p "$PROJECT_ROOT/release/android"
mkdir -p "$PROJECT_ROOT/release/checksums"

cp build/app/outputs/flutter-apk/app-release.apk "$PROJECT_ROOT/release/android/Habitat-1.0.0-android.apk"
cp build/app/outputs/bundle/release/app-release.aab "$PROJECT_ROOT/release/android/Habitat-1.0.0-android.aab"

# 7. Generate cryptographic checksums
echo "[7/7] Generating SHA-256 checksums..."
cd "$PROJECT_ROOT"
sha256sum release/android/Habitat-1.0.0-android.apk > release/checksums/Habitat-1.0.0-android.sha256

echo "=================================================="
echo "  HABITAT ANDROID BUILD COMPLETE & VERIFIED!     "
echo "  Artifact: release/android/Habitat-1.0.0-android.apk"
echo "  Bundle:   release/android/Habitat-1.0.0-android.aab"
echo "=================================================="
