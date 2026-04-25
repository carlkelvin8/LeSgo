# 🧪 Complete UI Testing Guide - With Authentication

**Date:** April 16, 2026  
**Status:** Ready for Complete Testing  
**Total Screens:** 18+ screens ready (including auth)

---

## 🔐 AUTHENTICATION SCREENS - Test First!

### 1. Login Screen ✅
**File:** `FRONTEND/lib/presentation/screens/auth/login_screen.dart`

**What to Test:**
- [ ] Screen loads without errors
- [ ] Email field validation
- [ ] Password field validation
- [ ] "Remember Me" checkbox works
- [ ] Login button works
- [ ] Loading indicator shows
- [ ] Success message appears
- [ ] Navigates to home after login
- [ ] Error messages display correctly
- [ ] "Forgot Password" link (if exists)
- [ ] "Register" link works

**Test Cases:**

**Valid Login:**
```
Email: test@example.com
Password: password123
Expected: Login successful, navigate to home
```

**Invalid Email:**
```
Email: invalid-email
Password: password123
Expected: Email validation error
```

**Wrong Password:**
```
Email: test@example.com
Password: wrongpassword
Expected: Login failed error
```

**Empty Fields:**
```
Email: (empty)
Password: (empty)
Expected: "Please enter email and password"
```

---

### 2. Register Screen ✅
**File:** `FRONTEND/lib/presentation/screens/auth/register_screen.dart`

**What to Test:**
- [ ] Screen loads
- [ ] All form fields present
- [ ] Field validation works
- [ ] Password confirmation matches
- [ ] Register button works
- [ ] Loading indicator shows
- [ ] Success message appears
- [ ] Navigates to home after register
- [ ] "Login" link works

**Test Cases:**

**Valid Registration:**
```
Name: Juan Dela Cruz
Email: juan@example.com
Phone: +639171234567
Password: password123
Confirm: password123
Expected: Registration successful
```

**Password Mismatch:**
```
Password: password123
Confirm: password456
Expected: Passwords don't match error
```

---

## 📱 COMPLETE TESTING FLOW

### 🎯 Flow 1: First Time User (Complete Journey)

```
1. App Opens
   ↓
2. See Login Screen
   ↓
3. Tap "Register"
   ↓
4. Fill registration form
   ↓
5. Submit registration
   ↓
6. Login successful
   ↓
7. Navigate to Home
   ↓
8. Explore services (LesGo, LesEat, etc.)
   ↓
9. Book a service
   ↓
10. Track order (NEW!)
   ↓
11. View transactions
   ↓
12. Check profile
   ↓
13. Logout
```

---

### 🎯 Flow 2: Returning User

```
1. App Opens
   ↓
2. See Login Screen
   ↓
3. Enter credentials
   ↓
4. Login successful
   ↓
5. Navigate to Home
   ↓
6. View active orders
   ↓
7. Track order (NEW!)
   ↓
8. View transactions
   ↓
9. Top-up wallet (NEW!)
```

---

## 📋 COMPLETE SCREEN LIST (18+ Screens)

### 🔐 Authentication (2 screens):
1. ✅ **Login Screen** - Email/password login
2. ✅ **Register Screen** - New user registration

### 🏠 Main Screens (3 screens):
3. ✅ **Home Screen** - Dashboard
4. ✅ **Transactions Screen** ⭐ (with track button)
5. ✅ **Profile Screen** - User profile

### 🚗 Booking Screens (7 screens):
6. ✅ **LesGo Screen** ⭐ (with tracking dialog)
7. ✅ **LesEat - Restaurant List**
8. ✅ **LesEat - Restaurant Details**
9. ✅ **LesEat - Checkout**
10. ✅ **LesBuy - Store List**
11. ✅ **LesBuy - Store Details**
12. ✅ **LesBuy - Cart**

### 💰 Payment Screens (2 screens):
13. ✅ **LesPay Screen** ⭐ (with Xendit)
14. ✅ **Payment Method Selector** ⭐

### 🆕 New Features (2 screens):
15. ✅ **Live Tracking Screen** ⭐⭐⭐ (MAIN FEATURE)
16. ✅ **Address Selector** ⭐

### 📚 Other Screens (2 screens):
17. ✅ **FAQ Screen**
18. ✅ **Settings Screen** (if exists)

---

## 🧪 PRIORITY TESTING ORDER

### 🔥 DAY 1: Authentication & Core Features (3 hours)

#### Morning (1.5 hours):
1. **Login Screen** (30 min)
   - Test valid login
   - Test invalid credentials
   - Test validation
   - Test navigation

