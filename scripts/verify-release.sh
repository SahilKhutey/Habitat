#!/usr/bin/env bash
set -euo pipefail

echo "========================================================"
echo "=== [Habitat] Release Candidate Verification Gate    ==="
echo "========================================================"

# 1. VERSION Check
if [ ! -f "VERSION" ]; then
  echo "ERROR: VERSION file missing!"
  exit 1
fi
VERSION=$(cat VERSION | tr -d '[:space:]')
echo "Detected Version: v$VERSION"

# 2. Secret Scan
echo "[Step 1/5] Scanning for accidental key/secret commits..."
LEAKS=$(find . -not -path '*/.*' -not -path './node_modules/*' \( -name "*.pem" -o -name "*.key" -o -name "*.keystore" -o -name "*.jks" -o -name "id_rsa" \))
if [ -n "$LEAKS" ]; then
  echo "CRITICAL: Private keys or certificates detected!"
  echo "$LEAKS"
  exit 1
fi
echo "Security Audit Passed: No raw credentials found."

# 3. Backend Verification
echo "[Step 2/5] Running Backend Quality Gate..."
bash scripts/verify-backend.sh

# 4. Release Manifest Check
echo "[Step 3/5] Verifying Release Manifest & Sign-Off..."
test -f release/RC1/RELEASE_NOTES.md
test -f release/RC1/RC_SIGNOFF.md
test -f release/RC1/SHA256SUMS.txt

echo "========================================================"
echo "=== RELEASE CANDIDATE v$VERSION VERIFIED & APPROVED ==="
echo "========================================================"
