# LezGo Rider - Quick Start After Fixes

## 🚀 Getting Started

### 1. Setup Android Build Environment (One-time)

```bash
# Run validation to check if everything is ready
powershell -ExecutionPolicy Bypass -File android/tool/validate_android_setup.ps1

# If validation fails, run quick fix
powershell -ExecutionPolicy Bypass -File android/tool/quick_fix.ps1

# For manual setup, see: android/SETUP.md
```

### 2. Sync Firebase Secrets

```bash
# From root directory
powershell -ExecutionPolicy Bypass -File tool/sync_secrets.ps1
```

### 3. Get Dependencies & Build

```bash
flutter pub get
flutter build apk --debug
```

---

## ✅ What's Fixed

| Issue | Status | How to Verify |
|-------|--------|---------------|
| **Firebase validation** | ✅ Fixed | Check logs for "FCM initialized: token received" |
| **Background location permission** | ✅ Fixed | Rider must grant "Allow all the time" permission |
| **Android build setup** | ✅ Fixed | Run validation script - should pass all checks |

---

## 📱 Testing the Fixes

### Test 1: Firebase Push Notifications
1. Login as a rider
2. Wait for a test order notification
3. Verify notification appears with sound/vibration
4. **Expected**: Notification received successfully

### Test 2: Background Location Tracking
1. Login as rider
2. Accept a delivery
3. Permission prompt: "Background location permission" - allow it
4. Minimize the app
5. Use other apps for 30+ seconds
6. Reopen LezGo app
7. **Expected**: Location was tracked in background, map shows current position

### Test 3: Android Build
1. Run: `flutter build apk --debug`
2. Wait for build to complete
3. **Expected**: Build succeeds, APK appears in `build/app/outputs/flutter-apk/`

---

## 🛠️ Common Tasks

### Run Debug Build
```bash
flutter run -v
```

### Build Release APK
```bash
# First time only: Generate keystore
powershell -ExecutionPolicy Bypass -File android/tool/generate_release_keystore.ps1

# Then build
flutter build apk --release
```

### Build for Google Play (App Bundle)
```bash
flutter build appbundle --release
```

### Clean & Rebuild
```bash
flutter clean
flutter pub get
flutter build apk --debug
```

---

## ❓ Troubleshooting

### "FCM token missing"
```bash
# Sync Firebase secrets
powershell -ExecutionPolicy Bypass -File tool/sync_secrets.ps1
# Rebuild app
flutter pub get && flutter build apk --debug
```

### "Background location permission denied"
- Rider must open Settings
- Go to: Apps → LezGo Rider → Permissions → Location
- Select: "Allow all the time"

### "cmdline-tools component missing"
```bash
# Run quick fix
powershell -ExecutionPolicy Bypass -File android/tool/quick_fix.ps1

# Or manual setup
# See: android/SETUP.md
```

### "Plugin symlink error on Windows"
```bash
flutter clean
cd android && gradlew clean
cd ..
flutter pub get
```

---

## 📚 Documentation

- **Firebase Setup**: See `lib/core/services/fcm_service.dart`
- **Location Tracking**: See `lib/presentation/provider/main/riderside/rider_location_provider.dart`
- **Android Build**: See `android/SETUP.md`
- **All Fixes**: See `FIXES_APPLIED.md`

---

## 🎯 Next Steps

1. ✅ Run Android validation: `powershell -ExecutionPolicy Bypass -File android/tool/validate_android_setup.ps1`
2. ✅ Sync secrets: `powershell -ExecutionPolicy Bypass -File tool/sync_secrets.ps1`
3. ✅ Build APK: `flutter build apk --debug`
4. ✅ Test on device/emulator: `flutter run`
5. ✅ Verify Firebase notifications work
6. ✅ Verify location tracking in background

---

**Last Updated**: June 2026
