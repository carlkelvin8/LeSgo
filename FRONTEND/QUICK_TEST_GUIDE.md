# Quick Test Guide - LeSGo App

**Purpose:** Verify all booking providers are working with real APIs

---

## 🧪 TEST 1: LesGo Delivery

**Provider:** `LesgoProvider`  
**Service ID:** 1

### Steps:
1. Open LesGo booking screen
2. Select pickup location
3. Select destination
4. Wait for fare estimate (should show real price from API)
5. Select payment method
6. Click "Book Now"
7. **Expected:** Order created successfully with order ID

### What to Check:
- ✅ Fare estimate loads from API
- ✅ Wallet validation works (if wallet selected)
- ✅ Order creation returns order ID
- ✅ Success message shows
- ✅ Can track order

---

## 🧪 TEST 2: LesRide

**Provider:** `LesrideProvider`  
**Service ID:** 2

### Steps:
1. Open LesRide booking screen
2. Select pickup location
3. Select destination
4. Select payment method
5. Click "Book Ride"
6. **Expected:** Ride booked successfully

### What to Check:
- ✅ Route displays on map
- ✅ Distance calculated
- ✅ Order created via API
- ✅ Success dialog shows

---

## 🧪 TEST 3: LesEat

**Provider:** `LesEatProvider` + `CheckoutProvider`  
**Service ID:** 3

### Steps:
1. Open LesEat screen
2. **Expected:** See real restaurants from API (Jollibee, Mang Inasal, etc.)
3. Select a restaurant
4. Add items to cart
5. Go to checkout
6. Apply voucher (optional)
7. Select delivery address
8. Select payment method
9. Place order
10. **Expected:** Order created successfully

### What to Check:
- ✅ Restaurants load from API
- ✅ Menu items load
- ✅ Voucher validation works
- ✅ Delivery fee calculated
- ✅ Order created via API

---

## 🧪 TEST 4: LesBuy Manual Order

**Provider:** `ManualOrderProvider`  
**Service ID:** 4

### Steps:
1. Open LesBuy screen
2. Select "Manual Order"
3. Add items to list:
   - Item name: "Rice 5kg"
   - Quantity: 2
4. Add more items
5. Confirm items
6. Enter delivery address
7. Select payment method
8. Create order
9. **Expected:** Order created successfully

### What to Check:
- ✅ Items added to list
- ✅ Wallet validation works
- ✅ Order created via API
- ✅ Success message shows

---

## 🧪 TEST 5: LesBuy Store Order

**Provider:** `StoreDetailProvider` + `CheckoutProvider`  
**Service ID:** 4

### Steps:
1. Open LesBuy screen
2. Select a store (Mercury Drug, National Bookstore, etc.)
3. **Expected:** See products from API
4. Add products to cart
5. Go to checkout
6. Place order
7. **Expected:** Order created successfully

### What to Check:
- ✅ Stores load from API
- ✅ Products load from API
- ✅ Cart management works
- ✅ Order created via API

---

## 🧪 TEST 6: LesTransport (LesPort)

**Provider:** `LesTransportProvider`  
**Service ID:** 5

### Steps:
1. Open LesPort screen
2. Enter sender details
3. Select delivery method
4. Enter addresses
5. Book transport
6. **Expected:** Transport booked successfully

### What to Check:
- ✅ Form validation works
- ✅ Order created via API
- ✅ Success message shows

---

## 🧪 TEST 7: Wallet Validation

**Test insufficient balance:**

### Steps:
1. Select "Wallet" as payment method
2. Try to book any service
3. **Expected:** If balance is low, show error message
4. **Expected:** If balance is sufficient, order proceeds

### What to Check:
- ✅ Wallet validation called before order
- ✅ Error message shows if insufficient
- ✅ Order proceeds if sufficient

---

## 🧪 TEST 8: Transactions

**Provider:** `TransactionsProvider`

### Steps:
1. Open Transactions screen
2. **Expected:** See orders from API
3. Switch tabs (Orders, Payments, Wallet)
4. **Expected:** Each tab shows real data

### What to Check:
- ✅ Orders load from API
- ✅ Payments load from API
- ✅ Wallet transactions load from API

---

## 🧪 TEST 9: Profile

**Provider:** `ProfileProvider`

### Steps:
1. Open Profile screen
2. **Expected:** See user data from API
3. Edit profile
4. Save changes
5. **Expected:** Profile updated successfully

### What to Check:
- ✅ Profile loads from API
- ✅ Profile updates via API
- ✅ Success message shows

---

## 🔍 DEBUGGING TIPS

### If order creation fails:

1. **Check token:**
   ```dart
   final token = localStorage.token;
   print('Token: $token');
   ```

2. **Check API response:**
   ```dart
   print('API Response: ${response.toJson()}');
   ```

3. **Check error message:**
   ```dart
   print('Error: ${e.toString()}');
   ```

### Common Issues:

1. **"Please login to create an order"**
   - Token is null or expired
   - Solution: Login again

2. **"Insufficient wallet balance"**
   - Wallet validation failed
   - Solution: Top up wallet or use different payment method

3. **"Failed to create order"**
   - API error
   - Solution: Check backend logs

---

## ✅ SUCCESS CRITERIA

All tests should:
- ✅ Load data from real API (not mock data)
- ✅ Create orders successfully
- ✅ Show success messages
- ✅ Return order IDs
- ✅ Handle errors gracefully

---

## 📊 TEST RESULTS TEMPLATE

```
TEST 1: LesGo Delivery
Status: [ ] Pass [ ] Fail
Notes: _______________________

TEST 2: LesRide
Status: [ ] Pass [ ] Fail
Notes: _______________________

TEST 3: LesEat
Status: [ ] Pass [ ] Fail
Notes: _______________________

TEST 4: LesBuy Manual Order
Status: [ ] Pass [ ] Fail
Notes: _______________________

TEST 5: LesBuy Store Order
Status: [ ] Pass [ ] Fail
Notes: _______________________

TEST 6: LesTransport
Status: [ ] Pass [ ] Fail
Notes: _______________________

TEST 7: Wallet Validation
Status: [ ] Pass [ ] Fail
Notes: _______________________

TEST 8: Transactions
Status: [ ] Pass [ ] Fail
Notes: _______________________

TEST 9: Profile
Status: [ ] Pass [ ] Fail
Notes: _______________________
```

---

**Ready to test!** 🚀

