# Real-time Tracking & Push Notifications Setup Guide

## ✅ What's Been Implemented

### 1. WebSocket Service (`lib/core/services/websocket_service.dart`)
- ✅ Pusher Channels Flutter integration (compatible with Laravel Reverb)
- ✅ Subscribe to order channels for real-time tracking
- ✅ Subscribe to user channels for notifications
- ✅ Subscribe to driver location updates
- ✅ Event stream management
- ✅ Automatic reconnection handling
- ✅ Private channel authorization

### 2. Notification Service (`lib/core/services/notification_service.dart`)
- ✅ Firebase Cloud Messaging (FCM) integration
- ✅ Local notifications for foreground messages
- ✅ Background message handling
- ✅ Notification channels (Order Updates, Driver Updates, General, Promotions)
- ✅ Notification tap handling with deep linking
- ✅ FCM token management and refresh
- ✅ Topic subscription support

### 3. Updated Live Tracking Provider
- ✅ WebSocket integration for real-time driver location
- ✅ Real-time order status updates
- ✅ Fallback to HTTP polling if WebSocket fails
- ✅ Automatic route updates when driver moves
- ✅ Event stream handling

### 4. App Notification Handler (`lib/core/services/app_notification_handler.dart`)
- ✅ Global notification management
- ✅ User session management
- ✅ Navigation handling from notifications
- ✅ Topic subscription management

---

## 🔧 Setup Required

### Step 1: Install Dependencies

Run the following command:

```bash
cd FRONTEND
flutter pub get
```

### Step 2: Firebase Setup

#### 2.1 Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or use existing one
3. Add Android app:
   - Package name: `com.lesgo.app` (or your actual package name)
   - Download `google-services.json`
   - Place it in `FRONTEND/android/app/`

4. Add iOS app (if needed):
   - Bundle ID: `com.lesgo.app`
   - Download `GoogleService-Info.plist`
   - Place it in `FRONTEND/ios/Runner/`

#### 2.2 Configure Firebase in Android

Edit `FRONTEND/android/build.gradle`:
```gradle
buildscript {
    dependencies {
        // Add this line
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

Edit `FRONTEND/android/app/build.gradle`:
```gradle
// Add at the bottom of the file
apply plugin: 'com.google.gms.google-services'
```

#### 2.3 Generate Firebase Options

Run FlutterFire CLI:
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase
flutterfire configure
```

This will generate `lib/firebase_options.dart` with your actual Firebase configuration.

#### 2.4 Update Backend with FCM Server Key

1. In Firebase Console, go to Project Settings > Cloud Messaging
2. Copy the Server Key
3. Update `BACKEND/lesgo-api/.env`:
```env
FIREBASE_PROJECT_ID=your-project-id
```

4. Download Firebase Admin SDK credentials:
   - Go to Project Settings > Service Accounts
   - Click "Generate new private key"
   - Save as `BACKEND/lesgo-api/storage/app/firebase-credentials.json`

### Step 3: Start Laravel Reverb Server

```bash
cd BACKEND/lesgo-api
php artisan reverb:start
```

This will start the WebSocket server on `localhost:8080`.

**For production**, you'll need to:
1. Deploy Reverb to a server with a public IP
2. Update `FRONTEND/lib/core/constants/api_constants.dart`:
```dart
static const String reverbHost = 'your-production-domain.com';
static const int reverbPort = 443;
static const String reverbScheme = 'https';
```

### Step 4: Initialize Services in Main App

Update `FRONTEND/lib/main.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/services/app_notification_handler.dart';
import 'core/di/injection.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize dependency injection
  await configureDependencies();
  
  // Initialize notification handler
  final notificationHandler = AppNotificationHandler(
    navigatorKey: navigatorKey,
  );
  await notificationHandler.initialize();
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // Important for notification navigation
      // ... rest of your app
    );
  }
}
```

### Step 5: Update User Login to Subscribe to Notifications

After successful login, update the notification handler:

```dart
// In your login provider/service
final notificationHandler = getIt<AppNotificationHandler>();
await notificationHandler.updateUserId(user.id);

// Send FCM token to backend
final fcmToken = notificationHandler.fcmToken;
if (fcmToken != null) {
  await authDataSource.updateFcmToken(fcmToken);
}
```

### Step 6: Test Real-time Features

#### Test Driver Location Updates:
1. Create an order
2. Assign a driver (via backend/admin panel)
3. Update driver location (via driver app or API):
```bash
curl -X POST http://localhost:8000/api/v1/tracking/driver/location \
  -H "Authorization: Bearer DRIVER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "latitude": 14.5995,
    "longitude": 120.9842,
    "accuracy": 10,
    "speed": 5,
    "heading": 90
  }'
```

