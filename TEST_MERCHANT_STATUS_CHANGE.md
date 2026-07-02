# 🧪 TEST: Merchant Order Status Change Fix

## ✅ Environment Status

### Currently Running:
- 🟢 **Backend API**: http://127.0.0.1:8000 (Terminal ID: 11)
- 🟢 **RIDERSIDE App**: emulator-5554 (Terminal ID: 9)

### Fix Applied:
- ✅ Backend fix committed: commit `3fecf7f`
- ✅ Branch: `feature/auth`
- ✅ Backend server restarted with fix

---

## 🎯 What Was Fixed

**Problem**: Merchants could not change order status to `ready_for_pickup`

**Fix**: Added permission in `OrderController.php` for `partner_admin` role to change status from `searching_driver` → `ready_for_pickup`

---

## 📝 Testing Steps

### Step 1: Login as Merchant
1. Open RIDERSIDE app on emulator
2. Login as merchant:
   - **Account**: Papa Clark Restos
   - **Partner ID**: 15
   - **Role**: partner_admin

### Step 2: Find or Create Test Order
Option A: Find existing pending order in Orders tab
Option B: Create new order via customer app (FRONTEND)

### Step 3: Test Accept Order ✅
1. Go to Orders tab
2. Find order in "Pending" status
3. Tap on order to open details
4. Click **"Accept Order"** button
5. **Expected**: 
   - ✅ Status changes to "For Pick Up" (searching_driver)
   - ✅ Prep timer starts
   - ✅ No error messages

### Step 4: Test Mark Ready (THE FIX!) 🎯
1. With order in "For Pick Up" status
2. Click **"Mark Ready for Pickup"** button
3. **Expected**: 
   - ✅ Status changes to "Ready" (ready_for_pickup)
   - ✅ Prep timer stops
   - ✅ No 403 error
   - ✅ Success message shown
4. **Before Fix**:
   - ❌ Would get 403 Forbidden error
   - ❌ Status would NOT change
   - ❌ Order stuck in "For Pick Up"

### Step 5: Test Cancel Order ✅
1. Create new pending order
2. Accept it
3. Click **"Cancel Order"** button
4. Select reason from dropdown
5. **Expected**:
   - ✅ Status changes to "Cancelled"
   - ✅ Prep timer stops
   - ✅ Cancellation reason saved

---

## 🔍 What to Watch For

### Console Logs (Good Signs):
```
✅ "Order status updated successfully"
✅ Status change logs showing ready_for_pickup
✅ No 403 or 422 errors
```

### Console Logs (Bad Signs - Should NOT appear):
```
❌ "Status change not allowed for your role"
❌ "403 Forbidden"
❌ "Failed to update order status"
```

### UI Behavior:
- ✅ Status badge color changes correctly
- ✅ Action buttons update based on new status
- ✅ Prep timer badge shows/hides correctly
- ✅ Order details refresh automatically

---

## 📊 Status Flow Chart

```
[Pending]
   ↓ (Merchant clicks "Accept Order")
[For Pick Up] (searching_driver)
   ↓ (Merchant clicks "Mark Ready") ← THIS IS WHAT WAS BROKEN!
[Ready] (ready_for_pickup)
   ↓ (Driver picks up)
[For Delivery] (picked_up)
   ↓ (Driver delivers)
[Delivered] (completed)
```

### Merchant Actions by Status:
```
Pending:          [Accept] [Reject]
For Pick Up:      [Mark Ready] [Cancel]  ← Mark Ready NOW WORKS!
Ready:            [Cancel]
For Delivery:     (No merchant actions - rider has order)
Delivered:        (Read-only)
Cancelled:        (Read-only)
```

---

## 🐛 Known Issues (Already Fixed)

### Issue 1: Duplicate Dialog Error ✅ FIXED
- **Problem**: Multiple dialogs opening on rapid clicks
- **Fix**: Added `_activeDialogs` Set guard
- **Status**: ✅ Working

### Issue 2: Rejection Dialog TextEditingController ✅ FIXED
- **Problem**: Controller disposal timing issue
- **Fix**: Changed to dropdown menu with StatefulWidget
- **Status**: ✅ Working

