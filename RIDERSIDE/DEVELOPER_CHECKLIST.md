# LezGo Rider - Developer Setup Checklist

## Pre-Development Environment Setup

### Phase 1: System Requirements
- [ ] Flutter SDK installed (3.10.3 or later)
- [ ] Dart SDK installed (should come with Flutter)
- [ ] Android SDK installed
- [ ] Java Development Kit (JDK) 17 or later installed
- [ ] Git installed and configured

### Phase 2: Android SDK Configuration
- [ ] `ANDROID_HOME` environment variable is set
- [ ] Android SDK cmdline-tools installed
- [ ] Android SDK Platform-Tools installed (adb)
- [ ] Android SDK Build-Tools installed
- [ ] Android licenses accepted

**How to verify**:
```bash
powershell -ExecutionPolicy Bypass -File android/tool/validate_android_setup.ps1
```

### Phase 3: Project Secrets Configuration
- [ ] `secrets.json` file exists in project root
- [ ] Firebase credentials are configured (not placeholder values)
  - [ ] FIREBASE_PROJECT_ID
  - [ ] FIREBASE_MESSAGING_SENDER_ID
  - [ ] FIREBASE_API_KEY_ANDROID
  - [ ] FIREBASE_APP_ID_ANDROID
- [ ] Google Maps API key is configured
- [ ] Secrets synced to Dart defines:

```bash
powershell -ExecutionPolicy Bypass -File tool/sync_secrets.ps1
```

### Phase 4: Initial Build
- [ ] Run: `flutter pub get`
- [ ] Run: `flutter build apk --debug`
- [ ] APK generated successfully in `build/app/outputs/flutter-apk/`

---

## Daily Development Workflow

### Before Starting Development

```bash
# 1. Update dependencies
flutter pub get

# 2. Run code generation if needed
flutter pub run build_runner build --delete-conflicting-outputs

# 3. Check for any issues
flutter doctor
flutter analyze
```

### During Development

- [ ] Changes follow project code style
- [ ] No console errors or warnings in Dart analysis
- [ ] All UI state changes use Riverpod providers
- [ ] Firebase integration maintained
- [ ] Location tracking permissions respected

### After Code Changes

```bash
# 1. Format code
dart format lib/

# 2. Run analysis
flutter analyze

# 3. Run tests (if any)
flutter test

# 4. Build debug APK to verify
flutter build apk --debug
```

---

## Critical Features - Modification Guide

### 🔐 Firebase Push Notifications
**Location**: `lib/core/services/fcm_service.dart`

When modifying:
- [ ] Keep `_validateFirebaseConfiguration()` validation
- [ ] Maintain error logging for troubleshooting
- [ ] Test Firebase initialization at app startup
- [ ] Verify token refresh handling

**Testing**:
```bash
flutter run -v  # Check logs for "FCM initialized"
# Send test notification from Firebase Console
```

### 📍 Location Tracking
**Location**: `lib/presentation/provider/main/riderside/rider_location_provider.dart`

When modifying:
- [ ] Background location permission is REQUIRED (not optional)
- [ ] Maintain accuracy filters (50m threshold)
- [ ] Distance filter prevents unnecessary updates
- [ ] Test with app in foreground and background

**Testing**:
```bash
# 1. Start delivery
# 2. Accept permissions (must grant background location)
# 3. Minimize app
# 4. Verify tracking continues every 5 seconds
# 5. Check location updates on server
```

### 🔨 Android Build Configuration
**Location**: `android/app/build.gradle.kts`

When modifying:
- [ ] Keep `validateAndroidSdk()` validation before building
- [ ] Maintain clear error messages for missing tools
- [ ] Test full build process after changes

**Building**:
```bash
# Validate environment
powershell -ExecutionPolicy Bypass -File android/tool/validate_android_setup.ps1

# Then build
flutter build apk --debug
```

---

## Common Development Tasks

### Add a New Dependency
```bash
flutter pub add package_name
flutter pub get
flutter build apk --debug  # Verify it builds
```

### Update Dependencies
```bash
flutter pub upgrade
flutter pub get
flutter build apk --debug  # Verify everything still works
```

### Clean Build
```bash
flutter clean
flutter pub get
flutter build apk --debug
```

