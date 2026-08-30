#!/usr/bin/env bash
set -euo pipefail

echo "========================================================"
echo "  HABITAT RC1: Backend Quality & Verification Gate     "
echo "========================================================"

# 1. Install dependencies from single root lockfile
echo "[1/4] Checking Node & dependencies..."
node --version
npm --version
npm ci

# 2. TypeScript build
echo "[2/4] Compiling TypeScript backend..."
npm run build:backend

# 3. Test suite execution
echo "[3/4] Executing test suite..."
npm run test:backend

# 4. Security vulnerability audit (High/Critical)
echo "[4/4] Running security vulnerability audit..."
npm audit --audit-level=high

echo "========================================================"
echo "  BACKEND QUALITY GATE: ALL CHECKS PASSED (100% GREEN)  "
echo "========================================================"
