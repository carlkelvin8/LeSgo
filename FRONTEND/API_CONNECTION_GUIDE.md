# API Connection Issue - Solutions

## Problem
Login failed with error: `DioException [connection error]: The connection errored: The XMLHttpRequest onError callback was called.`

This indicates the frontend cannot connect to the backend API.

## Solutions

### Option 1: Check if Backend Server is Running
The current API URL is: `https://lesgo-api-feature-auth-secmes.free.laravel.cloud/api`

**Test the API:**
1. Open your browser
2. Go to: `https://lesgo-api-feature-auth-secmes.free.laravel.cloud/api/v1/services`
3. If you see JSON data, the server is running
4. If you see an error or timeout, the server is down

### Option 2: Use Local Backend (Recommended for Development)
If you have a local backend running:

1. **Update API URL** in `FRONTEND/lib/core/constants/api_constants.dart`:
   ```dart
   static String get baseUrl {
     // For local development
     return 'http://localhost:8000/api';
     
     // OR if using different port
     // return 'http://localhost:3000/api';
   }
   ```

2. **Hot Reload** the app (press `r` in the terminal where flutter is running)

### Option 3: Fix CORS for Web Development
If the backend is running but CORS is blocking requests:

**Backend needs to allow localhost in CORS configuration:**
- Allow origin: `http://localhost:*`
- Allow methods: `GET, POST, PUT, DELETE, PATCH, OPTIONS`
- Allow headers: `Content-Type, Authorization, Accept`

### Option 4: Use Mock Data for UI Testing
If you just want to test the UI without a backend:

1. **Create a mock auth datasource** that returns fake data
2. **Bypass API calls** temporarily for UI development

## Current Configuration

**API Base URL:** `https://lesgo-api-feature-auth-secmes.free.laravel.cloud/api`

**Endpoints Being Used:**
- Login: `/v1/auth/login`
- Register: `/v1/auth/register`
- Get User: `/v1/auth/me`
- Logout: `/v1/auth/logout`

## Testing the Connection

You can test if the API is accessible by running this in your browser console:
```javascript
fetch('https://lesgo-api-feature-auth-secmes.free.laravel.cloud/api/v1/services')
  .then(r => r.json())
  .then(d => console.log('API is working:', d))
  .catch(e => console.error('API error:', e));
```

## Next Steps

1. **Verify backend is running** - Check the URL in browser
2. **Update API URL** if using local backend
3. **Configure CORS** on backend if needed
4. **Hot reload** the Flutter app after changes

## For Production

When deploying to production:
- Update `baseUrl` to your production API URL
- Ensure CORS is configured for your production domain
- Use environment variables for different environments (dev/staging/prod)
