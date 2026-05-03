# Forgot Password Implementation - Email OTP

## ✅ Complete Implementation

Naimplementa na ang complete **Forgot Password** system gamit ang **Email OTP**!

---

## 🎯 Features

### Backend Features
✅ **Email OTP System**
- 6-digit OTP code
- 10 minutes expiry
- Secure token generation
- Rate limiting protection

✅ **Security Features**
- Rate limiting (3 attempts per 5 minutes)
- OTP expiration (10 minutes)
- One-time use OTP
- IP address logging
- Automatic token revocation on password change

✅ **Email Template**
- Professional HTML email design
- Clear OTP display
- Security warnings
- Expiry information

### Frontend Features
✅ **3-Step Process**
1. **Enter Email** - User enters their email
2. **Verify OTP** - User enters 6-digit code from email
3. **Reset Password** - User creates new password

✅ **User Experience**
- Clean, intuitive UI
- Loading states
- Error handling
- Success messages
- Resend OTP option
- Password visibility toggle

---

## 📁 Files Created/Modified

### Backend Files

#### New Files:
1. **`BACKEND/lesgo-api/database/migrations/2026_04_29_000000_create_password_resets_table.php`**
   - Database table for storing OTP codes
   - Tracks email, OTP, expiry, usage status

2. **`BACKEND/lesgo-api/app/Models/PasswordReset.php`**
   - Model for password reset records
   - Helper methods: `isExpired()`, `isValid()`, `markAsUsed()`

3. **`BACKEND/lesgo-api/app/Mail/PasswordResetOtpMail.php`**
   - Mailable class for sending OTP emails

4. **`BACKEND/lesgo-api/resources/views/emails/password-reset-otp.blade.php`**
   - Beautiful HTML email template
   - Shows OTP code prominently
   - Includes security warnings

5. **`BACKEND/lesgo-api/app/Http/Controllers/Api/Auth/ForgotPasswordController.php`**
   - Handles all forgot password logic
   - Methods: `sendOtp()`, `verifyOtp()`, `resetPassword()`, `resendOtp()`

#### Modified Files:
6. **`BACKEND/lesgo-api/routes/api.php`**
   - Added 4 new routes:
     - `POST /v1/auth/forgot-password/send-otp`
     - `POST /v1/auth/forgot-password/verify-otp`
     - `POST /v1/auth/forgot-password/reset`
     - `POST /v1/auth/forgot-password/resend-otp`

### Frontend Files

#### New Files:
1. **`FRONTEND/lib/presentation/screens/auth/forgot_password_screen.dart`**
   - Complete UI for 3-step password reset
   - Form validation
   - State management integration

2. **`FRONTEND/lib/presentation/provider/auth/forgot_password_provider.dart`**
   - State management for forgot password flow
   - Handles API calls
   - Manages step transitions

#### Modified Files:
3. **`FRONTEND/lib/data/data_source/auth_remote_datasource.dart`**
   - Added 4 new methods:
     - `sendPasswordResetOtp()`
     - `resendPasswordResetOtp()`
     - `verifyPasswordResetOtp()`
     - `resetPassword()`

4. **`FRONTEND/lib/presentation/screens/auth/login_screen.dart`**
   - Connected "Forgot Password?" button
   - Navigates to ForgotPasswordScreen

---

## 🔄 User Flow

### Step 1: Enter Email
```
User taps "Forgot Password?" on login screen
  ↓
Opens Forgot Password screen
  ↓
User enters email address
  ↓
Taps "Send OTP"
  ↓
Backend generates 6-digit OTP
  ↓
Email sent to user
  ↓
Moves to Step 2
```

### Step 2: Verify OTP
```
User receives email with OTP
  ↓
User enters 6-digit code
  ↓
Taps "Verify OTP"
  ↓
Backend validates OTP
  ↓
If valid, moves to Step 3
  ↓
If invalid, shows error
  ↓
User can tap "Resend" if needed
```

