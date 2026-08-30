# Habitat Phase 20 Monorepo Quality & Release Verification Script (PowerShell)
$ErrorActionPreference = "Stop"

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "  HABITAT PHASE 20 FULL MONOREPO QUALITY VERIFICATION  " -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan

$rootDir = Resolve-Path "$PSScriptRoot\..\.."

# 1. Backend Verification Gate
Write-Host "`n>>> [1/3] Running Backend Verification Gate..." -ForegroundColor Yellow
Set-Location "$rootDir\backend"
cmd.exe /c "npm ci && npm run build && npm test && npm audit --audit-level=high"
if ($LASTEXITCODE -ne 0) {
    Write-Error "Backend Quality Gate Failed!"
    exit $LASTEXITCODE
}
Write-Host ">>> Backend Verification Gate [PASSED]" -ForegroundColor Green

# 2. Mobile & Design System Gate
Write-Host "`n>>> [2/3] Running Mobile & Design System Quality Gate..." -ForegroundColor Yellow
Set-Location "$rootDir\apps\mobile"
if (Get-Command flutter -ErrorAction SilentlyContinue) {
    cmd.exe /c "flutter pub get && dart format --output=none --set-exit-if-changed lib test && flutter analyze && flutter test"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Mobile Quality Gate Failed!"
        exit $LASTEXITCODE
    }
    Write-Host ">>> Mobile Verification Gate [PASSED]" -ForegroundColor Green
} else {
    Write-Host ">>> Flutter SDK not detected locally. Mobile builds will execute in GitHub Actions CI." -ForegroundColor Gray
}

# 3. Summary
Write-Host "`n========================================================" -ForegroundColor Cyan
Write-Host "  ALL LOCAL QUALITY GATES COMPLETED SUCCESSFULLY!       " -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Cyan
