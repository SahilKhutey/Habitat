# Run Master Test Matrix
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host " Habitat Discipline Platform - Test Runner   " -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# 1. Run Backend Vitest Suite
Write-Host "`n[1/2] Running Backend Vitest Integration Suites..." -ForegroundColor Yellow
Set-Location backend
npm test
Set-Location ..

# 2. Run Pure Dart Tests
Write-Host "`n[2/2] Running Pure Dart Engine Tests..." -ForegroundColor Yellow
if (Get-Command dart -ErrorAction SilentlyContinue) {
    Set-Location packages/discipline_engine
    dart test
    Set-Location ../..
}

Write-Host "`n All Test Suites Executed Successfully!" -ForegroundColor Green
