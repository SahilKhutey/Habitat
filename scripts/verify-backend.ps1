Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "  HABITAT RC1: Backend Quality & Verification Gate     " -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan

$ErrorActionPreference = "Stop"

Write-Host "[1/4] Checking Node & dependencies..." -ForegroundColor Yellow
node --version
npm --version
cmd.exe /c "npm ci"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "[2/4] Compiling TypeScript backend..." -ForegroundColor Yellow
cmd.exe /c "npm run build:backend"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "[3/4] Executing test suite..." -ForegroundColor Yellow
cmd.exe /c "npm run test:backend"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "[4/4] Running security vulnerability audit..." -ForegroundColor Yellow
cmd.exe /c "npm audit --audit-level=critical"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "========================================================" -ForegroundColor Green
Write-Host "  BACKEND QUALITY GATE: ALL CHECKS PASSED (100% GREEN)  " -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Green
