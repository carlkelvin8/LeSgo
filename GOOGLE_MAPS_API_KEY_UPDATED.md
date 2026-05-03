# Google Maps API Key - Updated

**New API Key:** `AIzaSyBekzwaPQ9H0Zu3y7XOyUkrM-ny4XdVZXA`  
**Updated:** May 2, 2026  
**Status:** ✅ All files updated

---

## ✅ FILES UPDATED

### Customer App (FRONTEND)

#### Android
- ✅ `FRONTEND/android/app/src/main/AndroidManifest.xml`
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="AIzaSyBekzwaPQ9H0Zu3y7XOyUkrM-ny4XdVZXA"/>
```

#### iOS
- ✅ `FRONTEND/ios/Runner/Info.plist`
```xml
<key>GMSApiKey</key>
<string>AIzaSyBekzwaPQ9H0Zu3y7XOyUkrM-ny4XdVZXA</string>
```

#### Web
- ✅ `FRONTEND/web/index.html`
```html
<script async defer src="https://maps.googleapis.com/maps/api/js?key=AIzaSyBekzwaPQ9H0Zu3y7XOyUkrM-ny4XdVZXA&loading=async&libraries=marker,geometry,places&v=weekly"></script>
```

---

### Rider App (RIDERSIDE)

#### Android
- ✅ `RIDERSIDE/android/app/src/main/AndroidManifest.xml`
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="AIzaSyBekzwaPQ9H0Zu3y7XOyUkrM-ny4XdVZXA"/>
```

#### iOS
- ✅ `RIDERSIDE/ios/Runner/Info.plist`
```xml
<key>GMSApiKey</key>
<string>AIzaSyBekzwaPQ9H0Zu3y7XOyUkrM-ny4XdVZXA</string>
```

#### Web
- ✅ `RIDERSIDE/web/index.html`
```html
<script src="https://maps.googleapis.com/maps/api/js?key=AIzaSyBekzwaPQ9H0Zu3y7XOyUkrM-ny4XdVZXA&libraries=geometry,places"></script>
```

---

### Backend (BACKEND/lesgo-api)

#### Google Places Proxy Controller
- ✅ `BACKEND/lesgo-api/app/Http/Controllers/Api/GooglePlacesProxyController.php`
```php
$this->apiKey = 'AIzaSyBekzwaPQ9H0Zu3y7XOyUkrM-ny4XdVZXA';
```

#### Geocoding Script
- ✅ `BACKEND/lesgo-api/geocode_profile_addresses.php`
```php
$apiKey = 'AIzaSyBekzwaPQ9H0Zu3y7XOyUkrM-ny4XdVZXA';
```

---

## 🔄 NEXT STEPS

### 1. Restart Apps (Required)
The apps need to be restarted to use the new API key:

```bash
# Stop current apps
# Customer app (Terminal 28)
# Rider app (Terminal 29)

# Restart Customer app
cd FRONTEND
flutter run -d chrome --web-port 54005

# Restart Rider app
cd RIDERSIDE
flutter run -d chrome --web-port 54006
```

### 2. Enable APIs in Google Cloud Console
Go to: https://console.cloud.google.com/

**Required APIs to Enable:**
1. ☐ Maps SDK for Android
2. ☐ Maps SDK for iOS
3. ☐ Maps JavaScript API (for web testing)
4. ☐ Geocoding API
5. ☐ Places API
6. ☐ Distance Matrix API

