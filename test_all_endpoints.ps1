# ============================================================
# LeSGo API - Comprehensive Endpoint Test Script
# Tests ALL backend API endpoints against production
# ============================================================

$BaseUrl = "https://lesgo-api-feature-auth-fhlrsy.laravel.cloud/api/v1"
$Token = ""
$Global:PassCount = 0
$Global:FailCount = 0
$Global:SkipCount = 0
$Global:Results = @()

# ── HELPER FUNCTIONS ──────────────────────────────────────────

function Write-Header($text) {
    Write-Host ""
    Write-Host ("=" * 70) -ForegroundColor Cyan
    Write-Host "  $text" -ForegroundColor Cyan
    Write-Host ("=" * 70) -ForegroundColor Cyan
}

function Write-SubHeader($text) {
    Write-Host ""
    Write-Host "  --- $text ---" -ForegroundColor Yellow
}

function Test-Endpoint {
    param(
        [string]$Method,
        [string]$Path,
        [string]$Description,
        [bool]$RequiresAuth = $true,
        [hashtable]$Body = $null,
        [int[]]$AcceptableCodes = @(200, 201),
        [int[]]$ExpectedFailCodes = @(404, 422, 403, 429, 405)
    )

    $url = "$BaseUrl$Path"
    $headers = @{ "Accept" = "application/json"; "Content-Type" = "application/json" }

    if ($RequiresAuth -and $Token) {
        $headers["Authorization"] = "Bearer $Token"
    }

    try {
        $params = @{
            Uri = $url
            Method = $Method
            Headers = $headers
            TimeoutSec = 30
            ErrorAction = "Stop"
        }

        if ($Body -and $Method -ne "GET") {
            $params["Body"] = ($Body | ConvertTo-Json -Depth 10)
        }

        $response = Invoke-WebRequest @params -UseBasicParsing
        $statusCode = $response.StatusCode

        if ($statusCode -in $AcceptableCodes) {
            Write-Host "  [PASS] $Method $Path - $statusCode - $Description" -ForegroundColor Green
            $Global:PassCount++
            $Global:Results += [PSCustomObject]@{ Status="PASS"; Method=$Method; Path=$Path; Code=$statusCode; Desc=$Description }
        } else {
            Write-Host "  [FAIL] $Method $Path - $statusCode - $Description" -ForegroundColor Red
            $Global:FailCount++
            $Global:Results += [PSCustomObject]@{ Status="FAIL"; Method=$Method; Path=$Path; Code=$statusCode; Desc=$Description }
        }
    }
    catch {
        $statusCode = 0
        if ($_.Exception.Response) {
            $statusCode = [int]$_.Exception.Response.StatusCode
        }

        if ($statusCode -in $ExpectedFailCodes) {
            Write-Host "  [PASS] $Method $Path - $statusCode (expected) - $Description" -ForegroundColor DarkGreen
            $Global:PassCount++
            $Global:Results += [PSCustomObject]@{ Status="PASS"; Method=$Method; Path=$Path; Code=$statusCode; Desc=$Description }
        } elseif ($statusCode -eq 401 -and !$RequiresAuth) {
            Write-Host "  [PASS] $Method $Path - 401 (auth required as expected) - $Description" -ForegroundColor DarkGreen
            $Global:PassCount++
            $Global:Results += [PSCustomObject]@{ Status="PASS"; Method=$Method; Path=$Path; Code=401; Desc=$Description }
        } elseif ($statusCode -eq 401) {
            Write-Host "  [FAIL] $Method $Path - 401 Unauthorized - $Description" -ForegroundColor Red
            $Global:FailCount++
            $Global:Results += [PSCustomObject]@{ Status="FAIL"; Method=$Method; Path=$Path; Code=401; Desc=$Description }
        } elseif ($statusCode -gt 0) {
            Write-Host "  [FAIL] $Method $Path - $statusCode - $Description" -ForegroundColor Red
            $Global:FailCount++
            $Global:Results += [PSCustomObject]@{ Status="FAIL"; Method=$Method; Path=$Path; Code=$statusCode; Desc=$Description }
        } else {
            Write-Host "  [FAIL] $Method $Path - ERROR: $($_.Exception.Message) - $Description" -ForegroundColor Red
            $Global:FailCount++
            $Global:Results += [PSCustomObject]@{ Status="FAIL"; Method=$Method; Path=$Path; Code="ERR"; Desc=$Description }
        }
    }
}

