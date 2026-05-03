# Google Maps API - iOS & Android Only

**API Key:** `AIzaSyD3A8EoUI7NPPh3SNsxh_ZxxYKSZUzlsg4`  
**Platform:** Mobile Apps Only (iOS + Android)

---

## ✅ REQUIRED APIs (5 APIs)

### 1. 🗺️ Maps SDK for Android
**Enable:** https://console.cloud.google.com/apis/library/maps-android-backend.googleapis.com

**Used For:**
- Display interactive maps on Android
- Show markers (pickup, destination)
- User location tracking
- Map gestures (zoom, pan, rotate)

**Price:** $7 per 1,000 map loads  
**Free Tier:** 28,000 loads/month

---

### 2. 🗺️ Maps SDK for iOS
**Enable:** https://console.cloud.google.com/apis/library/maps-ios-backend.googleapis.com

**Used For:**
- Display interactive maps on iOS
- Show markers (pickup, destination)
- User location tracking
- Map gestures (zoom, pan, rotate)

**Price:** $7 per 1,000 map loads  
**Free Tier:** 28,000 loads/month

---

### 3. 📍 Geocoding API
**Enable:** https://console.cloud.google.com/apis/library/geocoding-backend.googleapis.com

**Used For:**
- **Forward Geocoding:** Address → Coordinates
  - Example: "SM Manila" → (14.5995, 120.9842)
- **Reverse Geocoding:** Coordinates → Address
  - Example: (14.5995, 120.9842) → "SM Manila, Ermita, Manila"

**Price:** $5 per 1,000 requests  
**Free Tier:** 40,000 requests/month

---

### 4. 🔍 Places API
**Enable:** https://console.cloud.google.com/apis/library/places-backend.googleapis.com

**Used For:**
- Address search autocomplete
- Place suggestions while typing
- Get place details (name, address, coordinates)
- Search nearby places

**Example:**
```
User types: "Jollibee"
Shows: 
- Jollibee - SM Manila
- Jollibee - Robinsons Place
- Jollibee - MOA
```

**Price:** 
- Autocomplete: $2.83 per session
- Place Details: $17 per 1,000 requests

**Free Tier:** 
- Autocomplete: 70,000 sessions/month
- Details: 11,000 requests/month

---

### 5. 📏 Distance Matrix API
**Enable:** https://console.cloud.google.com/apis/library/distance-matrix-backend.googleapis.com

**Used For:**
- Calculate distance between pickup and destination
- Calculate travel time
- Fare estimation (distance-based pricing)
- Find nearest driver

**Example:**
```
From: SM Manila (14.5995, 120.9842)
To: MOA (14.5369, 120.9820)
Result:
  - Distance: 8.2 km
  - Duration: 18 minutes
  - Duration in traffic: 25 minutes
```

**Price:** $5 per 1,000 elements  
**Free Tier:** 40,000 elements/month

---

## ❌ NOT NEEDED (Web Only)

### ~~Maps JavaScript API~~
**Not needed** - Only for web browsers  
**Skip this** - Your app is mobile only

### ~~Directions API~~
**Not needed** - You removed routes/polylines from map  
**Skip this** - Only needed if showing route lines

---

## 🔧 HOW TO ENABLE

### Step 1: Go to Google Cloud Console
https://console.cloud.google.com/

### Step 2: Select Project
Click project dropdown → Select your LeSGo project

### Step 3: Enable Each API
1. Click **APIs & Services** → **Library**
2. Search for API name
3. Click on the API
4. Click **ENABLE** button
5. Repeat for all 5 APIs

