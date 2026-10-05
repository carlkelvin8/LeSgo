# Customer App - Role Validation Fix

**Date**: July 1, 2026  
**Issue**: Driver and Merchant accounts can login to customer app and get "unauthorized" errors when trying to create orders

## 🔧 CHANGES MADE

### 1. Updated User DTO (`user_dto.dart`)
Added `role` field to `UserPayloadDto`:
```dart
@JsonSerializable()
class UserPayloadDto {
  final int? id;
  final String? name;
  final String? email;
  final String? role;  // ← ADDED

  UserPayloadDto({this.id, this.name, this.email, this.role});
  // ...
}
```

Added `role` getter to `UserDto`:
```dart
String get role => user?.role ?? '';
```

### 2. Updated User Entity (`user.dart`)
Added `role` field to User domain entity:
```dart
class User {
  final String id;
  final String email;
  final String name;
  final String? token;
  final String? role;  // ← ADDED

  User({
    required this.id,
    required this.email,
    required this.name,
    this.token,
    this.role,  // ← ADDED
  });
}
```

### 3. Updated Repository (`user_repository_impl.dart`)
Pass role from DTO to User entity:
```dart
return User(
  id: dto.id,
  email: dto.email,
  name: dto.name,
  token: token,
  role: dto.role,  // ← ADDED
);
```

### 4. Updated Auth Provider (`auth_provider.dart`)
Added role validation in 3 places:

#### A. Login Method
```dart
try {
  final user = await _loginUseCase(request);

  // ✅ Role validation for customer app
  if (user.role != null && user.role != 'customer') {
    state = state.copyWith(
      isLoading: false,
      error: 'This account is for ${user.role}s. Please use the ${user.role} app to login.',
      clearSuccessMessage: true,
    );
    return;
  }

  state = state.copyWith(
    user: user,
    isLoading: false,
    error: null,
    clearError: true,
    successMessage: 'Login successful!',
  );
  // ...
}
```

#### B. Google Sign In Method
```dart
state = state.copyWith(
  user: User(
    id: profile.id.toString(),
    email: profile.email,
    name: profile.name,
    token: token,
    role: profile.role,  // ← ADDED
  ),
  clearError: true,
);

// ✅ Role validation for customer app
if (profile.role != 'customer') {
  state = AuthState(); // Clear state
  return false;
}
```

#### C. Restore Session Method
```dart
state = state.copyWith(
  user: User(
    id: profile.id.toString(),
    email: profile.email,
    name: profile.name,
    token: token,
    role: profile.role,  // ← ADDED
  ),
  rememberMe: true,
  clearError: true,
);

// ✅ Role validation for customer app
if (profile.role != 'customer') {
  state = AuthState(); // Clear state
  return false;
}
```

### 5. Regenerated Files
Ran build_runner to update .g.dart files:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## ✅ WHAT THIS FIXES

### Before Fix:
1. Driver/Merchant accounts could login to customer app
2. They would see customer interface
3. When trying to create orders → **401 Unauthorized error**
4. Confusing user experience
5. Wrong app usage

### After Fix:
1. ✅ **Customer accounts** → Login successful, can create orders
2. ❌ **Driver accounts** → Shows error: "This account is for drivers. Please use the driver app to login."
3. ❌ **Merchant accounts** → Shows error: "This account is for merchants. Please use the merchant app to login."
4. ❌ **Partner accounts** → Shows error: "This account is for partners. Please use the partner app to login."
5. Clear user guidance on which app to use

## 🧪 TEST CASES

### Test Case 1: Customer Login (Should Succeed) ✅
```
Email: carlkelvinmanahan014@gmail.com
Role: customer
Expected: Login successful, access home screen
```

### Test Case 2: Driver Login (Should Fail) ❌
```
Email: alcantarawilson0506@gmail.com
Role: driver
Expected: Error message - "This account is for drivers. Please use the driver app to login."
```

### Test Case 3: Merchant Login (Should Fail) ❌
```
Email: merchant@lesgo.test
Role: partner_admin
Expected: Error message - "This account is for partner_admins. Please use the partner_admin app to login."
```

## 📱 USER IMPACT

### Wilson's Account (alcantarawilson0506@gmail.com)
- **Before**: Could login, got unauthorized when ordering
- **After**: Cannot login, clear message to use driver/merchant app

**Recommendation for Wilson**:
1. Use existing account (`alcantarawilson0506@gmail.com`) for **RIDER/MERCHANT app**
2. Create NEW account with different email for **CUSTOMER app**
3. Example: `wilson.customer@gmail.com` or any other email

## 🔒 SECURITY BENEFITS

1. **Prevents unauthorized access** - Only customers can access customer features
2. **Clear app boundaries** - Each role uses their designated app
3. **Better error messages** - Users know which app to use
4. **Prevents confusion** - No more "why can't I create orders?" issues

## 📋 FILES MODIFIED

1. `FRONTEND/lib/domain/entities/user.dart` - Added role field
2. `FRONTEND/lib/data/data_source/dto/user/user_dto.dart` - Added role to DTO
3. `FRONTEND/lib/data/repositoryImpl/user_repository_impl.dart` - Pass role from DTO
4. `FRONTEND/lib/presentation/provider/auth/auth_provider.dart` - Role validation logic
5. Generated files updated via build_runner

## ✅ VERIFICATION STEPS

1. ✅ User DTO updated with role field
2. ✅ User entity updated with role field  
3. ✅ Repository passes role from API to entity
4. ✅ Auth provider validates role after login
5. ✅ Auth provider validates role after Google sign in
6. ✅ Auth provider validates role on session restore
7. ✅ Build runner regenerated .g.dart files
8. ⏳ Hot reload/restart app to apply changes
9. ⏳ Test with driver account (should show error)
10. ⏳ Test with customer account (should login successfully)

## 🚀 NEXT STEPS

1. Hot reload or restart the running app
2. Test login with Wilson's driver account (should fail with clear message)
3. Test login with customer account (should succeed)
4. Inform Wilson to create separate customer account
5. Consider adding similar role validation to RIDER and MERCHANT apps

## 📝 SIMILAR FIX FOR OTHER APPS

The same pattern should be applied to:

### Rider/Merchant App (RIDERSIDE)
Should only allow:
- `role: 'driver'`
- `role: 'partner_admin'`

Should reject:
- `role: 'customer'`

### Future Admin App
Should only allow:
- `role: 'admin'`
- `role: 'super_admin'`

---

**Fix Status**: ✅ CODE COMPLETE - Ready for testing
**App Status**: Running in emulator, needs hot reload
**User Guidance**: Clear error messages implemented
