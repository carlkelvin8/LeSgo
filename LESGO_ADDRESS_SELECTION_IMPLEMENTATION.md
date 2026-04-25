# LesGo Address Selection Implementation

## Overview
Implemented address selection for LesGo (delivery service) using existing API and widgets. Customers can now select pickup and dropoff locations from their saved addresses instead of only using map selection.

## Implementation Date
April 23, 2026

## Changes Made

### 1. LesGo Provider (`lesgo_provider.dart`)

#### Added Imports
```dart
import '../../../../data/data_source/dto/address/address_dto.dart';
import '../address/address_provider.dart';
```

#### Updated LesgoState
```dart
class LesgoState {
  // ... existing fields
  final AddressDto? selectedPickupAddress;
  final AddressDto? selectedDropoffAddress;
}
```

#### New Methods
```dart
void selectPickupAddress(AddressDto address)
void selectDropoffAddress(AddressDto address)
void clearPickupAddress()
void clearDropoffAddress()
```

#### Updated Order Creation
- Uses selected address if available
- Falls back to map-selected location
- Includes actual coordinates from saved address
- Includes contact info from saved address

### 2. LesGo Details Panel (`lesgo_details_panel.dart`)

#### Changed to ConsumerWidget
```dart
class LesgoDetailsPanel extends ConsumerWidget
```

#### Added Imports
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/data_source/dto/address/address_dto.dart';
import '../../../provider/main/booking/lesgo_provider.dart';
import '../../../provider/main/address/address_provider.dart';
import '../../address/address_selector_widget.dart';
```

#### New Method
```dart
void _showAddressSelector(
  BuildContext context,
  WidgetRef ref,
  bool isPickup,
)
```

#### Updated Location Tiles
- Shows selected address if available
- Shows bookmark icon when address is selected
- "Change" button opens address selector
- Can clear selected address and use map

## User Experience

### Pickup Address Selection
1. User sees "Pick-up Location" tile
2. User taps "Change" button
3. **Bottom sheet opens** with saved addresses
4. User selects address
5. **Pickup updates** with address coordinates
6. **Bookmark icon** appears
7. Map marker moves to address location

### Dropoff Address Selection
1. User sees "Drop-off Location" tile
2. User taps "Change" button
3. **Bottom sheet opens** with saved addresses
4. User selects address
5. **Dropoff updates** with address coordinates
6. **Bookmark icon** appears
7. Map marker moves to address location

### Clearing Selected Address
1. User taps "Change" button when address is selected
2. Selected address clears
3. Returns to map selection mode
4. Bookmark icon disappears

## Features

### ✅ Dual Selection Mode
- **Map selection** - Tap on map (existing)
- **Address selection** - Choose from saved addresses (new)

### ✅ Visual Indicators
- **Bookmark icon** - Shows when using saved address
- **Address display** - Shows selected address name
- **Change button** - Opens address selector

### ✅ Smart Fallback
- Uses selected address if available
- Falls back to map location
- Always has valid coordinates

### ✅ Contact Information
- Uses address contact name/phone
- Falls back to user profile
- Accurate delivery information

## Technical Implementation

### Address Selection Flow
```
1. User taps "Change" button
2. _showAddressSelector() called
3. Bottom sheet opens with AddressSelectorWidget
4. Widget loads addresses from API (GET /v1/addresses)
5. User selects address
6. selectPickupAddress() or selectDropoffAddress() called
7. Updates lesgoState with selected address
8. Updates lesgoLocationProvider with coordinates
9. Map marker moves to address location
10. UI updates with address name
```

### Order Creation Priority
```
Pickup Address:
1. selectedPickupAddress (if set)
   ↓
2. pickupLocation from map
   ↓
3. Default coordinates

Dropoff Address:
1. selectedDropoffAddress (if set)
   ↓
2. destinationLocation from map
   ↓
3. Default coordinates
```

### State Management
```dart
// LesgoState holds selected addresses
final AddressDto? selectedPickupAddress;
final AddressDto? selectedDropoffAddress;

// LesgoLocationState holds map locations
final LatLng? pickupLocation;
final LatLng? destinationLocation;

// Order creation uses both
pickup: OrderAddressDto(
  address: selectedPickupAddress?.addressLine1 ?? 
           pickupAddress?.toString(),
  lat: selectedPickupAddress?.latitude ?? 
       pickupLocation?.latitude,
  lng: selectedPickupAddress?.longitude ?? 
       pickupLocation?.longitude,
)
```

## Integration with Existing Features

### ✅ Map Selection (Existing)
- Still works as before
- Can switch between map and address selection
- Map updates when address selected

### ✅ Address Management (Existing)
- Uses existing AddressProvider
- Uses existing AddressSelectorWidget
- Uses existing API endpoints

### ✅ Location Provider (Existing)
- Updates with address coordinates
- Maintains route calculation
- Keeps distance/duration calculation

## Files Modified

1. **FRONTEND/lib/presentation/provider/main/booking/lesgo_provider.dart**
   - Added address selection state
   - Added address selection methods
   - Updated order creation logic

2. **FRONTEND/lib/presentation/widgets/booking/lesgo/lesgo_details_panel.dart**
   - Changed to ConsumerWidget
   - Added address selector bottom sheet
   - Updated location tiles with address selection

## No New Files Created

### ❌ No New Screens
- Used existing AddressSelectorWidget

### ❌ No New Widgets
- Used existing components

### ❌ No New API Calls
- Used existing GET /v1/addresses

### ❌ No New Providers
- Used existing AddressProvider

## Benefits

### For Customers
✅ **Quick selection** - Choose from saved addresses
✅ **Accurate locations** - Use verified addresses
✅ **Flexibility** - Switch between map and addresses
✅ **Convenience** - No need to search on map

### For Business
✅ **Better UX** - More intuitive booking
✅ **Accurate delivery** - Correct coordinates
✅ **Reduced errors** - Less wrong address issues

### For Drivers
✅ **Accurate locations** - Real coordinates
✅ **Contact info** - Correct phone numbers
✅ **Better navigation** - Precise pickup/dropoff

## Testing Checklist

- [x] Bottom sheet opens when tapping "Change"
- [x] Address list loads from API
- [x] Selecting address updates pickup/dropoff
- [x] Map marker moves to address location
- [x] Bookmark icon shows when address selected
- [x] Can clear selected address
- [x] Order created with address coordinates
- [x] Order created with address contact info
- [x] Falls back to map location if no address
- [x] Success message shows after selection

## Success Criteria

✅ Customer can select pickup from saved addresses
✅ Customer can select dropoff from saved addresses
✅ Selected address shows in location tile
✅ Map marker updates to address location
✅ Order created with correct address coordinates
✅ Order created with correct contact information
✅ Can switch between map and address selection
✅ Bookmark icon indicates address selection
✅ No breaking changes to existing flow
✅ Uses 100% existing infrastructure
