# Create Test Rider Account Script (PowerShell)
# This script creates a test rider account for development/testing

$API_BASE_URL = "https://lesgo-api-feature-auth-secmes.free.laravel.cloud/api/v1"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Creating Test Rider Account" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Test Rider Credentials
$RIDER_NAME = "Test Rider"
$RIDER_EMAIL = "testrider@lesgo.com"
$RIDER_PASSWORD = "TestRider123!"
$RIDER_PHONE = "+639171234567"
$RIDER_LICENSE = "N01-23-456789"

Write-Host "Rider Details:" -ForegroundColor Yellow
Write-Host "  Name: $RIDER_NAME"
Write-Host "  Email: $RIDER_EMAIL"
Write-Host "  Password: $RIDER_PASSWORD"
Write-Host "  Phone: $RIDER_PHONE"
Write-Host "  License: $RIDER_LICENSE"
Write-Host ""
Write-Host "Registering rider..." -ForegroundColor Yellow
Write-Host ""

# Prepare request body
$body = @{
    name = $RIDER_NAME
    email = $RIDER_EMAIL
    password = $RIDER_PASSWORD
    password_confirmation = $RIDER_PASSWORD
    phone_number = $RIDER_PHONE
    license_number = $RIDER_LICENSE
} | ConvertTo-Json

# Register the rider
try {
    $response = Invoke-RestMethod -Uri "$API_BASE_URL/drivers/register" `
        -Method Post `
        -ContentType "application/json" `
        -Body $body

    Write-Host "Response:" -ForegroundColor Yellow
    $response | ConvertTo-Json -Depth 10 | Write-Host
    Write-Host ""

    if ($response.success -eq $true) {
        Write-Host "=========================================" -ForegroundColor Green
        Write-Host "✅ Rider account created successfully!" -ForegroundColor Green
        Write-Host "=========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Login Credentials:" -ForegroundColor Cyan
        Write-Host "  Email: $RIDER_EMAIL" -ForegroundColor White
        Write-Host "  Password: $RIDER_PASSWORD" -ForegroundColor White
        Write-Host ""
        Write-Host "Note: The rider status is 'pending' and needs admin approval before accepting orders." -ForegroundColor Yellow
    } else {
        Write-Host "❌ Registration failed!" -ForegroundColor Red
        Write-Host "Error: $($response.message)" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Registration failed!" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        Write-Host "Details: $($_.ErrorDetails.Message)" -ForegroundColor Red
    }
}
