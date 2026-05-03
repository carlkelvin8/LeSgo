# Google Maps API Services - Required for LeSGo App

**API Key:** `AIzaSyD3A8EoUI7NPPh3SNsxh_ZxxYKSZUzlsg4`  
**Google Cloud Console:** https://console.cloud.google.com/google/maps-apis/

---

## ✅ CHECKLIST: APIs to Enable

Go to: **Google Cloud Console → APIs & Services → Library**

### 🗺️ 1. Maps SDK for Android
**Status:** ☐ Enable this  
**Required For:** Display maps on Android app  
**Used In:**
- Customer app (LesGo, LesRide, LesEat, LesBuy booking screens)
- Rider app (Map view, navigation)

**Enable:** https://console.cloud.google.com/apis/library/maps-android-backend.googleapis.com

---

### 🗺️ 2. Maps SDK for iOS
**Status:** ☐ Enable this  
**Required For:** Display maps on iOS app  
**Used In:**
- Customer app (LesGo, LesRide, LesEat, LesBuy booking screens)
- Rider app (Map view, navigation)

**Enable:** https://console.cloud.google.com/apis/library/maps-ios-backend.googleapis.com

---

### 🌐 3. Maps JavaScript API
**Status:** ☐ Enable this  
**Required For:** Display maps on Web (Flutter Web)  
**Used In:**
- Customer app web version
- Rider app web version
- Testing on Chrome

**Enable:** https://console.cloud.google.com/apis/library/maps-backend.googleapis.com

---

### 📍 4. Geocoding API
**Status:** ☐ Enable this  
**Required For:** Convert addresses to coordinates (lat/lng)  
**Used In:**
- Address input → Get coordinates
- Search location by address
- Validate addresses

**Example:**
```
Input: "123 Rizal Street, Manila"
Output: { lat: 14.5995, lng: 120.9842 }
```

**Enable:** https://console.cloud.google.com/apis/library/geocoding-backend.googleapis.com

---

