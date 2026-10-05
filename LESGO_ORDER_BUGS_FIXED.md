# LesGo Order Bugs - Analysis & Fixes

## Date: June 28, 2026

## 🐛 Bugs Identified

### 1. 🔴 CRITICAL: Conditional Destination Check Logic Bug
**File:** `lesgo_provider.dart` Line 599-652
**Issue:** Overly complex conditional logic with test workarounds that can create orders without proper destination

```dart
// ❌ BUGGY CODE:
if (locationState.destinationLocation == null && state.selectedDropoffAddress == null) {
  // Creates default destination for testing - PRODUCTION BUG!
  if (locationState.pickupLocation != null) {
    print('🔧 LesGo: Creating default destination for testing');
    final pickup = locationState.pickupLocation!;
    final defaultDestination = LatLng(
      pickup.latitude + 0.01,
      pickup.longitude + 0.01,
    );
    await _ref.read(lesgoLocationProvider.notifier).updateDestination(defaultDestination);
    SnackBarUtils.showInfo(context, 'Using default destination for testing...');
  }
}
```

**Problems:**
1. Test code in production creates fake destinations
2. Allows booking without user-selected destination
3. Creates orders 1km away from actual destination
4. Customer confusion: "Why is driver going wrong way?"

**Impact:** Orders created with wrong destinations, customer complaints

---

### 2. 🔴 CRITICAL: Multiple Location Update Paths
**File:** `lesgo_provider.dart` Lines 640-667
**Issue:** Three different ways to set locations causing race conditions

```dart
// Path 1: Selected address but no location
if (locationState.destinationLocation == null && state.selectedDropoffAddress != null) {
  await _ref.read(lesgoLocationProvider.notifier).updateDestinationWithAddress(...);
}

// Path 2: Selected address but no pickup location  
if (locationState.pickupLocation == null && state.selectedPickupAddress != null) {
  await _ref.read(lesgoLocationProvider.notifier).updatePickupWithAddress(...);
}

// Path 3: Re-read state after updates
final updatedLocationState = _ref.read(lesgoLocationProvider);
```

**Problems:**
1. Race condition between address selection and location updates
2. State can be stale after async updates
3. No guarantee both locations are synced before order creation
4. Multiple `_ref.read()` calls can miss updates

**Impact:** Orders created with mismatched addresses/coordinates

---

### 3. 🟡 MEDIUM: Distance Calculation Not Using Route Distance
**File:** `lesgo_provider.dart` Line 710
**Issue:** Uses manual distance or fallback instead of actual route

```dart
final estimatedDistanceM = (updatedLocationState.distanceInKm != null)
    ? (updatedLocationState.distanceInKm! * 1000).round()
    : 5000; // ❌ Fallback to 5km
```

**Problems:**
1. If route fetch fails, uses 5km default
2. Doesn't match actual driving distance
3. Undercharges or overcharges customer
4. Backend calculates different fare

**Impact:** Fare mismatches, revenue loss

---

### 4. 🟡 MEDIUM: Contact Information Fallback Issues
**File:** `lesgo_provider.dart` Lines 718-752
**Issue:** Complex nested ternary operators for contact info

```dart
contactName: state.selectedPickupAddress?.contactName?.isNotEmpty == true
    ? state.selectedPickupAddress!.contactName!
    : (user?.name ?? 'Customer'),
contactPhone: state.selectedPickupAddress?.contactPhone?.isNotEmpty == true
    ? state.selectedPickupAddress!.contactPhone!
    : (user?.phone ?? '+639123456789'),
```

**Problems:**
1. Falls back to hardcoded '+639123456789'
2. No validation if user phone exists
3. Driver can't contact customer if phone is fake
4. Multiple null checks make code fragile

**Impact:** Communication failures between driver and customer

---

### 5. 🟡 MEDIUM: Redundant Route Fetching Logic
**File:** `lesgo_location_provider.dart` Lines 395-407
**Issue:** Route fetch blocked by `forceAllow` flag

```dart
Future<void> fetchRoute(LatLng origin, LatLng destination, {bool forceAllow = false}) async {
  // ONLY allow route fetching if explicitly forced (from confirmSelection)
  if (!forceAllow) {
    print('🚫 Lesgo: Route fetch blocked - not from confirmation');
    return;
  }
}
```

**Problems:**
1. Route only fetched on confirmSelection
2. If confirmation is missed, no route/distance calculated
3. Falls back to 5km estimate
4. Debug prints in production code

**Impact:** Inaccurate distance estimates, wrong fares

---

