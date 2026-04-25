# LesEat Waiting for Restaurant Confirmation Screen

## Overview
Implemented the "Waiting for Restaurant Confirmation" screen that shows after a customer places a LesEat order and is waiting for the restaurant to accept it.

## Screen Features

### UI Components
1. **App Bar**
   - Back button (purple)
   - "LeSeat" title (centered)
   - Profile icon button

2. **Illustration**
   - Circular background (light gray)
   - Delivery person with food illustration
   - Fallback to restaurant icon if image not found

3. **Status Card**
   - "Waiting for Restaurant Confirmation" title
   - Loading spinner animation
   - Address section showing delivery address
   - Your Order section listing ordered items with quantities

4. **Cancel Button**
   - Full-width purple button at bottom
   - Shows confirmation dialog before canceling

### Parameters
```dart
LeseatWaitingConfirmationScreen({
  required int orderId,           // Order ID for tracking
  required String address,        // Delivery address
  required List<Map<String, dynamic>> orderItems,  // Order items list
})
```

### Order Items Format
```dart
[
  {
    'quantity': 4,
    'name': 'Sun Sets Pizza'
  },
  {
    'quantity': 2,
    'name': 'Sun Sets Sisig'
  }
]
```

## Integration

### 1. Add to Router

**File**: `FRONTEND/lib/core/constants/routers/booking/booking_router.dart`

```dart
GoRoute(
  path: 'leseat-waiting-confirmation',
  name: 'leseat-waiting-confirmation',
  builder: (context, state) {
    final extra = state.extra as Map<String, dynamic>;
    return LeseatWaitingConfirmationScreen(
      orderId: extra['orderId'] as int,
      address: extra['address'] as String,
      orderItems: extra['orderItems'] as List<Map<String, dynamic>>,
    );
  },
),
```

### 2. Navigate from Checkout

After successfully placing an order in `leseat_checkout_screen.dart`:

```dart
// After order is placed successfully
context.pushNamed(
  'leseat-waiting-confirmation',
  extra: {
    'orderId': orderId,
    'address': deliveryAddress,
    'orderItems': cartItems.map((item) => {
      'quantity': item.quantity,
      'name': item.name,
    }).toList(),
  },
);
```

### 3. Add Illustration Asset

Place the illustration image at:
```
FRONTEND/assets/images/leseat/waiting_confirmation.png
```

Or use the fallback restaurant icon (already implemented).

## User Flow

1. **Customer places order** → Checkout screen
2. **Order submitted** → Navigate to Waiting Confirmation screen
3. **Show loading state** → Circular progress indicator
4. **Display order details** → Address and items
5. **Wait for restaurant** → Poll order status or use WebSocket
6. **Restaurant accepts** → Navigate to Order Tracking screen
7. **Restaurant rejects** → Show error and go back
8. **Customer cancels** → Show confirmation dialog → Cancel order

## Next Steps

### Real-time Updates
Implement order status polling or WebSocket connection:

```dart
@override
void initState() {
  super.initState();
  _startPolling();
}

void _startPolling() {
  Timer.periodic(Duration(seconds: 5), (timer) async {
    final status = await ApiService.getOrderStatus(widget.orderId);
    
    if (status == 'accepted') {
      timer.cancel();
      // Navigate to tracking screen
      context.pushReplacementNamed('leseat-order-tracking', extra: {
        'orderId': widget.orderId,
      });
    } else if (status == 'rejected') {
      timer.cancel();
      // Show error and go back
      _showRejectedDialog();
    }
  });
}
```

### Cancel Order API

```dart
Future<void> _cancelOrder() async {
  try {
    await ApiService.cancelOrder(widget.orderId);
    context.pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Order cancelled successfully')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to cancel order')),
    );
  }
}
```

## Styling

### Colors
- Primary Purple: `Color(0xFF5F2D82)`
- White Background: `Colors.white`
- Gray Text: `Colors.grey.shade600`
- Border: `Colors.grey.shade300`

### Typography
- Font Family: `TT Fors`
- Title: 18px, Bold
- Body: 14px, Regular
- Button: 16px, Bold

## Files Created
- ✅ `FRONTEND/lib/presentation/screens/main/booking/leseat/leseat_waiting_confirmation_screen.dart`

## Files to Modify
- ⏳ `FRONTEND/lib/core/constants/routers/booking/booking_router.dart` (add route)
- ⏳ `FRONTEND/lib/presentation/screens/main/booking/leseat/leseat_checkout_screen.dart` (add navigation)

## Assets Needed
- ⏳ `FRONTEND/assets/images/leseat/waiting_confirmation.png` (illustration)

## Testing Checklist
- [ ] Screen displays correctly
- [ ] Back button works
- [ ] Cancel button shows confirmation dialog
- [ ] Order items display correctly
- [ ] Address displays correctly
- [ ] Loading spinner animates
- [ ] Responsive on different screen sizes
- [ ] Navigation works properly