### Debug on Device
```bash
# Connect Android device via USB
flutter devices  # Verify device is detected

flutter run -v  # Run with verbose logging
```

### Debug on Emulator
```bash
# Start emulator first
flutter run -v
```

---

## Code Review Checklist

When reviewing rider app code, check for:

### Firebase Integration
- [ ] Uses FcmService singleton
- [ ] Validates configuration at startup
- [ ] Handles token refresh properly
- [ ] No sensitive Firebase credentials in code

### Location Tracking
- [ ] Requires background location permission
- [ ] Calls riderLocationProvider for location updates
- [ ] Handles permission denial gracefully
- [ ] Updates location at appropriate intervals

### State Management
- [ ] Uses Riverpod StateNotifier pattern
- [ ] No direct state mutations
- [ ] Proper error handling and logging
- [ ] Clean resource disposal

### Android Compatibility
- [ ] Works with API level 26+ (minimum SDK)
- [ ] Handles runtime permissions correctly
- [ ] Tests on both physical device and emulator
- [ ] No Windows-specific code in Flutter

### Testing
- [ ] Tests Firebase initialization
- [ ] Tests location permission flow
- [ ] Tests error scenarios
- [ ] Verifies build succeeds

---

## Troubleshooting Guide for Developers

### Problem: "FCM initialization failed"
```dart
// In lib/core/services/fcm_service.dart
// Check _validateFirebaseConfiguration() method
// Ensure SecretsConfig values are not empty or placeholder
```

### Problem: "Background location not working"
```dart
// In lib/presentation/provider/main/riderside/rider_location_provider.dart
// Permission.locationAlways must return .isGranted
// Test on actual device (some emulators have issues)
```

### Problem: "Android build fails"
```bash
# Run validation first
powershell -ExecutionPolicy Bypass -File android/tool/validate_android_setup.ps1

# If validation fails, run quick fix
powershell -ExecutionPolicy Bypass -File android/tool/quick_fix.ps1

# Check android/SETUP.md for detailed instructions
```

### Problem: "Plugin symlink errors on Windows"
```bash
flutter clean
cd android && gradlew clean
cd ..
flutter pub get
flutter build apk --debug
```

### Problem: "Dart analysis errors"
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter analyze
```

---

## Release Build Checklist

Before creating a release build:

- [ ] All tests pass
- [ ] No console errors or warnings
- [ ] Firebase is properly configured
- [ ] Location permissions are tested
- [ ] Increment version number in `pubspec.yaml`
- [ ] Generate keystore (if not already done):
  ```bash
  powershell -ExecutionPolicy Bypass -File android/tool/generate_release_keystore.ps1
  ```
- [ ] Build release APK:
  ```bash
  flutter build apk --release
  ```
- [ ] Test release APK on device
- [ ] Generate App Bundle for Play Store:
  ```bash
  flutter build appbundle --release
  ```

---

## Helpful Commands Reference

```bash
# Project setup
flutter pub get
flutter pub upgrade
flutter pub outdated

# Code generation
flutter pub run build_runner build
flutter pub run build_runner watch

# Code quality
flutter analyze
dart format lib/
dart format --set-exit-if-changed lib/

# Testing
flutter test
flutter test --coverage

# Building
flutter build apk --debug
flutter build apk --release
flutter build appbundle --release

# Running
flutter run
flutter run -v  # Verbose
flutter run --release

# Debugging
flutter attach
flutter logs
flutter doctor -v

# Cleaning
flutter clean
flutter pub cache clean
```

---

## Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Riverpod Documentation](https://riverpod.dev)
- [Firebase Flutter Guide](https://firebase.flutter.dev)
- [Android Setup Guide](./android/SETUP.md)
- [Fixes Applied](./FIXES_APPLIED.md)

---

## Contact & Support

If you encounter issues not covered here:
1. Check FIXES_APPLIED.md for detailed explanations
2. Review android/SETUP.md for Android-specific issues
3. Run validation script: `powershell -ExecutionPolicy Bypass -File android/tool/validate_android_setup.ps1`
4. Check Flutter logs: `flutter run -v`

---

**Last Updated**: June 2026
**Minimum Flutter Version**: 3.10.3
**Target Android SDK**: 36
**Minimum Android SDK**: 26
