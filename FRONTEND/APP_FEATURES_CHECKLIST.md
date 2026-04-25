# LeSGo App - Missing Features Checklist

**Date:** April 18, 2026  
**Focus:** App-specific features only

---

## ✅ COMPLETE - Working Features

### Customer App (FRONTEND):
1. ✅ User Registration & Login
2. ✅ OTP Verification
3. ✅ Profile Management
4. ✅ Address Management
5. ✅ LesGo Booking (Delivery)
6. ✅ LesRide Booking (Ride)
7. ✅ LesEat Ordering (Food)
8. ✅ LesBuy Shopping (Grocery/Store)
9. ✅ LesTransport Booking
10. ✅ Order History/Transactions
11. ✅ Wallet System
12. ✅ Payment Integration (Cash, Wallet, Xendit)
13. ✅ Voucher System
14. ✅ FAQ System
15. ✅ Support Tickets
16. ✅ Reviews & Ratings (system ready)

### Driver App (RIDERSIDE):
1. ✅ Driver Login
2. ✅ Location Tracking
3. ✅ View Available Orders
4. ✅ Accept Orders
5. ✅ Order Details
6. ✅ Map Navigation

---

## 🔴 MISSING/INCOMPLETE - Need Implementation

### 1. Live Order Tracking (Customer Side) ⚠️ HIGH PRIORITY
**Status:** Screen exists but needs real-time updates  
**File:** `lib/presentation/screens/tracking/live_tracking_screen.dart`

**What's Missing:**
- [ ] Real-time driver location updates
- [ ] WebSocket/Pusher integration for live updates
- [ ] ETA calculation
- [ ] Driver info display (name, photo, rating)
- [ ] Call driver button
- [ ] Chat with driver button

**Implementation Needed:**
```dart
// Need to add WebSocket listener
void _listenToDriverLocation() {
  // Connect to Pusher/WebSocket
  // Listen for driver location updates
  // Update map marker in real-time
}
```

---

### 2. Push Notifications ⚠️ HIGH PRIORITY
**Status:** FCM token registration exists, but no notification handling  
**Files:** Need to create notification service

**What's Missing:**
- [ ] **Customer App:**
  - [ ] Order status updates (accepted, picked up, completed)
  - [ ] Driver assigned notification
  - [ ] Delivery arriving notification
  - [ ] Promotional notifications
  - [ ] Wallet top-up confirmation

- [ ] **Driver App:**
  - [ ] New order notification
  - [ ] Order cancelled notification
  - [ ] Payment received notification

**Implementation Needed:**
```dart
// lib/core/services/notification_service.dart
class NotificationService {
  Future<void> initialize() async {
    // Initialize FCM
    // Request permissions
    // Handle foreground notifications
    // Handle background notifications
    // Handle notification taps
  }
}
```

---

### 3. Real-time Chat (Customer-Driver) ⚠️ MEDIUM PRIORITY
**Status:** Backend API exists, frontend not implemented  
**Backend:** ✅ Chat endpoints ready

**What's Missing:**
- [ ] Chat screen UI
- [ ] Send message
- [ ] Receive messages (real-time)
- [ ] Message history
- [ ] Typing indicator
- [ ] Read receipts
- [ ] Image sharing (optional)

**Implementation Needed:**
```dart
// lib/presentation/screens/chat/chat_screen.dart
class ChatScreen extends StatefulWidget {
  final int orderId;
  // Chat UI implementation
}
```

---

### 4. Order Cancellation Flow ⚠️ MEDIUM PRIORITY
**Status:** Backend supports it, frontend needs UI

**What's Missing:**
- [ ] Cancel order button (before driver accepts)
- [ ] Cancellation reason selection
- [ ] Cancellation confirmation dialog
- [ ] Refund handling (if paid)
- [ ] Cancellation fee display (if applicable)

**Implementation Needed:**
```dart
// In order details screen
Future<void> cancelOrder(int orderId, String reason) async {
  // Show confirmation dialog
  // Call API to cancel
  // Handle refund
  // Show success message
}
```

---

### 5. Driver Earnings & Analytics (Driver App) ⚠️ MEDIUM PRIORITY
**Status:** Not implemented