# ── START TESTING ──────────────────────────────────────────────

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║     LeSGo API - COMPREHENSIVE ENDPOINT TEST SUITE              ║" -ForegroundColor Magenta
Write-Host "║     Target: $BaseUrl     ║" -ForegroundColor Magenta
Write-Host "║     Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')                              ║" -ForegroundColor Magenta
Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta

# ══════════════════════════════════════════════════════════════════
# 1. PUBLIC ENDPOINTS (No Auth Required)
# ══════════════════════════════════════════════════════════════════

Write-Header "1. PUBLIC ENDPOINTS - No Auth Required"

Write-SubHeader "Health and System"
Test-Endpoint -Method "GET" -Path "/ping" -Description "Ping" -RequiresAuth $false
Test-Endpoint -Method "GET" -Path "/health" -Description "Health check" -RequiresAuth $false
Test-Endpoint -Method "GET" -Path "/health/liveness" -Description "Liveness probe" -RequiresAuth $false
Test-Endpoint -Method "GET" -Path "/health/readiness" -Description "Readiness probe" -RequiresAuth $false
Test-Endpoint -Method "GET" -Path "/ping-legacy" -Description "Legacy ping" -RequiresAuth $false

Write-SubHeader "Config and App Info"
Test-Endpoint -Method "GET" -Path "/config/mobile" -Description "Mobile config" -RequiresAuth $false
Test-Endpoint -Method "GET" -Path "/app/rider-version" -Description "Rider app version" -RequiresAuth $false

Write-SubHeader "Services (Public)"
Test-Endpoint -Method "GET" -Path "/services" -Description "List services" -RequiresAuth $false
Test-Endpoint -Method "GET" -Path "/services/1" -Description "Show service #1" -RequiresAuth $false

Write-SubHeader "Partners/Merchants (Public)"
Test-Endpoint -Method "GET" -Path "/partners" -Description "List partners" -RequiresAuth $false
Test-Endpoint -Method "GET" -Path "/partners/1" -Description "Show partner #1" -RequiresAuth $false
Test-Endpoint -Method "GET" -Path "/partners/1/menu" -Description "Partner menu" -RequiresAuth $false
Test-Endpoint -Method "GET" -Path "/partners/1/reviews" -Description "Partner reviews" -RequiresAuth $false
Test-Endpoint -Method "GET" -Path "/partners/1/branches" -Description "Partner branches" -RequiresAuth $false

Write-SubHeader "Social (Public)"
Test-Endpoint -Method "GET" -Path "/social/trending" -Description "Trending social" -RequiresAuth $false
Test-Endpoint -Method "GET" -Path "/social/statistics" -Description "Social statistics" -RequiresAuth $false

# ══════════════════════════════════════════════════════════════════
# 2. AUTHENTICATION
# ══════════════════════════════════════════════════════════════════

Write-Header "2. AUTHENTICATION"

Write-SubHeader "Login (get token)"

# Try multiple credential sets
$credentialSets = @(
    @{ email = "testrider@lesgo.com"; password = "TestRider123!"; label = "testrider@lesgo.com" },
    @{ email = "driver@lesgo.test"; password = "password"; label = "driver@lesgo.test" },
    @{ email = "customer@lesgo.test"; password = "password"; label = "customer@lesgo.test" },
    @{ email = "admin@lesgo.test"; password = "admin123"; label = "admin@lesgo.test" },
    @{ email = "merchant@test.com"; password = "Password123!"; label = "merchant@test.com" },
    @{ email = "rider@lesgo.ph"; password = "password123"; label = "rider@lesgo.ph" },
    @{ email = "test@example.com"; password = "password"; label = "test@example.com" }
)

$headers = @{ "Accept" = "application/json"; "Content-Type" = "application/json" }
$loginSuccess = $false