2. **Register Screen** (30 min)
   - Test registration flow
   - Test validation
   - Test success flow

3. **Home Screen** (30 min)
   - Test after login
   - Check all services visible
   - Test navigation to services

#### Afternoon (1.5 hours):
4. **Live Tracking Screen** ⭐⭐⭐ (1 hour)
   - Test real-time updates
   - Test map interactions
   - Test driver info
   - Test call/chat buttons

5. **Transactions Screen** (30 min)
   - Test transaction list
   - Test track button
   - Test navigation to tracking

---

### 🔶 DAY 2: Booking & Payment (3 hours)

#### Morning (1.5 hours):
6. **LesGo Booking** (45 min)
   - Test complete booking flow
   - Test order dialog
   - Test track order button

7. **LesPay** (45 min)
   - Test wallet balance
   - Test Xendit top-up
   - Test payment flow

#### Afternoon (1.5 hours):
8. **LesEat Flow** (45 min)
   - Test restaurant browsing
   - Test menu selection
   - Test checkout

9. **LesBuy Flow** (45 min)
   - Test store browsing
   - Test cart
   - Test checkout

---

### 🔷 DAY 3: Polish & Edge Cases (2 hours)

10. **Profile & Settings** (30 min)
11. **FAQ** (30 min)
12. **Edge Cases** (1 hour)
    - Test with no internet
    - Test with slow connection
    - Test error scenarios
    - Test logout/login again

---

## 🎬 DETAILED TEST SCENARIOS

### Scenario 1: Complete First-Time User Journey

**Duration:** 15-20 minutes

```
Step 1: Launch App
- App opens to login screen
- UI loads correctly
- No errors in console

Step 2: Register New Account
- Tap "Register" button
- Fill all fields:
  * Name: Test User
  * Email: testuser@example.com
  * Phone: +639171234567
  * Password: Test123!
  * Confirm: Test123!
- Tap "Register"
- See loading indicator
- Registration successful
- Navigate to home

Step 3: Explore Home
- See all services (LesGo, LesEat, etc.)
- Wallet balance shows
- Profile icon visible

Step 4: Book First Ride (LesGo)
- Tap LesGo
- Map loads
- Select pickup location
- Select dropoff location
- See fare estimate
- Select payment method
- Tap "Book Now"
- See success dialog ⭐ NEW
- Tap "Track Order" ⭐ NEW

Step 5: Track Order
- Live tracking screen opens ⭐ NEW
- Map shows markers ⭐ NEW
- Driver location updates ⭐ NEW
- ETA displays ⭐ NEW
- Can expand bottom sheet ⭐ NEW
- Can see driver info ⭐ NEW
- Can tap call/chat ⭐ NEW

Step 6: View Transactions
- Go back to home
- Open transactions
- See booked order
- Tap "Track" button ⭐ NEW
- Opens live tracking ⭐ NEW

Step 7: Top-up Wallet
- Open LesPay
- Tap "Top Up"
- Enter amount: 500
- Select Xendit ⭐ NEW
- Create invoice ⭐ NEW
- Payment URL opens ⭐ NEW

Step 8: Check Profile
- Open profile
- See user info
- Check wallet balance
- Logout

✅ PASS if all steps work
❌ FAIL if any step breaks
```

---

### Scenario 2: Returning User - Quick Track

**Duration:** 5 minutes

```
Step 1: Login
- Enter email: testuser@example.com
- Enter password: Test123!
- Tap "Login"
- Navigate to home

Step 2: View Active Orders
- Open transactions
- See list of orders
- Find pending order

Step 3: Track Order
- Tap "Track" button ⭐ NEW
- Live tracking opens ⭐ NEW
- See real-time updates ⭐ NEW
- Watch for 30 seconds
- Verify location updates ⭐ NEW
- Verify ETA updates ⭐ NEW

✅ PASS if tracking works smoothly
❌ FAIL if updates don't work
```

---

### Scenario 3: Payment Gateway Test

**Duration:** 10 minutes

```
Step 1: Login
- Login with test account

Step 2: Open LesPay
- Navigate to LesPay
- Check current balance

Step 3: Initiate Top-up
- Tap "Top Up"
- Enter amount: 1000
- Select payment method: Xendit ⭐ NEW

Step 4: Create Invoice
- Tap "Proceed"
- Invoice created ⭐ NEW
- Invoice URL received ⭐ NEW

Step 5: Open Payment
- Payment URL opens ⭐ NEW
- Xendit page loads ⭐ NEW
- Can see payment options ⭐ NEW

Step 6: Complete Payment
- Complete payment (use test card)
- Return to app
- Check balance updated

✅ PASS if payment flow works
❌ FAIL if any step fails
```

