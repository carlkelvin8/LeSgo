# LeSGo App - Required API Endpoints

**Base URL:** `http://127.0.0.1:8000/api/v1`  
**Authentication:** Bearer Token (Laravel Sanctum)  
**Last Updated:** May 2, 2026

---

## 📱 CUSTOMER APP (FRONTEND) - Required APIs

### 🔐 1. Authentication & User Management
**Status:** ✅ Implemented

| Method | Endpoint | Purpose | Status |
|--------|----------|---------|--------|
| POST | `/auth/register` | Register new customer | ✅ |
| POST | `/auth/login` | Login customer | ✅ |
| POST | `/auth/google` | Google Sign-In | ✅ |
| GET | `/auth/me` | Get current user profile | ✅ |
| PUT | `/auth/me` | Update user profile | ✅ |
| POST | `/auth/me/profile-picture` | Upload profile picture | ✅ |
| POST | `/auth/logout` | Logout current session | ✅ |
| POST | `/auth/logout-all` | Logout all devices | ✅ |
| POST | `/auth/fcm-token` | Register FCM push token | ✅ |

**Forgot Password:**
| Method | Endpoint | Purpose | Status |
|--------|----------|---------|--------|
| POST | `/auth/forgot-password/send-otp` | Send OTP to email/phone | ✅ |
| POST | `/auth/forgot-password/verify-otp` | Verify OTP code | ✅ |
| POST | `/auth/forgot-password/reset` | Reset password | ✅ |
| POST | `/auth/forgot-password/resend-otp` | Resend OTP | ✅ |

**OTP Verification:**
| Method | Endpoint | Purpose | Status |
|--------|----------|---------|--------|
| POST | `/auth/otp/send` | Send OTP for verification | ✅ |
| POST | `/auth/otp/verify` | Verify OTP code | ✅ |
| POST | `/auth/otp/cancel` | Cancel OTP verification | ✅ |
| POST | `/auth/otp/check` | Check verification status | ✅ |

---

### 🏠 2. Home Screen APIs
**Status:** ✅ Implemented

| Method | Endpoint | Purpose | Status |
|--------|----------|---------|--------|
| GET | `/services` | Get all services (LesGo, LesRide, LesEat, LesBuy) | ✅ |
| GET | `/services/{id}` | Get service details | ✅ |
| GET | `/partners` | Get featured partners/restaurants | ✅ |
| GET | `/partners/{id}` | Get partner details | ✅ |
| GET | `/wallets/my/wallet` | Get wallet balance | ✅ |
| GET | `/notifications/unread-count` | Get unread notifications count | ✅ |

---

### 📍 3. Address Management
**Status:** ✅ Implemented

| Method | Endpoint | Purpose | Status |
|--------|----------|---------|--------|
| GET | `/addresses` | Get my saved addresses | ✅ |
| POST | `/addresses` | Save new address | ✅ |
| PATCH | `/addresses/{id}` | Update address | ✅ |
| DELETE | `/addresses/{id}` | Delete address | ✅ |

**Google Places Integration:**
| Method | Endpoint | Purpose | Status |
|--------|----------|---------|--------|
| GET | `/google-places/autocomplete` | Search places autocomplete | ✅ |
| GET | `/google-places/details` | Get place details | ✅ |
| GET | `/google-places/directions` | Get directions/route | ✅ |

---

### 🚗 4. LesGo (Delivery Service)
**Status:** ✅ Implemented

| Method | Endpoint | Purpose | Status |
|--------|----------|---------|--------|
| POST | `/orders/estimate` | Get fare estimate | ✅ |
| POST | `/orders` | Create delivery order | ✅ |
| GET | `/orders` | Get my orders | ✅ |
| GET | `/orders/{id}` | Get order details | ✅ |
| PATCH | `/orders/{id}/status` | Update order status (cancel) | ✅ |
| POST | `/orders/{id}/upload-proof` | Upload proof of delivery | ✅ |
| GET | `/orders/{id}/receipt` | Get order receipt | ✅ |

**Live Tracking:**
| Method | Endpoint | Purpose | Status |
|--------|----------|---------|--------|
| GET | `/tracking/orders/{id}` | Track order status | ✅ |
| GET | `/tracking/orders/{id}/location` | Get driver live location | ✅ |
| GET | `/tracking/order/{id}/live` | Get live tracking data | ✅ |
| GET | `/tracking/order/{id}/eta` | Get estimated arrival time | ✅ |