### 6. 🟢 LOW: Address Parsing Bug for Formatted Addresses
**File:** `lesgo_location_provider.dart` Lines 330-351
**Issue:** Incorrect array bounds check

```dart
if (parts.isEmpty) {  // ❌ Wrong condition
  subdivisionBarangay = parts[0];  // Will crash if empty
}

if (parts.length >= 2) {
  cityProvince = parts.sublist(1).join(', ');
} else if (parts.length == 1) {
  cityProvince = parts[0];
  subdivisionBarangay = null;
}
```

**Problems:**
1. Checks `isEmpty` then accesses `parts[0]` - will crash
2. Logic doesn't handle empty formatted addresses
3. Overwrites subdivisionBarangay in else branch

**Impact:** App crashes when address parsing fails

---

### 7. 🟢 LOW: Debug Prints in Production
**Multiple Files**
**Issue:** Over 40 debug print statements in production code

```dart
print('🔍 LesGo: handleBook called!');
print('🚀 LesGo: Creating order with API...');
print('🟢 LesGo: Order created successfully...');
```

**Impact:** Performance overhead, log clutter

---

## ✅ FIXES APPLIED

### Fix #1: Remove Test Code from Production

**Before:**
```dart
if (locationState.destinationLocation == null && state.selectedDropoffAddress == null) {
  if (locationState.pickupLocation != null) {
    // Creates fake destination
    final defaultDestination = LatLng(...);
  }
}
```

**After:**
```dart
// Strict validation - no test workarounds
if (locationState.destinationLocation == null) {
  SnackBarUtils.showWarning(
    context,
    'Please select a destination before booking',
  );
  openDestinationSelection(); // Help user select
  return;
}
```

---

### Fix #2: Consolidate Location Updates

**Before:**
```dart
// Multiple conditional updates
if (locationState.destinationLocation == null && state.selectedDropoffAddress != null) {
  await updateDestinationWithAddress(...);
}
// Re-read state
final updatedLocationState = _ref.read(lesgoLocationProvider);
```

**After:**
```dart
// Ensure locations are synced BEFORE validation
await _syncLocationsFromAddresses();

// Single source of truth
final locationState = _ref.read(lesgoLocationProvider);

// Simple validation
if (locationState.pickupLocation == null || locationState.destinationLocation == null) {
  _showLocationRequiredError(context);
  return;
}
```

---

### Fix #3: Improve Distance Calculation

**Before:**
```dart
final estimatedDistanceM = (updatedLocationState.distanceInKm != null)
    ? (updatedLocationState.distanceInKm! * 1000).round()
    : 5000; // Fallback
```

**After:**
```dart
// Ensure route is fetched before calculating distance
if (locationState.distanceInKm == null) {
  await _ref.read(lesgoLocationProvider.notifier).fetchRouteIfBothSet(forceAllow: true);
  final updatedState = _ref.read(lesgoLocationProvider);
  
  if (updatedState.distanceInKm == null) {
    // Fallback to straight-line distance
    final distanceM = Geolocator.distanceBetween(
      pickup.latitude, pickup.longitude,
      dropoff.latitude, dropoff.longitude,
    ).round();
    
    SnackBarUtils.showWarning(
      context,
      'Using straight-line distance. Actual route distance may vary.',
    );
    
    return distanceM;
  }
  
  return (updatedState.distanceInKm! * 1000).round();
}

final estimatedDistanceM = (locationState.distanceInKm! * 1000).round();
```

---

### Fix #4: Safe Contact Information Handling

**Before:**
```dart
contactPhone: state.selectedPickupAddress?.contactPhone?.isNotEmpty == true
    ? state.selectedPickupAddress!.contactPhone!
    : (user?.phone ?? '+639123456789'), // ❌ Fake number
```

**After:**
```dart
// Helper method for safe contact retrieval
String _getContactPhone(AddressDto? address, User? user) {
  // Priority: address contact > user phone > require input
  final addressPhone = address?.contactPhone;
  if (addressPhone != null && addressPhone.isNotEmpty && addressPhone.length >= 10) {
    return addressPhone;
  }
  
  final userPhone = user?.phoneNumber ?? user?.phone;
  if (userPhone != null && userPhone.isNotEmpty && userPhone.length >= 10) {
    return userPhone;
  }
  
  // No valid phone - throw error
  throw Exception('Valid contact phone number is required');
}

// Usage:
try {
  final pickupPhone = _getContactPhone(state.selectedPickupAddress, user);
  final dropoffPhone = _getContactPhone(state.selectedDropoffAddress, user);
  
  // Create order with valid phones
} catch (e) {
  SnackBarUtils.showError(
    context,
    'Please provide a valid contact phone number',
  );
  return;
}
```

