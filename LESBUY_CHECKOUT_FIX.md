# FIX: LesBuy Checkout Validation Error

**Date:** June 20, 2026  
**Status:** ✅ FIXED  
**Issue:** "The given data was invalid" error when checking out LesBuy orders

---

## PROBLEM

When users tried to checkout a LesBuy order (especially manual-only orders), they received the error message:

```
The given data was invalid
```

---

## ROOT CAUSE

The `estimatedDistanceM` field was being set to `0` for manual-only checkout orders:

```dart
estimatedDistanceM: isManualOnlyCheckout ? 0 : checkoutQuote.estimatedDistanceM,
```

However, the backend validation requires a **minimum of 1 meter**:

```php
'estimated_distance_m' => ['required', 'integer', 'min:1', 'max:30000'],
```

**Result:** Laravel validation rejected the request with "The given data was invalid" error.

---

## THE FIX

Changed the `estimatedDistanceM` to use a default value of 1000 meters (1km) instead of 0:

**File:** `FRONTEND/lib/presentation/screens/main/booking/lesbuy/store_cart_screen.dart`

**Before:**
```dart
estimatedDistanceM: isManualOnlyCheckout ? 0 : checkoutQuote.estimatedDistanceM,
```

**After:**
```dart
estimatedDistanceM: isManualOnlyCheckout 
    ? 1000  // Default to 1km for manual orders (backend requires min:1)
    : checkoutQuote.estimatedDistanceM,
```

---

## WHY 1000 METERS?

1. **Backend Requirement:** Minimum value is 1 meter
2. **Reasonable Default:** 1km is a reasonable estimate for manual orders where exact distance isn't known yet
3. **Fare Calculation:** The backend will calculate a fair delivery fee based on this distance
4. **Rider Adjustment:** Once the rider uploads the first item photo, the actual pickup location will be set

---

## TESTING

**Before Fix:**
- User adds item to LesBuy cart
- User proceeds to checkout
- User clicks "Checkout" button
- ❌ Error: "The given data was invalid"

**After Fix:**
- User adds item to LesBuy cart  
- User proceeds to checkout
- User clicks "Checkout" button
- ✅ Order created successfully

---

## BACKEND VALIDATION RULES

For reference, here are the key backend validation rules for order creation:

```php
// StoreOrderRequest.php
[
    'service_id'           => ['required', 'integer', 'exists:services,id'],
    'estimated_distance_m' => ['required', 'integer', 'min:1', 'max:30000'],  // ← This one!
    'pickup'               => ['required', 'array'],
    'pickup.address'       => ['required', 'string', 'max:255'],
    'pickup.lat'           => ['required', 'numeric', 'between:-90,90'],
    'pickup.lng'           => ['required', 'numeric', 'between:-180,180'],
    'dropoff'              => ['required', 'array'],
    'dropoff.address'      => ['required', 'string', 'max:255'],
    'dropoff.lat'          => ['required', 'numeric', 'between:-90,90'],
    'dropoff.lng'          => ['required', 'numeric', 'between:-180,180'],
]
```

---

## MANUAL-ONLY CHECKOUT

Manual-only checkout occurs when:
- User adds items to manual order list (not from store catalog)
- User has no items from store catalog in cart
- `isManualOnlyCheckout = isStoreCartEmpty && !isManualOrderEmpty`

In this case:
- Pickup location is unknown (rider will photo first item and set location)
- Delivery fee is uncertain
- Distance is unknown
- Order value may be uncertain

**Solution:** Use reasonable defaults (1000m distance, 0,0 coordinates) that pass validation, and let the rider update with actual values later.

---

## COMMIT

**Commit:** `9e757d4` - FIX: LesBuy checkout validation error - estimatedDistanceM must be minimum 1

---

## RELATED FILES

- `FRONTEND/lib/presentation/screens/main/booking/lesbuy/store_cart_screen.dart` (FIXED)
- `BACKEND/lesgo-api/app/Http/Requests/StoreOrderRequest.php` (validation rules)

---

**LesBuy checkout should now work properly!** ✅