---

### 🏍️ 5. LesRide (Ride Service)
**Status:** ✅ Implemented (Same as LesGo)

| Method | Endpoint | Purpose | Status |
|--------|----------|---------|--------|
| POST | `/orders/estimate` | Get ride fare estimate | ✅ |
| POST | `/orders` | Book a ride | ✅ |
| GET | `/orders/{id}` | Get ride details | ✅ |
| PATCH | `/orders/{id}/status` | Cancel ride | ✅ |
| GET | `/tracking/orders/{id}` | Track ride | ✅ |
| GET | `/tracking/orders/{id}/location` | Get driver location | ✅ |

---

### 🍔 6. LesEat (Food Delivery)
**Status:** ✅ Implemented

| Method | Endpoint | Purpose | Status |
|--------|----------|---------|--------|
| GET | `/partners?category=restaurant` | Get restaurants list | ✅ |
| GET | `/partners/{id}` | Get restaurant details | ✅ |
| GET | `/partners/{id}/menu` | Get restaurant menu | ✅ |
| GET | `/partners/{id}/branches` | Get restaurant branches | ✅ |
| POST | `/orders` | Create food order | ✅ |
| GET | `/orders/{id}` | Get food order details | ✅ |
| GET | `/tracking/orders/{id}` | Track food delivery | ✅ |

---

### 🛒 7. LesBuy (Shopping/Errands)
**Status:** ✅ Implemented

| Method | Endpoint | Purpose | Status |
|--------|----------|---------|--------|
| GET | `/partners?category=store` | Get stores list | ✅ |
| GET | `/partners/{id}` | Get store details | ✅ |
| GET | `/partners/{id}/menu` | Get store items | ✅ |
| GET | `/checklist-templates` | Get shopping templates | ✅ |
| POST | `/checklist-templates` | Create custom checklist | ✅ |
| POST | `/orders` | Create shopping order | ✅ |
| GET | `/orders/{id}` | Get shopping order details | ✅ |

---

### 💳 8. Payment & Wallet (LesPay)
**Status:** ✅ Implemented

**Wallet:**
| Method | Endpoint | Purpose | Status |
|--------|----------|---------|--------|
| GET | `/wallets/my/wallet` | Get my wallet balance | ✅ |
| GET | `/wallets/my/transactions` | Get wallet transactions | ✅ |
| GET | `/wallets/my/validation` | Validate wallet balance | ✅ |

**Payments:**
| Method | Endpoint | Purpose | Status |
|--------|----------|---------|--------|
| GET | `/payments` | Get payment history | ✅ |
| POST | `/payments` | Create payment | ✅ |
| GET | `/payments/{id}` | Get payment details | ✅ |

**Payment Gateway (Xendit):**
| Method | Endpoint | Purpose | Status |
|--------|----------|---------|--------|
| POST | `/gateway/invoice` | Create payment invoice | ✅ |
| GET | `/gateway/invoice/{id}` | Get invoice status | ✅ |
| POST | `/gateway/invoice/{id}/expire` | Expire invoice | ✅ |
| POST | `/gateway/refund` | Request refund | ✅ |

**Vouchers:**
| Method | Endpoint | Purpose | Status |
|--------|----------|---------|--------|
| GET | `/vouchers/available` | Get available vouchers | ✅ |
| POST | `/vouchers/validate` | Validate voucher code | ✅ |

---

### 📜 9. Transactions History
**Status:** ✅ Implemented

| Method | Endpoint | Purpose | Status |
|--------|----------|---------|--------|
| GET | `/orders?status=completed` | Get completed orders | ✅ |
| GET | `/orders?status=cancelled` | Get cancelled orders | ✅ |
| GET | `/wallets/my/transactions` | Get wallet transactions | ✅ |
| GET | `/payments` | Get payment history | ✅ |

---

### 💬 10. Chat & Support
**Status:** ✅ Implemented

**Live Chat:**
| Method | Endpoint | Purpose | Status |
|--------|----------|---------|--------|
| GET | `/chat/conversations` | Get my conversations | ✅ |
| GET | `/chat/conversations/order/{id}` | Get order chat | ✅ |
| GET | `/chat/conversations/{id}/messages` | Get chat messages | ✅ |
| POST | `/chat/conversations/{id}/messages` | Send message | ✅ |
| POST | `/chat/conversations/{id}/read` | Mark messages as read | ✅ |
| GET | `/chat/unread-count` | Get unread messages count | ✅ |

