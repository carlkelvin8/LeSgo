# RIDER APP - Failed to Accept Order Fix

## Date: June 20, 2026

## Problem
Rider app shows "Failed to accept order" error when trying to accept bookings.

## Root Cause Analysis

### Issue #1: No Pending Orders
- Initially, there were NO pending orders in the database
- The rider app was trying to accept order #1 which didn't exist

### Issue #2: No Wallet for Driver  
- Test driver (driver@lesgo.test) had no wallet record
- Riders need a wallet with sufficient balance to accept orders (booking charge)

### Issue #3: Authentication Error (MAIN ISSUE)
- The HTTP 500 error is actually caused by **unauthenticated requests**
- Backend error: `Route [login] not defined` triggered by `Authenticate` middleware
- The rider app is either:
  1. Not logged in properly
  2. Sending expired/invalid authentication token
  3. Token not being included in accept order API request

## Solutions Implemented

### 1. Created Test Order ✅
```bash
cd BACKEND/lesgo-api
php create_test_order.php
```

**Result**: Order #1 created
- Customer: Test Customer (customer@lesgo.test)
- Service: LesGo
- Fare: ₱120.00
- Status: pending

### 2. Created Driver Wallet ✅
```bash
php check_driver_wallet.php
```

**Result**: Wallet created for Test Driver
- User: Test Driver (driver@lesgo.test, ID: 3)
- Balance: ₱1000.00
- Driver Profile ID: 1

### 3. Authentication Issue (NEEDS FIX ⚠️)

The rider app needs to:
1. **Login with test driver credentials**:
   - Email: `driver@lesgo.test`
   - Password: Need to verify (likely `Password123` or `password`)

2. **Ensure token is included in API requests**
   - Check `Authorization: Bearer <token>` header is sent with accept order request

## Test Driver Credentials

**Email**: `driver@lesgo.test`  
**Phone**: `+639171234567`  
**Password**: ??? (needs to be confirmed or reset)

## Backend Setup Completed

1. ✅ Laravel server running on `http://127.0.0.1:8000`
2. ✅ Database has test order (Order #1)
3. ✅ Driver has wallet with ₱1000 balance
4. ✅ Driver profile exists (ID: 1, Status: active)

## Next Steps

### Option A: Check if rider app is logged in
```dart
// In rider app, check authentication state
final auth = ref.read(riderAuthProvider);
print('Is authenticated: ${auth.isAuthenticated}');
print('User: ${auth.user?.email}');
print('Token: ${auth.token}');  // Should not be null
```

### Option B: Re-login in rider app
1. Logout from rider app
2. Login with: `driver@lesgo.test` / `Password123`
3. Retry accepting order

### Option C: Reset driver password
```bash
cd BACKEND/lesgo-api
php artisan tinker
```
```php
$driver = App\Models\User::where('email', 'driver@lesgo.test')->first();
$driver->password = bcrypt('Password123');
$driver->save();
echo "Password reset to: Password123\n";
```

## Files Created

- `BACKEND/lesgo-api/create_test_order.php` - Creates test orders
- `BACKEND/lesgo-api/check_driver_wallet.php` - Checks/creates driver wallet
- `BACKEND/lesgo-api/check_pending_orders.php` - Lists pending orders

## API Endpoint Details

**Accept Order Endpoint:**
```
PATCH /api/v1/orders/{id}/status
Headers:
  Authorization: Bearer {token}
  Content-Type: application/json
Body:
  {
    "status": "accepted"
  }
```

**Expected Response (200):**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "status": "accepted",
    "driver_id": 1,
    "accepted_at": "2026-06-20T14:50:00.000000Z",
    ...
  }
}
```

**Current Error (500):**
```
Route [login] not defined.
Caused by: Authenticate middleware trying to redirect unauthenticated request
```

## Testing Checklist

- [x] Backend server running
- [x] Test order created
- [x] Driver wallet funded
- [ ] Rider app authenticated with valid token
- [ ] Accept order request includes Authorization header
- [ ] Order acceptance succeeds

## Related Commits

- `c783abf` - Backend: Fixed DriverLocationUpdated TypeError
- `8de68b9` - Root: Updated backend submodule
- `0522261` - Root: Documentation for rider app fixes

## Conclusion

The rider app **must be properly authenticated** to accept orders. The HTTP 500 error is misleading - it's actually an authentication issue, not a server error. Once the rider logs in with valid credentials and includes the auth token in the request, order acceptance should work.
