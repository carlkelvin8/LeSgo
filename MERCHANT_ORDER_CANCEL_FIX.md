# Merchant Order Cancellation Bug Fix

## Date: June 28, 2026

## 🐛 Error Identified

### Error Message:
```
Duplicate GlobalKeys detected in widget tree.
The following GlobalKeys were specified multiple times in the widget tree.
- [LabeledGlobalKey<_OverlayEntryWidgetState>#779c3]
- [LabeledGlobalKey<_OverlayEntryWidgetState>#e59cf]
```

### Error Type:
**Duplicate GlobalKey Error** - Flutter Framework Assertion Failure

### Location:
`package:flutter/src/widgets/framework.dart:6271`

---

## 📋 Root Cause Analysis

### What's Happening:
Kapag nag-cancel ng order sa merchant app, may widget (likely dialog/modal) na:
1. Hindi properly removed from widget tree
2. May duplicate GlobalKey sa overlay entries
3. Navigation context na may stale reference

### Common Scenarios:
1. **Dialog Overlap** - Dalawang dialogs simultaneously open
2. **Navigation Issue** - Pop without proper cleanup
3. **State Retention** - Widget recreated with same key
4. **Overlay Stack** - Multiple overlays using same keys

---

## ✅ Solution Approaches

### Solution 1: Ensure Single Dialog/Modal (Recommended)

**Problem:** Multiple dialogs with same keys
**Fix:** Guard against multiple simultaneous dialogs

```dart
// merchant_order_provider.dart or similar
bool _isCancelDialogShowing = false;

Future<void> showCancelOrderDialog(BuildContext context, int orderId) async {
  // Prevent duplicate dialogs
  if (_isCancelDialogShowing) {
    debugPrint('⚠️ Cancel dialog already showing, ignoring duplicate call');
    return;
  }
  
  _isCancelDialogShowing = true;
  
  try {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Must tap button to close
      builder: (dialogContext) => CancelOrderDialog(orderId: orderId),
    );
    
    if (result == true) {
      await _cancelOrder(orderId);
    }
  } finally {
    _isCancelDialogShowing = false;
  }
}
```

---

### Solution 2: Use UniqueKey for Dialogs

**Problem:** Same GlobalKey reused
**Fix:** Generate unique key per dialog

```dart
Future<void> showCancelOrderDialog(BuildContext context, int orderId) async {
  await showDialog<bool>(
    context: context,
    builder: (dialogContext) => CancelOrderDialog(
      key: UniqueKey(), // ✅ New unique key each time
      orderId: orderId,
    ),
  );
}
```

---

### Solution 3: Proper Context Management

**Problem:** Using stale BuildContext after navigation
**Fix:** Use Navigator.of(context) correctly

```dart
Future<void> cancelOrder(BuildContext context, int orderId) async {
  // Show loading
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => LoadingDialog(key: ValueKey('cancel_$orderId')), // Unique key
  );
  
  try {
    await _orderDataSource.cancelOrder(orderId, reason: 'Merchant cancelled');
    
    // Close loading dialog
    if (context.mounted) {
      Navigator.of(context).pop();
    }
    
    // Show success
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order cancelled successfully')),
      );
    }
    
    // Refresh order list
    refreshOrders();
    
  } catch (e) {
    // Close loading dialog
    if (context.mounted) {
      Navigator.of(context).pop();
    }
    
    // Show error
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel order: $e')),
      );
    }
  }
}
```

---

### Solution 4: Clear Overlay Stack Before Navigation

**Problem:** Lingering overlays in navigation stack
**Fix:** Clear overlays before popping

```dart
void cancelOrderAndGoBack(BuildContext context, int orderId) async {
  try {
    await _orderDataSource.cancelOrder(orderId, reason: 'Cancelled by merchant');
    
    // Clear any overlays
    if (context.mounted) {
      // Pop all dialogs/modals first
      Navigator.of(context).popUntil((route) => route is! DialogRoute);
      
      // Then navigate back
      Navigator.of(context).pop(true); // Pass result if needed
    }
  } catch (e) {
    // Handle error
  }
}
```

