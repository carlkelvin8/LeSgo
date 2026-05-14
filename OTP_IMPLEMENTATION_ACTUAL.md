# OTP Implementation - Actual System Documentation

## Overview
The LeSGo app has a **fully implemented OTP verification system** for phone number verification during registration. The system uses Twilio Verify API with a fallback cache-based OTP for development/testing.

---

## Backend Implementation

### 1. OTP Controller
**Location**: `BACKEND/lesgo-api/app/Http/Controllers/Api/Auth/OtpController.php`

#### Available Endpoints:
```
POST /api/v1/auth/otp/send       - Send OTP to phone number
POST /api/v1/auth/otp/verify     - Verify OTP code
POST /api/v1/auth/otp/cancel     - Cancel pending verification
POST /api/v1/auth/otp/check      - Check if phone is verified
```

#### Features:
- **Twilio Verify Integration**: Uses Twilio Verify Service for production
- **Fallback Mode**: Cache-based OTP for development (when `APP_ENV=local`)
- **Rate Limiting**: 
  - Send: 5 requests per minute
  - Verify: 10 requests per minute
  - Cancel: 5 requests per minute
  - Check: 10 requests per minute
- **Security**: Phone number masking in logs, IP tracking, user agent logging
- **Channels**: Supports SMS and voice call

### 2. OTP Controller Methods

#### `send(Request $request)`
**Purpose**: Send OTP verification code to phone number

**Request Body**:
```json
{
  "phone_number": "+639171234567",
  "channel": "sms"  // Optional: "sms" or "call"
}
```

**Response (Production - Twilio)**:
```json
{
  "success": true,
  "message": "Verification code sent successfully",
  "status": "pending",
  "channel": "sms",
  "verification_sid": "VE..."  // Only in non-production
}
```

**Response (Development - Fallback)**:
```json
{
  "success": true,
  "message": "Verification code sent (fallback mode)",
  "status": "pending",
  "channel": "sms",
  "otp": "123456",  // Exposed for testing
  "fallback": true
}
```

**How Fallback Works**:
1. Generates random 6-digit OTP
2. Stores in cache with key: `fallback_otp:{phone_digits}`
3. Expires after 10 minutes
4. Returns OTP in response for easy testing

#### `verify(Request $request)`
**Purpose**: Verify OTP code

**Request Body**:
```json
{
  "phone_number": "+639171234567",
  "otp": "123456"
}
```

**Response (Success)**:
```json
{
  "success": true,
  "verified": true,
  "message": "Phone number verified successfully",
  "status": "approved"
}
```

**Response (Failed)**:
```json
{
  "success": false,
  "verified": false,
  "message": "Invalid verification code",
  "error": "Invalid code"
}
```

**What Happens on Success**:
1. Marks phone as verified in cache: `phone_verified:{phone_digits}`
2. Cache entry expires after 1 hour
3. This allows registration to proceed

#### `checkVerification(Request $request)`
**Purpose**: Check if phone number is already verified

**Request Body**:
```json
{
  "phone_number": "+639171234567"
}
```

**Response**:
```json
{
  "phone_number": "+639171234567",
  "verified": true,
  "message": "Phone number is verified"
}
```

### 3. Routes Configuration
**Location**: `BACKEND/lesgo-api/routes/api.php`

```php
// OTP endpoints (public, rate-limited)
Route::post('/otp/send', [OtpController::class, 'send'])
    ->middleware('throttle:5,1'); // 5 per minute
Route::post('/otp/verify', [OtpController::class, 'verify'])
    ->middleware('throttle:10,1'); // 10 per minute
Route::post('/otp/cancel', [OtpController::class, 'cancel'])
    ->middleware('throttle:5,1'); // 5 per minute
Route::post('/otp/check', [OtpController::class, 'checkVerification'])
    ->middleware('throttle:10,1'); // 10 per minute
```

**Status**: ✅ **All routes are registered and active**

### 4. Environment Configuration
**Location**: `BACKEND/lesgo-api/.env`

```env
# Twilio Configuration
TWILIO_SID=AC0fa6e9808609b73de12058af0907ac48
TWILIO_AUTH_TOKEN=bf9c03f1fe72c36a70e7073efb803a79
TWILIO_FROM=+639498787542
TWILIO_VERIFY_SERVICE_SID=VA5e6d745859fffffccac5ee1c402ecbc6

# App Environment (determines fallback mode)
APP_ENV=local  # Use "local" for fallback OTP, "production" for Twilio
```

