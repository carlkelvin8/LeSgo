# LesEat Order Status Screens Implementation

## Overview
Implemented a dynamic order status screen for LesEat that displays different views based on the current order status.

## Implementation Details

### Files Created
1. **`FRONTEND/lib/presentation/screens/main/booking/leseat/leseat_order_status_screen.dart`**
   - Main screen with 3 status views
   - Dynamically switches UI based on order status

### Files Modified
1. **`FRONTEND/lib/core/constants/routers/booking/booking_routes.dart`**
   - Added `leseatOrderStatus` route constant

2. **`FRONTEND/lib/core/constants/routers/booking/booking_router.dart`**
   - Added route handler for `leseatOrderStatus`
   - Imported `LeseatOrderStatusScreen`

3. **`FRONTEND/lib/presentation/screens/main/booking/leseat/leseat_order_tracking_screen.dart`**
   - Updated `_rateOrder()` to navigate to order status screen with 'completed' status

## Screen Views

### 1. Cooking Status View
**Status**: `cooking`, `preparing`

**Features**:
- Circular illustration with restaurant icon
- Red status indicator: "We are cooking your food!"
- Loading spinner
- Address section with location icon
- Your Order section (list of order items)
- "Contact Restaurant" button (purple)

**UI Elements**:
- Red status card with circular indicator
- Grey background containers for address and order items
- Full-width purple button at bottom

### 2. Ready for Delivery View
**Status**: `ready_for_pickup`, `driver_assigned`, `on_the_way`, `delivering`

**Features**:
- Google Maps view at top (300px height)
- Yellow status indicator: "For Delivery!"
- Address section with location icon
- Your Order section (list of order items)
- Two action buttons:
  - "Contact Restaurant" (purple)
  - "Contact Driver" (grey)

**UI Elements**:
- Map takes top portion of screen
- Yellow status card with circular indicator
- Scrollable content below map
- Two stacked buttons at bottom

### 3. Order Complete View
**Status**: `completed`, `delivered`

**Features**:
- Restaurant logo/icon (circular, orange background)
- Restaurant name
- "ORDER IS COMPLETE!" heading (purple)
- Rating section:
  - "How was the experience?" text
  - 5-star rating (interactive)
  - Multi-line text input for review
  - "Submit" button (grey)
- "Book Another One" button (purple)

**UI Elements**:
- Centered layout with vertical flow
- Large circular restaurant icon
- Grey container for rating section
- Interactive star rating (tap to select)
- Text field with purple focus border
- Two full-width buttons at bottom

## Status Flow

```
pending → waiting_confirmation → cooking → ready_for_pickup → 
on_the_way → delivered → completed (with rating)
```

## Data Structure

The screen expects the following data structure in `orderData`:

```dart
{
  'status': 'cooking', // Current order status
  'restaurantName': 'Restaurant Name',
  'deliveryAddress': 'Full delivery address',
  'items': [
    OrderItem(
      name: 'Item Name',
      imagePath: 'assets/path/to/image.png',
      price: 150.0,
      quantity: 2,
    ),
    // ... more items
  ],
}
```

## Navigation

### To Order Status Screen
```dart
AppRouter.pushReplacement(
  context,
  BookingRoutes.leseatOrderStatus,
  arguments: {
    'orderId': '123',
    'orderType': 'LesEat',
    'orderData': {
      'status': 'cooking',
      'restaurantName': 'Sunsets Cafe',
      'deliveryAddress': '123 Main St, City',
      'items': [...],
    },
  },
);
```

### From Order Status Screen
- **Submit Rating**: Navigates to home (`/`)
- **Book Another One**: Navigates to LesEat screen (`BookingRoutes.leseat`)
- **Back Button**: Pops current screen

## Reused Components

The implementation reuses existing widgets:
- `OrderItemCard` - Displays order items with images, quantities, and prices
- `ResponsiveUtils` - Handles responsive sizing and spacing
- `AppRouter` - Navigation helper

## TODO / Future Enhancements

1. **API Integration**:
   - Fetch real-time order status from backend
   - Implement WebSocket or polling for status updates
   - Submit rating/review to backend API

2. **Contact Functionality**:
   - Implement "Contact Restaurant" feature (phone call or chat)
   - Implement "Contact Driver" feature (phone call or chat)

3. **Map Integration**:
   - Show real restaurant and delivery locations on map
   - Display driver's real-time location
   - Show route polyline

4. **Order Summary View**:
   - Create 4th view for detailed order summary
   - Include voucher application
   - Show itemized pricing breakdown

5. **Status Transitions**:
   - Add smooth animations between status views
   - Implement status change notifications
   - Add estimated time for each status

6. **Error Handling**:
   - Handle API errors gracefully
   - Show retry options for failed operations
   - Add offline mode support

## Testing

To test the implementation:

1. Navigate to LesEat screen
2. Select a restaurant and add items to cart
3. Proceed to checkout
4. After order placement, you'll see the waiting confirmation screen
5. Once confirmed, navigate to order status screen with different status values:
   - `cooking` - Shows cooking view
   - `ready_for_pickup` - Shows map view with yellow indicator
   - `completed` - Shows rating view

## Notes

- The screen automatically switches views based on the `status` field in `orderData`
- All buttons currently show placeholder messages (SnackBar)
- Map view uses default Cagayan de Oro coordinates
- Rating submission navigates to home screen
- Uses existing `OrderItemCard` widget for consistent item display
- Follows the app's design system (TT Fors font, purple theme color #5F2D82)

## Related Files

- `leseat_waiting_confirmation_screen.dart` - Shows before order is confirmed
- `leseat_order_tracking_screen.dart` - Shows real-time tracking with map
- `leseat_order_complete_screen.dart` - Alternative completion screen (can be deprecated)
- `leseat_checkout_screen.dart` - Checkout flow before order placement