**Support Tickets:**
| Method | Endpoint | Purpose | Status |
|--------|----------|---------|--------|
| GET | `/support/tickets` | Get my tickets | ✅ |
| POST | `/support/tickets` | Create support ticket | ✅ |
| GET | `/support/tickets/{id}` | Get ticket details | ✅ |
| POST | `/support/tickets/{id}/messages` | Add message to ticket | ✅ |
| POST | `/support/tickets/{id}/close` | Close ticket | ✅ |

**FAQ:**
| Method | Endpoint | Purpose | Status |
|--------|----------|---------|--------|
| GET | `/faq/categories` | Get FAQ categories | ✅ |
| GET | `/faq/categories/{id}` | Get category articles | ✅ |
| GET | `/faq/articles/{id}` | Get article details | ✅ |
| GET | `/faq/search` | Search FAQ | ✅ |
| GET | `/faq/featured` | Get featured articles | ✅ |

---

### ⭐ 11. Reviews & Ratings
**Status:** ✅ Implemented

| Method | Endpoint | Purpose | Status |
|--------|----------|---------|--------|
| GET | `/reviews` | Get reviews | ✅ |
| POST | `/reviews` | Submit review/rating | ✅ |
| GET | `/reviews/my-reviews` | Get my reviews | ✅ |
| GET | `/reviews/{id}` | Get review details | ✅ |
| PUT | `/reviews/{id}` | Update review | ✅ |

---

### 🔔 12. Notifications
**Status:** ✅ Implemented

| Method | Endpoint | Purpose | Status |
|--------|----------|---------|--------|
| GET | `/notifications` | Get all notifications | ✅ |
| GET | `/notifications/unread-count` | Get unread count | ✅ |
| PATCH | `/notifications/{id}/read` | Mark as read | ✅ |
| POST | `/notifications/read-all` | Mark all as read | ✅ |

---

### 👤 13. Profile Management
**Status:** ✅ Implemented

| Method | Endpoint | Purpose | Status |
|--------|----------|---------|--------|
| GET | `/auth/me` | Get profile | ✅ |
| PUT | `/auth/me` | Update profile | ✅ |
| POST | `/auth/me/profile-picture` | Upload profile picture | ✅ |
| GET | `/addresses` | Get saved addresses | ✅ |
| GET | `/orders` | Get order history | ✅ |
| GET | `/reviews/my-reviews` | Get my reviews | ✅ |

---

### 🔒 14. Security Features
**Status:** ✅ Implemented

| Method | Endpoint | Purpose | Status |
|--------|----------|---------|--------|
| GET | `/security/dashboard` | Get security overview | ✅ |
| POST | `/security/2fa/setup` | Setup 2FA | ✅ |
| POST | `/security/2fa/verify` | Verify 2FA code | ✅ |
| POST | `/security/2fa/disable` | Disable 2FA | ✅ |
| POST | `/security/biometric/enroll` | Enroll biometric | ✅ |
| POST | `/security/biometric/verify` | Verify biometric | ✅ |
| GET | `/security/audit/logs` | Get audit logs | ✅ |

---

### 📊 15. Analytics & Tracking
**Status:** ✅ Implemented

| Method | Endpoint | Purpose | Status |
|--------|----------|---------|--------|
| POST | `/analytics/events/track` | Track user events | ✅ |
| GET | `/analytics/dashboard` | Get user analytics | ✅ |

---

### 🌍 16. Geofencing
**Status:** ✅ Implemented

| Method | Endpoint | Purpose | Status |
|--------|----------|---------|--------|
| GET | `/geofences/nearby` | Get nearby geofences | ✅ |
| POST | `/geofences/location/check` | Check if in geofence | ✅ |

---

### 📱 17. Social Media Sharing
**Status:** ✅ Implemented

| Method | Endpoint | Purpose | Status |
|--------|----------|---------|--------|
| POST | `/social/orders/{id}/share` | Share order | ✅ |
| POST | `/social/referral/share` | Share referral code | ✅ |
| GET | `/social/my-shares` | Get my shares | ✅ |
| GET | `/social/platforms` | Get social platforms | ✅ |

---

