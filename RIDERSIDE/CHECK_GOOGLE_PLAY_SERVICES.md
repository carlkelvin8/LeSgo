# Google Play Services Troubleshooting

## Your Emulator HAS Google Play! ✅

I can see Play Store, Gmail, Photos, YouTube, Chrome - all Google apps are installed.

## Why Maps Still Not Loading?

Possible reasons:

### 1. Google Play Services Needs Update

**Solution:**
1. Open **Play Store** in emulator
2. Sign in with Google account
3. Search "Google Play Services"
4. Update if available
5. Restart emulator

### 2. API Key Restrictions

Your API key: `AIzaSyA0s1a7phLN0iaD6-MjnwqfpJFhYhmyNjU`

**Check restrictions:**
1. Go to: https://console.cloud.google.com/google/maps-apis/credentials
2. Find your API key
3. Check if it has:
   - ✅ **Application restrictions**: None OR Android apps
   - ✅ **API restrictions**: None OR includes "Maps SDK for Android"

### 3. Emulator Network Issue

**Test network:**
```bash
adb shell ping -c 4 maps.googleapis.com
```

If this fails, the emulator can't reach Google servers.

### 4. SHA-1 Certificate Issue

For Android, Google Maps might need SHA-1 certificate registered.

**Get SHA-1:**
```bash
cd RIDERSIDE/android
./gradlew signingReport
```

Look for "SHA1" under "debug" variant, then add it to your Google Cloud Console.

## Quick Test Commands

### Check if Google Play Services is installed:
```bash
adb shell pm list packages | findstr google
```

Should show:
- `com.google.android.gms` ✅
- `com.google.android.gsf` ✅

### Check Google Play Services version:
```bash
adb shell dumpsys package com.google.android.gms | findstr version
```

### Test network connectivity:
```bash
adb shell ping -c 4 8.8.8.8
adb shell ping -c 4 maps.googleapis.com
```

## Most Likely Fix

**Update Google Play Services:**
1. Open Play Store in emulator
2. Sign in
3. Update Google Play Services
4. Restart emulator
5. Run app again

This usually fixes the blank map issue!
