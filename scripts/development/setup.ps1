# Setup Development Environment
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host " Habitat Discipline Platform - Dev Setup     " -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# 1. Start Docker Infrastructure
Write-Host "`n[1/3] Starting Docker Compose Infrastructure (Postgres, Redis, MinIO)..." -ForegroundColor Yellow
docker compose -f infrastructure/docker/docker-compose.yml up -d

# 2. Install Backend Dependencies
Write-Host "`n[2/3] Installing Backend Dependencies & Building TypeScript..." -ForegroundColor Yellow
Set-Location backend
npm install
npm run build
Set-Location ..

# 3. Flutter Pub Get
Write-Host "`n[3/3] Getting Flutter Dependencies..." -ForegroundColor Yellow
if (Get-Command flutter -ErrorAction SilentlyContinue) {
    Set-Location apps/mobile
    flutter pub get
    Set-Location ../..
}

Write-Host "`n Setup Complete! Run scripts/development/start.ps1 to launch services." -ForegroundColor Green
