# 🧪 UI Testing Guide - Ready to Test Screens

**Date:** April 16, 2026  
**Status:** Ready for UI Testing  
**Total Screens:** 15+ screens ready

---

## 📱 Screens Ready for Testing

### ✅ FULLY FUNCTIONAL - Ready to Test Now

---

## 1. 🏠 Main Screens

### 1.1 Transactions Screen ✅
**File:** `FRONTEND/lib/presentation/screens/main/transactions_screen.dart`

**What to Test:**
- [ ] Screen loads without errors
- [ ] Shows list of transactions
- [ ] Pull to refresh works
- [ ] Empty state shows when no transactions
- [ ] **NEW:** Track button appears on pending orders
- [ ] **NEW:** Track button navigates to live tracking
- [ ] Transaction details display correctly
- [ ] Scrolling is smooth

**How to Access:**
```dart
// From main navigation
Navigator.pushNamed(context, '/transactions');
```

**Test Data Needed:**
- User with transactions
- Mix of completed and pending orders

---

### 1.2 Profile Screen ✅
**File:** `FRONTEND/lib/presentation/screens/main/profile_screen.dart`

**What to Test:**
- [ ] Profile loads user data
- [ ] Shows user name, email, phone
- [ ] Shows wallet balance
- [ ] Edit profile button works
- [ ] Logout button works
- [ ] Settings navigation works

**How to Access:**
```dart
// From main navigation
Navigator.pushNamed(context, '/profile');
```

**Test Data Needed:**
- Logged in user

---

### 1.3 FAQ Screen ✅
**File:** `FRONTEND/lib/presentation/screens/main/faq_screen.dart`

**What to Test:**
- [ ] FAQ categories load
- [ ] Can browse categories
- [ ] Articles display correctly
- [ ] Search works (if implemented)
- [ ] Back navigation works

**How to Access:**
```dart
// From profile or help menu
Navigator.pushNamed(context, '/faq');
```

---

## 2. 🚗 Booking Screens

### 2.1 LesGo Booking Screen ✅
**File:** `FRONTEND/lib/presentation/screens/main/booking/lesgo_screen.dart`

**What to Test:**
- [ ] Map loads correctly
- [ ] Can select pickup location
- [ ] Can select dropoff location
- [ ] Fare estimate shows
- [ ] Payment method selection works
- [ ] Book button works
- [ ] **NEW:** Order created dialog appears
- [ ] **NEW:** Track Order button in dialog works
- [ ] **NEW:** Navigates to live tracking

**How to Access:**
```dart
// From home screen
Navigator.pushNamed(context, '/lesgo');
```

**Test Scenarios:**
1. **Happy Path:**
   - Select pickup
   - Select dropoff
   - See fare estimate
   - Select payment method
   - Book ride
   - See success dialog
   - Tap "Track Order"
   - See live tracking

2. **Error Cases:**
   - Try to book without pickup
   - Try to book without dropoff
   - Try to book with insufficient wallet balance

---

### 2.2 LesEat Screens ✅
**Files:**
- `leseat_screen.dart` - Restaurant list
- `restaurant_detail_screen.dart` - Restaurant menu
- `leseat_checkout_screen.dart` - Checkout

**What to Test:**

**Restaurant List:**
- [ ] Restaurants load
- [ ] Can search restaurants
- [ ] Can filter by category
- [ ] Tap restaurant opens details

**Restaurant Details:**
- [ ] Menu items display
- [ ] Can add items to cart
- [ ] Cart updates correctly
- [ ] Checkout button works

**Checkout:**
- [ ] Order summary correct
- [ ] Can apply voucher
- [ ] Payment method selection
- [ ] Place order works
- [ ] Success message shows

**How to Access:**
```dart
// From home screen
Navigator.pushNamed(context, '/leseat');
```

---

### 2.3 LesBuy Screens ✅
**Files:**
- `lesbuy_screen.dart` - Store list
- `store_detail_screen.dart` - Store products
- `store_cart_screen.dart` - Shopping cart

**What to Test:**
- [ ] Stores load
- [ ] Products display
- [ ] Add to cart works
- [ ] Cart updates
- [ ] Checkout works

**How to Access:**
```dart
// From home screen
Navigator.pushNamed(context, '/lesbuy');
```

---

## 3. 💰 Payment Screens

### 3.1 LesPay Screen ✅
**File:** `FRONTEND/lib/presentation/screens/main/lespay_screen.dart`

**What to Test:**
- [ ] Wallet balance displays
- [ ] Transaction history shows
- [ ] Top-up button works
- [ ] **NEW:** Xendit payment integration
- [ ] **NEW:** Invoice creation works
- [ ] **NEW:** Payment URL opens
- [ ] Withdraw button works (if implemented)

