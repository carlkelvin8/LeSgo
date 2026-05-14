# Rider Not Receiving Orders - Debug Guide

## Issue
Rider app shows "No available bookings" even though there are pending orders in the database.

## Root Cause Analysis

### ✅ Backend is Working
Tested `GET /v1/orders` as driver — returns **15 pending orders** with `driver_id: null`:
- Order #35, #32, #22, #21, #20, #19, #18, #17, #16, #14, #8, #7, #6, #5, #4

### ✅ Frontend Code is Correct
- `RiderOrdersNotifier` fetches orders via `ApiService.getOrders(perPage: 50)`
- Filters available orders: `status == 'pending' || status == 'searching_driver'` AND `driverId == null`
- Auto-refreshes every 10 seconds via `Timer.periodic`

## Possible Causes

### 1. **Rider Not Logged In** (Most Likely)
- Check if rider app has valid auth token
- Verify `Authorization: Bearer <token>` header is being sent
- Check console logs for "🔒 Interceptor: Token available: false"

**Fix:** Login with valid driver credentials:
```
Email: driver@lesgo.test
Password: password
```

### 2. **Auto-Refresh Not Running**
- Timer may have been cancelled
- App may be in background/paused state

**Fix:** Pull-to-refresh manually or restart the app

### 3. **API Interceptor Issue**
- Token may be expired (401 response)
- Device ID header missing

**Fix:** Check console logs for 401 errors, re-login if needed

### 4. **Duty Status is OFF**
- `riderDutyProvider` is set to `false`
- UI shows "You are currently OFF DUTY"

**Fix:** Toggle duty status to ON in the app

## Debugging Steps

### Step 1: Check Console Logs
Look for these log messages:
```
🔄 Fetching orders from API...
📦 Received X orders from API
✅ Available orders: X
```

If you see:
- `📦 Received 0 orders` → Auth issue (not logged in or token expired)
- `✅ Available orders: 0` → Filtering issue (all orders have drivers assigned)

### Step 2: Verify Login
Check for:
```
🔐 getToken: Token found
🔒 Interceptor: Token available: true
🔒 Interceptor: Authorization header set
```

If missing → **Re-login required**

### Step 3: Check Duty Status
- Open Bookings tab
- Verify "ON DUTY" toggle is enabled
- If OFF DUTY, no orders will be shown

### Step 4: Manual Refresh
- Pull down on the bookings list to trigger refresh
- Check if orders appear after refresh

### Step 5: Check Network Response
Enable network logging and verify:
- Request: `GET /v1/orders?per_page=50`
- Response: `{"data": [...]}`  with pending orders
- Status: 200 OK

## Quick Fix Checklist

- [ ] Rider is logged in with driver account
- [ ] Duty status is ON
- [ ] Pull-to-refresh to force reload
- [ ] Check console for errors
- [ ] Verify backend has pending orders (use API test above)
- [ ] Restart app if auto-refresh stopped

## Test Accounts

**Driver Account:**
```
Email: driver@lesgo.test
Password: password
```

**Customer Account (to create orders):**
```
Email: test@example.com
Password: password
```

## Expected Behavior

When working correctly:
1. Rider logs in → Token saved
2. Bookings screen loads → Calls `GET /v1/orders`
3. Backend returns pending orders
4. App filters and displays available orders
5. Auto-refresh every 10 seconds keeps list updated
6. New orders appear automatically

## Current Status

- ✅ Backend: 15 pending orders available
- ✅ API endpoint: Working correctly
- ✅ Frontend code: Correct logic
- ❓ Rider app: Need to verify login status and duty toggle

**Next Step:** Check if rider app is logged in and duty status is ON.