### Issue 3: Invite Staff Dialog ✅ FIXED
- **Problem**: Controller disposal timing issue
- **Fix**: Created `_InviteStaffDialogContent` StatefulWidget
- **Status**: ✅ Working

### Issue 4: Bluetooth Printer Crash ✅ FIXED
- **Problem**: Multiple simultaneous Bluetooth enable requests
- **Fix**: Added `_isEnabling` guard
- **Status**: ✅ Working

### Issue 5: Status Change Blocked ✅ FIXED (THIS ONE!)
- **Problem**: Cannot mark orders ready_for_pickup
- **Fix**: Added backend permission for partner_admin
- **Status**: ✅ Fixed, needs testing

---

## 📞 If Testing Fails

### If "Mark Ready" Still Doesn't Work:

1. **Check Backend Running**:
   ```bash
   curl http://127.0.0.1:8000/api/v1/health
   ```
   Should return 200 OK

2. **Check Console Logs**:
   - Look for API errors
   - Check status code (should be 200, not 403)

3. **Verify Backend Fix Applied**:
   ```bash
   cd BACKEND/lesgo-api
   git log -1
   ```
   Should show commit `3fecf7f`

4. **Check API Connection**:
   - In RIDERSIDE app, check `api_constants.dart`
   - Verify baseUrl matches `http://127.0.0.1:8000` or correct IP

5. **Database Check**:
   - Verify order exists with correct status
   - Verify merchant has correct partner_id

### Common Issues:

**Issue**: "Failed to update order status"
**Solution**: Check backend logs, verify database connection

**Issue**: 403 Forbidden still appearing
**Solution**: Backend might not have restarted, restart Terminal ID: 11

**Issue**: Order not found
**Solution**: Create new test order via customer app

---

## ✅ Success Criteria

### Test is SUCCESSFUL if:
1. ✅ Can accept pending order → searching_driver
2. ✅ Can mark order ready → ready_for_pickup (NO 403 ERROR!)
3. ✅ Can cancel orders in proper statuses
4. ✅ UI updates correctly after each status change
5. ✅ No crashes or errors in console

### Test FAILS if:
1. ❌ Get 403 error when marking ready
2. ❌ Status doesn't change in UI
3. ❌ Backend returns error message
4. ❌ App crashes on status change

---

## 📸 Screenshots to Capture

If testing for documentation:
1. Pending order with Accept/Reject buttons
2. For Pick Up order with Mark Ready button
3. After clicking Mark Ready → status changed to Ready
4. Console logs showing successful status update
5. No error messages

---

## 🎓 Technical Details

### Backend Permission Logic:
```php
// OrderController.php - isStatusChangeAllowed()
if ($user->isPartnerAdmin()) {
    return match ($new) {
        'searching_driver'   => $current === 'pending',
        'ready_for_pickup'   => in_array($current, ['searching_driver', 'accepted'], true), // ← THIS WAS ADDED
        'cancelled'          => in_array($current, ['pending', 'searching_driver', 'ready_for_pickup'], true),
        default              => false,
    };
}
```

### API Endpoint:
```
PATCH /api/v1/orders/{orderId}/status
Headers: Authorization: Bearer {token}
Body: {"status": "ready_for_pickup"}
```

### Frontend Call:
```dart
await dataSource.updateOrderStatus(orderId, 'ready_for_pickup');
```

---

## 📝 Test Report Template

```
Date: _______________
Tester: ______________
Device: Android Emulator (emulator-5554)

Test Results:
[ ] Accept Order: PASS / FAIL
[ ] Mark Ready: PASS / FAIL  ← CRITICAL TEST
[ ] Cancel Order: PASS / FAIL

Issues Found:
_________________________________

Console Errors:
_________________________________

Screenshots: (attach)
```

---

**Testing Guide Created**: June 28, 2026  
**Fix Version**: commit 3fecf7f  
**Status**: ✅ Ready to test  
**Priority**: 🔴 Critical - Test immediately

