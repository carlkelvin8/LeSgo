import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/services/permission_service.dart';
import '../../../../../core/utils/snackbar_utils.dart';
import '../profile_provider.dart';

class ProfileControllers {
  final TextEditingController nameController;
  final TextEditingController address1Controller;
  final TextEditingController address2Controller;

  bool _isModalOpen = false;

  ProfileControllers({
    String name = '',
    String address1 = '',
    String address2 = '',
  })  : nameController = TextEditingController(text: name),
        address1Controller = TextEditingController(text: address1),
        address2Controller = TextEditingController(text: address2);

  /// Profile photos must be taken with the live camera (no gallery upload).
  Future<void> showImagePicker(
    BuildContext context,
    WidgetRef ref,
  ) async {
    if (_isModalOpen) return;
    _isModalOpen = true;

    try {
      await _pickImageFromCamera(context, ref, ImagePicker());
    } finally {
      _isModalOpen = false;
    }
  }

  Future<void> _pickImageFromCamera(
    BuildContext context,
    WidgetRef ref,
    ImagePicker picker,
  ) async {
    final permissionService = getIt<PermissionService>();
    final hasPermission = await permissionService.requestCameraWithRationale();
    if (!hasPermission) {
      if (context.mounted) {
        SnackBarUtils.showError(
          context,
          'Camera permission is required to take a profile photo.',
        );
      }
      return;
    }

    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1200,
      preferredCameraDevice: CameraDevice.front,
    );
    if (image != null && context.mounted) {
      await _updateProfileImage(context, ref, image);
    }
  }

  Future<void> _updateProfileImage(
    BuildContext context,
    WidgetRef ref,
    XFile imageFile,
  ) async {
    final success =
        await ref.read(profileProvider.notifier).updateProfileImage(imageFile);

    if (!context.mounted) return;

    if (success) {
      SnackBarUtils.showSuccess(
        context,
        'Profile picture updated successfully!',
      );
    } else {
      final error = ref.read(profileProvider).error;
      SnackBarUtils.showError(
        context,
        error ?? 'Failed to update profile picture. Please try again.',
      );
    }
  }

  Future<void> updateProfile(
    BuildContext context,
    WidgetRef ref,
  ) async {
    if (_isModalOpen) return;

    final success = await ref.read(profileProvider.notifier).updateProfile(
          name: nameController.text.isNotEmpty ? nameController.text : null,
          address1: address1Controller.text,
          address2: address2Controller.text,
        );

    if (context.mounted) {
      if (success) {
        SnackBarUtils.showSuccess(context, 'Profile updated successfully!');
      } else {
        SnackBarUtils.showError(context, 'Failed to update profile');
      }
    }
  }

  void dispose() {
    nameController.dispose();
    address1Controller.dispose();
    address2Controller.dispose();
  }
}
