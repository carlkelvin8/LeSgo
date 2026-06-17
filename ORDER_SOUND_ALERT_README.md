# Order Sound Alert Feature

A comprehensive notification sound system for the LezGo Rider app that plays custom alert sounds when new orders are received.

## Overview

The Order Sound Alert feature enhances order notifications by:
- Playing custom alert sounds when new orders arrive
- Allowing users to customize sound selections
- Providing volume control
- Enabling/disabling vibration alerts
- Persistent user preferences

## Architecture

### Core Components

#### 1. **OrderSoundAlertService** (`order_sound_alert_service.dart`)
The main service handling all sound alert operations.

**Key Features:**
- Audio playback using `just_audio` package
- SharedPreferences for persistent settings
- Multiple sound options (bell, chime, ping, notification)
- Volume control (0.0 - 1.0)
- Vibration toggle

**Key Methods:**
```dart
// Initialize the service
await OrderSoundAlertService().initialize();

// Play alert sound
await OrderSoundAlertService().playOrderAlert();

// Sound settings
setSoundEnabled(bool enabled)
getSelectedSound() → String
setVolume(double volume)
getVolume() → double

// Vibration settings
setVibrationEnabled(bool enabled)
getVibrationEnabled() → bool

// Utilities
testSound()
resetToDefaults()
dispose()
```

#### 2. **Sound Settings Provider** (`merchant_sound_settings_provider.dart`)
Riverpod providers for state management of sound preferences.

**Providers:**
- `soundEnabledProvider` - Enable/disable sound alerts
- `soundVolumeProvider` - Control volume level
- `selectedSoundProvider` - Select alert sound type
- `vibrationEnabledProvider` - Enable/disable vibration
- `availableSoundsProvider` - List available sounds

#### 3. **Settings Screen** (`merchant_sound_alert_settings_screen.dart`)
Complete UI for managing sound alert preferences.

**Features:**
- Sound alert toggle
- Sound selection radio buttons
- Volume slider control
- Test sound button
- Vibration toggle
- Info cards with tips

#### 4. **FCM Service Integration** (`fcm_service.dart`)
Enhanced to automatically trigger sound alerts for new orders.

**Integration:**
- Detects order notifications
- Calls `OrderSoundAlertService.playOrderAlert()` on new orders
- Automatic sound playback based on user preferences

## Available Sounds

The system comes with 4 default sounds:

| Sound | Key | Asset Path |
|-------|-----|-----------|
| 🔔 Bell | `bell` | `assets/sounds/order_bell.mp3` |
| ✨ Chime | `chime` | `assets/sounds/order_chime.mp3` |
| 📳 Ping | `ping` | `assets/sounds/order_ping.mp3` |
| 📢 Notification | `notification` | `assets/sounds/order_notification.mp3` |

### Adding Custom Sounds

To add more sounds, update `OrderSoundAlertService.availableSounds`:

```dart
static const Map<String, String> availableSounds = {
  'bell': 'assets/sounds/order_bell.mp3',
  'chime': 'assets/sounds/order_chime.mp3',
  'custom_sound': 'assets/sounds/custom_sound.mp3', // Add here
};
```

Then update the display names in the UI:
```dart
const soundNames = {
  'bell': '🔔 Bell',
  'custom_sound': '🎵 Custom', // Add here
};
```

## Implementation Guide

### Step 1: Add Dependencies

Update `pubspec.yaml`:
```yaml
dependencies:
  just_audio: ^0.9.36
```

Add sound assets:
```yaml
flutter:
  assets:
    - assets/sounds/
```

### Step 2: Initialize Service

Initialize the sound alert service in your app's main initialization:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize order sound alerts
  await OrderSoundAlertService().initialize();
  
  runApp(const MyApp());
}
```

### Step 3: Use in UI

Add the sound alert widget to merchant/rider settings:

```dart
import 'package:lezgo_rider/presentation/widgets/main/merchantside/order_sound_alert_widget.dart';

// In your settings screen
OrderSoundAlertWidget()
```

Or navigate to the full settings screen:

```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => const MerchantSoundAlertSettingsScreen(),
  ),
);
```

### Step 4: FCM Integration

The system automatically integrates with FCM. When a notification arrives:

1. FCM message is received
2. System checks if it's an order notification
3. If order notification and sound enabled → plays alert
4. Shows local notification

## Persistence

All settings are automatically saved using `SharedPreferences`:

```
- order_sound_enabled: Boolean (default: true)
- order_sound_volume: Double 0.0-1.0 (default: 0.7)
- order_sound_selected: String (default: 'bell')
- order_vibration_enabled: Boolean (default: true)
```

## Error Handling

The service gracefully handles errors:
- Silently fails if device doesn't support audio
- Logs errors for debugging
- Doesn't crash if asset not found
- Continues operation if initialization fails

## Testing

### Test Sound
Users can test the current sound configuration:

```dart
final service = OrderSoundAlertService();
await service.testSound(); // Plays selected sound at current volume
```

### Manual Testing in Code
```dart
// Initialize
await OrderSoundAlertService().initialize();

// Test with custom settings
await OrderSoundAlertService().setSoundEnabled(true);
await OrderSoundAlertService().setVolume(0.8);
await OrderSoundAlertService().setSelectedSound('chime');
await OrderSoundAlertService().playOrderAlert();
```

## Platform Support

### Android
- ✅ Full support
- Uses native Android audio capabilities
- Respects system volume settings
- Supports vibration feedback

### iOS
- ✅ Full support
- Uses AVAudioPlayer
- Respects device silent mode
- Supports haptic feedback (vibration)

### Web
- ⚠️ Limited support (optional)
- Can be extended with web audio API

## Best Practices

1. **Initialization**: Initialize the service early in app lifecycle
2. **Permissions**: Always request audio and vibration permissions
3. **Testing**: Test sound playback during onboarding
4. **User Preferences**: Respect user settings (don't override)
5. **Battery**: Consider impact on battery life (use moderate volume)
6. **Cleanup**: Call `dispose()` when app closes

## Troubleshooting

### Sound Not Playing
- Verify sound files exist in `assets/sounds/`
- Check if sounds are enabled in settings
- Ensure device volume is not muted
- Test with `testSound()` method

### Volume Not Changing
- Ensure volume slider is properly bound to provider
- Check SharedPreferences is initialized
- Verify value is between 0.0 and 1.0

### Vibration Not Working
- Check device supports vibration
- Verify vibration is enabled in settings
- Note: Some devices disable vibration when in certain modes

## File Structure

```
lib/
├── core/
│   └── services/
│       ├── order_sound_alert_service.dart      # Main service
│       └── fcm_service.dart                    # FCM integration
├── presentation/
│   ├── provider/
│   │   └── main/merchantside/
│   │       └── merchant_sound_settings_provider.dart  # State management
│   ├── screens/
│   │   └── main/merchantside/
│   │       └── merchant_sound_alert_settings_screen.dart  # Settings UI
│   └── widgets/
│       └── main/merchantside/
│           └── order_sound_alert_widget.dart  # Quick access widget
└── assets/
    └── sounds/
        ├── order_bell.mp3
        ├── order_chime.mp3
        ├── order_ping.mp3
        └── order_notification.mp3
```

## Future Enhancements

- [ ] Multiple notification profiles (urgent, normal, low priority)
- [ ] Time-based sound rules (quiet hours)
- [ ] Sound customization upload
- [ ] Analytics for sound alert usage
- [ ] Different sounds for different order types
- [ ] Do Not Disturb integration

## License

This feature is part of the LezGo platform.

## Support

For issues or improvements, please refer to the main project documentation.