### Step 3: Reset Password
```
User enters new password
  ↓
User confirms new password
  ↓
Taps "Reset Password"
  ↓
Backend updates password
  ↓
All existing tokens revoked (security)
  ↓
Success! Returns to login screen
  ↓
User logs in with new password
```

---

## 🔐 Security Features

### Rate Limiting
- **Send OTP**: 3 attempts per 5 minutes per email
- **Verify OTP**: 10 attempts per minute
- **Reset Password**: 5 attempts per minute
- **Resend OTP**: 2 attempts per 10 minutes

### OTP Security
- ✅ 6-digit random code
- ✅ 10 minutes expiry
- ✅ One-time use only
- ✅ Invalidates previous OTPs
- ✅ IP address logging

### Password Security
- ✅ Minimum 8 characters
- ✅ Password confirmation required
- ✅ All tokens revoked on password change
- ✅ User must login again after reset

### Email Security
- ✅ Doesn't reveal if email exists (prevents enumeration)
- ✅ Professional email template
- ✅ Clear security warnings
- ✅ No reply email address

---

## 📧 Email Configuration

### Required: Configure Laravel Mail

Edit `BACKEND/lesgo-api/.env`:

```env
# For Gmail (Development)
MAIL_MAILER=smtp
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=your-email@gmail.com
MAIL_PASSWORD=your-app-password
MAIL_ENCRYPTION=tls
MAIL_FROM_ADDRESS=your-email@gmail.com
MAIL_FROM_NAME="LeSGo"

# For Production (Recommended: SendGrid, Mailgun, SES)
# MAIL_MAILER=sendgrid
# SENDGRID_API_KEY=your-sendgrid-api-key
```

### Gmail Setup (Development Only)
1. Go to Google Account settings
2. Enable 2-Factor Authentication
3. Generate App Password
4. Use App Password in `.env`

### Production Email Services (Recommended)
- **SendGrid** - 100 emails/day free
- **Mailgun** - 5,000 emails/month free
- **Amazon SES** - Very cheap, pay-as-you-go
- **Postmark** - Reliable, good deliverability

---

## 🧪 Testing

### Test the Complete Flow

1. **Start Backend**
```bash
cd BACKEND/lesgo-api
php artisan migrate  # Already done
php artisan serve
```

2. **Start Frontend**
```bash
cd FRONTEND
flutter run -d chrome
```

3. **Test Steps**
   - Go to login screen
   - Tap "Forgot Password?"
   - Enter email: `testcustomer@lesgo.com`
   - Tap "Send OTP"
   - Check email for OTP code
   - Enter OTP code
   - Tap "Verify OTP"
   - Enter new password
   - Tap "Reset Password"
   - Login with new password

### Test Email Template

Run this command to test email sending:
```bash
cd BACKEND/lesgo-api
php artisan tinker
```

Then in tinker:
```php
Mail::to('your-email@gmail.com')->send(new \App\Mail\PasswordResetOtpMail('123456', 'Test User', 10));
```

---

## 📊 Database Schema

### `password_resets` Table
```sql
CREATE TABLE password_resets (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    email VARCHAR(255) NOT NULL,
    otp VARCHAR(6) NOT NULL,
    reset_token VARCHAR(64) NULL,
    expires_at TIMESTAMP NOT NULL,
    is_used BOOLEAN DEFAULT FALSE,
    used_at TIMESTAMP NULL,
    ip_address VARCHAR(45) NULL,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    
    INDEX idx_email_otp_used (email, otp, is_used),
    INDEX idx_expires_at (expires_at)
);
```

---

## 🎨 UI Screenshots

### Step 1: Enter Email
- Logo at top
- "Forgot Password?" title
- Email input field
- "Send OTP" button

### Step 2: Verify OTP
- "Verify OTP" title
- Shows email where OTP was sent
- 6-digit OTP input
- "Resend" link
- "Verify OTP" button