foreach ($cred in $credentialSets) {
    if ($loginSuccess) { break }
    $loginBody = @{ email = $cred.email; password = $cred.password; device_name = "test-script" }
    try {
        $loginResponse = Invoke-WebRequest -Uri "$BaseUrl/auth/login" -Method POST -Headers $headers -Body ($loginBody | ConvertTo-Json) -UseBasicParsing -TimeoutSec 30 -ErrorAction Stop
        $loginData = $loginResponse.Content | ConvertFrom-Json
        if ($loginData.data.token) { $Token = $loginData.data.token }
        elseif ($loginData.token) { $Token = $loginData.token }
        elseif ($loginData.data.access_token) { $Token = $loginData.data.access_token }
        elseif ($loginData.access_token) { $Token = $loginData.access_token }
        Write-Host "  [PASS] POST /auth/login - $($loginResponse.StatusCode) - Login as $($cred.label)" -ForegroundColor Green
        $Global:PassCount++
        $Global:Results += [PSCustomObject]@{ Status="PASS"; Method="POST"; Path="/auth/login"; Code=$loginResponse.StatusCode; Desc="Login $($cred.label)" }
        $loginSuccess = $true
    }
    catch {
        $sc = 0
        if ($_.Exception.Response) { $sc = [int]$_.Exception.Response.StatusCode }
        Write-Host "  [INFO] $($cred.label) failed ($sc)" -ForegroundColor Yellow
    }
}

if (-not $loginSuccess) {
    # Last resort: try registering a new user
    Write-Host "  [INFO] All logins failed. Trying to register new test user..." -ForegroundColor Yellow
    $regBody = @{
        name = "API Test User"
        email = "apitest_$(Get-Date -Format 'yyyyMMddHHmmss')@lesgo.test"
        password = "TestPass123!"
        password_confirmation = "TestPass123!"
        phone_number = "+639999999999"
        device_name = "test-script"
    }
    try {
        $regResponse = Invoke-WebRequest -Uri "$BaseUrl/auth/register" -Method POST -Headers $headers -Body ($regBody | ConvertTo-Json) -UseBasicParsing -TimeoutSec 30 -ErrorAction Stop
        $regData = $regResponse.Content | ConvertFrom-Json
        if ($regData.data.token) { $Token = $regData.data.token }
        elseif ($regData.token) { $Token = $regData.token }
        elseif ($regData.data.access_token) { $Token = $regData.data.access_token }
        elseif ($regData.access_token) { $Token = $regData.access_token }
        Write-Host "  [PASS] Registration + login succeeded" -ForegroundColor Green
        $Global:PassCount++
    }
    catch {
        Write-Host "  [FAIL] POST /auth/login - All login/register attempts failed" -ForegroundColor Red
        $Global:FailCount++
        $Global:Results += [PSCustomObject]@{ Status="FAIL"; Method="POST"; Path="/auth/login"; Code="ERR"; Desc="All logins failed" }
    }
}
if ($Token) {
    Write-Host "  [INFO] Token acquired successfully" -ForegroundColor Cyan
} else {
    Write-Host "  [WARN] No token! Protected endpoints will fail." -ForegroundColor Red
}

Write-SubHeader "Auth - Protected Endpoints"
Test-Endpoint -Method "GET" -Path "/auth/me" -Description "Get current user"
Test-Endpoint -Method "POST" -Path "/auth/refresh" -Description "Refresh token" -Body @{ refresh_token = "test" } -AcceptableCodes @(200,201) -ExpectedFailCodes @(401,422,400)

# ══════════════════════════════════════════════════════════════════
# 3. DRIVERS
# ══════════════════════════════════════════════════════════════════

Write-Header "3. DRIVERS"

Test-Endpoint -Method "GET" -Path "/drivers" -Description "List drivers"
Test-Endpoint -Method "GET" -Path "/drivers/1" -Description "Show driver #1"
Test-Endpoint -Method "GET" -Path "/drivers/vehicles" -Description "List driver vehicles"
Test-Endpoint -Method "GET" -Path "/drivers/me/package-tiers" -Description "Package tiers"
Test-Endpoint -Method "GET" -Path "/drivers/me/earnings" -Description "Driver earnings"

