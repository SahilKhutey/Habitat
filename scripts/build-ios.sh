#!/usr/bin/env bash
set -e

echo "=== [Habitat Mobile] Building iOS Release Archive ==="
cd apps/mobile

echo "1. Fetching flutter dependencies..."
flutter pub get

echo "2. Building iOS release bundle..."
flutter build ios --release --no-codesign --no-tree-shake-icons

echo "=== iOS Release Bundle Built Successfully ==="
echo "iOS Output: apps/mobile/build/ios/iphoneos/Runner.app"