---

## 🐛 COMMON ISSUES TO CHECK

### Authentication Issues:
- [ ] Login fails with correct credentials
- [ ] Token not saved
- [ ] Auto-login not working
- [ ] Logout doesn't clear data
- [ ] Session expires unexpectedly

### Navigation Issues:
- [ ] Can't navigate after login
- [ ] Back button doesn't work
- [ ] Deep links broken
- [ ] State lost on navigation

### API Issues:
- [ ] Requests fail
- [ ] Timeout errors
- [ ] No error messages
- [ ] Loading states stuck

### UI Issues:
- [ ] Buttons not tappable
- [ ] Text overflow
- [ ] Images not loading
- [ ] Colors incorrect
- [ ] Spacing issues

---

## 📊 TEST DATA REQUIREMENTS

### Test Accounts:

**Account 1: New User**
```
Email: newuser@test.com
Password: Test123!
Status: Not registered yet
Purpose: Test registration flow
```

**Account 2: Existing User**
```
Email: testuser@test.com
Password: Test123!
Wallet: ₱500
Orders: 3 (1 pending, 2 completed)
Addresses: 2 saved
Purpose: Test all features
```

**Account 3: Premium User**
```
Email: premium@test.com
Password: Test123!
Wallet: ₱5000
Orders: 20+ orders
Addresses: 5 saved
Purpose: Test with lots of data
```

---

## ✅ TESTING CHECKLIST

### Before Testing:
- [ ] App builds successfully
- [ ] No compilation errors
- [ ] Dependencies installed
- [ ] API keys configured (Google Maps, Xendit)
- [ ] Backend API running
- [ ] Test accounts created
- [ ] Test data prepared

### Authentication Testing:
- [ ] Login with valid credentials
- [ ] Login with invalid credentials
- [ ] Register new account
- [ ] Logout
- [ ] Auto-login on app restart
- [ ] Remember me works
- [ ] Token refresh works

### Feature Testing:
- [ ] All screens load
- [ ] Navigation works
- [ ] API calls succeed
- [ ] Loading states show
- [ ] Error messages display
- [ ] Success messages show

### New Features Testing:
- [ ] Live tracking works
- [ ] Track button appears
- [ ] Order dialog shows
- [ ] Xendit integration works
- [ ] Address selector works
- [ ] Payment method selector works

### Performance Testing:
- [ ] App loads quickly
- [ ] Scrolling is smooth
- [ ] No memory leaks
- [ ] No crashes
- [ ] Battery usage acceptable

---

## 🚀 QUICK START TESTING

### Option 1: Quick Test (30 minutes)
```
1. Login (5 min)
2. Book a ride (10 min)
3. Track order (10 min)
4. Check transactions (5 min)
```

### Option 2: Full Test (3 hours)
```
Day 1: Auth + Core (3 hours)
- Login/Register
- Live Tracking
- Transactions
```

### Option 3: Complete Test (3 days)
```
Day 1: Auth + Core
Day 2: Booking + Payment
Day 3: Polish + Edge Cases
```

---

## 📝 BUG REPORTING TEMPLATE

```markdown
## Bug Report

**Screen:** [Screen name]
**Feature:** [Feature name]
**Severity:** [Critical/High/Medium/Low]

**Steps to Reproduce:**
1. Step 1
2. Step 2
3. Step 3

**Expected Result:**
[What should happen]

**Actual Result:**
[What actually happened]

**Screenshots:**
[Attach screenshots]

**Console Errors:**
[Copy any errors from console]

**Device Info:**
- Device: [e.g., iPhone 12, Samsung S21]
- OS: [e.g., iOS 15, Android 12]
- App Version: [e.g., 1.0.0]
```

---

## 🎯 SUCCESS CRITERIA

### ✅ Testing Complete When:
- [ ] All 18+ screens tested
- [ ] All test scenarios passed
- [ ] No critical bugs found
- [ ] Performance acceptable
- [ ] User experience smooth
- [ ] Documentation updated

### ✅ Ready for Production When:
- [ ] All bugs fixed
- [ ] All features working
- [ ] Performance optimized
- [ ] Security validated
- [ ] User testing completed

---

## 🎉 READY TO TEST!

**Total Screens:** 18+ screens  
**New Features:** 4 major features  
**Test Duration:** 30 min (quick) to 3 days (complete)

**Start with:**
1. ✅ Login (5 min)
2. ✅ Live Tracking (15 min)
3. ✅ Book & Track (10 min)

**Lahat ay ready na! Start testing!** 🚀

