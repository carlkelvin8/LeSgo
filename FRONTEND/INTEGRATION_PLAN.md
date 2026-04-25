# API Integration Plan for Existing Screens

## 📱 Existing Screens & Applicable APIs

### 🔐 AUTH SCREENS

#### 1. **login_screen.dart**
**Applicable APIs:**
- ✅ POST `/v1/auth/login` - Already integrated
- 🔄 POST `/v1/auth/fcm-token` - Can add FCM token registration

#### 2. **register_screen.dart** 
**Applicable APIs:**
- ✅ POST `/v1/auth/register` - Already integrated
- 🔄 POST `/v1/auth/fcm-token` - Can add FCM token registration

#### 3. **verification_screen.dart**
**Applicable APIs:**
- 🔄 GET `/v1/auth/me` - Verify user after registration

#### 4. **address_screen.dart** (Registration step)
**Applicable APIs:**
- 🔄 POST `/v1/users/{user_id}/addresses` - Save address during registration
- 🔄 GET `/v1/users/{user_id}/addresses` - Load saved addresses

---

### 🏠 MAIN SCREENS

#### 5. **home_screen.dart**
**Applicable APIs:**
- 🔄 GET `/v1/notifications/unread-count` - Show notification badge
- 🔄 GET `/v1/orders?status=pending` - Show active orders
- 🔄 GET `/v1/analytics/dashboard` - Show user stats

#### 6. **profile_screen.dart**
**Applicable APIs:**
- 🔄 GET `/v1/auth/me` - Load user profile
- 🔄 PUT `/v1/auth/me` - Update profile
- 🔄 GET `/v1/users/{id}` - Get user details
- 🔄 PATCH `/v1/users/{id}` - Update user details
- 🔄 GET `/v1/reviews/my-reviews` - Show user reviews
- 🔄 GET `/v1/reviews/statistics` - Show review stats

#### 7. **settings_screen.dart**
**Applicable APIs:**
- 🔄 GET `/v1/security/dashboard` - Security settings
- 🔄 POST `/v1/security/2fa/setup` - Enable 2FA
- 🔄 POST `/v1/security/2fa/disable` - Disable 2FA
- 🔄 GET `/v1/security/biometric/list` - List biometric auth
- 🔄 POST `/v1/security/biometric/enroll` - Add biometric
- 🔄 GET `/v1/security/audit/logs` - View activity logs
- 🔄 POST `/v1/auth/logout` - Logout
- 🔄 POST `/v1/auth/logout-all` - Logout all devices

#### 8. **inbox_screen.dart**
**Applicable APIs:**
- ✅ GET `/v1/notifications` - Already integrated
- ✅ GET `/v1/notifications/unread-count` - Already integrated
- ✅ PATCH `/v1/notifications/{id}/read` - Already integrated
- ✅ POST `/v1/notifications/read-all` - Already integrated

#### 9. **transactions_screen.dart**
**Applicable APIs:**
- ✅ GET `/v1/wallets/my/transactions` - Already integrated
- 🔄 GET `/v1/payments` - Show payment history
- 🔄 GET `/v1/orders` - Show order history with details

#### 10. **lespay_screen.dart**
**Applicable APIs:**
- ✅ GET `/v1/wallets/my/wallet` - Already integrated
- 🔄 GET `/v1/wallets/my/validation` - Check wallet threshold
- 🔄 GET `/v1/wallets/threshold` - Get minimum threshold
- 🔄 POST `/v1/gateway/invoice` - Create top-up invoice
- 🔄 GET `/v1/gateway/invoice/{id}` - Check invoice status

#### 11. **missions_screen.dart**
**Applicable APIs:**
- 🔄 GET `/v1/vouchers/available` - Show available vouchers/rewards
- 🔄 GET `/v1/social/my-shares` - Show social sharing missions
- 🔄 GET `/v1/social/analytics` - Show mission progress

#### 12. **faqs_screen.dart**
**Applicable APIs:**
- 🔄 GET `/v1/faq/categories` - Load FAQ categories
- 🔄 GET `/v1/faq/categories/{id}` - Load category articles
- 🔄 GET `/v1/faq/articles/{id}` - Load article details
- 🔄 GET `/v1/faq/search` - Search FAQs
- 🔄 GET `/v1/faq/featured` - Show featured articles
- 🔄 GET `/v1/faq/popular` - Show popular articles
- 🔄 POST `/v1/faq/articles/{id}/helpful` - Mark helpful
- 🔄 POST `/v1/faq/articles/{id}/not-helpful` - Mark not helpful

#### 13. **about_screen.dart**
**Applicable APIs:**
- 🔄 GET `/v1/social/platforms` - Show social media links
- 🔄 GET `/v1/support/tickets/statistics` - Show support stats

---

### 📦 BOOKING SCREENS

