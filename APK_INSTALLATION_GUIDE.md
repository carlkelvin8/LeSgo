# LesGo Customer App - APK Installation Guide 📱

## 📦 APK Files Built Successfully!

**Version**: 1.1.6 (Build 20)  
**Build Date**: September 16, 2026  
**Location**: `c:\Users\PC\LEZGO\`

---

## 🎯 Which APK to Install?

### ✅ **RECOMMENDED: ARM64 (Most Modern Devices)**
**File**: `lesgo-customer-v1.1.6-build20-arm64.apk`  
**Size**: 56.3 MB  
**For**: Most modern Android phones (2017+)  
**Devices**: Samsung Galaxy S8+, Xiaomi, Oppo, Vivo, Realme, OnePlus (most models)

### ⚠️ **ALTERNATIVE: ARMv7 (Older Devices)**
**File**: `lesgo-customer-v1.1.6-build20-armeabi-v7a.apk`  
**Size**: 54.6 MB  
**For**: Older Android phones (2015-2016)  
**Devices**: Older budget phones, some tablets

### 🖥️ **EMULATOR ONLY: x86_64**
**File**: `lesgo-customer-v1.1.6-build20-x86_64.apk`  
**Size**: 57.8 MB  
**For**: Android emulators on PC (NOT for real phones)

---

## 📲 Installation Steps

### Method 1: Direct Install (Easiest)

**Step 1: Transfer APK to Phone**
```
1. Connect phone to PC via USB
2. Copy APK file to phone's Download folder
3. Or send via Telegram/Messenger to yourself
```

**Step 2: Enable Unknown Sources**
```
1. Go to Settings → Security → Unknown Sources
2. OR Settings → Apps → Special Access → Install Unknown Apps
3. Enable for "Files" or "Downloads" app
```

**Step 3: Install**
```
1. Open File Manager on phone
2. Navigate to Downloads folder
3. Tap on the APK file
4. Tap "Install"
5. Wait for installation to complete
6. Tap "Open" or find "LesGo" app icon
```

### Method 2: Via ADB (Developer)

**Requirements**: ADB installed on PC

**Steps**:
```powershell
# Enable USB Debugging on phone first
# Then run:

cd c:\Users\PC\LEZGO

# For ARM64 devices (recommended):
adb install lesgo-customer-v1.1.6-build20-arm64.apk

# For older devices:
adb install lesgo-customer-v1.1.6-build20-armeabi-v7a.apk

