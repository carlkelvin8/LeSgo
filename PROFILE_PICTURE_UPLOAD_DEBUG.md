# Profile Picture Upload Issue - Debug Guide

**Date**: July 1, 2026  
**Issue**: Profile picture update not working in customer app  
**Status**: 🔍 INVESTIGATING with debug logs added

## 🔧 Changes Made for Debugging

Added comprehensive logging to track the entire profile picture upload flow:

### 1. ProfileHeader Widget
Already has logging when image is tapped:
```dart
print('🔵 ProfileHeader: Profile image tapped!');
print('🔵 ProfileHeader: Calling onImageTap callback...');
```

### 2. ProfileControllers - showImagePicker
```dart
print('🔵 ProfileControllers: showImagePicker called!');
print('🔵 ProfileControllers: Opening camera picker...');
print('🔵 ProfileControllers: Modal closed.');
```

### 3. ProfileControllers - _pickImageFromCamera
```dart
print('🔵 ProfileControllers: Requesting camera permission...');
print('🔵 ProfileControllers: Camera permission result: $hasPermission');
print('❌ ProfileControllers: Camera permission denied');
print('🔵 ProfileControllers: Opening camera...');
print('✅ ProfileControllers: Image captured! Path: ${image.path}');
print('⚠️ ProfileControllers: No image captured (user cancelled?)');
```

### 4. ProfileControllers - _updateProfileImage
```dart
print('🔵 ProfileControllers: Starting profile image update...');
print('🔵 ProfileControllers: Image file path: ${imageFile.path}');
print('🔵 ProfileControllers: Update result: $success');
print('✅ ProfileControllers: Profile picture updated successfully!');
print('❌ ProfileControllers: Update failed! Error: $error');
```

### 5. ProfileProvider - updateProfileImage
```dart
print('🔵 ProfileProvider: updateProfileImage called');
print('🔵 ProfileProvider: imageFile type: ${imageFile.runtimeType}');
print('🔵 ProfileProvider: XFile created - path: ${xFile.path}');
print('🔵 ProfileProvider: Attempting FileUploadService upload...');
print('✅ ProfileProvider: File uploaded! URL: ${uploaded.url}');
print('🔵 ProfileProvider: updateMe response - success: ${response.success}');
print('✅ ProfileProvider: User updated via FileUploadService!');
print('⚠️ ProfileProvider: FileUploadService failed: $mediaError');
print('🔵 ProfileProvider: Trying direct uploadProfilePicture...');
print('✅ ProfileProvider: User updated via uploadProfilePicture!');
print('❌ ProfileProvider: No updated user received');
print('❌ ProfileProvider: Profile image upload error: $e\n$stackTrace');
```

## 📋 Flow to Monitor

When user taps profile picture:

1. **ProfileHeader** → Tap detected
2. **ProfileControllers.showImagePicker** → Called
3. **ProfileControllers._pickImageFromCamera** → Request permission
4. **Camera Opens** → User takes photo
5. **ProfileControllers._updateProfileImage** → Upload starts
6. **ProfileProvider.updateProfileImage** → Backend upload
7. **Success/Error** → UI feedback

## 🧪 Testing Steps

1. **Open app** in emulator (already running)
2. **Navigate** to Profile screen
3. **Tap** on profile picture
4. **Watch logs** in terminal for debug output
5. **Check** each step:
   - ✅ Image tap detected?
   - ✅ showImagePicker called?
   - ✅ Camera permission granted?
   - ✅ Camera opens?
   - ✅ Image captured?
   - ✅ Upload started?
   - ✅ Backend response?
   - ✅ Success/Error shown?

## 🔍 Expected Log Flow (Success)

```
🔵 ProfileHeader: Profile image tapped!
🔵 ProfileHeader: Calling onImageTap callback...
🔵 ProfileControllers: showImagePicker called!
🔵 ProfileControllers: Opening camera picker...
🔵 ProfileControllers: Requesting camera permission...
🔵 ProfileControllers: Camera permission result: true
🔵 ProfileControllers: Opening camera...
✅ ProfileControllers: Image captured! Path: /data/.../image.jpg
🔵 ProfileControllers: Starting profile image update...
🔵 ProfileControllers: Image file path: /data/.../image.jpg
🔵 ProfileProvider: updateProfileImage called
🔵 ProfileProvider: imageFile type: XFile
🔵 ProfileProvider: XFile created - path: /data/.../image.jpg
🔵 ProfileProvider: Attempting FileUploadService upload...
✅ ProfileProvider: File uploaded! URL: https://...
🔵 ProfileProvider: updateMe response - success: true
✅ ProfileProvider: User updated via FileUploadService!
✅ ProfileProvider: Profile updated! New URL: https://...
🔵 ProfileControllers: Update result: true
✅ ProfileControllers: Profile picture updated successfully!
🔵 ProfileControllers: Modal closed.
```

## 🚨 Common Issues to Check

### Issue 1: Tap Not Detected
**Symptoms**: No logs when tapping picture
**Check**:
- Is `onImageTap` callback null?
- Is ProfileHeader rendered?
- Is InkWell responding?

### Issue 2: Permission Denied
**Symptoms**: Camera permission logs show false
**Check**:
- Android permissions in AndroidManifest.xml
- Permission service implementation
- User actually denied permission

### Issue 3: Camera Won't Open
**Symptoms**: Permission granted but no camera
**Check**:
- image_picker plugin installed?
- Camera hardware available?
- Emulator camera configuration

### Issue 4: Image Captured But Upload Fails
**Symptoms**: Image path logged but upload error
**Check**:
- Network connectivity
- Backend API endpoint `/v1/auth/me/profile-picture`
- Authentication token valid
- File upload service configuration

### Issue 5: Backend Error
**Symptoms**: Upload starts but backend returns error
**Check**:
- Backend logs at `BACKEND/lesgo-api/storage/logs/laravel.log`
- File size (max 5MB)
- File format (jpeg, png, jpg, gif)
- Storage permissions on backend
- MediaStorageService working

## 🔧 Backend Endpoint

```
POST /api/v1/auth/me/profile-picture
Content-Type: multipart/form-data
Authorization: Bearer {token}

Body:
- profile_picture: (file) image file

Response:
{
  "success": true,
  "message": "Profile picture uploaded successfully",
  "profile_picture_url": "https://...",
  "user": { ... }
}
```

## 📱 Files Modified

1. `lib/presentation/provider/main/profile/controller/profile.controller.notifier.dart` - Added logs
2. `lib/presentation/provider/main/profile/profile_provider.dart` - Added logs
3. `lib/presentation/widgets/profile/profile_header.dart` - Already has logs

## ✅ Next Steps

1. **Test in emulator** - Navigate to Profile, tap picture
2. **Watch terminal output** - Look for debug logs
3. **Identify failure point** - Where does the flow stop?
4. **Fix identified issue** - Based on log output
5. **Retest** - Verify fix works

## 📝 Report Format

When reporting issue, include:

```
**What Happened**: [Describe behavior]
**Logs Captured**: [Copy relevant logs from terminal]
**Last Successful Step**: [Which log appeared last]
**Error Message**: [Any error shown in UI or logs]
```

---

**App Status**: Running in emulator with debug logs  
**Ready for Testing**: ✅ YES - Tap profile picture and watch logs!