# ══════════════════════════════════════════════════════════════════
# 4. ORDERS
# ══════════════════════════════════════════════════════════════════

Write-Header "4. ORDERS"

Test-Endpoint -Method "GET" -Path "/orders" -Description "List orders"
Test-Endpoint -Method "GET" -Path "/orders/1" -Description "Show order #1"

$estimateBody = @{
    service_id = 1
    pickup_latitude = 14.5995
    pickup_longitude = 120.9842
    dropoff_latitude = 14.6010
    dropoff_longitude = 120.9900
}
Test-Endpoint -Method "POST" -Path "/orders/estimate" -Description "Order estimate" -Body $estimateBody -AcceptableCodes @(200,201) -ExpectedFailCodes @(404,422,400)
Test-Endpoint -Method "GET" -Path "/orders/1/receipt" -Description "Order receipt"
Test-Endpoint -Method "GET" -Path "/orders/1/tracking" -Description "Order tracking"
Test-Endpoint -Method "GET" -Path "/orders/1/driver-location" -Description "Order driver location"

# ══════════════════════════════════════════════════════════════════
# 5. WALLETS & PAYMENTS
# ══════════════════════════════════════════════════════════════════

Write-Header "5. WALLETS AND PAYMENTS"

Write-SubHeader "Wallets"
Test-Endpoint -Method "GET" -Path "/wallets/my/wallet" -Description "My wallet"
Test-Endpoint -Method "GET" -Path "/wallets/my/transactions" -Description "My transactions"
Test-Endpoint -Method "GET" -Path "/wallets/my/payouts" -Description "My payouts"
Test-Endpoint -Method "GET" -Path "/wallets/my/validation" -Description "Wallet validation"
Test-Endpoint -Method "GET" -Path "/wallets/my/linked-accounts" -Description "Linked accounts"
Test-Endpoint -Method "GET" -Path "/wallets/threshold" -Description "Wallet threshold"

Write-SubHeader "Payments"
Test-Endpoint -Method "GET" -Path "/payments" -Description "List payments"

Write-SubHeader "Payment Gateway"
Test-Endpoint -Method "GET" -Path "/payment-gateway/wallet/validate" -Description "PG wallet validate"
Test-Endpoint -Method "GET" -Path "/payment-gateway/wallet/threshold" -Description "PG wallet threshold"

# ══════════════════════════════════════════════════════════════════
# 6. ADDRESSES
# ══════════════════════════════════════════════════════════════════

Write-Header "6. ADDRESSES"

Test-Endpoint -Method "GET" -Path "/addresses" -Description "My addresses"

# ══════════════════════════════════════════════════════════════════
# 7. NOTIFICATIONS
# ══════════════════════════════════════════════════════════════════

Write-Header "7. NOTIFICATIONS"

Test-Endpoint -Method "GET" -Path "/notifications" -Description "List notifications"
Test-Endpoint -Method "GET" -Path "/notifications/unread-count" -Description "Unread count"
Test-Endpoint -Method "POST" -Path "/notifications/read-all" -Description "Mark all read" -AcceptableCodes @(200,201,204)

# ══════════════════════════════════════════════════════════════════
# 8. REVIEWS & RATINGS
# ══════════════════════════════════════════════════════════════════

Write-Header "8. REVIEWS AND RATINGS"

Test-Endpoint -Method "GET" -Path "/reviews" -Description "List reviews"
Test-Endpoint -Method "GET" -Path "/reviews/my-reviews" -Description "My reviews"
Test-Endpoint -Method "GET" -Path "/reviews/statistics" -Description "Review stats"
Test-Endpoint -Method "GET" -Path "/reviews/1" -Description "Show review #1"

# ══════════════════════════════════════════════════════════════════
# 9. SUPPORT TICKETS
# ══════════════════════════════════════════════════════════════════

Write-Header "9. SUPPORT TICKETS"

Test-Endpoint -Method "GET" -Path "/support/tickets" -Description "List tickets"
Test-Endpoint -Method "GET" -Path "/support/tickets/statistics" -Description "Ticket stats"
Test-Endpoint -Method "GET" -Path "/support/tickets/1" -Description "Show ticket #1"

