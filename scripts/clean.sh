#!/usr/bin/env bash
# Habitat Build Cache Cleaner
set -e

echo "Cleaning Habitat build directories and temporary caches..."
rm -rf build/ dist/ .dart_tool/
if [ -d "apps/mobile" ]; then
  rm -rf apps/mobile/build apps/mobile/.dart_tool
fi
if [ -d "apps/web" ]; then
  rm -rf apps/web/dist apps/web/build
fi
echo "Clean complete."
