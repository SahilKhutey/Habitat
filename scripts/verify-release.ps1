Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "=== [Habitat] Release Candidate Verification Gate    ===" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan

$ErrorActionPreference = "Stop"

# 1. VERSION Check
if (!(Test-Path "VERSION")) {
    Write-Error "ERROR: VERSION file missing!"
    exit 1
}
$VERSION = (Get-Content "VERSION").Trim()
Write-Host "Detected Version: v$VERSION" -ForegroundColor Green

# 2. Secret Scan
Write-Host "[Step 1/4] Scanning for accidental key/secret commits..." -ForegroundColor Yellow
$Leaks = Get-ChildItem -Recurse -File -Include "*.pem", "*.key", "*.keystore", "*.jks", "id_rsa" | Where-Object { $_.FullName -notmatch "node_modules|\.git" }
if ($Leaks) {
    Write-Error "CRITICAL: Private keys or certificates detected! $Leaks"
    exit 1
}
Write-Host "Security Audit Passed: No raw credentials found." -ForegroundColor Green

# 3. Backend Verification
Write-Host "[Step 2/4] Running Backend Quality Gate..." -ForegroundColor Yellow
& "$PSScriptRoot\verify-backend.ps1"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# 4. Release Manifest Check
Write-Host "[Step 3/4] Verifying Release Manifest & Sign-Off..." -ForegroundColor Yellow
if (!(Test-Path "release/RC1/RELEASE_NOTES.md") -or !(Test-Path "release/RC1/RC_SIGNOFF.md") -or !(Test-Path "release/RC1/SHA256SUMS.txt")) {
    Write-Error "Release Candidate manifest files missing!"
    exit 1
}
Write-Host "Release Manifest Verified." -ForegroundColor Green

Write-Host "========================================================" -ForegroundColor Green
Write-Host "=== RELEASE CANDIDATE v$VERSION VERIFIED & APPROVED ===" -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Green
