# Habitat Standard Android APK Build & Packaging Pipeline (PowerShell)
$ErrorActionPreference = "Stop"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  HABITAT - ANDROID RELEASE BUILD PIPELINE        " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

$root = Resolve-Path "$PSScriptRoot/.."
Set-Location "$root/apps/mobile"

# 1. Clean build artifacts
Write-Host "[1/7] Cleaning Flutter project..." -ForegroundColor Yellow
flutter clean

# 2. Fetch dependencies
Write-Host "[2/7] Fetching dependencies..." -ForegroundColor Yellow
flutter pub get

# 3. Static code analysis
Write-Host "[3/7] Running static code analysis..." -ForegroundColor Yellow
flutter analyze

# 4. Run test suite
Write-Host "[4/7] Running tests..." -ForegroundColor Yellow
flutter test

# 5. Build Release APK and App Bundle
Write-Host "[5/7] Building Release APK and AAB..." -ForegroundColor Yellow
flutter build apk --release --no-tree-shake-icons
flutter build appbundle --release --no-tree-shake-icons

# 6. Copy and rename artifacts to release/android/
Write-Host "[6/7] Packaging artifacts into release/android/..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path "$root/release/android" | Out-Null
New-Item -ItemType Directory -Force -Path "$root/release/checksums" | Out-Null

Copy-Item "build/app/outputs/flutter-apk/app-release.apk" -Destination "$root/release/android/Habitat-1.0.0-android.apk" -Force
Copy-Item "build/app/outputs/bundle/release/app-release.aab" -Destination "$root/release/android/Habitat-1.0.0-android.aab" -Force

# 7. Generate cryptographic checksums
Write-Host "[7/7] Generating SHA-256 checksums..." -ForegroundColor Yellow
$hash = (Get-FileHash "$root/release/android/Habitat-1.0.0-android.apk" -Algorithm SHA256).Hash
"$hash  release/android/Habitat-1.0.0-android.apk" | Out-File -FilePath "$root/release/checksums/Habitat-1.0.0-android.sha256" -Encoding utf8

Set-Location $root
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  HABITAT ANDROID BUILD COMPLETE & VERIFIED!     " -ForegroundColor Green
Write-Host "  Artifact: release/android/Habitat-1.0.0-android.apk" -ForegroundColor Green
Write-Host "  Bundle:   release/android/Habitat-1.0.0-android.aab" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Cyan
