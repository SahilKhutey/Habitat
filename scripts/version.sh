#!/usr/bin/env bash
# Synchronize Habitat version across Android, iOS, Backend, and Web
set -e

VERSION=$(cat VERSION | tr -d '[:space:]')
echo "Synchronizing Habitat version to: v$VERSION"

# 1. Update package.json version
if [ -f "backend/package.json" ]; then
  npm --prefix backend version "$VERSION" --no-git-tag-version || true
fi

# 2. Update pubspec.yaml version if present
if [ -f "apps/mobile/pubspec.yaml" ]; then
  sed -i "s/^version: .*/version: $VERSION+1/" apps/mobile/pubspec.yaml || true
fi

echo "Version synchronization complete: $VERSION"
