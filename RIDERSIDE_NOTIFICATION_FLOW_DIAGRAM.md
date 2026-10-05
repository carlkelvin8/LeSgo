# RIDERSIDE: Persistent Notification Sound Flow Diagram

## 🔔 Notification Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                    NEW BOOKING ARRIVES                               │
│                  (FCM Push Notification)                             │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│              FcmService._showForegroundNotification()                │
│                                                                       │
│  • Receives RemoteMessage                                            │
│  • Checks if order notification (_isOrderNotification)               │
│  • Calls OrderSoundAlertService().playOrderAlert()                   │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│            OrderSoundAlertService.playOrderAlert()                   │
│                                                                       │
│  1. Stop any existing sound                                          │
│  2. Check if sound enabled (getSoundEnabled)                         │
│  3. Apply volume (getVolume)                                         │
│  4. Get selected sound (getSelectedSound)                            │
│  5. Check looping enabled (getLoopingEnabled)                        │
│                                                                       │
│  IF LOOPING ENABLED:                                                 │
│    • Set LoopMode.one                                                │
│    • _isLooping = true                                               │
│    • Start vibration pattern (every 2 seconds)                       │
│                                                                       │
│  6. Play sound with AudioPlayer                                      │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                  🔊 SOUND LOOPS CONTINUOUSLY                         │
│                  📳 VIBRATION REPEATS EVERY 2s                       │
│                                                                       │
│  Sound keeps playing until one of these happens:                     │
│    • Rider opens app                                                 │
│    • Rider views Bookings tab                                        │
│    • App calls acknowledgeOrderAlert()                               │
└─────────────────────────────────────────────────────────────────────┘
                             │
                             │
        ┌────────────────────┴────────────────────┐
        │                                         │
        ▼                                         ▼
┌──────────────────────┐              ┌──────────────────────┐
│  Rider Opens App     │              │ Rider Views Bookings │
│                      │              │       Tab            │
│  RiderMainScreen     │              │                      │
│    .initState()      │              │ RiderBookingsView    │
│                      │              │    .initState()      │
└──────────┬───────────┘              └──────────┬───────────┘
           │                                     │
           │                                     │
           └──────────────┬──────────────────────┘
                          │
                          ▼
        ┌─────────────────────────────────────────┐
        │  acknowledgeOrderAlert() called         │
        └─────────────────┬───────────────────────┘
                          │
                          ▼
        ┌─────────────────────────────────────────┐
        │         stopSound()                     │
        │                                         │
        │  1. audioPlayer.stop()                  │
        │  2. setLoopMode(LoopMode.off)           │
        │  3. _stopVibrationPattern()             │
        │  4. _isLooping = false                  │
        └─────────────────┬───────────────────────┘
                          │
                          ▼
        ┌─────────────────────────────────────────┐
        │     🔇 SOUND STOPPED                    │
        │     ✋ VIBRATION STOPPED                 │
        └─────────────────────────────────────────┘
```

---

## 🎵 Sound Selection Flow

```
┌────────────────────────────────────────────────────┐
│          OrderSoundAlertService                    │
│                                                    │
│  getSelectedSound() →  SharedPreferences           │
│                           ↓                        │
│                    'order_sound_selected'          │
│                           ↓                        │
│          Returns: 'bell' | 'chime' | 'ping' |     │
│                   'notification'                   │
└────────────────────────────┬───────────────────────┘
                             │
                             ▼
┌────────────────────────────────────────────────────┐
│          availableSounds Map                       │
│                                                    │
│  'bell'         → 'assets/sounds/order_bell.mp3'   │
│  'chime'        → 'assets/sounds/order_chime.mp3'  │
│  'ping'         → 'assets/sounds/order_ping.mp3'   │
│  'notification' → 'assets/sounds/order_notification.mp3' │
└────────────────────────────┬───────────────────────┘
                             │
                             ▼
┌────────────────────────────────────────────────────┐
│          audioPlayer.setAsset(soundPath)           │
│          audioPlayer.play()                        │
└────────────────────────────────────────────────────┘
```

---

## ⚙️ Settings Flow

```
┌────────────────────────────────────────────────────┐
│              SharedPreferences                     │
│                                                    │
│  Key                            Default            │
│  ─────────────────────────────  ───────           │
│  order_sound_enabled            true               │
│  order_sound_looping_enabled    true ⭐            │
│  order_sound_volume             0.7                │
│  order_sound_selected           'bell'             │
│  order_vibration_enabled        true               │
└────────────────────────────────────────────────────┘
                      │
                      │ Get/Set via OrderSoundAlertService
                      │
        ┌─────────────┴─────────────┐
        │                           │
        ▼                           ▼
