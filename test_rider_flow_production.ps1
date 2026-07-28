# ═══════════════════════════════════════════════════════════════════════════════
# LESGO RIDER FLOW - PRODUCTION API INTEGRATION TEST
# Tests the full rider lifecycle against the live API
# ═══════════════════════════════════════════════════════════════════════════════

$BASE_URL = "https://lesgo-api-feature-auth-fhlrsy.laravel.cloud/api/v1"
$PASS = 0
$FAIL = 0
$RESULTS = @()

function Test-Endpoint {
    param(
        [string]$Name,
        [string]$Method,
        [string]$Url,
        [hashtable]$Headers = @{},
        [string]$Body = "",
        [int]$ExpectedStatus = 200,
        [string]$ExpectJsonPath = "",
        [string]$ExpectJsonValue = ""
    )

    try {
        $params = @{
            Method = $Method
            Uri = $Url
            Headers = $Headers
            ContentType = "application/json"
            ErrorAction = "Stop"
        }
        if ($Body -and $Method -ne "GET") {
            $params.Body = $Body
        }

        $response = Invoke-WebRequest @params
        $status = $response.StatusCode
        $json = $response.Content | ConvertFrom-Json

        if ($status -eq $ExpectedStatus) {
            if ($ExpectJsonPath -and $ExpectJsonValue) {
                $actual = Invoke-Expression "`$json.$ExpectJsonPath"
                if ("$actual" -eq "$ExpectJsonValue") {
                    Write-Host "  [PASS] $Name (status=$status)" -ForegroundColor Green
                    $script:PASS++
                    return $json
                } else {
                    Write-Host "  [FAIL] $Name - Expected $ExpectJsonPath='$ExpectJsonValue', got '$actual'" -ForegroundColor Red
                    $script:FAIL++
                    return $json
                }
            }
            Write-Host "  [PASS] $Name (status=$status)" -ForegroundColor Green
            $script:PASS++
            return $json
        } else {
            Write-Host "  [FAIL] $Name - Expected status $ExpectedStatus, got $status" -ForegroundColor Red
            $script:FAIL++
            return $json
        }
    } catch {
        $errStatus = 0
        if ($_.Exception.Response) {
            $errStatus = [int]$_.Exception.Response.StatusCode
        }
        if ($ExpectedStatus -eq $errStatus) {
            Write-Host "  [PASS] $Name (expected error status=$errStatus)" -ForegroundColor Green
            $script:PASS++
            return $null
        }
        Write-Host "  [FAIL] $Name - Error: $($_.Exception.Message) (status=$errStatus)" -ForegroundColor Red
        $script:FAIL++
        return $null
    }
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  LESGO RIDER FLOW - PRODUCTION API TEST" -ForegroundColor Cyan
Write-Host "  API: $BASE_URL" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# ── 1. HEALTH CHECK ──────────────────────────────────────────────────────────
Write-Host "[1/10] Health Check" -ForegroundColor Yellow
Test-Endpoint -Name "API responds" -Method GET -Url "$BASE_URL/../up" -ExpectedStatus 200

# ── 2. RIDER REGISTRATION ────────────────────────────────────────────────────
Write-Host ""
Write-Host "[2/10] Rider Registration" -ForegroundColor Yellow
$timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
$riderEmail = "testrider_${timestamp}@automation.test"
$riderPassword = "TestPass123!"
$riderPhone = "+6391700${timestamp}".Substring(0, 13)

$registerBody = @{
    name = "Auto Test Rider"
    email = $riderEmail
    password = $riderPassword
    password_confirmation = $riderPassword
    phone_number = $riderPhone
    license_number = "N01-AUTO-$timestamp"
} | ConvertTo-Json

$regResult = Test-Endpoint -Name "Register rider" -Method POST -Url "$BASE_URL/drivers/register" -Body $registerBody -ExpectedStatus 201

$riderToken = ""
if ($regResult -and $regResult.token) {
    $riderToken = $regResult.token
    Write-Host "    Token obtained: $($riderToken.Substring(0,20))..." -ForegroundColor DarkGray
}

# ── 3. RIDER LOGIN ───────────────────────────────────────────────────────────
Write-Host ""
Write-Host "[3/10] Rider Login" -ForegroundColor Yellow
$loginBody = @{ email = $riderEmail; password = $riderPassword } | ConvertTo-Json
$loginResult = Test-Endpoint -Name "Login rider" -Method POST -Url "$BASE_URL/auth/login" -Body $loginBody -ExpectedStatus 200

if ($loginResult -and $loginResult.token) {
    $riderToken = $loginResult.token
}

$authHeaders = @{ Authorization = "Bearer $riderToken" }

# ── 4. GET PROFILE (ME) ─────────────────────────────────────────────────────
Write-Host ""
Write-Host "[4/10] Get Profile" -ForegroundColor Yellow
$meResult = Test-Endpoint -Name "Get /auth/me" -Method GET -Url "$BASE_URL/auth/me" -Headers $authHeaders -ExpectedStatus 200

$driverProfileId = $null
if ($meResult) {
    $userData = if ($meResult.data) { $meResult.data } elseif ($meResult.user) { $meResult.user } else { $meResult }
    $dp = $userData.driver_profile
    if ($dp) {
        $driverProfileId = $dp.id
        Write-Host "    Driver profile ID: $driverProfileId, Status: $($dp.status)" -ForegroundColor DarkGray
    }
}

# ── 5. UPDATE AVAILABILITY ───────────────────────────────────────────────────
Write-Host ""
Write-Host "[5/10] Update Availability (Go Online)" -ForegroundColor Yellow
if ($driverProfileId) {
    $availBody = @{ is_available = $true } | ConvertTo-Json
    Test-Endpoint -Name "Set available" -Method PATCH -Url "$BASE_URL/drivers/$driverProfileId" -Headers $authHeaders -Body $availBody -ExpectedStatus 200
} else {
    Write-Host "  [SKIP] No driver profile ID" -ForegroundColor DarkYellow
}

# ── 6. LOAD ORDERS ───────────────────────────────────────────────────────────
Write-Host ""
Write-Host "[6/10] Load Orders" -ForegroundColor Yellow
$ordersResult = Test-Endpoint -Name "GET /orders" -Method GET -Url "$BASE_URL/orders?per_page=10" -Headers $authHeaders -ExpectedStatus 200

$orderCount = 0
if ($ordersResult -and $ordersResult.data) {
    if ($ordersResult.data -is [array]) {
        $orderCount = $ordersResult.data.Count
    } elseif ($ordersResult.data.data -is [array]) {
        $orderCount = $ordersResult.data.data.Count
    }
}
Write-Host "    Orders visible: $orderCount" -ForegroundColor DarkGray

# ── 7. FARE ESTIMATE ─────────────────────────────────────────────────────────
Write-Host ""
Write-Host "[7/10] Fare Estimate" -ForegroundColor Yellow
$estimateBody = @{
    service_id = 1
    pickup = @{ lat = 8.4542; lng = 124.6319 }
    dropoff = @{ lat = 8.4700; lng = 124.6500 }
    estimated_distance_m = 5000
} | ConvertTo-Json -Depth 3

$estimateResult = Test-Endpoint -Name "POST /orders/estimate" -Method POST -Url "$BASE_URL/orders/estimate" -Headers $authHeaders -Body $estimateBody -ExpectedStatus 200

if ($estimateResult -and $estimateResult.data) {
    Write-Host "    Estimated fare: PHP $($estimateResult.data.estimated_fare)" -ForegroundColor DarkGray
    Write-Host "    Base fare: PHP $($estimateResult.data.fare_breakdown.base_fare)" -ForegroundColor DarkGray
}

# ── 8. WALLET CHECK ──────────────────────────────────────────────────────────
Write-Host ""
Write-Host "[8/10] Wallet" -ForegroundColor Yellow
$walletResult = Test-Endpoint -Name "GET /wallets/my/wallet" -Method GET -Url "$BASE_URL/wallets/my/wallet" -Headers $authHeaders -ExpectedStatus 200

if ($walletResult -and $walletResult.data) {
    $balance = if ($walletResult.data.balance) { $walletResult.data.balance } else { 0 }
    Write-Host "    Balance: PHP $balance" -ForegroundColor DarkGray
}

# ── 9. UNAUTHORIZED ACCESS TESTS ─────────────────────────────────────────────
Write-Host ""
Write-Host "[9/10] Authorization Guards" -ForegroundColor Yellow
Test-Endpoint -Name "Orders without auth = 401" -Method GET -Url "$BASE_URL/orders" -ExpectedStatus 401
Test-Endpoint -Name "Profile without auth = 401" -Method GET -Url "$BASE_URL/auth/me" -ExpectedStatus 401

# ── 10. UPDATE LOCATION ──────────────────────────────────────────────────────
Write-Host ""
Write-Host "[10/10] Location Update" -ForegroundColor Yellow
if ($driverProfileId) {
    $locBody = @{ last_latitude = 8.4550; last_longitude = 124.6330 } | ConvertTo-Json
    Test-Endpoint -Name "PATCH /drivers/$driverProfileId/location" -Method PATCH -Url "$BASE_URL/drivers/$driverProfileId/location" -Headers $authHeaders -Body $locBody -ExpectedStatus 200
} else {
    Write-Host "  [SKIP] No driver profile ID" -ForegroundColor DarkYellow
}

# ── SUMMARY ──────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  RESULTS: $PASS PASSED, $FAIL FAILED" -ForegroundColor $(if ($FAIL -eq 0) { "Green" } else { "Red" })
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
