# Next Steps - Action Plan

## ✅ What We Just Fixed

1. **Price Parsing** - Now logs errors instead of silent failures
2. **Chat Endpoints** - Type-safe functions prevent URL bugs  
3. **Tracking Errors** - Proper error propagation instead of null returns

## 🎯 What to Do Next

### IMMEDIATE (Today/Tomorrow)

#### 1. Test the Fixes
```bash
# Run the app and test:
□ Open chat for any order
□ Send a message
□ Check if messages load
□ Monitor debug console for ⚠️ warnings

# Check tracking:
□ Track an order
□ Verify driver location shows
□ Test with no driver assigned
```

#### 2. Verify No Regressions
```bash
□ Order creation still works
□ Payment processing unchanged
□ Location tracking functional
□ No crashes from type changes
```

---

### HIGH PRIORITY (This Week)

#### 3. Fix Wallet Race Condition
**File to Edit:** `FRONTEND/lib/presentation/provider/main/booking/checkout_provider.dart`

**Current Problem:** Lines 408-433
```dart
// ❌ Bad: Checks balance, then refreshes separately
final wallet = await getMyWallet();
ref.read(lespayProvider.notifier).refreshBalance();
if (wallet.balance < order.total) { ... }
```

**What to Do:**
1. **Option A (Quick Fix):** Remove the separate refresh call
   ```dart
   // Just use the fetched wallet balance
   final wallet = await getMyWallet();
   if (wallet.balance < order.total) { ... }
   ```

2. **Option B (Proper Fix):** Add backend validation endpoint
   ```dart
   // New endpoint: GET /v1/wallets/my/validate?amount=100.00
   // Returns: { "sufficient": true, "balance": 250.00 }
   final validation = await validateBalance(order.total);
   if (!validation.sufficient) { ... }
   ```

**Choose Option A for now**, Option B requires backend changes.

---

#### 4. Fix Distance Calculation
**File to Edit:** `FRONTEND/lib/presentation/provider/main/booking/checkout_provider.dart`

**Current Problem:** Line 143-156
```dart
// ❌ Bad: Clamps to 500m-25km
.clamp(500, 25000)
```

**What to Do:**
```dart
// Remove the clamp - let actual distance be used
final distanceM = BookingGeoUtils.distanceMeters(
  lat1: state.pickupLat,
  lng1: state.pickupLng,
  lat2: state.dropoffLat,
  lng2: state.dropoffLng,
); // No .clamp()

// Or better: Use route distance from Google Maps
// This requires calling Directions API
```

**Impact:** Accurate pricing for all distances

---

#### 5. Fix Fare Estimation Error Handling
**File to Edit:** `FRONTEND/lib/presentation/provider/main/booking/checkout_provider.dart`

**Current Problem:** Line 157-171
```dart
// ❌ Bad: Catches all, defaults to ₱50
catch (_) {
  final updatedOrder = state.order!.copyWith(deliveryFee: 50.00);
}
```

**What to Do:**
```dart
try {
  final deliveryFee = await _orderDataSource.getFareEstimateRaw(...);
  // Success path
} on DioException catch (e) {
  if (e.type == DioExceptionType.connectionTimeout) {
    state = state.copyWith(
      error: 'Network timeout. Please try again.',
      isLoadingFare: false,
    );
  } else if (e.response?.statusCode == 401) {
    // Token expired - refresh and retry
    await ref.read(authProvider.notifier).refreshToken();
    return refreshDeliveryFee(); // Retry
  } else {
    state = state.copyWith(
      error: 'Unable to calculate delivery fee',
      isLoadingFare: false,
    );
  }
} catch (e) {
  state = state.copyWith(
    error: 'Unexpected error',
    isLoadingFare: false,
  );
}
```

**Impact:** Users see real errors instead of wrong prices

---

### MEDIUM PRIORITY (Next Week)

#### 6. Add Exponential Backoff to WebSocket Polling
**File to Edit:** `FRONTEND/lib/presentation/provider/chat/chat_provider.dart`

See `CODE_FIXES_EXAMPLES.md` for full implementation.

**Impact:** Reduces server load, better battery life

---

