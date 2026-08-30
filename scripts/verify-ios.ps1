Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "  HABITAT RC1: iOS Platform Quality Verification        " -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan

$ErrorActionPreference = "Stop"

Set-Location apps/mobile

Write-Host "[1/5] Installing mobile dependencies..." -ForegroundColor Yellow
cmd.exe /c "flutter pub get"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "[2/5] Verifying iOS platform infrastructure..." -ForegroundColor Yellow
if (!(Test-Path "ios/Runner.xcodeproj/project.pbxproj") -or !(Test-Path "ios/Podfile")) {
    Write-Error "iOS platform infrastructure missing!"
    exit 1
}

Write-Host "[3/5] Formatting verification..." -ForegroundColor Yellow
cmd.exe /c "dart format lib test"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "[4/5] Static analysis..." -ForegroundColor Yellow
cmd.exe /c "flutter analyze --no-fatal-infos"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "[5/5] Building iOS Release App Framework (No Codesign)..." -ForegroundColor Yellow
cmd.exe /c "flutter build ios --release --no-codesign --no-tree-shake-icons"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Set-Location ../..

Write-Host "========================================================" -ForegroundColor Green
Write-Host "  iOS PLATFORM QUALITY GATE: ALL CHECKS PASSED          " -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Green
