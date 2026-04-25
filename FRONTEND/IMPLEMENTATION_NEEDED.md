# 🚀 ACTUAL IMPLEMENTATION NEEDED

**Date:** April 16, 2026  
**Status:** DataSources created, need Provider & Screen integration

---

## ✅ WHAT'S DONE (DataSource Layer)

### Already Integrated:
1. ✅ **AuthRemoteDataSource** - 7 auth endpoints
2. ✅ **OrderManagementRemoteDataSource** - 10 order endpoints
3. ✅ **PaymentGatewayRemoteDataSource** - 8 payment endpoints
4. ✅ **AddressRemoteDataSource** - Address management
5. ✅ **ServiceRemoteDataSource** - Services
6. ✅ **PartnerRemoteDataSource** - Partners & branches
7. ✅ **ReviewRemoteDataSource** - Reviews
8. ✅ **WalletRemoteDataSource** - Wallet
9. ✅ **NotificationRemoteDataSource** - Notifications
10. ✅ **TrackingRemoteDataSource** - Driver tracking
11. ✅ **DistanceRemoteDataSource** - Distance calculation
12. ✅ **GeofenceRemoteDataSource** - Service area checking
13. ✅ **SecurityRemoteDataSource** - Security features
14. ✅ **SocialRemoteDataSource** - Social/referrals
15. ✅ **FaqRemoteDataSource** - FAQ system
16. ✅ **SupportRemoteDataSource** - Support tickets
17. ✅ **ChatRemoteDataSource** - Chat messages
18. ✅ **VoucherRemoteDataSource** - Vouchers
19. ✅ **GatewayRemoteDataSource** - Payment gateway
20. ✅ **OrderRemoteDataSource** - Orders (old)
21. ✅ **UserRemoteDataSource** - Users

**Total: 107 endpoints integrated at DataSource level**

---

## ❌ WHAT'S MISSING (Provider & Screen Integration)

### 1. AUTH SCREENS (CRITICAL) 🔥

#### Login Screen
**File:** `lib/presentation/screens/auth/login_screen.dart`  
**Current:** Uses old UserRemoteDataSource  
**Needs:**
- [ ] Update AuthProvider to use AuthRemoteDataSource
- [ ] Implement actual login API call
- [ ] Save token to SharedPreferences
- [ ] Navigate to home on success
- [ ] Show error messages

**Implementation:**
```dart
// In AuthProvider
Future<void> login(String email, String password) async {
  state = state.copyWith(isLoading: true);
  
  try {
    final request = LoginRequestDto(
      email: email,
      password: password,
    );
    
    final response = await _authDataSource.login(request);
    
    // Save token
    await _localStorage.saveToken(response.token!);
    
    state = state.copyWith(
      isLoading: false,
      user: response.user,
      token: response.token,
    );
  } catch (e) {
    state = state.copyWith(
      isLoading: false,
      error: e.toString(),
    );
  }
}
```

#### Register Screen
**File:** `lib/presentation/screens/auth/register_screen.dart`  
**Current:** No API integration  
**Needs:**
- [ ] Update RegisterProvider to use AuthRemoteDataSource
- [ ] Implement actual register API call
- [ ] Send all form data (name, email, password, phone, address)
- [ ] Save token on success
- [ ] Navigate to success screen

**Implementation:**
```dart
// In RegisterProvider
Future<void> register() async {
  state = state.copyWith(isLoading: true);
  
  try {
    final request = RegisterRequestDto(
      name: '${data.firstName} ${data.lastName}',
      email: data.email,
      phoneNumber: data.phoneNumber,
      password: data.password,
      passwordConfirmation: data.password,
      referredBy: data.referralCode,
    );
    
    final response = await _authDataSource.register(request);
    
    // Save token
    await _localStorage.saveToken(response.token!);
    
    state = state.copyWith(
      isLoading: false,
      registeredUser: response.user,
    );
  } catch (e) {
    state = state.copyWith(
      isLoading: false,
      error: e.toString(),
    );
  }
}
```

---

### 2. BOOKING SCREENS (CRITICAL) 🔥

#### LesGo Screen
**File:** `lib/presentation/provider/main/booking/lesgo_provider.dart`  
**Current:** Mock data  
**Needs:**
- [ ] Integrate OrderManagementRemoteDataSource
- [ ] Implement createOrder() with real API
- [ ] Implement estimateOrderFare() before creating order
- [ ] Validate wallet balance before order
- [ ] Show real-time order tracking

