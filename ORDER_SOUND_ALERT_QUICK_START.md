# Order Sound Alert - Quick Start Guide

## 🚀 Get Started in 5 Minutes

### Step 1: Add Dependencies
```bash
cd RIDERSIDE
flutter pub get
```

The `just_audio: ^0.9.36` dependency is already added to `pubspec.yaml`.

### Step 2: Add Sound Files
Create the sounds directory and add MP3 files:
```
RIDERSIDE/
└── assets/
    └── sounds/
        ├── order_bell.mp3
        ├── order_chime.mp3
        ├── order_ping.mp3
        └── order_notification.mp3
```

### Step 3: Initialize in main.dart
```dart
import 'package:lezgo_rider/core/services/order_sound_alert_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize order sound alerts
  await OrderSoundAlertService().initialize();
  
  runApp(const MyApp());
}
```

### Step 4: Add Widget to Settings
```dart
import 'package:lezgo_rider/presentation/widgets/main/merchantside/order_sound_alert_widget.dart';

// In your merchant settings screen
@override
Widget build(BuildContext context) {
  return Scaffold(
    // ... other widgets
    body: Column(
      children: [
        // Existing widgets...
        const OrderSoundAlertWidget(),  // Add this
      ],
    ),
  );
}
```

### Step 5: Build & Test
```bash
flutter clean
flutter pub get
flutter run
```

## 📁 Files Added

| File | Location | Purpose |
|------|----------|---------|
| `order_sound_alert_service.dart` | `core/services/` | Main service |
| `merchant_sound_settings_provider.dart` | `presentation/provider/...` | State management |
| `merchant_sound_alert_settings_screen.dart` | `presentation/screens/...` | Settings UI |
| `order_sound_alert_widget.dart` | `presentation/widgets/...` | Quick widget |

## 🎵 Available Sounds

- **Bell** 🔔 - Classic bell sound
- **Chime** ✨ - Melodic chime
- **Ping** 📳 - Short ping
- **Notification** 📢 - Notification tone

## 🎮 Usage

### For Users
1. Open Merchant Settings
2. Find "Order Notifications" section
3. Toggle sound on/off
4. Select sound type
5. Adjust volume
6. Enable/disable vibration
7. Click "Test Sound" to hear it

### For Developers
```dart
// Initialize
final service = OrderSoundAlertService();
await service.initialize();

// Play sound
await service.playOrderAlert();

// Change settings
await service.setSelectedSound('chime');
await service.setVolume(0.8);
```

## ✅ Testing Checklist

- [ ] App starts without errors
- [ ] Sound plays when test button clicked
- [ ] Volume slider works
- [ ] Sound selection works
- [ ] Settings persist after restart
- [ ] FCM notifications trigger sound (if enabled)

## 🐛 Troubleshooting

### Sound not playing?
1. Check audio files exist in `assets/sounds/`
2. Verify sound is enabled in settings
3. Check device volume is not muted
4. Test with different sounds

### Settings not saving?
1. Ensure SharedPreferences is initialized
2. Check device has storage permission
3. Verify app is not crashing on save

### App crashes on startup?
1. Ensure `just_audio` dependency is installed
2. Run `flutter clean && flutter pub get`
3. Check main.dart initialization

## 📚 Documentation

- **Full Guide**: See `ORDER_SOUND_ALERT_README.md`
- **Implementation Details**: See `ORDER_SOUND_ALERT_IMPLEMENTATION_SUMMARY.md`

## 🔗 Key Code Locations

1. **Service**: `lib/core/services/order_sound_alert_service.dart`
2. **Providers**: `lib/presentation/provider/main/merchantside/merchant_sound_settings_provider.dart`
3. **UI**: `lib/presentation/screens/main/merchantside/merchant_sound_alert_settings_screen.dart`
4. **Widget**: `lib/presentation/widgets/main/merchantside/order_sound_alert_widget.dart`
5. **FCM Integration**: `lib/core/services/fcm_service.dart`

## 💡 Pro Tips

1. **Test Sound First** - Always test the sound option before publishing
2. **Volume Default** - 70% volume is a good default for most users
3. **User Experience** - Let users customize; don't force settings
4. **Battery** - Consider battery impact; moderate volume is best
5. **Permissions** - Always request permissions before playing sounds

## 🎯 What's Next?

After basic setup, consider:
- Adding more sound options
- Implementing quiet hours
- Creating notification profiles
- Adding analytics tracking
- Different sounds for different order types

---

**Ready to integrate?** Start with Step 1! 🚀
