# Rider Profile Picture Upload Implementation

## Overview
Implemented profile picture upload functionality for riders, allowing them to upload and display their profile pictures in the rider app.

## Backend Changes

### 1. Database Migration
**File**: `BACKEND/lesgo-api/database/migrations/2026_04_23_000000_add_profile_picture_to_users_table.php`
- Added `profile_picture` column to `users` table
- Column type: `string`, nullable
- Stores the relative path to the uploaded image (e.g., `profile_pictures/xyz.jpg`)

### 2. User Model
**File**: `BACKEND/lesgo-api/app/Models/User.php`
- Added `profile_picture` to the `$fillable` array

### 3. Auth Controller
**File**: `BACKEND/lesgo-api/app/Http/Controllers/Api/Auth/AuthController.php`

#### New Endpoint: `POST /api/v1/auth/me/profile-picture`
- **Authentication**: Required (Bearer token)
- **Request**: Multipart form data with `profile_picture` file
- **Validation**: 
  - Required image file
  - Allowed types: jpeg, png, jpg, gif
  - Max size: 5MB (5120 KB)
- **Functionality**:
  - Deletes old profile picture if exists
  - Stores new image in `storage/app/public/profile_pictures/`
  - Updates user record with new path
  - Returns success response with profile picture URL

#### Updated `formatUserResponse()` Method
- Now includes `profile_picture` field in user response
- Also includes `driver_profile` data if user is a driver

### 4. API Routes
**File**: `BACKEND/lesgo-api/routes/api.php`
- Added route: `POST /v1/auth/me/profile-picture` → `AuthController@uploadProfilePicture`
- Protected by `auth:sanctum` middleware

### 5. Image Serving
**File**: `BACKEND/lesgo-api/public/serve-image.php`
- Already supports serving profile pictures with CORS headers
- Usage: `http://127.0.0.1:8000/serve-image.php?path=profile_pictures/filename.jpg`

## Frontend Changes (RIDERSIDE)

### 1. Rider Profile State
**File**: `RIDERSIDE/lib/presentation/provider/main/riderside/rider_profile_provider.dart`

#### Updated `RiderProfileState`
- Added `profilePictureUrl` field (nullable String)
- Added `isUploading` field (boolean) to track upload progress

#### Updated `RiderProfileNotifier`
- **`loadProfile()` method**: 
  - Fetches user data from `/v1/auth/me`
  - Builds profile picture URL using `serve-image.php` if path exists
  - Handles both absolute URLs and relative paths
  
- **New `uploadProfilePicture()` method**:
  - Accepts image path as parameter
  - Calls `ApiService.uploadProfilePicture()`
  - Shows upload progress via `isUploading` state
  - Reloads profile after successful upload
  - Returns boolean indicating success/failure

### 2. Profile Header Widget
**File**: `RIDERSIDE/lib/presentation/widgets/main/riderside/profile/rider_profile_header.dart`

#### Features
- **Tappable Profile Picture**: User can tap to upload new picture
- **Image Picker Integration**: Opens gallery to select image
- **Loading Overlay**: Shows circular progress indicator during upload
- **Camera Icon Overlay**: Visual indicator that picture is tappable
- **Error Handling**: Shows snackbar messages for success/failure
- **Image Display**:
  - Shows uploaded profile picture via `Image.network()`
  - Fallback to person icon if no picture
  - Loading indicator while image loads
  - Error builder for failed image loads

#### Image Picker Configuration
- Source: Gallery only
- Max dimensions: 800x800 pixels
- Image quality: 85%

### 3. API Service
**File**: `RIDERSIDE/lib/core/services/api_service.dart`

#### New Method: `uploadProfilePicture()`
- **Endpoint**: `POST /v1/auth/me/profile-picture`
- **Request**: Multipart form data
- **Parameters**: 
  - `imagePath`: Local file path to image
- **Returns**: Response map with success status and profile picture URL
- **Error Handling**: Rethrows exceptions for caller to handle

## User Flow

1. **View Profile**: Rider opens profile screen
2. **Tap Picture**: Rider taps on profile picture (or placeholder icon)
3. **Select Image**: Gallery opens, rider selects image
4. **Upload**: 
   - Loading overlay appears
   - Image uploads to backend
   - Backend stores in `storage/app/public/profile_pictures/`
   - Backend updates user record
5. **Display**: 
   - Profile reloads
   - New picture displays via `serve-image.php`
   - Success message shows

## CORS Support

Profile pictures are served through `serve-image.php` which adds proper CORS headers:
- `Access-Control-Allow-Origin: *`
- `Access-Control-Allow-Methods: GET, OPTIONS`
- `Access-Control-Allow-Headers: *`

This ensures Flutter web can load images without CORS errors.

## Security Features

1. **Authentication Required**: Only authenticated users can upload
2. **File Validation**: 
   - Type checking (images only)
   - Size limit (5MB max)
3. **Path Security**: `serve-image.php` prevents directory traversal attacks
4. **Old File Cleanup**: Previous profile pictures are deleted on new upload

## Testing

### Test User
- **Driver ID**: 74
- **User ID**: 926
- **Name**: Test Rider
- **Email**: testrider@lesgo.com

### Test Steps
1. Login as test rider
2. Navigate to profile screen
3. Tap profile picture
4. Select image from gallery
5. Verify upload progress indicator
6. Verify success message
7. Verify new picture displays correctly
8. Check browser console for any CORS errors

## Files Modified/Created

### Backend
- ✅ `database/migrations/2026_04_23_000000_add_profile_picture_to_users_table.php` (NEW)
- ✅ `app/Models/User.php` (MODIFIED)
- ✅ `app/Http/Controllers/Api/Auth/AuthController.php` (MODIFIED)
- ✅ `routes/api.php` (MODIFIED)
- ✅ `public/serve-image.php` (ALREADY EXISTS)

### Frontend (RIDERSIDE)
- ✅ `lib/presentation/provider/main/riderside/rider_profile_provider.dart` (MODIFIED)
- ✅ `lib/presentation/widgets/main/riderside/profile/rider_profile_header.dart` (MODIFIED)
- ✅ `lib/core/services/api_service.dart` (MODIFIED)

## Next Steps

1. ✅ Database migration completed
2. ✅ Backend endpoint implemented
3. ✅ Frontend UI implemented
4. ⏳ **Test the functionality** (needs user verification)
5. ⏳ Verify images load correctly in rider app
6. ⏳ Check for any CORS issues
7. ⏳ Verify old images are deleted properly

## Notes

- Profile pictures are stored separately from `profile_photo_url` (which is for external URLs)
- The `profile_picture` field stores the relative path within storage
- Images are served with proper CORS headers via `serve-image.php`
- The implementation follows the same pattern as proof images upload
- Maximum file size is 5MB to balance quality and performance