┌──────────────────┐      ┌──────────────────┐
│   Getters        │      │   Setters        │
│                  │      │                  │
│ getSoundEnabled  │      │ setSoundEnabled  │
│ getLoopingEnabled│      │ setLoopingEnabled│
│ getVolume        │      │ setVolume        │
│ getSelectedSound │      │ setSelectedSound │
│ getVibrationEnabled     │ setVibrationEnabled│
└──────────────────┘      └──────────────────┘
```

---

## 📳 Vibration Pattern Flow

```
┌────────────────────────────────────────────────────┐
│     _startVibrationPattern() called                │
└────────────────────┬───────────────────────────────┘
                     │
                     ▼
┌────────────────────────────────────────────────────┐
│  Timer.periodic(Duration(seconds: 2))              │
│                                                    │
│  Every 2 seconds:                                  │
│    HapticFeedback.heavyImpact()                    │
└────────────────────┬───────────────────────────────┘
                     │
                     │ Repeats until...
                     │
                     ▼
┌────────────────────────────────────────────────────┐
│  _stopVibrationPattern() called                    │
│                                                    │
│  • _vibrationTimer?.cancel()                       │
│  • _vibrationTimer = null                          │
└────────────────────────────────────────────────────┘
```

---

## 🔄 State Tracking

```
┌─────────────────────────────────────────────┐
│     OrderSoundAlertService State            │
│                                             │
│  _isInitialized: bool                       │
│    ↳ Service ready for use                  │
│                                             │
│  _isLooping: bool                           │
│    ↳ Currently playing looped sound         │
│                                             │
│  _vibrationTimer: Timer?                    │
│    ↳ Active vibration pattern timer         │
│                                             │
│  _audioPlayer: AudioPlayer                  │
│    ↳ just_audio player instance             │
│                                             │
│  _prefs: SharedPreferences                  │
│    ↳ Settings storage                       │
└─────────────────────────────────────────────┘
```

---

## 🎯 Stop Triggers

```
┌──────────────────────────────────────────────────┐
│         When Does Sound Stop?                    │
│                                                  │
│  1. ✅ Rider opens app                           │
│     → RiderMainScreen.initState()                │
│     → acknowledgeOrderAlert()                    │
│                                                  │
│  2. ✅ Rider views Bookings tab                  │
│     → RiderBookingsView.initState()              │
│     → acknowledgeOrderAlert()                    │
│                                                  │
│  3. ✅ Manual stop                               │
│     → stopSound() called directly                │
│                                                  │
│  4. ⚙️ Looping disabled in settings              │
│     → Plays once, doesn't loop                   │
│                                                  │
│  5. 🔇 Sound disabled in settings                │
│     → Doesn't play at all                        │
└──────────────────────────────────────────────────┘
```

---

## 🎨 Visual Timeline

```
Time →
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

00:00  📲 Notification arrives
       ↓
00:01  🔊 Sound starts playing (loops)
       📳 Vibration starts (every 2s)
       ↓
00:03  📳 Vibration
       ↓
00:05  📳 Vibration
       ↓
00:07  📳 Vibration
       ↓
00:10  👤 Rider opens app
       ↓
00:11  🔇 Sound stops
       ✋ Vibration stops
       ✅ Alert acknowledged

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 📱 Platform Behavior

```
┌──────────────────────────────────────────────────┐
│              Android (Primary)                   │
│                                                  │
│  • ✅ Full support                               │
│  • ✅ Background sound works                     │
│  • ✅ Vibration works                            │
│  • ✅ Respects system DND                        │
│  • ✅ Battery optimization supported             │
└──────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────┐
│                   iOS                            │
│                                                  │
│  • ✅ Supported                                  │
│  • ⚠️ Requires notification permission           │
│  • ⚠️ Background limitations apply               │
│  • ✅ Vibration works                            │
└──────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────┐
│                   Web                            │
│                                                  │
│  • ❌ Not supported                              │
│  • ℹ️ kIsWeb check prevents issues               │
└──────────────────────────────────────────────────┘
```

---

## 🐛 Error Handling

```
┌────────────────────────────────────────────────────┐
│           Graceful Degradation                     │
│                                                    │
│  IF sound file not found:                          │
│    → Falls back to default 'bell'                  │
│    → Logs error with AppLogger                     │
│                                                    │
│  IF audio player fails:                            │
│    → Catches exception                             │
│    → Sets _isLooping = false                       │
│    → Logs error                                    │
│    → Notification still shows                      │
│                                                    │
│  IF vibration not supported:                       │
│    → Catches exception                             │
│    → Sound continues                               │
│    → No crash                                      │
│                                                    │
│  IF settings not available:                        │
│    → Uses default values                           │
│    → Service still works                           │
└────────────────────────────────────────────────────┘
```

---

**Legend:**
- 🔊 Sound playing
- 🔇 Sound stopped
- 📳 Vibration
- ✋ Stop
- 📲 Notification
- 👤 User action
- ✅ Success
- ⚠️ Warning
- ❌ Not supported
- ⭐ Default enabled

