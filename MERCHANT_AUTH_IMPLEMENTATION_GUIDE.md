# Merchant Authentication - Complete Implementation Guide

## 🔴 Current Status: BROKEN

The merchant authentication is not working. Users can see the merchant UI but cannot perform authenticated actions like creating menu items.

## 📊 What We Know

### ✅ Working:
1. **Backend API** - Login endpoint returns correct response with token and partner_id
2. **Menu Loading** - App can load menu items (public endpoint)
3. **Profile Loading** - App can load partner profile (public endpoint)
4. **Backend Menu Item Creation** - API endpoint works when called with valid token

### ❌ Not Working:
1. **Token Persistence** - Token is not being saved after login
2. **Authenticated Requests** - All authenticated endpoints return "Unauthenticated"
3. **Login Flow** - No login logs appear in console, suggesting login might not be triggering

## 🔍 Root Cause Analysis

The issue is that **the authentication token is not being saved to SharedPreferences** after login. This could be due to:

1. **Login not being called** - The login button might not be connected to the auth provider
2. **Login failing silently** - An error might be occurring but not being shown
3. **Token not being saved** - The `saveToken()` method might be failing
4. **Wrong auth flow** - The merchant might be using a different login mechanism

## 🎯 Required Implementation

### Step 1: Verify Login Button Connection

Check `RIDERSIDE/lib/presentation/widgets/auth/rider_login_content.dart` or the merchant login screen to ensure the login button calls:

```dart
await ref.read(riderAuthProvider.notifier).login(email, password);
```

### Step 2: Add Error Handling to Login Screen

The login screen should show errors if login fails:

```dart
ref.listen(riderAuthProvider, (previous, next) {
  if (next.error != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(next.error!)),
    );
  }
});
```

### Step 3: Verify SharedPreferences Initialization

Ensure SharedPreferences is properly initialized in `main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferences.getInstance(); // Ensure it's initialized
  runApp(MyApp());
}
```

### Step 4: Test Token Persistence

Add a test button to manually save and retrieve a token:

```dart
// Test save
await ApiService.saveToken('test_token_123');

// Test retrieve
final token = await ApiService.getToken();
print('Retrieved token: $token');
```

### Step 5: Check for Platform-Specific Issues

On Android, ensure the app has proper permissions in `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

## 🚀 Temporary Workaround (For Testing Only)

To test if the menu item creation works, you can temporarily hardcode a valid token:

### Get a Fresh Token:

```powershell
$response = Invoke-RestMethod -Uri 'http://localhost:8000/api/v1/auth/login' -Method Post -Body (@{email='merchant@test.com';password='password123'} | ConvertTo-Json) -ContentType 'application/json'
$response.token
```

### Hardcode in ApiService:

```dart
static Future<String?> getToken() async {
  // TEMPORARY - Replace with actual token from above
  return 'YOUR_TOKEN_HERE';
}
```

This will allow you to test menu item creation while the auth issue is being fixed.

## 📝 Debugging Steps

### 1. Check if Login is Being Called

Add this at the start of the `login()` method in `rider_auth_provider.dart`:

```dart
Future<bool> login(String email, String password) async {
  print('🔐🔐🔐 LOGIN METHOD CALLED - Email: $email');
  // ... rest of code
}
```

If you don't see this log when clicking login, the button is not connected.

### 2. Check for Exceptions

Wrap the entire login method in a try-catch:

```dart
try {
  // ... login code
} catch (e, stackTrace) {
  print('❌❌❌ LOGIN EXCEPTION: $e');
  print('Stack trace: $stackTrace');
  // ... error handling
}
```

### 3. Check SharedPreferences

Test if SharedPreferences works at all:

```dart
final prefs = await SharedPreferences.getInstance();
await prefs.setString('test_key', 'test_value');
final value = prefs.getString('test_key');
print('SharedPreferences test: $value'); // Should print 'test_value'
```

### 4. Check API Response

Log the raw response from the login API:

```dart
final response = await _dio.post('/v1/auth/login', data: {
  'email': email,
  'password': password,
});
print('🔐 Raw API response: ${response.data}');
print('🔐 Status code: ${response.statusCode}');
```

## 🎯 Expected Behavior

After proper implementation:

1. User enters email/password and clicks login
2. App calls `riderAuthProvider.login()`
3. Login method calls backend API
4. Backend returns `{success: true, token: "...", user: {..., partner_id: 11}}`
5. App saves token to SharedPreferences
6. App updates auth state with user data
7. App navigates to merchant dashboard
8. All subsequent API calls include `Authorization: Bearer {token}` header
9. Menu item creation works

## 🔧 Files to Check

1. **Login Screen** - Where is the login button? Is it calling the auth provider?
2. **Auth Provider** - `rider_auth_provider.dart` - Is login method being called?
3. **API Service** - `api_service.dart` - Is saveToken working?
4. **Main.dart** - Is SharedPreferences initialized?
5. **Navigation** - Does the app navigate after successful login?

## ⚠️ Important Notes

- The backend API is **100% working** - verified with curl/Postman
- The menu item creation endpoint is **100% working** - verified with valid token
- The issue is **purely on the Flutter side** - token management
- This requires a **Flutter developer** to debug properly with access to the running app

## 📊 Success Criteria

Authentication is fixed when:

1. ✅ User can login with merchant@test.com / password123
2. ✅ Token is saved to SharedPreferences
3. ✅ Token persists after app restart
4. ✅ All API calls include Authorization header
5. ✅ Menu item creation works without "Unauthenticated" error
6. ✅ Orders load without "Unauthenticated" error

---

**Status**: Requires Flutter developer to debug authentication flow
**Priority**: HIGH - Blocking all authenticated merchant features
**Estimated Time**: 1-2 hours for experienced Flutter developer