---

## 🔍 Debugging Steps

### Step 1: Add Debug Logging
```dart
@override
Widget build(BuildContext context) {
  debugPrint('🏗️ Building CancelOrderDialog for order $orderId');
  return AlertDialog(
    // ... dialog content
  );
}

@override
void dispose() {
  debugPrint('🗑️ Disposing CancelOrderDialog for order $orderId');
  super.dispose();
}
```

### Step 2: Check Widget Inspector
```bash
# In emulator, press 'w' to open Widget Inspector
# Look for duplicate widgets with same GlobalKey
```

### Step 3: Monitor Navigation Stack
```dart
// Add observer to track navigation
class MyNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint('📍 Pushed: ${route.settings.name}');
  }
  
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint('📍 Popped: ${route.settings.name}');
  }
}

// Add to MaterialApp
MaterialApp(
  navigatorObservers: [MyNavigatorObserver()],
  // ...
)
```

---

## 🛠️ Implementation Checklist

### For Merchant App:
- [ ] Find merchant order cancellation code
- [ ] Add guard against duplicate dialogs
- [ ] Use UniqueKey for dynamic dialogs
- [ ] Ensure proper context.mounted checks
- [ ] Clear overlays before navigation
- [ ] Add debug logging
- [ ] Test multiple rapid cancellations
- [ ] Test back button during cancellation
- [ ] Test network errors during cancel

---

## 📝 Common Patterns to Avoid

### ❌ DON'T:
```dart
// Bad: No duplicate check
void onCancelPressed() {
  showDialog(...); // Can be called multiple times
}

// Bad: Using same GlobalKey
final _dialogKey = GlobalKey();
showDialog(builder: (ctx) => MyDialog(key: _dialogKey));

// Bad: Not checking mounted
Navigator.of(context).pop(); // After async operation

// Bad: Nested dialogs without cleanup
showDialog(...); // Dialog 1
  await api.call();
  showDialog(...); // Dialog 2 - duplicate key!
```

### ✅ DO:
```dart
// Good: Guard against duplicates
bool _isDialogShowing = false;
void onCancelPressed() {
  if (_isDialogShowing) return;
  _isDialogShowing = true;
  showDialog(...).then((_) => _isDialogShowing = false);
}

// Good: Unique keys
showDialog(builder: (ctx) => MyDialog(key: UniqueKey()));

// Good: Check mounted
if (context.mounted) Navigator.of(context).pop();

// Good: Sequential dialogs with cleanup
await showDialog(...); // Dialog 1
// Dialog 1 auto-closed before Dialog 2
await showDialog(...); // Dialog 2
```

---

## 🧪 Testing Scenarios

### Test Case 1: Rapid Cancel Clicks
```
1. Open merchant app
2. Navigate to pending order
3. Tap "Cancel" button rapidly 3x
4. ✅ Should show dialog only once
5. ✅ No duplicate key error
```

### Test Case 2: Cancel During Network Call
```
1. Open cancel dialog
2. Confirm cancel
3. While loading, tap back button
4. ✅ Should handle gracefully
5. ✅ No widget tree error
```

### Test Case 3: Cancel with Poor Network
```
1. Enable airplane mode
2. Try to cancel order
3. Wait for timeout
4. ✅ Should show error
5. ✅ Dialog should close properly
```

### Test Case 4: Multiple Orders Cancel
```
1. Open order list
2. Cancel order A
3. Immediately cancel order B
4. ✅ Both should work sequentially
5. ✅ No key conflicts
```

---

## 🔧 Quick Fix (If Can't Find Exact Code)

