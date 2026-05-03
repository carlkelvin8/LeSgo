# LeSGo App - Third-Party API Requirements

**Last Updated:** May 2, 2026  
**App:** LeSGo (Delivery, Ride, Food, Shopping)

---

## 📋 Overview

This document lists all external/third-party APIs required for the LeSGo mobile application (Customer + Rider apps).

---

## ✅ CURRENTLY CONFIGURED

### 1. 🗺️ Google Maps Platform APIs
**Status:** ✅ Active  
**API Key:** `AIzaSyD3A8EoUI7NPPh3SNsxh_ZxxYKSZUzlsg4`  
**Provider:** Google Cloud Platform

**Required APIs:**
- ✅ **Maps SDK for Android** - Display maps on Android
- ✅ **Maps SDK for iOS** - Display maps on iOS
- ✅ **Maps JavaScript API** - Display maps on Web
- ✅ **Geocoding API** - Convert addresses to coordinates
- ✅ **Reverse Geocoding API** - Convert coordinates to addresses
- ✅ **Places API** - Address autocomplete and search
- ✅ **Directions API** - Get routes between locations
- ✅ **Distance Matrix API** - Calculate distances and travel times

**Used In:**
- Customer App: Booking screens (LesGo, LesRide, LesEat, LesBuy)
- Rider App: Map view, navigation, location tracking
- Backend: Distance calculation, fare estimation

**Pricing:**
- Free tier: $200 credit/month
- Typical cost: $50-150/month
- Pay-as-you-go after free tier

**Configuration:**
```
Frontend: 
- FRONTEND/android/app/src/main/AndroidManifest.xml
- FRONTEND/ios/Runner/AppDelegate.swift
- FRONTEND/web/index.html

Backend:
- BACKEND/lesgo-api/.env (GOOGLE_MAPS_API_KEY)
- Proxy endpoints: /api/v1/google-places/*
```

**Documentation:** https://developers.google.com/maps

---

### 2. 📧 Gmail SMTP (Email Service)
**Status:** ✅ Active  
**Provider:** Google Gmail

**Credentials:**
```
MAIL_HOST=smtp.gmail.com
MAIL_PORT=465
MAIL_USERNAME=gghsoftware2024@gmail.com
MAIL_PASSWORD=xsxjjutsibmulzok (App Password)
MAIL_ENCRYPTION=ssl
```

**Used For:**
- Forgot password OTP emails
- Password reset emails
- Account verification emails
- Order receipts (future)
- Promotional emails (future)

**Pricing:** FREE (Gmail account)

**Limitations:**
- 500 emails/day limit
- Not recommended for production scale
- Consider upgrading to SendGrid/Mailgun for production

**Configuration:**
```
Backend: BACKEND/lesgo-api/.env
```

---

### 3. 📱 Twilio (SMS/OTP Service)
**Status:** ✅ Configured  
**Provider:** Twilio

**Credentials:**
```
TWILIO_SID=AC0fa6e9808609b73de12058af0907ac48
TWILIO_AUTH_TOKEN=bf9c03f1fe72c36a70e7073efb803a79
TWILIO_FROM=+639498787542
TWILIO_VERIFY_SERVICE_SID=VA5e6d745859fffffccac5ee1c402ecbc6
```

**Used For:**
- OTP verification (phone number verification)
- SMS notifications for order updates
- SMS alerts for riders
- Two-factor authentication (2FA)

**Pricing:**
- $0.0075 per SMS (Philippines)
- ~₱0.40 per SMS
- Pay-as-you-go

**Configuration:**
```
Backend: BACKEND/lesgo-api/.env
```

**Documentation:** https://www.twilio.com/docs

---

### 4. 🔄 Laravel Reverb (WebSocket Server)
**Status:** ✅ Configured  
**Provider:** Laravel (Self-hosted)

**Credentials:**
```
REVERB_APP_ID=345288
REVERB_APP_KEY=8cwrfdifchs4011diljr
REVERB_APP_SECRET=rt5bri9qwdssucvijqtr
REVERB_HOST=localhost
REVERB_PORT=8080
REVERB_SCHEME=http
```