# For emulator:
adb install lesgo-customer-v1.1.6-build20-x86_64.apk
```

### Method 3: Via Firebase App Distribution (Team)

**For sharing with team/testers:**
```
1. Upload APK to Firebase App Distribution
2. Add tester emails
3. Testers receive installation link via email
4. Click link to install
```

---

## ⚡ Quick Install Commands

### Install on Connected Phone (ARM64)
```powershell
adb install -r c:\Users\PC\LEZGO\lesgo-customer-v1.1.6-build20-arm64.apk
```

### Install on Emulator (x86_64)
```powershell
adb install -r c:\Users\PC\LEZGO\lesgo-customer-v1.1.6-build20-x86_64.apk
```

### Check Device Architecture
```powershell
adb shell getprop ro.product.cpu.abi
```
- Output `arm64-v8a` → Use ARM64 APK
- Output `armeabi-v7a` → Use ARMv7 APK
- Output `x86_64` → Use x86_64 APK (emulator)

---

## ✅ What's Included in This Version

### 🎨 Intense Home Screen Animations
- ✅ Hero carousel auto-scrolls (4s)
- ✅ Promo cards auto-scroll (3s)
- ✅ Floating cards (Inbox & Wallet)
- ✅ Icon bounce animations
- ✅ Arrow rotation animations
- ✅ Pulse animations on buttons
- ✅ Staggered page entrance
- ✅ Press feedback on all cards

### 🎯 Unified Theme
- ✅ Light clean design
- ✅ Consistent with profile page
- ✅ Dark purple text on light background
- ✅ Professional polish

### ⚡ Performance
- ✅ 60fps smooth animations
- ✅ Optimized file size
- ✅ Release mode build
- ✅ Obfuscation enabled

---

## 🔐 Security Notes

### Digital Signature
- **Signed**: Production keystore
- **SHA-1**: `E1:08:3F:68:C5:50:8B:C7:17:D5:E0:63:84:4E:ED:F0:52:1E:69:83`
- **Package**: `com.lesgo.app`

### Permissions Required
- ✅ Internet (API calls)
- ✅ Location (GPS tracking, maps)
- ✅ Camera (Profile photos, document upload)
- ✅ Storage (Photo uploads)
- ✅ Notifications (Push notifications)
- ✅ Phone (Google Sign-In)

---

## 🧪 Testing Checklist

After installation, verify:

### ✅ Basic Functionality
- [ ] App launches successfully
- [ ] Login with Google working
- [ ] Login with email/password working
- [ ] Home screen displays correctly
- [ ] All animations working smoothly

### ✅ Animations
- [ ] Hero carousel auto-scrolls every 4s
- [ ] Promo cards auto-scroll every 3s
- [ ] Cards float up and down
- [ ] Icons bounce
- [ ] Arrows spin
- [ ] BOOK NOW button pulses
- [ ] Track order icon pulses (if order exists)
- [ ] Press feedback on cards

### ✅ Services
- [ ] LesRide booking works
- [ ] LesEat restaurant browsing works
- [ ] LesBuy store browsing works
- [ ] LesGo package delivery works
- [ ] LesPay wallet works

### ✅ Core Features
- [ ] Order tracking works
- [ ] Chat functionality works
- [ ] Push notifications work
- [ ] Maps display correctly
- [ ] Payment processing works

---

## 🐛 Troubleshooting

### Issue: "App not installed"
**Solutions**:
```
1. Uninstall old version first
2. Enable "Install from Unknown Sources"
3. Check if enough storage space (need ~200MB)
4. Try different APK version (ARM64 vs ARMv7)
```

### Issue: "Parse error"
**Solutions**:
```
1. Re-download APK (file may be corrupted)
2. Check Android version (need Android 6.0+)
3. Try ARMv7 version instead of ARM64
```

### Issue: "Google Sign-In not working"
**Solutions**:
```
1. Check internet connection
2. Clear app cache and data
3. Make sure Play Store SHA-1 is added to Google Console
4. Reinstall app
```

### Issue: "Animations not smooth"
**Solutions**:
```
1. Close background apps
2. Restart phone
3. Check if device supports 60fps
4. Animations work best on Android 8.0+ devices
```

### Issue: "App crashes on launch"
**Solutions**:
```
1. Clear app data: Settings → Apps → LesGo → Clear Data
2. Reinstall app
3. Check Android version (need 6.0+)
4. Check if device has 2GB+ RAM
```

---

## 📊 Device Compatibility

### ✅ Supported
- Android 6.0 (Marshmallow) and above
- ARM64-v8a architecture (most devices 2017+)
- ARMv7 architecture (older devices 2015-2016)
- 2GB+ RAM recommended
- 500MB free storage

### ❌ Not Supported
- Android 5.1 and below
- x86 architecture (real phones, not emulators)
- Devices with less than 1GB RAM

---

## 📱 Recommended Devices

### Excellent Performance (60fps smooth):
- Samsung Galaxy S9 and newer
- Xiaomi Redmi Note 8 and newer
- Oppo/Vivo/Realme (2019 models+)
- OnePlus 6 and newer
- Google Pixel 3 and newer

### Good Performance:
- Samsung Galaxy S7/S8
- Xiaomi Redmi 5/6/7 series
- Budget phones with 3GB+ RAM

### Minimum Performance:
- Older phones with 2GB RAM
- Android 6.0-7.0 devices
- Animations may not be as smooth

---

## 🔄 Updating from Previous Version

### If you have v1.1.5 or older installed:

**Option 1: Install Over (Preserves Data)**
```
1. Just install new APK
2. Tap "Update" when prompted
3. App data and login preserved
```

**Option 2: Clean Install (Fresh Start)**
```
1. Uninstall old version
2. Install new APK
3. Need to login again
4. All data cleared
```

---

## 📤 Sharing with Team

### Via Telegram/Messenger:
```
1. Compress APK to ZIP (optional)
2. Send file directly
3. Recipient downloads and installs
```

### Via Google Drive:
```
1. Upload APK to Drive
2. Set sharing to "Anyone with link"
3. Share link with team
4. They download and install
```

### Via Firebase App Distribution (Best):
```
1. Upload to Firebase
2. Add tester emails
3. They receive link via email
4. One-click install
```

---

## 🎯 File Locations

**APK Files**:
```
c:\Users\PC\LEZGO\lesgo-customer-v1.1.6-build20-arm64.apk (ARM64 - RECOMMENDED)
c:\Users\PC\LEZGO\lesgo-customer-v1.1.6-build20-armeabi-v7a.apk (ARMv7 - Older devices)
c:\Users\PC\LEZGO\lesgo-customer-v1.1.6-build20-x86_64.apk (Emulator only)
```

**AAB File** (for Play Store):
```
c:\Users\PC\LEZGO\lesgo-customer-v1.1.6-build20-with-animations.aab
```

**Documentation**:
```
c:\Users\PC\LEZGO\RELEASE_NOTES_v1.1.6.md
c:\Users\PC\LEZGO\DEPLOYMENT_CHECKLIST_v1.1.6.md
c:\Users\PC\LEZGO\APK_INSTALLATION_GUIDE.md (this file)
```

---

## 💡 Tips

### For Best Experience:
- ✅ Use ARM64 version on modern phones
- ✅ Install on devices with 3GB+ RAM
- ✅ Use Android 8.0+ for best animation performance
- ✅ Close background apps before testing animations
- ✅ Connect to stable internet for all features

### For Testing:
- ✅ Test on multiple devices if possible
- ✅ Try both Google login and email login
- ✅ Test all 5 services (LesRide, LesEat, LesBuy, LesGo, LesPay)
- ✅ Verify animations work smoothly
- ✅ Check push notifications
- ✅ Test order tracking

---

**APK STATUS**: ✅ **READY FOR INSTALLATION**  
**BUILD TYPE**: Release (Production)  
**RECOMMENDED FILE**: `lesgo-customer-v1.1.6-build20-arm64.apk`  

**Install now and enjoy the enhanced experience with intense animations! 🎉📱✨**
