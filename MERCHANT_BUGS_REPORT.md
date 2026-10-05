# Merchant Side - Critical Bugs & Logic Errors Report

**Generated:** June 16, 2026  
**Severity:** HIGH - Production Ready Fixes Required

---

## 🔴 CRITICAL BUGS (Must Fix)

### BUG #1: Order Status Filter Logic Error
**File:** `merchant_orders_provider.dart:85-104`  
**Severity:** 🔴 CRITICAL  
**Impact:** Orders appear in wrong tabs, merchants can't track lifecycle

**Problem:**
Order filters have overlapping status ranges:
```dart
// CURRENT (BUGGY)
case MerchantOrderFilter.pickUp:
  return status == 'searching_driver' || 
         status == 'accepted' || 
         status == 'ready_for_pickup'; // ← Problem: also in forDelivery

case MerchantOrderFilter.forDelivery:
  return status == 'picked_up' || 
         status == 'in_progress' ||
         status == 'driver_arrived_at_pickup';
```

**Fix:**
```dart
List<OrderDto> _filterOrders(List<OrderDto> orders, MerchantOrderFilter filter) {
  if (filter == MerchantOrderFilter.all) return orders;

  return orders.where((order) {
    final status = order.status.toLowerCase();
    switch (filter) {
      case MerchantOrderFilter.pending:
        return status == 'pending';
      
      case MerchantOrderFilter.pickUp:
        // Orders waiting for pickup (after driver accepted, before pickup)
        return status == 'searching_driver' || 
               status == 'accepted';
      
      case MerchantOrderFilter.ready:
        // Ready and waiting for driver
        return status == 'ready_for_pickup';
      
      case MerchantOrderFilter.forDelivery:
        // Orders picked up by driver
        return status == 'picked_up' || 
               status == 'in_progress' ||
               status == 'driver_arrived_at_pickup';
      
      case MerchantOrderFilter.completed:
        return status == 'completed';
      
      case MerchantOrderFilter.cancelled:
        return status == 'cancelled';
      
      case MerchantOrderFilter.all:
        return true;
    }
  }).toList();
}
```

---

### BUG #2: Wallet Balance Not Persisting After TopUp
**File:** `merchant_wallet_provider.dart:100-116`  
**Severity:** 🔴 CRITICAL  
**Impact:** Duplicate charges, wallet balance not updating

**Problem:**
The `completeTopUp()` method sends redundant request and doesn't verify response:
```dart
// CURRENT (BUGGY)
Future<bool> completeTopUp(MerchantTopUpCheckout checkout) async {
  await ApiService.dio.post('/v1/wallets/my/topup', data: {
    'amount': checkout.walletAmount,
    'payment_method': 'xendit',
    'xendit_invoice_id': checkout.invoiceId,
  });
  
  await loadWallet(); // Doesn't verify response
  return true;
}
```

**Fix:**
```dart
Future<bool> completeTopUp(MerchantTopUpCheckout checkout) async {
  try {
    final response = await ApiService.dio.post(
      '/v1/wallets/my/topup/confirm', // Different endpoint - just confirm
      data: {
        'xendit_invoice_id': checkout.invoiceId, // Only confirm payment
        'amount': checkout.walletAmount,
      },
    );

    // Verify response contains updated balance
    final data = response.data as Map<String, dynamic>?;
    if (data == null || data['success'] != true) {
      throw Exception('TopUp confirmation failed');
    }

    // Update state with new balance
    final newBalance = data['wallet_balance'] as num?;
    if (newBalance == null) {
      // Fallback: reload wallet from API
      await loadWallet();
    } else {
      // Direct update to avoid extra API call
      state = (state as AsyncValue<MerchantWallet>).whenData((wallet) {
        return wallet.copyWith(availableBalance: newBalance.toDouble());
      });
    }

    return true;
  } catch (e, stack) {
    debugPrint('Complete topup failed: $e');
    state = AsyncValue.error(e, stack);
    return false;
  }
}
```

---

### BUG #3: Earnings Calculation Includes Non-Completed Orders
**File:** `merchant_earnings_provider.dart:87-97`  
**Severity:** 🔴 CRITICAL  
**Impact:** Incorrect financial reporting, merchants overestimate earnings

**Problem:**
Pending earnings includes orders that might get cancelled:
```dart
// CURRENT (BUGGY)
for (final order in orders) {
  if (MerchantOrderAmountUtils.isPendingEarnings(order)) {
    pendingEarnings += amount; // Includes non-finalized orders!
    pendingOrders += 1;
  }
}
```

