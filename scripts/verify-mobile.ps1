Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "  HABITAT RC1: Mobile (Android) Quality Verification   " -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan

$ErrorActionPreference = "Stop"

Set-Location apps/mobile

Write-Host "[1/6] Installing mobile dependencies..." -ForegroundColor Yellow
cmd.exe /c "flutter pub get"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "[2/6] Verifying Android platform infrastructure..." -ForegroundColor Yellow
if (!(Test-Path "android/settings.gradle") -or !(Test-Path "android/app/build.gradle") -or !(Test-Path "android/gradlew")) {
    Write-Error "Android platform infrastructure missing!"
    exit 1
}

Write-Host "[3/6] Formatting verification..." -ForegroundColor Yellow
cmd.exe /c "dart format lib test"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "[4/6] Static analysis..." -ForegroundColor Yellow
cmd.exe /c "flutter analyze --no-fatal-infos"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "[5/6] Running Flutter test suite..." -ForegroundColor Yellow
cmd.exe /c "flutter test"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "[6/6] Building Android Debug APK..." -ForegroundColor Yellow
cmd.exe /c "flutter build apk --debug"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Set-Location ../..

Write-Host "========================================================" -ForegroundColor Green
Write-Host "  MOBILE (ANDROID) QUALITY GATE: ALL CHECKS PASSED      " -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Green