**How to Access:**
```dart
// From main navigation
Navigator.pushNamed(context, '/lespay');
```

**Test Scenarios:**
1. **Wallet Top-up:**
   - Tap top-up
   - Enter amount
   - Select payment method
   - Create invoice
   - Open payment URL
   - Complete payment
   - Check balance updates

---

## 4. 🆕 NEW SCREENS - Just Implemented

### 4.1 Live Tracking Screen ⭐ NEW ✅
**File:** `FRONTEND/lib/presentation/screens/tracking/live_tracking_screen.dart`

**What to Test:**
- [ ] Screen loads with order ID
- [ ] Map displays correctly
- [ ] Markers show (driver, pickup, dropoff)
- [ ] Driver location updates (every 5 seconds)
- [ ] ETA updates (every 15 seconds)
- [ ] Route polyline displays
- [ ] Bottom sheet expands/collapses
- [ ] Driver info displays
- [ ] Call button works
- [ ] Chat button works
- [ ] Order timeline shows
- [ ] Refresh button works
- [ ] My location button works
- [ ] Auto-fit bounds works

**How to Access:**
```dart
// Method 1: From Transactions
// Tap "Track" button on any pending order

// Method 2: After booking
// Tap "Track Order" in success dialog

// Method 3: Direct navigation
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => LiveTrackingScreen(orderId: 123),
  ),
);
```

**Test Scenarios:**

1. **Real-time Updates:**
   - Open tracking screen
   - Wait 5 seconds
   - Check if driver marker moves
   - Wait 15 seconds
   - Check if ETA updates

2. **Bottom Sheet:**
   - Swipe up to expand
   - Swipe down to collapse
   - Check all content displays

3. **Driver Actions:**
   - Tap call button
   - Check phone dialer opens
   - Tap chat button
   - Check chat screen opens

4. **Order States:**
   - Test with pending order
   - Test with in-transit order
   - Test with completed order
   - Check status colors change

---

## 5. 📋 Example Widgets - For Testing

### 5.1 Address Selector Example ⭐ NEW
**File:** `FRONTEND/lib/presentation/widgets/address/address_selector_example.dart`

**What to Test:**
- [ ] Addresses load
- [ ] Can select address
- [ ] Default address marked
- [ ] Edit button works
- [ ] Delete button works
- [ ] Add new address works
- [ ] Set as default works

**How to Test:**
```dart
// Add to any screen for testing
AddressSelectorExample(
  onAddressSelected: (addressId) {
    print('Selected address: $addressId');
  },
)
```

---

### 5.2 Payment Method Selector Example ⭐ NEW
**File:** `FRONTEND/lib/presentation/widgets/payment/payment_method_selector_example.dart`

**What to Test:**
- [ ] Payment methods display
- [ ] Can select method
- [ ] Wallet balance shows
- [ ] Wallet validation works
- [ ] Xendit option works
- [ ] Confirm button works

**How to Test:**
```dart
// Add to checkout screens
PaymentMethodSelectorExample(
  amount: 150.00,
  onMethodSelected: (method) {
    print('Selected method: $method');
  },
)
```

---

## 6. 🧪 Testing Checklist by Feature

### Address Management ✅
**Screens to Test:**
- [ ] Checkout screens (LesEat, LesBuy)
- [ ] Address selector widget
- [ ] Profile/settings (if address management added)

**Test Cases:**
1. Load addresses
2. Select address
3. Add new address
4. Edit address
5. Delete address
6. Set default address

---

### Payment Tracking ✅
**Screens to Test:**
- [ ] Transactions screen
- [ ] Payment history (if separate screen)
- [ ] Order details

**Test Cases:**
1. View payment history
2. Filter by status
3. View payment details
4. Check totals

---

### Payment Gateway (Xendit) ✅
**Screens to Test:**
- [ ] LesPay (wallet top-up)
- [ ] Checkout screens (all services)
- [ ] Payment method selector

**Test Cases:**
1. Create invoice
2. Open payment URL
3. Complete payment
4. Check status updates
5. Validate wallet balance

---

### Live Tracking ✅
**Screens to Test:**
- [ ] Live tracking screen
- [ ] Transactions (track button)
- [ ] Order confirmation dialogs

**Test Cases:**
1. Open from transactions
2. Open from order confirmation
3. Real-time updates
4. Driver info display
5. Call/chat actions
6. Order timeline
7. Map interactions

---

## 7. 📱 Complete Testing Flow

### Flow 1: Book and Track (LesGo)
```
1. Open LesGo
2. Select pickup location
3. Select dropoff location
4. See fare estimate
5. Select payment method
6. Tap "Book Now"
7. See success dialog
8. Tap "Track Order"
9. See live tracking screen
10. Watch real-time updates
11. Tap call/chat buttons
12. Expand bottom sheet
13. See order timeline
```