4. Watch the customer app update in real-time!

#### Test Push Notifications:
1. Send a test notification from Firebase Console:
   - Go to Cloud Messaging
   - Click "Send your first message"
   - Enter title and body
   - Select your app
   - Send

2. Or trigger from backend:
```php
// In Laravel
use App\Events\OrderStatusUpdated;

$order = Order::find($orderId);
event(new OrderStatusUpdated($order, 'pending', 'accepted'));
```

---

## 📱 Android Permissions

Add to `FRONTEND/android/app/src/main/AndroidManifest.xml`:

```xml
<manifest>
    <!-- Add these permissions -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.VIBRATE"/>
    
    <application>
        <!-- Add notification icon -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_icon"
            android:resource="@mipmap/ic_launcher" />
        
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_color"
            android:resource="@color/colorPrimary" />
    </application>
</manifest>
```

---

## 🍎 iOS Setup

1. Enable Push Notifications capability in Xcode
2. Add to `FRONTEND/ios/Runner/Info.plist`:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

3. Request APNs certificate from Apple Developer Portal
4. Upload APNs certificate to Firebase Console

---

## 🔍 Debugging

### Check WebSocket Connection:
```dart
// In your app
debugPrint('WebSocket initialized: ${webSocketService._isInitialized}');
```

### Check FCM Token:
```dart
final token = notificationHandler.fcmToken;
debugPrint('FCM Token: $token');
```

### Monitor Laravel Reverb:
```bash
# In backend terminal
php artisan reverb:start --debug
```

### Test WebSocket from Browser:
```javascript
// Open browser console on http://localhost:8080
const pusher = new Pusher('8cwrfdifchs4011diljr', {
  wsHost: 'localhost',
  wsPort: 8080,
  forceTLS: false,
  enabledTransports: ['ws']
});

const channel = pusher.subscribe('private-order.1');
channel.bind('driver.location.updated', (data) => {
  console.log('Location update:', data);
});
```

---

## 🚀 Production Checklist

- [ ] Deploy Laravel Reverb to production server
- [ ] Update WebSocket host/port in `api_constants.dart`
- [ ] Enable SSL/TLS for WebSocket (wss://)
- [ ] Configure Firebase for production
- [ ] Upload APNs certificate (iOS)
- [ ] Test on physical devices
- [ ] Set up monitoring for WebSocket connections
- [ ] Configure FCM server key in backend
- [ ] Test notification delivery in production

---

## 📊 Event Types

### Order Events (Channel: `private-order.{orderId}`)
- `order.status.updated` - Order status changed
- `driver.location.updated` - Driver location updated
- `order.driver.assigned` - Driver assigned to order

### User Events (Channel: `private-user.{userId}`)
- `order.status.updated` - Any order status update
- `notification.sent` - New notification received
- `wallet.updated` - Wallet balance changed

### Driver Events (Channel: `private-driver.{driverId}`)
- `driver.location.updated` - Location update confirmation
- `order.assigned` - New order assigned

---

## 🎯 Next Steps

1. **Run `flutter pub get`** to install dependencies
2. **Set up Firebase** following Step 2
3. **Start Reverb server** following Step 3
4. **Update main.dart** following Step 4
5. **Test on device** - WebSocket and notifications don't work well on emulators

---

## ❓ Troubleshooting

### WebSocket not connecting:
- Check if Reverb server is running
- Verify `reverbHost` and `reverbPort` in `api_constants.dart`
- Check firewall settings
- Try using IP address instead of `localhost` on physical device

### Notifications not received:
- Check if FCM token is generated
- Verify Firebase configuration
- Check notification permissions
- Test with Firebase Console first
- Check backend FCM credentials

### Driver location not updating:
- Verify WebSocket connection
- Check if driver is updating location via API
- Verify order channel subscription
- Check Laravel logs for broadcast events

---

## 📝 Notes

- WebSocket works best on physical devices, not emulators
- iOS requires physical device for push notifications
- Reverb server must be accessible from the device (use ngrok for local testing)
- FCM has rate limits - don't spam notifications
- Always test on both Android and iOS

---

## 🔗 Useful Links

- [Laravel Reverb Docs](https://laravel.com/docs/11.x/reverb)
- [Pusher Channels Flutter](https://pub.dev/packages/pusher_channels_flutter)
- [Firebase Messaging](https://firebase.google.com/docs/cloud-messaging)
- [FlutterFire](https://firebase.flutter.dev/)
