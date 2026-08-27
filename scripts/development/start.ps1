# Start Habitat Development Services
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host " Habitat Discipline Platform - Start Dev     " -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# 1. Ensure Docker running
docker compose -f infrastructure/docker/docker-compose.yml up -d

# 2. Launch Backend
Write-Host "`n[+] Starting Habitat Modular Backend on http://localhost:4000..." -ForegroundColor Green
Set-Location backend
npm run dev
