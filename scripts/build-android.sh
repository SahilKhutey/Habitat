#!/usr/bin/env bash
set -e

echo "=== [Habitat Mobile] Building Android Release Bundle & APK ==="
cd apps/mobile

echo "1. Fetching flutter dependencies..."
flutter pub get

echo "2. Building release APK..."
flutter build apk --release --no-tree-shake-icons

echo "3. Building release Android App Bundle (AAB)..."
flutter build appbundle --release --no-tree-shake-icons

echo "=== Android Build Completed Successfully ==="
echo "APK Output: apps/mobile/build/app/outputs/flutter-apk/app-release.apk"
echo "AAB Output: apps/mobile/build/app/outputs/bundle/release/app-release.aab"