**Used For:**
- Real-time order status updates
- Live driver location tracking
- Live chat messages
- Push notifications (in-app)
- Real-time notifications

**Pricing:** FREE (self-hosted)

**Alternative:** Pusher (paid service, $49/month)

**Configuration:**
```
Backend: BACKEND/lesgo-api/.env
Frontend: Connect via WebSocket client
```

**Documentation:** https://reverb.laravel.com

---

## ⚠️ CONFIGURED BUT NOT ACTIVE

### 5. 💳 Xendit (Payment Gateway)
**Status:** ⚠️ Configured but keys empty  
**Provider:** Xendit (Indonesia/Philippines)

**Required Credentials:**
```
XENDIT_SECRET_KEY=(empty - needs to be filled)
XENDIT_PUBLIC_KEY=(empty - needs to be filled)
XENDIT_WEBHOOK_TOKEN=(empty - needs to be filled)
XENDIT_SUCCESS_URL=https://app.lesgo.ph/payment/success
XENDIT_FAILURE_URL=https://app.lesgo.ph/payment/failed
```

**Used For:**
- Credit/Debit card payments
- E-wallet payments (GCash, GrabPay, PayMaya)
- Online banking
- Payment invoices
- Refunds

**Pricing:**
- 2.9% + ₱15 per transaction (cards)
- 2% per transaction (e-wallets)

**Setup Required:**
1. Create Xendit account: https://dashboard.xendit.co/register
2. Get API keys from dashboard
3. Configure webhook URL
4. Add keys to `.env` file

**Configuration:**
```
Backend: BACKEND/lesgo-api/.env
API Endpoints: /api/v1/gateway/*
Webhook: /api/v1/webhooks/payments/xendit
```

**Documentation:** https://developers.xendit.co

---

### 6. 📱 Semaphore (SMS Service - Philippines)
**Status:** ⚠️ Configured but key empty  
**Provider:** Semaphore (Philippines)

**Required Credentials:**
```
SEMAPHORE_API_KEY=(empty - needs to be filled)
SEMAPHORE_SENDER_NAME=LESGO
```

**Used For:**
- Backup SMS service (if Twilio fails)
- Bulk SMS for promotions
- SMS notifications

**Pricing:**
- ₱0.50 - ₱1.00 per SMS
- Prepaid credits

**Setup Required:**
1. Create account: https://semaphore.co
2. Purchase SMS credits
3. Get API key
4. Add to `.env` file

**Configuration:**
```
Backend: BACKEND/lesgo-api/.env
```

**Documentation:** https://semaphore.co/docs

---

### 7. 💰 GCash & Maya (Payment Webhooks)
**Status:** ⚠️ Configured but secrets empty  
**Provider:** GCash, Maya (Philippines)

**Required Credentials:**
```
GCASH_WEBHOOK_SECRET=(empty - needs to be filled)
MAYA_WEBHOOK_SECRET=(empty - needs to be filled)
```

**Used For:**
- Direct GCash payments
- Direct Maya payments
- Payment verification
- Webhook security

**Setup Required:**
1. Register as GCash merchant
2. Register as Maya merchant
3. Get webhook secrets
4. Configure webhook URLs

**Configuration:**
```
Backend: BACKEND/lesgo-api/.env
Webhook: /api/v1/webhooks/payments/gcash
Webhook: /api/v1/webhooks/payments/maya
```

---

## ❌ NOT YET CONFIGURED

### 8. 🔔 Firebase Cloud Messaging (FCM)
**Status:** ❌ Not configured  
**Provider:** Google Firebase

**Required:**
- Firebase project
- `google-services.json` (Android)
- `GoogleService-Info.plist` (iOS)
- Server key for backend

**Used For:**
- Push notifications to customers
- Push notifications to riders
- Order status notifications
- Chat message notifications
- Promotional notifications

**Pricing:** FREE (unlimited)

**Setup Required:**
1. Create Firebase project: https://console.firebase.google.com
2. Add Android app (package: `com.lesgo.customer`)
3. Add iOS app (bundle ID: `com.lesgo.customer`)
4. Download config files
5. Add to Flutter project
6. Configure backend with server key

