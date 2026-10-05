# LeSgo Support Text Update

## ✅ Change Applied

Changed "LeSgo Rider Support" to "LeSgo Support" throughout the RIDERSIDE app.

## 📝 Files Modified

### 1. **Localization Strings**
**File**: `lib/core/utils/app_localization.dart`

**English (Before):**
```dart
'lesgo_rider_support': 'LeSgo Rider Support',
```

**English (After):**
```dart
'lesgo_rider_support': 'LeSgo Support',
```

**Filipino/Tagalog (Before):**
```dart
'lesgo_rider_support': 'LeSgo Rider Support',
```

**Filipino/Tagalog (After):**
```dart
'lesgo_rider_support': 'LeSgo Support',
```

### 2. **Welcome Message**
**File**: `lib/presentation/provider/main/riderside/rider_customer_service_chat_provider.dart`

**Before:**
```dart
const _welcomeMessage =
    'Hi! This is LeSgo Rider Support. Message our admin team here for help with safety, orders, earnings, LesPay, and account issues.';
```

**After:**
```dart
const _welcomeMessage =
    'Hi! This is LeSgo Support. Message our admin team here for help with safety, orders, earnings, LesPay, and account issues.';
```

## 🎯 Result

### App Bar Title:
- **Before**: "LeSgo Rider Support"
- **After**: "LeSgo Support"

### Welcome Message:
- **Before**: "Hi! This is LeSgo Rider Support..."
- **After**: "Hi! This is LeSgo Support..."

### Applies To:
- ✅ Merchant app
- ✅ Rider app
- ✅ Both English and Filipino languages

## 📱 App Status
- **App**: RIDERSIDE (Merchant/Rider/Affiliate)
- **Version**: v1.1.5+14
- **Status**: ✅ Running on emulator with text changes applied
- **Device**: emulator-5554 (sdk gphone64 x86 64)

## ✅ Verification
- ✅ Text changed in localization files (English & Filipino)
- ✅ Text changed in welcome message
- ✅ App rebuilt with changes
- ✅ No hardcoded "LeSgo Rider Support" remaining

## 📝 Note
The text is now generic "LeSgo Support" for both Rider and Merchant users, making it more appropriate for the unified support chat.
