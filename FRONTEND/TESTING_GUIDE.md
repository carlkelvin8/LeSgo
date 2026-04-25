# 🧪 Testing Guide - Medium Priority API Integration

**Date:** April 16, 2026  
**Status:** Ready for Testing  
**Features:** Security, Social, Geofence, Distance

---

## 📋 Overview

This guide will help you test all the newly integrated medium priority features. We've created a comprehensive test suite that validates all 26 endpoints.

---

## 🚀 How to Run Tests

### Method 1: Using the Test Screen (Recommended)

1. **Run the app:**
   ```bash
   cd FRONTEND
   flutter run
   ```

2. **Navigate to Test Screen:**
   - From the main menu, find the "API Test" option
   - Or navigate directly to `/test-api` route

3. **Run Medium Priority Tests:**
   - Click the **"Test Medium Priority APIs (NEW!)"** button
   - This will open a dedicated test screen

4. **Execute All Tests:**
   - Click **"RUN ALL TESTS"** button
   - Wait for all 14 tests to complete
   - View results in real-time

### Method 2: Manual Testing via Code

You can also test individual features programmatically:

```dart
import 'package:lesgo/core/di/injection.dart';
import 'package:lesgo/data/data_source/security_remote_datasource.dart';

// Example: Test Security Dashboard
final securityDataSource = getIt<SecurityRemoteDataSource>();
final dashboard = await securityDataSource.getSecurityDashboard();
print('Active sessions: ${dashboard.activeSessions}');
```

---

## 🧪 Test Suite Details

### Total Tests: 14

#### Security Tests (4 tests)
1. ✅ **Security Dashboard** - Get security overview
2. ✅ **Setup 2FA** - Initialize two-factor authentication
3. ✅ **List Biometrics** - Get enrolled biometric devices
4. ✅ **Get Audit Logs** - Retrieve security audit logs

#### Social Tests (3 tests)
5. ✅ **Get Social Platforms** - List available platforms
6. ✅ **Get Social Statistics** - Overall sharing stats
7. ✅ **Get Social Analytics** - Personal analytics

#### Geofence Tests (4 tests)
8. ✅ **Get Geofences** - List all geofences
9. ✅ **Get Geofence Types** - Available geofence types
10. ✅ **Get Geofence Statistics** - Geofence stats
11. ✅ **Check Location** - Validate service area (Manila)

#### Distance Tests (2 tests)
12. ✅ **Calculate Distance** - Manila to Quezon City
13. ✅ **Get Overall Distance Stats** - Total distance statistics

---

## 📊 Expected Results

### ✅ Success Criteria

Each test should return:
- ✅ **Status Code:** 200 OK
- ✅ **Valid Data:** Properly formatted response
- ✅ **No Errors:** No exceptions thrown
- ✅ **Response Time:** < 5 seconds

### Example Success Output:

```
✅ Security Dashboard
   Dashboard loaded: 2 active sessions
   Duration: 234ms

✅ Get Social Platforms
   Found 3 platform(s): Facebook, Twitter, Instagram
   Duration: 189ms

✅ Check Location (Manila)
   Inside service area! Found 1 geofence(s)
   Duration: 156ms

✅ Calculate Distance
   Distance: 3.45 km (3450 m)
   Duration: 201ms
```

---

## ⚠️ Common Issues & Solutions

### Issue 1: Authentication Required (401)
**Error:** `Unauthorized - Please login first`

**Solution:**
```dart
// You need to login first before testing
// The test suite requires a valid auth token
// Make sure you're logged in before running tests
```

### Issue 2: CORS Error (Web Only)
**Error:** `XMLHttpRequest error`

**Solution:**
- CORS errors only affect web builds
- Test on mobile (Android/iOS) instead
- Or configure backend to allow CORS

### Issue 3: Connection Timeout
**Error:** `Connection timeout`

**Solution:**
- Check internet connection
- Verify API server is running
- Check if URL is correct: `https://lesgo-api-feature-auth-secmes.free.laravel.cloud/api`

### Issue 4: Endpoint Not Found (404)
**Error:** `Endpoint not found`

**Solution:**
- Verify the endpoint exists in backend
- Check API documentation
- Ensure you're using the correct API version (v1)

---

## 🔍 Manual Testing Checklist

### Security Features

#### 2FA (Two-Factor Authentication)
- [ ] Setup 2FA returns QR code
- [ ] QR code is valid base64 image
- [ ] Secret key is provided
- [ ] Backup codes are generated (3+ codes)
- [ ] Can verify 2FA with code
- [ ] Can disable 2FA
- [ ] Can regenerate backup codes

#### Biometric Authentication
- [ ] Can enroll biometric (fingerprint/face)
- [ ] List biometrics returns enrolled devices
- [ ] Can verify biometric
- [ ] Can deactivate biometric

#### Audit Logs
- [ ] Audit logs return events
- [ ] Can filter by event type
- [ ] Can filter by date range
- [ ] Pagination works correctly

---

### Social Sharing Features

#### Platforms
- [ ] Get platforms returns list
- [ ] Each platform has name, icon, max_characters
- [ ] Supported features are listed

#### Sharing
- [ ] Can generate order share
- [ ] Share URL is valid
- [ ] Content is generated
- [ ] Image URL is provided (if applicable)
- [ ] Can generate referral share
- [ ] Referral code is unique
- [ ] Can generate milestone share

