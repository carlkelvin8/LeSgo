# Setup Android Emulator with Google Play Services for Google Maps

## Problem
Google Maps shows blank/gray screen because the emulator doesn't have Google Play Services installed.

## Solution: Create Emulator with Google Play

### Step 1: Open Android Studio
1. Open Android Studio
2. Go to **Tools** → **Device Manager** (or **AVD Manager**)

### Step 2: Create New Virtual Device
1. Click **"Create Device"**
2. Select a device definition (e.g., **Pixel 5** or **Medium Phone**)
3. Click **Next**

### Step 3: Select System Image with Google Play
**IMPORTANT:** Choose a system image that includes **"Google Play"**

✅ **CORRECT** - Look for these:
- Android 14.0 (**Google Play**) x86_64
- Android 13.0 (**Google Play**) x86_64  
- Android 12.0 (**Google Play**) x86_64
- Android 11.0 (**Google Play**) x86_64

❌ **WRONG** - Avoid these:
- Android XX (**Google APIs**) - Missing Google Play Services
- Android XX (No label) - Missing Google Play Services

### Step 4: Download System Image
1. If not downloaded, click **Download** next to the system image
2. Wait for download to complete
3. Click **Next**

### Step 5: Configure AVD
1. Give it a name: **"Pixel 5 with Google Play"**
2. Click **Finish**

### Step 6: Launch Emulator
1. Click the **Play** button next to your new emulator
2. Wait for it to boot up

### Step 7: Test Google Maps
1. Run your Flutter app: `flutter run`
2. Navigate to Map View
3. Google Maps should now load properly! 🗺️

## Verify Google Play Services

After launching the emulator, verify Google Play Services is installed:

```bash
adb shell pm list packages | grep -i google
```

You should see:
- `com.google.android.gms` (Google Play Services)
- `com.google.android.gsf` (Google Services Framework)

## Alternative: Use Existing Emulator

If you want to keep your current emulator, you can try:

1. Open **Play Store** app in the emulator
2. Sign in with a Google account
3. Update **Google Play Services**
4. Restart the emulator

## Current Emulator Info

Your current emulator: **Medium Phone API 36.1**
- This appears to be missing Google Play Services
- That's why Google Maps shows blank/gray screen

## What's Working

✅ Google Maps API Key is correct
✅ Location permissions granted
✅ Map widget is created successfully
✅ Location tracking is working
❌ Map tiles not loading (needs Google Play Services)

## Next Steps

1. Create new emulator with Google Play (recommended)
2. OR test on a real Android device
3. Run the app again
4. Google Maps should work! 🎉
