$base = "https://lesgo-api-feature-auth-secmes.free.laravel.cloud/api/v1"
$email = "testuser1778720118525@lesgo.com"
$password = "TestPassword123!"

Write-Host "=== 1. Login ==="
$loginBody = @{ email = $email; password = $password; device_name = "api-verify" } | ConvertTo-Json
try {
    $login = Invoke-RestMethod -Uri "$base/auth/login" -Method Post -ContentType "application/json" -Body $loginBody
} catch {
    Write-Host "Login failed:" $_.Exception.Message
    if ($_.ErrorDetails.Message) { Write-Host $_.ErrorDetails.Message }
    exit 1
}

Write-Host "refresh_token present:" ([bool]$login.refresh_token)
Write-Host "token present:" ([bool]$login.token)

if (-not $login.refresh_token) {
    Write-Host "WARN: Deploy may not be live yet - no refresh_token in login response."
    exit 2
}

Write-Host ""
Write-Host "=== 2. Refresh (invalid) ==="
try {
    Invoke-RestMethod -Uri "$base/auth/refresh" -Method Post -ContentType "application/json" -Body '{"refresh_token":"invalid"}' | ConvertTo-Json
} catch {
    Write-Host "Status:" $_.Exception.Response.StatusCode.value__
    Write-Host $_.ErrorDetails.Message
}

Write-Host ""
Write-Host "=== 3. Refresh (valid) ==="
$refreshBody = @{ refresh_token = $login.refresh_token } | ConvertTo-Json
$refreshed = Invoke-RestMethod -Uri "$base/auth/refresh" -Method Post -ContentType "application/json" -Body $refreshBody
Write-Host "New token:" ([bool]$refreshed.token)
Write-Host "New refresh_token:" ([bool]$refreshed.refresh_token)

Write-Host ""
Write-Host "=== 4. Change password wrong current ==="
$headers = @{ Authorization = "Bearer $($refreshed.token)" }
$badChange = @{ current_password = "wrong"; password = "NewPass123!"; password_confirmation = "NewPass123!" } | ConvertTo-Json
try {
    Invoke-RestMethod -Uri "$base/auth/change-password" -Method Post -ContentType "application/json" -Headers $headers -Body $badChange | ConvertTo-Json
} catch {
    Write-Host "Status:" $_.Exception.Response.StatusCode.value__
    Write-Host $_.ErrorDetails.Message
}

Write-Host ""
Write-Host "All critical auth endpoints reachable."
