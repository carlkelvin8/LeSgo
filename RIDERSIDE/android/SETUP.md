# Android Build Setup Guide

## Prerequisites

Before building the Android APK for LezGo Rider, ensure your environment is properly configured.

### 1. Install Android SDK cmdline-tools

The `cmdline-tools` component is required for Android builds. Follow these steps:

#### Option A: Using Android Studio (Recommended)

1. Open **Android Studio**
2. Go to **Settings → Languages & Frameworks → Android SDK**
3. Click the **SDK Tools** tab
4. Ensure the following are installed:
   - ✅ **Android SDK Command-line Tools (latest)**
   - ✅ **Android SDK Platform-Tools**
   - ✅ **Android SDK Build-Tools** (latest version for your target SDK)
5. Click **Apply** and let it download

#### Option B: Command Line

If you have Android SDK installed but missing cmdline-tools:

```bash
# For Windows (PowerShell)
$ANDROID_HOME = "C:\Users\PC\AppData\Local\Android\sdk"

# Download and extract latest cmdline-tools from:
# https://developer.android.com/studio/command-line-tools

# Extract to: $ANDROID_HOME\cmdline-tools\latest

# Then run:
$ANDROID_HOME\cmdline-tools\latest\bin\sdkmanager.bat --licenses
```

### 2. Accept Android Licenses

After installing cmdline-tools, accept the Android licenses:

```bash
flutter doctor --android-licenses
```

This will prompt you to accept each license. Type `y` and press Enter for each one.

### 3. Verify Installation

Run the setup validation script:

```bash
# From the RIDERSIDE directory
powershell -ExecutionPolicy Bypass -File android/tool/validate_android_setup.ps1
```

This will check:
- ✅ Android SDK location
- ✅ cmdline-tools installation
- ✅ Android licenses acceptance
- ✅ Build tools availability
- ✅ Emulator/device availability

### 4. Generate Release Keystore (for production builds)

Before building a release APK, generate a signing keystore:

```bash
powershell -ExecutionPolicy Bypass -File android/tool/generate_release_keystore.ps1
```

This creates `android/key.properties` with your signing credentials.

## Building the APK

Once setup is complete:

### Debug Build
```bash
flutter build apk --debug
```

### Release Build
```bash
flutter build apk --release
```

### AAB Build (for Google Play Store)
```bash
flutter build appbundle --release
```

## Troubleshooting

### Error: "cmdline-tools component is missing"
- Run `flutter doctor` to verify
- Follow **Option A** or **B** above to install
- Run `flutter doctor --android-licenses`

### Error: "Android license status unknown"
- Run `flutter doctor --android-licenses` and accept all licenses

### Error: "gradle project not found"
- Delete Flutter cache:
  ```bash
  flutter clean
  cd android && gradlew clean
  cd ..
  flutter pub get
  ```

### Error: Plugin symlink issues on Windows
- Delete `android/.gradle` and `android/app/build` directories
- Run `flutter clean`
- Run `flutter pub get`

## References

- [Android SDK Command-Line Tools](https://developer.android.com/studio/command-line-tools)
- [Flutter Android Setup](https://flutter.dev/docs/get-started/install/windows#android-setup)
- [Flutter Doctor Guide](https://flutter.dev/docs/get-started/install#verify-your-flutter-and-dart-environment)