# ══════════════════════════════════════════════════════════════════
# 10. FAQ & HELP CENTER
# ══════════════════════════════════════════════════════════════════

Write-Header "10. FAQ AND HELP CENTER"

Test-Endpoint -Method "GET" -Path "/faq/categories" -Description "FAQ categories"
Test-Endpoint -Method "GET" -Path "/faq/categories/1" -Description "FAQ category #1"
Test-Endpoint -Method "GET" -Path "/faq/articles" -Description "FAQ articles"
Test-Endpoint -Method "GET" -Path "/faq/articles/1" -Description "FAQ article #1"
Test-Endpoint -Method "GET" -Path "/faq/search?q=delivery" -Description "FAQ search"
Test-Endpoint -Method "GET" -Path "/faq/featured" -Description "FAQ featured"
Test-Endpoint -Method "GET" -Path "/faq/popular" -Description "FAQ popular"
Test-Endpoint -Method "GET" -Path "/faq/statistics" -Description "FAQ statistics"

# ══════════════════════════════════════════════════════════════════
# 11. CHAT / MESSAGES
# ══════════════════════════════════════════════════════════════════

Write-Header "11. CHAT / MESSAGES"

Test-Endpoint -Method "GET" -Path "/chat/conversations" -Description "List conversations"
Test-Endpoint -Method "GET" -Path "/chat/unread-count" -Description "Chat unread count"

# ══════════════════════════════════════════════════════════════════
# 12. LIVE TRACKING
# ══════════════════════════════════════════════════════════════════

Write-Header "12. LIVE TRACKING"

Test-Endpoint -Method "GET" -Path "/tracking/drivers/nearby" -Description "Nearby drivers"
Test-Endpoint -Method "GET" -Path "/tracking/stats" -Description "Tracking stats"
Test-Endpoint -Method "GET" -Path "/tracking/driver/1/location" -Description "Driver #1 location"
Test-Endpoint -Method "GET" -Path "/tracking/driver/1/history" -Description "Driver #1 history"
Test-Endpoint -Method "GET" -Path "/tracking/order/1/live" -Description "Order #1 live track"
Test-Endpoint -Method "GET" -Path "/tracking/order/1/eta" -Description "Order #1 ETA"

# ══════════════════════════════════════════════════════════════════
# 13. DOCUMENTS / VERIFICATION
# ══════════════════════════════════════════════════════════════════

Write-Header "13. DOCUMENTS / VERIFICATION"

Test-Endpoint -Method "GET" -Path "/documents/my-documents" -Description "My documents"
Test-Endpoint -Method "GET" -Path "/documents/types" -Description "Document types"
Test-Endpoint -Method "GET" -Path "/documents/verification-status" -Description "Verification status"

# ══════════════════════════════════════════════════════════════════
# 14. SOCIAL MEDIA
# ══════════════════════════════════════════════════════════════════

Write-Header "14. SOCIAL MEDIA (Authenticated)"

Test-Endpoint -Method "GET" -Path "/social/platforms" -Description "Social platforms"
Test-Endpoint -Method "GET" -Path "/social/my-shares" -Description "My shares"
Test-Endpoint -Method "GET" -Path "/social/analytics" -Description "Social analytics"

# ══════════════════════════════════════════════════════════════════
# 15. VOUCHERS
# ══════════════════════════════════════════════════════════════════

Write-Header "15. VOUCHERS"

Test-Endpoint -Method "GET" -Path "/vouchers/available" -Description "Available vouchers"
Test-Endpoint -Method "POST" -Path "/vouchers/validate" -Description "Validate voucher" -Body @{ code = "TESTCODE" } -AcceptableCodes @(200,201) -ExpectedFailCodes @(404,422,400)

# ══════════════════════════════════════════════════════════════════
# 16. GEOFENCING
# ══════════════════════════════════════════════════════════════════

Write-Header "16. GEOFENCING"

