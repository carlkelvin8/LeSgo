# LesEat Order Status Screens Implementation Plan

## Overview
Need to implement 4 different order status screens for LesEat flow based on order status.

## Screens to Implement

### 1. "We are cooking your food!" Screen
**Status**: `cooking` / `preparing`
**Features**:
- Illustration of delivery person with food
- Red status indicator with "We are cooking your food!"
- Address section
- Your Order section (list of items)
- "Contact Restaurant" button (purple)

### 2. "For Delivery!" Screen  
**Status**: `ready_for_pickup` / `driver_assigned`
**Features**:
- Map view showing restaurant and delivery locations
- Yellow status indicator with "For Delivery!"
- Address section
- Your Order section
- Two buttons:
  - "Contact Restaurant" (purple)
  - "Contact Driver" (gray)

### 3. "ORDER IS COMPLETE!" Screen
**Status**: `completed` / `delivered`
**Features**:
- Sunsets Cafe logo/icon
- "ORDER IS COMPLETE!" heading (purple)
- "How was the experience?" text
- Star rating (5 stars)
- Text input for review
- "Submit" button (gray)
- "Book Another One" button (purple)

### 4. Order Summary Screen
**Status**: After rating submitted
**Features**:
- "Deliver this order to:" with map thumbnail
- Restaurant name (Sunsets Cafe)
- Order items with images, quantities, and prices
- "Add more items" link
- Summary section:
  - Apply Voucher option
  - Subtotal
  - Delivery fee
  - Total (in items)
- "Continue" button (purple)

## Implementation Approach

### Option 1: Single Dynamic Screen
Create one screen that changes UI based on order status:
```dart
class LeseatOrderStatusScreen extends StatelessWidget {
  final String status;
  final Map<String, dynamic> orderData;
  
  Widget build(BuildContext context) {
    switch (status) {
      case 'cooking':
        return _buildCookingView();
      case 'ready_for_pickup':
        return _buildReadyForDeliveryView();
      case 'completed':
        return _buildCompletedView();
      case 'summary':
        return _buildSummaryView();
      default:
        return _buildTrackingView();
    }
  }
}
```

### Option 2: Separate Screens
Create 4 separate screen files:
- `leseat_cooking_screen.dart`
- `leseat_ready_delivery_screen.dart`  
- `leseat_order_complete_screen.dart` (already exists, needs update)
- `leseat_order_summary_screen.dart`

## Recommended: Option 1 (Single Dynamic Screen)

**Advantages**:
- Easier state management
- Smoother transitions
- Less code duplication
- Single source of truth for order data

## Files to Create/Modify

1. **Create**: `leseat_order_status_screen.dart`
   - Main screen with status-based views
   - Handles all 4 states

2. **Create Widgets**:
   - `cooking_status_view.dart`
   - `ready_delivery_status_view.dart`
   - `completed_status_view.dart`
   - `summary_status_view.dart`

3. **Modify**: `leseat_order_tracking_screen.dart`
   - Update to use new status screen
   - Add status polling/WebSocket

4. **Modify**: `booking_router.dart`
   - Add route for new status screen

## Data Structure

```dart
class OrderStatusData {
  final String orderId;
  final String status;
  final String restaurantName;
  final String restaurantLogo;
  final String deliveryAddress;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final DriverInfo? driverInfo;
  final RestaurantInfo? restaurantInfo;
}

class OrderItem {
  final String name;
  final String image;
  final int quantity;
  final double price;
}
```

## Status Flow

```
pending → waiting_confirmation → cooking → ready_for_pickup → 
on_the_way → delivered → completed (with rating) → summary
```

## Next Steps

1. Create the main `LeseatOrderStatusScreen`
2. Create individual view widgets for each status
3. Add status polling mechanism
4. Integrate with existing order tracking
5. Add rating/review functionality
6. Test all status transitions

Would you like me to proceed with implementing Option 1 (single dynamic screen with multiple views)?
