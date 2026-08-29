#!/usr/bin/env bash
# Habitat Release Verification Script
set -e

echo "=== Verifying Habitat Release v1.0.0 ==="

# 1. Version check
if [ ! -f "VERSION" ]; then
  echo "Error: VERSION file missing!"
  exit 1
fi
echo "Version: $(cat VERSION)"

# 2. Security audit (no secrets)
echo "Auditing for private keys and credentials..."
FORBIDDEN="*.pem *.key *.keystore *.jks *.p12 id_rsa"
for pattern in $FORBIDDEN; do
  if find . -name "$pattern" -not -path "./node_modules/*" -not -path "./.git/*" | grep -q .; then
    echo "CRITICAL: Private keys or secrets detected!"
    exit 1
  fi
done
echo "Zero secrets committed."

# 3. Backend compilation & tests
echo "Compiling and testing backend..."
cd backend
npm run build
npm test
cd ..

echo "=== Verification Succeeded: All Gates Passed ==="