### Flow 2: View and Track from Transactions
```
1. Open Transactions
2. See list of orders
3. Find pending order
4. Tap "Track" button
5. See live tracking screen
6. Watch updates
7. Go back
8. Try another order
```

### Flow 3: Wallet Top-up
```
1. Open LesPay
2. See current balance
3. Tap "Top Up"
4. Enter amount
5. Select Xendit
6. Create invoice
7. Open payment URL
8. Complete payment
9. Return to app
10. Check balance updated
```

---

## 8. 🐛 Common Issues to Check

### Map Issues:
- [ ] Map loads (check API key)
- [ ] Markers display
- [ ] Polylines show
- [ ] Location permission granted
- [ ] Internet connection active

### API Issues:
- [ ] Check API responses
- [ ] Handle errors gracefully
- [ ] Show loading states
- [ ] Display error messages
- [ ] Retry mechanisms work

### UI Issues:
- [ ] Buttons are tappable
- [ ] Text is readable
- [ ] Colors are correct
- [ ] Spacing is proper
- [ ] Animations are smooth

### Navigation Issues:
- [ ] Screens open correctly
- [ ] Back button works
- [ ] Deep linking works
- [ ] State persists

---

## 9. 📊 Testing Priority

### 🔥 HIGH PRIORITY (Test First):
1. ✅ **Live Tracking Screen** - New feature
2. ✅ **Transactions Screen** - Track button
3. ✅ **LesGo Booking** - Order dialog
4. ✅ **LesPay** - Xendit integration

### 🔶 MEDIUM PRIORITY:
5. ✅ Address selector widget
6. ✅ Payment method selector
7. ✅ LesEat checkout
8. ✅ LesBuy checkout

### 🔷 LOW PRIORITY:
9. ✅ Profile screen
10. ✅ FAQ screen
11. ✅ Other existing screens

---

## 10. 🧪 Test Data Requirements

### User Accounts:
- [ ] User with wallet balance
- [ ] User with saved addresses
- [ ] User with order history
- [ ] User with pending orders

### Orders:
- [ ] Pending order (for tracking)
- [ ] In-transit order (for tracking)
- [ ] Completed order
- [ ] Cancelled order

### Addresses:
- [ ] Multiple saved addresses
- [ ] Default address set
- [ ] Addresses with coordinates

---

## 11. 📝 Testing Checklist

### Before Testing:
- [ ] App builds successfully
- [ ] No compilation errors
- [ ] Dependencies installed
- [ ] API keys configured
- [ ] Test user created
- [ ] Test data prepared

### During Testing:
- [ ] Take screenshots
- [ ] Note any bugs
- [ ] Check console for errors
- [ ] Test on different devices
- [ ] Test different scenarios

### After Testing:
- [ ] Document bugs found
- [ ] List improvements needed
- [ ] Note performance issues
- [ ] Suggest UI enhancements

---

## 12. 🚀 Quick Test Commands

### Run the app:
```bash
cd FRONTEND
flutter run
```

### Run with specific device:
```bash
flutter run -d <device-id>
```

### Check for errors:
```bash
flutter analyze
```

### Run tests:
```bash
flutter test
```

---

## 📱 Screens Summary

### ✅ Ready to Test (15+ screens):

**Main Screens (3):**
1. Transactions ⭐ (with track button)
2. Profile
3. FAQ

**Booking Screens (6):**
4. LesGo ⭐ (with tracking dialog)
5. LesEat - Restaurant list
6. LesEat - Restaurant details
7. LesEat - Checkout
8. LesBuy - Store list
9. LesBuy - Cart

**Payment Screens (2):**
10. LesPay ⭐ (with Xendit)
11. Payment method selector ⭐

**New Screens (2):**
12. Live Tracking ⭐⭐⭐ (MAIN FEATURE)
13. Address selector ⭐

**Widgets (2):**
14. Driver info card ⭐
15. Order timeline ⭐

---

## 🎯 Recommended Testing Order

### Day 1: Core Features
1. ✅ Live Tracking Screen (1 hour)
2. ✅ Transactions with Track button (30 min)
3. ✅ LesGo with Order dialog (30 min)

### Day 2: Payment Features
4. ✅ LesPay with Xendit (1 hour)
5. ✅ Payment method selector (30 min)
6. ✅ Address selector (30 min)

### Day 3: Booking Features
7. ✅ LesEat flow (1 hour)
8. ✅ LesBuy flow (1 hour)
9. ✅ Other screens (1 hour)

---

## ✅ Ready to Start Testing!

**Total Screens Ready:** 15+  
**New Features:** 4  
**Priority Features:** 4  
**Estimated Testing Time:** 3 days

**Start with Live Tracking - it's the most impressive!** 🚀