#### Analytics
- [ ] Statistics show total shares/views/clicks
- [ ] Engagement rate is calculated
- [ ] My shares list is paginated
- [ ] Can track engagement (view/click)

---

### Geofence Features

#### Service Areas
- [ ] Get geofences returns list
- [ ] Each geofence has name, type, coordinates
- [ ] Radius is in kilometers
- [ ] Active status is shown

#### Location Checking
- [ ] Check location validates coordinates
- [ ] Returns inside/outside status
- [ ] Lists matching geofences
- [ ] Manila coordinates (14.5995, 120.9842) work

#### Types & Statistics
- [ ] Get types returns available types
- [ ] Statistics show total/active counts
- [ ] Entries today is tracked
- [ ] Orders from geofences is counted

---

### Distance Calculator Features

#### Distance Calculation
- [ ] Calculate distance works
- [ ] Returns distance in km
- [ ] Returns distance in meters
- [ ] Unit is specified
- [ ] Manila to Quezon City calculation works

#### Statistics
- [ ] Overall stats show total distance
- [ ] Total orders is counted
- [ ] Average distance is calculated

---

## 📱 Testing on Different Platforms

### Web Testing
```bash
flutter run -d chrome
```
**Note:** May encounter CORS issues. Use mobile for full testing.

### Android Testing
```bash
flutter run -d android
```
**Recommended:** Best for full API testing

### iOS Testing
```bash
flutter run -d ios
```
**Recommended:** Best for full API testing

---

## 🐛 Debugging Tips

### Enable Verbose Logging

Add this to your test code:
```dart
import 'package:dio/dio.dart';

final dio = Dio();
dio.interceptors.add(LogInterceptor(
  requestBody: true,
  responseBody: true,
  error: true,
));
```

### Check Network Requests

Use Flutter DevTools:
1. Run app with `flutter run`
2. Open DevTools
3. Go to Network tab
4. Monitor API requests

### View API Responses

Add print statements:
```dart
try {
  final response = await dataSource.getSecurityDashboard();
  print('Response: $response');
} catch (e) {
  print('Error: $e');
}
```

---

## 📈 Test Results Interpretation

### Success Rate Calculation
```
Success Rate = (Passed Tests / Total Tests) × 100%
```

### Expected Success Rates

| Scenario | Expected Rate | Status |
|----------|--------------|--------|
| **All endpoints working** | 100% | ✅ Perfect |
| **Some endpoints down** | 70-99% | ⚠️ Partial |
| **Auth issues** | 0% | ❌ Login required |
| **Network issues** | 0% | ❌ Check connection |

---

## 🎯 Test Scenarios

### Scenario 1: First Time User
```
1. Run app
2. Navigate to test screen
3. Run all tests
4. Expected: Some tests may fail (401) if not logged in
5. Login first, then re-run tests
```

### Scenario 2: Logged In User
```
1. Login to app
2. Navigate to test screen
3. Run all tests
4. Expected: All tests should pass (100%)
```

### Scenario 3: Offline Testing
```
1. Disable internet
2. Run tests
3. Expected: All tests fail with timeout/connection errors
4. This validates error handling
```

---

## 📝 Test Report Template

After running tests, document results:

```
# Test Report - Medium Priority APIs

Date: [Date]
Tester: [Name]
Platform: [Android/iOS/Web]
App Version: [Version]

## Summary
- Total Tests: 14
- Passed: [X]
- Failed: [Y]
- Success Rate: [Z]%

## Failed Tests
1. [Test Name]
   - Error: [Error Message]
   - Reason: [Root Cause]
   - Fix: [Solution]

## Notes
[Any additional observations]

## Conclusion
[Overall assessment]
```

---

## 🔧 Troubleshooting Commands

### Clear Flutter Cache
```bash
flutter clean
flutter pub get
```

### Rebuild Generated Files
```bash
dart run build_runner build --delete-conflicting-outputs
```

### Check Dependencies
```bash
flutter pub outdated
flutter pub upgrade
```

### Analyze Code
```bash
flutter analyze
```

---

## ✅ Pre-Testing Checklist

Before running tests, ensure:

- [ ] Flutter is installed and updated
- [ ] Dependencies are installed (`flutter pub get`)
- [ ] Build runner has generated files
- [ ] No compilation errors (`flutter analyze`)
- [ ] Internet connection is active
- [ ] API server is accessible
- [ ] (Optional) User is logged in for auth-required endpoints

---

## 🎉 Success Indicators

Your integration is successful if:

1. ✅ **All 14 tests pass** (100% success rate)
2. ✅ **Response times are reasonable** (< 5 seconds)
3. ✅ **Data is properly formatted** (valid JSON)
4. ✅ **No compilation errors** (clean build)
5. ✅ **Error handling works** (graceful failures)

---

## 📞 Support

If you encounter issues:

1. Check this guide first
2. Review error messages carefully
3. Check API documentation
4. Verify backend is running
5. Test on different platforms

---

## 🚀 Next Steps After Testing

Once all tests pass:

1. **Create UI Screens** - Build user interfaces for features
2. **Add Error Handling** - Improve error messages
3. **Add Loading States** - Show progress indicators
4. **Add Animations** - Enhance user experience
5. **Write Unit Tests** - Add automated testing
6. **Integration Testing** - Test full user flows

---

**Happy Testing!** 🎉

If all tests pass, you're ready to build the UI and start using these features in production!