### 📄 18. Document Verification
**Status:** ✅ Implemented

| Method | Endpoint | Purpose | Status |
|--------|----------|---------|--------|
| POST | `/documents/submit` | Submit document | ✅ |
| GET | `/documents/my-documents` | Get my documents | ✅ |
| GET | `/documents/types` | Get document types | ✅ |
| GET | `/documents/verification-status` | Get verification status | ✅ |

---

## 🏍️ RIDER APP (RIDERSIDE) - Required APIs

### 🔐 1. Authentication
**Status:** ✅ Implemented

| Method | Endpoint | Purpose | Status |
|--------|----------|---------|--------|
| POST | `/auth/login` | Login rider | ✅ |
| POST | `/auth/register` | Register rider | ✅ |
| POST | `/drivers/register` | Register driver profile | ✅ |
| GET | `/auth/me` | Get rider profile | ✅ |
| PUT | `/auth/me` | Update rider profile | ✅ |
| POST | `/auth/logout` | Logout | ✅ |

---

### 📋 2. Bookings Management
**Status:** ✅ Implemented

| Method | Endpoint | Purpose | Status |
|--------|----------|---------|--------|
| GET | `/orders?status=pending` | Get available bookings | ✅ |
| GET | `/orders?status=searching_driver` | Get searching bookings | ✅ |
| GET | `/orders?status=accepted` | Get accepted bookings | ✅ |
| GET | `/orders?status=picked_up` | Get in-progress bookings | ✅ |
| GET | `/orders?status=completed` | Get completed bookings | ✅ |
| GET | `/orders/{id}` | Get booking details | ✅ |
| PATCH | `/orders/{id}/status` | Update booking status | ✅ |

**Status Updates:**
- `pending` → `accepted` (Accept booking)
- `accepted` → `driver_arrived` (Arrived at pickup)
- `driver_arrived` → `picked_up` (Picked up item/passenger)
- `picked_up` → `in_progress` (On the way to destination)
- `in_progress` → `completed` (Delivered/Completed)
- Any status → `cancelled` (Cancel booking)

---

### 📍 3. Location & Tracking
**Status:** ✅ Implemented

| Method | Endpoint | Purpose | Status |
|--------|----------|---------|--------|
| PATCH | `/drivers/{id}/location` | Update driver location | ✅ |
| POST | `/tracking/driver/location` | Update live location | ✅ |
| GET | `/tracking/drivers/nearby` | Get nearby drivers | ✅ |
| GET | `/tracking/order/{id}/live` | Get order tracking | ✅ |

---

### 👤 4. Driver Profile
**Status:** ✅ Implemented

| Method | Endpoint | Purpose | Status |
|--------|----------|---------|--------|
| GET | `/drivers/{id}` | Get driver profile | ✅ |
| PATCH | `/drivers/{id}/status` | Update driver status (online/offline) | ✅ |
| GET | `/wallets/my/wallet` | Get wallet balance | ✅ |
| GET | `/wallets/my/validation` | Validate wallet balance | ✅ |

---

### 🎯 5. Driver Missions
**Status:** ✅ Implemented

| Method | Endpoint | Purpose | Status |
|--------|----------|---------|--------|
| GET | `/driver/missions` | Get available missions | ✅ |
| POST | `/driver/missions/{id}/claim` | Claim mission reward | ✅ |

---

### 📜 6. History & Earnings
**Status:** ✅ Implemented

| Method | Endpoint | Purpose | Status |
|--------|----------|---------|--------|
| GET | `/orders?status=completed` | Get completed orders | ✅ |
| GET | `/wallets/my/transactions` | Get earnings history | ✅ |
| GET | `/payments` | Get payment history | ✅ |

---

### 💬 7. Chat
**Status:** ✅ Implemented

| Method | Endpoint | Purpose | Status |
|--------|----------|---------|--------|
| GET | `/chat/conversations/order/{id}` | Get order chat | ✅ |
| POST | `/chat/conversations/{id}/messages` | Send message | ✅ |
| GET | `/chat/conversations/{id}/messages` | Get messages | ✅ |

---

### 📸 8. Proof of Delivery
**Status:** ✅ Implemented

| Method | Endpoint | Purpose | Status |
|--------|----------|---------|--------|
| POST | `/orders/{id}/upload-proof` | Upload proof photo | ✅ |

---

