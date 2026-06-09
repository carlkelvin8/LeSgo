import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/services/permission_service.dart';
import '../../../../../core/utils/responsive_utils.dart';
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

  Future<void> showImagePicker(
    BuildContext context,
    WidgetRef ref,
  ) async {
    _isModalOpen = true;
    final ImagePicker picker = ImagePicker();

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isDismissible: true,
      enableDrag: true,
      useRootNavigator: true,
      builder: (BuildContext modalContext) {
        return WillPopScope(
          onWillPop: () async {
            _isModalOpen = false;
            return true;
          },
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(ResponsiveUtils.spacing(modalContext, 20)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      _isModalOpen = false;
                      Navigator.pop(modalContext);
                      Future.delayed(const Duration(milliseconds: 150), () {
                        _pickImageFromGallery(context, ref, picker);
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      child: Row(
                        children: const [
                          Icon(
                            Icons.photo_library,
                            color: Color(0xFF5F2D82),
                          ),
                          SizedBox(width: 16),
                          Text(
                            'Choose from gallery',
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      _isModalOpen = false;
                      Navigator.pop(modalContext);
                      Future.delayed(const Duration(milliseconds: 150), () {
                        _pickImageFromCamera(context, ref, picker);
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      child: Row(
                        children: const [
                          Icon(
                            Icons.camera_alt,
                            color: Color(0xFF5F2D82),
                          ),
                          SizedBox(width: 16),
                          Text(
                            'Take a photo',
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(modalContext, 10)),
                ],
              ),
            ),
          ),
        );
      },
    );

    _isModalOpen = false;
  }

  Future<void> _pickImageFromGallery(
    BuildContext context,
    WidgetRef ref,
    ImagePicker picker,
  ) async {
    final permissionService = getIt<PermissionService>();
    final hasPermission = await permissionService.requestGalleryWithRationale();
    if (!hasPermission) {
      if (context.mounted) {
        SnackBarUtils.showError(
          context,
          'Gallery permission is required to choose a photo.',
        );
      }
      return;
    }

    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (image != null && context.mounted) {
      await _updateProfileImage(context, ref, image);
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
          'Camera permission is required to take a photo.',
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