### Step 3: Reset Password
- "Reset Password" title
- New password input (with show/hide)
- Confirm password input (with show/hide)
- "Reset Password" button

---

## 🚀 API Endpoints

### 1. Send OTP
```http
POST /api/v1/auth/forgot-password/send-otp
Content-Type: application/json

{
  "email": "user@example.com"
}

Response:
{
  "success": true,
  "message": "OTP sent to your email. Please check your inbox.",
  "expires_in_minutes": 10
}
```

### 2. Verify OTP
```http
POST /api/v1/auth/forgot-password/verify-otp
Content-Type: application/json

{
  "email": "user@example.com",
  "otp": "123456"
}

Response:
{
  "success": true,
  "message": "OTP verified successfully.",
  "reset_token": "abc123..."
}
```

### 3. Reset Password
```http
POST /api/v1/auth/forgot-password/reset
Content-Type: application/json

{
  "email": "user@example.com",
  "otp": "123456",
  "password": "newpassword123",
  "password_confirmation": "newpassword123"
}

Response:
{
  "success": true,
  "message": "Password reset successfully. Please login with your new password."
}
```

### 4. Resend OTP
```http
POST /api/v1/auth/forgot-password/resend-otp
Content-Type: application/json

{
  "email": "user@example.com"
}

Response:
{
  "success": true,
  "message": "OTP resent to your email."
}
```

---

## ✅ Advantages of Email OTP

### vs SMS OTP:
✅ **FREE** - No cost per OTP  
✅ **No SMS gateway needed** - Uses existing email service  
✅ **Better UX** - Users can copy-paste OTP  
✅ **More secure** - Email accounts usually have 2FA  
✅ **Works internationally** - No country restrictions  
✅ **Can include reset link** - Option to click link instead of typing OTP  

### Disadvantages:
⚠️ Requires email verification during registration  
⚠️ User must have access to email  
⚠️ Slightly slower than SMS (but more reliable)  

---

## 🔧 Troubleshooting

### Email Not Sending
1. Check `.env` mail configuration
2. Check Laravel logs: `BACKEND/lesgo-api/storage/logs/laravel.log`
3. Test with `php artisan tinker` (see Testing section)
4. For Gmail: Make sure App Password is correct
5. Check spam folder

### OTP Invalid/Expired
- OTP expires after 10 minutes
- OTP can only be used once
- Previous OTPs are invalidated when new one is sent
- Check system time is correct

### Rate Limiting
- Wait for cooldown period
- Check `RateLimiter` settings in controller
- Clear rate limiter: `php artisan cache:clear`

---

## 📝 Next Steps

### Optional Enhancements:
1. **Add SMS OTP option** (if budget allows)
2. **Add "Reset via Link" option** (click link in email instead of typing OTP)
3. **Add password strength indicator**
4. **Add "Remember this device" option**
5. **Add email notification when password is changed**
6. **Add 2FA requirement for sensitive accounts**

---

## 💰 Cost Analysis

### Email OTP (Current Implementation)
- **Cost**: FREE (up to limits)
- **SendGrid**: 100 emails/day free
- **Mailgun**: 5,000 emails/month free
- **Gmail**: Free (development only)

### SMS OTP (Alternative)
- **Cost**: ₱0.50-1.00 per SMS
- **Monthly estimate**: ₱3,000-10,000 (depending on usage)
- **Requires**: Semaphore or similar SMS gateway

**Recommendation**: Start with Email OTP (FREE), add SMS later if needed.

---

## ✅ Implementation Complete!

Tapos na ang implementation! Test mo na:

1. ✅ Backend API endpoints working
2. ✅ Database migration done
3. ✅ Email template created
4. ✅ Frontend UI complete
5. ✅ State management setup
6. ✅ Security features implemented
7. ✅ Rate limiting configured

**Next**: Configure email in `.env` and test the complete flow!
