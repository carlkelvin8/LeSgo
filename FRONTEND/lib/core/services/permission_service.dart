import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';

/// Service for handling app permissions
@lazySingleton
class PermissionService {
  /// Check if location permission is granted
  Future<bool> hasLocationPermission() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }

  /// Request location permission
  Future<PermissionStatus> requestLocationPermission() async {
    debugPrint('📍 Requesting location permission...');
    
    final status = await Permission.location.request();
    
    if (status.isGranted) {
      debugPrint('✅ Location permission granted');
    } else if (status.isDenied) {
      debugPrint('❌ Location permission denied');
    } else if (status.isPermanentlyDenied) {
      debugPrint('⛔ Location permission permanently denied');
    }
    
    return status;
  }

  /// Check if camera permission is granted
  Future<bool> hasCameraPermission() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  /// Request camera permission
  Future<PermissionStatus> requestCameraPermission() async {
    debugPrint('📷 Requesting camera permission...');
    
    final status = await Permission.camera.request();
    
    if (status.isGranted) {
      debugPrint('✅ Camera permission granted');
    } else if (status.isDenied) {
      debugPrint('❌ Camera permission denied');
    } else if (status.isPermanentlyDenied) {
      debugPrint('⛔ Camera permission permanently denied');
    }
    
    return status;
  }

  /// Check if notification permission is granted
  Future<bool> hasNotificationPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// Request notification permission
  Future<PermissionStatus> requestNotificationPermission() async {
    debugPrint('🔔 Requesting notification permission...');
    
    final status = await Permission.notification.request();
    
    if (status.isGranted) {
      debugPrint('✅ Notification permission granted');
    } else if (status.isDenied) {
      debugPrint('❌ Notification permission denied');
    } else if (status.isPermanentlyDenied) {
      debugPrint('⛔ Notification permission permanently denied');
    }
    
    return status;
  }

  /// Check if storage permission is granted (for older Android versions)
  Future<bool> hasStoragePermission() async {
    final status = await Permission.storage.status;
    return status.isGranted;
  }

  /// Request storage permission
  Future<PermissionStatus> requestStoragePermission() async {
    debugPrint('💾 Requesting storage permission...');
    
    final status = await Permission.storage.request();
    
    if (status.isGranted) {
      debugPrint('✅ Storage permission granted');
    } else if (status.isDenied) {
      debugPrint('❌ Storage permission denied');
    } else if (status.isPermanentlyDenied) {
      debugPrint('⛔ Storage permission permanently denied');
    }
    
    return status;
  }

  /// Open app settings (for permanently denied permissions)
  Future<bool> openSettings() async {
    debugPrint('⚙️ Opening app settings...');
    return openAppSettings();
  }

  /// Request location permission with rationale
  Future<bool> requestLocationWithRationale() async {
    final status = await Permission.location.status;
    
    if (status.isGranted) {
      return true;
    }
    
    if (status.isPermanentlyDenied) {
      // User has permanently denied, need to open settings
      return false;
    }
    
    // Request permission
    final result = await requestLocationPermission();
    return result.isGranted;
  }

  /// Request gallery/photos permission (Android 13+ uses photo picker, no permission needed).
  Future<bool> requestGalleryWithRationale() async {
    if (kIsWeb) return true;

    if (Platform.isIOS) {
      final status = await Permission.photos.request();
      return status.isGranted || status.isLimited;
    }

    return true;
  }

  /// Request camera permission with rationale
  Future<bool> requestCameraWithRationale() async {
    final status = await Permission.camera.status;
    
    if (status.isGranted) {
      return true;
    }
    
    if (status.isPermanentlyDenied) {
      return false;
    }
    
    final result = await requestCameraPermission();
    return result.isGranted;
  }

  /// Request notification permission with rationale
  Future<bool> requestNotificationWithRationale() async {
    final status = await Permission.notification.status;
    
    if (status.isGranted) {
      return true;
    }
    
    if (status.isPermanentlyDenied) {
      return false;
    }
    
    final result = await requestNotificationPermission();
    return result.isGranted;
  }

  /// Check if permission is permanently denied
  Future<bool> isLocationPermanentlyDenied() async {
    final status = await Permission.location.status;
    return status.isPermanentlyDenied;
  }

  Future<bool> isCameraPermanentlyDenied() async {
    final status = await Permission.camera.status;
    return status.isPermanentlyDenied;
  }

  Future<bool> isNotificationPermanentlyDenied() async {
    final status = await Permission.notification.status;
    return status.isPermanentlyDenied;
  }

  /// Request all necessary permissions at once
  Future<Map<Permission, PermissionStatus>> requestAllPermissions() async {
    debugPrint('📋 Requesting all permissions...');
    
    return await [
      Permission.location,
      Permission.notification,
    ].request();
  }

  /// Pick image with permission handling
  Future<String?> pickImageWithPermission() async {
    // Check camera permission
    final hasPermission = await requestCameraWithRationale();
    
    if (!hasPermission) {
      debugPrint('❌ Camera permission not granted');
      return null;
    }
    
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        debugPrint('✅ Image picked: ${image.path}');
        return image.path;
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ Error picking image: $e');
      return null;
    }
  }

  /// Take photo with permission handling
  Future<String?> takePhotoWithPermission() async {
    // Check camera permission
    final hasPermission = await requestCameraWithRationale();
    
    if (!hasPermission) {
      debugPrint('❌ Camera permission not granted');
      return null;
    }
    
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.camera);
      
      if (image != null) {
        debugPrint('✅ Photo taken: ${image.path}');
        return image.path;
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ Error taking photo: $e');
      return null;
    }
  }
}