**Implementation:**
```dart
// In LesgoProvider
Future<void> createDeliveryOrder() async {
  state = state.copyWith(isLoading: true);
  
  try {
    // 1. Estimate fare first
    final estimate = await _orderDataSource.estimateOrderFare(token, {
      'service_id': 1, // LesGo
      'pickup_latitude': pickupLocation.latitude,
      'pickup_longitude': pickupLocation.longitude,
      'dropoff_latitude': dropoffLocation.latitude,
      'dropoff_longitude': dropoffLocation.longitude,
    });
    
    // 2. Validate wallet
    final validation = await _paymentDataSource.validateWalletBalance(token);
    if (validation.needsTopup) {
      throw Exception('Insufficient wallet balance');
    }
    
    // 3. Create order
    final request = CreateOrderRequestDto(
      serviceId: 1,
      pickupAddress: pickupAddress,
      pickupLatitude: pickupLocation.latitude,
      pickupLongitude: pickupLocation.longitude,
      dropoffAddress: dropoffAddress,
      dropoffLatitude: dropoffLocation.latitude,
      dropoffLongitude: dropoffLocation.longitude,
      notes: notes,
      paymentMethod: 'wallet',
      estimatedFare: estimate['estimated_fare'],
    );
    
    final response = await _orderDataSource.createOrder(token, request);
    
    state = state.copyWith(
      isLoading: false,
      currentOrder: response.order,
    );
  } catch (e) {
    state = state.copyWith(
      isLoading: false,
      error: e.toString(),
    );
  }
}
```

#### LesEat Checkout Screen
**File:** `lib/presentation/provider/main/booking/checkout_provider.dart`  
**Current:** Mock data  
**Needs:**
- [ ] Integrate OrderManagementRemoteDataSource
- [ ] Implement createOrder() with items
- [ ] Integrate PaymentGatewayRemoteDataSource
- [ ] Create payment invoice if needed
- [ ] Record payment after success

**Implementation:**
```dart
// In CheckoutProvider
Future<void> createFoodOrder() async {
  state = state.copyWith(isLoading: true);
  
  try {
    // 1. Create order with items
    final request = CreateOrderRequestDto(
      serviceId: 2, // LesEat
      partnerId: restaurant.id,
      branchId: branch.id,
      dropoffAddress: deliveryAddress,
      dropoffLatitude: location.latitude,
      dropoffLongitude: location.longitude,
      notes: notes,
      paymentMethod: paymentMethod,
      items: cartItems.map((item) => OrderItemDto(
        productName: item.name,
        quantity: item.quantity,
        price: item.price,
        notes: item.notes,
      )).toList(),
    );
    
    final response = await _orderDataSource.createOrder(token, request);
    
    // 2. If payment method is not wallet, create invoice
    if (paymentMethod != 'wallet') {
      final invoiceRequest = InvoiceRequestDto(
        amount: totalAmount,
        description: 'Order #${response.order!.id}',
        paymentMethod: paymentMethod,
      );
      
      final invoice = await _paymentDataSource.createInvoice(token, invoiceRequest);
      
      // Open payment URL
      if (invoice.invoice?.paymentUrl != null) {
        // Launch payment URL
      }
    }
    
    state = state.copyWith(
      isLoading: false,
      order: response.order,
    );
  } catch (e) {
    state = state.copyWith(
      isLoading: false,
      error: e.toString(),
    );
  }
}
```

#### LesBuy Screen
**File:** `lib/presentation/provider/main/booking/lesbuy/manual_order_provider.dart`  
**Current:** Mock data  
**Needs:**
- [ ] Integrate OrderManagementRemoteDataSource
- [ ] Implement createOrder() with shopping items
- [ ] Same payment flow as LesEat

#### LesRide Screen
**File:** `lib/presentation/provider/main/booking/lesride_provider.dart`  
**Current:** Mock data  
**Needs:**
- [ ] Integrate OrderManagementRemoteDataSource
- [ ] Implement estimateOrderFare()
- [ ] Implement createOrder() for ride

#### LesPort Screen
**File:** `lib/presentation/provider/main/booking/lesport_provider.dart`  
**Current:** Mock data  
**Needs:**
- [ ] Integrate OrderManagementRemoteDataSource
- [ ] Implement estimateOrderFare()
- [ ] Implement createOrder() for transport

---

### 3. LESPAY SCREEN (CRITICAL) 🔥