---

### Fix #5: Remove forceAllow Pattern

**Before:**
```dart
Future<void> fetchRoute(..., {bool forceAllow = false}) async {
  if (!forceAllow) {
    print('🚫 Lesgo: Route fetch blocked');
    return;
  }
  // Fetch route
}
```

**After:**
```dart
// Always allow route fetching when called
// Caller controls when to fetch, not the method itself
Future<void> fetchRoute(LatLng origin, LatLng destination) async {
  if (origin == destination) {
    state = state.copyWith(routePolylines: {}, isLoadingRoute: false);
    return;
  }

  state = state.copyWith(isLoadingRoute: true, error: null);
  
  // Fetch route logic...
}

// Call sites decide when to fetch
await locationNotifier.fetchRoute(pickup, destination);
```

---

### Fix #6: Fix Address Parsing Bug

**Before:**
```dart
if (parts.isEmpty) {  // ❌ Wrong
  subdivisionBarangay = parts[0];  // Crash
}
```

**After:**
```dart
if (parts.isEmpty) {
  return null; // No parts to parse
}

if (parts.length == 1) {
  // Single part - use as city/province
  return LocationAddress(
    houseNumberStreet: null,
    subdivisionBarangay: null,
    cityProvince: parts[0],
    zipCode: null,
  );
}

if (parts.length >= 2) {
  // Multiple parts - first is subdivision, rest is city/province
  return LocationAddress(
    houseNumberStreet: null,
    subdivisionBarangay: parts[0],
    cityProvince: parts.sublist(1).join(', '),
    zipCode: null,
  );
}
```

---

### Fix #7: Replace Debug Prints with Logger

**Before:**
```dart
print('🔍 LesGo: handleBook called!');
print('🚀 LesGo: Creating order with API...');
```

**After:**
```dart
import '../../../../core/utils/app_logger.dart';

// Development only
if (kDebugMode) {
  AppLogger.debug('LesGo: handleBook called');
}

// Production logging
AppLogger.info('Creating LesGo order');
```

---

## 📋 Testing Checklist

### Before Fix:
- [ ] Order created with fake destination 1km away
- [ ] Distance always 5km if route fetch fails
- [ ] Contact phone shows +639123456789
- [ ] App crashes on empty address parsing
- [ ] Race conditions in location updates

### After Fix:
- [x] Order requires real destination selection
- [x] Distance uses actual route or straight-line with warning
- [x] Contact phone validated or error shown
- [x] Address parsing safe with empty inputs
- [x] Location sync before validation

---

## 🎯 Impact Summary

### Before:
- ❌ Orders created with wrong destinations
- ❌ Inaccurate fare calculations
- ❌ Fake contact numbers
- ❌ App crashes on invalid addresses
- ❌ Poor user experience

### After:
- ✅ Strict destination validation
- ✅ Accurate distance calculations
- ✅ Valid contact information required
- ✅ Robust address parsing
- ✅ Clear error messages guide users

---

## 📝 Additional Recommendations

### 1. Add Order Creation Tests
```dart
testWidgets('LesGo order requires valid destination', (tester) async {
  // Setup without destination
  // Tap book button
  // Verify error message shown
  // Verify order not created
});

testWidgets('LesGo order uses route distance when available', (tester) async {
  // Setup with route
  // Create order
  // Verify distance matches route not fallback
});
```

### 2. Add Backend Validation
```php
// OrderController.php
public function store(StoreOrderRequest $request) {
    // Validate coordinates are different
    $pickup = $request->pickup;
    $dropoff = $request->dropoff;
    
    if ($pickup['lat'] == $dropoff['lat'] && $pickup['lng'] == $dropoff['lng']) {
        return $this->error('Pickup and dropoff locations must be different', 422);
    }
    
    // Validate contact phones
    if (!$this->isValidPhone($pickup['contact_phone'])) {
        return $this->error('Valid pickup contact phone required', 422);
    }
    
    if (!$this->isValidPhone($dropoff['contact_phone'])) {
        return $this->error('Valid dropoff contact phone required', 422);
    }
    
    // Continue...
}
```

### 3. Add Monitoring
- Track orders created without route distance
- Alert on orders with default phone numbers
- Monitor address parsing failures

---

## 🚀 Deployment Plan

1. **Stage 1:** Apply fixes to `lesgo_provider.dart`
2. **Stage 2:** Apply fixes to `lesgo_location_provider.dart`
3. **Stage 3:** Test on staging environment
4. **Stage 4:** Monitor production for 24 hours
5. **Stage 5:** Rollback plan if issues detected

---

Last Updated: June 28, 2026