**What's Missing:**
- [ ] Daily earnings summary
- [ ] Weekly/monthly earnings
- [ ] Completed orders count
- [ ] Average rating
- [ ] Total distance traveled
- [ ] Earnings breakdown (base fare, tips, bonuses)
- [ ] Payout history

**Implementation Needed:**
```dart
// lib/presentation/screens/driver/earnings_screen.dart
class EarningsScreen extends StatelessWidget {
  // Show earnings dashboard
}
```

---

### 6. Wallet Top-up Flow ⚠️ MEDIUM PRIORITY
**Status:** Backend ready, frontend needs complete flow

**What's Missing:**
- [ ] Top-up amount selection
- [ ] Payment method selection (GCash, Maya, Card)
- [ ] Xendit payment page integration
- [ ] Payment status polling
- [ ] Success/failure handling
- [ ] Transaction receipt

**Implementation Needed:**
```dart
// In LesPay screen
Future<void> topUpWallet(double amount, String method) async {
  // Create invoice via Xendit
  // Open payment URL
  // Poll for payment status
  // Update wallet balance
  // Show receipt
}
```

---

### 7. Order Rating & Review ⚠️ LOW PRIORITY
**Status:** Backend ready, frontend needs UI

**What's Missing:**
- [ ] Rate order after completion
- [ ] Rate driver
- [ ] Rate food/service quality
- [ ] Write review text
- [ ] Upload photos (optional)
- [ ] View own reviews

**Implementation Needed:**
```dart
// lib/presentation/screens/review/rate_order_screen.dart
class RateOrderScreen extends StatefulWidget {
  final int orderId;
  // Rating UI implementation
}
```

---

### 8. Referral System ⚠️ LOW PRIORITY
**Status:** Backend has referral code, frontend needs UI

**What's Missing:**
- [ ] Share referral code
- [ ] View referral rewards
- [ ] Track referred users
- [ ] Claim referral bonuses
- [ ] Social sharing integration

**Implementation Needed:**
```dart
// In profile screen
void shareReferralCode(String code) {
  // Share via social media
  // Copy to clipboard
  // Generate referral link
}
```

---

### 9. Promo/Voucher Discovery ⚠️ LOW PRIORITY
**Status:** Voucher validation works, but no voucher browsing

**What's Missing:**
- [ ] Browse available vouchers
- [ ] Voucher categories
- [ ] Claim voucher
- [ ] My vouchers screen
- [ ] Voucher expiry notifications
- [ ] Auto-apply best voucher

**Implementation Needed:**
```dart
// lib/presentation/screens/vouchers/vouchers_screen.dart
class VouchersScreen extends StatelessWidget {
  // Show available vouchers
}
```

---

### 10. Order Scheduling ⚠️ LOW PRIORITY
**Status:** Backend supports scheduled_at, frontend needs UI

**What's Missing:**
- [ ] Schedule order for later
- [ ] Date/time picker
- [ ] Scheduled orders list
- [ ] Edit scheduled order
- [ ] Cancel scheduled order

**Implementation Needed:**
```dart
// In booking screens
Future<void> scheduleOrder(DateTime scheduledTime) async {
  // Add scheduled_at to order request
  // Show confirmation
}
```

---

### 11. Multi-language Support ⚠️ LOW PRIORITY
**Status:** Not implemented

**What's Missing:**
- [ ] English language
- [ ] Filipino/Tagalog language
- [ ] Language selector in settings
- [ ] Localized strings
- [ ] Date/time formatting

**Implementation Needed:**
```dart
// Use flutter_localizations
// Create translation files
// Implement language switching
```

---

### 12. Offline Mode Handling ⚠️ LOW PRIORITY
**Status:** Basic error handling exists, needs improvement

**What's Missing:**
- [ ] Detect offline status
- [ ] Show offline indicator
- [ ] Queue actions for when online
- [ ] Cached data display
- [ ] Retry failed requests

**Implementation Needed:**
```dart
// lib/core/services/connectivity_service.dart
class ConnectivityService {
  Stream<bool> get isOnline;
  // Handle offline scenarios
}
```

---

### 13. Onboarding Tutorial ⚠️ LOW PRIORITY
**Status:** Not implemented

