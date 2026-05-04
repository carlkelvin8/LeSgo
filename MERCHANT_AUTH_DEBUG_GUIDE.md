# Merchant Authentication Debug Guide

## Current Status

✅ **App is running with comprehensive logging enabled**

The Flutter app has been restarted with detailed logging that will show us exactly what's happening during the login process.

## What I've Done

### 1. Enhanced Logging in Multiple Files

#### `main.dart`
- Added SharedPreferences initialization check on app startup
- Logs whether a token exists when app starts

#### `rider_login_content.dart` (Login UI)
- Added logging when login button is pressed
- Shows form validation status
- Displays login success/failure

#### `rider_auth_provider.dart` (Auth Logic)
- Comprehensive logging throughout the login method
- Shows token extraction and saving process
- Verifies token was actually saved to SharedPreferences
- Displays user role and partner_id

#### `api_service.dart` (Network Layer)
- Logs all API requests with their paths
- Shows whether Authorization header is being set
- Displays API response status and data
- Shows errors with full details

### 2. What the Logs Will Show

When you login, you'll see logs like this in the terminal:

```
🔐 LOGIN BUTTON PRESSED
🔐 Attempting login with email: merchant@test.com
🔐🔐🔐 LOGIN METHOD CALLED 🔐🔐🔐
🌐 API: Calling POST /v1/auth/login
🔒 Interceptor: Making request to /v1/auth/login
🔒 Interceptor: Token available: false
🌐 API: Login response status: 200
🔐 Token extracted: eyJ0eXBiOiJKV1QiLCJ...
🔐 Parsed user - ID: 930, Role: partner, Partner ID: 11
🔐 Calling ApiService.saveToken...
🔐 Token saved successfully
🔐 Token verification: SUCCESS
✅✅✅ LOGIN SUCCESSFUL ✅✅✅
```

## Next Steps - PLEASE DO THIS

### Step 1: Clear App Data (IMPORTANT!)
Before logging in, clear the app data to ensure a fresh start:

**In the Android Emulator:**
1. Long press the app icon
2. Tap "App info"
3. Tap "Storage"
4. Tap "Clear storage" or "Clear data"
5. Confirm

**OR restart the app from the terminal:**
- The app is already running in terminal 29

### Step 2: Login
1. Open the app in the emulator
2. Navigate to the merchant login screen
3. Enter credentials:
   - Email: `merchant@test.com`
   - Password: `password123`
4. Click "Log In"

### Step 3: Watch the Terminal
Look at the terminal output (terminal 29) and tell me:
- Do you see the "🔐 LOGIN BUTTON PRESSED" message?
- Do you see "✅✅✅ LOGIN SUCCESSFUL ✅✅✅"?
- Do you see "Token verification: SUCCESS"?
- Are there any error messages?

### Step 4: Try Adding a Menu Item
After successful login:
1. Go to the merchant menu section
2. Try to add a new menu item
3. Watch the terminal for:
   - "🔒 Interceptor: Token available: true"
   - "🔒 Interceptor: Authorization header set"

## Expected Behavior

### If Login Works:
- You'll see all the success messages
- Token will be saved to SharedPreferences
- All subsequent API calls will include the Authorization header
- Adding menu items will work

### If Login Fails:
- The logs will show exactly where it fails:
  - Network error?
  - Invalid credentials?
  - Token not being saved?
  - SharedPreferences not working?

## Test Credentials

- **Email**: merchant@test.com
- **Password**: password123
- **Partner ID**: 11 (Test Restaurant)
- **User ID**: 930

## Backend Status

✅ Backend is running on port 8000 (terminal 7)
✅ Android emulator is running (terminal 18)
✅ Flutter app is running with debug logging (terminal 29)

## What to Report

Please tell me:
1. **Did you clear app data before logging in?**
2. **What logs do you see in the terminal when you click login?**
3. **Does the login succeed or fail?**
4. **If you try to add a menu item, what error do you get?**
5. **Copy and paste the relevant log output from the terminal**

## Common Issues and Solutions

### Issue: "Unauthenticated" error when adding menu items
**Cause**: Token not being sent with API requests
**Solution**: The logs will show if token is available in the interceptor

### Issue: Login succeeds but token not saved
**Cause**: SharedPreferences not initialized or permission issue
**Solution**: The logs will show "Token verification: FAILED"

### Issue: Login button doesn't do anything
**Cause**: Form validation failing or button not connected
**Solution**: The logs will show "Form validation failed"

## Architecture Overview

```
Login Flow:
1. User enters credentials in rider_login_content.dart
2. Calls riderAuthProvider.login()
3. Calls ApiService.login() → POST /v1/auth/login
4. Backend returns token + user data
5. ApiService.saveToken() → Saves to SharedPreferences
6. State updated with user info

API Request Flow:
1. Any API call goes through Dio interceptor
2. Interceptor calls ApiService.getToken()
3. If token exists, adds "Authorization: Bearer {token}" header
4. Request sent to backend
5. Backend validates token and processes request
```

## Files Modified

- `RIDERSIDE/lib/main.dart` - Added SharedPreferences initialization
- `RIDERSIDE/lib/presentation/widgets/auth/rider_login_content.dart` - Added login logging
- `RIDERSIDE/lib/presentation/provider/auth/rider_auth_provider.dart` - Added comprehensive auth logging
- `RIDERSIDE/lib/core/services/api_service.dart` - Added API and interceptor logging

---

**The app is ready for testing. Please follow the steps above and report what you see in the terminal!**
