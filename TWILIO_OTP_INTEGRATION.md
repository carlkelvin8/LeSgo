# Twilio OTP Integration for Customer Registration

## Overview

This document describes the integration of Twilio Verify API for OTP (One-Time Password) verification during customer registration in the LeSGo application.

## Features Implemented

### Backend Integration

1. **TwilioVerifyService** - New service class for handling Twilio Verify API
   - Send verification codes via SMS or voice
   - Verify OTP codes
   - Cancel pending verifications
   - Proper error handling and logging

2. **Updated OtpController** - Enhanced to use Twilio Verify API
   - Primary: Twilio Verify API for production
   - Fallback: Cache-based OTP for development/testing
   - Rate limiting and security measures

3. **Configuration** - Added Twilio Verify Service SID
   - `TWILIO_VERIFY_SERVICE_SID=VA5e6d745859fffffccac5ee1c402ecbc6`

### Frontend Integration

1. **AuthRemoteDataSource** - New data source for authentication APIs
   - Send OTP requests
   - Verify OTP codes
   - Cancel OTP requests
   - Check verification status

2. **Updated OtpNotifier** - Enhanced to use real API calls
   - Proper error handling
   - Integration with Twilio backend

3. **OTP Response DTOs** - Type-safe API responses
   - Success/failure status
   - Verification status
   - Error messages

## API Endpoints

### Send OTP
```
POST /api/v1/auth/otp/send
Content-Type: application/json

{
  "phone_number": "+639171234567",
  "channel": "sms" // optional: "sms" or "call"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Verification code sent to +63917***4567",
  "status": "pending",
  "channel": "sms",
  "verification_sid": "VE..." // only in development
}
```

### Verify OTP
```
POST /api/v1/auth/otp/verify
Content-Type: application/json

{
  "phone_number": "+639171234567",
  "otp": "123456"
}
```

**Response:**
```json
{
  "success": true,
  "verified": true,
  "message": "Phone number verified successfully",
  "status": "approved"
}
```

### Cancel OTP
```
POST /api/v1/auth/otp/cancel
Content-Type: application/json

{
  "phone_number": "+639171234567"
}
```

### Check Verification Status
```
POST /api/v1/auth/otp/check
Content-Type: application/json

{
  "phone_number": "+639171234567"
}
```

## Configuration

### Backend (.env)
```env
# Twilio Configuration
TWILIO_SID=your_twilio_account_sid
TWILIO_AUTH_TOKEN=your_twilio_auth_token
TWILIO_FROM=your_twilio_phone_number
TWILIO_VERIFY_SERVICE_SID=VA5e6d745859fffffccac5ee1c402ecbc6
```

### Twilio Verify Service
The Verify Service SID `VA5e6d745859fffffccac5ee1c402ecbc6` is configured in:
- `config/services.php`
- `.env` file
- `TwilioVerifyService` class

## Security Features

1. **Rate Limiting**
   - Send OTP: 5 requests per minute
   - Verify OTP: 10 requests per minute
   - Cancel OTP: 5 requests per minute

2. **Phone Number Normalization**
   - Converts Philippine numbers (09XXXXXXXXX → +639XXXXXXXXX)
   - Handles international format
   - Validates E.164 format

3. **Logging & Monitoring**
   - Comprehensive logging for debugging
   - Masked phone numbers in logs
   - Error tracking and monitoring

4. **Fallback System**
   - Production: Twilio Verify API
   - Development: Cache-based OTP for testing
   - Graceful error handling

## Testing

### Backend Test Script
Run the test script to verify Twilio integration:
```bash
cd BACKEND/lesgo-api
php test_twilio_otp.php
```

### Frontend Testing
1. Navigate to registration flow
2. Enter phone number
3. Request OTP
4. Enter received code
5. Verify successful verification

## Error Handling

### Common Errors
1. **Invalid Phone Number**
   - Validation on both frontend and backend
   - Clear error messages

2. **Rate Limiting**
   - Proper HTTP status codes
   - Retry-after headers

3. **Twilio API Errors**
   - Network issues
   - Invalid credentials
   - Service unavailable

4. **Expired/Invalid OTP**
   - Clear error messages
   - Option to resend

## Integration Flow

1. **User Registration**
   ```
   User enters phone → Send OTP → User enters code → Verify → Continue registration
   ```

2. **OTP Verification Process**
   ```
   Frontend → AuthRemoteDataSource → Backend API → TwilioVerifyService → Twilio API
   ```

3. **Verification Status**
   ```
   Twilio Response → Backend Processing → Frontend Update → UI State Change
   ```

## Benefits

1. **Reliability** - Twilio's global SMS infrastructure
2. **Security** - Industry-standard OTP verification
3. **Scalability** - Handles high volume of verifications
4. **Compliance** - Meets regulatory requirements
5. **User Experience** - Fast and reliable delivery

## Next Steps

1. **Production Setup**
   - Configure Twilio credentials
   - Set up monitoring and alerts
   - Test with real phone numbers

2. **Enhanced Features**
   - Voice call fallback
   - Multiple language support
   - Custom message templates

3. **Analytics**
   - Track verification success rates
   - Monitor delivery times
   - Analyze failure patterns

## Support

For issues or questions:
1. Check Twilio console for delivery status
2. Review application logs
3. Test with the provided test script
4. Verify configuration settings