**isPendingEarnings()** status includes:
- pending, searching_driver, accepted, ready_for_pickup, picked_up, in_progress, driver_arrived_at_pickup

**Fix:**
```dart
// Create separate method for truly finalized earnings
static bool isFinalizedEarnings(OrderDto order) {
  final status = order.status.toLowerCase();
  return status == 'completed' && !order.isCancelled;
}

// Pending earnings are only orders with driver picked up
static bool isPendingEarnings(OrderDto order) {
  final status = order.status.toLowerCase();
  return (status == 'picked_up' || 
          status == 'in_progress' ||
          status == 'driver_arrived_at_pickup') &&
         !order.isCancelled;
}

// Update provider
for (final order in orders) {
  final amount = MerchantOrderAmountUtils.getEarnings(order);
  
  // Only count completed earnings
  if (MerchantOrderAmountUtils.isFinalizedEarnings(order)) {
    completedEarnings += amount;
    completedOrders += 1;
  }
  // Pending only for picked up orders
  else if (MerchantOrderAmountUtils.isPendingEarnings(order)) {
    pendingEarnings += amount;
    pendingOrders += 1;
  }
}
```

---

### BUG #4: Wallet Transactions Sorted Incorrectly
**File:** `merchant_wallet_provider.dart:138-145`  
**Severity:** 🟡 HIGH  
**Impact:** Transactions appear out of order

**Problem:**
String comparison instead of date parsing:
```dart
// CURRENT (BUGGY)
items.sort((a, b) {
  final aDate = a['created_at']?.toString() ?? '';
  final bDate = b['created_at']?.toString() ?? '';
  return bDate.compareTo(aDate); // String comparison!
});
```

**Fix:**
```dart
items.sort((a, b) {
  try {
    final aDate = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime(2000);
    final bDate = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime(2000);
    return bDate.compareTo(aDate); // Proper date comparison
  } catch (e) {
    debugPrint('Error sorting transactions: $e');
    return 0;
  }
});
```

---

### BUG #5: Menu Item Form - Missing Null Safety
**File:** `merchant_menu_item_form_provider.dart:244-265`  
**Severity:** 🟡 HIGH  
**Impact:** App crashes when creating menu items if partnerId is null

**Problem:**
No validation before API call:
```dart
// CURRENT (BUGGY)
final authState = _ref.read(riderAuthProvider);
final profile = _ref.read(merchantProfileProvider).value;
final partnerId = authState.user?.partnerId ?? profile?.id;

if (partnerId == null) {
  // Check exists but...
}

// Later: this can crash
dataSource.createMenuItem(partnerId, request); // partnerId might still be null
```

**Fix:**
```dart
Future<void> submitForm() async {
  try {
    state = const AsyncValue.loading();

    // Get partnerId with fallback
    final authState = _ref.read(riderAuthProvider);
    var partnerId = authState.user?.partnerId;
    
    // Try profile if not in auth
    if (partnerId == null) {
      final profile = _ref.read(merchantProfileProvider).value;
      partnerId = profile?.id;
    }

    // Validate partnerId exists
    if (partnerId == null) {
      throw Exception('Partner ID not found. Please log in again.');
    }

    // Validate form state
    final currentForm = state.valueOrNull;
    if (currentForm == null) {
      throw Exception('Form is not initialized');
    }

    // Create request from form
    final request = _buildRequest(currentForm);
    if (!request.isValid()) {
      throw Exception('Please fill all required fields');
    }

    // API call with valid partnerId
    final result = await dataSource.createMenuItem(partnerId, request);
    
    state = AsyncValue.data(result);
  } catch (e, stack) {
    debugPrint('Menu item creation failed: $e');
    state = AsyncValue.error(e, stack);
  }
}
```

---

### BUG #6: Analytics - Active Orders Counted Incorrectly
**File:** `merchant_analytics_provider.dart:131-148`  
**Severity:** 🟡 HIGH  
**Impact:** Dashboard shows wrong active order count

**Problem:**
Active orders only incremented in else clause:
```dart
// CURRENT (BUGGY)
if (MerchantOrderAmountUtils.isCompleted(order)) {
  completedOrders += 1;
} else if (MerchantOrderAmountUtils.isCancelled(order)) {
  cancelledOrders += 1;
} else {
  activeOrders += 1; // Only if NOT completed/cancelled
}
// But what about orders in "ready_for_pickup" state?
```