### 📍 5. Geocoding API (Reverse)
**Status:** ☐ Enable this (same as #4)  
**Required For:** Convert coordinates to addresses  
**Used In:**
- Current location → Get address
- Map tap → Get address
- Display readable addresses

**Example:**
```
Input: { lat: 14.5995, lng: 120.9842 }
Output: "123 Rizal Street, Ermita, Manila, Metro Manila, Philippines"
```

**Enable:** https://console.cloud.google.com/apis/library/geocoding-backend.googleapis.com

---

### 🔍 6. Places API
**Status:** ☐ Enable this  
**Required For:** Address autocomplete and place search  
**Used In:**
- Address search bar (autocomplete suggestions)
- Place details (name, address, coordinates)
- Nearby places search

**Features:**
- Autocomplete: Type "Jollibee" → Get suggestions
- Place Details: Get full info about a place
- Nearby Search: Find restaurants, stores near location

**Enable:** https://console.cloud.google.com/apis/library/places-backend.googleapis.com

---

### 🛣️ 7. Directions API
**Status:** ☐ Enable this  
**Required For:** Get routes and navigation between two points  
**Used In:**
- Calculate route from pickup to destination
- Show route on map (polylines) - REMOVED in current version
- Get turn-by-turn directions
- Estimate travel time

**Example:**
```
From: Pickup location (14.5995, 120.9842)
To: Destination (14.6090, 121.0000)
Output: Route polyline, distance, duration, steps
```

**Enable:** https://console.cloud.google.com/apis/library/directions-backend.googleapis.com

---

### 📏 8. Distance Matrix API
**Status:** ☐ Enable this  
**Required For:** Calculate distance and travel time between locations  
**Used In:**
- Fare estimation (distance-based pricing)
- ETA calculation
- Driver assignment (find nearest driver)
- Delivery time estimation

**Example:**
```
From: Pickup (14.5995, 120.9842)
To: Destination (14.6090, 121.0000)
Output: 
  - Distance: 5.2 km
  - Duration: 15 minutes
  - Duration in traffic: 22 minutes
```

**Enable:** https://console.cloud.google.com/apis/library/distance-matrix-backend.googleapis.com

---

### 🌍 9. Geolocation API (Optional)
**Status:** ☐ Optional - Enable if needed  
**Required For:** Get location from WiFi/Cell towers (no GPS)  
**Used In:**
- Indoor location
- When GPS is unavailable
- Faster initial location

**Note:** Flutter usually uses device GPS, this is optional

**Enable:** https://console.cloud.google.com/apis/library/geolocation.googleapis.com

---

### 🚦 10. Roads API (Optional)
**Status:** ☐ Optional - For advanced features  
**Required For:** Snap GPS coordinates to roads  
**Used In:**
- Accurate driver tracking on roads
- Speed limit data
- Road snapping for better route display

**Note:** Not required for basic functionality

**Enable:** https://console.cloud.google.com/apis/library/roads.googleapis.com

---

## 📋 SUMMARY

### ✅ REQUIRED (Must Enable - 8 APIs)
1. ☐ Maps SDK for Android
2. ☐ Maps SDK for iOS
3. ☐ Maps JavaScript API
4. ☐ Geocoding API
5. ☐ Places API
6. ☐ Directions API
7. ☐ Distance Matrix API

### ⚪ OPTIONAL (Nice to Have - 2 APIs)
8. ☐ Geolocation API
9. ☐ Roads API

---

## 🔧 HOW TO ENABLE APIs

### Step 1: Go to Google Cloud Console
https://console.cloud.google.com/

### Step 2: Select Your Project
- Click project dropdown at top
- Select your LeSGo project (or create new)

### Step 3: Enable APIs
1. Go to **APIs & Services → Library**
2. Search for each API name (e.g., "Maps SDK for Android")
3. Click on the API
4. Click **"ENABLE"** button
5. Wait for activation (takes a few seconds)

### Step 4: Verify API Key
1. Go to **APIs & Services → Credentials**
2. Find your API key: `AIzaSyD3A8EoUI7NPPh3SNsxh_ZxxYKSZUzlsg4`
3. Click **Edit** (pencil icon)
4. Under **API restrictions**, select **"Restrict key"**
5. Check all the APIs you enabled
6. Click **Save**

---

## 🔒 SECURITY: API KEY RESTRICTIONS

### Application Restrictions
**Recommended:** Restrict by app

#### For Android:
- Restriction type: **Android apps**
- Package name: `com.lesgo.customer` (Customer app)
- Package name: `com.lesgo.rider` (Rider app)
- SHA-1 fingerprint: Get from your keystore

#### For iOS:
- Restriction type: **iOS apps**
- Bundle ID: `com.lesgo.customer` (Customer app)
- Bundle ID: `com.lesgo.rider` (Rider app)

#### For Web (Testing):
- Restriction type: **HTTP referrers**
- Website restrictions: 
  - `http://localhost:*`
  - `http://127.0.0.1:*`
  - `https://yourdomain.com/*`

### API Restrictions
**Recommended:** Restrict to only enabled APIs

Select these APIs:
- ✅ Maps SDK for Android
- ✅ Maps SDK for iOS
- ✅ Maps JavaScript API
- ✅ Geocoding API
- ✅ Places API
- ✅ Directions API
- ✅ Distance Matrix API

---

## 💰 PRICING ESTIMATE

### Free Tier (Monthly)
- **$200 credit** per month (covers ~28,000 map loads)

### Pay-as-you-go Pricing

| API | Price per 1,000 requests | Free Tier |
|-----|-------------------------|-----------|
| Maps SDK (Android/iOS) | $7.00 | 28,000 loads |
| Maps JavaScript API | $7.00 | 28,000 loads |
| Geocoding API | $5.00 | 40,000 requests |
| Places API (Autocomplete) | $2.83 per session | 70,000 sessions |
| Places API (Details) | $17.00 | 11,000 requests |
| Directions API | $5.00 | 40,000 requests |
| Distance Matrix API | $5.00 | 40,000 elements |

### Typical Monthly Usage (1000 active users)
- Map loads: ~30,000 → **$7**
- Geocoding: ~10,000 → **$2.50**
- Places Autocomplete: ~5,000 → **$0.71**
- Directions: ~8,000 → **$2**
- Distance Matrix: ~15,000 → **$3.75**

**Total:** ~$16/month (well within $200 free tier)

### At Scale (10,000 active users)
- Estimated: **$50-150/month**
- Still mostly covered by free tier

---

## 📊 MONITORING & ALERTS

### Set Up Billing Alerts
1. Go to **Billing → Budgets & alerts**
2. Create budget: $200/month
3. Set alerts at: 50%, 90%, 100%
4. Add email notifications

### Monitor API Usage
1. Go to **APIs & Services → Dashboard**
2. View usage charts for each API
3. Check daily/weekly/monthly trends
4. Watch for unusual spikes

---

## 🧪 TESTING

### Test Each API

#### 1. Test Maps Display
```dart
// Should show map with markers
GoogleMap(
  initialCameraPosition: CameraPosition(
    target: LatLng(14.5995, 120.9842),
    zoom: 15,
  ),
)
```

#### 2. Test Geocoding
```bash
curl "https://maps.googleapis.com/maps/api/geocode/json?address=Manila&key=AIzaSyD3A8EoUI7NPPh3SNsxh_ZxxYKSZUzlsg4"
```

#### 3. Test Places Autocomplete
```bash
curl "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=Jollibee&key=AIzaSyD3A8EoUI7NPPh3SNsxh_ZxxYKSZUzlsg4"
```

#### 4. Test Directions
```bash
curl "https://maps.googleapis.com/maps/api/directions/json?origin=Manila&destination=Quezon+City&key=AIzaSyD3A8EoUI7NPPh3SNsxh_ZxxYKSZUzlsg4"
```

#### 5. Test Distance Matrix
```bash
curl "https://maps.googleapis.com/maps/api/distancematrix/json?origins=Manila&destinations=Quezon+City&key=AIzaSyD3A8EoUI7NPPh3SNsxh_ZxxYKSZUzlsg4"
```

---

## ⚠️ COMMON ISSUES

### Issue 1: "This API project is not authorized to use this API"
**Solution:** Enable the API in Google Cloud Console

### Issue 2: "API key not valid"
**Solution:** 
- Check if key is correct
- Check if API is enabled
- Check if restrictions allow your app

### Issue 3: "REQUEST_DENIED"
**Solution:**
- Enable billing on Google Cloud project
- Check API restrictions
- Verify app package name/bundle ID

### Issue 4: "OVER_QUERY_LIMIT"
**Solution:**
- You've exceeded free tier
- Enable billing or wait for quota reset
- Optimize API calls (cache results)

### Issue 5: Map shows gray tiles
**Solution:**
- Maps SDK not enabled
- API key restrictions too strict
- Check browser console for errors

---

## 📱 APP CONFIGURATION

### Android
**File:** `FRONTEND/android/app/src/main/AndroidManifest.xml`
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="AIzaSyD3A8EoUI7NPPh3SNsxh_ZxxYKSZUzlsg4"/>
```

### iOS
**File:** `FRONTEND/ios/Runner/AppDelegate.swift`
```swift
GMSServices.provideAPIKey("AIzaSyD3A8EoUI7NPPh3SNsxh_ZxxYKSZUzlsg4")
```

### Web
**File:** `FRONTEND/web/index.html`
```html
<script src="https://maps.googleapis.com/maps/api/js?key=AIzaSyD3A8EoUI7NPPh3SNsxh_ZxxYKSZUzlsg4"></script>
```

### Backend (Proxy)
**File:** `BACKEND/lesgo-api/.env`
```env
GOOGLE_MAPS_API_KEY=AIzaSyD3A8EoUI7NPPh3SNsxh_ZxxYKSZUzlsg4
```

---

## 🎯 QUICK START CHECKLIST

### Before Launch:
- [ ] Enable all 7 required APIs
- [ ] Set up API key restrictions
- [ ] Configure billing alerts
- [ ] Test all APIs
- [ ] Add API key to Android app
- [ ] Add API key to iOS app
- [ ] Add API key to Web app
- [ ] Add API key to Backend
- [ ] Monitor usage for 1 week
- [ ] Optimize API calls if needed

---

## 📞 SUPPORT

### Google Maps Platform Support
- Documentation: https://developers.google.com/maps/documentation
- Support: https://support.google.com/maps
- Community: https://stackoverflow.com/questions/tagged/google-maps

### Billing Questions
- Billing Console: https://console.cloud.google.com/billing
- Pricing Calculator: https://mapsplatform.google.com/pricing/

---

**Last Updated:** May 2, 2026  
**API Key:** `AIzaSyD3A8EoUI7NPPh3SNsxh_ZxxYKSZUzlsg4`  
**Status:** Ready to enable APIs