### Quick Links:
- [Maps SDK for Android](https://console.cloud.google.com/apis/library/maps-android-backend.googleapis.com)
- [Maps SDK for iOS](https://console.cloud.google.com/apis/library/maps-ios-backend.googleapis.com)
- [Geocoding API](https://console.cloud.google.com/apis/library/geocoding-backend.googleapis.com)
- [Places API](https://console.cloud.google.com/apis/library/places-backend.googleapis.com)
- [Distance Matrix API](https://console.cloud.google.com/apis/library/distance-matrix-backend.googleapis.com)

---

## 🔒 SECURITY: API KEY RESTRICTIONS

### Step 1: Go to Credentials
1. Go to **APIs & Services** → **Credentials**
2. Find your API key: `AIzaSyD3A8EoUI7NPPh3SNsxh_ZxxYKSZUzlsg4`
3. Click **Edit** (pencil icon)

### Step 2: Set Application Restrictions

#### Option A: Restrict by Android App
- Select **Android apps**
- Click **Add an item**
- Package name: `com.lesgo.customer`
- SHA-1 fingerprint: (get from your keystore)
- Click **Add an item** again
- Package name: `com.lesgo.rider`
- SHA-1 fingerprint: (get from your keystore)

**How to get SHA-1:**
```bash
# Debug keystore
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# Release keystore
keytool -list -v -keystore /path/to/your/keystore.jks -alias your-alias
```

#### Option B: Restrict by iOS App
- Select **iOS apps**
- Click **Add an item**
- Bundle ID: `com.lesgo.customer`
- Click **Add an item** again
- Bundle ID: `com.lesgo.rider`

### Step 3: Set API Restrictions
- Select **Restrict key**
- Check these 5 APIs:
  - ✅ Maps SDK for Android
  - ✅ Maps SDK for iOS
  - ✅ Geocoding API
  - ✅ Places API
  - ✅ Distance Matrix API
- Click **Save**

---

## 💰 COST ESTIMATE

### Free Tier (Monthly)
**$200 credit** = Covers approximately:
- 28,000 map loads
- 40,000 geocoding requests
- 70,000 autocomplete sessions
- 40,000 distance calculations

### Typical Usage (1,000 active users/month)

| API | Usage | Cost |
|-----|-------|------|
| Maps SDK | 30,000 loads | $7.00 |
| Geocoding | 10,000 requests | $2.50 |
| Places Autocomplete | 5,000 sessions | $0.71 |
| Distance Matrix | 15,000 elements | $3.75 |
| **TOTAL** | | **$13.96** |

✅ **Well within $200 free tier!**

### At Scale (10,000 active users/month)

| API | Usage | Cost |
|-----|-------|------|
| Maps SDK | 300,000 loads | $70.00 |
| Geocoding | 100,000 requests | $25.00 |
| Places Autocomplete | 50,000 sessions | $7.08 |
| Distance Matrix | 150,000 elements | $37.50 |
| **TOTAL** | | **$139.58** |

✅ **Still within $200 free tier!**

---

## 📱 APP CONFIGURATION

### Android Configuration

**File:** `FRONTEND/android/app/src/main/AndroidManifest.xml`

Add inside `<application>` tag:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="AIzaSyD3A8EoUI7NPPh3SNsxh_ZxxYKSZUzlsg4"/>
```

**File:** `RIDERSIDE/android/app/src/main/AndroidManifest.xml`

Add inside `<application>` tag:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="AIzaSyD3A8EoUI7NPPh3SNsxh_ZxxYKSZUzlsg4"/>
```

---

### iOS Configuration

**File:** `FRONTEND/ios/Runner/AppDelegate.swift`

Add at the top:
```swift
import GoogleMaps
```

Add inside `application` function:
```swift
GMSServices.provideAPIKey("AIzaSyD3A8EoUI7NPPh3SNsxh_ZxxYKSZUzlsg4")
```

Full example:
```swift
import UIKit
import Flutter
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyD3A8EoUI7NPPh3SNsxh_ZxxYKSZUzlsg4")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

**File:** `RIDERSIDE/ios/Runner/AppDelegate.swift`

Same configuration as above.

---

## 🧪 TESTING

### Test on Android
```bash
cd FRONTEND
flutter run -d <android-device-id>
```

### Test on iOS
```bash
cd FRONTEND
flutter run -d <ios-device-id>
```

### What to Test:
1. ✅ Map displays correctly
2. ✅ Purple marker shows at pickup location
3. ✅ Red marker shows at destination
4. ✅ Address search works (autocomplete)
5. ✅ Tap map to select location
6. ✅ Current location button works
7. ✅ Distance calculation works
8. ✅ Fare estimation works

---

## ⚠️ COMMON ISSUES

### Issue 1: Map shows blank/gray
**Cause:** Maps SDK not enabled  
**Fix:** Enable Maps SDK for Android/iOS

### Issue 2: "API key not valid"
**Cause:** Wrong API key or restrictions  
**Fix:** 
- Check API key is correct
- Check package name/bundle ID matches
- Check SHA-1 fingerprint (Android)

### Issue 3: Address search not working
**Cause:** Places API not enabled  
**Fix:** Enable Places API

### Issue 4: Distance calculation fails
**Cause:** Distance Matrix API not enabled  
**Fix:** Enable Distance Matrix API

### Issue 5: "REQUEST_DENIED"
**Cause:** Billing not enabled  
**Fix:** Enable billing in Google Cloud Console

---

## 📊 MONITORING

### Set Up Billing Alerts
1. Go to **Billing** → **Budgets & alerts**
2. Create budget: **$200/month**
3. Set alerts at: **50%, 90%, 100%**
4. Add your email

### Monitor API Usage
1. Go to **APIs & Services** → **Dashboard**
2. View usage for each API
3. Check daily/weekly trends
4. Watch for unusual spikes

---

## ✅ QUICK CHECKLIST

### Before Launch:
- [ ] Enable Maps SDK for Android
- [ ] Enable Maps SDK for iOS
- [ ] Enable Geocoding API
- [ ] Enable Places API
- [ ] Enable Distance Matrix API
- [ ] Set API key restrictions (package name/bundle ID)
- [ ] Set API restrictions (select 5 APIs only)
- [ ] Add API key to Android app (AndroidManifest.xml)
- [ ] Add API key to iOS app (AppDelegate.swift)
- [ ] Test on Android device
- [ ] Test on iOS device
- [ ] Set up billing alerts
- [ ] Monitor usage for 1 week

---

## 📞 SUPPORT

### Google Maps Platform
- **Documentation:** https://developers.google.com/maps/documentation
- **Support:** https://support.google.com/maps
- **Pricing:** https://mapsplatform.google.com/pricing/

### Get Help
- **Stack Overflow:** https://stackoverflow.com/questions/tagged/google-maps
- **GitHub Issues:** https://github.com/flutter/flutter/issues

---

## 📋 SUMMARY

### ✅ Enable These 5 APIs:
1. Maps SDK for Android
2. Maps SDK for iOS
3. Geocoding API
4. Places API
5. Distance Matrix API

### ❌ Skip These (Not Needed):
- ~~Maps JavaScript API~~ (Web only)
- ~~Directions API~~ (Routes removed)
- ~~Geolocation API~~ (Optional)
- ~~Roads API~~ (Optional)

### 💰 Cost:
- **Free tier:** $200/month
- **Typical usage:** $14-140/month
- **Well within free tier** ✅

### 🔒 Security:
- Restrict by package name (Android)
- Restrict by bundle ID (iOS)
- Restrict to 5 APIs only

---

**API Key:** `AIzaSyD3A8EoUI7NPPh3SNsxh_ZxxYKSZUzlsg4`  
**Platform:** iOS + Android  
**Status:** Ready to enable  
**Last Updated:** May 2, 2026