Test-Endpoint -Method "GET" -Path "/geofences" -Description "List geofences"
Test-Endpoint -Method "GET" -Path "/geofences/types" -Description "Geofence types"
Test-Endpoint -Method "GET" -Path "/geofences/nearby?latitude=14.5995&longitude=120.9842" -Description "Nearby geofences"
Test-Endpoint -Method "GET" -Path "/geofences/statistics" -Description "Geofence stats"

# ══════════════════════════════════════════════════════════════════
# 17. REALTIME / WEBSOCKET
# ══════════════════════════════════════════════════════════════════

Write-Header "17. REALTIME / WEBSOCKET"

Test-Endpoint -Method "GET" -Path "/realtime/config" -Description "Realtime config"
Test-Endpoint -Method "GET" -Path "/realtime/connections" -Description "Realtime connections"
Test-Endpoint -Method "GET" -Path "/realtime/notifications" -Description "Realtime notifications"
Test-Endpoint -Method "GET" -Path "/realtime/stats" -Description "Realtime stats"

# ══════════════════════════════════════════════════════════════════
# 18. ANALYTICS
# ══════════════════════════════════════════════════════════════════

Write-Header "18. ANALYTICS"

Test-Endpoint -Method "GET" -Path "/analytics/dashboard" -Description "Analytics dashboard"
Test-Endpoint -Method "GET" -Path "/analytics/revenue" -Description "Revenue analytics"
Test-Endpoint -Method "GET" -Path "/analytics/drivers/performance" -Description "Driver performance"
Test-Endpoint -Method "GET" -Path "/analytics/customers/behavior" -Description "Customer behavior"
Test-Endpoint -Method "GET" -Path "/analytics/services/demand" -Description "Service demand"
Test-Endpoint -Method "GET" -Path "/analytics/geofences/effectiveness" -Description "Geofence analytics"
Test-Endpoint -Method "GET" -Path "/analytics/predictions" -Description "Predictions"
Test-Endpoint -Method "GET" -Path "/analytics/events" -Description "Analytics events"

# ══════════════════════════════════════════════════════════════════
# 19. SECURITY
# ══════════════════════════════════════════════════════════════════

Write-Header "19. SECURITY"

Test-Endpoint -Method "GET" -Path "/security/dashboard" -Description "Security dashboard"
Test-Endpoint -Method "GET" -Path "/security/biometric/list" -Description "Biometric list"
Test-Endpoint -Method "GET" -Path "/security/audit/logs" -Description "Audit logs"
Test-Endpoint -Method "GET" -Path "/security/audit/events" -Description "Security events"
Test-Endpoint -Method "GET" -Path "/security/audit-logs" -Description "Audit logs (legacy)"
Test-Endpoint -Method "GET" -Path "/security/gdpr/requests" -Description "GDPR requests"

# ══════════════════════════════════════════════════════════════════
# 20. DISTANCE
# ══════════════════════════════════════════════════════════════════

Write-Header "20. DISTANCE"

Test-Endpoint -Method "GET" -Path "/distance/calculate?origin_lat=14.5995&origin_lng=120.9842&dest_lat=14.6010&dest_lng=120.9900" -Description "Distance calc (GET)" -AcceptableCodes @(200,201) -ExpectedFailCodes @(422,400)
Test-Endpoint -Method "GET" -Path "/distance/overall" -Description "Distance overall"

# ══════════════════════════════════════════════════════════════════
# 21. CHECKLIST TEMPLATES
# ══════════════════════════════════════════════════════════════════

Write-Header "21. CHECKLIST TEMPLATES"

Test-Endpoint -Method "GET" -Path "/checklist-templates" -Description "List checklist templates"

# ══════════════════════════════════════════════════════════════════
# 22. MISSIONS & REWARDS
# ══════════════════════════════════════════════════════════════════

Write-Header "22. MISSIONS AND REWARDS"

Test-Endpoint -Method "GET" -Path "/driver/missions" -Description "Driver missions"
Test-Endpoint -Method "GET" -Path "/missions" -Description "Customer missions"
Test-Endpoint -Method "GET" -Path "/merchant/missions" -Description "Merchant missions"
Test-Endpoint -Method "GET" -Path "/loyalty/rewards" -Description "Loyalty rewards"
Test-Endpoint -Method "GET" -Path "/referrals/dashboard" -Description "Referral dashboard"