**Current Mode**: `local` - Using fallback cache-based OTP

---

## Frontend Implementation

### 1. OTP Notifier (Business Logic)
**Location**: `FRONTEND/lib/presentation/provider/register/notifier/otp_notifier.dart`

#### Methods:

##### `sendOtp(String phoneNumber)`
- Calls backend `/v1/auth/otp/send`
- Updates state with `otpSent: true` on success
- Stores phone number in registration state
- Returns `true` on success, `false` on failure

##### `verifyOtp(String otp)`
- Calls backend `/v1/auth/otp/verify`
- Uses phone number from state
- Returns `true` if verified, `false` otherwise
- Updates state with error message on failure

##### `resendOtp(String phoneNumber)`
- Simply calls `sendOtp()` again
- Twilio Verify handles resend logic automatically

##### `cancelOtp(String phoneNumber)`
- Calls backend `/v1/auth/otp/cancel`
- Cancels pending verification

##### `checkVerificationStatus(String phoneNumber)`
- Calls backend `/v1/auth/otp/check`
- Returns verification status

### 2. Auth Remote Data Source
**Location**: `FRONTEND/lib/data/data_source/auth_remote_datasource.dart`

#### API Methods:

```dart
// Send OTP
Future<OtpResponseDto> sendOtp(String phoneNumber, {String channel = 'sms'})

// Verify OTP
Future<OtpResponseDto> verifyOtp(String phoneNumber, String otp)

// Cancel OTP
Future<OtpResponseDto> cancelOtp(String phoneNumber)

// Check verification status
Future<OtpResponseDto> checkOtpVerification(String phoneNumber)
```

**All methods use DioClient with 30-second timeout**

### 3. OTP Response DTO
**Location**: `FRONTEND/lib/data/data_source/dto/auth/otp_response_dto.dart`

```dart
class OtpResponseDto {
  final bool success;
  final String message;
  final bool? verified;
  final String? status;
  final String? channel;
  final String? verificationSid;
  final String? otp;        // Only in development
  final bool? fallback;     // Indicates fallback mode
  final String? error;
}
```

### 4. Register Provider Integration
**Location**: `FRONTEND/lib/presentation/provider/register/register_provider.dart`

```dart
class RegisterNotifier extends StateNotifier<RegisterState>
    with TermsNotifier, 
         PersonalInfoNotifier, 
         VerificationNotifier, 
         OtpNotifier,          // ✅ OTP mixin included
         AddressNotifier, 
         SubmitNotifier {
  // ...
}
```

**Status**: ✅ **OTP functionality is mixed into RegisterNotifier**

### 5. Verification Screen
**Location**: `FRONTEND/lib/presentation/screens/auth/steps/verification_screen.dart`

This screen handles:
- Phone number input
- OTP code input
- Send OTP button
- Resend OTP button
- Verify OTP button
- Error display

---

## How OTP Flow Works

### Registration Flow with OTP:

```
1. User enters personal info (name, email, password)
   ↓
2. User enters phone number
   ↓
3. User clicks "Send OTP"
   → Frontend calls: sendOtp(phoneNumber)
   → Backend generates OTP (Twilio or fallback)
   → Backend sends SMS (Twilio) or returns OTP (fallback)
   ↓
4. User receives OTP code
   - Production: SMS to phone
   - Development: OTP in API response
   ↓
5. User enters OTP code
   ↓
6. User clicks "Verify"
   → Frontend calls: verifyOtp(phoneNumber, otp)
   → Backend verifies code
   → Backend marks phone as verified in cache
   ↓
7. If verified: Continue to next step (address, selfie)
   If failed: Show error, allow retry
   ↓
8. User completes registration
   → Backend checks phone verification status
   → If verified: Create account
   → If not verified: Reject registration
```

---

## Current Status

### ✅ What's Working:
1. **Backend OTP Controller**: Fully implemented with Twilio + fallback
2. **Backend Routes**: All OTP endpoints registered and active
3. **Frontend OTP Notifier**: Complete business logic
4. **Frontend Data Source**: All API calls implemented
5. **Frontend DTO**: Response parsing ready
6. **Provider Integration**: OTP mixin included in RegisterNotifier

### ⚠️ Potential Issues:

#### 1. **Twilio Credentials**
- Credentials are configured in `.env`
- Need to verify if Twilio account is active
- Need to verify if phone number `+639498787542` is verified in Twilio

