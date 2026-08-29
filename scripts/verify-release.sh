#!/usr/bin/env bash
set -e

echo "=== [Habitat] Release Verifier & Integrity Gatekeeper ==="

# 1. VERSION Check
if [ ! -f "VERSION" ]; then
  echo "ERROR: VERSION file missing!"
  exit 1
fi
VERSION=$(cat VERSION | tr -d '[:space:]')
echo "Detected Version: v$VERSION"

# 2. Secret Scan
echo "Scanning for accidental key/secret commits..."
LEAKS=$(find . -not -path '*/.*' -not -path './node_modules/*' \( -name "*.pem" -o -name "*.key" -o -name "*.keystore" -o -name "*.jks" -o -name "id_rsa" \))
if [ -n "$LEAKS" ]; then
  echo "CRITICAL: Private keys or certificates detected!"
  echo "$LEAKS"
  exit 1
fi
echo "Security Audit Passed: No raw credentials found."

# 3. Backend Compilation & Tests
echo "Building backend..."
cd backend
npm run build
npm test
cd ..

echo "=== RELEASE v$VERSION VERIFIED & PRODUCTION READY ==="
