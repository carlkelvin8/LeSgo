import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'register_state.dart';


mixin VerificationNotifier on StateNotifier<RegisterState> {

  Future<String?> captureSelfie() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final ImagePicker picker = ImagePicker();
      
      // For web, we might need to handle camera access differently
      XFile? photo;
      
      if (kIsWeb) {
        // On web, try camera first, fallback to gallery if camera fails
        try {
          photo = await picker.pickImage(
            source: ImageSource.camera,
            preferredCameraDevice: CameraDevice.front,
            imageQuality: 85,
          );
        } catch (cameraError) {
          // If camera fails on web, allow gallery selection as fallback
          debugPrint('Camera access failed on web: $cameraError');
          photo = await picker.pickImage(
            source: ImageSource.gallery,
            imageQuality: 85,
          );
        }
      } else {
        // On mobile, use camera directly
        photo = await picker.pickImage(
          source: ImageSource.camera,
          preferredCameraDevice: CameraDevice.front,
          imageQuality: 85,
        );
      }

      if (photo != null) {
        // For web, we need to handle the path differently
        String imagePath = photo.path;
        if (kIsWeb) {
          // On web, create a blob URL for the image
          imagePath = photo.path;
        }
        
        state = state.copyWith(
          data: state.data.copyWith(selfiePath: imagePath),
          isLoading: false,
        );
        return imagePath;
      }

      state = state.copyWith(isLoading: false);
      return null;
    } catch (e) {
      String errorMessage = 'Failed to capture photo';
      
      if (kIsWeb) {
        errorMessage = 'Camera access failed. Please ensure you have granted camera permissions in your browser settings.';
      }
      
      state = state.copyWith(
        isLoading: false,
        error: '$errorMessage: ${e.toString()}',
      );
      return null;
    }
  }

  void updateSelfie(String selfiePath) {
    state = state.copyWith(
      data: state.data.copyWith(selfiePath: selfiePath),
    );
  }
}