**File:** `lib/presentation/provider/main/lespay/lespay_provider.dart`  
**Current:** Mock data  
**Needs:**
- [ ] Integrate PaymentGatewayRemoteDataSource
- [ ] Implement validateWalletBalance()
- [ ] Implement getWalletThreshold()
- [ ] Implement createInvoice() for top-up
- [ ] Implement checkInvoiceStatus()
- [ ] Poll invoice status after payment

**Implementation:**
```dart
// In LespayProvider
Future<void> validateWallet() async {
  try {
    final validation = await _paymentDataSource.validateWalletBalance(token);
    
    state = state.copyWith(
      currentBalance: validation.currentBalance,
      minimumThreshold: validation.minimumThreshold,
      needsTopup: validation.needsTopup,
    );
  } catch (e) {
    state = state.copyWith(error: e.toString());
  }
}

Future<void> topUpWallet(double amount, String paymentMethod) async {
  state = state.copyWith(isLoading: true);
  
  try {
    final request = InvoiceRequestDto(
      amount: amount,
      description: 'Wallet Top-up',
      paymentMethod: paymentMethod,
    );
    
    final response = await _paymentDataSource.createInvoice(token, request);
    
    if (response.invoice?.paymentUrl != null) {
      // Launch payment URL
      // Then poll for status
      await _pollInvoiceStatus(response.invoice!.id);
    }
    
    state = state.copyWith(isLoading: false);
  } catch (e) {
    state = state.copyWith(
      isLoading: false,
      error: e.toString(),
    );
  }
}

Future<void> _pollInvoiceStatus(int invoiceId) async {
  for (int i = 0; i < 60; i++) {
    await Future.delayed(Duration(seconds: 2));
    
    final invoice = await _paymentDataSource.getInvoiceStatus(
      token,
      invoiceId.toString(),
    );
    
    if (invoice.invoice?.status == 'paid') {
      // Success! Refresh wallet balance
      await validateWallet();
      break;
    } else if (invoice.invoice?.status == 'expired' || 
               invoice.invoice?.status == 'cancelled') {
      throw Exception('Payment ${invoice.invoice?.status}');
    }
  }
}
```

---

### 4. TRANSACTIONS SCREEN (HIGH PRIORITY)

**File:** `lib/presentation/provider/main/transactions/transactions_provider.dart`  
**Current:** Mock data  
**Needs:**
- [ ] Integrate OrderManagementRemoteDataSource
- [ ] Implement getOrders() with filters
- [ ] Implement getOrderDetails()
- [ ] Implement getOrderReceipt()
- [ ] Integrate PaymentGatewayRemoteDataSource
- [ ] Implement getPaymentHistory()
- [ ] Implement getPaymentDetails()

**Implementation:**
```dart
// In TransactionsProvider
Future<void> loadOrders({String? status}) async {
  state = state.copyWith(isLoading: true);
  
  try {
    final response = await _orderDataSource.getOrders(
      token,
      status: status,
      page: currentPage,
      perPage: 20,
    );
    
    state = state.copyWith(
      isLoading: false,
      orders: response.orders ?? [],
      pagination: response.pagination,
    );
  } catch (e) {
    state = state.copyWith(
      isLoading: false,
      error: e.toString(),
    );
  }
}

Future<void> loadOrderDetails(int orderId) async {
  try {
    final order = await _orderDataSource.getOrderDetails(token, orderId);
    
    state = state.copyWith(selectedOrder: order);
  } catch (e) {
    state = state.copyWith(error: e.toString());
  }
}

Future<void> loadPaymentHistory() async {
  try {
    final history = await _paymentDataSource.getPaymentHistory(
      token,
      page: currentPage,
      perPage: 20,
    );
    
    state = state.copyWith(payments: history['payments']);
  } catch (e) {
    state = state.copyWith(error: e.toString());
  }
}
```

---

### 5. PROFILE SCREEN (MEDIUM PRIORITY)

**File:** `lib/presentation/provider/main/profile/profile_provider.dart`  
**Current:** Mock data  
**Needs:**
- [ ] Integrate AuthRemoteDataSource
- [ ] Implement getMe() to load profile
- [ ] Implement updateMe() to update profile
- [ ] Implement logout()
- [ ] Implement logoutAll()

