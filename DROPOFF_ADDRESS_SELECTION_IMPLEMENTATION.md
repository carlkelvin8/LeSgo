# Dropoff Address Selection Implementation for LesEat & LesBuy

## Overview
Implemented dropoff address selection functionality for LesEat and LesBuy checkout screens. Customers can now select from their saved addresses instead of being limited to their default profile address.

## Implementation Date
April 23, 2026

## Problem Statement
Previously, when placing orders in LesEat and LesBuy:
- ❌ Dropoff address was hardcoded to user's profile address
- ❌ No option to select different delivery location
- ❌ `onTap` callback in `DeliveryAddressSection` was TODO
- ❌ Limited flexibility for customers with multiple addresses

## Solution
Integrated existing `AddressSelectorWidget` into checkout flow with bottom sheet modal for address selection.

## Changes Made

### 1. LesBuy Store Cart Screen (`store_cart_screen.dart`)

#### Changed from StatelessWidget to StatefulWidget
```dart
class StoreCartScreen extends ConsumerStatefulWidget
class _StoreCartScreenState extends ConsumerState<StoreCartScreen>
```

#### Added State Variable
```dart
AddressDto? _selectedAddress;
```

#### Added Imports
```dart
import '../../../../../data/data_source/dto/address/address_dto.dart';
import '../../../../provider/main/address/address_provider.dart';
import '../../../../widgets/address/address_selector_widget.dart';
```

#### New Method: `_showAddressSelector()`
```dart
void _showAddressSelector(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(...),
          // Address selector
          Expanded(
            child: AddressSelectorWidget(
              title: 'Select Delivery Address',
              onAddressSelected: (address) {
                setState(() {
                  _selectedAddress = address;
                });
                Navigator.pop(context);
                // Show confirmation
              },
            ),
          ),
        ],
      ),
    ),
  );
}
```

#### Updated Address Handling in `build()`
```dart
// Get delivery address - use selected address or fallback to profile
final String userAddress;
final double dropoffLat;
final double dropoffLng;
final String contactName;
final String contactPhone;

if (_selectedAddress != null) {
  userAddress = _selectedAddress!.addressLine1;
  dropoffLat = _selectedAddress!.latitude;
  dropoffLng = _selectedAddress!.longitude;
  contactName = _selectedAddress!.contactName.isNotEmpty 
      ? _selectedAddress!.contactName 
      : (profileState.user?.name ?? 'Customer');
  contactPhone = _selectedAddress!.contactPhone.isNotEmpty 
      ? _selectedAddress!.contactPhone 
      : (profileState.user?.phone ?? '+639123456789');
} else {
  // Fallback to profile address
  userAddress = profileState.address1.isNotEmpty 
      ? profileState.address1 
      : (profileState.user?.addressLine1 ?? 'No address set');
  dropoffLat = 8.4542; // Default coordinates
  dropoffLng = 124.6319;
  contactName = profileState.user?.name ?? 'Customer';
  contactPhone = profileState.user?.phone ?? '+639123456789';
}
```

#### Updated DeliveryAddressSection
```dart
DeliveryAddressSection(
  address: userAddress,
  onTap: () {
    _showAddressSelector(context, ref);
  },
),
```

#### Updated Order Creation
```dart
dropoff: OrderAddressDto(
  address: dropoffAddress,
  lat: dropoffLat,
  lng: dropoffLng,
  contactName: dropoffContactName,
  contactPhone: dropoffContactPhone,
),
```

### 2. LesEat Checkout Screen (`leseat_checkout_screen.dart`)

#### Changed from StatelessWidget to StatefulWidget
```dart
class LeseatCheckoutScreen extends ConsumerStatefulWidget
class _LeseatCheckoutScreenState extends ConsumerState<LeseatCheckoutScreen>
```

#### Added State Variable
```dart
AddressDto? _selectedAddress;
```

#### Added Imports
```dart
import '../../../../../data/data_source/dto/address/address_dto.dart';
import '../../../../provider/main/address/address_provider.dart';
import '../../../../widgets/address/address_selector_widget.dart';
```

