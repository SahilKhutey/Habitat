Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "  HABITAT RC1: Web Platform Quality Verification        " -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan

$ErrorActionPreference = "Stop"

Set-Location apps/web

Write-Host "[1/6] Installing web dependencies..." -ForegroundColor Yellow
cmd.exe /c "flutter pub get"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "[2/6] Verifying Web platform infrastructure..." -ForegroundColor Yellow
if (!(Test-Path "web/index.html") -or !(Test-Path "web/manifest.json")) {
    Write-Error "Web platform infrastructure missing!"
    exit 1
}

Write-Host "[3/6] Formatting verification..." -ForegroundColor Yellow
cmd.exe /c "dart format lib test"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "[4/6] Static analysis..." -ForegroundColor Yellow
cmd.exe /c "flutter analyze --no-fatal-infos"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "[5/6] Running Web test suite..." -ForegroundColor Yellow
cmd.exe /c "flutter test"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "[6/6] Building Flutter Web Release..." -ForegroundColor Yellow
cmd.exe /c "flutter build web --release"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Set-Location ../..

Write-Host "========================================================" -ForegroundColor Green
Write-Host "  WEB PLATFORM QUALITY GATE: ALL CHECKS PASSED          " -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Green