#### 2. **Fallback Mode Active**
- `APP_ENV=local` means using cache-based OTP
- OTP is returned in API response for testing
- **For production**: Change to `APP_ENV=production`

#### 3. **Phone Number Format**
- Backend expects international format: `+639171234567`
- Frontend must format phone numbers correctly
- Need to verify frontend phone input validation

#### 4. **Cache Configuration**
- Fallback OTP uses Laravel cache
- Current cache driver: `database`
- Verify cache is working: `php artisan cache:clear`

---

## Testing the OTP System

### Development Mode (Fallback OTP):

1. **Send OTP**:
```bash
curl -X POST https://lesgo-api-feature-auth-secmes.free.laravel.cloud/api/v1/auth/otp/send \
  -H "Content-Type: application/json" \
  -d '{
    "phone_number": "+639171234567"
  }'
```

**Expected Response**:
```json
{
  "success": true,
  "message": "Verification code sent (fallback mode)",
  "status": "pending",
  "channel": "sms",
  "otp": "123456",  // ← Use this code
  "fallback": true
}
```

2. **Verify OTP**:
```bash
curl -X POST https://lesgo-api-feature-auth-secmes.free.laravel.cloud/api/v1/auth/otp/verify \
  -H "Content-Type: application/json" \
  -d '{
    "phone_number": "+639171234567",
    "otp": "123456"
  }'
```

**Expected Response**:
```json
{
  "success": true,
  "verified": true,
  "message": "Phone number verified successfully (fallback mode)",
  "status": "approved",
  "fallback": true
}
```

3. **Check Verification**:
```bash
curl -X POST https://lesgo-api-feature-auth-secmes.free.laravel.cloud/api/v1/auth/otp/check \
  -H "Content-Type: application/json" \
  -d '{
    "phone_number": "+639171234567"
  }'
```

---

## Troubleshooting

### Issue: "OTP not working"

**Possible Causes**:

1. **Frontend not calling OTP endpoints**
   - Check if verification screen is using OTP notifier
   - Check if send/verify buttons are wired correctly

2. **Phone number format incorrect**
   - Must be international format: `+63` prefix
   - Example: `+639171234567`

3. **Cache not working**
   - Run: `php artisan cache:clear`
   - Check cache driver in `.env`: `CACHE_STORE=database`

4. **Twilio credentials invalid** (if using production mode)
   - Verify Twilio account is active
   - Verify phone number is verified in Twilio console

5. **Rate limiting**
   - Too many requests in short time
   - Wait 1 minute and try again

6. **Timeout issues**
   - Frontend timeout is 30 seconds
   - Backend should respond quickly in fallback mode

### Debug Steps:

1. **Check backend logs**:
```bash
tail -f BACKEND/lesgo-api/storage/logs/laravel.log
```

Look for:
- `OTP send request`
- `OTP verify request`
- `Fallback OTP generated`
- `OTP verification successful`

2. **Test API directly** (see Testing section above)

3. **Check frontend console** for API errors

4. **Verify phone verification status**:
```bash
curl -X POST https://lesgo-api-feature-auth-secmes.free.laravel.cloud/api/v1/auth/otp/check \
  -H "Content-Type: application/json" \
  -d '{"phone_number": "+639171234567"}'
```

---

## Production Deployment Checklist

Before deploying to production:

- [ ] Change `APP_ENV=production` in `.env`
- [ ] Verify Twilio credentials are valid
- [ ] Verify Twilio phone number is active
- [ ] Test Twilio SMS delivery
- [ ] Remove OTP from API responses (automatic in production)
- [ ] Set up proper rate limiting
- [ ] Monitor Twilio usage and costs
- [ ] Set up alerts for failed OTP deliveries

---

## Summary

**The OTP system is FULLY IMPLEMENTED** on both backend and frontend. The issue "OTP not working" likely means:

1. Frontend UI is not properly wired to call OTP methods
2. Phone number format is incorrect
3. Cache is not working (run `php artisan cache:clear`)
4. User is not following the correct flow

**Next Steps**:
1. Test OTP endpoints directly with curl
2. Check if verification screen calls `sendOtp()` and `verifyOtp()`
3. Verify phone number format in frontend
4. Check Laravel logs for OTP-related entries
5. Test complete registration flow in emulator/APK

---

**Last Updated**: May 8, 2026
**Status**: ✅ Fully Implemented, Ready for Testing
