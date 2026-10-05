# Test if production backend has the fix

$baseUrl = "https://lesgo-api-feature-auth-secmes.free.laravel.cloud/api"

Write-Host "Testing production API..." -ForegroundColor Yellow
Write-Host "URL: $baseUrl" -ForegroundColor Cyan

try {
    $response = Invoke-WebRequest -Uri "$baseUrl/v1/health" -Method Get -ErrorAction Stop
    Write-Host "✅ Production API is accessible" -ForegroundColor Green
    Write-Host "Status: $($response.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "❌ Cannot reach production API" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n📝 To verify the fix is deployed:" -ForegroundColor Yellow
Write-Host "1. Check Laravel Cloud dashboard" -ForegroundColor Cyan
Write-Host "2. Look for commit 3fecf7f deployment status" -ForegroundColor Cyan
Write-Host "3. Check if last deployment was successful" -ForegroundColor Cyan
