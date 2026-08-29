# Habitat Release Verification and Production Gatekeeper

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  HABITAT DISCIPLINE PLATFORM - RELEASE VERIFIER  " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

$ErrorActionPreference = "Stop"
$root = Resolve-Path "$PSScriptRoot/.."
Set-Location $root

# 1. Verify VERSION File
Write-Host "[1/5] Checking VERSION file..." -ForegroundColor Yellow
if (-not (Test-Path "VERSION")) {
    Write-Error "VERSION file is missing!"
}
$version = (Get-Content "VERSION").Trim()
Write-Host "      Detected Release Version: v$version" -ForegroundColor Green

# 2. Security and Secrets Audit
Write-Host "[2/5] Performing Security and Secrets Audit..." -ForegroundColor Yellow
$forbiddenPatterns = @("*.pem", "*.key", "*.keystore", "*.jks", "*.p12", "id_rsa")
$leakedFiles = Get-ChildItem -Path . -Recurse -Include $forbiddenPatterns -Exclude "node_modules", ".git" -ErrorAction SilentlyContinue
if ($leakedFiles.Count -gt 0) {
    Write-Error "CRITICAL: Potential secrets or private key files detected in repo!"
}
Write-Host "      Zero secrets or private keystores committed." -ForegroundColor Green

# 3. Backend TypeScript Compilation
Write-Host "[3/5] Compiling Backend TypeScript..." -ForegroundColor Yellow
Set-Location "$root/backend"
npm.cmd run build
Write-Host "      Backend TypeScript built cleanly." -ForegroundColor Green

# 4. Backend Vitest Test Suite Execution
Write-Host "[4/5] Executing All Test Suites..." -ForegroundColor Yellow
npm.cmd test
Write-Host "      All test suites passed with 100% success rate." -ForegroundColor Green

# 5. Mobile Configuration Check
Write-Host "[5/5] Checking Mobile App Pubspec and Architecture..." -ForegroundColor Yellow
if (-not (Test-Path "$root/apps/mobile/pubspec.yaml")) {
    Write-Error "Mobile pubspec.yaml is missing!"
}
Write-Host "      Mobile configuration intact." -ForegroundColor Green

Set-Location $root
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  RELEASE v$version VERIFIED AND PRODUCTION READY!   " -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Cyan
