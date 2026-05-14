# APK Build Guide - LEZGO Apps

## 🚨 Current Situation

**Production Server Status**: ❌ DOWN (lesgo-api-feature-auth-secmes.free.laravel.cloud not responding)  
**Local Server Status**: ✅ RUNNING (http://127.0.0.1:8000)

Para ma-generate ang APK na pwedeng i-install sa actual phone, kailangan ng accessible API server.

---

## 🎯 Solution: Use ngrok to Expose Local Server

### Step 1: Install ngrok
1. Download ngrok: https://ngrok.com/download
2. Extract and place `ngrok.exe` sa accessible location
3. Sign up for free account: https://dashboard.ngrok.com/signup
4. Get your authtoken from: https://dashboard.ngrok.com/get-started/your-authtoken

### Step 2: Configure ngrok
```bash
ngrok config add-authtoken YOUR_AUTH_TOKEN
```

### Step 3: Start ngrok Tunnel
```bash
# In a new terminal
ngrok http 8000
```

This will give you a public URL like: `https://abc123.ngrok.io`

### Step 4: Update Flutter Apps to Use ngrok URL

**FRONTEND/lib/core/constants/api_constants.dart**:
```dart
static String get baseUrl {
  return 'https://YOUR_NGROK_URL.ngrok.io/api';
}
```

**RIDERSIDE/lib/core/constants/api_constants.dart**:
```dart
static String get baseUrl {
  return 'https://YOUR_NGROK_URL.ngrok.io/api';
}
```

**RIDERSIDE/lib/core/network/dio_client.dart**:
```dart
baseUrl: 'https://YOUR_NGROK_URL.ngrok.io/api',
```

### Step 5: Build APK

**For FRONTEND (Customer App)**:
```bash
cd FRONTEND
flutter build apk --release
```

**For RIDERSIDE (Rider App)**:
```bash
cd RIDERSIDE
flutter build apk --release
```

APK location:
- FRONTEND: `FRONTEND/build/app/outputs/flutter-apk/app-release.apk`
- RIDERSIDE: `RIDERSIDE/build/app/outputs/flutter-apk/app-release.apk`

---

## 🔄 Alternative: Fix Production Server

If you want to use the production server instead:

### 1. Check Server Status
```bash
curl https://lesgo-api-feature-auth-secmes.free.laravel.cloud/api/v1/auth/login
```

### 2. Redeploy Backend
- Login to Laravel Cloud dashboard
- Redeploy the `feature/chat` branch
- Wait for deployment to complete

### 3. Test Server
```bash
curl -X POST https://lesgo-api-feature-auth-secmes.free.laravel.cloud/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"testrider@lesgo.com","password":"TestRider123!"}'
```

### 4. Update Apps to Production URL
```dart
static String get baseUrl {
  return 'https://lesgo-api-feature-auth-secmes.free.laravel.cloud/api';
}
```

### 5. Build APK
```bash
flutter build apk --release
```

---

## 📦 Quick Build Commands

### Build Debug APK (Faster, for testing)
```bash
# FRONTEND
cd FRONTEND
flutter build apk --debug

# RIDERSIDE
cd RIDERSIDE
flutter build apk --debug
```

### Build Release APK (Optimized, for distribution)
```bash
# FRONTEND
cd FRONTEND
flutter build apk --release

# RIDERSIDE
cd RIDERSIDE
flutter build apk --release
```

### Build App Bundle (For Google Play Store)
```bash
# FRONTEND
cd FRONTEND
flutter build appbundle --release

# RIDERSIDE
cd RIDERSIDE
flutter build appbundle --release
```

---

## 🔍 Troubleshooting

### Error: "Gradle build failed"
```bash
# Clean build
flutter clean
flutter pub get
flutter build apk --release
```

### Error: "Missing .g.dart files" (RIDERSIDE only)
```bash
# Generate JSON serialization files
cd RIDERSIDE
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Error: "Signing key not found"
- For debug builds, this is automatic
- For release builds, you need to configure signing in `android/app/build.gradle`

---

## 📱 Installing APK on Phone

### Method 1: USB Cable
1. Enable Developer Options on phone
2. Enable USB Debugging
3. Connect phone to PC
4. Run: `flutter install` or manually copy APK

### Method 2: File Transfer
1. Copy APK to phone via USB/Bluetooth/Cloud
2. Open APK file on phone
3. Allow "Install from Unknown Sources"
4. Install

### Method 3: ADB Install
```bash
adb install path/to/app-release.apk
```

---

## ⚙️ Current Configuration

### Local Server (Currently Running)
- **URL**: http://127.0.0.1:8000
- **Status**: ✅ Running
- **Access**: Local only (emulator can access via 10.0.2.2:8000)

### Apps Configuration (Current)
- **FRONTEND**: Using local server (10.0.2.2:8000)
- **RIDERSIDE**: Using local server (10.0.2.2:8000)
- **Timeout**: 30 seconds

---

## 🎯 Recommended Workflow

### For Development & Testing
1. Use local server with emulator
2. URL: `http://10.0.2.2:8000/api`
3. Fast iteration, easy debugging

### For APK Testing on Real Device
1. Use ngrok to expose local server
2. URL: `https://YOUR_NGROK_URL.ngrok.io/api`
3. Build APK with ngrok URL
4. Install on phone and test

### For Production Release
1. Fix and deploy production server
2. URL: `https://lesgo-api-feature-auth-secmes.free.laravel.cloud/api`
3. Build release APK
4. Distribute to users

---

## 📝 Next Steps

1. **Choose your approach**:
   - Option A: Use ngrok (Quick, for testing)
   - Option B: Fix production server (Better for long-term)

2. **Update API URLs** in both apps

3. **Build APK**:
   ```bash
   flutter build apk --release
   ```

4. **Test on real device**

5. **If everything works, prepare for production**

---

## 🔗 Useful Links

- ngrok: https://ngrok.com
- Flutter Build Docs: https://docs.flutter.dev/deployment/android
- Laravel Cloud: https://cloud.laravel.com

---

**Last Updated**: May 8, 2026  
**Local Server**: ✅ Running on http://127.0.0.1:8000  
**Production Server**: ❌ Not responding  
**Recommended**: Use ngrok for APK testing