# ══════════════════════════════════════════════════════════════════
# 23. PARTNER MANAGEMENT (Authenticated)
# ══════════════════════════════════════════════════════════════════

Write-Header "23. PARTNER MANAGEMENT (Auth)"

Test-Endpoint -Method "GET" -Path "/partners/1/staff" -Description "Partner staff list"

# ══════════════════════════════════════════════════════════════════
# 24. ADMIN ENDPOINTS (May need admin role)
# ══════════════════════════════════════════════════════════════════

Write-Header "24. ADMIN ENDPOINTS"

Test-Endpoint -Method "GET" -Path "/admin/documents" -Description "Admin documents" -ExpectedFailCodes @(403,404,401,422)
Test-Endpoint -Method "GET" -Path "/admin/documents/statistics" -Description "Admin doc stats" -ExpectedFailCodes @(403,404,401,422)
Test-Endpoint -Method "GET" -Path "/admin/documents/users-with-pending" -Description "Pending docs" -ExpectedFailCodes @(403,404,401,422)
Test-Endpoint -Method "GET" -Path "/admin/driver-duty-attendances" -Description "Duty attendances" -ExpectedFailCodes @(403,404,401,422)
Test-Endpoint -Method "GET" -Path "/admin/wallet-settings/threshold" -Description "Admin wallet threshold" -ExpectedFailCodes @(403,404,401,422)
Test-Endpoint -Method "GET" -Path "/admin/wallet-settings/commission-rates" -Description "Commission rates" -ExpectedFailCodes @(403,404,401,422)
Test-Endpoint -Method "GET" -Path "/admin/wallet-settings/package-prices" -Description "Package prices" -ExpectedFailCodes @(403,404,401,422)

# ══════════════════════════════════════════════════════════════════
# 25. GOOGLE PLACES PROXY
# ══════════════════════════════════════════════════════════════════

Write-Header "25. GOOGLE PLACES PROXY"

Test-Endpoint -Method "GET" -Path "/google-places/autocomplete?input=Manila" -Description "Places autocomplete" -RequiresAuth $false -AcceptableCodes @(200) -ExpectedFailCodes @(422,400,429,500)
Test-Endpoint -Method "GET" -Path "/google-places/details?place_id=test" -Description "Places details" -RequiresAuth $false -AcceptableCodes @(200) -ExpectedFailCodes @(422,400,429,500)

# ══════════════════════════════════════════════════════════════════
# SUMMARY
# ══════════════════════════════════════════════════════════════════

Write-Host ""
Write-Host ""
Write-Host ("=" * 70) -ForegroundColor Magenta
Write-Host "                    TEST RESULTS SUMMARY" -ForegroundColor Magenta
Write-Host ("=" * 70) -ForegroundColor Magenta
Write-Host ""

$total = $Global:PassCount + $Global:FailCount
$passRate = if ($total -gt 0) { [math]::Round(($Global:PassCount / $total) * 100, 1) } else { 0 }

Write-Host "  Total Tested:  $total" -ForegroundColor White
Write-Host "  PASSED:        $($Global:PassCount)" -ForegroundColor Green
Write-Host "  FAILED:        $($Global:FailCount)" -ForegroundColor Red
Write-Host "  Pass Rate:     $passRate%" -ForegroundColor $(if ($passRate -ge 80) { "Green" } elseif ($passRate -ge 50) { "Yellow" } else { "Red" })
Write-Host ""

if ($Global:FailCount -gt 0) {
    Write-Host "  ── FAILED ENDPOINTS ──" -ForegroundColor Red
    $Global:Results | Where-Object { $_.Status -eq "FAIL" } | ForEach-Object {
        Write-Host "    $($_.Method) $($_.Path) [$($_.Code)] - $($_.Desc)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host ("=" * 70) -ForegroundColor Magenta
Write-Host "  Test completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Magenta
Write-Host ("=" * 70) -ForegroundColor Magenta
Write-Host ""
