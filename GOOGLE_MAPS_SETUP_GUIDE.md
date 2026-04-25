# Google Maps API Setup Guide

## Overview
This guide will help you set up Google Maps API for the LesGo application to enable real-time tracking with actual road routes.

## Prerequisites
- Google Cloud Platform account
- Credit card (for billing, but Google provides $200 free credit monthly)

## Step 1: Create Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Click "Select a project" → "New Project"
3. Enter project name: `LesGo-App`
4. Click "Create"

## Step 2: Enable Required APIs

1. In the Google Cloud Console, go to **APIs & Services** → **Library**
2. Enable the following APIs:
   - **Maps SDK for Android**
   - **Maps SDK for iOS**
   - **Directions API** ⭐ (Most important for routing)
   - **Distance Matrix API** (Optional, for advanced ETA)
   - **Geocoding API** (Optional, for address lookup)
   - **Places API** (Optional, for place search)

## Step 3: Create API Keys

### Backend API Key (Server-side)
1. Go to **APIs & Services** → **Credentials**
2. Click **Create Credentials** → **API Key**
3. Copy the API key
4. Click **Restrict Key**
5. Under **Application restrictions**:
   - Select **IP addresses**
   - Add your server IP addresses
6. Under **API restrictions**:
   - Select **Restrict key**
   - Check: **Directions API**, **Distance Matrix API**
7. Click **Save**

### Android API Key
1. Create another API key
2. Under **Application restrictions**:
   - Select **Android apps**
   - Click **Add an item**
   - Enter package name: `com.lesgo.app` (or your actual package name)
   - Get SHA-1 fingerprint:
     ```bash
     # Debug keystore
     keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
     
     # Release keystore
     keytool -list -v -keystore /path/to/your/keystore.jks -alias your-alias
     ```
   - Add the SHA-1 fingerprint
3. Under **API restrictions**:
   - Select **Restrict key**
   - Check: **Maps SDK for Android**
4. Click **Save**

### iOS API Key
1. Create another API key
2. Under **Application restrictions**:
   - Select **iOS apps**
   - Click **Add an item**
   - Enter bundle identifier: `com.lesgo.app` (or your actual bundle ID)
3. Under **API restrictions**:
   - Select **Restrict key**
   - Check: **Maps SDK for iOS**
4. Click **Save**

## Step 4: Configure Backend

### 1. Add API Key to .env
```bash
# In BACKEND/lesgo-api/.env
GOOGLE_MAPS_API_KEY=your_backend_api_key_here
```

### 2. Verify Configuration
The configuration is already set up in:
- `config/services.php` - Google Maps config
- `app/Http/Controllers/Api/LiveTrackingController.php` - API integration

### 3. Test the API
```bash
# Test route endpoint
curl -X GET "http://localhost:8000/api/v1/tracking/route?origin_lat=8.4542&origin_lng=124.6319&dest_lat=8.4600&dest_lng=124.6400" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Step 5: Configure Android App

### 1. Add API Key to AndroidManifest.xml
```xml
<!-- FRONTEND/android/app/src/main/AndroidManifest.xml -->
<manifest>
    <application>
        <!-- Add this inside <application> tag -->
        <meta-data
            android:name="com.google.android.geo.API_KEY"
            android:value="YOUR_ANDROID_API_KEY_HERE"/>
    </application>
</manifest>
```

### 2. Update build.gradle (if needed)
```gradle
// FRONTEND/android/app/build.gradle
android {
    defaultConfig {
        minSdkVersion 21  // Google Maps requires minimum SDK 21
    }
}
```

## Step 6: Configure iOS App

### 1. Add API Key to AppDelegate
```swift
// FRONTEND/ios/Runner/AppDelegate.swift
import UIKit
import Flutter
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("YOUR_IOS_API_KEY_HERE")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

### 2. Update Info.plist
```xml
<!-- FRONTEND/ios/Runner/Info.plist -->
<dict>
    <!-- Add this -->
    <key>io.flutter.embedded_views_preview</key>
    <true/>
</dict>
```

### 3. Update Podfile
```ruby
# FRONTEND/ios/Podfile
platform :ios, '12.0'  # Google Maps requires iOS 12.0+
```

## Step 7: Enable Billing (Required)

⚠️ **Important:** Google Maps APIs require billing to be enabled, even though you get $200 free credit monthly.

1. Go to **Billing** in Google Cloud Console
2. Click **Link a billing account**
3. Add your credit card information
4. You won't be charged unless you exceed $200/month

