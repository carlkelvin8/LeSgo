# Google Sign-In Setup Guide

## ✅ What's Already Done (Code-Ready)

The Google Sign-In code is **fully implemented** in both frontend and backend. Only configuration is needed.

### Frontend (Flutter):
- ✅ `google_sign_in` package installed
- ✅ `GoogleAuthService` implemented (`lib/core/services/google_auth_service.dart`)
- ✅ `GoogleAuthHelper` utility (`lib/core/utils/google_auth_helper.dart`)
- ✅ Login screen has "Sign in with Google" button
- ✅ Auth provider has `completeGoogleSignIn()` method
- ✅ Secrets config reads `GOOGLE_WEB_CLIENT_ID`

### Backend (Laravel):
- ✅ `GoogleAuthController` implemented (`app/Http/Controllers/Api/Auth/GoogleAuthController.php`)
- ✅ Route: `POST /api/v1/auth/google`
- ✅ Token verification via Google's tokeninfo endpoint
- ✅ Auto-creates new user with role `customer` if not exists
- ✅ Returns auth token for existing users

---

## 🔧 SETUP STEPS (Do This in Google Cloud Console)

### Step 1: Go to Google Cloud Console

1. Open https://console.cloud.google.com
2. Select project: **lesgo-a957c** (or create if needed)

### Step 2: Enable Google Sign-In API

1. Go to **APIs & Services** → **Library**
2. Search for **"Google Identity"** or **"People API"**
3. Enable **People API**
4. Also enable **Google Sign-In** if listed

### Step 3: Configure OAuth Consent Screen

1. Go to **APIs & Services** → **OAuth consent screen**
2. Select **External** user type
3. Fill in:
   - **App name**: LesGo
   - **User support email**: your email
   - **Developer contact**: your email
4. Add scopes:
   - `./auth/userinfo.email`
   - `./auth/userinfo.profile`
5. Add test users (if in testing mode):
   - Your Gmail accounts
6. Click **Publish App** (to make it available for all users)

### Step 4: Create OAuth 2.0 Client IDs

Go to **APIs & Services** → **Credentials** → **Create Credentials** → **OAuth 2.0 Client ID**

#### A. Web Application Client ID (MOST IMPORTANT)

1. Application type: **Web application**
2. Name: `LesGo Web Client`
3. Authorized JavaScript origins: (leave empty for now)
4. Authorized redirect URIs: (leave empty for now)
5. Click **Create**
6. **Copy the Client ID** — it looks like: `937689509907-xxxxxxxxxxxx.apps.googleusercontent.com`

#### B. Android Client ID

1. Application type: **Android**
2. Name: `LesGo Android (Customer)`
3. Package name: `com.lesgo_customer`
4. SHA-1 certificate fingerprint: (get from below)
5. Click **Create**

#### Get SHA-1 Fingerprint:
```bash
# Debug keystore (for testing):
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android

# Look for SHA1: XX:XX:XX:XX:...
```

### Step 5: Update Configuration Files

#### A. Update `secrets.json` (Frontend)
```json
{
  "GOOGLE_WEB_CLIENT_ID": "937689509907-YOUR_ACTUAL_ID.apps.googleusercontent.com"
}
```

#### B. Update `google-services.json` (Frontend)
Add the oauth_client entry:
```json
"oauth_client": [
  {
    "client_id": "937689509907-YOUR_ACTUAL_ID.apps.googleusercontent.com",
    "client_type": 3
  }
]
```

#### C. Update Backend `.env`
```env
GOOGLE_CLIENT_ID=937689509907-YOUR_ACTUAL_ID.apps.googleusercontent.com
```

#### D. Update `config/services.php` in Backend
```php
'google' => [
    'client_id' => env('GOOGLE_CLIENT_ID'),
],
```

### Step 6: Test

1. Run the app
2. Tap "Sign in with Google"
3. Google sign-in popup should appear
4. Select account
5. Should auto-login or create account

---

## 📋 Quick Setup Checklist

- [ ] Google Cloud project `lesgo-a957c` selected
- [ ] People API enabled
- [ ] OAuth consent screen configured & published
- [ ] **Web Client ID** created
- [ ] Android Client ID created (with SHA-1)
- [ ] `secrets.json` updated with Web Client ID
- [ ] `google-services.json` updated with oauth_client
- [ ] Backend `.env` updated with `GOOGLE_CLIENT_ID`
- [ ] Backend `config/services.php` has google client_id
- [ ] Test sign-in works

---

## 🔑 Where to Put the Client ID

Once you have the Web Client ID (e.g., `937689509907-abc123xyz.apps.googleusercontent.com`):

### File 1: `FRONTEND/secrets.json`
```json
"GOOGLE_WEB_CLIENT_ID": "937689509907-abc123xyz.apps.googleusercontent.com"
```

### File 2: `BACKEND/lesgo-api/.env`
```env
GOOGLE_CLIENT_ID=937689509907-abc123xyz.apps.googleusercontent.com
```

### File 3: `FRONTEND/android/app/google-services.json`
In the `oauth_client` array, add:
```json
{
  "client_id": "937689509907-abc123xyz.apps.googleusercontent.com",
  "client_type": 3
}
```

---

## ⚡ FASTEST SETUP (If You Already Have Firebase)

Since you already have Firebase project `lesgo-a957c`:

1. Go to https://console.firebase.google.com
2. Select project `lesgo-a957c`
3. Go to **Authentication** → **Sign-in method**
4. Enable **Google**
5. It will auto-create the OAuth client IDs
6. Go to **Project Settings** → **General** → scroll to your Android app
7. Download fresh `google-services.json`
8. The Web Client ID will be in **Authentication** → **Sign-in method** → **Google** → **Web SDK configuration** → **Web client ID**

That Web client ID is what goes in `secrets.json`!

---

## 🎯 Summary

| What | Where | Value Needed |
|------|-------|-------------|
| Web Client ID | `secrets.json` | From Google Cloud Console |
| Web Client ID | Backend `.env` | Same as above |
| Android Client ID | `google-services.json` | Auto-created with SHA-1 |
| SHA-1 fingerprint | Google Cloud Console | From `keytool` command |

**The code is 100% ready. Just provide the Google Client ID and it works!**