**Fix:**
```dart
for (final order in orders) {
  final status = order.status.toLowerCase();
  
  if (MerchantOrderAmountUtils.isCompleted(order)) {
    completedOrders += 1;
    totalRevenue += getEarnings(order);
  } else if (MerchantOrderAmountUtils.isCancelled(order)) {
    cancelledOrders += 1;
  } else {
    // All non-terminal states are active
    activeOrders += 1;
    
    // Separately track prep and delivery
    if (status == 'pending' || status == 'accepted' || status == 'ready_for_pickup') {
      itemsInPrep += 1;
    } else if (status == 'picked_up' || status == 'in_progress') {
      itemsInDelivery += 1;
    }
  }
}
```

---

### BUG #7: Prep Timer - Overdue Status Lost on Reload
**File:** `merchant_prep_timer_provider.dart:89-112`  
**Severity:** 🟡 MEDIUM  
**Impact:** No feedback if prep exceeded time estimate

**Problem:**
Timer removed once order moves from "accepted" to "picked_up":
```dart
// CURRENT (BUGGY)
for (final order in orders) {
  if (!MerchantOrderOpsUtils.showsPrepTimer(order.status)) continue;
  activePrepIds.add(order.id);
}
// Once picked_up, timer is gone - no historical view
```

**Fix:**
```dart
Future<void> syncWithOrders(List<OrderDto> orders) async {
  final activePrepIds = <int>{};

  for (final order in orders) {
    final status = order.status.toLowerCase();
    
    // Keep timer for prep and ready states
    if (status == 'pending' || 
        status == 'accepted' || 
        status == 'ready_for_pickup') {
      activePrepIds.add(order.id);
    }
  }

  // Remove timers for orders no longer prepping
  final next = Map<int, MerchantPrepTimerEntry>.from(state);
  next.removeWhere((orderId, _) => !activePrepIds.contains(orderId));

  if (next.length != state.length) {
    state = next;
    await _persist();
    
    // Log overdue preps for analytics
    for (final removed in state.keys.where((id) => !next.containsKey(id))) {
      final timer = state[removed];
      if (timer != null && timer.isOverdue()) {
        debugPrint('Order $removed prep exceeded ${timer.durationMinutes} minutes');
        // Could send to analytics
      }
    }
  }
}

// Add helper method
extension on MerchantPrepTimerEntry {
  bool isOverdue() {
    final elapsed = DateTime.now().difference(startedAt).inMinutes;
    return elapsed > durationMinutes;
  }
}
```

---

### BUG #8: Missing Provider Reference Error Handling
**File:** Multiple providers  
**Severity:** 🟡 MEDIUM  
**Impact:** Cascading failures if data source initialization fails

**Problem:**
Providers depend on `merchantDataSourceProvider` without error handling:
```dart
// CURRENT (BUGGY) - Multiple providers
final ordersAsync = ref.watch(merchantOrdersProvider);
// If merchantDataSourceProvider init fails, this cascades
```

**Fix:**
```dart
// Create wrapper provider with error handling
final merchantOrdersProvider = FutureProvider<List<OrderDto>>((ref) async {
  try {
    final dataSource = ref.watch(merchantDataSourceProvider);
    return await dataSource.getOrders();
  } catch (e) {
    debugPrint('Failed to load merchant orders: $e');
    // Return empty list instead of crashing
    return [];
  }
});

// Add error boundary widget
class MerchantOrdersErrorBoundary extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(merchantOrdersProvider).when(
      data: (orders) => MerchantOrdersList(orders: orders),
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) {
        debugPrintStack(stackTrace: stack);
        return MerchantErrorUI(
          title: 'Could not load orders',
          error: error.toString(),
          onRetry: () => ref.refresh(merchantOrdersProvider),
        );
      },
    );
  }
}
```

---

## 🟡 ADDITIONAL ISSUES

### Issue #9: Auth Session Restoration - Expired Token Check Missing
**File:** `rider_auth_provider.dart:102-108`  
**Severity:** 🟡 HIGH

**Problem:**
Token expiry not checked when restoring session:
```dart
// CURRENT (BUGGY)
Future<void> _restoreWithStoredTokens() async {
  final tokens = await SecureStorageService.getTokens();
  if (tokens == null) return;
  
  // Doesn't check if tokens are expired!
  state = AsyncValue.data(RiderUser.fromTokens(tokens));
  await RememberMeService.refreshExpiry();
}
```