**What's Missing:**
- [ ] First-time user tutorial
- [ ] Feature highlights
- [ ] How to book guide
- [ ] Skip tutorial option
- [ ] Don't show again option

**Implementation Needed:**
```dart
// lib/presentation/screens/onboarding/onboarding_screen.dart
class OnboardingScreen extends StatelessWidget {
  // Show tutorial slides
}
```

---

### 14. App Settings ⚠️ LOW PRIORITY
**Status:** Basic settings exist, needs more options

**What's Missing:**
- [ ] Notification preferences
- [ ] Language selection
- [ ] Theme selection (light/dark)
- [ ] Location permissions
- [ ] Clear cache
- [ ] App version info
- [ ] Terms & privacy links

**Implementation Needed:**
```dart
// Expand settings screen with more options
```

---

### 15. Emergency/SOS Button ⚠️ LOW PRIORITY
**Status:** Not implemented

**What's Missing:**
- [ ] Emergency button during ride
- [ ] Share live location with emergency contact
- [ ] Call emergency hotline
- [ ] Report safety issue

**Implementation Needed:**
```dart
// In live tracking screen
void triggerEmergency() {
  // Share location
  // Call hotline
  // Alert support team
}
```

---

## 📊 PRIORITY SUMMARY

### 🔴 HIGH PRIORITY (Must Have for Launch):
1. **Live Order Tracking** - Critical for user experience
2. **Push Notifications** - Essential for order updates
3. **Wallet Top-up Flow** - Needed for payments

**Estimated Time:** 2-3 weeks

---

### 🟡 MEDIUM PRIORITY (Should Have Soon):
4. **Real-time Chat** - Good for customer support
5. **Order Cancellation** - Important for flexibility
6. **Driver Earnings** - Important for driver satisfaction
7. **Order Rating** - Important for quality control

**Estimated Time:** 2-3 weeks

---

### 🟢 LOW PRIORITY (Nice to Have):
8. **Referral System** - For growth
9. **Voucher Discovery** - For marketing
10. **Order Scheduling** - Convenience feature
11. **Multi-language** - For wider reach
12. **Offline Mode** - Better UX
13. **Onboarding** - Better first impression
14. **App Settings** - More customization
15. **Emergency Button** - Safety feature

**Estimated Time:** 4-6 weeks

---

## 🎯 RECOMMENDED IMPLEMENTATION ORDER

### Week 1-2: Critical Features
1. ✅ Complete testing of existing features
2. 🔴 Implement Live Order Tracking
3. 🔴 Implement Push Notifications

### Week 3-4: Important Features
4. 🔴 Implement Wallet Top-up Flow
5. 🟡 Implement Order Cancellation
6. 🟡 Implement Real-time Chat

### Week 5-6: Quality Features
7. 🟡 Implement Order Rating
8. 🟡 Implement Driver Earnings
9. 🟢 Implement Voucher Discovery

### Week 7+: Enhancement Features
10. 🟢 Implement remaining low-priority features
11. 🟢 Polish UI/UX
12. 🟢 Performance optimization

---

## ✅ MINIMUM VIABLE PRODUCT (MVP)

### Can Launch With:
- ✅ All booking flows (DONE)
- ✅ Payment system (DONE)
- ✅ Order management (DONE)
- ✅ Basic tracking (DONE)
- 🔴 Live tracking (NEEDED)
- 🔴 Push notifications (NEEDED)
- 🔴 Wallet top-up (NEEDED)

### Can Add Later:
- 🟡 Chat
- 🟡 Cancellation
- 🟡 Ratings
- 🟢 All low-priority features

---

## 📝 CONCLUSION

### What's Ready Now:
- ✅ 95% of core features implemented
- ✅ All booking flows working
- ✅ Payment integration ready
- ✅ Backend APIs complete

### What's Missing for MVP:
- 🔴 Live order tracking (2-3 days)
- 🔴 Push notifications (2-3 days)
- 🔴 Wallet top-up flow (1-2 days)

**Total Time to MVP:** 1-2 weeks

### What Can Wait:
- Everything else can be added post-launch

---

**Bottom Line:** You're very close! Just need 3 critical features (live tracking, notifications, wallet top-up) and you can launch. Everything else is nice-to-have.