**Configuration:**
```
Frontend:
- FRONTEND/android/app/google-services.json
- FRONTEND/ios/Runner/GoogleService-Info.plist

Rider:
- RIDERSIDE/android/app/google-services.json
- RIDERSIDE/ios/Runner/GoogleService-Info.plist

Backend:
- BACKEND/lesgo-api/storage/app/firebase-credentials.json
- BACKEND/lesgo-api/.env (FIREBASE_PROJECT_ID)
```

**Documentation:** https://firebase.google.com/docs/cloud-messaging

---

### 9. ☁️ AWS S3 (Cloud Storage)
**Status:** ❌ Not configured  
**Provider:** Amazon Web Services

**Required Credentials:**
```
AWS_ACCESS_KEY_ID=(empty)
AWS_SECRET_ACCESS_KEY=(empty)
AWS_DEFAULT_REGION=us-east-1
AWS_BUCKET=(empty)
```

**Used For:**
- Profile pictures
- Proof of delivery images
- Restaurant/store images
- Menu item images
- Document uploads (driver verification)

**Pricing:**
- $0.023 per GB/month (storage)
- $0.09 per GB (data transfer)
- ~$5-20/month typical usage

**Alternative:** Google Cloud Storage, DigitalOcean Spaces

**Setup Required:**
1. Create AWS account
2. Create S3 bucket
3. Create IAM user with S3 access
4. Get access keys
5. Configure Laravel filesystem

**Configuration:**
```
Backend: BACKEND/lesgo-api/.env
Laravel: config/filesystems.php
```

**Documentation:** https://aws.amazon.com/s3/

---

### 10. 🔐 Google Sign-In (OAuth)
**Status:** ⚠️ Partially configured  
**Provider:** Google Cloud Platform

**Required:**
- OAuth 2.0 Client ID (Web)
- OAuth 2.0 Client ID (Android)
- OAuth 2.0 Client ID (iOS)

**Current:**
```dart
// FRONTEND/lib/core/services/google_auth_service.dart
static const _webClientId = 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com';
```

**Used For:**
- Sign in with Google (customer app)
- Sign in with Google (rider app)
- Quick registration

**Pricing:** FREE

**Setup Required:**
1. Go to Google Cloud Console
2. Enable Google Sign-In API
3. Create OAuth 2.0 credentials
4. Configure consent screen
5. Add authorized domains
6. Update Flutter code with client IDs

**Configuration:**
```
Frontend: FRONTEND/lib/core/services/google_auth_service.dart
Backend: BACKEND/lesgo-api/app/Http/Controllers/Api/Auth/GoogleAuthController.php
```

**Documentation:** https://developers.google.com/identity

---

### 11. 📊 Google Analytics
**Status:** ❌ Not configured  
**Provider:** Google

**Required:**
- Measurement ID
- API Secret (for server-side events)

**Used For:**
- User behavior tracking
- App performance monitoring
- Conversion tracking
- User demographics
- Retention analysis

**Pricing:** FREE

**Setup Required:**
1. Create Google Analytics 4 property
2. Get Measurement ID
3. Add to Flutter app
4. Configure events

**Configuration:**
```
Frontend: pubspec.yaml (firebase_analytics package)
```

**Documentation:** https://firebase.google.com/docs/analytics

---

### 12. 🗺️ Mapbox (Alternative to Google Maps)
**Status:** ❌ Not configured  
**Provider:** Mapbox

**Used For:**
- Alternative map provider (cheaper than Google)
- Custom map styling
- Offline maps
- Navigation

**Pricing:**
- Free tier: 50,000 map loads/month
- $5 per 1,000 loads after free tier
- Much cheaper than Google Maps

**Note:** Consider switching to Mapbox to reduce costs

**Documentation:** https://www.mapbox.com

---

## 📊 SUMMARY

### ✅ Active (4 APIs)
1. ✅ Google Maps Platform - $50-150/month
2. ✅ Gmail SMTP - FREE
3. ✅ Twilio SMS - Pay-as-you-go
4. ✅ Laravel Reverb - FREE (self-hosted)