#### 14. **booking_screen.dart**
**Applicable APIs:**
- ✅ GET `/v1/services` - Already integrated
- ✅ GET `/v1/services/{id}` - Already integrated

#### 15. **lesgo_screen.dart**
**Applicable APIs:**
- ✅ POST `/v1/orders/estimate` - Already integrated
- 🔄 POST `/v1/orders` - Create delivery order
- 🔄 GET `/v1/distance/calculate` - Calculate distance
- 🔄 GET `/v1/users/{user_id}/addresses` - Load saved addresses
- 🔄 POST `/v1/users/{user_id}/addresses` - Save new address
- 🔄 GET `/v1/tracking/drivers/nearby` - Show nearby drivers
- 🔄 GET `/v1/geofences/location/check` - Check service area

#### 16. **lesride_screen.dart**
**Applicable APIs:**
- 🔄 POST `/v1/orders/estimate` - Get ride fare estimate
- 🔄 POST `/v1/orders` - Create ride order
- 🔄 GET `/v1/tracking/drivers/nearby` - Show nearby drivers
- 🔄 GET `/v1/users/{user_id}/addresses` - Load saved addresses

#### 17. **leseat_screen.dart**
**Applicable APIs:**
- ✅ GET `/v1/partners?category=restaurant` - Already integrated
- 🔄 GET `/v1/partners/{id}` - Get restaurant details
- 🔄 GET `/v1/partners/{id}/branches` - Get restaurant branches

#### 18. **leseat/restaurant_detail_screen.dart**
**Applicable APIs:**
- 🔄 GET `/v1/partners/{id}` - Load restaurant details
- 🔄 GET `/v1/reviews?partner_id={id}` - Load restaurant reviews
- 🔄 POST `/v1/reviews` - Submit review
- 🔄 GET `/v1/reviews/statistics` - Show rating stats

#### 19. **leseat/leseat_checkout_screen.dart**
**Applicable APIs:**
- ✅ POST `/v1/vouchers/validate` - Already integrated
- 🔄 POST `/v1/orders` - Create food order
- 🔄 POST `/v1/gateway/invoice` - Create payment invoice
- 🔄 GET `/v1/users/{user_id}/addresses` - Load delivery addresses
- 🔄 POST `/v1/orders/estimate` - Get delivery fee estimate

#### 20. **lesport_screen.dart**
**Applicable APIs:**
- 🔄 POST `/v1/orders/estimate` - Get transport fare
- 🔄 POST `/v1/orders` - Create transport order
- 🔄 GET `/v1/tracking/drivers/nearby` - Show nearby drivers

#### 21. **lesbuy/store_cart_screen.dart**
**Applicable APIs:**
- ✅ POST `/v1/vouchers/validate` - Already integrated
- 🔄 POST `/v1/orders` - Create shopping order
- 🔄 POST `/v1/gateway/invoice` - Create payment
- 🔄 GET `/v1/checklist-templates` - Load shopping lists

---

## 📊 Integration Summary

### Current Status:
- **Total Screens:** 21 screens
- **Already Integrated:** 11 endpoints across 6 screens
- **Can Be Integrated:** 80+ additional endpoints

### Priority Integration by Screen:

#### 🔥 HIGH PRIORITY (Complete User Journeys)
1. **lesgo_screen.dart** - Add order creation (5 endpoints)
2. **leseat_checkout_screen.dart** - Add order creation & payment (4 endpoints)
3. **profile_screen.dart** - Add profile management (6 endpoints)
4. **lespay_screen.dart** - Add top-up functionality (3 endpoints)
5. **transactions_screen.dart** - Add order history (2 endpoints)

#### 🟡 MEDIUM PRIORITY (Enhanced Features)
6. **faqs_screen.dart** - Full FAQ integration (8 endpoints)
7. **settings_screen.dart** - Security features (7 endpoints)
8. **missions_screen.dart** - Vouchers & rewards (3 endpoints)
9. **home_screen.dart** - Dashboard stats (3 endpoints)

#### 🟢 LOW PRIORITY (Nice to Have)
10. **about_screen.dart** - Social links (2 endpoints)
11. **address_screen.dart** - Address management (2 endpoints)

---

## 🎯 Recommended Approach

### Phase 1: Complete Core Journeys (15 endpoints)
Integrate APIs that complete the booking → payment → tracking flow:
- Order creation
- Payment processing
- Address management
- Order tracking

### Phase 2: User Management (10 endpoints)
Integrate profile and settings APIs:
- Profile updates
- Security settings
- Activity logs

### Phase 3: Content & Support (15 endpoints)
Integrate informational APIs:
- FAQs
- Reviews
- Support tickets

---

**Total Endpoints That Can Be Integrated:** ~80 endpoints  
**Estimated Integration Time:** 
- Phase 1: 2-3 hours
- Phase 2: 1-2 hours  
- Phase 3: 2-3 hours

Would you like me to proceed with Phase 1 integration?