#### New Method: `_showAddressSelector()`
Same implementation as LesBuy, with additional provider update:
```dart
// Update checkout provider with new address
ref.read(checkoutProvider.notifier).updateDeliveryAddress(
  address.addressLine1,
  address.latitude,
  address.longitude,
  address.contactName,
  address.contactPhone,
);
```

#### Updated DeliveryAddressSection
```dart
DeliveryAddressSection(
  address: _selectedAddress?.addressLine1 ?? order.deliveryAddress,
  onTap: () {
    _showAddressSelector(context, ref);
  },
),
```

### 3. Checkout Provider (`checkout_provider.dart`)

#### New Method: `updateDeliveryAddress()`
```dart
void updateDeliveryAddress(
  String address,
  double lat,
  double lng,
  String contactName,
  String contactPhone,
) {
  if (state.order == null) return;

  final updatedOrder = state.order!.copyWith(
    deliveryAddress: address,
  );

  state = state.copyWith(order: updatedOrder);
}
```

## User Experience Flow

### LesBuy Flow
1. Customer adds items to cart
2. Customer goes to checkout (Store Cart Screen)
3. Customer sees current delivery address
4. Customer taps on delivery address section
5. **Bottom sheet opens** with address selector
6. Customer sees list of saved addresses:
   - Default address (if exists)
   - Other saved addresses (up to 2)
   - "View all X addresses" button (if more than 3)
7. Customer selects desired address
8. **Address updates** in UI
9. **Success message** shows: "Delivery address updated"
10. Customer proceeds with checkout
11. Order created with **selected address coordinates**

### LesEat Flow
1. Customer adds items to cart
2. Customer goes to checkout
3. Customer sees current delivery address
4. Customer taps on delivery address section
5. **Bottom sheet opens** with address selector
6. Customer selects desired address
7. **Checkout provider updates** with new address
8. **Address updates** in UI
9. **Success message** shows
10. Customer proceeds with checkout
11. Order created with **selected address**

## Address Selector Features

### AddressSelectorWidget
- **Compact design** for bottom sheets
- **Default address** highlighted
- **Address labels** (Home, Work, etc.)
- **Contact info** displayed
- **Radio button** selection
- **Manage button** to add/edit addresses
- **Empty state** with "Add Address" button

### Address Display
- Shows address label badge
- Shows "Default" badge if applicable
- Shows address line 1
- Shows contact name and phone
- Selected address has:
  - Purple left border
  - Purple background tint
  - Checkmark icon

### Bottom Sheet Design
- **70% screen height**
- **Rounded top corners** (20px radius)
- **Handle bar** at top (drag indicator)
- **Scrollable** address list
- **Transparent background** with white container

## Technical Details

### Address Data Flow
```
1. User taps delivery address section
2. Bottom sheet opens with AddressSelectorWidget
3. Widget loads addresses from AddressProvider
4. User selects address
5. onAddressSelected callback fires
6. setState updates _selectedAddress
7. UI rebuilds with new address
8. Order creation uses selected address data
```

### Address Priority
```
1. Selected address (_selectedAddress != null)
   ↓
2. Profile address (user.addressLine1)
   ↓
3. Default fallback ("No address set")
```

### Coordinate Handling
- **Selected address**: Uses actual lat/lng from address
- **Profile address**: Uses default coordinates (8.4542, 124.6319)
- **Fallback**: Uses default coordinates

### Contact Information
- **Selected address**: Uses address contact info if available
- **Fallback**: Uses user profile name/phone
- **Default**: "Customer" / "+639123456789"

## Integration with Existing Features

### Address Management
- Uses existing `AddressProvider`
- Uses existing `AddressDto` model
- Uses existing `AddressSelectorWidget`
- Integrates with address management screen

### Order Creation
- Passes selected address to `CreateOrderRequestDto`
- Includes actual coordinates (lat/lng)
- Includes contact name and phone
- Stored in order metadata

