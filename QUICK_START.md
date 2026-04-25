# 🚀 Quick Start Guide - LeSGo Real-time Features

## ✅ What's Complete

All code is written and ready! You just need to set up Firebase and start the services.

---

## 📋 Prerequisites

- Flutter SDK installed
- Firebase account
- Laravel backend running
- Physical device for testing (notifications don't work well on emulators)

---

## ⚡ Quick Setup (30 minutes)

### Step 1: Firebase Setup (15 minutes)

1. **Create Firebase Project**
   - Go to https://console.firebase.google.com/
   - Click "Add project"
   - Enter project name: "LeSGo"
   - Disable Google Analytics (optional)
   - Click "Create project"

2. **Add Android App**
   - Click "Add app" → Android icon
   - Package name: `com.lesgo.app`
   - App nickname: "LeSGo Android"
   - Click "Register app"
   - Download `google-services.json`
   - Place in `FRONTEND/android/app/`

3. **Add iOS App** (if needed)
   - Click "Add app" → iOS icon
   - Bundle ID: `com.lesgo.app`
   - App nickname: "LeSGo iOS"
   - Click "Register app"
   - Download `GoogleService-Info.plist`
   - Place in `FRONTEND/ios/Runner/`

4. **Configure Flutter**
   ```bash
   # Install FlutterFire CLI
   dart pub global activate flutterfire_cli
   
   # Configure Firebase
   cd FRONTEND
   flutterfire configure
   ```

5. **Download Firebase Admin SDK Credentials**
   - In Firebase Console → Project Settings → Service Accounts
   - Click "Generate new private key"
   - Save as `BACKEND/lesgo-api/storage/app/firebase-credentials.json`

### Step 2: Update Frontend (5 minutes)

**Edit `FRONTEND/lib/main.dart`:**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/constants/routers/app_router.dart';
import 'core/constants/routers/auth/auth_routes.dart';
import 'core/di/injection.dart';
import 'core/services/app_notification_handler.dart';

// Global navigator key for notifications
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
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
  
  runApp(const ProviderScope(child: LesgoApp()));
}

class LesgoApp extends StatelessWidget {
  const LesgoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lezgo',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey, // Important!
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: LoginRoutes.login,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
```

### Step 3: Update Backend (10 minutes)

1. **Install Firebase Admin SDK**
   ```bash
   cd BACKEND/lesgo-api
   composer require kreait/firebase-php
   ```

2. **Add Migration**
   ```bash
   php artisan make:migration add_fcm_token_to_users_table
   ```

   **Edit the migration:**
   ```php
   public function up()
   {
       Schema::table('users', function (Blueprint $table) {
           $table->string('fcm_token')->nullable()->after('remember_token');
       });
   }
   ```

   ```bash
   php artisan migrate
   ```

3. **Add FCM Token Endpoint**
   
   **In `routes/api.php`:**
   ```php
   Route::post('/v1/auth/fcm-token', [AuthController::class, 'updateFcmToken'])
       ->middleware('auth:sanctum');
   ```

   **In `app/Http/Controllers/Api/AuthController.php`:**
   ```php
   public function updateFcmToken(Request $request)
   {
       $request->validate([
           'fcm_token' => 'required|string',
       ]);

       $user = $request->user();
       $user->fcm_token = $request->fcm_token;
       $user->save();

       return response()->json([
           'success' => true,
           'message' => 'FCM token updated successfully',
       ]);
   }
   ```

4. **Create NotificationService**
   
   Copy from `BACKEND/lesgo-api/NOTIFICATION_BACKEND_GUIDE.md` Step 6

---

## 🎮 Run the App

### Terminal 1: Start Laravel Reverb
```bash
cd BACKEND/lesgo-api
php artisan reverb:start
```

### Terminal 2: Start Laravel Server
```bash
cd BACKEND/lesgo-api
php artisan serve
```

### Terminal 3: Run Flutter App
```bash
cd FRONTEND
flutter run
```

---

## 🧪 Test It!

### Test 1: Real-time Tracking
1. Create an order
2. Assign a driver
3. Update driver location:
   ```bash
   curl -X POST http://localhost:8000/api/v1/tracking/driver/location \
     -H "Authorization: Bearer DRIVER_TOKEN" \
     -d '{"latitude": 14.5995, "longitude": 120.9842}'
   ```
4. Watch the map update instantly!

### Test 2: Push Notifications
1. Send test from Firebase Console:
   - Go to Cloud Messaging
   - Click "Send test message"
   - Enter FCM token (check app logs)
   - Add custom data:
     ```json
     {
       "type": "order_accepted",
       "order_id": "123"
     }
     ```
   - Send
2. Watch the banner appear!

### Test 3: Wallet Top-Up
1. Open LesPay screen
2. Tap "Top up"
3. Enter amount: 500
4. Complete payment
5. Balance updates!

---

## 📚 Full Documentation

- **Setup Guide:** `FRONTEND/REALTIME_SETUP_GUIDE.md`
- **Notification Guide:** `FRONTEND/NOTIFICATION_INTEGRATION_COMPLETE.md`
- **Backend Guide:** `BACKEND/lesgo-api/NOTIFICATION_BACKEND_GUIDE.md`
- **Complete Summary:** `IMPLEMENTATION_COMPLETE_SUMMARY.md`

---

## ❓ Troubleshooting

### WebSocket not connecting?
- Check if Reverb is running: `php artisan reverb:start`
- Check `reverbHost` in `api_constants.dart` (use IP address, not localhost on device)

### Notifications not working?
- Test on physical device (not emulator)
- Check FCM token in app logs
- Verify Firebase credentials

### Build errors?
- Run `flutter clean && flutter pub get`
- Run `flutter pub run build_runner build --delete-conflicting-outputs`

---

## 🎉 You're Done!

All features are now working:
- ✅ Real-time driver tracking
- ✅ Push notifications
- ✅ Order status updates
- ✅ Driver assigned alerts
- ✅ Wallet top-up

**Ready to launch!** 🚀