### ⚠️ Configured but Inactive (4 APIs)
5. ⚠️ Xendit Payment Gateway - Needs API keys
6. ⚠️ Semaphore SMS - Needs API key
7. ⚠️ GCash/Maya - Needs webhook secrets
8. ⚠️ Google Sign-In - Needs OAuth client IDs

### ❌ Not Configured (4 APIs)
9. ❌ Firebase FCM - Push notifications
10. ❌ AWS S3 - Cloud storage
11. ❌ Google Analytics - Analytics
12. ❌ Mapbox - Alternative maps

---

## 💰 COST ESTIMATE

### Current Monthly Costs:
| Service | Cost |
|---------|------|
| Google Maps | $50 - $150 |
| Gmail SMTP | FREE |
| Twilio SMS | ~₱500 - ₱2,000 |
| Laravel Reverb | FREE |
| **TOTAL** | **~₱3,000 - ₱10,000/month** |

### With All APIs Activated:
| Service | Cost |
|---------|------|
| Google Maps | $50 - $150 |
| Gmail SMTP | FREE |
| Twilio SMS | ₱500 - ₱2,000 |
| Laravel Reverb | FREE |
| Xendit | 2.9% per transaction |
| Semaphore SMS | ₱500 - ₱1,000 |
| Firebase FCM | FREE |
| AWS S3 | $5 - $20 |
| Google Analytics | FREE |
| **TOTAL** | **~₱5,000 - ₱15,000/month** |

*Note: Payment gateway fees are per-transaction, not monthly*

---

## 🎯 PRIORITY SETUP

### 🔴 CRITICAL (Before Launch)
1. ✅ Google Maps - Already active
2. ❌ **Firebase FCM** - Push notifications essential
3. ⚠️ **Xendit** - Payment processing essential
4. ⚠️ **Google Sign-In** - User convenience

### 🟡 HIGH PRIORITY (Within 1 month)
5. ⚠️ Semaphore SMS - Backup SMS service
6. ❌ AWS S3 - Scalable file storage
7. ⚠️ GCash/Maya - Popular payment methods in PH

### 🟢 MEDIUM PRIORITY (Within 3 months)
8. ❌ Google Analytics - Business insights
9. Consider Mapbox - Cost optimization

---

## 🔒 SECURITY NOTES

1. **Never commit API keys to Git**
   - All keys in `.env` file
   - `.env` is in `.gitignore`

2. **Restrict API keys**
   - Google Maps: Restrict by app bundle ID
   - Set IP restrictions where possible
   - Enable only required APIs

3. **Rotate keys regularly**
   - Change every 3-6 months
   - Immediately if compromised

4. **Monitor usage**
   - Set up billing alerts
   - Review API usage weekly
   - Watch for unusual spikes

5. **Use environment-specific keys**
   - Development keys for testing
   - Production keys for live app
   - Never mix them

---

## 📞 SUPPORT CONTACTS

### Google Maps
- Console: https://console.cloud.google.com
- Support: https://support.google.com/maps

### Twilio
- Dashboard: https://console.twilio.com
- Support: https://support.twilio.com

### Xendit
- Dashboard: https://dashboard.xendit.co
- Support: support@xendit.co

### Firebase
- Console: https://console.firebase.google.com
- Support: https://firebase.google.com/support

---

## 📝 NEXT STEPS

1. **Setup Firebase FCM** (Critical)
   - Create Firebase project
   - Add Android/iOS apps
   - Download config files
   - Implement push notifications

2. **Activate Xendit** (Critical)
   - Create merchant account
   - Get API keys
   - Test payment flow
   - Configure webhooks

3. **Complete Google Sign-In** (High Priority)
   - Create OAuth credentials
   - Update Flutter code
   - Test sign-in flow

4. **Setup AWS S3** (High Priority)
   - Create bucket
   - Configure IAM
   - Migrate file uploads

5. **Add Google Analytics** (Medium Priority)
   - Create GA4 property
   - Add to Flutter
   - Configure events

---

**Document Version:** 1.0  
**Last Updated:** May 2, 2026  
**Maintained By:** Development Team