### Pricing (as of 2024):
- **Directions API**: $5 per 1,000 requests (first $200 free)
- **Maps SDK**: $7 per 1,000 loads (first $200 free)
- **Distance Matrix API**: $5 per 1,000 elements

### Cost Estimation:
For 1,000 orders/day:
- Directions API: ~3,000 requests/day = $15/day = $450/month
- With $200 free credit = $250/month actual cost

## Step 8: Set Up Usage Quotas (Recommended)

To prevent unexpected charges:

1. Go to **APIs & Services** → **Quotas**
2. Select **Directions API**
3. Click **Edit Quotas**
4. Set daily limit (e.g., 10,000 requests/day)
5. Click **Save**

## Step 9: Test the Integration

### Backend Test:
```bash
# Test with actual coordinates
curl -X GET "http://localhost:8000/api/v1/tracking/route?origin_lat=8.4542&origin_lng=124.6319&dest_lat=8.4600&dest_lng=124.6400" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Accept: application/json"
```

Expected response:
```json
{
  "success": true,
  "data": {
    "distance": {
      "value": 2500,
      "text": "2.5 km"
    },
    "duration": {
      "value": 900,
      "text": "15 mins"
    },
    "polyline": [
      {"latitude": 8.4542, "longitude": 124.6319},
      {"latitude": 8.4545, "longitude": 124.6325},
      ...
    ],
    "bounds": {
      "northeast": {"lat": 8.4600, "lng": 124.6400},
      "southwest": {"lat": 8.4542, "lng": 124.6319}
    }
  }
}
```

### Frontend Test:
1. Run the app
2. Create an order
3. Navigate to tracking screen
4. Verify:
   - Map displays correctly
   - Driver marker appears
   - Route polyline shows actual roads (not straight line)
   - ETA updates correctly

## Troubleshooting

### Issue: "API key not valid"
**Solution:** 
- Verify API key is correct in .env
- Check API restrictions match your usage
- Ensure Directions API is enabled

### Issue: "This API project is not authorized"
**Solution:**
- Enable billing on your Google Cloud project
- Wait 5-10 minutes for changes to propagate

### Issue: "OVER_QUERY_LIMIT"
**Solution:**
- Check your daily quota limits
- Implement request caching
- Consider upgrading your plan

### Issue: Map shows but no route
**Solution:**
- Check backend logs for API errors
- Verify coordinates are valid
- Test API endpoint directly with curl

### Issue: Straight line instead of road route
**Solution:**
- Verify Google Maps API key is set in backend .env
- Check if Directions API is enabled
- Look for fallback mode in API response

## Security Best Practices

### 1. Never Commit API Keys
```bash
# Add to .gitignore
.env
android/app/src/main/AndroidManifest.xml
ios/Runner/AppDelegate.swift
```

### 2. Use Environment Variables
```bash
# For CI/CD
export GOOGLE_MAPS_API_KEY="your_key_here"
```

### 3. Rotate Keys Regularly
- Rotate API keys every 90 days
- Use different keys for dev/staging/production

### 4. Monitor Usage
- Set up billing alerts
- Monitor API usage in Google Cloud Console
- Set up quotas to prevent abuse

## Alternative: Fallback Mode

If you don't want to use Google Maps API immediately, the system will automatically fall back to simple straight-line routing:

```php
// In LiveTrackingController.php
// If Google Maps API fails, it uses Haversine formula
private function getFallbackRoute($originLat, $originLng, $destLat, $destLng)
{
    // Simple distance calculation
    // Straight line polyline
    // Estimated ETA based on average speed
}
```

## Cost Optimization Tips

### 1. Cache Routes
```php
// Cache routes for 5 minutes
$cacheKey = "route_{$originLat}_{$originLng}_{$destLat}_{$destLng}";
$route = Cache::remember($cacheKey, 300, function() {
    return $this->getRouteFromGoogleMaps();
});
```

### 2. Batch Requests
- Use Distance Matrix API for multiple destinations
- Reduce individual Directions API calls

### 3. Use Waypoints Efficiently
- Combine multiple stops into one request
- Use waypoint optimization

### 4. Implement Request Throttling
```php
// Limit route updates to every 30 seconds
if ($lastRouteUpdate->diffInSeconds(now()) < 30) {
    return $cachedRoute;
}
```

## Summary

✅ Google Cloud project created
✅ APIs enabled (Directions, Maps SDK)
✅ API keys created and restricted
✅ Backend configured with API key
✅ Android app configured
✅ iOS app configured
✅ Billing enabled
✅ Usage quotas set
✅ Integration tested

Your app now has **actual Google Maps routing** with real road routes, accurate ETAs, and traffic-aware directions! 🗺️✨
