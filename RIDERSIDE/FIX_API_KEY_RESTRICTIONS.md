# 🔑 Fix Google Maps API Key for Android

## Problem
- ✅ Google Play Services is ON
- ✅ Code is correct
- ❌ Maps not loading = **API Key restriction issue**

## Your App Info
- **Package Name:** `com.example.frontend2`
- **Current API Key:** `AIzaSyA0s1a7phLN0iaD6-MjnwqfpJFhYhmyNjU`

---

## ⚡ QUICKEST FIX (5 minutes)

### Remove API Key Restrictions (For Testing)

1. **Go to:** https://console.cloud.google.com/google/maps-apis/credentials

2. **Find your API key** in the list

3. **Click the pencil icon** (Edit)

4. **Under "Application restrictions":**
   - Select: **"None"**

5. **Under "API restrictions":**
   - Select: **"Don't restrict key"**

6. **Click "SAVE"**

7. **IMPORTANT: Wait 5 minutes** for changes to propagate

8. **Restart your app:**
   ```bash
   flutter run
   ```

9. **Test Map View** - should work now! 🗺️✨

---

## 🔒 PROPER FIX (For Production)

If you want to keep restrictions (more secure):

### Step 1: Get Your SHA-1 Certificate

**On Windows:**
```bash
cd RIDERSIDE\android
gradlew.bat signingReport
```

**On Mac/Linux:**
```bash
cd RIDERSIDE/android
./gradlew signingReport
```

**Look for this in the output:**
```
Variant: debug
Config: debug
Store: C:\Users\YourName\.android\debug.keystore
Alias: AndroidDebugKey
MD5: XX:XX:XX:...
SHA1: A1:B2:C3:D4:E5:F6:G7:H8:I9:J0:K1:L2:M3:N4:O5:P6:Q7:R8:S9:T0  ← COPY THIS!
SHA-256: ...
```

**Copy the SHA1 value!**

### Step 2: Configure API Key with Android Restrictions

1. Go to: https://console.cloud.google.com/google/maps-apis/credentials

2. Click your API key

3. Under **"Application restrictions":**
   - Select: **"Android apps"**

4. Click **"+ Add an item"**

5. Enter:
   - **Package name:** `com.example.frontend2`
   - **SHA-1 certificate fingerprint:** (paste your SHA-1 from Step 1)

6. Click **"Done"**

7. Click **"SAVE"**

8. **Wait 5 minutes**

9. Test your app!

---

## 🆕 Alternative: Create New API Key

If the current key has issues, create a fresh one:

### Step 1: Create New Key

1. Go to: https://console.cloud.google.com/google/maps-apis/credentials

2. Click **"+ CREATE CREDENTIALS"**

3. Select **"API key"**

4. **Copy the new key** (it will look like: `AIzaSy...`)

5. **Don't add restrictions yet** (for testing)

### Step 2: Enable Required APIs

Make sure these APIs are enabled:
1. Go to: https://console.cloud.google.com/apis/library

2. Search and enable:
   - ✅ **Maps SDK for Android**
   - ✅ **Maps SDK for iOS** (if you plan to support iOS)
   - ✅ **Places API** (if you use places)
   - ✅ **Directions API** (if you use directions)
   - ✅ **Distance Matrix API** (if you calculate distances)

### Step 3: Update AndroidManifest.xml

Replace the API key in: `RIDERSIDE/android/app/src/main/AndroidManifest.xml`

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_NEW_API_KEY_HERE"/>
```

### Step 4: Test

```bash
flutter clean
flutter run
```

---

## 🧪 Verify API Key is Working

### Test in Browser

Try this URL in your browser (replace with your key):
```
https://maps.googleapis.com/maps/api/staticmap?center=8.4542,124.6319&zoom=13&size=400x400&key=AIzaSyA0s1a7phLN0iaD6-MjnwqfpJFhYhmyNjU
```

If you see a map image = API key works!
If you see error = API key has issues

---

## 📋 Checklist

- [ ] API key exists in Google Cloud Console
- [ ] Maps SDK for Android is enabled
- [ ] API key has no restrictions (for testing) OR
- [ ] API key has Android app restriction with correct package name and SHA-1
- [ ] Waited 5 minutes after making changes
- [ ] Restarted the app
- [ ] Google Play Services is updated in emulator

---

## 🎯 Most Common Solution

**90% of the time, removing API key restrictions fixes this immediately!**

Just:
1. Go to Google Cloud Console
2. Edit your API key
3. Set restrictions to "None"
4. Save
5. Wait 5 minutes
6. Restart app
7. Done! 🎉

---

## Still Not Working?

Try these:

### 1. Cold Boot Emulator
- Close emulator
- In Android Studio → Device Manager
- Click dropdown → "Cold Boot Now"

### 2. Clear App Data
- In emulator: Settings → Apps → LezGo Rider
- Clear Storage & Cache

### 3. Test on Real Device
- Connect Android phone via USB
- Enable USB Debugging
- Run: `flutter run`
- Select your phone
- Maps will work on real device!

### 4. Check Logcat for Errors
Look for Google Maps errors in the console when you open Map View.
Common errors:
- "API key not found" = Key not in manifest
- "This API key is not authorized" = Restrictions blocking it
- "OVER_QUERY_LIMIT" = Too many requests (wait or upgrade plan)
