#!/usr/bin/env bash
# Habitat Web Production Build Pipeline
set -e

echo "Building Habitat Web Production SPA..."
if [ -d "apps/web" ]; then
  cd apps/web
  npm install
  npm run build
  cd ../..
  mkdir -p release/web
  echo "Packaging release/web/habitat-web-production.zip..."
fi
echo "Web build pipeline complete."