**Quick Enable Links:**
- [Maps SDK for Android](https://console.cloud.google.com/apis/library/maps-android-backend.googleapis.com)
- [Maps SDK for iOS](https://console.cloud.google.com/apis/library/maps-ios-backend.googleapis.com)
- [Maps JavaScript API](https://console.cloud.google.com/apis/library/maps-backend.googleapis.com)
- [Geocoding API](https://console.cloud.google.com/apis/library/geocoding-backend.googleapis.com)
- [Places API](https://console.cloud.google.com/apis/library/places-backend.googleapis.com)
- [Distance Matrix API](https://console.cloud.google.com/apis/library/distance-matrix-backend.googleapis.com)

### 3. Set API Key Restrictions (Recommended)

#### Application Restrictions
**For Android:**
- Package name: `com.lesgo.customer`
- Package name: `com.lesgo.rider`
- SHA-1 fingerprint: (get from your keystore)

**For iOS:**
- Bundle ID: `com.lesgo.customer`
- Bundle ID: `com.lesgo.rider`

**For Web (Testing):**
- HTTP referrers: `http://localhost:*`, `http://127.0.0.1:*`

#### API Restrictions
Select only these APIs:
- ✅ Maps SDK for Android
- ✅ Maps SDK for iOS
- ✅ Maps JavaScript API
- ✅ Geocoding API
- ✅ Places API
- ✅ Distance Matrix API

---

## 🧪 TESTING

### Test on Web (Chrome)
1. Open Customer app: http://localhost:54005
2. Go to LesGo booking screen
3. Check if map displays correctly
4. Check if address search works
5. Check if markers show (purple pickup, red destination)

### Test API Key Directly
```bash
# Test Geocoding
curl "https://maps.googleapis.com/maps/api/geocode/json?address=Manila&key=AIzaSyBekzwaPQ9H0Zu3y7XOyUkrM-ny4XdVZXA"

# Test Places Autocomplete
curl "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=Jollibee&key=AIzaSyBekzwaPQ9H0Zu3y7XOyUkrM-ny4XdVZXA"

# Test Distance Matrix
curl "https://maps.googleapis.com/maps/api/distancematrix/json?origins=Manila&destinations=Quezon+City&key=AIzaSyBekzwaPQ9H0Zu3y7XOyUkrM-ny4XdVZXA"
```

---

## ⚠️ TROUBLESHOOTING

### Issue: Map shows blank/gray
**Cause:** APIs not enabled  
**Fix:** Enable all 6 required APIs in Google Cloud Console

### Issue: "This API project is not authorized"
**Cause:** API not enabled for this key  
**Fix:** Go to Google Cloud Console → APIs & Services → Library → Enable the API

### Issue: "REQUEST_DENIED"
**Cause:** Billing not enabled  
**Fix:** Enable billing in Google Cloud Console

### Issue: Address search not working
**Cause:** Places API not enabled  
**Fix:** Enable Places API

### Issue: Distance calculation fails
**Cause:** Distance Matrix API not enabled  
**Fix:** Enable Distance Matrix API

---

## 📊 COST MONITORING

### Set Up Billing Alerts
1. Go to Google Cloud Console
2. Navigate to **Billing → Budgets & alerts**
3. Create budget: **$200/month**
4. Set alerts at: **50%, 90%, 100%**
5. Add your email for notifications

### Monitor Usage
1. Go to **APIs & Services → Dashboard**
2. View usage charts for each API
3. Check daily/weekly trends
4. Watch for unusual spikes

---

## 📝 SUMMARY

### ✅ Completed
- [x] Updated API key in all Android manifests (2 files)
- [x] Updated API key in all iOS Info.plist files (2 files)
- [x] Updated API key in all web index.html files (2 files)
- [x] Updated API key in backend controller (1 file)
- [x] Updated API key in backend script (1 file)

**Total files updated:** 8 files

### ⚠️ Action Required
- [ ] Restart Customer app
- [ ] Restart Rider app
- [ ] Enable 6 APIs in Google Cloud Console
- [ ] Set API key restrictions
- [ ] Test maps on all platforms
- [ ] Set up billing alerts

---

## 🔑 API KEY DETAILS

**Old Key:** `AIzaSyD3A8EoUI7NPPh3SNsxh_ZxxYKSZUzlsg4`  
**New Key:** `AIzaSyBekzwaPQ9H0Zu3y7XOyUkrM-ny4XdVZXA`

**Google Cloud Console:** https://console.cloud.google.com/  
**APIs & Services:** https://console.cloud.google.com/apis/dashboard

---

**Status:** ✅ All files updated, ready to restart apps  
**Last Updated:** May 2, 2026