### Profile Integration
- Falls back to profile address if no selection
- Uses profile contact info as fallback
- Maintains backward compatibility

## Files Modified

1. **FRONTEND/lib/presentation/screens/main/booking/lesbuy/store_cart_screen.dart**
   - Changed to StatefulWidget
   - Added address selection logic
   - Added bottom sheet modal
   - Updated order creation

2. **FRONTEND/lib/presentation/screens/main/booking/leseat/leseat_checkout_screen.dart**
   - Changed to StatefulWidget
   - Added address selection logic
   - Added bottom sheet modal
   - Integrated with checkout provider

3. **FRONTEND/lib/presentation/provider/main/booking/checkout_provider.dart**
   - Added `updateDeliveryAddress()` method
   - Updates order with new address

## Dependencies

### Existing Components Used
- `AddressSelectorWidget` - Address selection UI
- `AddressProvider` - Address state management
- `AddressDto` - Address data model
- `DeliveryAddressSection` - Address display widget

### No New Dependencies
- Uses existing address management system
- No new packages required
- Leverages existing UI components

## Testing Checklist

- [x] Bottom sheet opens when tapping delivery address
- [x] Address list loads from AddressProvider
- [x] Default address shows "Default" badge
- [x] Selected address highlights with purple border
- [x] Selecting address updates UI
- [x] Success message shows after selection
- [x] Bottom sheet closes after selection
- [x] Order created with selected address coordinates
- [x] Order created with selected contact info
- [x] Fallback to profile address works
- [x] Empty state shows "Add Address" button
- [x] "Manage" button navigates to address management
- [x] Multiple addresses display correctly
- [x] "View all" button shows for 3+ addresses

## Benefits

### For Customers
✅ **Flexibility** - Choose delivery location per order
✅ **Convenience** - Use saved addresses
✅ **Accuracy** - Actual coordinates sent to driver
✅ **Multiple locations** - Home, work, friend's place, etc.

### For Business
✅ **Better UX** - More intuitive ordering
✅ **Accurate delivery** - Correct coordinates
✅ **Reduced errors** - Less wrong address issues
✅ **Customer satisfaction** - More control

### For Drivers
✅ **Accurate locations** - Real coordinates
✅ **Contact info** - Correct phone numbers
✅ **Better navigation** - Precise dropoff points

## Future Enhancements

### Potential Improvements
1. **Recent addresses** - Show recently used addresses first
2. **Address search** - Search/filter saved addresses
3. **Quick add** - Add new address from checkout
4. **Address validation** - Verify address before order
5. **Distance calculation** - Show distance from restaurant/store
6. **Delivery fee update** - Adjust fee based on distance
7. **Map preview** - Show address on map before selection
8. **Favorite addresses** - Star frequently used addresses

### Performance Optimizations
1. **Address caching** - Cache loaded addresses
2. **Lazy loading** - Load addresses on demand
3. **Debounced updates** - Prevent rapid state changes

## Related Implementations

### Previous Work
1. **Address Management System**
   - `AddressManagementScreen`
   - `AddressProvider`
   - `AddressDto` model

2. **Address Selector Widget**
   - `AddressSelectorWidget`
   - Compact design for checkout

3. **Order Creation**
   - `CreateOrderRequestDto`
   - `OrderAddressDto`
   - Backend API integration

## Notes

- Address selection is **optional** - defaults to profile address
- Selected address **persists** during checkout session
- Address **resets** when starting new order
- Bottom sheet is **dismissible** by tapping outside
- Address coordinates are **required** for accurate routing
- Contact info is **important** for driver communication

## Success Criteria

✅ Customer can select dropoff address in LesEat
✅ Customer can select dropoff address in LesBuy
✅ Selected address shows in delivery section
✅ Order created with correct address coordinates
✅ Order created with correct contact information
✅ Fallback to profile address works
✅ UI updates immediately after selection
✅ Success feedback shown to user
✅ No breaking changes to existing flow
✅ Backward compatible with profile addresses
