# API Keys Required for LesGo App

## Currently Used API Keys

### 1. **Google Maps API Key** ✅ (Already Configured)
**Current Key:** `AIzaSyD3A8EoUI7NPPh3SNsxh_ZxxYKSZUzlsg4`

**Used For:**
- 📍 Map display (Google Maps widget)
- 🔍 Address search and autocomplete
- 📌 Geocoding (converting addresses to lat/lng)
- 🗺️ Reverse geocoding (converting lat/lng to addresses)
- 🚗 Distance calculation
- 🛣️ Directions and routing

**APIs to Enable in Google Cloud Console:**
- Maps SDK for Android
- Maps SDK for iOS
- Maps JavaScript API (for web)
- Geocoding API
- Places API
- Directions API
- Distance Matrix API

**Monthly Cost Estimate:** 
- Free tier: $200 credit/month
- Typical usage: ~$50-150/month depending on active users

---

## Additional API Keys Needed (Optional/Future)

### 2. **Firebase Cloud Messaging (FCM)** 🔔
**Status:** Not yet configured

**Used For:**
- Push notifications to customers
- Push notifications to riders
- Real-time order updates
- Chat message notifications

**Setup Required:**
- Create Firebase project
- Add `google-services.json` (Android)
- Add `GoogleService-Info.plist` (iOS)
- Configure FCM in backend

**Cost:** FREE (unlimited notifications)

---

### 3. **Payment Gateway API Keys** 💳
**Status:** Not yet configured

**Options:**

#### A. **PayMongo** (Philippines)
- Public Key
- Secret Key
- Webhook Secret

**Used For:**
- Credit/Debit card payments
- GCash
- GrabPay
- Online banking

**Cost:** 3.5% + ₱15 per transaction

#### B. **PayPal**
- Client ID
- Secret Key

**Cost:** 3.9% + $0.30 per transaction

#### C. **Stripe**
- Publishable Key
- Secret Key
- Webhook Secret

**Cost:** 3.5% + ₱15 per transaction (Philippines)

---

### 4. **SMS API** 📱
**Status:** Not yet configured

**Options:**

#### A. **Semaphore** (Philippines)
- API Key

**Used For:**
- OTP verification
- Order status SMS
- Rider notifications

**Cost:** ₱0.50 - ₱1.00 per SMS

#### B. **Twilio**
- Account SID
- Auth Token
- Phone Number

**Cost:** $0.0075 per SMS (Philippines)

---

### 5. **Email Service** 📧
**Status:** Not yet configured

**Options:**

#### A. **SendGrid**
- API Key

**Used For:**
- Email verification
- Order receipts
- Password reset
- Promotional emails

**Cost:** FREE (100 emails/day), Paid: $14.95/month (40,000 emails)

#### B. **Mailgun**
- API Key
- Domain

**Cost:** FREE (5,000 emails/month)

---

### 6. **Cloud Storage** ☁️
**Status:** Using local storage

**Options:**

#### A. **AWS S3**
- Access Key ID
- Secret Access Key
- Bucket Name

**Used For:**
- Profile pictures
- Proof of delivery images
- Restaurant/store images
- Document uploads

**Cost:** ~$0.023 per GB/month

#### B. **Google Cloud Storage**
- Service Account JSON
- Bucket Name

**Cost:** ~$0.020 per GB/month

---

### 7. **Analytics** 📊
**Status:** Not yet configured

#### A. **Google Analytics**
- Measurement ID
- API Secret

**Used For:**
- User behavior tracking
- App performance monitoring
- Conversion tracking

**Cost:** FREE

#### B. **Mixpanel**
- Project Token

**Cost:** FREE (up to 100K events/month)

---

## Priority Recommendations

### **MUST HAVE (Before Launch):**
1. ✅ **Google Maps API** - Already configured
2. 🔔 **Firebase FCM** - For push notifications
3. 💳 **Payment Gateway** - Choose one (PayMongo recommended for PH)
4. 📱 **SMS API** - For OTP verification (Semaphore recommended for PH)

### **SHOULD HAVE (Within 1-3 months):**
5. 📧 **Email Service** - For receipts and notifications
6. ☁️ **Cloud Storage** - For scalability and reliability

### **NICE TO HAVE (Future):**
7. 📊 **Analytics** - For business insights

---

## Current Configuration Files

### Frontend:
- `FRONTEND/android/app/src/main/AndroidManifest.xml` - Google Maps API key
- `FRONTEND/ios/Runner/AppDelegate.swift` - Google Maps API key
- `FRONTEND/web/index.html` - Google Maps JavaScript API

### Backend:
- `BACKEND/lesgo-api/.env` - All API keys should be stored here

---

## Estimated Monthly Costs

| Service | Cost (Monthly) |
|---------|----------------|
| Google Maps API | $50 - $150 |
| Firebase FCM | FREE |
| Payment Gateway (PayMongo) | 3.5% per transaction |
| SMS (Semaphore) | ₱500 - ₱2,000 |
| Email (SendGrid) | FREE - $15 |
| Cloud Storage (AWS S3) | $5 - $20 |
| **TOTAL** | **~₱3,000 - ₱10,000/month** |

*Note: Costs vary based on usage and number of active users*

---

## Security Best Practices

1. **Never commit API keys to Git**
   - Use `.env` files
   - Add `.env` to `.gitignore`

2. **Restrict API keys**
   - Set IP restrictions
   - Set app restrictions (bundle ID/package name)
   - Enable only required APIs

3. **Rotate keys regularly**
   - Change keys every 3-6 months
   - Immediately rotate if compromised

4. **Monitor usage**
   - Set up billing alerts
   - Review API usage weekly
   - Watch for unusual spikes

---

## Next Steps

1. **Enable Firebase FCM** - For push notifications
2. **Choose and setup Payment Gateway** - PayMongo recommended
3. **Setup SMS API** - Semaphore recommended for Philippines
4. **Configure Email Service** - SendGrid free tier
5. **Setup Cloud Storage** - AWS S3 or Google Cloud Storage

---

**Last Updated:** April 28, 2026