### 🔔 9. Notifications
**Status:** ✅ Implemented

| Method | Endpoint | Purpose | Status |
|--------|----------|---------|--------|
| GET | `/notifications` | Get notifications | ✅ |
| GET | `/notifications/unread-count` | Get unread count | ✅ |
| PATCH | `/notifications/{id}/read` | Mark as read | ✅ |
| POST | `/auth/fcm-token` | Register FCM token | ✅ |

---

### 📄 10. Document Submission
**Status:** ✅ Implemented

| Method | Endpoint | Purpose | Status |
|--------|----------|---------|--------|
| POST | `/documents/submit` | Submit driver documents | ✅ |
| GET | `/documents/my-documents` | Get my documents | ✅ |
| GET | `/documents/verification-status` | Check verification status | ✅ |

---

## 🔧 UTILITY APIs (Both Apps)

### 🗺️ Google Maps Integration
**Status:** ✅ Implemented

| Method | Endpoint | Purpose | Status |
|--------|----------|---------|--------|
| GET | `/google-places/autocomplete` | Place autocomplete | ✅ |
| GET | `/google-places/details` | Place details | ✅ |
| GET | `/google-places/directions` | Get directions | ✅ |

---

### 📏 Distance Calculator
**Status:** ✅ Implemented

| Method | Endpoint | Purpose | Status |
|--------|----------|---------|--------|
| GET | `/distance/calculate` | Calculate distance | ✅ |
| GET | `/distance/overall` | Get distance stats | ✅ |

---

### 🏥 Health Check
**Status:** ✅ Implemented

| Method | Endpoint | Purpose | Status |
|--------|----------|---------|--------|
| GET | `/ping` | Check API status | ✅ |
| GET | `/health/liveness` | Liveness probe | ✅ |
| GET | `/health/readiness` | Readiness probe | ✅ |

---

## 📊 SUMMARY

### Customer App (FRONTEND)
- **Total Endpoints:** 150+
- **Status:** ✅ All Implemented
- **Categories:** 18

### Rider App (RIDERSIDE)
- **Total Endpoints:** 50+
- **Status:** ✅ All Implemented
- **Categories:** 10

### Total API Endpoints
- **Total:** 200+ endpoints
- **Status:** ✅ 100% Implemented
- **Backend:** Laravel 10 + Sanctum
- **Database:** MySQL
- **Real-time:** Pusher/WebSockets
- **Payment:** Xendit Integration
- **Maps:** Google Maps API

---

## 🔑 API Keys Required

### Google Maps API
```
AIzaSyD3A8EoUI7NPPh3SNsxh_ZxxYKSZUzlsg4
```

**Required Services:**
- ✅ Maps JavaScript API
- ✅ Places API
- ✅ Directions API
- ✅ Geocoding API
- ✅ Distance Matrix API

### Xendit (Payment Gateway)
- API Key: (configured in backend .env)
- Webhook URL: `{BASE_URL}/api/v1/webhooks/payments/xendit`

### Firebase (Push Notifications)
- FCM Server Key: (configured in backend)
- Client config: google-services.json (Android)
- Client config: GoogleService-Info.plist (iOS)

---

## 🚀 Testing

### Test User (Customer)
```
Email: carlkelvinmanahan014@gmail.com
Password: password123
User ID: 928
```

### Test Endpoints
```bash
# Health Check
curl http://127.0.0.1:8000/api/v1/ping

# Login
curl -X POST http://127.0.0.1:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"carlkelvinmanahan014@gmail.com","password":"password123"}'

# Get Services
curl http://127.0.0.1:8000/api/v1/services

# Get Profile (with token)
curl http://127.0.0.1:8000/api/v1/auth/me \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## 📝 Notes

1. **All endpoints are implemented and working** ✅
2. **Backend is running** on `http://127.0.0.1:8000`
3. **Customer app is running** on `http://localhost:54005`
4. **Rider app is running** on `http://localhost:54006`
5. **Google Maps markers** are now purple (pickup) and red (destination)
6. **Routes/polylines** have been removed from maps
7. **Authentication** uses Laravel Sanctum Bearer tokens
8. **Rate limiting** is configured for all endpoints
9. **CORS** is enabled for frontend access
10. **File uploads** support images and documents

---

**Last Updated:** May 2, 2026  
**Backend Version:** v1  
**Status:** ✅ Production Ready