#### 7. Fix Driver Profile Field Inconsistency
**Backend File:** Create migration
**Frontend File:** `FRONTEND/lib/data/data_source/dto/order/order_dto.dart`

**Backend Migration:**
```php
// Consolidate vehicle_plate into plate_number
DB::statement('UPDATE driver_profiles SET plate_number = vehicle_plate WHERE plate_number IS NULL');
$table->dropColumn('vehicle_plate');
```

**Frontend Getter:**
```dart
String? get effectivePlateNumber => plateNumber ?? vehiclePlate;
```

---

#### 8. Add Logging Service
**New File:** `FRONTEND/lib/core/utils/app_logger.dart`

Copy from `CODE_FIXES_EXAMPLES.md` - includes Firebase Crashlytics integration.

**Impact:** Better production error tracking

---

### ONGOING (Continuous)

#### 9. Monitor Logs During Testing
Look for these in debug console:
```
⚠️ OrderDto: Null value for numeric field: total_amount
⚠️ OrderDto: Failed to parse discount_amount: "invalid"
⚠️ Mark as read failed for conversation 123: DioException...
```

If you see these, investigate backend response format.

---

#### 10. Add Integration Tests
**New Folder:** `integration_test/`

Start with:
- `order_creation_test.dart`
- `chat_messaging_test.dart`
- `tracking_flow_test.dart`

---

## 📋 Quick Checklist

### Before Committing:
- [ ] Run `flutter analyze` (should pass)
- [ ] Run existing tests (if any)
- [ ] Test chat functionality manually
- [ ] Test order creation manually
- [ ] Check debug console for warnings

### Before Deploying:
- [ ] Test on real device (not just emulator)
- [ ] Test with production API
- [ ] Verify no regressions in payment flow
- [ ] Test location tracking end-to-end
- [ ] Check backend logs for unusual errors

---

## 🔥 If Something Breaks

### Chat Not Working:
1. Check backend API route exists: `/v1/chat/conversations/order/{order_id}`
2. Check network logs - does URL look correct?
3. Verify auth token is included in headers

### Parse Errors Appearing:
1. Note the field name in the warning
2. Check backend response for that order
3. May need to update DTO or fix backend data

### Tracking Shows No Data:
1. Check if error is being thrown (good - we fixed this!)
2. UI should show appropriate error message
3. If it says "network error", that's working correctly

---

## 📚 Reference Files

All in the workspace root:

1. **BUG_ANALYSIS_REPORT.md** - Full analysis (200+ lines)
2. **CRITICAL_FIXES_CHECKLIST.md** - Quick reference
3. **CODE_FIXES_EXAMPLES.md** - Copy-paste code
4. **FIXES_APPLIED.md** - What we just did
5. **NEXT_STEPS.md** - This file

---

## 💬 Questions?

### Common Questions:

**Q: Do I need to regenerate code after DTO changes?**
A: Yes, if you modify fields. Run: `flutter pub run build_runner build`

**Q: Will these changes break existing code?**
A: No - all changes are backward compatible.

**Q: When should I do the remaining fixes?**
A: Wallet fix (Priority 3) and Distance fix (Priority 4) are most critical for revenue protection.

**Q: Can I deploy with just these 4 fixes?**
A: Yes - these are safe improvements that don't break anything.

---

## 🎯 Success Metrics

After all fixes deployed, track:
- [ ] Chat message success rate > 99%
- [ ] Order creation success rate > 95%  
- [ ] Parse error count = 0 (in logs)
- [ ] User complaints about pricing ↓
- [ ] "Chat not working" tickets ↓

---

## ⏱️ Time Estimates

- Testing current fixes: **2 hours**
- Wallet fix (#3): **2 hours**
- Distance fix (#4): **1 hour**
- Fare error handling (#5): **2 hours**
- WebSocket backoff (#6): **3 hours**
- Logging service (#8): **2 hours**
- Integration tests (#10): **8 hours**

**Total for high priority: ~8 hours (1 day)**
**Total including medium: ~18 hours (2-3 days)**

---

Last Updated: June 23, 2026

**Start Here:** Test the 4 fixes we just applied ☝️