### Generic Fix for Any Dialog:
```dart
// Add to your app's utilities
class DialogHelper {
  static final Set<String> _activeDialogs = {};
  
  static Future<T?> showDialogOnce<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    String? dialogId,
  }) async {
    final id = dialogId ?? builder.toString();
    
    if (_activeDialogs.contains(id)) {
      debugPrint('⚠️ Dialog $id already showing');
      return null;
    }
    
    _activeDialogs.add(id);
    
    try {
      return await showDialog<T>(
        context: context,
        builder: builder,
      );
    } finally {
      _activeDialogs.remove(id);
    }
  }
}

// Usage:
await DialogHelper.showDialogOnce(
  context: context,
  dialogId: 'cancel_order_$orderId',
  builder: (ctx) => CancelOrderDialog(orderId: orderId),
);
```

---

## 📊 Expected Outcome

### Before Fix:
- ❌ Duplicate GlobalKey error on cancel
- ❌ Red error screen
- ❌ App crash possible
- ❌ Poor user experience

### After Fix:
- ✅ Single cancel dialog shown
- ✅ No duplicate key errors
- ✅ Smooth cancellation flow
- ✅ Proper error handling

---

## 🚀 Deployment Steps

1. **Locate the merchant order cancellation code**
   - Search for "cancel.*order" in merchant files
   - Find dialog/modal widgets
   - Identify navigation patterns

2. **Apply appropriate solution** (Solution 1 recommended)
   - Add duplicate dialog guard
   - Use UniqueKey if needed
   - Ensure context.mounted checks

3. **Test thoroughly**
   - All test scenarios above
   - Real device testing
   - Different network conditions

4. **Monitor production**
   - Track crash rates
   - Monitor error logs
   - User feedback

---

## 📞 Next Steps

Since merchant code wasn't found in open files, you need to:

1. **Find merchant app location**
   ```bash
   # Search for merchant files
   dir /s /b *merchant*.dart
   ```

2. **Locate cancel order code**
   - Look in merchant order detail screen
   - Find cancel button handler
   - Identify dialog/modal widget

3. **Apply fixes from this document**
   - Use Solution 1 (recommended)
   - Add debug logging
   - Test thoroughly

---

---

## ✅ FIX APPLIED (June 28, 2026)

### Files Modified:
- `RIDERSIDE/lib/presentation/widgets/main/merchantside/orders/merchant_order_dialogs.dart`

### Changes Made:

#### 1. Fixed `showMerchantCancelReasonDialog`:
- ✅ Added `_activeDialogs` Set to track open dialogs
- ✅ Added unique dialog ID based on `context.hashCode`
- ✅ Added duplicate dialog guard
- ✅ Set `barrierDismissible: false` to prevent tap-outside dismissal
- ✅ Added `ValueKey` to AlertDialog for unique keys
- ✅ Added try-finally to ensure cleanup

#### 2. Fixed `showMerchantConfirmDialog`:
- ✅ Added unique dialog ID based on `context.hashCode` and `title.hashCode`
- ✅ Added duplicate dialog guard using same `_activeDialogs` Set
- ✅ Set `barrierDismissible: false` to prevent tap-outside dismissal
- ✅ Added `ValueKey` to AlertDialog for unique keys
- ✅ Added try-finally to ensure cleanup
- ✅ Returns `false` if duplicate dialog detected

### Code Pattern Applied:
```dart
// Shared guard across both dialog functions
final Set<String> _activeDialogs = {};

// Each function:
1. Creates unique dialog ID
2. Checks if dialog already active
3. Adds to active set
4. Shows dialog with unique ValueKey
5. Removes from set in finally block
```

### Testing Required:
- [ ] Test rapid cancel button clicks (should show dialog only once)
- [ ] Test cancel during network call
- [ ] Test back button during cancel operation
- [ ] Test multiple different orders in sequence
- [ ] Verify no "Duplicate GlobalKeys" error appears

### Hot Reload Steps:
```bash
# In the running emulator terminal (Terminal ID: 2)
# Press 'r' for hot reload
# OR press 'R' for hot restart if needed
```

---

Last Updated: June 28, 2026 - **FIX COMPLETED**
Priority: HIGH - Affects merchant operations
Status: ✅ READY FOR TESTING
