# 🚀 Registration API Integration - Quick Start

**Para sa Rider at Merchant Registration**

---

## ⚡ QUICK SETUP (3 Steps)

### **Step 1: Install Dependencies**
```bash
cd RIDERSIDE
flutter pub get
```

### **Step 2: Generate Code**
```powershell
# Windows
cd RIDERSIDE
.\generate_dto.ps1
```

### **Step 3: Update main.dart**
```dart
import 'core/di/injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Add this line ⬇️
  await configureDependencies();
  
  runApp(const MyApp());
}
```

---

## ✅ DONE!

**Merchant Registration**: 🟢 **READY TO USE**  
**Rider Registration**: 🟡 **WORKS** (with placeholder values)

---

## 🧪 TEST NOW

### **Test Merchant**:
1. Open RIDERSIDE app
2. Go to Merchant Registration
3. Fill form (including password!)
4. Upload documents
5. Submit
6. ✅ Should work!

### **Test Rider**:
1. Open RIDERSIDE app
2. Go to Rider Registration
3. Fill form
4. Upload documents
5. Submit
6. ⚠️ Uses placeholder password & license

---

## 📝 WHAT WAS DONE

✅ Created API client (`AuthRemoteDataSource`)  
✅ Created DTOs (6 files)  
✅ Updated providers (2 files)  
✅ Added dependency injection  
✅ Added `get_it` to pubspec.yaml  

---

## ⚠️ IMPORTANT

**Rider Registration** uses placeholder values:
- Password: `TempPassword123!`
- License: `N01-12-345678`
- Phone: `+639171234567`

**Why?** Current UI doesn't collect these fields.

**Fix**: Add password & license fields to rider registration UI.

---

## 🐛 IF ERROR

### **"Cannot find get_it"**
```bash
cd RIDERSIDE
flutter pub get
```

### **"Missing .g.dart files"**
```bash
cd RIDERSIDE
flutter pub run build_runner build --delete-conflicting-outputs
```

### **"DioClient not registered"**
Add `await configureDependencies();` to `main.dart`

---

## 📚 FULL DOCS

Check `RIDER_MERCHANT_REGISTRATION_IMPLEMENTATION.md` for complete details.

---

**Status**: ✅ READY  
**Time**: 5 minutes to setup  
**Difficulty**: Easy 😊