**Implementation:**
```dart
// In ProfileProvider
Future<void> loadProfile() async {
  try {
    final user = await _authDataSource.getMe(token);
    
    state = state.copyWith(user: user);
  } catch (e) {
    state = state.copyWith(error: e.toString());
  }
}

Future<void> updateProfile(Map<String, dynamic> data) async {
  state = state.copyWith(isLoading: true);
  
  try {
    final user = await _authDataSource.updateMe(token, data);
    
    state = state.copyWith(
      isLoading: false,
      user: user,
    );
  } catch (e) {
    state = state.copyWith(
      isLoading: false,
      error: e.toString(),
    );
  }
}

Future<void> logout() async {
  try {
    await _authDataSource.logout(token);
    await _localStorage.clearToken();
    
    // Navigate to login
  } catch (e) {
    state = state.copyWith(error: e.toString());
  }
}
```

---

### 6. FAQ SCREEN (MEDIUM PRIORITY)

**File:** `lib/presentation/provider/main/faq/faq_provider.dart`  
**Current:** Uses FaqRemoteDataSource ✅  
**Status:** Already integrated! Just needs testing

---

### 7. HOME SCREEN (MEDIUM PRIORITY)

**File:** `lib/presentation/screens/main/home_screen.dart`  
**Needs:**
- [ ] Load active orders
- [ ] Load wallet balance
- [ ] Load notification count
- [ ] Show recent orders

---

## 📋 IMPLEMENTATION PRIORITY

### Phase 1: Auth (CRITICAL) 🔥
**Time:** 1-2 hours  
**Impact:** Users can login/register

1. [ ] Update AuthProvider to use AuthRemoteDataSource
2. [ ] Implement login with token storage
3. [ ] Implement register with token storage
4. [ ] Add auto-login on app start
5. [ ] Test login/register flow

### Phase 2: Order Creation (CRITICAL) 🔥
**Time:** 2-3 hours  
**Impact:** Users can create orders

1. [ ] Update LesgoProvider with OrderManagementRemoteDataSource
2. [ ] Implement createOrder() in all booking providers
3. [ ] Implement estimateOrderFare()
4. [ ] Add wallet validation before order
5. [ ] Test order creation flow

### Phase 3: Payment (CRITICAL) 🔥
**Time:** 2-3 hours  
**Impact:** Users can pay for orders

1. [ ] Update LespayProvider with PaymentGatewayRemoteDataSource
2. [ ] Implement wallet validation
3. [ ] Implement invoice creation
4. [ ] Implement invoice status polling
5. [ ] Test payment flow

### Phase 4: Transactions (HIGH PRIORITY)
**Time:** 1-2 hours  
**Impact:** Users can view history

1. [ ] Update TransactionsProvider
2. [ ] Implement order history
3. [ ] Implement payment history
4. [ ] Implement order details
5. [ ] Test transactions screen

### Phase 5: Profile (MEDIUM PRIORITY)
**Time:** 1 hour  
**Impact:** Users can manage profile

1. [ ] Update ProfileProvider
2. [ ] Implement profile loading
3. [ ] Implement profile update
4. [ ] Implement logout
5. [ ] Test profile screen

---

## 🎯 TOTAL WORK REMAINING

### Critical (Must Do):
- **Auth:** 2 screens (Login, Register)
- **Booking:** 5 screens (LesGo, LesEat, LesBuy, LesRide, LesPort)
- **Payment:** 1 screen (LesPay)

### High Priority (Should Do):
- **Transactions:** 1 screen
- **Profile:** 1 screen

### Medium Priority (Nice to Have):
- **Home:** Dashboard integration
- **Notifications:** Badge counts

---

## 📊 SUMMARY

### What's Done:
- ✅ 107 endpoints integrated at DataSource level
- ✅ All DTOs with JSON serialization
- ✅ All remote data sources created
- ✅ Zero compilation errors

### What's Needed:
- ❌ Provider integration (connect DataSources to Providers)
- ❌ Screen integration (use Providers in UI)
- ❌ Token management (save/load/clear)
- ❌ Error handling (show user-friendly messages)
- ❌ Loading states (show spinners)
- ❌ Navigation (after success/error)

### Estimated Time:
- **Phase 1 (Auth):** 2 hours
- **Phase 2 (Orders):** 3 hours
- **Phase 3 (Payment):** 3 hours
- **Phase 4 (Transactions):** 2 hours
- **Phase 5 (Profile):** 1 hour
- **Total:** ~11 hours of focused work

---

## 🚀 NEXT STEPS

1. **Start with Auth** - Most critical, blocks everything else
2. **Then Orders** - Core functionality
3. **Then Payment** - Complete the flow
4. **Then Transactions** - User can see history
5. **Finally Profile** - User can manage account

**Gusto mo bang simulan ko na ang implementation?** 🎯
