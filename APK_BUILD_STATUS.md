# APK Build Status - LEZGO Apps

## 🚀 Building APKs for Production

**Production API**: `https://lesgo-api-feature-auth-secmes.free.laravel.cloud/api`  
**Status**: ✅ LIVE & WORKING  
**Build Type**: Release APK

---

## 📦 Build Progress

### FRONTEND (Customer App)
- **Status**: 🔄 **BUILDING NOW...**
- **Command**: `flutter build apk --release`
- **Output Location**: `FRONTEND/build/app/outputs/flutter-apk/app-release.apk`
- **Estimated Time**: 3-5 minutes

### RIDERSIDE (Rider App)
- **Status**: ⏳ **PENDING** (will build after FRONTEND completes)
- **Issue**: Missing `.g.dart` files (needs code generation first)
- **Command**: `flutter build apk --release`
- **Output Location**: `RIDERSIDE/build/app/outputs/flutter-apk/app-release.apk`

---

## ✅ Configuration Summary

### API Configuration
Both apps are configured to use production API:
```dart
static String get baseUrl {
  return 'https://lesgo-api-feature-auth-secmes.free.laravel.cloud/api';
}
```

### Timeout Settings
- **Connect Timeout**: 30 seconds
- **Receive Timeout**: 30 seconds

### Production Data
- ✅ Services seeded
- ✅ Restaurants: Jollibee, Mang Inasal, Chowking
- ✅ Stores: Mercury Drug, National Book Store, Ace Hardware, Watsons
- ✅ Test driver account: `driver@lesgo.test` / `password`

---

## 📱 After Build Completes

### APK Locations
```
FRONTEND/build/app/outputs/flutter-apk/app-release.apk
RIDERSIDE/build/app/outputs/flutter-apk/app-release.apk
```

### Installation Methods

**Method 1: USB Cable**
```bash
# Connect phone via USB
adb install FRONTEND/build/app/outputs/flutter-apk/app-release.apk
```

**Method 2: File Transfer**
1. Copy APK to phone
2. Open APK file on phone
3. Allow "Install from Unknown Sources"
4. Install

**Method 3: Direct Copy**
- Copy APK to phone via USB/Bluetooth/Cloud
- Install directly from phone

---

## 🧪 Testing Checklist

### FRONTEND (Customer App)
- [ ] Install APK on phone
- [ ] Open app
- [ ] Test registration (create new account)
- [ ] Test login with registered account
- [ ] Browse restaurants/stores
- [ ] Test booking flow
- [ ] Test order placement

### RIDERSIDE (Rider App)
- [ ] Install APK on phone
- [ ] Open app
- [ ] Test registration (create rider account)
- [ ] Test login
- [ ] View available bookings
- [ ] Test accept booking
- [ ] Test tracking

---

## ⚠️ Known Issues

### RIDERSIDE Build Issue
**Problem**: Missing `.g.dart` files for JSON serialization

**Solution**:
```bash
cd RIDERSIDE
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter build apk --release
```

**Alternative**: Build debug APK first to test
```bash
flutter build apk --debug
```

---

## 📊 Build Specifications

### Release APK
- **Build Mode**: Release
- **Optimization**: Enabled
- **Obfuscation**: Disabled (can be enabled later)
- **Shrinking**: Enabled
- **Target**: Android API 21+ (Android 5.0+)

### APK Size (Estimated)
- **FRONTEND**: ~50-80 MB
- **RIDERSIDE**: ~50-80 MB

---

## 🔐 Security Notes

### Production Configuration
- ✅ HTTPS enabled
- ✅ 30-second timeout
- ✅ Token-based authentication
- ✅ Secure storage for tokens

### Before Distribution
- [ ] Test all features thoroughly
- [ ] Verify API endpoints
- [ ] Test on multiple devices
- [ ] Check permissions
- [ ] Test offline behavior

---

## 📝 Next Steps

1. **Wait for FRONTEND build** to complete (~3-5 minutes)
2. **Test FRONTEND APK** on real device
3. **Fix RIDERSIDE** `.g.dart` issue
4. **Build RIDERSIDE APK**
5. **Test RIDERSIDE APK** on real device
6. **Distribute** to testers/users

---

## 🎯 Distribution Options

### Internal Testing
- Share APK directly via file transfer
- Use Google Drive/Dropbox
- Email to testers

### Beta Testing
- Upload to Google Play Console (Internal Testing)
- Use Firebase App Distribution
- TestFlight (for iOS later)

### Production Release
- Upload to Google Play Store
- Complete store listing
- Submit for review

---

## 📞 Support

If you encounter issues:
1. Check build logs
2. Verify API is accessible
3. Test on emulator first
4. Check device compatibility
5. Review error messages

---

**Build Started**: May 8, 2026  
**Production API**: ✅ LIVE  
**FRONTEND Build**: 🔄 IN PROGRESS  
**RIDERSIDE Build**: ⏳ PENDING