**Fix:**
```dart
Future<void> _restoreWithStoredTokens() async {
  try {
    final tokens = await SecureStorageService.getTokens();
    if (tokens == null) {
      state = const AsyncValue.data(RiderUser.anonymous());
      return;
    }
    
    // Check token expiry
    if (tokens.isExpired()) {
      // Try refresh
      final refreshed = await _refreshTokens(tokens);
      if (refreshed == null) {
        state = const AsyncValue.data(RiderUser.anonymous());
        return;
      }
      
      await SecureStorageService.saveTokens(refreshed);
      tokens = refreshed;
    }
    
    state = AsyncValue.data(RiderUser.fromTokens(tokens));
    await RememberMeService.refreshExpiry();
  } catch (e) {
    debugPrint('Session restoration failed: $e');
    state = const AsyncValue.data(RiderUser.anonymous());
  }
}
```

---

### Issue #10: Review Dashboard Stats - Stale Fallback Data
**File:** `merchant_reviews_provider.dart:56-71`  
**Severity:** 🟡 MEDIUM

**Problem:**
Falls back to profile stats that might be stale:
```dart
// CURRENT (BUGGY)
final rating = reviewsAsync.maybeWhen(
  data: (dashboard) => dashboard.statistics.averageRating,
  orElse: () => profile?.rating ?? 0, // Stale data from app startup
);
```

**Fix:**
```dart
// Track last fetch time
final lastReviewsFetchProvider = StateProvider<DateTime?>((ref) => null);

final merchantReviewsDashboardProvider = FutureProvider<MerchantReviewsDashboard>((ref) async {
  final lastFetch = ref.watch(lastReviewsFetchProvider);
  final shouldRefresh = lastFetch == null || 
      DateTime.now().difference(lastFetch).inMinutes > 5;

  if (!shouldRefresh) {
    return ref.watch(merchantReviewsProvider).valueOrNull ??
        throw Exception('No cached data available');
  }

  final dataSource = ref.watch(merchantDataSourceProvider);
  final dashboard = await dataSource.getReviewsDashboard();
  
  // Update last fetch time
  ref.read(lastReviewsFetchProvider.notifier).state = DateTime.now();
  
  return dashboard;
});
```

---

## 📋 FIXES SUMMARY

| Bug # | File | Severity | Status | Fix Required |
|-------|------|----------|--------|--------------|
| 1 | merchant_orders_provider.dart | 🔴 CRITICAL | Unfixed | Refactor filter logic |
| 2 | merchant_wallet_provider.dart | 🔴 CRITICAL | Unfixed | Add response verification |
| 3 | merchant_earnings_provider.dart | 🔴 CRITICAL | Unfixed | Separate pending vs finalized |
| 4 | merchant_wallet_provider.dart | 🟡 HIGH | Unfixed | Parse dates properly |
| 5 | merchant_menu_item_form_provider.dart | 🟡 HIGH | Unfixed | Add null validation |
| 6 | merchant_analytics_provider.dart | 🟡 HIGH | Unfixed | Fix active order counting |
| 7 | merchant_prep_timer_provider.dart | 🟡 MEDIUM | Unfixed | Keep timer history |
| 8 | Multiple providers | 🟡 MEDIUM | Unfixed | Add error boundaries |
| 9 | rider_auth_provider.dart | 🟡 HIGH | Unfixed | Check token expiry |
| 10 | merchant_reviews_provider.dart | 🟡 MEDIUM | Unfixed | Cache management |

---

## 🚀 IMPLEMENTATION PRIORITY

**Phase 1 (CRITICAL - This Sprint):**
1. Fix Bug #1 - Order filter logic
2. Fix Bug #2 - Wallet topup verification
3. Fix Bug #3 - Earnings calculation
4. Fix Bug #9 - Token expiry check

**Phase 2 (HIGH - Next Sprint):**
5. Fix Bug #4 - Transaction sorting
6. Fix Bug #5 - Menu item form validation
7. Fix Bug #6 - Analytics counting

**Phase 3 (MEDIUM - Future):**
8. Fix Bug #7 - Prep timer history
9. Fix Bug #8 - Error boundaries
10. Fix Bug #10 - Cache management

---

**Generated:** June 16, 2026  
**Status:** Ready for Development
